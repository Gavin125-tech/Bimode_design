module crc_check_slave (

      data_in, // 24 data + 8 bit CRC code
      crc_in, // 24 data + 8 bit CRC code
      flag_crc, // high if crc validated
     //ready_crc, // high if crc is done
     crc_new // new crc
);


parameter LEN_PACKET = 32 ; //packet data 
parameter LEN_DATA = 24 ; //packet data 
parameter LEN_CRC = 8 ; //packet data 

input [LEN_DATA-1:0]  data_in;
input [LEN_CRC-1:0]  crc_in;
output reg [LEN_CRC-1:0]  crc_new;
output reg flag_crc;

//output reg [LEN_SPI-1:0] rx_spi_data;
//output reg flag_crc;
//output reg rx_spi_data;
//reg [LEN_CRC-1:0] crc_code;

always @(*) begin 
          //ready_crc = 1;
          crc_new = nextCRC8_D24(data_in,8'h00);
         if (  (crc_new==crc_in))begin 
            flag_crc = 1;
         end
         else begin 
            flag_crc = 0;
         end
end

    //crc8 0x97
  // polynomial: x^8 + x^5 + x^3 + x^2 + x^1 + 1
  // data width: 24
  // convention: the first serial bit is D[23]
  function [7:0] nextCRC8_D24;

    input [23:0] Data;
    input [7:0] crc;
    reg [23:0] d;
    reg [7:0] c;
    reg [7:0] newcrc;
  begin
    d = Data;
    c = crc;

    newcrc[0] = d[23] ^ d[22] ^ d[21] ^ d[15] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[0] ^ c[5] ^ c[6] ^ c[7];
    newcrc[1] = d[21] ^ d[16] ^ d[15] ^ d[13] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[5];
    newcrc[2] = d[23] ^ d[21] ^ d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[5] ^ c[7];
    newcrc[3] = d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[1] ^ c[2] ^ c[5] ^ c[7];
    newcrc[4] = d[22] ^ d[19] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[1] ^ c[2] ^ c[3] ^ c[6];
    newcrc[5] = d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[0] ^ c[2] ^ c[3] ^ c[4] ^ c[5] ^ c[6];
    newcrc[6] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ c[3] ^ c[4] ^ c[5] ^ c[6] ^ c[7];
    newcrc[7] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ c[4] ^ c[5] ^ c[6] ^ c[7];
    nextCRC8_D24 = newcrc;
  end
  endfunction
endmodule