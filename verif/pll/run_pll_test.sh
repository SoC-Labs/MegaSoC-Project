#!/usr/bin/env bash
#-----------------------------------------------------------------------------
# run_pll_test.sh
# Standalone behavioural check that the Synopsys LPDDR4 PHY master block
# (dwc_ddrphymaster_top) emits a clock on PclkOutC0. Deliberately bypasses the
# full UVM/VIP + Verdi flow: compiles only the PHY RTL plus tb_pll_clocks.
#
# Expected: PclkOutC0 ~= DfiClk reference (50 MHz), locked=0  -> CLOCK PRESENT
#   (PLL bypass passthrough; the locked/multiplied output needs the PLL
#    frequency CSRs programmed, normally by PHY PMU firmware.)
#-----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -z "${SYNOPSYS_LPDDR4_multiPHY_LIB_DIR:-}" ]; then
  SYNOPSYS_LPDDR4_multiPHY_LIB_DIR="$(grep -E '^[[:space:]]*SYNOPSYS_LPDDR4_multiPHY_LIB_DIR[[:space:]]*[?:]?=' \
    "$PROJ_ROOT/megasoc.config" | head -1 | sed -E 's/^[^=]*=[[:space:]]*//')"
fi
export SYNOPSYS_LPDDR4_multiPHY_LIB_DIR
if [ ! -d "$SYNOPSYS_LPDDR4_multiPHY_LIB_DIR" ]; then
  echo "ERROR: SYNOPSYS_LPDDR4_multiPHY_LIB_DIR not found: '$SYNOPSYS_LPDDR4_multiPHY_LIB_DIR'"
  echo "       Export it to the LPDDR4 multiPHY IP 'Latest' dir and re-run."
  exit 1
fi

BEHAV_FLIST="$PROJ_ROOT/megasoc_tech/flist/IP/Synopsys_LPDDR4PHY_BEHAV.flist"
[ -f "$BEHAV_FLIST" ] || { echo "ERROR: missing $BEHAV_FLIST (is the megasoc_tech submodule initialised?)"; exit 1; }

WORK="$(mktemp -d)"
TRIM_FLIST="$WORK/pll_phy_only.flist"

sed '/CTB_VIP_HOME/,$d' "$BEHAV_FLIST" > "$TRIM_FLIST"
sed -i "s|\$(SYNOPSYS_LPDDR4_multiPHY_LIB_DIR)|${SYNOPSYS_LPDDR4_multiPHY_LIB_DIR}|g" "$TRIM_FLIST"

cd "$WORK"
vcs -full64 -sverilog +v2k -override_timescale=1ns/1ps \
  +define+INC_SYNOPSYS_LPDDR4 +define+DWC_DDRPHY_NUM_DBYTES_2 +define+DWC_DDRPHY_NUM_ANIBS_3 \
  +define+DWC_DDRPHY_CUST_PHYREV=0 +define+DWC_DDRPHY_CUST_PUBREV=0 +define+DWC_PUB_RID=9248 \
  +define+DWC_DDRPHY_NUM_TOP_SCAN_CHAINS=110 +define+DWC_DDRPHY_NO_PG_PINS \
  +define+DWC_DDRPHY_TECH__CDCBUF__DISABLE_BEHAVIORAL_VERILOG +define+DWC_DDRPHY_FIXED_DFICTLCLK_RATIO \
  +define+DWC_DDRPHY_HWEMUL +define+DWC_DDRPHY_HWEMUL_SIM +define+DWC_DDRPHY_SIMPLE_MODEL \
  +define+DWC_DDRPHY_DRVBE_SIMPLE +define+DWC_DDRPHY_HWEMUL_CGRC +define+DWC_DDRPHY_MODEL_ASYNCMSFLOP_AS_DFF \
  -f "$TRIM_FLIST" "$SCRIPT_DIR/tb_pll_clocks.sv" \
  -top tb_pll_clocks -o simv_pll -l comp_pll.log

./simv_pll -l run_pll.log
echo "----"
echo "Logs: $WORK/comp_pll.log , $WORK/run_pll.log"
