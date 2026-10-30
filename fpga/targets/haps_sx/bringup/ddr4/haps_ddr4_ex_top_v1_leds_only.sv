// HAPS-SX VU19P - standalone DDR4 check (MGSOC-34, step 1): the Xilinx DDR4 IP example design (simple traffic generator)
// on the on-board SODIMM. Thin wrapper: the board's push button is active low, the IP's sys_rst is active high;
// the two status outputs drive user LEDs. Generated example_top.sv is left untouched.
module haps_ddr4_ex_top (
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
    example_top u_example_top (
        .sys_rst                (~USER_PB2_n),
        .c0_init_calib_complete (LED_CALIB),
        .c0_data_compare_error  (LED_ERR),
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
endmodule
