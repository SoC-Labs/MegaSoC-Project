`ifndef GUARD_SDIO_VIP_CARD_CFG_SV
`define GUARD_SDIO_VIP_CARD_CFG_SV

/**
 * Applies the validated SD-memory operating point to a card agent
 * configuration: SD (not SDIO-function), SDHC capacity, 1-bit bus at
 * config time (the DUT's ACMD6 sequence performs the switch to 4-bit),
 * non-UHS-I signalling, physical layer spec 4.20.
 *
 * This mirrors megasoc_tb.sv's mdl_sdio #(.OPT_HIGH_CAPACITY(1), ...)
 * parameterisation so both verification paths model the same card.
 */
function void apply_sdio_card_cfg(svt_emmc_card_agent_configuration card_cfg);
  card_cfg.card_type         = svt_emmc_types::SD;
  card_cfg.card_capacity     = svt_emmc_types::SDHC;
  card_cfg.serial_bus_width  = 1;
  card_cfg.uhs1_card_support = svt_emmc_types::NON_UHS_I;
  card_cfg.emmc_spec_ver     = svt_emmc_types::SD_4_20;

  /** Per-transaction cmd_xact/rsp_xact reporting from the card monitor --
   *  this is the FSM-level visibility we need for the first real-DUT run,
   *  to tell whether the card agent saw real bus traffic at all. */
  card_cfg.enable_transaction_tracing = 1;
  card_cfg.enable_card_reporting      = 1;
  card_cfg.enable_card_tracing        = 1;
endfunction : apply_sdio_card_cfg

/**
 * Populates the CSD/CID/SCR/OCR register fields the VIP's own protocol
 * checker validates at start_of_simulation_phase (e.g. SDHC density
 * must report >= 2GB per SD Physical Layer Spec 4.20 Section 3.3/4.2.3).
 * Without this, the card_cfg.reg_cfg object is left at its uninitialised
 * default and the VIP raises sd_memory_density_check as a UVM_FATAL at
 * time 0 -- a config validation failure, not an RTL/test failure.
 *
 * Values are taken from the VC-VIP-SOC reference example's
 * emmc_sd_base_test::load_config() (CSD v2.0 fields encode a >= 2GB
 * density), the standard validated way to construct a spec-legal SDHC
 * register set with this VIP. Unrelated to AXI-Lite/RTL driving.
 */
