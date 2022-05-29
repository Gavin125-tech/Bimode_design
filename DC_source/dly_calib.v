//by yanpeng2020.12.28
//15 cycles of row*2 pulse
//note : the input clk should be TDC clk, if down freq the dalayline can delay new time
//change log: 2021.2.22 yanpeng
//all TDC use same pulse wire
module dly_calib (
				clk_div_enable	,
				rst_n			,
				cs_dly_calib	,
				calib_dly		,
				finish_dly_calib,
				cnt_calib_dlyj
				

	
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



	
input 						clk_div_enable	;    
input 						rst_n			;
input 						cs_dly_calib	;
output	reg				 	calib_dly		;
output	reg					finish_dly_calib; 
output reg [CNT_DLY_CALIB-1:0] 	cnt_calib_dlyj;

reg [2:0]	cnt_calib_dlyi;



always @(posedge clk_div_enable or negedge rst_n) begin                       
        if(~rst_n) begin
            cnt_calib_dlyi<='d0;
            cnt_calib_dlyj<='d0;
            calib_dly<='d0;
            finish_dly_calib<=0;
        end 
        else begin
        	if((cs_dly_calib)&&(!finish_dly_calib))begin

	             if (cnt_calib_dlyj >= BITS_DLY_SWITCH) begin//应该为BITS_CALIBDLY，这里的cnt=6还会持续一个clk，才会被下一个clk判断.还是会产生6个pulse
	                cnt_calib_dlyj <= 0;
	                cnt_calib_dlyi <= 0;
	                finish_dly_calib<=1;
	                calib_dly<='d0;
	                end
	             else begin
	             	if (cnt_calib_dlyi==7) begin//当时可能就是为了等待足够长的时间，让它稳定，2us*8,16us
	             		cnt_calib_dlyi<=0;
	             		cnt_calib_dlyj<=cnt_calib_dlyj+1;
	             	end
	             	else begin
	             		if (cnt_calib_dlyi==0) begin
	             			calib_dly<=1;
	             			cnt_calib_dlyi<=cnt_calib_dlyi+1;
	             		end
	             		
	             		else begin
	             			cnt_calib_dlyi<=cnt_calib_dlyi+1;
	             			calib_dly<=0;
	             		end
	             	end
	             	

	             	
				end
			end
	        else begin
	        	calib_dly<='d0;
	        	cnt_calib_dlyj <= 0;
	            cnt_calib_dlyi <= 0;
	        end



             
       end
end

endmodule