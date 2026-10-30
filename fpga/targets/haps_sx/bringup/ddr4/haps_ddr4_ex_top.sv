// HAPS-SX VU19P - standalone DDR4 check (MGSOC-34, step 1): the Xilinx DDR4 IP example design (simple traffic generator)
// on the on-board SODIMM. Thin wrapper around the untouched generated example_top.sv:
//  - the board's push button is active low, the IP's sys_rst is active high;
//  - v2: a VIO (JTAG) reads calibration-complete, data-compare-error and a heartbeat, and can assert the IP reset, so the
//    whole check works from the hardware manager on srv03335 without seeing the LEDs or pressing the button. The VIO is
//    clocked from the board's 20 MHz GCLK1, which ConfPro supplies independently of the bitstream.
module haps_ddr4_ex_top (
    input  wire        HAPS_CLK_IN_P,     // GCLK1 20 MHz, bank 20 (BM44/BN44), LVDS - VIO clock only
    input  wire        HAPS_CLK_IN_N,
    input  wire        USER_PB2_n,        // bank 20, active low
    output wire        LED_CALIB,         // bank 83: c0_init_calib_complete
    output wire        LED_ERR,           // bank 83: c0_data_compare_error
    input  wire        c0_sys_clk_p,      // 299.85 MHz reference, bank 30 (AF51/AF52)
    input  wire        c0_sys_clk_n,
    output wire        c0_ddr4_act_n,
    output wire [16:0] c0_ddr4_adr,
    output wire [1:0]  c0_ddr4_ba,
    output wire [1:0]  c0_ddr4_bg,
    output wire [1:0]  c0_ddr4_cke,
    output wire [1:0]  c0_ddr4_odt,
    output wire [1:0]  c0_ddr4_cs_n,
    output wire [1:0]  c0_ddr4_ck_t,
    output wire [1:0]  c0_ddr4_ck_c,
    output wire        c0_ddr4_reset_n,
    inout  wire [7:0]  c0_ddr4_dm_dbi_n,
    inout  wire [63:0] c0_ddr4_dq,
    inout  wire [7:0]  c0_ddr4_dqs_t,
    inout  wire [7:0]  c0_ddr4_dqs_c
);
    wire clk20_ibuf, clk20;
    IBUFDS u_ibufds_clk20 (.I(HAPS_CLK_IN_P), .IB(HAPS_CLK_IN_N), .O(clk20_ibuf));
    BUFG   u_bufg_clk20   (.I(clk20_ibuf), .O(clk20));

    reg [24:0] hb_cnt = 25'd0;                 // 20 MHz / 2^25 = 0.6 Hz heartbeat visible in the VIO
    always @(posedge clk20) hb_cnt <= hb_cnt + 25'd1;

    wire calib, err, jtag_rst;
    (* ASYNC_REG = "true" *) reg [1:0] calib_s = 2'b00, err_s = 2'b00;   // UI-clock status bits sampled at 20 MHz
    always @(posedge clk20) begin calib_s <= {calib_s[0], calib}; err_s <= {err_s[0], err}; end

    vio_0 u_vio (
        .clk        (clk20),
        .probe_in0  (calib_s[1]),              // 1 = DDR4 calibration complete
        .probe_in1  (err_s[1]),                // 1 = traffic generator saw a data compare error (sticky in the TG)
        .probe_in2  (hb_cnt[24]),              // toggles ~0.6 Hz: proves GCLK1 and the VIO are alive
        .probe_out0 (jtag_rst)                 // 1 = hold the IP in reset (re-calibrates on release); initial 0
    );

    example_top u_example_top (
        .sys_rst                (~USER_PB2_n | jtag_rst),
        .c0_init_calib_complete (calib),
        .c0_data_compare_error  (err),
        .c0_sys_clk_p           (c0_sys_clk_p),
        .c0_sys_clk_n           (c0_sys_clk_n),
        .c0_ddr4_act_n          (c0_ddr4_act_n),
        .c0_ddr4_adr            (c0_ddr4_adr),
        .c0_ddr4_ba             (c0_ddr4_ba),
        .c0_ddr4_bg             (c0_ddr4_bg),
        .c0_ddr4_cke            (c0_ddr4_cke),
        .c0_ddr4_odt            (c0_ddr4_odt),
        .c0_ddr4_cs_n           (c0_ddr4_cs_n),
        .c0_ddr4_ck_t           (c0_ddr4_ck_t),
        .c0_ddr4_ck_c           (c0_ddr4_ck_c),
        .c0_ddr4_reset_n        (c0_ddr4_reset_n),
        .c0_ddr4_dm_dbi_n       (c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq             (c0_ddr4_dq),
        .c0_ddr4_dqs_t          (c0_ddr4_dqs_t),
        .c0_ddr4_dqs_c          (c0_ddr4_dqs_c)
    );
    assign LED_CALIB = calib;
    assign LED_ERR   = err;
endmodule
