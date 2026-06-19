//-----------------------------------------------------------------------------
// tb_pll_clocks.sv  - standalone harness for dwc_ddrphymaster_top
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_pll_clocks;

    localparam real DFICLK_PERIOD_NS = 20.0;   // 50 MHz reference

    reg DfiClk = 1'b0;
    always #(DFICLK_PERIOD_NS/2.0) DfiClk = ~DfiClk;

    reg PwrOk    = 1'b0;
    reg Reset    = 1'b1;   // active high
    reg dfi_rstn = 1'b0;

    initial begin
        #100;
        PwrOk = 1'b1;
        #200;                 // PwrOk leads Reset release
        Reset    = 1'b0;
        dfi_rstn = 1'b1;
        $display("[%0t] TB: PwrOk asserted, Reset released", $time);
    end

    wire pll_clk_c0, pll_clk_c1;
    wire pll_locked, pll_end_of_cal;
    wire VREF;

    dwc_ddrphymaster_top u_dut (
        .PwrOk(PwrOk), .DfiClk(DfiClk), .Reset(Reset), .dfi_reset_n(dfi_rstn),
        .VrefGlobal(VREF), .PwrOkScan_DfiClk(), .MemAlert(),
        .PclkOutC1(pll_clk_c1), .PclkOutC0(pll_clk_c0),
        .VrefOutGlobal(VREF), .PwrOkDlyd_VIO(),
        .BypassPclk(1'b0), .BypassModeEn(2'b00), .BypassOutEn(2'b00),
        .BypassOutData(2'b00), .BypassInData(), .MtestComboOut(),
        .PclkEnAsync(1'b0), .Cmpdig_CmpanaEn(1'b0), .Cmpdig_CalCmpr(1'b0),
        .Cmpdig_CalExt(1'b0), .Cmpdig_CalInt(1'b0), .Cmpdig_CalDac(8'h80),
        .Cmpdig_CalRef(2'b00), .Cmpdig_CmprBiasPowerUp(1'b0), .calDrvMode(4'h0),
        .calDrvPU(12'h000), .calDrvPD(12'h000), .calDrvPdTestValTh(31'd0),
        .calDrvPuTestValTh(31'd0), .CmpAnaClkEn(1'b0), .TxCalThermP(31'd0),
        .TxCalThermN(31'd0), .Cmpana_Out(),
        .PhyInitSync(2'b00), .atpg_lu_ctrl(2'b00), .atpg_se(2'b00),
        .atpg_mode(1'b0), .atpg_Pclk(1'b0), .atpg_si(2'b00), .atpg_so(),
        .csrPclkGateEn(1'b1), .csrPllReset(Reset), .csrPllPwrDn(1'b0),
        .csrPllEnCal(1'b1),
        .csrPllBypassMode(), .csrPllBypSel(), .csrPllOutBypEn(), .csrPllX2Mode(),
        .csrPllForceCal(), .csrPllStandby(), .csrPllPreset(), .csrPllFreqSel(),
        .csrPllMaxRange(), .csrPllLockPhSel(), .csrPllCpIntCtrl(),
        .csrPllCpPropCtrl(), .csrPllCpIntGsCtrl(), .csrPllCpPropGsCtrl(),
        .csrPllGearShift(), .csrPllLockCntSel(), .csrPllSelDfiFreqRatio(),
        .csrPllSpareCtrl0(), .csrPllDacValIn(), .csrPllTestMode(),
        .csrPllDigTstSel(), .csrPllSpare(), .csrPllAnaTstSel(), .csrPllAnaTstEn(),
        .csrPllReserved10x7(),
        .PllDacValOut(), .MiscPhyStatus(), .PllStandbyEff(),
        .PllEndofCal(pll_end_of_cal), .PllLockStatus(pll_locked),
        .csrPllDllLockDone(), .csrUcDctSane(),
        .csrARdPtrInitVal(), .csrMtestMuxSel(), .csrMALERTRxEn(),
        .csrMALERTVrefLevel(), .csrMALERTPuStren(), .csrTestGainCurrAdj(),
        .csrTestBumpEn(), .csrTestMajorMode(), .csrTestAnalogOutCtrl(),
        .csrTxPreOvN(), .csrTxPreOvP(), .csrCmprGainCurrAdj(),
        .csrGlobalVrefInDAC(), .csrGlobalVrefInSel(), .csrMemResetLValue(),
        .csrProtectMemReset(), .csrMALERTVrefExtEn(), .csrMALERTPuEn(),
        .csrCmprGainResAdj(), .csrCmprBiasBypassEn(), .csrTestExtVrefRange(),
        .BP_ZN_SENSE(), .BP_VREF(), .BP_ALERT_N(), .BP_MEMRESET_L(), .BP_ZN()
    );

    always @(posedge pll_end_of_cal) $display("[%0t] TB: PllEndofCal asserted", $time);
    always @(posedge pll_locked)     $display("[%0t] TB: PllLockStatus asserted", $time);

`ifdef PLL_FORCE_LOCK
    `define PLLWRAP       u_dut.PUT_PLLWRAP_INSTANCE_NAME_HERE
    `define PLL_FREQ_SEL  5'd8

    initial begin : tier2_force
        @(negedge Reset);
        #500;
        force `PLLWRAP.csrPllOutBypEn = 1'b0;
        force `PLLWRAP.csrPllFreqSel  = `PLL_FREQ_SEL;
        force `PLLWRAP.csrPllForceCal = 1'b1;
        #200;
        force `PLLWRAP.csrPllForceCal = 1'b0;
        $display("[%0t] TB: Tier-2 force applied (freq_sel=%0d)", $time, `PLL_FREQ_SEL);
    end
`endif

    integer edges;
    real    t_start, t_end, meas_period_ns;

    initial begin : measure
        edges = 0;
`ifdef PLL_FORCE_LOCK
        #5000;
`else
        #1000;
`endif
        t_start = $realtime;
        repeat (200) @(posedge pll_clk_c0) edges = edges + 1;
        t_end = $realtime;
        meas_period_ns = (t_end - t_start) / 200.0;
        $display("[%0t] TB: measured PclkOutC0 = %0.3f ns (%0.2f MHz), locked=%b",
                 $time, meas_period_ns, 1000.0/meas_period_ns, pll_locked);
        $display("[%0t] TB: RESULT = CLOCK PRESENT", $time);
        $finish;
    end

    initial begin : timeout
        #200000;
        $display("[%0t] TB: RESULT = NO CLOCK - PclkOutC0 did not oscillate.", $time);
        $finish;
    end

endmodule
