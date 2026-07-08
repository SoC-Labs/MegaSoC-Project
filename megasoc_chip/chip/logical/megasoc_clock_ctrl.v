

module megasoc_clock_ctrl(
    input  wire         CLK_IN,
    input  wire         PORESTn,

    input  wire [31:0]  PADDR,
    input  wire [31:0]  PWDATA,
    input  wire         PWRITE,
    input  wire [2:0]   PPROT,
    input  wire [3:0]   PSTRB,
    input  wire         PENABLE,
    input  wire         PSELx,
    output wire [31:0]  PRDATA,
    output wire         PSLVERR,
    output wire         PREADY,

    output wire         SYS_CLK,
    output wire         CPU_CLK,
    output wire         FLASH_CLK
);

reg clock_sys;
reg clock_cpu;
reg clock_flash;

assign SYS_CLK = clock_sys;
assign CPU_CLK = clock_cpu;
assign FLASH_CLK = clock_flash;

initial
begin
    clock_sys   <= 1'b0;
    clock_cpu  <= 1'b0;
    clock_flash <= 1'b0;
    #40 clock_sys <= 1'b1;
    clock_cpu <= 1'b1;
end

always @(clock_sys) 
    #1 clock_sys <= !clock_sys;  // 2ns period, 500MHz

always @(clock_cpu)
    #5 clock_cpu <= !clock_cpu; // 10ns period, 100MHz -- matches the CPU_CLK base sdiodrv.c's SDIOCK_* divisor table assumes (sdio.v:69)

always @(clock_flash)
    #2 clock_flash <= !clock_flash; // 4ns period 250MHz

wire VREF;

dwc_ddrphymaster_top u_pll(
    // Interface to global signals
        .PwrOk(1'b1),
        .DfiClk(CLK_IN),
        .Reset(~PORESTn),
        .dfi_reset_n(PORESTn),
        .VrefGlobal(VREF),

        .PwrOkScan_DfiClk(),
        .MemAlert(),
        .PclkOutC1(),
        .PclkOutC0(),
        .VrefOutGlobal(VREF),
        .PwrOkDlyd_VIO(),

    // Asynchronous IO Test Signals
        .BypassPclk(1'b0),
        .BypassModeEn(2'b00),
        .BypassOutEn(2'b00),
        .BypassOutData(2'b00),

        .BypassInData(),
        .MtestComboOut(),

    // Asynchronous Calibration Signals
        .PclkEnAsync(1'b0),
        .Cmpdig_CmpanaEn(1'b0),
        .Cmpdig_CalCmpr(1'b0),
        .Cmpdig_CalExt(1'b0),
        .Cmpdig_CalInt(1'b0),
        .Cmpdig_CalDac(8'h80),
        .Cmpdig_CalRef(2'b00),
        .Cmpdig_CmprBiasPowerUp(1'b0),
        .calDrvMode(4'h0),
        .calDrvPU(12'h000),
        .calDrvPD(12'h000),
        .calDrvPdTestValTh(31'd0),
        .calDrvPuTestValTh(31'd0),
        .CmpAnaClkEn(1'b0),
        .TxCalThermP(31'd0),
        .TxCalThermN(31'd0),

        .Cmpana_Out(),

    // Interface to ATPG Mode signals
        .PhyInitSync(2'b00),
        .atpg_lu_ctrl(2'b00),
        .atpg_se(2'b00),
        .atpg_mode(1'b0),
        .atpg_Pclk(1'b0),
        .atpg_si(2'b00),
        .atpg_so(),

    // Interface to Configuration Signals
        .csrPclkGateEn(1'b1),
        .csrPllReset(~PORESTn),
        .csrPllPwrDn(1'b0),
        .csrPllEnCal(1'b1),
        .csrPllBypassMode(),
        .csrPllBypSel(),
        .csrPllOutBypEn(),
        .csrPllX2Mode(),
        .csrPllForceCal(),
        .csrPllStandby(),
        .csrPllPreset(),
        .csrPllFreqSel(),
        .csrPllMaxRange(),
        .csrPllLockPhSel(),
        .csrPllCpIntCtrl(),
        .csrPllCpPropCtrl(),
        .csrPllCpIntGsCtrl(),
        .csrPllCpPropGsCtrl(),
        .csrPllGearShift(),
        .csrPllLockCntSel(),
        .csrPllSelDfiFreqRatio(),
        .csrPllSpareCtrl0(),
        .csrPllDacValIn(),
        .csrPllTestMode(),
        .csrPllDigTstSel(),
        .csrPllSpare(),
        .csrPllAnaTstSel(),
        .csrPllAnaTstEn(),
        .csrPllReserved10x7(),
        .PllDacValOut(),
        .MiscPhyStatus(),
        .PllStandbyEff(),
        .PllEndofCal(pll_end_of_cal),
        .PllLockStatus(pll_locked),
        .csrPllDllLockDone(),
        .csrUcDctSane(),
        .csrARdPtrInitVal(),
        .csrMtestMuxSel(),
        .csrMALERTRxEn(),
        .csrMALERTVrefLevel(),
        .csrMALERTPuStren(),
        .csrTestGainCurrAdj(),
        .csrTestBumpEn(),
        .csrTestMajorMode(),
        .csrTestAnalogOutCtrl(),
        .csrTxPreOvN(),
        .csrTxPreOvP(),
        .csrCmprGainCurrAdj(),
        .csrGlobalVrefInDAC(),
        .csrGlobalVrefInSel(),
        .csrMemResetLValue(),
        .csrProtectMemReset(),
        .csrMALERTVrefExtEn(),
        .csrMALERTPuEn(),
        .csrCmprGainResAdj(),
        .csrCmprBiasBypassEn(),
        .csrTestExtVrefRange(),

    // Interface to SDRAM Signals
        .BP_ZN_SENSE(),
        .BP_VREF(),
        .BP_ALERT_N(),
        .BP_MEMRESET_L(),
        .BP_ZN()

);

endmodule
