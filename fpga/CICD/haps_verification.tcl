# --------
#   main
# --------

# Connect hw server
# This part of tcl commands are board related.
# They can be copied from Vivado Tcl Console after connecting to FPGA successfully
open_hw
connect_zc702

# send data to bram
file2bram 0xc0000000 mat_to_fpga0.txt
bram2file 0xc0000000 1024 fpga2mat0.txt

# close hardware connection
close_hw