

module megasoc_clock_ctrl(
    input  wire         CLK_IN,
    input  wire         PORESTn,

    input  wire [31:0]  PADDR,
    input  wire [31:0]  PWDATA,
    input  wire         PWRITE,
    input  wire [2:0]   PPROT,
    input  wire [3:0]   PSTRB,
    input  wire         PENABLE,
    input  wire         PSELx,
    output wire [31:0]  PRDATA,
    output wire         PSLVERR,
    output wire         PREADY,

    output wire         SYS_CLK,
    output wire         CPU_CLK,
    output wire         FLASH_CLK
);

reg clock_sys;
reg clock_cpu;
reg clock_flash;

assign SYS_CLK = clock_sys;
assign CPU_CLK = clock_cpu;
assign FLASH_CLK = clock_flash;

initial
begin
    clock_sys   <= 1'b0;
    clock_cpu  <= 1'b0;
    clock_flash <= 1'b0;
    #40 clock_sys <= 1'b1;
    clock_cpu <= 1'b1;
end

always @(clock_sys) 
    #1 clock_sys <= !clock_sys;  // 2ns period, 500MHz

always @(clock_cpu)
    #0.5 clock_cpu <= !clock_cpu; // 1ns period, 1GHz

always @(clock_flash)
    #2 clock_flash <= !clock_flash; // 4ns period 250MHz

endmodule