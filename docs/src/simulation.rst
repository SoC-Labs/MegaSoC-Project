*********************
Simulation
*********************

This describes the steps needed to simulate nanoSoC. Supported simulators are:

    * Synopsys VCS
    * Siemens QuestaSim
    * Cadence Xcelium
    * Icarus Verilog


Running Simulations
========================

You can run make commands from the nanosoc tech directory to run the simulation.

``make run SIM=x TESTNAME=y ACCELERATOR=yes``

Where x=mti, vcs, xm, or iverilog for QuestaSim, VCS, Xcelium, or Icarus Verilog respectively. 
And y is the name of the test, the default test is hello (a hello world example).

Or to run the simulation in the GUI you can use:
``make sim SIM=x TESTNAME=y ACCELERATOR=yes``

Whilst the simulation is running, you should see the output from the std out channel in the console/terminal


Debugging Simulations
========================

`My simulation won't run`

This may be an environment issue or a design that won't compile. Please first check the compile_$(SIM).log in the simulate/sim/$(TESTNAME) directory.
If you don't see this file, look at the output of the terminal when you run the ``make run`` command, usually it will give you some explaination.

If the problem is it can't find files, you may have forgotten to run the ``source set_env.sh`` command.


Preloading expansion memories
==================================

You may want to load test vectors directly into the expansion memories to run your tests. Doing this can save space in the instruction memory space as you
then don't have to load data in as arrays or vectors in your testcode. Instead you can use the simulator to automatically load these memories at the start of
simulation.

To do this, simply add an ”expram l.hex” file and/or ”expram h.hex” file to
your testcode directory. These files will then be loaded to the EXPRAM L or
EXPRAM H region repectively. These can then be addressed in your testcode
from 0x80000000 for EXPRAM L and 0x90000000 for EXPRAM H.
The expram l.hex files must be ASCII text files with a single byte per line.
They will look very similar to the .hex files that are used to preload the instruction memory.

