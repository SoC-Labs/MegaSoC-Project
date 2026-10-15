#-----------------------------------------------------------------------------
# MegaSoC Top-Level Makefile 
# - Includes other Makefiles in flow directory
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# Daniel Newbrook (d.newbrook@soton.ac.uk)
#
# Copyright (C) 2021-4, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
include $(SOCLABS_PROJECT_DIR)/megasoc.config

#-------------------------------------
# - Commonly Overloaded Variables
#-------------------------------------
# Name of test directory - Default Test is Hello World
TESTNAME   ?= hello_world

# Simulator type (mti/vcs/xm)
SIMULATOR   = vcs

# IS this for an ASIC Flow?
ASIC ?= no

# Are simulations to be run in fast mode? (i.e. RAMs preloaded)
FAST_SIM ?= yes

# Include the expansion subsystem?
INC_EXP ?= no

# Include the LPDDR4 DRAM subsystem (megasoc_tech/logical/lpddr4_subsystem)?
INC_LPDDR4 ?= no

ASIC_MEMS ?= no 

ifeq ($(ASIC_MEMS),yes)
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/ARM_CA53_ASICMEMS.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/megasoc_tech_ASICMEMS.flist
	DEFINES_VC += +define+POWER_PINS
else
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/ARM_CA53_BEHAV.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/megasoc_tech_BEHAVMEMS.flist
endif

export ASIC_MEMS

ifeq ($(INC_EXP),yes)
	FLIST_INCLUDES += $(SOCLABS_PROJECT_DIR)/flist/project/expansion.flist
endif

ifeq ($(INC_LPDDR4),yes)
	# RTL selects dram_wrapper (LPDDR4) over the fast sim DRAM responder
	DEFINES_VC += +define+INC_LPDDR4
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/megasoc_tech_LPDDR4.flist
	# filelist_compile.py drops +define+ lines from flists, so take the
	# subsystem's design defines straight from its flist (single source of truth)
	DEFINES_VC += $(shell grep -h '^+define+' $(LPDDR4_PROJECT_DIR)/flist/lpddr4_rtl.vc)
	# LPDDR4 DRAM device model for the testbench (Synopsys LPDDR VIP behind
	# lpddr_model.v), set up as in the subsystem's standalone testbench
	FLIST_INCLUDES += $(LPDDR4_PROJECT_DIR)/flist/lpddr4_mem_model.vc
	DEFINES_VC += $(shell grep -h '^+define+' $(LPDDR4_PROJECT_DIR)/flist/lpddr4_mem_model.vc)
	DEFINES_VC += +define+SYNOPSYS_SV +define+SVT_UVM_TECHNOLOGY +define+SVT_MEM_DPI_OK
	DEFINES_VC += +define+UVM_DISABLE_AUTO_ITEM_RECORDING +define+UVM_PACKER_MAX_BYTES=1500000
endif

export FLIST_INCLUDES



COMPILE_GCC ?= 0
AARCH64 	?= 1
export COMPILE_GCC
export AARCH64
#-------------------------------------
# - Directory Setups
#-------------------------------------
# Directory of Testcodes
TESTCODES_DIR    := $(SOCLABS_MEGASOC_TECH_DIR)/software/src
TESTCODES_BUILD_DIR := $(SOCLABS_MEGASOC_TECH_DIR)/software/build
export TESTCODES_BUILD_DIR

PROJ_SW_DIR		:= $(SOCLABS_PROJECT_DIR)/system/firmware

# Project System Directory
FPGA_IMP_DIR     := $(SOCLABS_PROJECT_DIR)/imp/fpga

# Directory to put simulation files
SIM_TOP_DIR ?= $(SOCLABS_PROJECT_DIR)/simulate/sim
SIM_DIR      = $(SIM_TOP_DIR)/$(TESTNAME)
SIM_BUILD_DIR = $(SIM_TOP_DIR)/build

#-------------------------------------
# - Test List Variables
#-------------------------------------
# List of all tests (this is used when running 'make all/clean')
TEST_LIST_FILE   ?= $(TESTCODES_DIR)/software_list.txt
TEST_LIST         = $(shell cat $(TEST_LIST_FILE) | while read line || [ -n "$$line" ]; do echo $$line; done)

#-------------------------------------
# - Verilog Defines and Filelists
#-------------------------------------
# Simulator/Lint Defines
DEFINES_VC  += +define+CORTEX_A53 +define+USE_TARMAC +define+SDFRONTEND_SPLIT_TRISTATE

