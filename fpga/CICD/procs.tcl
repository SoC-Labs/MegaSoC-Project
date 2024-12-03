# Usage
# > settings64.bat
# > vivado -mode batch -source file2bram.tcl
# Note: Bitstream needs to be downloaded and running first




#################################################
# file2bram
#   read data from file and send it to BRAM
#   data in file are regard as hex without 0x prefix
#
# file2bram $addr $file
proc file2bram {addr in_fn} {

  puts "----------------------------------------"
  puts "Start to Write Data From File to BRAM"
  puts "----------------------------------------"

  # check input arguments

  # open file
  puts "Input File: $in_fn"
  set fd [open $in_fn r]


  # remove previously created txn if exist
  if {[llength [get_hw_axi_txns wr_txn_* -quiet]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns wr_txn_*]
  }

  # concatenate lines into a string
  set data []
  set line_number 0
  set wr_nr 0
  while {[gets $fd cur_line] > 0} {
    append cur_line $data
    set data $cur_line; #data should be (line2 line1) style
    incr line_number

    # create txn when line number gets to 256
    # since max length of a burst is 256
    if {$line_number >= 256} {
      set addr_string [format "0x%x" [expr $addr + $wr_nr * 256 * 4]]
      create_hw_axi_txn wr_txn_$wr_nr [get_hw_axis] -address $addr_string -data $data -len 256 -type write
      set line_number 0
      set data []
      incr wr_nr
    }

  }


  # create txn for the reminders if there's any
  if {$line_number > 0} {
    set addr_string [format "0x%x" [expr $addr + $wr_nr * 256 * 4]]
    create_hw_axi_txn wr_txn_$wr_nr [get_hw_axis] -address $addr_string -data $data -len $line_number -type write
  }

  # write file
  run_hw_axi [get_hw_axi_txns wr_txn_*]

  # wait and check file write successful

  # remove created txn
  if {[llength [get_hw_axi_txns wr_txn_* -quiet]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns wr_txn_*]
  }
  # close file
  close $fd

  puts "Data transfer completes"
}



#############################################
# bram2file
#   read data from bram and save it to file
#   addr: start read address
#   len: length in words
#   out_fn: output file name
proc bram2file {addr len out_fn} {
  puts "Output File: $out_fn"
  # open file for write. file will be replaced if it exists
  set fd [open $out_fn w]

  set line_number 0
  set rd_nr 0


  # remove previously created txn if exist
  if {[llength [get_hw_axi_txns rd_txn_* -quiet]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns rd_txn_*]
  }

  while {$len > 0} {

    if {$len >= 256} {
      set burst_length 256
    } else {
      set burst_length $len
    }

    # create read txn
    set address_string [format "0x%x" [expr $addr + $rd_nr * $burst_length * 4]]
    create_hw_axi_txn rd_txn_$rd_nr [get_hw_axis] -address $address_string -len $burst_length -type read
    # read from jtag
    run_hw_axi [get_hw_axi_txns rd_txn_$rd_nr]
    # get read data
    set data [report_hw_axi_txn -t x4 -w 4 [get_hw_axi_txns rd_txn_$rd_nr]]
    # data is a list like [addr1 data1 addr2 data2]

    # save data to file
    for {set data_length [llength $data]; set i 1} { $i < $data_length } { incr i 2 } {
      puts $fd [lindex $data $i]
    }





    incr rd_nr
    set len [expr $len - 256]
  }

  # close file
  close $fd

  if {[llength [get_hw_axi_txns rd_txn_*]] > 0} {
    delete_hw_axi_txn [get_hw_axi_txns rd_txn_*]
  }


}



proc connect_zc702 {} {
  connect_hw_server -host localhost -port 60001 -url localhost:3121
  current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210203326797A]
  set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/210203326797A]
  open_hw_target
  current_hw_device [lindex [get_hw_devices] 1]
  refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 1]
}

proc connect_haps_sx {} {
  
}



