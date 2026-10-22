//-----------------------------------------------------------------------------
// In-FPGA QSPI flash emulator (FPGA bring-up only)
//
// 2026-10-15: stands in for the HAPS-SX on-board W25Q32FW, which no longer accepts
// writes or array reads (ticket N30). Sits on the QSPI controller's pad-side signals
// inside megasoc_tech_wrapper and behaves like the SST26VF064B that SoC Labs verified
// the controller and SPI_STARTUP() against, so the unmodified boot code runs.
//
//   SPI (1-bit):  9Fh JEDEC (BF 26 43), 05h status {WEL,BUSY}, 35h (00), 06h/04h,
//                 38h enter QPI, 66h+99h reset, 03h read, 0Bh fast read (SPI_DUMMY),
//                 02h page program, 20h 4 KB / D8h 64 KB / C7h,60h chip erase
//   QPI (4-bit):  same opcodes as 2-clock nibbles. 0Bh/EBh: address (6 clk), mode byte
//                 (2 clk), QPI_DUMMY clocks, data - SST26VF064B SQI high-speed read.
//                 Mode byte 0xAx enters continuous-read mode: the following transactions
//                 start with the address (what the controller's No_CMD mode sends).
//                 FFh exits QPI; in continuous mode a transaction that ends before the
//                 mode byte leaves continuous mode, and if it carried FFh it also exits
//                 QPI (Reset-QIO), which is how firmware gets back to SPI.
//   Program overwrites (no AND with old data). Erase sets bytes to FFh, BUSY while it runs.
//
// Store: MEM_KB of block RAM, one true-dual-port array per byte lane.
//   port A = 64-bit backdoor from axi4_bram_slave (the UART loader fills it)
//   port B = flash side (prefetch read of the current word, byte writes, erase)
// Everything runs on HCLK: SCLK, nCS and IO are sampled and edge-detected, so the
// controller's CLK_DIV must be >= 4 (firmware uses 4). Output data changes one HCLK
// after the SCLK falling edge; the controller samples at the next rising edge.
// The emulator is reset with the SoC; its store is not (BRAM keeps the image).
//-----------------------------------------------------------------------------
module qspi_flash_emu #(
    parameter MEM_KB    = 512,
    parameter [23:0] JEDEC = 24'hBF2643,
    parameter QPI_DUMMY = 4,
    parameter SPI_DUMMY = 8
)(
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        SCLK,
    input  wire        nCS,
    input  wire [3:0]  IO_i,          // driven by the controller
    output reg  [3:0]  IO_o,
    output reg  [3:0]  IO_e,
    input  wire        bd_we,
    input  wire        bd_re,
    input  wire [15:0] bd_addr,       // 64-bit word index (aliased to the store size)
    input  wire [63:0] bd_wdata,
    input  wire [7:0]  bd_wstrb,
    output reg  [63:0] bd_rdata,
    output wire        emu_qpi,
    output wire        emu_busy
);
    localparam DEPTH = MEM_KB * 1024 / 8;
    localparam AW    = $clog2(DEPTH);
    localparam BW    = AW + 3;

    // ---------------- store ----------------
    reg           pb_we;
    reg  [7:0]    pb_wstrb;
    reg  [AW-1:0] pb_addr;
    reg  [63:0]   pb_wdata;
    reg  [63:0]   pb_rdata;
    genvar g;
    generate for (g = 0; g < 8; g = g + 1) begin : g_lane
        reg [7:0] lane [0:DEPTH-1];
        always @(posedge HCLK) begin
            if (bd_we && bd_wstrb[g]) lane[bd_addr[AW-1:0]] <= bd_wdata[8*g +: 8];
            if (bd_re)                bd_rdata[8*g +: 8] <= lane[bd_addr[AW-1:0]];
        end
        always @(posedge HCLK) begin
            if (pb_we && pb_wstrb[g]) lane[pb_addr] <= pb_wdata[8*g +: 8];
            pb_rdata[8*g +: 8] <= lane[pb_addr];
        end
    end endgenerate

    // ---------------- edge detection ----------------
    reg sclk_q, ncs_q;
    always @(posedge HCLK or negedge HRESETn)
        if (!HRESETn) begin sclk_q <= 1'b0; ncs_q <= 1'b1; end
        else          begin sclk_q <= SCLK; ncs_q <= nCS; end
    wire rise    =  SCLK & ~sclk_q & ~nCS;
    wire fall    = ~SCLK &  sclk_q & ~nCS;
    wire cs_fall = ~nCS &  ncs_q;
    wire cs_rise =  nCS & ~ncs_q;

    // ---------------- device state ----------------
    reg qpi, cont, wel, rsten, busy;
    assign emu_qpi  = qpi;
    assign emu_busy = busy;
    localparam [2:0] P_OP = 3'd0, P_ADDR = 3'd1, P_MODE = 3'd2, P_DUMMY = 3'd3, P_DOUT = 3'd4, P_DIN = 3'd5, P_IGN = 3'd6;
    reg [2:0]  phase;
    reg [7:0]  op, sh, mode;
    reg [4:0]  bitcnt;
    reg [23:0] addr;
    reg [1:0]  idbyte;
    reg [7:0]  obyte;
    reg [2:0]  obit;
    reg        cont_next;
    reg        er_run;
    reg [AW-1:0] er_idx, er_end;

    wire [AW-1:0] widx      = addr[BW-1:3];
    wire [7:0]    mem_byte  = pb_rdata[8*addr[2:0] +: 8];
    wire [7:0]    id_byte   = (idbyte == 2'd0) ? JEDEC[23:16] : (idbyte == 2'd1) ? JEDEC[15:8] : (idbyte == 2'd2) ? JEDEC[7:0] : 8'h00;
    wire [7:0]    nxt_byte  = (op == 8'h9F) ? id_byte : (op == 8'h05) ? {6'b0, wel, busy} : (op == 8'h35) ? 8'h00 : mem_byte;
    wire [7:0]    in_byte   = qpi ? {sh[3:0], IO_i} : {sh[6:0], IO_i[0]};
    wire [4:0]    clk_byte  = qpi ? 5'd1 : 5'd7;     // bitcnt value at the last clock of a byte

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            qpi <= 1'b0; cont <= 1'b0; wel <= 1'b0; rsten <= 1'b0; busy <= 1'b0;
            phase <= P_IGN; op <= 8'h0; sh <= 8'h0; mode <= 8'h0; bitcnt <= 5'd0; addr <= 24'h0;
            idbyte <= 2'd0; obyte <= 8'h0; obit <= 3'd0; cont_next <= 1'b0;
            IO_o <= 4'hF; IO_e <= 4'h0;
            pb_we <= 1'b0; pb_wstrb <= 8'h0; pb_addr <= '0; pb_wdata <= 64'h0;
            er_run <= 1'b0; er_idx <= '0; er_end <= '0;
        end else begin
            pb_we <= 1'b0;
            if (!er_run) pb_addr <= widx;               // keep the current word prefetched
            // ---- erase engine: one 64-bit word per cycle ----
            if (er_run) begin
                pb_we <= 1'b1; pb_wstrb <= 8'hFF; pb_addr <= er_idx; pb_wdata <= {64{1'b1}};
                er_idx <= er_idx + 1'b1;
                if (er_idx == er_end) begin er_run <= 1'b0; busy <= 1'b0; end
            end
            // ---- chip select falling: start of a transaction ----
            if (cs_fall) begin
                bitcnt <= 5'd0; sh <= 8'h0; idbyte <= 2'd0; obit <= 3'd0; cont_next <= 1'b0;
                IO_e <= 4'h0;
                if (cont) begin phase <= P_ADDR; op <= 8'h0B; addr <= 24'h0; end
                else      begin phase <= P_OP;   op <= 8'h00; end
            end
            // ---- rising SCLK: sample ----
            if (rise) begin
                case (phase)
                    P_OP: begin
                        sh <= in_byte; bitcnt <= bitcnt + 5'd1;
                        if (bitcnt == clk_byte) begin
                            op <= in_byte; bitcnt <= 5'd0;
                            case (in_byte)
                                8'h9F, 8'h05, 8'h35:                      begin phase <= P_DOUT; obit <= 3'd0; end
                                8'h03, 8'h0B, 8'hEB, 8'h02, 8'h20, 8'hD8: begin phase <= P_ADDR; addr <= 24'h0; end
                                default:                                  phase <= P_IGN;   // acts at CS rise
                            endcase
                        end
                    end
                    P_ADDR: begin
                        addr <= qpi ? {addr[19:0], IO_i} : {addr[22:0], IO_i[0]};
                        bitcnt <= bitcnt + 5'd1;
                        if (bitcnt == (qpi ? 5'd5 : 5'd23)) begin
                            bitcnt <= 5'd0;
                            case (op)
                                8'h03:        begin phase <= P_DOUT; obit <= 3'd0; end
                                8'h0B, 8'hEB: phase <= qpi ? P_MODE : P_DUMMY;
                                8'h02:        begin phase <= P_DIN; sh <= 8'h0; end
                                default:      phase <= P_IGN;      // erase: act at CS rise
                            endcase
                        end
                    end
                    P_MODE: begin
                        mode <= {mode[3:0], IO_i}; bitcnt <= bitcnt + 5'd1;
                        if (bitcnt == 5'd1) begin
                            bitcnt <= 5'd0;
                            cont_next <= ({mode[3:0], IO_i} & 8'hF0) == 8'hA0;
                            phase <= P_DUMMY;
                        end
                    end
                    P_DUMMY: begin
                        bitcnt <= bitcnt + 5'd1;
                        if (bitcnt == (qpi ? QPI_DUMMY - 1 : SPI_DUMMY - 1)) begin bitcnt <= 5'd0; phase <= P_DOUT; obit <= 3'd0; end
                    end
                    P_DIN: begin
                        sh <= in_byte; bitcnt <= bitcnt + 5'd1;
                        if (bitcnt == clk_byte) begin
                            bitcnt <= 5'd0;
                            if (wel && !busy) begin
                                pb_we <= 1'b1; pb_addr <= widx; pb_wstrb <= (8'h01 << addr[2:0]); pb_wdata <= {8{in_byte}};
                            end
                            addr <= addr + 24'd1;
                        end
                    end
                    default: ;
                endcase
            end
            // ---- falling SCLK: drive data ----
            if (fall && phase == P_DOUT) begin
                if (obit == 3'd0) begin
                    obyte <= nxt_byte;
                    if (qpi) begin IO_o <= nxt_byte[7:4];             IO_e <= 4'hF;    obit <= 3'd1; end
                    else     begin IO_o <= {2'b11, nxt_byte[7], 1'b1}; IO_e <= 4'b0010; obit <= 3'd7; end
                    if (op == 8'h9F) idbyte <= idbyte + 2'd1;
                    else if (op != 8'h05 && op != 8'h35) addr <= addr + 24'd1;   // prefetch the next byte
                end else begin
                    if (qpi) begin IO_o <= obyte[3:0]; obit <= 3'd0; end
                    else     begin IO_o <= {2'b11, obyte[obit-3'd1], 1'b1}; obit <= obit - 3'd1; end
                end
            end
            // ---- chip select rising: end of a transaction ----
            if (cs_rise) begin
                IO_e <= 4'h0; IO_o <= 4'hF; phase <= P_IGN;
                case (op)
                    8'h38: qpi <= 1'b1;
                    8'hFF: begin qpi <= 1'b0; cont <= 1'b0; end
                    8'h66: rsten <= 1'b1;
                    8'h99: if (rsten) begin qpi <= 1'b0; cont <= 1'b0; wel <= 1'b0; end
                    8'h06: wel <= 1'b1;
                    8'h04, 8'h02: wel <= 1'b0;
                    8'h20: if (wel && !busy) begin wel <= 1'b0; busy <= 1'b1; er_run <= 1'b1; er_idx <= widx & ({AW{1'b1}} << 9);  er_end <= widx | {{(AW-9){1'b0}}, 9'h1FF}; end
                    8'hD8: if (wel && !busy) begin wel <= 1'b0; busy <= 1'b1; er_run <= 1'b1; er_idx <= widx & ({AW{1'b1}} << 13); er_end <= widx | ({AW{1'b1}} >> (AW-13)); end
                    8'hC7, 8'h60: if (wel && !busy) begin wel <= 1'b0; busy <= 1'b1; er_run <= 1'b1; er_idx <= '0; er_end <= {AW{1'b1}}; end
                    8'h0B, 8'hEB: if (phase == P_DUMMY || phase == P_DOUT) cont <= cont_next;   // mode byte was received
                    default: ;
                endcase
                if (op != 8'h66) rsten <= 1'b0;
                // continuous mode: a transaction that ends before the mode byte leaves it;
                // FFh in the first two QPI clocks is Reset-QIO and also leaves QPI.
                // A chip-select pulse with no clock (the controller's NO_FETCH path when the
                // address repeats) changes nothing, as on a real part.
                if (cont && ((phase == P_ADDR && bitcnt != 5'd0) || phase == P_MODE)) begin
                    cont <= 1'b0;
                    if (phase == P_ADDR && qpi && bitcnt == 5'd2 && addr[7:0] == 8'hFF) qpi <= 1'b0;
                end
            end
            if (phase != P_DOUT || nCS) IO_e <= 4'h0;
        end
    end
endmodule
