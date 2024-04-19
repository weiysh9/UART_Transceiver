UART_Transceiver

UART总线学习

参考了alexforencich的verilog-uart
在原来的基础上简单拓展了模块参数
新增Parity和Stopbits参数
可以支持不同的Parity校验（NONE、ODD、EVEN、MARK、SPACE)
可以支持不同长度的stopbit（1位、1.5位、2位）

UART_Transceiver的user interface为AXI-Stream

input信号prescale和alex的不同，prescale直接指定分频比，即 Baud Rate = Fclk / prescale

UART_rx的AXI-Stream master interface增加了一个非标准的信号m_axis_error
若检查到校验位不符合Parity指定的校验或识别到停止位不为"1"
m_axis_tvalid仍会拉高，但m_axis_error也会同时拉高，告知用户数据出错
