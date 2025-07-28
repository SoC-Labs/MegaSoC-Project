# MegaSoC Project


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

