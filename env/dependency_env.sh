#-----------------------------------------------------------------------------
# SoC Labs Dependency Repository Environment Setup Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
#!/bin/bash

#-----------------------------------------------------------------------------
# Technologies
#-----------------------------------------------------------------------------

# MegaSoC Tech
export SOCLABS_MEGASOC_TECH_DIR="$SOCLABS_PROJECT_DIR/megasoc_tech"

# MegaSoC Expansion Tech
export SOCLABS_MEGASOC_EXP_TECH_DIR="$SOCLABS_PROJECT_DIR/expansion_subsystem_tech"

#-----------------------------------------------------------------------------
# Flows
#-----------------------------------------------------------------------------

# SoCTools - Toolkit of scripts related to SoCLabs projects
export SOCLABS_SOCTOOLS_FLOW_DIR="$SOCLABS_PROJECT_DIR/soctools_flow"

export SOCLABS_AHB_QSPI_DIR="$SOCLABS_MEGASOC_TECH_DIR/logical/sl_ahb_qspi"

# LPDDR4 DRAM subsystem (controller + PHY integration) -- nested submodule of
# megasoc_tech. LPDDR4_PROJECT_DIR is the name its own flists expand.
export SOCLABS_LPDDR4_DIR="$SOCLABS_MEGASOC_TECH_DIR/logical/lpddr4_subsystem"
export LPDDR4_PROJECT_DIR="$SOCLABS_LPDDR4_DIR"

# Ethernet subsystem (Ethernet-MAC-AHB, ethmac_subsystem_apb) -- nested
# submodule of megasoc_tech, used by INC_ETH builds. The OpenCores ethmac and
# HA1588 sources it builds on are not in the submodule; these are the shared
# copies on this server (external users: OpenCores ethmac rel27 / ha1588).
export SOCLABS_ETHMAC_AHB_DIR="$SOCLABS_MEGASOC_TECH_DIR/logical/ethernet_mac_ahb"
export ETHMAC_IP_DIR="${ETHMAC_IP_DIR:-/research/AAA/ip_library/OpenCores-EthMAC}"
export HA1588_IP_DIR="${HA1588_IP_DIR:-/research/AAA/ip_library/OpenCores-HA1588}"

# SoCLabs ASIC FLow - toolkit of scripts related to ASIC implementatino
export SOCLABS_ASIC_FLOW_DIR="$SOCLABS_PROJECT_DIR/asic_flow"

# Synopsys VC-VIP-SOC eMMC/SD card VIP -- required by the SDIO VIP testbench
# (see flist/project/uvm_vip_tb.flist); shared install on this server, same
# path for every user.
export DESIGNWARE_HOME=/eda/synopsys/2022-23/RHELx86/VC-VIP-SOC_2022.12