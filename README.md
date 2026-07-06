# MegaSoC Project
megaSoC is a system on chip reference design targetted for the integration of custom hardware acceleration in a Linux capable SoC. The system includes the Arm Cortex A53, DMA350, GIC400, NIC400 bus interconnect plus many other pieces of Arm IP from the Arm Academic Access Program (AAA)

## README contents
1. [Prerequisites](#prerequisites)
1. [First Time Setup](#first-time-setup)
2. [Repository Structure](#repository-structure)
3. [Simulation](#simulation)
4. [FPGA](#fpga)

## Prerequisites
You will first need to setup the environment. This includes downloading all the IP, having tools installed and setup correctly.

### Arm IP
You will need to download from Arm the following IP
- Cortex A53
- Cortex A53 FPU and NEON extension
- NIC-400
- GIC-400
- DMA350
- Corstone-101
- PCK600
- PL011
- PL022
- PL031
- SIE300
- CG092

You may need to do some additional unpacking of these IPs (particularly the A53) Please see the release notes from the downloaded IP.

In order for the project to find the required files. You can use this repo (https://git.soton.ac.uk/soclabs/soclabs-arm-ip-environment) to setup the IP environment.

Once you have set this up, you should set up an environment variable $ARM_IP_LIBRARY_PATH that points to the Arm IP directory.

### Socrates
You need Socrates installed on your system. This will allow the configuration of the Arm IP in the project. 

You will also need to associate the IP (i.e. tell socrates where the IP is stored)

- Open Socrates GUI
- In toolbar go to "IP Catalog"->"Associate All IP Bundles"
- Navigate to IP stored location, this should be the same as $ARM_IP_LIBRARY_PATH
- Press Finish
- This will take some time to run as it searches all the sub-directories

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

### SDIO Synopsys VIP
SDIO/SD-card verification is done via the Synopsys VC-VIP-SOC eMMC/SD UVM
testbench (`logical/sdspi` is `soclabs/sdio-controller`, the RTL host; the
VIP is the card model)

```bash
make testcode TESTNAME=sdio_tests   # only if sdio_tests.c/sdiodrv.c changed --rebuilds the embedded test software image (compile_vip only rebuilds the RTL/testbench,it does NOT pick up software changes)
make compile_vip                    # only if a uvm_vip/*.sv file or RTL changed
make run_vip TESTNAME=sdio_tests
```

## FPGA
So far limited testing in FPGA has been achieved. We have attempted to build for the Arm MPS3 but the design does not fit the Kintex 115 part. 

Support is being developed for the Arm MPS4 board and HAPS-SX