
module TDC_interface(                                

    clk,                
    rst_TDC_interface,                
    flag_col,
    SI,
    SO,

    BUF1,

    ready,
    TDC_data_i
    
);
//`include "CONSTANT.vh"
//jiang bing xing shu ju huan cun xiao chu fu hao wei 

parameter BITS_SIG_TDC = 16 ;
parameter BITS_UNSIG_TDC = 15;  //修改 ：16位 UNSIG->SIG
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


    input rst_TDC_interface;                   // Global reset port
    input clk;                      // Global clock
    input SI;
    
    input flag_col;

    input ready;                      // 
    //spi data interface
    
    input [BITS_SIG_TDC-1:0] TDC_data_i;                            //input14 bit of TDC output with sign
    output wire SO;
    output reg [BITS_UNSIG_TDC-1:0] BUF1;

    
    reg [BITS_UNSIG_TDC-1:0] BUF2;
    reg [BITS_UNSIG_TDC-1:0] unsign_TDC;
    reg flag_col_dly_oneclk;
    reg flag_col_dly_twoclk;

    assign SO =BUF2[BITS_UNSIG_TDC-1];                    
    //assign unsign_TDC[BITS_UNSIG_TDC-1:0]  =  TDC_data_i[5]? {TDC_data_i[BITS_SIG_TDC-1:6],{5{1'b0}}} - {{10{1'b0}},TDC_data_i[4:0]} : {TDC_data_i[BITS_SIG_TDC-1:6],TDC_data_i[4:0]} ;

    
    always @(*) begin 
          if (TDC_data_i[5]) begin
               unsign_TDC[BITS_UNSIG_TDC-1:0] <={TDC_data_i[BITS_SIG_TDC-1:6],{5{1'b0}}} - {{10{1'b0}},TDC_data_i[4:0]};
           end 
           else begin
                unsign_TDC[BITS_UNSIG_TDC-1:0]<={TDC_data_i[BITS_SIG_TDC-1:6],TDC_data_i[4:0]};
        end
    end



    always @(posedge clk or negedge rst_TDC_interface) begin 
        if(~rst_TDC_interface) begin
             flag_col_dly_oneclk<='d0;
             flag_col_dly_twoclk<= 'd0;
        end else begin
            if (flag_col==1'b1) begin
                 flag_col_dly_oneclk<=1'b1;
            end
            else begin
                flag_col_dly_oneclk<=1'b0;
            end

            if (flag_col_dly_oneclk==1'b1) begin
                flag_col_dly_twoclk<= 1'b1;
            end
            else begin
                flag_col_dly_twoclk<=1'b0;
            end
        end
    end
    


    always @(posedge clk or negedge rst_TDC_interface) begin
        if(~rst_TDC_interface) begin
            BUF1[BITS_UNSIG_TDC-1:0] <= 0;
            BUF2[BITS_UNSIG_TDC-1:0] <= 0;
          
        end
        else begin
            BUF2[BITS_UNSIG_TDC-1:0] <= {BUF2[BITS_UNSIG_TDC-2:0],SI};
            if(ready == 1'b1&&flag_col_dly_twoclk == 1'b0) begin                          //这个input的ready从电路来，ready然后就存结果.注意，这个ready和clk是同步的，这里采集到的是ready结束之前的值。
                BUF1[BITS_UNSIG_TDC-1:0] <= unsign_TDC[BITS_UNSIG_TDC-1:0];
            end
            else if (flag_col_dly_twoclk==1'b1) begin
                BUF1[BITS_UNSIG_TDC-1:0] <= 'd0;
            end
            else begin
                BUF1[BITS_UNSIG_TDC-1:0] <= BUF1[BITS_UNSIG_TDC-1:0];
            end



            if(flag_col == 1'b1) begin                         //这个从fsm来，SWCOL之后，吧地址位和TDC的结果放到buf2里面，然后一次次挪到输出里面，这个也是col结束之前的值
                BUF2[BITS_UNSIG_TDC-1:0] <= BUF1[BITS_UNSIG_TDC-1:0];             
            end
        end
    end

endmodule 