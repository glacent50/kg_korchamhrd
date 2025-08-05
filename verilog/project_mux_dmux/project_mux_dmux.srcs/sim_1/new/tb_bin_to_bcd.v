`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 02:07:56 PM
// Design Name: 
// Module Name: tb_bin_to_bcd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_bin_to_dec;
    reg [11:0] bin;
    reg [15:0] bcd;

    bin_to_dec uut ( 
        .bin(bin),
        .bcd(bcd)
    );

    initial begin
        bin = 12'b0;

        #10 bin = 12'b0000_0000_0000;
        #10 bin = 12'b0000_0000_0001;
        #10 bin = 12'b0000_0000_1001;
        #10 bin = 12'b0000_0001_0100;
        #10 bin = 12'b0000_1011_0101;
        #10 bin = 12'b1011_0110_1101;
        #10 bin = 12'b1111_1111_1111;

        #20 $stop;   // 시뮬레이션 종료
    end

    initial begin
        $monitor("Time=%t | bin=%b (%d) --> BCD=%b (BCD digit:%0d%0d%0d%0d)",
                  $time, bin, bin, bcd, bcd[15:12], bcd[11:8], bcd[7:4], bcd[3:0]);
    end
    


endmodule
