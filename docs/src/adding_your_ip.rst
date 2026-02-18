******************
Adding your IP
******************

In order to add the files for your IP there are 2 options. Either as a local version
of your project or as a remote version.
    #. Local version: you can just place your IP files into a new directory or in the system/expansion_region directory
    #. Remote version: you can fork the accelerator-project git to your own git account, this allows you to add your IP either in the system/expansion_region directory or as a git submodule.

Integrating your IP
=========================

There are 2 steps to integrating your IP in nanosoc
    #. Include your IP in the file list
    #. Instantiate your IP in the system/expansion_region/expansion_region_example.v file

For step 1. you can add paths to your files in the flist/project/accelerator.flist file. We recommend that you use the environment variables as mentioned in section 1.4. In order for fpga and asic flows to work properly you
should split verilog and system verilog files into seperate .flist files. We suggest adding an accelerator sv.flist to the accelerator-project/flist/project directory
and adding the following to accelerator.flist

``-f $SOCLABS P ROJECT DIR/flist/project/accelerator sv.flist``

For step 2. you need to edit the accelerator subsystem.v file (found in accelerator-project/system/src/). The ports of this file are an AHB-lite port,
2x EXP DRQ (data request from accelerator to DMA), 2x EXP DLAST (last signal from DMA to accelerator), 4x EXP IRQ (Interrupts from accelerator to
CPU), and some AXI stream interfaces (these are only there if the DMA350 is configured with stream interfaces)

.. warning:: Add the option ACCELERATOR=yes to include your accelerator when you run make commands!

