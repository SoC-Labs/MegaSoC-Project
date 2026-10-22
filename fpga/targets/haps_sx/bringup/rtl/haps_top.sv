//-----------------------------------------------------------------------------
// MegaSoC Chip - HAPS FPGA Top (Corrected for HAPS-SX VU19P 1F board + ILA)
//
// Clock:  GCLK1 (LVDS differential) via IBUFDS on BM44/BN44
//         NOTE: Set GCLK1 = 20 MHz in ConfPro Clock tab before testing!
// Reset:  PB1 push button on BK44 (active low)
// LEDs:   LED5 (BF14) = heartbeat (~4.8 Hz blink at 20 MHz)
// UART:   PMOD3 connector (bank 83, 1.8V)
//           IO[0] BE18 = UART_TX  (FPGA transmits, wire to bridge RX)
//           IO[1] BE19 = UART_RX  (FPGA receives,  wire to bridge TX)
//           IO[2] BG19 = PL011_TX
// QSPI:   On-board SPI flash W25Q32FW (bank 21, 1.8V)
// Debug:  ILA removed 2026-08-11 - debug_uart_probe is the sole channel now
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic
// Access license.
//
// Contributors
//   Anastasios Dimitriou (ad1u25@soton.ac.uk)
//
// Copyright 2021-4, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module haps_top (
    // GCLK1 - LVDS differential clock from on-board PLL
    input  wire        HAPS_CLK_IN_P,    // BM44 (GCLK1 P)
    input  wire        HAPS_CLK_IN_N,    // BN44 (GCLK1 N)

    // PB1 - user push button, active low
    input  wire        HAPS_RESET_N,     // BK44

    // UART on PMOD3 connector (bank 83, directly accessible)
    output wire        UART_TX,          // BE18 (PMOD3 IO[0])
    input  wire        UART_RX,          // BE19 (PMOD3 IO[1])

    // LED5 - green, active high
    output wire        HB,               // BF14

    // PL011 secondary UART on PMOD3
    output wire        PL011_TX,         // BG19 (PMOD3 IO[2])

    // Debug UART event logger - dedicated TX-only output, independent of
    // the JTAG/ILA path (corrupted at 20 MHz on this board). See
    // debug_uart_probe.sv.
    output wire        DEBUG_UART_TX,    // BF19 (PMOD3 IO[3])

    // On-board SPI flash (bank 21, 1.8V)
    output wire        QSPI_SCLK,        // CA49
    output wire        QSPI_nCS,         // CB49
    inout  wire [3:0]  QSPI_IO           // CC49, CC50, CA51, CB51
);

    // =========================================================================
    // 1) Clock - LVDS differential to single-ended via IBUFDS + BUFG
    // =========================================================================
    wire clk_ibuf;

    IBUFDS #(
        .DIFF_TERM("FALSE"),
        .IBUF_LOW_PWR("FALSE")
    ) u_ibufds_clk (
        .I  (HAPS_CLK_IN_P),
        .IB (HAPS_CLK_IN_N),
        .O  (clk_ibuf)
    );

    wire clk;
    BUFG u_bufg_clk (
        .I (clk_ibuf),
        .O (clk)
    );

    // =========================================================================
    // 2) Reset shaping
    // =========================================================================
    // 2026-08-11: periodic auto-reset for unattended operation. PB1 was
    // never actually required for a single reset-release cycle (nreset_soc
    // starts counting from its bitstream-init value the moment
    // configuration completes, with no dependency on HAPS_RESET_N ever
    // being asserted) - but a single automatic cycle only gives one
    // observation window, easy to miss if a logging terminal isn't
    // connected before programming finishes. With no physical access for
    // the next week, auto_reset_n re-triggers the whole SoC reset
    // sequence every ~10s on its own, giving many independent boot
    // attempts for debug_uart_probe (which stays running continuously
    // across these, tied only to HAPS_RESET_N - see dbg_resetn below) to
    // capture into one continuous log. A real PB1 press still works too.
    logic [27:0] auto_rst_period_cnt;
    localparam logic [27:0] AUTO_RST_PERIOD = 28'd200_000_000;  // ~10s at 20MHz
    always_ff @(posedge clk or negedge HAPS_RESET_N)
        if (!HAPS_RESET_N) auto_rst_period_cnt <= '0;
        else if (auto_rst_period_cnt == AUTO_RST_PERIOD - 1'b1) auto_rst_period_cnt <= '0;
        else auto_rst_period_cnt <= auto_rst_period_cnt + 1'b1;
    // 2026-10-14 (build 46): the monitor boot ROM needs the SoC to stay up while a
    // host talks to it over UART0, and the 10 s auto-reset above cut every monitor
    // session short. Any falling edge on UART_RX (a start bit) now suspends the
    // auto-reset for 2^32 cycles (~215 s at 20 MHz), renewed by every byte received.
    // Edge detection rather than level, so a floating or stuck-low RX pin cannot
    // disable the auto-reset. PB1 (HAPS_RESET_N) still resets at any time.
    (* ASYNC_REG = "true" *) logic [1:0] uart_rx_sync;
    logic        uart_rx_q;
    logic [31:0] rx_holdoff_cnt;
    always_ff @(posedge clk or negedge HAPS_RESET_N)
        if (!HAPS_RESET_N) begin
            uart_rx_sync   <= 2'b11;
            uart_rx_q      <= 1'b1;
            rx_holdoff_cnt <= '0;
        end else begin
            uart_rx_sync <= {uart_rx_sync[0], UART_RX};
            uart_rx_q    <= uart_rx_sync[1];
            if (uart_rx_q & ~uart_rx_sync[1])  rx_holdoff_cnt <= 32'hFFFF_FFFF;
            else if (rx_holdoff_cnt != '0)     rx_holdoff_cnt <= rx_holdoff_cnt - 1'b1;
        end
    wire rx_holdoff   = (rx_holdoff_cnt != '0);
    wire auto_reset_n = ~((auto_rst_period_cnt < 28'd64) & ~rx_holdoff);

    logic [15:0] rst_cnt;
    logic        nreset_soc;

    always_ff @(posedge clk or negedge HAPS_RESET_N) begin
        if (!HAPS_RESET_N || !auto_reset_n) begin
            rst_cnt    <= '0;
            nreset_soc <= 1'b0;
        end else begin
            if (!rst_cnt[15]) rst_cnt <= rst_cnt + 1'b1;
            nreset_soc <= rst_cnt[15];
        end
    end

    // 2026-08-10: debug_uart_probe needs its OWN, fast-releasing reset.
    // Tying it to nreset_soc (which takes ~1.6ms / 32768 cycles to
    // release) means it can never observe any signal that settles at or
    // before that point - including nreset_soc-derived signals
    // themselves (confirmed via the SYS_RESETn test: it shares
    // nreset_soc's exact net, so by the probe's own first post-reset
    // sample it was already settled high, with no "before" state left to
    // detect an edge against) and, worse, anything that happens to now
    // release around the same time nreset_soc does - which would make it
    // vanish from the log with nothing actually wrong. A short local
    // synchronizer on HAPS_RESET_N releases in a handful of cycles,
    // letting the probe watch from the very start instead.
    logic [2:0] dbg_rst_sync;
    always_ff @(posedge clk or negedge HAPS_RESET_N)
        if (!HAPS_RESET_N) dbg_rst_sync <= 3'b000;
        else               dbg_rst_sync <= {dbg_rst_sync[1:0], 1'b1};
    wire dbg_resetn = dbg_rst_sync[2];

    // =========================================================================
    // 3) RT clock - a gated copy of the main clock, 32.787 kHz
    // =========================================================================
    // History: rtc_div[15] (305 Hz, 107x too slow - bug register B4/B5) until
    // 2026-09-28; then, in the Linux tree, a /610 toggle register rt_clk_r
    // declared in the XDC as a generated clock (B6). Replaced on 2026-09-30,
    // and kept through the 2026-10-05 merge, by a BUFGCE-gated copy of the
    // main clock. Both give 32.787 kHz; the difference is what timing analysis
    // sees.
    //
    // RT_CLK is produced by a BUFGCE in parallel with the main BUFG, both fed
    // from the same IBUFDS, with the clock enable asserted for one cycle in
    // every 610 (20 MHz / 610 = 32.787 kHz, +0.06%). Each enabled cycle passes
    // exactly one full clock period. To static timing analysis RT_CLK is
    // therefore simply HAPS_CLK: it needs no generated-clock declaration, the
    // RT-domain flops are timed like any others, and every RT<->system crossing
    // is an ordinary same-clock path rather than a CDC to be bounded. The two
    // buffers are balanced with a CLOCK_DELAY_GROUP in haps_top_clocks_impl.xdc.
    // (The Linux tree's `create_generated_clock -name RT_CLK ... rt_clk_r_reg/Q`
    // and its two set_max_delay lines must NOT be carried over: the register
    // they name does not exist here, and the build gate would fail on it.)
    //
    // Consequence for consumers: RT_CLK is a CLOCK ONLY. It is high for half a
    // system-clock period once every 610 cycles, so it must never be sampled as
    // data by system-clock logic - see rt_extin in megasoc_peripheral_subsystem.
    localparam int unsigned RTC_PERIOD = 610;
    logic [9:0] rtc_cnt;
    logic       rtc_tick;   // registered: BUFGCE.CE must be glitch-free
    always_ff @(posedge clk or negedge nreset_soc) begin
        if (!nreset_soc) begin
            rtc_cnt  <= '0;
            rtc_tick <= 1'b0;
        end else begin
            rtc_tick <= (rtc_cnt == RTC_PERIOD - 1);
            rtc_cnt  <= (rtc_cnt == RTC_PERIOD - 1) ? '0 : rtc_cnt + 1'b1;
        end
    end

    wire rt_clk;
    BUFGCE #(
        .CE_TYPE        ("SYNC"),
        .IS_CE_INVERTED (1'b0),
        .IS_I_INVERTED  (1'b0),
        .SIM_DEVICE     ("ULTRASCALE_PLUS"),
        .STARTUP_SYNC   ("FALSE")
    ) u_bufgce_rtclk (
        .I  (clk_ibuf),
        .CE (rtc_tick),
        .O  (rt_clk)
    );

    // =========================================================================
    // 4) Heartbeat - LED5 (green, BF14)
    //    hb_cnt[22] = ~4.8 Hz at 20 MHz - clearly visible blink
    // =========================================================================
    logic [31:0] hb_cnt;
    always_ff @(posedge clk or negedge nreset_soc) begin
        if (!nreset_soc) hb_cnt <= '0;
        else             hb_cnt <= hb_cnt + 1'b1;
    end
    assign HB = hb_cnt[22];

    // =========================================================================
    // 5) QSPI breakout
    // =========================================================================
    wire [3:0] qspi_io_o, qspi_io_e, qspi_io_i;
    genvar k;
    generate for (k = 0; k < 4; k++) begin : g_qspi
        assign QSPI_IO[k]   = qspi_io_e[k] ? qspi_io_o[k] : 1'bz;
        assign qspi_io_i[k] = QSPI_IO[k];
    end endgenerate

    // =========================================================================
    // 6) Tie-offs
    // =========================================================================
    wire nTRST    = 1'b1;
    wire SWCLKTCK = 1'b0;
    wire SWDITMS  = 1'b0;
    wire TDI      = 1'b0;
    wire TDO, nTDOEN, SWDO, SWDOEN;

    wire [15:0] PAD_P0_IN  = 16'h0000;
    wire [15:0] PAD_P0_OUT, PAD_P0_EN;
    wire [15:0] PAD_P1_IN  = 16'h0000;
    wire [15:0] PAD_P1_OUT, PAD_P1_EN;

    // PL011 (secondary UART)
    wire PL011_nUARTCTS = 1'b1;
    wire PL011_nUARTDCD = 1'b1;
    wire PL011_nUARTDSR = 1'b1;
    wire PL011_nUARTRI  = 1'b1;
    wire PL011_UARTTXD;
    wire PL011_UARTRXD  = PL011_UARTTXD;   // 2026-10-20 (build 52): PL011 loopback TX -> RX, as in the testbench (pl011_uart_tests)
    wire PL011_nUARTOut2, PL011_nUARTOut1, PL011_nUARTRTS, PL011_nUARTDTR;
    assign PL011_TX = PL011_UARTTXD;

    // Direct UART0 bypass
    wire UART0_TXD_DIRECT;
    assign UART_TX = UART0_TXD_DIRECT;

    // 2026-09-01: debug taps on the boot software's own UART TX lines
    // (distinct from DEBUG_UART_TX, our bring-up logger's own dedicated
    // output) - now that ARVALID/RVALID confirm the CPU is genuinely
    // fetching and receiving instruction data from ROM, checking whether
    // the booted software itself ever transmits anything.
    wire uart0_txd_dbg_raw   = UART0_TXD_DIRECT;
    wire pl011_uarttxd_dbg   = PL011_UARTTXD;

    // 2026-09-07: UART0_TXD_DIRECT is not known to be synchronous to `clk`
    // (the debug logger's own sampling clock) - same CDC hazard class as
    // gov_inv_all_req_dbg/scu_ar_block_dbg earlier this session, which
    // caused severe FIFO starvation from raw-tap metastability until a
    // proper 2-flop synchronizer was added. Applying that same fix
    // proactively here instead of re-discovering it the hard way.
    (* ASYNC_REG = "true" *) logic uart0_txd_sync1, uart0_txd_sync2;
    always_ff @(posedge clk) begin
        uart0_txd_sync1 <= uart0_txd_dbg_raw;
        uart0_txd_sync2 <= uart0_txd_sync1;
    end
    wire uart0_txd_dbg = uart0_txd_sync2;
    // 2026-10-01: sticky "a start bit was ever sent" flag. The live TX line
    // toggles far too fast for the logger (it starves everything above it),
    // but one bit of information is all the boot question needs. Resets per
    // boot attempt (nreset_soc). TX idles high; the first low is a start bit.
    logic uart0_tx_ever_low_dbg;
    always_ff @(posedge clk or negedge nreset_soc)
        if (!nreset_soc)           uart0_tx_ever_low_dbg <= 1'b0;
        else if (!uart0_txd_dbg)   uart0_tx_ever_low_dbg <= 1'b1;

    // DDR4 (internal, no controller - terminated by error slave inside)
    wire        DDR4_CK_T, DDR4_CK_C;
    wire [16:0] DDR4_ADR;
    wire [1:0]  DDR4_BA, DDR4_BG;
    wire        DDR4_ACT_n;
    wire [1:0]  DDR4_CKE, DDR4_CS_N, DDR4_ODT;
    wire        DDR_PARITY;
    wire [63:0] DDR4_DQ;
    wire [7:0]  DDR4_DM_DBI_N, DDR4_DQS_T, DDR4_DQS_C;
    wire        DDR4_RESET_N;
    wire        DDR_nALERT = 1'b1;
    wire        DDR_nEVENT = 1'b1;

    // SDIO (not pinned)
    wire        SDIO_CK, SDIO_CMD_tri, SDIO_CMD_o;
    wire        SDIO_CMD_i = 1'b1;
    wire [3:0]  SDIO_DAT_tri, SDIO_DAT_o;
    wire [3:0]  SDIO_DAT_i = 4'hF;
    wire        SD_O_1P8V;

    // =========================================================================
    // 7) SoC instance
    // =========================================================================
    megasoc_chip u_soc (
        .CLK_IN          (clk),
        .RT_CLK          (rt_clk),
        .nRESET          (nreset_soc),

        .QSPI_SCLK      (QSPI_SCLK),
        .QSPI_nCS        (QSPI_nCS),
        .QSPI_IO_o       (qspi_io_o),
        .QSPI_IO_i       (qspi_io_i),
        .QSPI_IO_e       (qspi_io_e),

        .nTRST           (nTRST),
        .SWCLKTCK        (SWCLKTCK),
        .SWDITMS         (SWDITMS),
        .TDI             (TDI),
        .TDO             (TDO),
        .nTDOEN          (nTDOEN),
        .SWDO            (SWDO),
        .SWDOEN          (SWDOEN),

        .PAD_P0_IN       (PAD_P0_IN),
        .PAD_P0_OUT      (PAD_P0_OUT),
        .PAD_P0_EN       (PAD_P0_EN),
        .PAD_P1_IN       (PAD_P1_IN),
        .PAD_P1_OUT      (PAD_P1_OUT),
        .PAD_P1_EN       (PAD_P1_EN),

        .PL011_nUARTCTS  (PL011_nUARTCTS),
        .PL011_nUARTDCD  (PL011_nUARTDCD),
        .PL011_nUARTDSR  (PL011_nUARTDSR),
        .PL011_nUARTRI   (PL011_nUARTRI),
        .PL011_UARTRXD   (PL011_UARTRXD),
        .PL011_UARTTXD   (PL011_UARTTXD),
        .PL011_nUARTOut2 (PL011_nUARTOut2),
        .PL011_nUARTOut1 (PL011_nUARTOut1),
        .PL011_nUARTRTS  (PL011_nUARTRTS),
        .PL011_nUARTDTR  (PL011_nUARTDTR),

        .DDR4_CK_T       (DDR4_CK_T),
        .DDR4_CK_C       (DDR4_CK_C),
        .DDR4_ADR        (DDR4_ADR),
        .DDR4_BA         (DDR4_BA),
        .DDR4_BG         (DDR4_BG),
        .DDR4_ACT_n      (DDR4_ACT_n),
        .DDR4_CKE        (DDR4_CKE),
        .DDR4_CS_N       (DDR4_CS_N),
        .DDR4_ODT        (DDR4_ODT),
        .DDR_PARITY      (DDR_PARITY),
        .DDR4_DQ         (DDR4_DQ),
        .DDR4_DM_DBI_N   (DDR4_DM_DBI_N),
        .DDR4_DQS_T      (DDR4_DQS_T),
        .DDR4_DQS_C      (DDR4_DQS_C),
        .DDR4_RESET_N    (DDR4_RESET_N),
        .DDR_nALERT      (DDR_nALERT),
        .DDR_nEVENT      (DDR_nEVENT),

        .SDIO_CK         (SDIO_CK),
        .SDIO_CMD_tri    (SDIO_CMD_tri),
        .SDIO_CMD_o      (SDIO_CMD_o),
        .SDIO_CMD_i      (SDIO_CMD_i),
        .SDIO_DAT_tri    (SDIO_DAT_tri),
        .SDIO_DAT_o      (SDIO_DAT_o),
        .SDIO_DAT_i      (SDIO_DAT_i),
        .SD_O_1P8V       (SD_O_1P8V),

        .UART0_TXD_DIRECT(UART0_TXD_DIRECT),
        .UART0_RXD_DIRECT(UART_RX)
    );

    // =========================================================================
    // 8) Debug UART event logger - sidesteps the corrupted-at-20MHz ILA/
    //    JTAG path entirely. Same 21 signals u_ila_0 has been probing all
    //    session, tapped by XMR straight into megasoc_tech_wrapper.sv (no
    //    new ports threaded through the hierarchy). One text line per
    //    transition, out DEBUG_UART_TX at 115200 8N1: "TccccIiiIVI\r\n"
    //    where cccc = hex cycle count since nreset_soc release, ii = hex
    //    signal ID below, v = new value.
    //
    //    2026-09-21: IDs 00/01/09 reassigned. 00 now carries the sticky
    //    ARVALID-ever latch (lowest ID = never starved), 01 is reserved by
    //    debug_uart_probe for its own FIFO-overflow flag, and 09 carries
    //    CPU_CORE_PORESETn, displaced from 00. Also note the cycle count
    //    below is 8 hex digits, not 4, and is counted from dbg_resetn
    //    release - NOT from nreset_soc release as this comment used to say.
    //
    // (ID table of 2026-09-21 removed 2026-10-01; the current table is immediately
    //  above the debug_probe_bus assignment below.)
    //
    // 2026-10-02 (build 39): whole-bus logger (debug_uart_probe.sv) and a
    // 16-bit bus of sticky milestone flags and slow levels ONLY; build 40 adds
    // a 16-bit value field on top (bits 31:16). Every line
    // is the complete bus: T<cycle>:<bus hex>=  (or '!' if changes were
    // dropped since the previous line). Per-transaction signals are off the
    // bus on purpose: they toggle every few cycles, fill the FIFO, and have
    // already told us all a UART logger can (ARVALID 9/9, continuous
    // fetching). The parser (haps_parse_logger.py) must match this table.
    //
    //    bit  Signal
    //    0    cpu_axi_arvalid_ever_dbg       sticky: CPU issued a fetch
    //    1    cpu_axi_rvalid_ever_dbg        sticky: CPU received read data
    //    2    rom_rvalid_ever_dbg            sticky: ROM returned data
    //    3    sram_write_ever_dbg            sticky: any SRAM write
    //    4    sram_boot_write_dbg            sticky: boot ROM's first store (..1ff0)
    //    5    flash_ahb_access_ever_dbg      sticky: any access to the QSPI window
    //    6    uart0_apb_write_ever_dbg       sticky: CPU wrote a UART0 register
    //    7    uart0_tx_ever_low_dbg          sticky: UART0 TX sent a start bit
    //    8    CPU_CORE_PORESETn              level
    //    9    ROM_RESETn                     level
    //    10   CPU_L2_RESETn                  level
    //    11   cpu_standbywfi_dbg             level
    //    12   dbg_fetch_far_ever             sticky: CPU read outside the 128 KB ROM window (build 41)
    //    13   dbg_vector_fetch_ever          sticky: instruction fetch from the EL3 vector table (build 41)
    //    14   CPU_CORE_WRMRSTn               level: core warm reset from the PPU (build 41)
    //    15   nreset_soc                     level (boot-cycle marker, top-level reset)
    //    16-31 dbg_val (build 41): {ARPROT[2], ARADDR[16:2]} - the instruction fetch
    //          before the first vector-table fetch (first 50 ms), then the next
    //          CPU read re-sampled every 50 ms. See megasoc_tech_wrapper.sv.
    wire [31:0] debug_probe_bus = {
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.dbg_val,                         // 31:16
        nreset_soc,                                                                    // 15
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.dbg_qspi_apb_ever,              // 14 (build 43: was CPU_CORE_WRMRSTn)
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.dbg_vector_fetch_ever,           // 13 (build 41: was cpu_standbywfil2_dbg)
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.dbg_rd_stuck,                    // 12 (build 44: read outstanding >1.6 ms; build 43: raw level)
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.cpu_standbywfi_dbg,              // 11
        // bit 10 (build 43): was CPU_L2_RESETn, now write-outstanding level; L2 reset proven at +2.1 us
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.dbg_wr_stuck,                    // 10 (build 44: write outstanding >1.6 ms; build 43: raw level)
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.cpu_standbywfe_dbg,              //  9 (build 43: was ROM_RESETn)
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.CPU_CORE_PORESETn,               //  8
        uart0_tx_ever_low_dbg,                                                         //  7
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.uart0_apb_write_ever_dbg,        //  6
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.flash_ahb_access_ever_dbg,       //  5
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.sram_boot_write_dbg,             //  4
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.sram_write_ever_dbg,             //  3
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.rom_rvalid_ever_dbg,             //  2
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.cpu_axi_rvalid_ever_dbg,         //  1
        u_soc.u_megasoc_system.u_megasoc_tech_wrapper.cpu_axi_arvalid_ever_dbg         //  0
    };

    // 2026-08-10: resetn now dbg_resetn (fast, decoupled synchronizer)
    // instead of nreset_soc - see reset-shaping section above for why.
    debug_uart_probe #(
        .CLK_FREQ_HZ  (20_000_000),
        .BAUD_RATE    (115200),
        .NUM_SIGNALS  (32)
    ) u_debug_uart_probe (
        .clk        (clk),
        .resetn     (dbg_resetn),
        .probe_bus  (debug_probe_bus),
        .uart_tx    (DEBUG_UART_TX)
    );

    // -------------------------------------------------------------------------
    // 2026-08-11: ILA removed entirely - debug_uart_probe is the sole debug
    // channel now (JTAG/ILA readback confirmed unreliable at 20MHz all
    // along; kept these as plain wires only because debug_uart_probe's
    // probe_bus references them via XMR).
    // -------------------------------------------------------------------------
    wire debug_uart_tx_dbg      = DEBUG_UART_TX;
    wire debug_uart_tx_run_dbg  = u_debug_uart_probe.tx_running;
    wire debug_uart_fifo_push_dbg = u_debug_uart_probe.fifo_push;
    wire debug_uart_pending_any_dbg = u_debug_uart_probe.pending_any;

endmodule