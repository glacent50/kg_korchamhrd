`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2025 04:26:45 PM
// Design Name: 
// Module Name: tb_full_adder
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


module tb_full_adder;

    reg a, b, cin;
    wire sum, carry;

    full_adder_structural uut(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .carry(carry)
    );

    initial begin
        $display("A B Cin | Sum Carry");
        $display("-------------------");

        a = 0; b = 0; cin = 0; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 0; b = 0; cin = 1; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 0; b = 1; cin = 0; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 0; b = 1; cin = 1; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 1; b = 0; cin = 0; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 1; b = 0; cin = 1; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 1; b = 1; cin = 0; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        a = 1; b = 1; cin = 1; #10;
        $display("%b %b %b | %b %b", a, b, cin, sum, carry);

        $finish;
    end

endmodule



module tb_full_adder_tb;

    reg a, b, cin;
    wire sum, carry;

    // 0 = behavioral, 1 = dataflow
    parameter USE_DATAFLOW = 0;

    generate
        if (USE_DATAFLOW == 0) begin : behav
            full_adder_behavioral uut(
                .a(a),
                .b(b),
                .cin(cin),
                .sum(sum),
                .carry(carry)
            );
        end
        else begin : dataf
            full_adder_dataflow uut(
                .a(a),
                .b(b),
                .cin(cin),
                .sum(sum),
                .carry(carry)
            );
        end
    endgenerate

    initial begin
        a = 0; b = 0; cin = 0;

        repeat (8) begin
            #10;
            {a, b, cin} = {a, b, cin} + 1;
        end
        #10;
        $finish;
    end

    initial begin
        $display("Time\t a b cin | sum carry");
        $monitor("%0t\t %b %b %b | %b %b", $time, a, b, cin, sum, carry);

    end

endmodule


module tb_fadder_4bit_structual;

    reg [3:0] a, b;
    reg cin;
    wire [3:0] sum;
    wire carry;

    fadder_4bit_structural uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .carry(carry)
    );

    initial begin
    
        $display("Time\t cin\t a\t  b\t  sum\t carry");
        $monitor("%0t\t  %b\t  %b\t %b\t %b\t  %b\t", $time, cin, a, b, sum, carry);


        // 테스트용
        cin = 0; a = 4'b0000; b = 4'b0000; #10;
        cin = 0; a = 4'b0001; b = 4'b0001; #10; 
        cin = 1; a = 4'b0010; b = 4'b0011; #10;
        cin = 0; a = 4'b1111; b = 4'b0001; #10;
        cin = 1; a = 4'b0101; b = 4'b0101; #10;
        cin = 0; a = 4'b1111; b = 4'b1111; #10;
        cin = 1; a = 4'b1111; b = 4'b1111; #10;

        #10 $finish;
    end

endmodule


module tb_fadder_sub_4bit;

    reg [3:0] a, b;
    reg s;
    wire [3:0] sum;
    wire carry;

    // 0 = Beavioral, 1 = dataflow
    parameter USE_BEHAVIORAL = 0;

    generate
        if (USE_BEHAVIORAL == 0) begin : behav
            fadder_sub_4bit_behavioral uut (
                .a(a),
                .b(b),
                .s(s),
                .sum(sum),
                .carry(carry)
            );
        end else begin : dataf
            fadder_sub_4bit_dataflow uut (
                .a(a),
                .b(b),
                .s(s),
                .sum(sum),
                .carry(carry)
            );
        end
    endgenerate


    // fadder_sub_4bit_structural uut (
    //     .a(a),
    //     .b(b),
    //     .s(s),
    //     .sum(sum),
    //     .carry(carry)
    // );

    integer i, j;

    initial begin
    
        $display("Time\t  a  b   S | sum\t carry");
        $monitor(" %0t\t  %b %b  %b | %b\t  %b\t", $time, a, b, s, sum, carry);

        for (i=0 ; i<16 ; i = i + 1) begin
            for (j=0 ; j<16 ; j = j+1) begin
                a = i;
                b = j;
                //덧셈
                s = 0;
                #10;
                //뺄셈
                s = 1;
                #10;
            end
        end
        
        $finish;
    end

endmodule





