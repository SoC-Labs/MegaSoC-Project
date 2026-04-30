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

ASIC_MEMS ?= no 

ifeq ($(ASIC_MEMS),yes)
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/ARM_CA53_ASICMEMS.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/megasoc_tech_ASICMEMS.flist
	MEGASOC_DEFINES += ASIC_MEMS
else
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/ARM_CA53_BEHAV.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/megasoc_tech_BEHAVMEMS.flist
endif

export ASIC_MEMS

ifeq ($(INC_EXP),yes)
	FLIST_INCLUDES += $(SOCLABS_PROJECT_DIR)/flist/project/expansion.flist
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
DEFINES_VC  += +define+CORTEX_A53 

ifeq ($(ASIC),no)
	DEFINES_VC += +define+USE_TARMAC 
endif

export INC_SYNOPSYS_LPDDR4
export SYNOPSYS_LPDDR4_UMCTL2_DIR
export SYNOPSYS_LPDDR4_multiPHY_DIR
export SYNOPSYS_LPDDR4_multiPHY_LIB_DIR
export CTB_VIP_HOME

ifeq ($(INC_SYNOPSYS_LPDDR4),yes)
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/Synopsys_uMCTL2.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/Synopsys_LPDDR4PHY.flist
	FLIST_INCLUDES += $(SOCLABS_MEGASOC_TECH_DIR)/flist/IP/Synopsys_LPDDR4PHY_BEHAV.flist

	DEFINES_VC += +define+INC_SYNOPSYS_LPDDR4   
	ifeq ($(ASIC),no)
		DEFINES_VC += +define+LP4_STD +define+DFI_MODE1 +define+LPDDR4 +define+lpddr4_proc
		DEFINES_VC += +define+UVM_DISABLE_AUTO_ITEM_RECORDING +define+UVM_PACKER_MAX_BYTES=1500000 +define+DFI_ACTIVE +define+SVT_DFI_MAX_DATA_WIDTH=32 +define+SVT_DFI_SLICE_WIDTH=8 +define+SVT_DFI_MAX_RANK_WIDTH=2 +define+SVT_DFI_MAX_BL=32 +define+SVT_DFI_RAND_CMD_PHASE_DDR 
		DEFINES_VC += +define+UVM_VERBOSITY=UVM_FULL  +define+UVM_PACKER_MAX_BYTES=24000  +define+SYNOPSYS_SV 
		DEFINES_VC += +define+DWC_DDRPHY_NO_PG_PINS_MACROS +define+DWC_DDRPHY_TECH__CDCBUF__DISABLE_BEHAVIORAL_VERILOG 
		DEFINES_VC += +define+DWC_DDRPHY_HWEMUL +define+DWC_DDRPHY_HWEMUL_PLL +define+DWC_DDRPHY_HWEMUL_SIM +define+DWC_DDRPHY_SIMPLE_MODEL
		DEFINES_VC += +define+DWC_DDRPHY_DRVBE_SIMPLE +define+DWC_DDRPHY_HWEMUL_CGRC +define+DWC_DDRPHY_MODEL_ASYNCMSFLOP_AS_DFF
	endif
endif

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
export DEFINES_VC
export ARM_CORTEX_M0_DIR
export ARM_CORSTONE_101_DIR
export CORTEX_A53_IP_LOGICAL_DIR
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