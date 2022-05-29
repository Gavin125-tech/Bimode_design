module div_clk_enable (
								clk,    
								rst_n,  
								
								ratio_enable,
								clk_enable,
								
								
								cnt_clk_enable
								
	
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

input [15:0]					ratio_enable; 
output reg						clk_enable;

output reg 	[17:0]	cnt_clk_enable;


always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 cnt_clk_enable<= 'd0;
		 clk_enable<='b0;
		 
	end 
	else begin
		
			if(cnt_clk_enable>=(ratio_enable+1'b1)*2-1'b1)begin   
			 cnt_clk_enable<='d0;
			 clk_enable<=~clk_enable;

			end
			else if(cnt_clk_enable==ratio_enable)		//专门分成了两部分，后一次判断用来生成flag_col的//默认值应该为99  
														//最后的半周期就是这个ratio+1，比如ratio为8f，143，实际半周期144,这里需要默认值为99.
			begin
				clk_enable<=~clk_enable;	
				cnt_clk_enable<=cnt_clk_enable+1'b1;  
			end
			
			else begin
			
			 cnt_clk_enable<=cnt_clk_enable+1'b1;
			 clk_enable<=clk_enable;
			
			
			end
	end

end
endmodule