`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 10:22:03 AM
// Design Name: 
// Module Name: tb_comparator
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


module tb_comparator;

    // 입력 신호 선언
    reg [3:0] a, b;
    
    // 출력 신호 선언
    wire equal, greater, less;
    
    // DUT (Device Under Test) 인스턴스
    comparator_dataflow uut (
        .a(a),
        .b(b),
        .equal(equal),
        .greater(greater),
        .less(less)
    );
    

    initial begin
        $display("Time \t a \t b \t | equal greater less");
        $monitor("%0t  \t %b\t %b\t | %b    %b      %b  ", $time, a, b, equal, greater, less);

        //테스트용
        a = 0; b = 0; #10;
        a = 0; b = 1; #10;
        a = 1; b = 0; #10;
        a = 1; b = 1; #10;

        $finish;
    end

endmodule


module tb_comparator_4bit_full;

    reg [3:0]a, b;
    wire equal, greater, less;

    // DUT

    comparator_Nbit #(.N(4)) dut (
        .a(a),
        .b(b),
        .equal(equal),
        .greater(greater),
        .less(less)
    );

    integer i, j;

    initial begin
        $display("Time\t a\t   b\t | \tequal \tgreate \tless");
        $monitor("%4t\t  %b\t  %b\t|  %b\t    %b\t     %b\t ", $time, a, b, equal, greater, less);

        // 모드 조합 테스트 (a -> 0 ~ 15, b -> 0 ~ 15)
        for (i=0 ; i<16 ; i = i+1) begin
            for(j=0 ; j < 16 ; j = j + 1) begin
                a=1;
                b=j;
                #5;
            end
        end

        $finish;

    end

    
endmodule


