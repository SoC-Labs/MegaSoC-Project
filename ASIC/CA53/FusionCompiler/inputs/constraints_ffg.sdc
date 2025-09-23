#-----------------------------------------------------------------------------
# Cortex A53 FFG Corner Constraints for Synthesis 
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# Daniel Newbrook (d.newbrook@soton.ac.uk)
#
# Copyright (C) 2021-5, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

# Factor for ffg corner 0.8V 125C
set max_transition_factor        0.438;  
set clock_max_transition_factor  0.438;

source ../inputs/ca53_constraints.sdc