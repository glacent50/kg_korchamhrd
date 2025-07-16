`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2025 04:08:44 PM
// Design Name: 
// Module Name: tb_or_gate
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


module tb_or_gate;
    reg a, b;
    wire q;

    or_gate_behavioral uut (.a(a), .b(b), .q(q));
    //or_gate_dataflow uut (.a(a), .b(b), .q(q));
    //or_gate_structural uut (.a(a), .b(b), .q(q));

    initial begin
        $display("Time \t a b | q");
        $monitor("%0t\t%b %b | %b", $time, a, b, q);


        // input combination test
        a = 0; b = 0 ; #10;
        a = 0; b = 1 ; #10;
        a = 1; b = 0 ; #10;
        a = 1; b = 1 ; #10;

        $finish;
    end

    
endmodule
