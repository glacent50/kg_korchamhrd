`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2025 03:45:47 PM
// Design Name: 
// Module Name: tb_half_adder_N_bit
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


module tb_half_adder_N_bit;

parameter N = 8;

reg inc;
reg [N-1:0] load_data;
wire [N-1:0] sum;

half_adder_N_bit #(N) uut(
    .inc(inc),
    .load_data(load_data),
    .sum(sum)
);

initial begin
    $display("Time\t inc\t load_data\t | \tsum");
    $monitor("%0t\t %b\t %b\t | \t%b", $time, inc, load_data, sum);

    //테스트용
    inc = 0; load_data =  8'b00000000; #10;
    inc = 1; load_data =  8'b00000000; #10;
    inc = 1; load_data =  8'b00000001; #10;
    inc = 1; load_data =  8'b00001111; #10;
    inc = 1; load_data =  8'b11111111; #10;
    inc = 0; load_data =  8'b10101010; #10;
    inc = 1; load_data =  8'b10101010; #10;

end

endmodule

