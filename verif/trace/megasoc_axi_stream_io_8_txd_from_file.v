//-----------------------------------------------------------------------------
// customised example ADP i/o stream controller (with code loader for netlist)
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Flynn (d.w.flynn@soton.ac.uk)
//
// Copyright (C) 2023, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Abstract : FT1248 1-bit data off-chip interface (emulate FT232H device)
// and allows cmsdk_uart_capture testbench models to log ADP ip, op streams
//-----------------------------------------------------------------------------


module megasoc_axi_stream_io_8_txd_from_file
  #(parameter TXDFILENAME = "adp.cmd",
    parameter VERBOSE = 0,
    parameter FAST_LOAD = 1)
  (
  input  wire  aclk,
  input  wire  aresetn,
  input  wire  txd8_ready,
  output wire  txd8_valid,
  output wire  [7:0] txd8_data
  );

function [7:0] FNmap_hex_digit;
input [3:0] nibble;
case (nibble[3:0])
4'b0000: FNmap_hex_digit = "0" & 8'hff;
4'b0001: FNmap_hex_digit = "1" & 8'hff;
4'b0010: FNmap_hex_digit = "2" & 8'hff;
4'b0011: FNmap_hex_digit = "3" & 8'hff;
4'b0100: FNmap_hex_digit = "4" & 8'hff;
4'b0101: FNmap_hex_digit = "5" & 8'hff;
4'b0110: FNmap_hex_digit = "6" & 8'hff;
4'b0111: FNmap_hex_digit = "7" & 8'hff;
4'b1000: FNmap_hex_digit = "8" & 8'hff;
4'b1001: FNmap_hex_digit = "9" & 8'hff;
4'b1010: FNmap_hex_digit = "a" & 8'hff;
4'b1011: FNmap_hex_digit = "b" & 8'hff;
4'b1100: FNmap_hex_digit = "c" & 8'hff;
4'b1101: FNmap_hex_digit = "d" & 8'hff;
4'b1110: FNmap_hex_digit = "e" & 8'hff;
4'b1111: FNmap_hex_digit = "f" & 8'hff;
//default: FNmap_hex_digit = "0" & 8'hff;
endcase
endfunction

 //----------------------------------------------
 //-- File I/O
 //----------------------------------------------


   integer        fd;       // channel descriptor for cmd file input
   integer        ch;
   
   integer        flen;
   reg [31:0]     codesize;
   integer        fp;

`define EOF -1

   reg       valid;
   reg [7:0] data8;

localparam BUFSIZE = (64 * 1024);

   reg     [7:0]   adpbuf  [0:BUFSIZE-1];
 
   initial
     begin
       valid <= 0;
       // append any ADP command file to the code memory preload
       flen =0;
       fd= $fopen(TXDFILENAME,"r");
       $write("** %m : input file : <%s> **\n", TXDFILENAME);
       if (fd == 0)
          $write("** %m : input file <%s> failed to open **\n", TXDFILENAME);
       else begin
         while (!$feof(fd)) begin
           adpbuf[flen] =  $fgetc(fd);
           flen = flen +1;
           end
         $write("** %m : file closed after stream TX completed **\n");
         $fclose(fd);
       end
    $write("** %m : input file length measured as: %d **\n", flen); 
       if (flen > 0) flen=flen-1; // correct for extra char count(???)
       // now output the entire adp buffer to the stream
       fp = 0;
       valid <= 0;
       begin
         @(posedge aresetn);
         while (fp <= flen) begin
           @(posedge aclk);
           data8 <= adpbuf[fp];
           fp = fp + 1;
           valid <= 1'b1;
           @(posedge aclk);
           while (txd8_ready == 1'b0)
             @(posedge aclk);
           valid <=0;
         end
         $write("** %m : adpbuf replay completed **\n");
         valid <= 0;
       end
     end

assign txd8_valid = valid;
assign txd8_data = data8;

endmodule