function void apply_sdio_card_reg_cfg(svt_emmc_register_configuration reg_cfg);
  reg_cfg.set_emmc_sd_reg_field(8'd0, svt_emmc_types::SD_CID_REG_MID_B127_B120);
  reg_cfg.set_emmc_sd_reg_field(16'd0,svt_emmc_types::SD_CID_REG_OID_B119_B104);
  reg_cfg.set_emmc_sd_reg_field(40'd0,svt_emmc_types::SD_CID_REG_PNM_B103_B64);
  reg_cfg.set_emmc_sd_reg_field(8'd0, svt_emmc_types::SD_CID_REG_PRV_B63_B56);
  reg_cfg.set_emmc_sd_reg_field(32'd0,svt_emmc_types::SD_CID_REG_PSN_B55_B24);
  reg_cfg.set_emmc_sd_reg_field(4'd0, svt_emmc_types::SD_CID_REG_RSVD_B23_B20);
  reg_cfg.set_emmc_sd_reg_field(12'd0,svt_emmc_types::SD_CID_REG_MDT_B19_B8);
  reg_cfg.set_emmc_sd_reg_field(7'd0, svt_emmc_types::SD_CID_REG_CRC_B7_B1);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_CID_REG_NOT_USED_B1);

  reg_cfg.set_emmc_sd_reg_field(16'd0,svt_emmc_types::SD_RCA_REG_B16_B0);
  reg_cfg.set_emmc_sd_reg_field(16'h404,svt_emmc_types::SD_DSR_REG_B16_B0);

  // CSD Version 2.0 (SDHC/SDXC) -- C_SIZE='h00FFFF gives a multi-GB
  // density, comfortably clearing the >= 2GB SDHC minimum.
  reg_cfg.set_emmc_sd_reg_field(2'd1,            svt_emmc_types::SD_CSD_REG_V2_CSD_STRUCTURE_B127_B126);
  reg_cfg.set_emmc_sd_reg_field(6'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B125_B120);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_TAAC_RSVD_B119);
  reg_cfg.set_emmc_sd_reg_field(4'b0001,         svt_emmc_types::SD_CSD_REG_V2_TAAC_B118_B115);
  reg_cfg.set_emmc_sd_reg_field(3'b110,          svt_emmc_types::SD_CSD_REG_V2_TAAC_B114_B112);
  reg_cfg.set_emmc_sd_reg_field(8'd0,            svt_emmc_types::SD_CSD_REG_V2_NSAC_B111_B104);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_TRAN_SPEED_RSVD_B103);
  reg_cfg.set_emmc_sd_reg_field(4'd6,            svt_emmc_types::SD_CSD_REG_V2_TRAN_SPEED_B102_B99);
  reg_cfg.set_emmc_sd_reg_field(3'd2,            svt_emmc_types::SD_CSD_REG_V2_TRAN_SPEED_B98_B96);
  reg_cfg.set_emmc_sd_reg_field(12'b010110110101,svt_emmc_types::SD_CSD_REG_V2_CCC_B95_B84);
  reg_cfg.set_emmc_sd_reg_field(4'd9,            svt_emmc_types::SD_CSD_REG_V2_READ_BL_LEN_B83_B80);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_READ_BL_PARTIAL_B79);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_WRITE_BLK_MISALIGN_B78);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_READ_BLK_MISALIGN_B77);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_DSR_IMP_B76);
  reg_cfg.set_emmc_sd_reg_field(6'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B75_B70);
  reg_cfg.set_emmc_sd_reg_field(22'h00FFFF,      svt_emmc_types::SD_CSD_REG_V2_C_SIZE_B69_B48);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B47);
  reg_cfg.set_emmc_sd_reg_field(1'd1,            svt_emmc_types::SD_CSD_REG_V2_ERASE_BLK_EN_B46);
  reg_cfg.set_emmc_sd_reg_field(7'h7f,           svt_emmc_types::SD_CSD_REG_V2_ERASE_SECTOR_SIZE_B45_B39);
  reg_cfg.set_emmc_sd_reg_field(7'd0,            svt_emmc_types::SD_CSD_REG_V2_WP_PROTECT_GRP_SIZE_B38_B32);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_WP_PROTECT_GRP_ENABLE_B31);
  reg_cfg.set_emmc_sd_reg_field(2'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B30_B29);
  reg_cfg.set_emmc_sd_reg_field(3'd2,            svt_emmc_types::SD_CSD_REG_V2_R2W_FACTOR_B28_B26);
  reg_cfg.set_emmc_sd_reg_field(4'd9,            svt_emmc_types::SD_CSD_REG_V2_WRITE_BL_LEN_B25_B22);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_WRITE_BL_PARTIAL_B21);
  reg_cfg.set_emmc_sd_reg_field(5'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B20_B16);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_FILE_FORMAT_GRP_B15);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_COPY_B14);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_PERM_WRITE_PROTECT_B13);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_TMP_WRITE_PROTECT_B12);
  reg_cfg.set_emmc_sd_reg_field(2'd0,            svt_emmc_types::SD_CSD_REG_V2_FILE_FORMAT_B11_B10);
  reg_cfg.set_emmc_sd_reg_field(2'd0,            svt_emmc_types::SD_CSD_REG_V2_RSVD_B9_B8);
  reg_cfg.set_emmc_sd_reg_field(7'h0,            svt_emmc_types::SD_CSD_REG_V2_CRC_B7_B1);
  reg_cfg.set_emmc_sd_reg_field(1'd0,            svt_emmc_types::SD_CSD_REG_V2_NOT_USED_B0);

  reg_cfg.set_emmc_sd_reg_field(4'd0,   svt_emmc_types::SD_SCR_REG_SCR_STRUCTURE_B63_B60);
  // SD_SPEC=2 (with SD_SPEC3=1, SD_SPEC4=1 below) is the correct encoding
  // for SD_4_20 per spec Sec-5.6 -- the reference example's load_config()
  // used 4'd11 because its test ran emmc_spec_ver=EMMC_5_0 by default,
  // where this particular consistency check doesn't apply.
  reg_cfg.set_emmc_sd_reg_field(4'd2,   svt_emmc_types::SD_SCR_REG_SD_SPEC_B59_B56);
  reg_cfg.set_emmc_sd_reg_field(1'd0,   svt_emmc_types::SD_SCR_REG_DATA_STAT_AFTER_ERASE_B55);
  reg_cfg.set_emmc_sd_reg_field(3'd2,   svt_emmc_types::SD_SCR_REG_SD_SECURITY_B54_B52);
  reg_cfg.set_emmc_sd_reg_field(1'd0,   svt_emmc_types::SD_SCR_REG_SD_BUS_WIDTH_RSVD_B51);
  reg_cfg.set_emmc_sd_reg_field(1'd1,   svt_emmc_types::SD_SCR_REG_SD_BUS_WIDTH_B50);
  reg_cfg.set_emmc_sd_reg_field(1'd0,   svt_emmc_types::SD_SCR_REG_SD_BUS_WIDTH_RSVD_B49);
  reg_cfg.set_emmc_sd_reg_field(1'd1,   svt_emmc_types::SD_SCR_REG_SD_BUS_WIDTH_B48);
  reg_cfg.set_emmc_sd_reg_field(1'd1,   svt_emmc_types::SD_SCR_REG_SD_SPEC3_B47);
  reg_cfg.set_emmc_sd_reg_field(4'd0,   svt_emmc_types::SD_SCR_REG_EXTN_SECURITY_B46_B43);
  reg_cfg.set_emmc_sd_reg_field(1'd1,   svt_emmc_types::SD_SCR_REG_SD_SPEC4_B42);
  reg_cfg.set_emmc_sd_reg_field(6'd0,   svt_emmc_types::SD_SCR_REG_RSVD_B41_B36);
  reg_cfg.set_emmc_sd_reg_field(4'b1110,svt_emmc_types::SD_SCR_REG_CMD_SUPPORT_B35_B32);
  reg_cfg.set_emmc_sd_reg_field(32'd0,  svt_emmc_types::SD_SCR_REG_RSVD_B31_B0);

  reg_cfg.set_emmc_sd_reg_field(15'd0,svt_emmc_types::SD_OCR_REG_VDD_RSVD_B14_B0);
  reg_cfg.set_emmc_sd_reg_field(1'd1, svt_emmc_types::SD_OCR_REG_VDD_B15_2PT7_2PT8);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B16_2PT8_2PT9);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B17_2PT9_3PT0);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B18_3PT0_3PT1);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B19_3PT1_3PT2);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B20_3PT2_3PT3);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B21_3PT3_3PT4);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B22_3PT4_3PT5);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B23_3PT5_3PT6);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_VDD_B24_SWITCH_1PT8_ACCEPTED);
  reg_cfg.set_emmc_sd_reg_field(4'd0, svt_emmc_types::SD_OCR_REG_RSVD_B25_B28);
  reg_cfg.set_emmc_sd_reg_field(1'd1, svt_emmc_types::SD_OCR_REG_B29_UHS2_CARD_STATUS);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_B30_CARD_CAPACITY_STATUS);
  reg_cfg.set_emmc_sd_reg_field(1'd0, svt_emmc_types::SD_OCR_REG_B31_CARD_POWERUP_STATUS);
endfunction : apply_sdio_card_reg_cfg

`endif // GUARD_SDIO_VIP_CARD_CFG_SV
