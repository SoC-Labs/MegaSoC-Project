//-----------------------------------------------------------------------------
// HAPS-SX DDR4 bridge (FPGA bring-up only) - MGSOC-34 step 2
//
// 2026-10-28 (build 58): puts the on-board DDR4 SODIMM (MTA16ATF2G64HZ-2G3, 16 GB, 2 ranks)
// on the NIC-400 "DRAM" port in place of the 512 KB axi4_bram_slave of builds 47-57. Same AXI
// subordinate port list as axi4_bram_slave (minus the flash-emulator backdoor), so it is a
// drop-in replacement in megasoc_tech_wrapper.sv.
//
//   DRAM_AXI (64-bit data, 9-bit ID, 33-bit address, SYS_CLK 20 MHz)
//     -> axi_cc_dram : Xilinx AXI clock converter v2.1, asynchronous (FIFO), 64-bit,
//                      SYS_CLK <-> c0_ddr4_ui_clk (266.5 MHz)
//     -> axi_dw_dram : Xilinx AXI data width converter v2.1, 64 -> 512 bits, single thread
//                      (the IDs are stored and returned in order, the 512-bit side has no ID)
//     -> ddr4_0      : Xilinx DDR4 IP (ddr4 v2.2) configured as in ddr4/README_ddr4_step1.md,
//                      the configuration that calibrated and ran error-free on this board on
//                      28 Oct (step 1): DDR4-2133 (tCK 938 ps), 299.85 MHz reference, 4:1,
//                      CL15/CWL11, DM_NO_DBI, ROW_COLUMN_BANK, AXI 512-bit / 34-bit / ID 1,
//                      narrow bursts on, RD_PRI_REG.
//
// Address: the NIC-400 passes the low 33 address bits unchanged (DRAM window
// 0x8000_0000-0x2_7FFF_FFFF, 8 GB). The IP has 34 (16 GB; with ROW_COLUMN_BANK the rank is
// the top bit). Bit 33 is tied low, so the SoC sees rank 0 = the first 8 GB:
// CPU 0x8000_0000..0x1_FFFF_FFFF -> DRAM 2..8 GB, CPU 0x2_0000_0000..0x2_7FFF_FFFF -> DRAM 0..2 GB.
//
// Resets
//  * DDR4_SYS_RST (active high, asynchronous) resets the IP: MMCM, PHY, calibration (~0.6 s),
//    DRAM contents lost. haps_top drives it from PB1 only - NOT from the SoC reset - so the
//    10 s auto-reset and every monitor 'g' leave the DRAM contents intact. After FPGA
//    configuration the IP calibrates by itself (step 1 showed this, no button needed).
//  * The two converters and the IP's AXI shim (c0_ddr4_aresetn) are held in reset while
//    SoC reset | !calib_complete | ui_clk_sync_rst. One asynchronous source, released through a
//    4-stage synchroniser in each clock domain (PG085: assert both converter resets together).
//    Until calibration completes the SoC side sees AWREADY/ARREADY low: an early DRAM access
//    stalls the CPU instead of failing. Deliberate - the monitor never touches DRAM before the
//    host asks for it, and a DECERR would be mistaken for a bus fault.
//  * DDR4_CALIB_COMPLETE = c0_init_calib_complete (ui_clk domain, level): LED and debug bus.
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
// Contributors: Anastasios Dimitriou (ad1u25@soton.ac.uk)
//-----------------------------------------------------------------------------
module haps_ddr4_bridge #(
    parameter ID_W   = 9,
    parameter DATA_W = 64,
    parameter ADDR_W = 33
)(
    input  wire                  ACLK,          // SYS_CLK (20 MHz)
    input  wire                  ARESETn,       // SoC reset (SYS_RESETn)
    // ---- AXI4 subordinate: NIC-400 DRAM port ----
    input  wire                  AWVALID,
    output wire                  AWREADY,
    input  wire [ID_W-1:0]       AWID,
    input  wire [ADDR_W-1:0]     AWADDR,
    input  wire [7:0]            AWLEN,
    input  wire [2:0]            AWSIZE,
    input  wire [1:0]            AWBURST,
    input  wire                  AWLOCK,
    input  wire [3:0]            AWCACHE,
    input  wire [2:0]            AWPROT,
    input  wire                  WVALID,
    output wire                  WREADY,
    input  wire [DATA_W-1:0]     WDATA,
    input  wire [(DATA_W/8)-1:0] WSTRB,
    input  wire                  WLAST,
    output wire                  BVALID,
    input  wire                  BREADY,
    output wire [ID_W-1:0]       BID,
    output wire [1:0]            BRESP,
    input  wire                  ARVALID,
    output wire                  ARREADY,
    input  wire [ID_W-1:0]       ARID,
    input  wire [ADDR_W-1:0]     ARADDR,
    input  wire [7:0]            ARLEN,
    input  wire [2:0]            ARSIZE,
    input  wire [1:0]            ARBURST,
    input  wire                  ARLOCK,
    input  wire [3:0]            ARCACHE,
    input  wire [2:0]            ARPROT,
    output wire                  RVALID,
    input  wire                  RREADY,
    output wire [ID_W-1:0]       RID,
    output wire [DATA_W-1:0]     RDATA,
    output wire [1:0]            RRESP,
    output wire                  RLAST,
    // ---- DDR4 IP reference clock (AF51/AF52, 299.85 MHz LVDS), reset, status ----
    input  wire                  DDR4_SYS_CLK_P,
    input  wire                  DDR4_SYS_CLK_N,
    input  wire                  DDR4_SYS_RST,
    output wire                  DDR4_CALIB_COMPLETE,
    // ---- DDR4 SODIMM pins (banks 29/30/31) ----
    output wire [1:0]            DDR4_CK_T,
    output wire [1:0]            DDR4_CK_C,
    output wire [16:0]           DDR4_ADR,
    output wire [1:0]            DDR4_BA,
    output wire [1:0]            DDR4_BG,
    output wire                  DDR4_ACT_n,
    output wire [1:0]            DDR4_CKE,
    output wire [1:0]            DDR4_CS_N,
    output wire [1:0]            DDR4_ODT,
    inout  wire [63:0]           DDR4_DQ,
    inout  wire [7:0]            DDR4_DM_DBI_N,
    inout  wire [7:0]            DDR4_DQS_T,
    inout  wire [7:0]            DDR4_DQS_C,
    output wire                  DDR4_RESET_N
);
    localparam IP_ADDR_W = 34;      // ddr4_0 C0.DDR4_AxiAddressWidth
    localparam IP_DATA_W = 512;     // ddr4_0 C0.DDR4_AxiDataWidth

    // ------------------------------------------------------------------------
    // Clocks and resets
    // ------------------------------------------------------------------------
    wire ui_clk;                    // c0_ddr4_ui_clk, 266.5 MHz
    wire ui_rst;                    // c0_ddr4_ui_clk_sync_rst (active high, ui_clk domain)
    wire calib;                     // c0_init_calib_complete (ui_clk domain)
    assign DDR4_CALIB_COMPLETE = calib;

    // ui_clk-domain "memory ready" level, registered so the reset source below is glitch-free
    // with respect to the two ui_clk signals it combines.
    (* ASYNC_REG = "TRUE" *) reg ui_ready = 1'b0;
    always @(posedge ui_clk) ui_ready <= calib & ~ui_rst;

    // One asynchronous reset source for the AXI path: SoC reset or memory not ready.
    wire path_rst_n = ARESETn & ui_ready;

    // Synchronous release in each domain (asynchronous assertion).
    (* ASYNC_REG = "TRUE" *) reg [3:0] s_rst_sync = 4'b0000;   // ACLK domain
    always @(posedge ACLK or negedge path_rst_n)
        if (!path_rst_n) s_rst_sync <= 4'b0000;
        else             s_rst_sync <= {s_rst_sync[2:0], 1'b1};
    wire s_aresetn = s_rst_sync[3];

    (* ASYNC_REG = "TRUE" *) reg [3:0] m_rst_sync = 4'b0000;   // ui_clk domain
    always @(posedge ui_clk or negedge path_rst_n)
        if (!path_rst_n) m_rst_sync <= 4'b0000;
        else             m_rst_sync <= {m_rst_sync[2:0], 1'b1};
    wire m_aresetn = m_rst_sync[3];

    // ------------------------------------------------------------------------
    // 1) Clock converter: SYS_CLK (20 MHz) -> ui_clk, 64-bit, 9-bit ID, 34-bit address
    // ------------------------------------------------------------------------
    wire [ID_W-1:0]       cc_awid, cc_arid, cc_bid, cc_rid;
    wire [IP_ADDR_W-1:0]  cc_awaddr, cc_araddr;
    wire [7:0]            cc_awlen, cc_arlen;
    wire [2:0]            cc_awsize, cc_arsize, cc_awprot, cc_arprot;
    wire [1:0]            cc_awburst, cc_arburst, cc_bresp, cc_rresp;
    wire                  cc_awlock, cc_arlock;
    wire [3:0]            cc_awcache, cc_arcache, cc_awqos, cc_arqos, cc_awregion, cc_arregion;
    wire                  cc_awvalid, cc_awready, cc_wvalid, cc_wready, cc_wlast;
    wire                  cc_bvalid, cc_bready, cc_arvalid, cc_arready, cc_rvalid, cc_rready, cc_rlast;
    wire [DATA_W-1:0]     cc_wdata, cc_rdata;
    wire [DATA_W/8-1:0]   cc_wstrb;

    axi_cc_dram u_axi_cc (
        .s_axi_aclk(ACLK), .s_axi_aresetn(s_aresetn),
        .s_axi_awid(AWID), .s_axi_awaddr({1'b0, AWADDR}), .s_axi_awlen(AWLEN), .s_axi_awsize(AWSIZE),
        .s_axi_awburst(AWBURST), .s_axi_awlock(AWLOCK), .s_axi_awcache(AWCACHE), .s_axi_awprot(AWPROT),
        .s_axi_awregion(4'h0), .s_axi_awqos(4'h0), .s_axi_awvalid(AWVALID), .s_axi_awready(AWREADY),
        .s_axi_wdata(WDATA), .s_axi_wstrb(WSTRB), .s_axi_wlast(WLAST), .s_axi_wvalid(WVALID), .s_axi_wready(WREADY),
        .s_axi_bid(BID), .s_axi_bresp(BRESP), .s_axi_bvalid(BVALID), .s_axi_bready(BREADY),
        .s_axi_arid(ARID), .s_axi_araddr({1'b0, ARADDR}), .s_axi_arlen(ARLEN), .s_axi_arsize(ARSIZE),
        .s_axi_arburst(ARBURST), .s_axi_arlock(ARLOCK), .s_axi_arcache(ARCACHE), .s_axi_arprot(ARPROT),
        .s_axi_arregion(4'h0), .s_axi_arqos(4'h0), .s_axi_arvalid(ARVALID), .s_axi_arready(ARREADY),
        .s_axi_rid(RID), .s_axi_rdata(RDATA), .s_axi_rresp(RRESP), .s_axi_rlast(RLAST), .s_axi_rvalid(RVALID), .s_axi_rready(RREADY),
        .m_axi_aclk(ui_clk), .m_axi_aresetn(m_aresetn),
        .m_axi_awid(cc_awid), .m_axi_awaddr(cc_awaddr), .m_axi_awlen(cc_awlen), .m_axi_awsize(cc_awsize),
        .m_axi_awburst(cc_awburst), .m_axi_awlock(cc_awlock), .m_axi_awcache(cc_awcache), .m_axi_awprot(cc_awprot),
        .m_axi_awregion(cc_awregion), .m_axi_awqos(cc_awqos), .m_axi_awvalid(cc_awvalid), .m_axi_awready(cc_awready),
        .m_axi_wdata(cc_wdata), .m_axi_wstrb(cc_wstrb), .m_axi_wlast(cc_wlast), .m_axi_wvalid(cc_wvalid), .m_axi_wready(cc_wready),
        .m_axi_bid(cc_bid), .m_axi_bresp(cc_bresp), .m_axi_bvalid(cc_bvalid), .m_axi_bready(cc_bready),
        .m_axi_arid(cc_arid), .m_axi_araddr(cc_araddr), .m_axi_arlen(cc_arlen), .m_axi_arsize(cc_arsize),
        .m_axi_arburst(cc_arburst), .m_axi_arlock(cc_arlock), .m_axi_arcache(cc_arcache), .m_axi_arprot(cc_arprot),
        .m_axi_arregion(cc_arregion), .m_axi_arqos(cc_arqos), .m_axi_arvalid(cc_arvalid), .m_axi_arready(cc_arready),
        .m_axi_rid(cc_rid), .m_axi_rdata(cc_rdata), .m_axi_rresp(cc_rresp), .m_axi_rlast(cc_rlast), .m_axi_rvalid(cc_rvalid), .m_axi_rready(cc_rready)
    );

    // ------------------------------------------------------------------------
    // 2) Data width converter: 64 -> 512 bits at ui_clk. No ID on its 512-bit side.
    // ------------------------------------------------------------------------
    wire [IP_ADDR_W-1:0]  dw_awaddr, dw_araddr;
    wire [7:0]            dw_awlen, dw_arlen;
    wire [2:0]            dw_awsize, dw_arsize, dw_awprot, dw_arprot;
    wire [1:0]            dw_awburst, dw_arburst, dw_bresp, dw_rresp;
    wire                  dw_awlock, dw_arlock;
    wire [3:0]            dw_awcache, dw_arcache, dw_awqos, dw_arqos, dw_awregion, dw_arregion;
    wire                  dw_awvalid, dw_awready, dw_wvalid, dw_wready, dw_wlast;
    wire                  dw_bvalid, dw_bready, dw_arvalid, dw_arready, dw_rvalid, dw_rready, dw_rlast;
    wire [IP_DATA_W-1:0]  dw_wdata, dw_rdata;
    wire [IP_DATA_W/8-1:0] dw_wstrb;

    axi_dw_dram u_axi_dw (
        .s_axi_aclk(ui_clk), .s_axi_aresetn(m_aresetn),
        .s_axi_awid(cc_awid), .s_axi_awaddr(cc_awaddr), .s_axi_awlen(cc_awlen), .s_axi_awsize(cc_awsize),
        .s_axi_awburst(cc_awburst), .s_axi_awlock(cc_awlock), .s_axi_awcache(cc_awcache), .s_axi_awprot(cc_awprot),
        .s_axi_awregion(cc_awregion), .s_axi_awqos(cc_awqos), .s_axi_awvalid(cc_awvalid), .s_axi_awready(cc_awready),
        .s_axi_wdata(cc_wdata), .s_axi_wstrb(cc_wstrb), .s_axi_wlast(cc_wlast), .s_axi_wvalid(cc_wvalid), .s_axi_wready(cc_wready),
        .s_axi_bid(cc_bid), .s_axi_bresp(cc_bresp), .s_axi_bvalid(cc_bvalid), .s_axi_bready(cc_bready),
        .s_axi_arid(cc_arid), .s_axi_araddr(cc_araddr), .s_axi_arlen(cc_arlen), .s_axi_arsize(cc_arsize),
        .s_axi_arburst(cc_arburst), .s_axi_arlock(cc_arlock), .s_axi_arcache(cc_arcache), .s_axi_arprot(cc_arprot),
        .s_axi_arregion(cc_arregion), .s_axi_arqos(cc_arqos), .s_axi_arvalid(cc_arvalid), .s_axi_arready(cc_arready),
        .s_axi_rid(cc_rid), .s_axi_rdata(cc_rdata), .s_axi_rresp(cc_rresp), .s_axi_rlast(cc_rlast), .s_axi_rvalid(cc_rvalid), .s_axi_rready(cc_rready),
        .m_axi_awaddr(dw_awaddr), .m_axi_awlen(dw_awlen), .m_axi_awsize(dw_awsize),
        .m_axi_awburst(dw_awburst), .m_axi_awlock(dw_awlock), .m_axi_awcache(dw_awcache), .m_axi_awprot(dw_awprot),
        .m_axi_awregion(dw_awregion), .m_axi_awqos(dw_awqos), .m_axi_awvalid(dw_awvalid), .m_axi_awready(dw_awready),
        .m_axi_wdata(dw_wdata), .m_axi_wstrb(dw_wstrb), .m_axi_wlast(dw_wlast), .m_axi_wvalid(dw_wvalid), .m_axi_wready(dw_wready),
        .m_axi_bresp(dw_bresp), .m_axi_bvalid(dw_bvalid), .m_axi_bready(dw_bready),
        .m_axi_araddr(dw_araddr), .m_axi_arlen(dw_arlen), .m_axi_arsize(dw_arsize),
        .m_axi_arburst(dw_arburst), .m_axi_arlock(dw_arlock), .m_axi_arcache(dw_arcache), .m_axi_arprot(dw_arprot),
        .m_axi_arregion(dw_arregion), .m_axi_arqos(dw_arqos), .m_axi_arvalid(dw_arvalid), .m_axi_arready(dw_arready),
        .m_axi_rdata(dw_rdata), .m_axi_rresp(dw_rresp), .m_axi_rlast(dw_rlast), .m_axi_rvalid(dw_rvalid), .m_axi_rready(dw_rready)
    );

    // ------------------------------------------------------------------------
    // 3) DDR4 IP. AXI address bit 33 (rank) forced to 0 -> rank 0 = first 8 GB.
    // ------------------------------------------------------------------------
    ddr4_0 u_ddr4_0 (
        .sys_rst(DDR4_SYS_RST),
        .c0_sys_clk_p(DDR4_SYS_CLK_P), .c0_sys_clk_n(DDR4_SYS_CLK_N),
        .c0_init_calib_complete(calib),
        .c0_ddr4_ui_clk(ui_clk), .c0_ddr4_ui_clk_sync_rst(ui_rst),
        .c0_ddr4_aresetn(m_aresetn),
        .dbg_clk(), .dbg_bus(),
        // DRAM pins
        .c0_ddr4_adr(DDR4_ADR), .c0_ddr4_ba(DDR4_BA), .c0_ddr4_bg(DDR4_BG), .c0_ddr4_act_n(DDR4_ACT_n),
        .c0_ddr4_cke(DDR4_CKE), .c0_ddr4_cs_n(DDR4_CS_N), .c0_ddr4_odt(DDR4_ODT),
        .c0_ddr4_ck_t(DDR4_CK_T), .c0_ddr4_ck_c(DDR4_CK_C), .c0_ddr4_reset_n(DDR4_RESET_N),
        .c0_ddr4_dq(DDR4_DQ), .c0_ddr4_dm_dbi_n(DDR4_DM_DBI_N), .c0_ddr4_dqs_t(DDR4_DQS_T), .c0_ddr4_dqs_c(DDR4_DQS_C),
        // AXI4 slave, 512-bit, ID width 1
        .c0_ddr4_s_axi_awid(1'b0), .c0_ddr4_s_axi_awaddr({1'b0, dw_awaddr[IP_ADDR_W-2:0]}), .c0_ddr4_s_axi_awlen(dw_awlen),
        .c0_ddr4_s_axi_awsize(dw_awsize), .c0_ddr4_s_axi_awburst(dw_awburst), .c0_ddr4_s_axi_awlock(dw_awlock),
        .c0_ddr4_s_axi_awcache(dw_awcache), .c0_ddr4_s_axi_awprot(dw_awprot), .c0_ddr4_s_axi_awqos(dw_awqos),
        .c0_ddr4_s_axi_awvalid(dw_awvalid), .c0_ddr4_s_axi_awready(dw_awready),
        .c0_ddr4_s_axi_wdata(dw_wdata), .c0_ddr4_s_axi_wstrb(dw_wstrb), .c0_ddr4_s_axi_wlast(dw_wlast),
        .c0_ddr4_s_axi_wvalid(dw_wvalid), .c0_ddr4_s_axi_wready(dw_wready),
        .c0_ddr4_s_axi_bid(), .c0_ddr4_s_axi_bresp(dw_bresp), .c0_ddr4_s_axi_bvalid(dw_bvalid), .c0_ddr4_s_axi_bready(dw_bready),
        .c0_ddr4_s_axi_arid(1'b0), .c0_ddr4_s_axi_araddr({1'b0, dw_araddr[IP_ADDR_W-2:0]}), .c0_ddr4_s_axi_arlen(dw_arlen),
        .c0_ddr4_s_axi_arsize(dw_arsize), .c0_ddr4_s_axi_arburst(dw_arburst), .c0_ddr4_s_axi_arlock(dw_arlock),
        .c0_ddr4_s_axi_arcache(dw_arcache), .c0_ddr4_s_axi_arprot(dw_arprot), .c0_ddr4_s_axi_arqos(dw_arqos),
        .c0_ddr4_s_axi_arvalid(dw_arvalid), .c0_ddr4_s_axi_arready(dw_arready),
        .c0_ddr4_s_axi_rid(), .c0_ddr4_s_axi_rdata(dw_rdata), .c0_ddr4_s_axi_rresp(dw_rresp), .c0_ddr4_s_axi_rlast(dw_rlast),
        .c0_ddr4_s_axi_rvalid(dw_rvalid), .c0_ddr4_s_axi_rready(dw_rready)
    );
endmodule
