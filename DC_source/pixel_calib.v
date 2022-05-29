//by yanpeng2020.2.21
//cnt_column_sys means the column number when work or calib, when half work, the number should be 0-24,and 25-49
//finish frame, when the cnt_column_sys is max, when half work, half cnt can make finish frame 1
//flag_col is sys flag col
//DATABUF is TDC DATABUF
//sign control 50 sign 
//sign pulse:all pixel use the same one
//cnt half is used to tell top the half has finish then the cnt will be 25-49
 
 //这个还需要考虑，所有的校准用同一个pulse信号，所有的计算是否能全部完成。4.13 pulse的选通换成了下一个pixel的
//要考虑阵列末端的flag_col能不能顺利进来

module pixel_calib (
						clk,    
						rst_calib,  
						cnt_column_sys,		//需要统一控制列选
						cs_pixel_calib,
						finish_frame,
						flag_col,
						DATABUF,
						ratio_calib,
						
					 	sign,
					 	sign_pulse, 
					 	
					 	finish_pixel_calib,
					 	cnt_column_calib,
					 	square_wave

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



	input 			clk;    
	input 			rst_calib;  
	input 	[CNT_COL-1:0]	cnt_column_sys;		//需要统一控制列选
	input 			cs_pixel_calib;
	input 			finish_frame;
	input 			flag_col;
	input 	[BITS_UNSIG_TDC*NUM_ROW-1:0]		DATABUF;
	input [7:0] ratio_calib;

	output reg 	[NUM_ROW-1:0]	sign;

	output reg 		sign_pulse; 
	output reg 		finish_pixel_calib;
	output reg 		square_wave;

	 reg [9:0]cnt_frame;      //记录阵列第几次刷新,因为ratio是8bit的，为了防止计算溢出加至10bit
	 reg [7:0]cnt_switch;	 //第几个开关
output reg [CNT_COL-1:0]cnt_column_calib;	//第几列

reg [BITS_UNSIG_TDC*NUM_ROW-1:0]regRecord;


reg flag_calib;
reg sign_flag;
reg sign_pulse_t;
wire flag_calib_two;
reg [9:0] cnt_square;

always @(posedge clk or negedge rst_calib) begin 
	if(~rst_calib) begin
		  square_wave<= 0;
		  cnt_square<='d0;//其实和cnt_frame相等
	end 
	else begin
		if (cs_pixel_calib) begin
			 if (finish_frame) begin
			 	
			 	if (cnt_square < ratio_calib ) begin
			 		square_wave<= 1'b1;
			 		cnt_square<=cnt_square+1;
			 	end
			 	else if(cnt_square==(ratio_calib+1'b1)*2-1'b1) begin
			 		square_wave<= 1'b1;
			 		cnt_square<='d0;
			 	end
			 	else begin
			 		square_wave<= 1'b0;
			 		cnt_square<=cnt_square+1;
			 	end
			 end
			 else begin
			 	cnt_square<=cnt_square;
			 end
		end
		else begin
			square_wave<=0;
			cnt_square<=0;
		end

	end
end









always @(posedge clk or negedge rst_calib) begin 
	if(~rst_calib) begin
		
		cnt_frame<= 0;//多少次阵列循环
		cnt_switch<=0;//多少次开关
		cnt_column_calib<=0;//多少列了
		finish_pixel_calib<=0;
		
	end 
	else begin
		if((cs_pixel_calib)&(!finish_pixel_calib))
		begin
			
			if (cnt_column_calib=='d2) begin //应该为NUM_COL  这里设置为N，N值持续一个clk，不影响效果。
				cnt_column_calib<=0;
				finish_pixel_calib<=1'b1;
			end
			else begin
				
			 
				if (cnt_switch=='d60) begin     //应该为127.修改后，建议改多出一些余量，150次     这里比如设置为N，实际中N只持续一个clk。
						cnt_switch<=0;
						cnt_column_calib<=cnt_column_calib+1;					//改动这一块是因为，循环次数没有达到预期。上下有一个先后等级。这一块应该去并行。就维持目前的状态即可
				end
				else begin
					if (finish_frame==1'b1) begin
						if(cnt_frame==(ratio_calib+1'b1)*2-1'b1) begin//当ratio为3的时候，应该为7
							cnt_frame<=0;
							cnt_switch<=cnt_switch+1;
						end
						else begin
							cnt_frame<=cnt_frame+1;
						end
					end
					else begin
						cnt_frame<=cnt_frame;
						cnt_column_calib<=cnt_column_calib;
						cnt_switch<=cnt_switch;
					end
				end
			end

		end
		else begin
			cnt_frame<= 0;
			cnt_switch<=0;
			cnt_column_calib<=0;
			
			
		end
		 
	end
end



always @(posedge clk or negedge rst_calib) begin
	if(~rst_calib) begin
		 flag_calib<= 0;
	end 
	else begin
		if((cs_pixel_calib)&(!finish_pixel_calib)) begin//让外界的计数器和内部计数器相等的时候，给出一个高
			if(cnt_column_calib==cnt_column_sys)		//这里flag_calib是比cnt晚一个周期的，刚刚好包括了flag-col,能让他通过
				flag_calib<=1;							//而且延后了一个周期，使得上一个周期的flag没有进来
			else begin
				flag_calib<=0;
			end
		end
		else begin
			flag_calib<= 0;
		end
	end
end


assign flag_calib_two=flag_calib&flag_col; 				//希望外部的flag_col能在必要的时候进来，而且不出现延时.这里会导致一些延迟，但是不影响下面的触发
integer jj;
always @(posedge clk or negedge rst_calib) begin 
	if(~rst_calib) begin
		regRecord<='d0;
		
		sign<='d0;
		sign_flag<='d0;
		
		
	end
	else begin
		if((cs_pixel_calib)&(!finish_pixel_calib))
		begin
			if (flag_calib_two) 
			begin
				if (cnt_frame==ratio_calib) //  当ratio=3的时候，这里应该为3
				begin
					regRecord<= DATABUF;
					
					sign_flag<=0;
				end
				else if(cnt_frame==(ratio_calib+1'b1)*2-1'b1)//当ratio=3的时候，这里应该为7
				begin
					//for(jj = 0;jj < NUM_ROW; jj=jj+1 )
					//begin

						//if(regRecord[(jj+1)*BITS_UNSIG_TDC-1-:BITS_UNSIG_TDC] >=DATABUF[(jj+1)*BITS_UNSIG_TDC-1-:BITS_UNSIG_TDC])  //自带了buffer，不需要再加
						if(regRecord[BITS_UNSIG_TDC-1:0] >=DATABUF[BITS_UNSIG_TDC-1:0]) //上面应该搞错了？
						begin
								sign[0]<='d0;				//第一次记录大于第二次记录时，说明负电压不足，需要减小电容，增加负电压
								sign_flag<=1'b1;
								
						end
						else  
						begin
								sign[0]<=1'b1;
								sign_flag<=1'b1;
								
						end
					//end


					

				end
				else 
				begin
					
					sign_flag<=sign_flag;
					sign<=sign;
				end
			end
			else begin
				sign<=sign;
			 	sign_flag<=1'b0;
			 	
			end
		end
		else begin
			sign<='d0;
		 	sign_flag<=1'b0;
			
		end

	end
end










always @(posedge clk or negedge rst_calib) begin 
	if(~rst_calib) begin
		sign_pulse_t<=1'b0;
	end 
	else begin
		if(sign_flag==1) begin
			 sign_pulse_t<=1'b1;
		end
		else begin
			sign_pulse_t<=1'b0 ;
		end
		
	end
end

always @(posedge clk or negedge rst_calib) begin 
	if(~rst_calib) begin
		sign_pulse<=1'b0;
	end 
	else begin
		if(sign_pulse_t==1) begin
			 sign_pulse<=1'b1 ;
		end
		else begin
			sign_pulse<=1'b0 ;
		end
		
	end
end




endmodule











