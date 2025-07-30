# MegaSoC Project
megaSoC is a system on chip reference design targetted for the integration of custom hardware acceleration in a Linux capable SoC. The system includes the Arm Cortex A53, DMA350, GIC400, NIC400 bus interconnect plus many other pieces of Arm IP from the Arm Academic Access Program (AAA)

## README contents
1. [First Time Setup](#first-time-setup)
2. [Repository Structure](#repository-structure)
3. [Simulation](#simulation)

## First Time Setup
Follow these steps to setup the MegaSoC Project.

First download the git repository with all it's submodules

```bash
git clone --recurse-submodules https://git.soton.ac.uk/soclabs/megasoc_project.git
```

Once downloaded run the following in terminal
```bash
source set_env.sh
make first_time_setup
```
This will configure all of the IP necessary for the project.

## Repository Structure
The following shows what is included in each of the top level directories and subrepositories
- ASIC - Directory containing ASIC scripts specific for the megasoc project. Mostly these are setup/configuration scripts, floorplan, power plan etc.
- asic_flow - Subrepository containing generic ASIC scripts for backend. 
- doc - PDF + tex documentation for megaSoC
- env - setup script for the working environment
- expansion_subsystem_tech - Subrepository for the expansion subsystem (i.e. This is an example subsystem that can be used to integrate a hardware accelerator). It contains setup and RTL for a system with DMA350, NIC400 and SRAMs
- flist - Directory containing top level file lists for used for compiling the .vc or tcl files
- flows - included makefiles for running simulation, FPGA build, ASIC implementation, firmware compilation etc.
- fpga - Directory including information for the FPGA targets (Currently the ARM MPS3 and HAPS-SX)
- megasoc_chip - Top level for megasoc project including the chip level and pad level RTL files
- megasoc_system - instatiated withing megasoc_chip. This level of hierarchy instantates the megasoc_tech_wrapper and expansion_subsystem
- megasoc_tech - Subrepository containing the megasoc_tech_wrapper and included hierarchy. This instantiates the core of megaSoC including the A53, GIC, NIC400, SRAMs, peripherals etc. (THIS SHOULD NOT NEED TO BE EDITED)
- soctools_flow - Contains some generic scripts used for the various flows
- system - Directory including and expansion_region_example (this is where a hardware accelerator  be instantiated) and some firmware for testing the expansion subsystem
- verif - Testbench and other RTL for the testbench

## Simulation
You can run all the simulations from the top level megasoc_project directory using the makefile. To run a simulation first
compile the project using

```bash
make compile
```

Then you can run a test using:
```bash
make run TESTNAME=X
```

To get a list of the valid values for TESTNAME run:
```bash
make list_tests
```

