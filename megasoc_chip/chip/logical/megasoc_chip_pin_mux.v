module megasoc_chip_pin_mux (
    output wire [15:0]      SOC_P0_IN,
    input  wire [15:0]      SOC_P0_OUT,
    input  wire [15:0]      SOC_P0_EN,
    input  wire [15:0]      SOC_P0_FUNC,
    input  wire [15:0]      SOC_P0_ALT_OUT,
    output wire [15:0]      SOC_P0_ALT_IN,
    input  wire [15:0]      SOC_P0_ALT_EN,

    output wire [15:0]      SOC_P1_IN,
    input  wire [15:0]      SOC_P1_OUT,
    input  wire [15:0]      SOC_P1_EN,
    input  wire [15:0]      SOC_P1_FUNC,
    input  wire [15:0]      SOC_P1_ALT_OUT,
    output wire [15:0]      SOC_P1_ALT_IN,
    input  wire [15:0]      SOC_P1_ALT_EN,

    input  wire [15:0]      PAD_P0_IN,
    output wire [15:0]      PAD_P0_OUT,
    output wire [15:0]      PAD_P0_EN,

    input  wire [15:0]      PAD_P1_IN,
    output wire [15:0]      PAD_P1_OUT,
    output wire [15:0]      PAD_P1_EN
);


genvar i;
generate
    for(i=0;i<16;i=i+1) begin
        assign PAD_P0_OUT[i] = (SOC_P0_FUNC[i]==1'b1) ? SOC_P0_ALT_OUT[i] : SOC_P0_OUT[i];
        assign PAD_P1_OUT[i] = (SOC_P1_FUNC[i]==1'b1) ? SOC_P1_ALT_OUT[i] : SOC_P1_OUT[i];
        
        assign SOC_P0_ALT_IN[i] = (SOC_P0_FUNC[i]==1'b1) ? PAD_P0_IN[i] : 1'b0;
        assign SOC_P1_ALT_IN[i] = (SOC_P1_FUNC[i]==1'b1) ? PAD_P1_IN[i] : 1'b0;
        
        assign SOC_P0_IN[i] = (SOC_P0_FUNC[i]==1'b1) ? 1'b0 : PAD_P0_IN[i];
        assign SOC_P1_IN[i] = (SOC_P1_FUNC[i]==1'b1) ? 1'b0 : PAD_P1_IN[i];

        assign PAD_P0_EN[i] = (SOC_P0_FUNC[i]==1'b1) ? SOC_P0_ALT_EN[i] : SOC_P0_EN[i];
        assign PAD_P1_EN[i] = (SOC_P1_FUNC[i]==1'b1) ? SOC_P1_ALT_EN[i] : SOC_P1_EN[i];
    end
endgenerate



endmodule