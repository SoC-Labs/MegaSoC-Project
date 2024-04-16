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

# MilliSoC Tech
export SOCLABS_MEGASOC_TECH_DIR="$SOCLABS_PROJECT_DIR/millisoc_tech"

# MilliSoC Expansion Tech
export SOCLABS_MEGASOC_EXP_TECH_DIR="$SOCLABS_PROJECT_DIR/expansion_subsystem_tech"

#-----------------------------------------------------------------------------
# Flows
#-----------------------------------------------------------------------------

# SoCTools - Toolkit of scripts related to SoCLabs projects
export SOCLABS_SOCTOOLS_FLOW_DIR="$SOCLABS_PROJECT_DIR/soctools_flow"
