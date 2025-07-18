`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 11:42:52 AM
// Design Name: 
// Module Name: 
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


module tb_decoder;

    reg [1:0] code;
    wire [3:0] signal;

    decoder_2x4_behavioral d_b(
        .code(code),
        .signal(signal)
    );
    

    initial begin
        $display("Time\t code\t behavioral");
        $monitor("%0t\t %b\t %4b", $time, code, signal);

        code = 2'b00; #10;
        code = 2'b01; #10;
        code = 2'b10; #10;
        code = 2'b11; #10;
        
        $display("Simulation completed");
        $finish;
    end


endmodule


module tb_encoder_4x2_behaviral;

    reg [3:0] signal;
    wire [1:0] code;

    encoder_4x2_behavioral e_b(
        .signal(signal),
        .code(code)
    );
    
    initial begin
        $display("Time\t signal\t code");
        $monitor("%0t\t %4b\t %b", $time, signal, code);
        
        signal = 4'b0000;   // 초기화

        #10; signal = 4'b0001;   // code should be 00
        #10; signal = 4'b0010;   // code should be 01
        #10; signal = 4'b0100;   // code should be 10
        #10; signal = 4'b1000;   // code should be 11
 

        #10; signal = 4'b0000;   // 유효하지 않은 입력 (모든 비트가 0)
        #10; signal = 4'b0011;   // 다중 비트 활성화 (우선순위에 따라 결정됨)

        #10; $finish;
    end

endmodule