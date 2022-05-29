module sys_column_enable (
							CLK ,			 										
							rst_n,
							
							part_work,
							cnt_clk_enable,
							ratio_enable,
							

							column_enable,
							finish_frame,
							flag_col,
							cnt_column_sys

	
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



input 					CLK 				; 
input 					rst_n 				; 
input 				part_work 				;//单pixel工作
input 			[17:0]   cnt_clk_enable		;		
input 			[15:0]	ratio_enable 	;	


output 	reg	[NUM_COL-1:0]	column_enable;
output 	reg					finish_frame;
output	reg					flag_col;
output	reg	[CNT_COL-1:0]	cnt_column_sys;
wire [17:0] test;
assign  test=((ratio_enable+1)*2-1);
always @(posedge CLK or negedge rst_n) begin          		
	if(~rst_n) begin
		cnt_column_sys<= 0;
		flag_col<=0;
		 column_enable<=0;

		 
	end 
	else begin
		
			column_enable <= {{(NUM_ROW-1){1'b0}},{1'b1}} << cnt_column_sys;
			if(cnt_clk_enable>=((ratio_enable+1)*2-1))
			begin
				flag_col<=1;
				case (part_work)
					1'b0://work
						begin
							if (cnt_column_sys>=NUM_COL-1) begin	
								cnt_column_sys<=0;	
								finish_frame<=1;	
							end
							else begin
								cnt_column_sys<=cnt_column_sys+1;
								finish_frame<=0;
							end
						end
					1'b1://one work
						begin
							if (cnt_column_sys>=3) begin
								cnt_column_sys<=0;
								finish_frame<=1;	
							end
							else begin
								cnt_column_sys<=cnt_column_sys+1;
								finish_frame<=0;
							end
						end
					

					default :
						begin
							if (cnt_column_sys>=NUM_COL-1) begin//cnt_column_sys==NUM_COL*2-1
								cnt_column_sys<=0;
								finish_frame<=1;	
							end
							else begin
								cnt_column_sys<=cnt_column_sys+1;
								finish_frame<=0;
							end
						end 
				endcase
				
		 	end
		 	else begin 
		 		cnt_column_sys<=cnt_column_sys;
		 		flag_col<=0;
		 		finish_frame<=0;
		 	end
		
	 	

	end



end

endmodule