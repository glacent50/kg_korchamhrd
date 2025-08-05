`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 11:48:33 AM
// Design Name: 
// Module Name: bcd
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

// 참고 : https://rocketnoning.tistory.com/22
module bin_to_dec(
    input [11:0] bin,      //12 bit 이진 입력
    output reg [15:0] bcd  // 4 자리의 BCD output (4비트 X 4자리)
    );
    
    integer i;             // 반복문 
    always @(bin) begin
        bcd = 0;
        for (i = 0; i <12 ; i = i + 1) begin
            // 1) 각 BCD 자리(4비트)가 5 이상이면 3을 더함
            if (bcd[3:0] >= 5) bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] >= 5) bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] >= 5) bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;

            // 2) 1 비트 left shift + 새로운 비트 붙임
            bcd = {bcd[14:0], bin[11-i]};
        end
    end
        
endmodule
