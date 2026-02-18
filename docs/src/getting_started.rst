******************
Getting Started 
******************


Pre-requisites
===================

The megaSoC repository contains all the wrappers and system integrations of the Arm IP's. The IP's themselves are not included in the repository
as these are licensed by Arm.

In order to gain access to the Arm IP. If you are part of an academic insitution, you can sign up to `Arm's Academic Access program (AAA) <https://www.arm.com/resources/research/enablement/academic-access-inquiry>`__
This program is an agreement between your institution and Arm, so you must be an academic or educator within the institution to make this agreement.
Your institution may already be signed up, in which case you can contact your internal user manager to gain access to the IP download site.

IP
-----

Once you have access to the Arm IP library, you will need to download and set up your environment with the IP. Soclabs provide a script for 
unpacking and setting up the IP in a way that can be used with our reference SoC's (`SoCLabs Arm IP Environment <https://git.soton.ac.uk/soclabs/soclabs-arm-ip-environment>`__)

The IP that you need from arm is:

    * Cortex-A53
    * NIC400
    * and more...

Once you have downloaded and unpacked the IP, you will need to set an environment variable in your system to point to this location, you can do this by
adding ``export ARM_IP_LIBRARY_PATH=/path/to/this`` to your .bashrc file.


Software
----------

Simulator
^^^^^^^^^^
You will need a simulator in order to develop with nanoSoC. We have developed flows for:

    * Synopsys VCS
    * Siemens QuestaSim
    * Cadence Xcelium
    * Icarus Verilog

Firmware Compiler
^^^^^^^^^^^^^^^^^^
We recommend using the Arm DS-6 compiler as we have found this gives the best results in terms
of code size (and memory is very limited in nanoSoC to keep area and cost minimized)

You can download the Arm DS-6 compiler as part of the Hardware Success Kit (available from the Arm IP download site)

FPGA Build
^^^^^^^^^^^^^^
We recommend using xilinx Vivado (v2025)

ASIC
^^^^^^^^^


Repository Structure
-----------------------

Below is the repository structure showing all the dependancies from the top level megaSoC project.

Cloning the Repository
--------------------------
This Repository contains multiple sub-repositories. In order to clone them with this repository, please use the following command:

``git clone --recurse https://git.soton.ac.uk/soclabs/megasoc_project``

At this stage you can also add your submodule with:

``git submodule add``

After doing this you should update the projbranch file to include your repository name (as it appears in .gitmodules) and the branch. This will allow the set_env.sh script to pull in your repository when updates are made
At this point you may also like to edit the /env/dependency_env.sh to include your accelerator directory for example:
export ACCELERATOR_DIR="$SOCLABS_PROJECT_DIR/accelerator"

Setting up the Project Environment
--------------------------------------
Every time you wish to run commands in this project, you will need to make sure the set environment script has been run for your current terminal session. This is done by moving to the top-level of the project and running:

``source set_env.sh``

This sets the environment variables related to this project and creates visability to the scripts in the flow directory.

Updating Subrepositories
---------------------------

Once you have run a source set_env.sh in your current terminal, you are then able to update all your repositories to their latest version by running:

``socpull``

This runs a git pull on all repositories in your project.

First-time simulation
-------------------------

Before adding your IP to nanoSoC, we recommend that you run a "hello world" simulation to make sure that your environment is setup correctly.
You can do this by running:

``source set_env.sh``

``cd nanosoc_tech``

``make run``

This will run through the compilation and simulation of nanoSoC. In the following steps:

    #. Compilation the bootrom Software
    #. Compilation of the testcode (hello in this case)
    #. Compilation of the HDL with the simulator
    #. Running the simulation

The final output from this should be:

