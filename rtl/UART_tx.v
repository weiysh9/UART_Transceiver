`timescale 1ns / 1ps
`default_nettype none

module UART_tx  #
(
    parameter   Databits    =   8,
    parameter   Parity      =   "NONE", /*  NONE:   no parity bit
                                             ODD:    odd parity ~(^tdata)
                                             EVEN:   even parity  (^tdata)
                                             MARK:   fixed "1"
                                             SPACE:  fixed "0"
                                         */
                                         
    parameter   Stopbits    =   0,      /*  0:     1
                                             1:     1.5
                                             2:     2
                                         */
    parameter   parity_bit  =   (Parity == "NONE")? 0   :   1
)
(
    //Clock and Reset signal
    input   wire                    clk,
    input   wire                    rst,    //Synchronous active-high reset signal
    
    //Input Interface
    //AXI-Stream
    input   wire    [Databits-1:0]  s_axis_tdata,
    input   wire                    s_axis_tvalid,
    output  wire                    s_axis_tready,
    
    //Ouput Interface
    //UART
    output  wire                    txd,
    
    //Status
    output  wire                    busy,
    
    //CONFIGURATION
    input   wire    [15:0]          prescale    //Baud rate = Fclk / prescale
    );
    
    
    reg s_axis_tready_reg = 0;
    
    reg txd_reg = 1;
    
    reg [3:0]   bit_cnt = 0;
    reg [15:0]  prescale_reg = 0;
    
    wire        parity;
    wire[Databits+parity_bit:0] data;
    reg [Databits+parity_bit:0] data_reg = 0;
    
    reg         busy_reg = 0;
    
    assign s_axis_tready =   s_axis_tready_reg;
    
    assign txd  =   txd_reg;
    
    assign busy =   busy_reg;
    
    always @(posedge clk)
        if(rst)
            s_axis_tready_reg    <=  0;
        else if(prescale_reg != 0)
            s_axis_tready_reg    <=  0;
        else if(bit_cnt == 0)
            s_axis_tready_reg    <=  s_axis_tvalid?   ~s_axis_tready_reg   :   1;
        else
            s_axis_tready_reg    <=  s_axis_tready_reg;
    
    always @(posedge clk)
        if(rst)
            bit_cnt <=  0;
        else if(prescale_reg == 0)  begin
            if(bit_cnt == 0)
                bit_cnt <=  s_axis_tvalid?   Databits + parity_bit + 1   :   0;
            else
                bit_cnt <=  bit_cnt - 1;        
        end
        else
            bit_cnt <=  bit_cnt;
    
    generate begin
        always @(posedge clk)   begin
            if(rst)
                prescale_reg    <=  0;
            else if(prescale_reg != 0)
                prescale_reg    <=  prescale_reg - 1;
            else    begin
                if(bit_cnt == 0)
                    prescale_reg    <=  (s_axis_tvalid)? prescale - 1    :   0;
                else if(bit_cnt == 1)   begin
                    if(Stopbits == 0)
                        prescale_reg    <=  prescale - 1;
                    else if(Stopbits == 1)
                        prescale_reg    <=  prescale + (prescale >> 1) - 1;
                    else
                        prescale_reg    <=  (prescale << 1) - 1;
                end
                else
                    prescale_reg    <=  prescale - 1;
            end
        end
        
        begin
            if(Parity == "ODD")
                assign  parity  =   ~(^s_axis_tdata);
            else if(Parity == "EVEN")
                assign  parity  =   (^s_axis_tdata);
            else if(Parity == "MARK")
                assign  parity  =   1;
            else if(Parity == "SPACE")
                assign  parity  =   0;
            else
                assign  parity  =   0;
        end
        
        begin
            if(parity_bit)
                assign  data    =   {1'b1,parity,s_axis_tdata};
            else
                assign  data    =   {1'b1,s_axis_tdata};
        end
        
        always @(posedge clk)   begin
            if(rst)
                data_reg    <=  0;
            else if(prescale_reg == 0)  begin
                if(bit_cnt == 0)
                    data_reg    <=  (s_axis_tvalid)? data    :   0;
                else
                    data_reg    <=  {1'b1,data_reg[Databits+parity_bit:1]};
            end
            else
                data_reg    <=  data_reg;
        end
        
                    
        
        end
    endgenerate
        
    always @(posedge clk)
        if(rst)
            txd_reg <=  1;
        else if(prescale_reg == 0)  begin
            if(bit_cnt == 0)
                txd_reg <=  (s_axis_tvalid)? 0   :   1;
            else
                txd_reg <=  data_reg[0];
        end
        else
            txd_reg <=  txd_reg;
    
    always @(posedge clk)
        if(rst)
            busy_reg    <=  0;
        else if((prescale_reg == 0) && (bit_cnt == 0))
            busy_reg    <=  (s_axis_tvalid)? 1   :   0;
        else
            busy_reg    <=  busy_reg;
            
           

endmodule
`default_nettype wire