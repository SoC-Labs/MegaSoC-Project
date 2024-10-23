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

# Project System Directory
FPGA_IMP_DIR     := $(SOCLABS_PROJECT_DIR)/imp/fpga

# Directory to put simulation files
SIM_TOP_DIR ?= $(SOCLABS_PROJECT_DIR)/simulate/sim
SIM_DIR      = $(SIM_TOP_DIR)/$(TESTNAME)

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
DEFINES_VC  += +define+CORTEX_A53 +define+USE_TARMAC 

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

clean: clean_sim clean_all_code