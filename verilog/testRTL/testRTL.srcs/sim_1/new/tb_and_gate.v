`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2025 12:41:55 PM
// Design Name: 
// Module Name: tb_and_gate
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

module tb_and_gate;

    reg a, b;
    wire q;

    and_gate_behavioral uut (.a(a), .b(b), .q(q));
    //and_gate_dataflow uut (.a(a), .b(b), .q(q));
    //and_gate_structural uut (.a(a), .b(b), .q(q));

    initial begin
        $display("Time\ta b | q");
        $display("--------------------");
        $monitor("%4t\t%b %b | %b", $time, a, b, q);

        a = 0; b = 0; #10;
        a = 0; b = 1; #10;
        a = 1; b = 0; #10;
        a = 1; b = 1; #10;

        $display("Simulation completed successfully");
        $finish;
    end
endmodule
