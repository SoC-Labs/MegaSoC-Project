`timescale 1ps/1ps
// Testbench for haps_ddr4_bridge with the Xilinx converter IPs and the behavioural ddr4_0 model.
// SoC-side AXI4 master at 20 MHz: resets, bursts (INCR/WRAP), narrow writes, IDs, addresses above 4 GB and the
// 0x2_0000_0000 alias; every byte written is tracked in a reference memory keyed by the DDR4 IP address.
module tb_bridge;
    localparam ID_W = 9, ADDR_W = 33, DATA_W = 64;
    reg ACLK = 0; always #25000 ACLK = ~ACLK;          // 20 MHz
    reg ARESETn = 0, DDR4_SYS_RST = 1;
    // AXI master signals
    reg  AWVALID = 0; wire AWREADY; reg [ID_W-1:0] AWID = 0; reg [ADDR_W-1:0] AWADDR = 0; reg [7:0] AWLEN = 0; reg [2:0] AWSIZE = 3; reg [1:0] AWBURST = 1;
    reg  WVALID = 0; wire WREADY; reg [63:0] WDATA = 0; reg [7:0] WSTRB = 0; reg WLAST = 0;
    wire BVALID; reg BREADY = 0; wire [ID_W-1:0] BID; wire [1:0] BRESP;
    reg  ARVALID = 0; wire ARREADY; reg [ID_W-1:0] ARID = 0; reg [ADDR_W-1:0] ARADDR = 0; reg [7:0] ARLEN = 0; reg [2:0] ARSIZE = 3; reg [1:0] ARBURST = 1;
    wire RVALID; reg RREADY = 0; wire [ID_W-1:0] RID; wire [63:0] RDATA; wire [1:0] RRESP; wire RLAST;
    wire calib;
    wire [63:0] dq; wire [7:0] dm, dqs_t, dqs_c;

    haps_ddr4_bridge #(.ID_W(ID_W), .DATA_W(DATA_W), .ADDR_W(ADDR_W)) dut (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .AWVALID(AWVALID), .AWREADY(AWREADY), .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE), .AWBURST(AWBURST),
        .AWLOCK(1'b0), .AWCACHE(4'h3), .AWPROT(3'b000),
        .WVALID(WVALID), .WREADY(WREADY), .WDATA(WDATA), .WSTRB(WSTRB), .WLAST(WLAST),
        .BVALID(BVALID), .BREADY(BREADY), .BID(BID), .BRESP(BRESP),
        .ARVALID(ARVALID), .ARREADY(ARREADY), .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE), .ARBURST(ARBURST),
        .ARLOCK(1'b0), .ARCACHE(4'h3), .ARPROT(3'b000),
        .RVALID(RVALID), .RREADY(RREADY), .RID(RID), .RDATA(RDATA), .RRESP(RRESP), .RLAST(RLAST),
        .DDR4_SYS_CLK_P(1'b0), .DDR4_SYS_CLK_N(1'b1), .DDR4_SYS_RST(DDR4_SYS_RST), .DDR4_CALIB_COMPLETE(calib),
        .DDR4_CK_T(), .DDR4_CK_C(), .DDR4_ADR(), .DDR4_BA(), .DDR4_BG(), .DDR4_ACT_n(), .DDR4_CKE(), .DDR4_CS_N(), .DDR4_ODT(),
        .DDR4_DQ(dq), .DDR4_DM_DBI_N(dm), .DDR4_DQS_T(dqs_t), .DDR4_DQS_C(dqs_c), .DDR4_RESET_N()
    );

    // ---- reference memory keyed by DDR4 IP byte address (bit 33 of the CPU address dropped) ----
    bit [7:0] ref_mem [longint unsigned];
    function automatic longint unsigned ip_addr(input longint unsigned cpu_a); return cpu_a & 64'h1_FFFF_FFFF; endfunction
    function automatic longint unsigned nxt(input longint unsigned a, input [2:0] size, input [1:0] burst, input [7:0] len);
        longint unsigned inc = 1 << size, aligned = (a >> size) << size, wm = ((len + 1) << size) - 1;
        case (burst) 2'b00: return a; 2'b10: return (aligned & ~wm) | ((aligned + inc) & wm); default: return aligned + inc; endcase
    endfunction
    integer errors = 0, checks = 0;

    // ---- AXI master tasks ----
    task automatic axi_write(input [ID_W-1:0] id, input longint unsigned addr, input [7:0] len, input [2:0] size, input [1:0] burst, input [63:0] data[]);
        longint unsigned a = addr; integer nb = 1 << size, i, k;
        @(posedge ACLK); AWID <= id; AWADDR <= addr[32:0]; AWLEN <= len; AWSIZE <= size; AWBURST <= burst; AWVALID <= 1;
        do @(posedge ACLK); while (!AWREADY);
        AWVALID <= 0;
        for (i = 0; i <= len; i++) begin
            WDATA <= data[i]; WSTRB <= ((8'h1 << nb) - 1) << (a & 7); WLAST <= (i == len); WVALID <= 1;
            for (k = 0; k < nb; k++) ref_mem[ip_addr(a) + k] = data[i][((a & 7) + k) * 8 +: 8];
            do @(posedge ACLK); while (!WREADY);
            a = nxt(a, size, burst, len);
        end
        WVALID <= 0; WLAST <= 0; BREADY <= 1;
        do @(posedge ACLK); while (!BVALID);
        checks++; if (BID !== id || BRESP !== 2'b00) begin errors++; $display("%t FAIL write resp id %h (exp %h) resp %b", $time, BID, id, BRESP); end
        BREADY <= 0;
    endtask
    task automatic axi_read_check(input [ID_W-1:0] id, input longint unsigned addr, input [7:0] len, input [2:0] size, input [1:0] burst);
        longint unsigned a = addr; integer nb = 1 << size, i, k; bit [7:0] exp;
        @(posedge ACLK); ARID <= id; ARADDR <= addr[32:0]; ARLEN <= len; ARSIZE <= size; ARBURST <= burst; ARVALID <= 1;
        do @(posedge ACLK); while (!ARREADY);
        ARVALID <= 0; RREADY <= 1;
        for (i = 0; i <= len; i++) begin
            do @(posedge ACLK); while (!RVALID);
            checks++;
            if (RID !== id || RRESP !== 2'b00 || RLAST !== (i == len)) begin errors++; $display("%t FAIL read beat %0d id %h (exp %h) resp %b last %b", $time, i, RID, id, RRESP, RLAST); end
            for (k = 0; k < nb; k++) if (ref_mem.exists(ip_addr(a) + k)) begin
                exp = ref_mem[ip_addr(a) + k];
                if (RDATA[((a & 7) + k) * 8 +: 8] !== exp) begin errors++; $display("%t FAIL read data @%h byte %0d got %h exp %h (beat %0d)", $time, a, k, RDATA[((a & 7) + k) * 8 +: 8], exp, i); end
            end
            a = nxt(a, size, burst, len);
        end
        RREADY <= 0;
    endtask

    reg [63:0] d[]; integer n; time t0; longint unsigned base;
    initial begin
        d = new[16];
        // ---- power-up: IP reset pulse, SoC held in reset for 1 us ----
        #200000 DDR4_SYS_RST = 0;
        #1000000 ARESETn = 1;
        // T0: a write issued before calibration completes must only finish after it
        $display("%t T0 write before calibration (calib=%b)", $time, calib);
        for (n = 0; n < 8; n++) d[n] = 64'h0123_4567_89AB_CDEF ^ (n * 64'h1111_1111_1111_1111);
        t0 = $time; axi_write(9'h005, 64'h8000_0000, 7, 3, 2'b01, d);
        if (!calib) begin errors++; $display("%t FAIL write completed before calibration", $time); end
        else $display("%t T0 ok: write completed %0t after start, calib=%b", $time, $time - t0, calib);
        axi_read_check(9'h005, 64'h8000_0000, 7, 3, 2'b01);
        // T1: full-line INCR bursts at a few addresses, read back (same and different IDs)
        $display("%t T1 INCR bursts", $time);
        for (base = 64'h8000_1000; base < 64'h8000_1000 + 64'h200; base += 64'h40) begin
            for (n = 0; n < 8; n++) d[n] = base * 64'h9E37_79B9_7F4A_7C15 + n;
            axi_write(base[8:3], base, 7, 3, 2'b01, d);
        end
        for (base = 64'h8000_1000; base < 64'h8000_1000 + 64'h200; base += 64'h40) axi_read_check(~base[8:3], base, 7, 3, 2'b01);
        // T2: WRAP bursts starting mid-line (Cortex-A53 line fill), 4- and 8-beat
        $display("%t T2 WRAP bursts", $time);
        for (n = 0; n < 8; n++) d[n] = 64'hA5A5_0000_0000_0000 | n;
        axi_write(9'h021, 64'h8000_2018, 7, 3, 2'b10, d);
        axi_read_check(9'h022, 64'h8000_2018, 7, 3, 2'b10);
        axi_read_check(9'h023, 64'h8000_2000, 7, 3, 2'b01);
        for (n = 0; n < 4; n++) d[n] = 64'h5A5A_0000_0000_0000 | n;
        axi_write(9'h024, 64'h8000_2130, 3, 3, 2'b10, d);
        axi_read_check(9'h025, 64'h8000_2130, 3, 3, 2'b10);
        // T3: narrow writes - bytes, halfwords, words at every lane, then 64-bit read of the lines
        $display("%t T3 narrow writes", $time);
        for (n = 0; n < 8; n++) d[n] = 64'hFFFF_FFFF_FFFF_FFFF;
        axi_write(9'h030, 64'h8000_3000, 7, 3, 2'b01, d);
        for (n = 0; n < 8; n++) begin d[0] = {8{8'h10 + n[7:0]}}; axi_write(9'h031, 64'h8000_3000 + n, 0, 0, 2'b01, d); end
        for (n = 0; n < 4; n++) begin d[0] = {4{16'h2000 + n[15:0] * 16'h0101}}; axi_write(9'h032, 64'h8000_3008 + n * 2, 0, 1, 2'b01, d); end
        for (n = 0; n < 2; n++) begin d[0] = {2{32'h3000_0000 + n * 32'h0101_0101}}; axi_write(9'h033, 64'h8000_3010 + n * 4, 0, 2, 2'b01, d); end
        for (n = 0; n < 4; n++) d[n] = {8{8'h40 + n[7:0]}};
        axi_write(9'h034, 64'h8000_3018, 3, 0, 2'b01, d);              // 4-beat byte burst
        axi_read_check(9'h035, 64'h8000_3000, 3, 3, 2'b01);
        axi_read_check(9'h036, 64'h8000_3000, 7, 0, 2'b01);              // byte reads
        axi_read_check(9'h037, 64'h8000_3010, 3, 2, 2'b01);              // word reads
        // T4: addresses above 4 GB (bit 32) and the alias window above 8 GB (bit 33 dropped)
        $display("%t T4 high addresses", $time);
        for (n = 0; n < 8; n++) d[n] = 64'h0400_0000_0000_0000 | n;
        axi_write(9'h041, 64'h1_0000_0040, 7, 3, 2'b01, d);
        for (n = 0; n < 8; n++) d[n] = 64'h0800_0000_0000_0000 | n;
        axi_write(9'h042, 64'h2_0000_0040, 7, 3, 2'b01, d);            // -> DDR4 address 0x40
        for (n = 0; n < 8; n++) d[n] = 64'h1FFF_0000_0000_0000 | n;
        axi_write(9'h043, 64'h1_FFFF_FFC0, 7, 3, 2'b01, d);            // last line of rank 0
        axi_read_check(9'h044, 64'h1_0000_0040, 7, 3, 2'b01);
        axi_read_check(9'h045, 64'h2_0000_0040, 7, 3, 2'b01);
        axi_read_check(9'h046, 64'h1_FFFF_FFC0, 7, 3, 2'b01);
        if (dut.u_ddr4_0.mem.exists(28'h1) && dut.u_ddr4_0.mem[28'h1][63:0] == (64'h0800_0000_0000_0000)) $display("%t T4 ok: 0x2_0000_0040 landed at DDR4 line 1", $time);
        else begin errors++; $display("%t FAIL alias: DDR4 line 1 = %h", $time, dut.u_ddr4_0.mem.exists(28'h1) ? dut.u_ddr4_0.mem[28'h1][63:0] : 64'hx); end
        // T5: back-to-back reads with different IDs (ordering), then writes
        $display("%t T5 ordering", $time);
        axi_read_check(9'h101, 64'h8000_1000, 7, 3, 2'b01);
        axi_read_check(9'h102, 64'h8000_2000, 7, 3, 2'b01);
        axi_read_check(9'h103, 64'h8000_1040, 7, 3, 2'b01);
        // T6: SoC reset while idle, then traffic again; DRAM contents must survive (IP not reset)
        $display("%t T6 SoC reset", $time);
        @(posedge ACLK); ARESETn <= 0; repeat (40) @(posedge ACLK); ARESETn <= 1; repeat (10) @(posedge ACLK);
        axi_read_check(9'h061, 64'h8000_1000, 7, 3, 2'b01);
        for (n = 0; n < 8; n++) d[n] = 64'h6666_0000_0000_0000 | n;
        axi_write(9'h062, 64'h8000_6000, 7, 3, 2'b01, d);
        axi_read_check(9'h063, 64'h8000_6000, 7, 3, 2'b01);
        #2000000;
        $display("===SIM=== checks=%0d errors=%0d %s", checks, errors, errors == 0 ? "PASS" : "FAIL");
        $finish;
    end
    initial begin #400_000_000; $display("===SIM=== TIMEOUT errors=%0d", errors + 1); $finish; end
endmodule
