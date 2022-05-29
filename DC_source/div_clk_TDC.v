//by yanpeng
//clk_TDC=(ratio+1)*2*  (1/CLK) 
//problem: when ratio change, the clk_TC will error in 1 clk
module div_clk_TDC (
								clk,    
								rst_n,  
								ratio_TDC,
								clk_TDC
	
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

parameter cmd_dummy				=4'b0001;
parameter cmd_reg_set			=4'b0010;
parameter cmd_reg_get			=4'b0011;
parameter cmd_reset_dly			=4'b0100;
parameter cmd_reset_pixel		=4'b0101;
parameter cmd_reset_analog		=4'b0110;
parameter cmd_dly_calib			=4'b1000;
parameter cmd_pixel_calib		=4'b1001;
parameter cmd_main_work			=4'b1010;
parameter st_idle				=4'b0000;
parameter st_dummy				=4'b0001;
parameter st_reg_set			=4'b0010;
parameter st_reg_get			=4'b0011;
parameter st_reset_dly			=4'b0100;
parameter st_reset_pixel		=4'b0101;
parameter st_reset_analog		=4'b0110;
parameter st_dly_calib			=4'b1000;
parameter st_pixel_calib		=4'b1001;
parameter st_main_work			=4'b1010;
parameter st_err=4'b1111;


input							clk;    
input							rst_n; 
input 	[7:0]					ratio_TDC; 
output reg						clk_TDC;



reg 	[7:0]				cnt;
reg		clk_TDCt;
always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 cnt<= 'd0;
		 clk_TDCt<='d0;
	end 
	else begin
		if(cnt>=ratio_TDC)begin//最后的半周期就是这个ratio+1，比如ratio为8f，143，实际半周期144。如果ratio为4，原周期30ns，变化后的是0.3us
			 cnt<='d0;
			 clk_TDCt<=~clk_TDCt;
		end
		else begin
			
			 cnt<=cnt+1'b1 ;
			 clk_TDCt<=clk_TDCt;
		end
	end
end


always @( clk or clk_TDCt or ratio_TDC) begin 				//仿照刘博的写法，暂时不要改
    if(ratio_TDC == {8{1'b1}}) begin
        clk_TDC <= clk;
    end else begin
        clk_TDC <= clk_TDCt;
    end
end






endmodule