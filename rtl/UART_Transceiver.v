`timescale 1ns / 1ps
`default_nettype none

module UART_Transceiver #
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
    input   wire                    rst,
    
    //CONFIGURATION
    input   wire    [15:0]          prescale,
    
    //Tx AXI-Stream Interface
    input   wire    [Databits-1:0]  s_axis_tdata,
    input   wire                    s_axis_tvalid,
    output  wire                    s_axis_tready,
    
    //Rx AXI-Stream Interface
    output  wire    [Databits-1:0]  m_axis_tdata,
    output  wire                    m_axis_tvalid,
    input   wire                    m_axis_tready,
    output  wire                    m_axis_error,
    
    //UART
    output  wire                    txd,
    input   wire                    rxd,
    
    //Status
    output  wire                    tx_busy,
    output  wire                    rx_busy
);
    
UART_tx #(
    .Databits(Databits),
    .Parity(Parity),
    .Stopbits(Stopbits)
)
uart_tx_inst (
    .clk(clk),
    .rst(rst),

    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),

    .txd(txd),

    .busy(tx_busy),

    .prescale(prescale)
);

UART_rx #(
    .Databits(Databits),
    .Parity(Parity),
    .Stopbits(Stopbits)
)
uart_rx_inst (
    .clk(clk),
    .rst(rst),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_error(m_axis_error),
    
    .rxd(rxd),

    .busy(rx_busy),

    .prescale(prescale)
);
endmodule
`default_nettype wire
