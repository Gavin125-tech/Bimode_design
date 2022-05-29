module top_FSM(
    
    sclk,                // SPI clock
    miso,               // Master IN slave Out
    mosi,               // Master Out slave IN
    cs_spi,
    
    CLK,                // Main clock
    RESET_async,        // Hard rst_n
    
    //for TDC
    TDC_data_in,
    READY,
    clk_TDC,
    flag_col,
    mode_select_TDC,
    SO,

    //sys
    column_enable,

    //rst
    rst_n,
    rst_analog,
    rst_dly_calib,
    rst_pixel_calib,
    rst_TDC,

    //clk,
    clk_enable,
    square_wave,

    //calib dly
    switch_dly,
    calib_dly,
  
    //calib pixel
    switch_pixel,
    sign,
    sign_pulse,

    //test port
    CMFB_en,
    bias_direct_in,
    amp_direct_out,
    bus_direct_out,
    supply_direct_in,
    TDC_test_in,
    array_probe_select,
    pixel_calib_en,

    //ongly for simulation
    cs_pixel_calib      
    
    
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



    //spi
    input sclk,mosi,cs_spi;
    output miso;
    

   //for test
    //input     [31:0] para_output;
    //input spi_ready;                                   //TDC的ready信号


    input CLK;                      // Global clock
    input RESET_async;                      // Global rst_n port
    
    //for TDC  
    input [BITS_SIG_TDC*NUM_ROW -1 :0] TDC_data_in;     				//TDC的输入接口
    input [NUM_ROW -1 :0] READY;	
    output wire clk_TDC;														//给TDC的时钟
    output wire flag_col;	                                  //输出给外部的，告诉TDC数据和地址准备好了。
    output wire mode_select_TDC;												
    output wire SO;                      //串行输出

    //sys
    output wire [NUM_COL-1 :0] column_enable;										//列选信号
   			 
    //rst
    output wire rst_analog;
    output wire rst_pixel_calib;
    output rst_n; 
    output wire  rst_TDC;
    output wire rst_dly_calib;

    //clk
    output wire clk_enable;
    output square_wave;
    
    //calib dly
    input [14:0]    switch_dly;
    output wire     calib_dly; 
  

    //calib pixel
    input [7:0]    switch_pixel;
    output wire [NUM_ROW-1:0]sign;
    output wire sign_pulse;




    
    //reg [7:0] addr_buffer;//SPI
    //reg [BITS_COL+BITS_TDC-1:0] buftemp,buftempspi;//5+5
    //wire [7:0] statue_fsm;
    




    wire spi_ready;
    wire xcvr_busy;
    assign  spi_ready= !xcvr_busy;
    //spi regs
    reg spi_ready_pulse;  // Flag signal to avoid read the same data twice; High when para_output has already been read;
    reg [1:0] spi_readyz;   //for delay 1 clk
    reg [BITS_SPI-1:0] para_input;
    wire [BITS_SPI-1:0] para_output;
    //assign  spi_ready= !xcvr_busy;
    wire flag_crc;

    //state machine
    reg [3:0] state, next_state;      // State registers
    reg [7:0] addr_buffer;
    reg [3:0] cnt_wait_spi;

    //TDC
    wire [NUM_ROW :0] wire_serial; //serial shift data connection，32，第一个TDC需要初始值，所以就不减一
    wire [NUM_ROW*BITS_UNSIG_TDC-1:0]DATABUF; //                          
    reg [CNT_COL:0]temp;
    assign rst_TDC = (!flag_col)&rst_n;

    //regArray
    reg  [7:0] regArray [NUM_BUFBYTES - 1 : 0];   
    reg  [7:0] regArray_buf [NUM_BUFBYTES - 1 : 0];                                    //18个byte的配置寄存器
    wire [15:0] ratio_enable;
    wire [7:0] ratio_TDC;
   
    wire finish_dly_calib;
    wire finish_pixel_calib;
    output wire bus_direct_out;
    output wire CMFB_en;
    output wire amp_direct_out;
    output wire bias_direct_in;
    output wire supply_direct_in;
    output wire TDC_test_in;
    output wire array_probe_select;
    output wire pixel_calib_en;


    wire part_work;
    wire rst_analog_control;
    wire [7:0] ratio_calib;

    assign amp_direct_out = regArray[0][0];
    assign bus_direct_out = regArray[0][1];
    assign part_work = regArray[0][2];
    assign CMFB_en = regArray[0][3];
    assign bias_direct_in = regArray[0][4];
    assign rst_analog_control = !regArray[0][5];
    assign supply_direct_in = regArray[0][6];
    assign TDC_test_in = regArray[0][7];
    assign array_probe_select = regArray[1][0];
    assign pixel_calib_en = regArray[1][1];
    

    assign ratio_TDC = regArray[3][7:0];
    assign ratio_enable = {regArray[5][7:0], regArray[4][7:0]};
    assign ratio_calib = regArray[6][7:0];

    
    
    

    //clk
    
    wire finish_frame;
    
    //system
    wire   rst_n;
    wire  [CNT_COL-1:0] cnt_column_sys;
    
    
    reg cs_dly_calib;
    output reg cs_pixel_calib;

    reg rst_pixel_calibt;
    reg rst_dly_calibt;
    reg rst_analogt;
    
    

    assign rst_pixel_calib =rst_n&rst_pixel_calibt;
    assign rst_dly_calib = rst_n&rst_dly_calibt;
    assign rst_analog = rst_n&rst_analogt&rst_analog_control;
    assign   mode_select_TDC = cs_dly_calib;//给TDC模式选择的

    //data output
    wire [CNT_COL-1:0] ADDRCOL;//4
    
    assign SO = temp[CNT_COL];        
    assign  wire_serial[0] = 'b0;//给第一个TDC接口的SO初始值。
    assign ADDRCOL = cnt_column_sys;//把列选技术给了ADDR
    

    //calib
    wire [CNT_DLY_CALIB-1:0]  cnt_calib_dlyj;
    wire [CNT_COL-1:0]  cnt_column_calib;
   
    
    integer ii;
    wire [17:0] cnt_clk_enable;
    


    wire [31:0] dummy_data_pack;
    wire [7:0]  CRC;
    
    assign dummy_data_pack={4'b1001,state,regArray[2][1:0],regArray[0][3],ADDRCOL,para_output[27:24],4'b0,flag_crc,CRC};


    always @(posedge CLK or negedge rst_n) begin                                            
        if (!rst_n) 
        begin
            regArray[0][7:0] <= 8'b0000_0000;
            regArray[1][7:0] <= 8'b0000_0010;
            regArray[2][7:0] <= 8'b0000_0000;
            regArray[3][7:0] <= 8'b1111_1111;
            regArray[4][7:0] <= 8'b0110_0011;
            regArray[5][7:0] <= 8'b0000_0000;
            regArray[6][7:0] <= 8'b0000_0001;

            regArray[7][7:0] <= 8'b0000_0000;
            regArray[8][7:0] <= 8'b0000_0000;
            regArray[9][7:0] <= 8'b0000_0000;
           
        end
        else begin
            regArray[0][7:0]    <=  regArray_buf[0][7:0];
            regArray[1][7:0]    <=  regArray_buf[1][7:0];    
            regArray[2][2:0]    <=  {finish_pixel_calib,finish_dly_calib};
            regArray[3][7:0]    <=  regArray_buf[3][7:0];
            regArray[4][7:0]    <=  regArray_buf[4][7:0];
            regArray[5][7:0]    <=  regArray_buf[5][7:0];
            regArray[6][7:0]    <=  regArray_buf[6][7:0];
            regArray[7][7:0]    <=  {switch_dly[7:0]};
            regArray[8][6:0]    <=  {switch_dly[14:8]};
            regArray[9][7:0]    <=  {switch_pixel[7:0]};
            

        end
    end

     
                                








    // Essentially, "spi_ready_clk" signal is a delayed (one CLK) version of spi_ready. The XOR of the two signal identify whether new data has been send by SPI module.
    
    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n) begin
            spi_readyz <= 2'b00;
            spi_ready_pulse <= 0;
        end
        else begin
            spi_readyz <= {spi_readyz[0],spi_ready};
            if (spi_readyz[0] && !spi_readyz[1])									//如果spi_readyz是01，就ready pulse，下个变成10，然后01，就相当于产生了一个pulse
            begin
                spi_ready_pulse <= 1;
            end
            else begin
                spi_ready_pulse <= 0;
            end
        end
    end
    
    // State Transition
    always @(posedge CLK or negedge rst_n) begin									//定义初始状态+下一个状态
        if (!rst_n) begin           
            state <= st_idle;
        end
        else begin
            state <= next_state;
        end
    end

    // Determine the next state
    always @(state, spi_ready_pulse, cnt_wait_spi,para_output, finish_dly_calib,finish_pixel_calib) begin							//这里要把触发条件加满
        case(state)
            st_idle:
                begin
                    if (spi_ready_pulse=='d1&&flag_crc=='d1) begin        //只有spi ready 之后，有一个clk 的pulse信号，在这个clk内配置下一个状态.用pulse大概是为了控制一次spi只执行一次
                        case(para_output[27:24])//4位
                            cmd_dummy://4'b0001
                                begin
                                    next_state <= st_idle;
                                end 
                            cmd_reg_set://4'b0010
                                begin
                                    next_state <= st_reg_set;
                                end  
                            cmd_reg_get://4'b0011
                                begin
                                    next_state <= st_reg_get;
                                end    
                            

                            cmd_reset_dly://4'b0100
                                begin
                                    next_state<=st_reset_dly;
                                end
                            cmd_reset_pixel://4'b0101
                                begin
                                    next_state<=st_reset_pixel;
                                end
                            cmd_reset_analog://4'b0110
                                begin
                                    next_state<=st_reset_analog;
                                end 


                            cmd_dly_calib://4'b1000
                                begin
                                    next_state<=st_dly_calib;
                                end
                            cmd_pixel_calib://4'b1001
                                begin
                                    next_state<=st_pixel_calib;
                                end
                            cmd_main_work://4'b1010
                                begin
                                    next_state<=st_main_work;
                                end


                            default: //All the other invalid commands
                                begin
                                    next_state <= st_idle;
                                end
                        endcase
                    end
                    else begin
                        next_state <= st_idle;    
                    end
                end
            st_reg_set://4'b0010
                begin
                    
                        if (cnt_wait_spi ==2) begin
                            next_state<= st_idle;
                        end
                        else begin
                            next_state <= state;
                        end
                    
                end
            st_reg_get://4'b0011
                begin
                    if (spi_ready_pulse=='d1&&flag_crc=='d1) begin
                        if((para_output[27:24]==cmd_reg_get)||(para_output[27:24]==cmd_dummy))
                        begin next_state <= state;
                        end
                        else begin
                            next_state<= st_idle;
                        end
                    end
                    else begin
                        next_state <= state;
                    end
                end

            
            st_reset_dly://4'b0100
                begin
                    
                        if (cnt_wait_spi ==2 ) begin   //整个rst状态持续两个SPI pulse，不用给第四个pulse来返回idle
                            next_state<= st_idle;
                        end
                        else begin
                            next_state <= state;
                        end
                    
                end
            st_reset_pixel://4'b0101
                begin
                    
                        if (cnt_wait_spi ==2 ) begin
                            next_state<= st_idle;
                        end
                        else begin
                            next_state <= state;
                        end
                   
                end
            st_reset_analog://4'b0110
                begin
                    
                        if (cnt_wait_spi ==2 ) begin
                            next_state<= st_idle;
                        end
                        else begin
                            next_state <= state;
                        end
                   
                end

            st_dly_calib://4'b1000, note that finish have to be high to move on
                begin
                    if(finish_dly_calib)
                    begin                       
                        next_state<=st_idle;
                    end
                    else begin
                        next_state <= state;
                    end
                end 
            st_pixel_calib://4'b1001
                begin
                    if(finish_pixel_calib)
                    begin                       
                        next_state<=st_idle;
                    end
                    else begin
                        next_state <= state;
                    end
                end
            st_main_work://4'b1010
                 begin 
                    if (spi_ready_pulse==1&&flag_crc=='d1)
                    begin              
                        if((para_output[27:24] == st_main_work)||(para_output[27:24] == cmd_dummy) )   //后续改成cmd_buffer!!!!!!!!!!!!!???不改了
                        begin
                            next_state <= state;
                        end
                        else   
                        begin
                            next_state <= st_idle;
                        end
                    end
                end

            default:
                begin
                    next_state <= st_idle;
                end
        endcase
    end
    


            




 
    always @(posedge CLK or negedge rst_n) begin											//配置每个状态干啥
        if (!rst_n) 
        begin
            
            para_input <= 'd0;
            addr_buffer <= 0;

            cnt_wait_spi    <=1'd0;
            rst_dly_calibt  <=1'b1;
            rst_analogt     <=1'b1;
            rst_pixel_calibt<=1'b1;
           
            

           
            cs_dly_calib         <=0;
            cs_pixel_calib       <=0;
          
            regArray_buf[0][7:0] <= 8'b0000_0000;
            regArray_buf[1][7:0] <= 8'b0000_0010;
            regArray_buf[2][7:0] <= 8'b0000_0000;
            regArray_buf[3][7:0] <= 8'b1111_1111;
            regArray_buf[4][7:0] <= 8'b0110_0011;
            regArray_buf[5][7:0] <= 8'b0000_0000;
            regArray_buf[6][7:0] <= 8'b0000_0001;

            regArray_buf[7][7:0] <= 8'b0000_0000;
            regArray_buf[8][7:0] <= 8'b0000_0000;
            regArray_buf[9][7:0] <= 8'b0000_0000;
            

            
        end
        else begin
            case (state)
                st_idle://4'b0000															//idle状态，把fsm给spi。并且把spi给的命令搞下来
                    begin
                        cnt_wait_spi        <= 'd0;

                       
                        cs_dly_calib        <=1'b0;
                        cs_pixel_calib      <=1'b0;	
		
                        para_input <= dummy_data_pack;   

                    end
                st_reg_set://4'b0010
                    begin																	//set状态，第一次从SPI读地址，第二次写寄存器。可能这个东西只能调用两次，
                        if (spi_ready_pulse==1'b1&&flag_crc=='d1)                                          //
                        begin
                            
                            cs_dly_calib <=1'b0;
                            cs_pixel_calib<=1'b0;  
                            
                            cnt_wait_spi <= cnt_wait_spi +1;
                            if (cnt_wait_spi == 0) begin 
                                addr_buffer <= para_output[23:16];
                            end
                            else if (cnt_wait_spi == 1) begin 
                                    para_input <= {4'b1001,state,addr_buffer,regArray[addr_buffer][7:0],CRC};
                                    regArray_buf[addr_buffer][7:0]<=para_output[15:8];
                            end
                            else 
                            begin
                                    addr_buffer <=addr_buffer;
                            end

                        end
                    end

                st_reg_get://4'b0011
                    begin
                        if (spi_ready_pulse==1'b1)                                                
                        begin
                           
                            cs_dly_calib<=1'b0;
                            cs_pixel_calib<=1'b0;  
                           
                            para_input <= {4'b1001,state,4'b0,cnt_wait_spi,regArray[cnt_wait_spi][7:0],CRC};
                            if (cnt_wait_spi==NUM_BUFBYTES-1) begin
                                cnt_wait_spi<='d0;
                            end
                            else begin
                                cnt_wait_spi <= cnt_wait_spi +1;
                            end

                        end
                        else begin 
                            para_input <= para_input ;
                        end
                    end
                            
                            


                st_reset_dly ://4'b0100

                    begin
                        if (spi_ready_pulse)                                               
                        begin
                            
                            cs_dly_calib<=1'b0;
                            cs_pixel_calib<=1'b0;  
                           
                            cnt_wait_spi <= cnt_wait_spi +1;

                            para_input <= dummy_data_pack;
                            if (cnt_wait_spi == 0) begin 
                                rst_dly_calibt<=0;
                                
                            end  
                            else 
                            begin 
                                rst_dly_calibt<=1;
                            end                         
                        end
                    end

                        
                    
                st_reset_pixel ://4'b0101
                    begin
                        if (spi_ready_pulse)                                               
                        begin
                           
                            cs_dly_calib<=1'b0;
                            cs_pixel_calib<=1'b0;  
                             
                            cnt_wait_spi <= cnt_wait_spi +1;
                            para_input <= dummy_data_pack;
                            if (cnt_wait_spi == 0) begin                                 
                                rst_pixel_calibt     <=0;  
                            end
                            else 
                            begin
                                rst_pixel_calibt     <=1;
                            end                           
                        end
                    end

                st_reset_analog://4'b0110
                    begin
                        if (spi_ready_pulse)                                               
                        begin
                           
                            cs_dly_calib<=0;
                            cs_pixel_calib<=1'b0;  
                            
                            cnt_wait_spi <= cnt_wait_spi +1;

                            para_input <= dummy_data_pack;
                            if (cnt_wait_spi == 0) begin 
                                
                                rst_analogt     <=0;
                                
                            end    
                            else 
                            begin
                                rst_analogt     <=1;
                            end                
                        end
                    end
                

                st_dly_calib://4'b1000
                    begin
                        
                        cs_pixel_calib<=1'b0;  
                        
                        cs_dly_calib<=1;
                        
                        para_input <= dummy_data_pack;
                        
                            
                    end

                st_pixel_calib://4'b1001
                    begin
                        
                        cs_pixel_calib<=1'b1;  
                        cs_dly_calib<=0;  

                         para_input <= {4'b1001,state,regArray[2][1:0],regArray[0][3],cnt_column_calib,8'b0,flag_crc,CRC}; 
                        
                       

                    end
                    

                st_main_work://4'b1010
                    begin
                        cs_pixel_calib<=1'b0;
                        cs_dly_calib<=1'b0; 
                        if(flag_col == 1) begin
                            para_input <= {ADDRCOL,state,1'b0,DATABUF[NUM_ROW*BITS_UNSIG_TDC-1:0],CRC}; 
                        end
                        else begin
                            para_input <= para_input;
                        end

                    end   






                default: 
                    begin
                        
                        para_input <= {4'b1001,st_err,regArray[2][1:0],regArray[0][3],ADDRCOL,para_output[27:24],4'b0,flag_crc,CRC}; //error
                        cnt_wait_spi <= 0;
                    end
            endcase
        end
    end










//sys
    async2sync_rst resetSync( 
        
        .clk             (CLK),
        .asyncrst_n      (RESET_async),
        .rst_n           (rst_n)
        );


//div clk


    div_clk_enable             divclkenable(
                                .clk                (clk_TDC),    
                                .rst_n              (rst_n),   
                                                         
                                
                                .clk_enable         (clk_enable),
                                
                                .cnt_clk_enable     (cnt_clk_enable),
                                .ratio_enable    (ratio_enable)

    );

    div_clk_TDC             divclkTDC(
                                .clk            (CLK),    
                                .rst_n          (rst_n),  

                                .ratio_TDC      (ratio_TDC),   
                                .clk_TDC        (clk_TDC)
    
    );
   

//sys_enable
    
    sys_column_enable   syscolumenable (
                            .CLK                    (clk_TDC        ),  
                             
                            .rst_n                  (rst_n          ),
                           
                            .part_work              (part_work   ),
                            .cnt_clk_enable         (cnt_clk_enable),
                            .ratio_enable           (ratio_enable),
                            
                            .column_enable          (column_enable  ),
                            .finish_frame           (finish_frame   ),
                            .flag_col               (flag_col       ),
                            .cnt_column_sys         (cnt_column_sys )

    
);



  


    SPI_FSM U0(
    
        .sclk               (sclk),        
        .miso               (miso),       
        .mosi               (mosi),      
        .cs_spi             (cs_spi), 

        .rst_n_spi          (rst_n),      
        .para_output        (para_output),   
        .para_input         (para_input),  
        .xcvr_busy          (xcvr_busy)
    );


    crc_check_slave U1(
    	.data_in 	(para_output[31:8]), // 24 data + 8 bit CRC code
     	.crc_in 	(para_output[7:0]), // 24 data + 8 bit CRC code
     	.flag_crc 	(flag_crc),
     	.crc_new 	(CRC) 
    	);

//all TDC interface
    //1.TDC data. o_TDC<15:0> and ready


    /*
    generate
        genvar cnt_TDCi;
        for (cnt_TDCi = 0; cnt_TDCi < NUM_ROW; cnt_TDCi = cnt_TDCi + 1) begin: tdci
            
            TDC_interface TDCinterface(                                

                .clk(clk_TDC),                
                .rst_TDC_interface(rst_n),                
                .flag_col(flag_col),
                .SI(wire_serial[cnt_TDCi]),
                .SO(wire_serial[cnt_TDCi+1]),
                .BUF1(DATABUF[cnt_TDCi*BITS_UNSIG_TDC+BITS_UNSIG_TDC-1:cnt_TDCi*BITS_UNSIG_TDC]),//输出无符号
                .ready(READY[cnt_TDCi]),
                .TDC_data_i(TDC_data_in[cnt_TDCi*BITS_SIG_TDC+BITS_SIG_TDC-1:cnt_TDCi*BITS_SIG_TDC])//输入是有符号的
                
            );

        end
    endgenerate*/
    TDC_interface TDCinterface(                                

                .clk(clk_TDC),                
                .rst_TDC_interface(rst_n),                
                .flag_col(flag_col),
                .SI(wire_serial[0]),
                .SO(wire_serial[1]),
                .BUF1(DATABUF[BITS_UNSIG_TDC-1:0]),//输出无符号
                .ready(READY[0]),
                .TDC_data_i(TDC_data_in[BITS_SIG_TDC-1:0])//输入是有符号的
                
            );



    //2.TDC calib enable. enable_delayline
    dly_calib dlycalib(
                   .clk_div_enable  (clk_enable),
                   .rst_n           (rst_dly_calib),
                   .cs_dly_calib    (cs_dly_calib),
                   .calib_dly       (calib_dly),
                   .finish_dly_calib(finish_dly_calib),
                   .cnt_calib_dlyj  (cnt_calib_dlyj)

        
    );
 
    //3.other TDC.1)clk should be TDC_clk. 2)mode_sele when 0, normal work,when 1 calib 3) rst_ 
   





//pixel calib model
    
    pixel_calib pixelcalib (
                        .clk                (clk_TDC),   
                        .rst_calib          (rst_pixel_calib),  
                        .cnt_column_sys     (cnt_column_sys),       
                        .cs_pixel_calib     (cs_pixel_calib),
                        .finish_frame       (finish_frame),
                        .flag_col           (flag_col),
                        .DATABUF            (DATABUF),
                        .ratio_calib        (ratio_calib),
                        

                        .sign               (sign),
                        .sign_pulse         (sign_pulse),                   
                        .finish_pixel_calib (finish_pixel_calib),
                        .cnt_column_calib   (cnt_column_calib),
                        .square_wave        (square_wave)

    );








    
    always @(posedge clk_TDC or negedge rst_n) begin 
        if(~rst_n) begin
             temp<= 0;
        end 
        else 
        begin
            if(flag_col == 1'b1) begin                         
                temp[CNT_COL-1:0]<=cnt_column_sys[CNT_COL-1:0]-'d1;             
            end
            else begin
                temp<={temp[CNT_COL-1:0],wire_serial[NUM_ROW]};
            end
             
        end
    end
  






endmodule
