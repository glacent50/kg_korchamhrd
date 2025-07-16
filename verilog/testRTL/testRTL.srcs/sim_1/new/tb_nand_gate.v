`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2025 09:32:07 AM
// Design Name: 
// Module Name: tb_nand_gate
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


module tb_nand_gate;
    reg a, b;
    wire q;

    nand_gate_behavioral uut (.a(a), .b(b), .q(q));
    //nand_gate_dataflow uut (.a(a), .b(b), .q(q));
    //nand_gate_structural uut (.a(a), .b(b), .q(q));

    initial begin
        $display("Time \t a b | q");
        $monitor("%4t \t %b %b | %b", $time, a, b, q);

        // input combination test
        a = 0; b = 0 ; #10;
        a = 0; b = 1 ; #10;
        a = 1; b = 0 ; #10;
        a = 1; b = 1 ; #10;

        $finish;
    end
endmodule