# Set Variables depending on whether Expansion subsystem is included
ifeq ($(INC_EXP),yes)
	DEFINES_VC += +define+INC_EXP
	MEGASOC_DEFINES += INC_EXP
endif

ifeq ($(ASIC),yes)
	DESIGN_VC            ?= $(SOCLABS_PROJECT_DIR)/flist/project/top_ASIC.flist
	MEGASOC_DEFINES      += ASIC_TEST_PORTS POWER_PINS
else
	DESIGN_VC            ?= $(SOCLABS_PROJECT_DIR)/flist/project/top_BEHAV.flist
	TBENCH_VC            ?= $(SOCLABS_PROJECT_DIR)/flist/project/top_BEHAV.flist
	TB_TOP               ?= megasoc_tb
endif

FPGA_DESIGN_VC ?= $(SOCLABS_PROJECT_DIR)/flist/project/top_FPGA.flist

# Make variables visible to target shells
export ARM_CORTEX_M0_DIR
export ARM_CORSTONE_101_DIR
export CORTEX_A53_IP_LOGICAL_DIR
export SYNOPSYS_LPDDR4_UMCTL2_DIR
export SYNOPSYS_LPDDR4_multiPHY_DIR
export SYNOPSYS_LPDDR4_multiPHY_LIB_DIR
export FLIST_INCLUDES
export AMS
# Location of Defines File
DEFINES_DIR   := $(SOCLABS_PROJECT_DIR)/system/src/defines/
DEFINES_FILE  := $(DEFINES_DIR)/gen_defines.v

#------------------------------------------
# - Include Makefiles for Specific Flows
#------------------------------------------
# Include Software Compilation Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.software

# Include Linting Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.lint

# Include Simulation Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.simulate

# LPDDR4 memory model: SVT/UVM base classes and the VIP memory server. Added
# after makefile.simulate because that file assigns VCS_OPTIONS with '='.
ifeq ($(INC_LPDDR4),yes)
VCS_OPTIONS    += -ntb_opts uvm $(DESIGNWARE_HOME)/vip/svt/common/latest/C/lib/amd64/libmemserver.so
# Same time settings as the subsystem's standalone flow: 1ns/100fs as the
# default only (not forced), so the LPDDR4 PHY models keep their own timescale.
# Forcing 1ps on them stops the PHY generating the DRAM clock (CK stays X).
VCS_OPTIONS    := $(subst -override_timescale=1ns/1ps,-timescale=1ns/100fs,$(VCS_OPTIONS))
VCS_SIM_OPTION += +ddr_squashz_to_0
# Optional LPDDR4 integration waveform (lpddr4_waves.fsdb in the run folder)
LPDDR4_WAVES ?= no
ifeq ($(LPDDR4_WAVES),yes)
VCS_SIM_OPTION += +LPDDR4_WAVES
endif
endif

# Include Regression Simulation Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.regression

# Include FPGA Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.fpga

# Include Synthesis Makefile
include $(SOCLABS_PROJECT_DIR)/flows/makefile.asic

#------------------------------------------
# - Common Targets Across Flows
#------------------------------------------
# Generate Defines File for MegaSoC
gen_defs:
	@mkdir -p $(DEFINES_DIR)
	@$(SOCLABS_SOCTOOLS_FLOW_DIR)/bin/defines_compile.py -d $(MEGASOC_DEFINES) -o $(DEFINES_FILE)
	
clean_sim:
	@rm -rf ./simulate

make_project:
	make -C ./megasoc_tech make_project

build_ip:
	make -C ./megasoc_tech build_ip

get_flash_model:
	make -C ./megasoc_tech/logical/sl_ahb_qspi get_flash_model

first_time_setup: make_project build_ip get_flash_model

docs:
	pdflatex --output-directory=./doc/tex/ ./doc/tex/megasoc_datasheet.tex
	pdflatex --output-directory=./doc/tex/ ./doc/tex/megasoc_datasheet.tex
	pdflatex --output-directory=./doc/tex/ ./doc/tex/megasoc_configuration_manual.tex
	pdflatex --output-directory=./doc/tex/ ./doc/tex/megasoc_configuration_manual.tex
	mv ./doc/tex/megasoc_datasheet.pdf ./doc/megasoc_datasheet.pdf
	mv ./doc/tex/megasoc_configuration_manual.pdf ./doc/megasoc_configuration_manual.pdf

clean: clean_sim clean_all_code