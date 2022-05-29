// Standard SPI module (slave mode)
// Function:
// Two separate clocks for internal and external communication.
// Internal interface to FSM is parallel. It can be converted to serial via a SIPO with proper handshake with this code.
// Change Log:
// 2020.12.16 yanpeng
//  this module is a slave ,recieve serial data from testbench and save at buf
//  at the same time transmit parallel FMS data to testbench 
module SPI_FSM (
    // Standard SPI interface
    sclk,        // SPI clock
    miso,       // Master IN slave Out lsb first, Latched in in falling edge
    mosi,       // Master Out slave IN lsb first, changed in falling edge
    cs_spi,        // Chip select (low active)

    // Internal parallel interface
    rst_n_spi,      // Asynchronous rst_n_spi LOW ACTIVE
    para_input,   // data from FSM to testbench
    para_output,  // Receiving PORT DUT -<- External
    xcvr_busy  // Transceiver is busy (high active), will be low if is idel or tx rx finished
);

//`include "CONSTANT.vh"


parameter BITS_SIG_TDC = 16 ;
parameter BITS_UNSIG_TDC = 15;
parameter BITS_SPI =32;
parameter CNT_SPI = 5;
parameter NUM_COL = 16;
parameter CNT_COL =  4;//16列，4位 

parameter NUM_ROW = 1;

parameter BITS_DLY_SWITCH = 25;//从15改成了25
parameter CNT_DLY_CALIB = 5;//从4改成了5

parameter NUM_BUFBYTES = 10;//增加了probe

parameter BITS_COARSE = 10;
parameter BITS_COL = 5;

parameter cmd_dummy             =4'b0001;
parameter cmd_reg_set           =4'b0010;
parameter cmd_reg_get           =4'b0011;
parameter cmd_reset_dly         =4'b0100;
parameter cmd_reset_pixel       =4'b0101;
parameter cmd_reset_analog      =4'b0110;
parameter cmd_dly_calib         =4'b1000;
parameter cmd_pixel_calib       =4'b1001;
parameter cmd_main_work         =4'b1010;
parameter st_idle               =4'b0000;
parameter st_dummy              =4'b0001;
parameter st_reg_set            =4'b0010;
parameter st_reg_get            =4'b0011;
parameter st_reset_dly          =4'b0100;
parameter st_reset_pixel        =4'b0101;
parameter st_reset_analog       =4'b0110;
parameter st_dly_calib          =4'b1000;
parameter st_pixel_calib        =4'b1001;
parameter st_main_work          =4'b1010;
parameter st_err=4'b1111;


// SPI interface
input sclk, mosi, cs_spi;
output wire miso;



// Internal parallel interface to FSM
input rst_n_spi;
input [BITS_SPI-1:0] para_input;
output reg [BITS_SPI-1:0] para_output;
output reg xcvr_busy;

// internal registers and variables
reg [BITS_SPI-1:0] xcvr_buffer;  // Shift registers for transceiver
reg [CNT_SPI-1:0] counter;
//reg [BITS_SPI-2:0] tx_buf; //ADD input latch to avoid chaning tx, need to be ready before the next falling edge of xcvr_busy  //这个最后没有用




always @(negedge sclk or negedge rst_n_spi) begin                                               //输入master应该是上升沿写数据的
    if (!rst_n_spi) begin
        // rst_n_spi
        xcvr_buffer <= 'd0;
        xcvr_busy <= 1'b0;
        counter <= 'd0;
//        tx_buf <= 0;
        para_output <= 0;
    end
    else begin
        if (cs_spi == 1'b0) begin
            // If chip is selected
            if (counter == BITS_SPI-1) begin
                // If SPI finishes communication
                xcvr_busy <= 1'b0;
                counter <= 'd0;
                xcvr_buffer [BITS_SPI-1: 0] <= para_input[BITS_SPI-1 : 0];                              //把内部的输出串行放到了buf里面，放进来。在完成第一次接受之后，开始具有了输出功能，
                                                                                                    //输入输出公用一个buffer，每次挪一位，进来一个输入，挪出去一个输出。
                para_output <= {xcvr_buffer[BITS_SPI-2:0],mosi};                                       //输入信号的转并行，输出给内部模块
            end
            else begin
                xcvr_busy <= 1'b1;
                counter <= counter + 'd1;
                xcvr_buffer <= {xcvr_buffer[BITS_SPI-2:0],mosi};
            end
        end
        else begin
            counter<='d0;
            xcvr_busy<='d0;
        end
    end
end
assign miso = xcvr_buffer[31];                                                          //这里把输出的数据一次一次传出去,MISO应该是在cs拉低之后，就是最高位数据。而接受数据，是从cs拉低之后，第二个时钟开始的。
endmodule                                                                               //上面的理解有误