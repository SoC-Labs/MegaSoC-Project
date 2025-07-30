##------------------------------------------------------------------------------
## The confidential and proprietary information contained in this file may
## only be used by a person authorised under and to the extent permitted
## by a subsisting licensing agreement from Arm Limited or its affiliates.
##
##        (C) COPYRIGHT 2018-2021 Arm Limited or its affiliates.
##            ALL RIGHTS RESERVED
##
## This entire notice must be reproduced on all copies of this file
## and copies of this file may only be made by a person if such person is
## permitted to do so under the terms of a subsisting license agreement
## from Arm Limited or its affiliates.
##
##      Release Information : SSE710-r0p0-00rel0
##
##------------------------------------------------------------------------------
## Purpose : C test Makefile
##------------------------------------------------------------------------------

TEST_PATH       := $(CURDIR)
TEST_ID         := $(notdir $(TEST_PATH))

export TEST_PATH
export TEST_ID

#############################################################################
#### Variables globally applied for all images                         ######
#############################################################################

ifeq ($(TEST_VERBOSITY), 1)
  GLOBAL_TESTDEFINES  := -DTEST_VERBOSITY_HIGH
endif

#############################################################################
############# Variables necessary for compiling image for Cortex A53 ########
#############################################################################

APP_TESTDEFINES     :=

APP_SCAT := default
APP_LD_FLAGS :=
APP_AS_FLAGS := -DMASTER_CPU_REF=0x0 -DMASTER_CLUS_REF=0x0 -DTTBR0_BASE=0x02100000 -DVBAR_ADDR=0x02000000
APP_AS_INC_DIR :=
APP_C_FLAGS := $(APP_TESTDEFINES) $(GLOBAL_TESTDEFINES) -DTTBR0_BASE=0x02100000
APP_C_INC_DIR := $(TEST_PATH)
APP_SRC := exp_dma350_tests.c

export APP_SRC
export APP_C_FLAGS
export APP_C_INC_DIR
export APP_AS_FLAGS
export APP_AS_INC_DIR
export APP_LD_FLAGS
export APP_SCAT

###############################################################################
###############################################################################
###############################################################################

include $(SOCLABS_MEGASOC_TECH_DIR)/software/lib/common/Makefile.sim



