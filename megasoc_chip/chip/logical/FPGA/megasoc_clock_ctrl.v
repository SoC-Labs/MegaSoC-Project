

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


assign SYS_CLK = CLK_IN;
assign CPU_CLK = CLK_IN;
assign FLASH_CLK = CLK_IN;

endmodule
