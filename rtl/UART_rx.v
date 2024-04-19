`timescale 1ns / 1ps
`default_nettype none

module UART_rx  #
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
    //UART
    input   wire                    rxd,
    
    //Output interface
    //AXI-Stream
    output  wire    [Databits-1:0]  m_axis_tdata,
    output  wire                    m_axis_tvalid,
    input   wire                    m_axis_tready,
    output  wire                    m_axis_error, //non-standard  axi-stream signal
    
    //Status
    output  wire                    busy,

    //CONFIGURATION
    input   wire    [15:0]          prescale    //Baud rate = Fclk / prescale
);
    
    reg rxd_reg = 1;

    reg [Databits-1:0]  data_reg = 0;
    
    reg [15:0]  prescale_reg = 0;
    reg [3:0]   bit_cnt = 0;

    wire    parity;
    reg     parity_reg = 0;
    
    reg [Databits - 1:0]    m_axis_tdata_reg = 0;
    reg                     m_axis_tvalid_reg = 0;
    reg                     m_axis_error_reg = 0;
    
    reg     busy_reg;
    
    assign  m_axis_tdata    =   m_axis_tdata_reg;
    assign  m_axis_tvalid   =   m_axis_tvalid_reg;
    assign  m_axis_error =   m_axis_error_reg;
    
    assign  busy    =   busy_reg;
    
    always @(posedge clk)
        if(rst)
            rxd_reg <=  1;
        else
            rxd_reg <=  rxd;
    
    always @(posedge clk)
        if(rst)
            bit_cnt <=  0;
        else if(prescale_reg == 0)  begin
            if(bit_cnt == 0)
                bit_cnt <=  (~rxd_reg)? Databits + parity_bit + 2   :   0;
            else
                bit_cnt <=  bit_cnt - 1;
        end
        else
            bit_cnt <=  bit_cnt;
    
    always @(posedge clk)
        if(rst)
            data_reg    <=  0;
        else if((prescale_reg == 0) && (bit_cnt > parity_bit + 1))
            data_reg    <=  {rxd_reg,data_reg[Databits-1:1]};
        else
            data_reg    <=  data_reg;
            
    always @(posedge clk)
        if(rst)
            m_axis_tvalid_reg   <=  0;
        else if((prescale_reg == 0) && (bit_cnt == 1))
            m_axis_tvalid_reg   <=  (rxd_reg)?  1   :   0;
        else
            m_axis_tvalid_reg   <=  (m_axis_tvalid & m_axis_tready)?    0   :   m_axis_tvalid_reg;
            
    always @(posedge clk)
        if(rst)
            m_axis_tdata_reg   <=  0;
        else if((prescale_reg == 0) && (bit_cnt == 1))
            m_axis_tdata_reg   <=  (rxd_reg)?  data_reg   :   0;
        else
            m_axis_tdata_reg   <=  (m_axis_tvalid & m_axis_tready)?    0   :   m_axis_tdata_reg;
    
    always @(posedge clk)
        if(rst)
            busy_reg    <=  0;
        else if((prescale_reg == 0) && (bit_cnt == 0))
            busy_reg    <=  (~rxd_reg)? 1   :   0;
        else
            busy_reg    <=  busy_reg;
    
    generate    begin
        always @(posedge clk)
            if(rst)
                prescale_reg    <=  0;
            else if(prescale_reg != 0)
                prescale_reg    <=  prescale_reg - 1;
            else    begin
                if(bit_cnt == 2)    begin
                    if(Stopbits == 0)
                        prescale_reg    <=  prescale - 1;
                    else if(Stopbits == 1)
                        prescale_reg    <=  prescale + (prescale >> 1) - 1;
                    else if(Stopbits == 2)
                        prescale_reg    <=  (prescale << 1) - 1;
                    else
                        prescale_reg    <=  prescale - 1;
                end
                else if(bit_cnt == 1)
                    prescale_reg    <=  0;
                else if(bit_cnt == 0)
                    prescale_reg    <=  (~rxd_reg)? (prescale >> 1) :   0;
                else
                    prescale_reg    <=  prescale - 1;
            end
            
        begin
            if(Parity == "ODD")
                assign  parity  =   ~(^data_reg);
            else if(Parity == "EVEN")
                assign  parity  =   (^data_reg);
            else if(Parity == "MARK")
                assign  parity  =   1;
            else if(Parity == "SPACE")
                assign  parity  =   0;
            else
                assign  parity  =   0;
        end    
        
        if(Parity != "NONE")    begin
            always @(posedge clk)
                if(rst)
                    parity_reg  <=  0;
                else if((prescale_reg == 0) && (bit_cnt == 2))
                    parity_reg  <=  rxd_reg;
                else
                    parity_reg  <=  parity_reg;
        end
        
        begin
            always @(posedge clk)
                if(rst)
                    m_axis_error_reg <=  0;
            else if((prescale_reg == 0) && (bit_cnt == 1))      begin
                    if(Parity == "NONE")
                        m_axis_error_reg    <=  (~rxd_reg)?  1  :   0;
                    else
                        m_axis_error_reg <= (~rxd_reg)? 1   :   ((parity == parity_reg)? 0   :   1);
                end
                else
                    m_axis_error_reg <=  (m_axis_tvalid & m_axis_tready)?    0   :   m_axis_error_reg;
        end

        
        end
    endgenerate
    
    

endmodule
`default_nettype wire
