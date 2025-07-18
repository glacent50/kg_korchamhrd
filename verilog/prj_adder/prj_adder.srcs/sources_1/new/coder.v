`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 11:33:52 AM
// Design Name: 
// Module Name: coder
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


module decoder_2x4_behavioral(
    input [1:0] code,
    output reg [3:0] signal
    );

    // always @(code) begin
    //     if (code == 2'b00) signal = 4'b0001;
    //     else if (code == 2'b01) signal = 4'b0010;
    //     else if (code == 2'b10) signal = 4'b0100;
    //     else signal = 4'b1000;    
    // end

    always @(code) begin
        case (code)
            2'b00: signal = 4'b0001;
            2'b01: signal = 4'b0010;
            2'b10: signal = 4'b0100;
            2'b11: signal = 4'b1000;
        endcase
    end


endmodule



module decoder_2x4_dataflow (
    input [1:0] code,
    output [3:0] signal
);

    assign signal = (code == 2'b00) ? 4'b0001 :
                    (code == 2'b01) ? 4'b0010 :
                    (code == 2'b10) ? 4'b0100 : 4'b1000 ;
    
endmodule


module decoder_2x4_dataflow_d (
    input [1:0] code,
    output [3:0] signal
);

    assign signal[0] = (~code[1]) & (~code[0]);
    assign signal[1] = (~code[1]) & ( code[0]);
    assign signal[2] = ( code[1]) & (~code[0]);
    assign signal[3] = ( code[1]) & ( code[0]);
    
endmodule


module decoder_2x4_structual (
    input [1:0] code,
    output [3:0] signal
);
    wire n0, n1;    // not 신호

    not u_not0 (n0, code[0]);
    not u_not1 (n1, code[1]);

    and u_and0 (signal[0], n1, n2);
    and u_and1 (signal[1], n1, code[0]);
    and u_and2 (signal[2], code[1], n0);
    and u_and3 (signal[3], code[1], code[0]);
 
endmodule



module decoder_7seg (
    input [3:0] hex_value,
    output reg [7:0] seg_7,
    output reg [3:0] com_an
);
    
    always @(hex_value) begin
        case (hex_value)
            4'b0000: seg_7 = 8'b11000000; // 0
            4'b0001: seg_7 = 8'b11111001; // 1
            4'b0010: seg_7 = 8'b10100100; // 2
            4'b0011: seg_7 = 8'b10110000; // 3
            4'b0100: seg_7 = 8'b10011001; // 4
            4'b0101: seg_7 = 8'b10010010; // 5
            4'b0110: seg_7 = 8'b10000010; // 6
            4'b0111: seg_7 = 8'b11111000; // 7
            4'b1000: seg_7 = 8'b10000000; // 8
            4'b1001: seg_7 = 8'b10010000; // 9
            4'b1010: seg_7 = 8'b10001000; // A
            4'b1011: seg_7 = 8'b10000011; // b
            4'b1100: seg_7 = 8'b11000110; // C
            4'b1101: seg_7 = 8'b10100001; // d
            4'b1110: seg_7 = 8'b10000110; // E
            4'b1111: seg_7 = 8'b10001110; // F
        endcase
        
        // 첫 번째 디지트만 활성화 (common anode)
        com_an = 4'b1110;
    end

endmodule


module encoder_4x2_behavioral (
    output reg [1:0] code, // 2비트 출력 : 입력중에 커진 위치를 이진수로 출력
    input [3:0] signal     // 4비트 입력 : 4개의 신호중에 하나가 1이라고 가정 !!
);
    
    always @(signal) begin
        // if (signal == 4'b0001) 
        //     code = 2'b00;
        // else if (signal == 4'b0010) 
        //     code = 2'b01;
        // else if (signal == 4'b0100) 
        //     code = 2'b10;
        // else  
        //     code = 2'b11;

        case (signal)
            4'b0001: code = 2'b00;
            4'b0010: code = 2'b01;
            4'b0100: code = 2'b10;
            4'b1000: code = 2'b11;
            default: code = 2'b00;
        endcase
    end
    
endmodule

module encoder_4x2_dataflow (
    output [1:0] code, // 2비트 출력 : 입력중에 커진 위치를 이진수로 출력
    input [3:0] signal     // 4비트 입력 : 4개의 신호중에 하나가 1이라고 가정 !!
);

    // 이전 코드
    // assign code[0] = signal[1] | signal[3];
    // assign code[1] = signal[2] | signal[3];

    assign code = (signal == 4'b0001) ? 2'b00 :
                 (signal == 4'b0010) ? 2'b01 :
                 (signal == 4'b0100) ? 2'b10 :
                 (signal == 4'b1000) ? 2'b11 : 2'b00;

endmodule


module encoder_4x2_structural (
    output [1:0] code, // 2비트 출력 : 입력중에 커진 위치를 이진수로 출력
    input [3:0] signal     // 4비트 입력 : 4개의 신호중에 하나가 1이라고 가정 !!
);
    wire a0, a1;

    // 입력값이 0100 또는 1000 일 경우 code[1]은 1
    or or1 (a1, signal[2], signal[3]);

    // 입력값이 0010 또는 0001 일 경우 code[0]은 1
    or or0 (a0, signal[1], signal[3]);

    assign code = {a1, a0}; //code[1]이 상위비트, code[0]이 하위비트
endmodule