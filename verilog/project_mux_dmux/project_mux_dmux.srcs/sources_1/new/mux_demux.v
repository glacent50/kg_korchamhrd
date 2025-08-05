`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 03:45:36 PM
// Design Name: 
// Module Name: mux_demux
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


module mux_2_1(
    input [1:0] d, // 입력 신호 2개
    input s,
    output f
    );

    assign f = s ? d[1] : d[0];  // s가 1이면 d[1]을 출력, 0이면 d[0]을 출력

endmodule


module mux_4_1(
    input [3:0] d, // 입력 신호 4개
    input [1:0] s, // select signal 2bit (00, 01, 10, 11)
    output f
    );

    assign f = d[s]; // s가 가리키는 d 배열의 원소

endmodule


module mux_8_1(
    input [7:0] d, // 입력 신호 8개
    input [2:0] s, // select signal 3bit (000, 001, 010, 011, 100, 101, 110, 111)
    output f
    );

    assign f = d[s]; // s가 가리키는 d 배열의 원소

endmodule

module mux_2_1_behavioral(
    input [1:0] d, // 입력 신호 2개
    input s,
    output reg f
    );


    always @( d or s) begin
        if (s == 1'b1)
            f = d[1];
        else
            f = d[0];
    end

endmodule


module mux_2_1_structual (
    input [1:0] d,
    input s,
    output f
);

    wire s_n;         // s의 NOT을 저장할 내부 와이어
    wire and_out_0;   // 첫번째 AND 게이트 출력
    wire and_out_1;   // 두번째 AND 게이트 출력

    not (s_n, s);                   // s의 NOT 연산 수행
    and (and_out_0, d[0], s_n);     // d[0]과 s_n의 AND 연산
    and (and_out_1, d[1], s);       // d[1]과 s의 AND 연산
    or  (f, and_out_0, and_out_1);  // 두 AND 결과를 OR 연산하여 최종 출력

endmodule

module mux_4_1_behavioral (
    input [3:0] d,
    input [1:0] s,
    output reg f
);

    always @(d or s) begin
        case(s)
            2'b00: f = d[0];   // s가 00일 때 d[0] 선택
            2'b01: f = d[1];   // s가 01일 때 d[1] 선택
            2'b10: f = d[2];   // s가 10일 때 d[2] 선택
            2'b11: f = d[3];   // s가 11일 때 d[3] 선택
            //default: f = 1'bx; // 예상치 못한 값에 대한 기본 케이스
        endcase
    end
    
endmodule

module mux_4_1_structual (
    input [3:0] d,
    input [1:0] s,
    output f
);

    wire mux_out_0;
    wire mux_out_1;
    
    // 첫 번째 단계: 두 개의 2-to-1 멀티플렉서
    mux_2_1_structual m0 (
        .d({d[1], d[0]}),
        .s(s[0]),
        .f(mux_out_0)
    );
    
    mux_2_1_structual m1 (
        .d({d[3], d[2]}),
        .s(s[0]),
        .f(mux_out_1)
    );
    
    // 두 번째 단계: 최종 선택을 위한 2-to-1 멀티플렉서
    mux_2_1_structual m2 (
        .d({mux_out_1, mux_out_0}),
        .s(s[1]),
        .f(f)
    );
    
endmodule



// 1-to-2 디멀티플렉서 모듈 추가
module demux_1_to_2(
    input in,        // 입력 신호 1개
    input s,        // 선택 신호
    output reg [1:0] out  // 출력 신호 2개(reg 타입으로 변경)
    );
    
    always @(*) begin
        out = 2'b00;  // 기본값: 모든 출력을 0으로 설정
        case(s)
            1'b0: out[0] = in;  // s=0일 때, 입력을 out[0]으로 라우팅
            1'b1: out[1] = in;  // s=1일 때, 입력을 out[1]으로 라우팅
        endcase
    end

endmodule


module demux_1_4_d (
    input d,
    input [1:0] s,
    output [3:0] f
);
    // 선택 신호 s에 따라 값 정의 튜플. 결합연산자.
    assign f = (s == 2'b00) ? {3'b000, d} :       // s=00 -> f=000d (f[0] = d)
               (s == 2'b01) ? {2'b00, d, 1'b0} :  // s=01 -> f=00d0 (f[1] = d)
               (s == 2'b10) ? {1'b0, d, 2'b00} :  // s=10 -> f=0d00 (f[2] = d)
                              {d, 3'b000};        // s=11 -> f=d000 (f[3] = d)
endmodule


module mux_demux_test (
    input [3:0] d,         // mux 입력 4개
    input [1:0] mux_s,     // mux 신호
    input [1:0] demux_s,   // demux 신호
    output [3:0] f         // demux 출력
);

    wire mux_f;
    
    // 4-to-1 멀티플렉서 인스턴스화
    mux_4_1 mux4 (
        .d(d),          // 4비트 입력 d 연결
        .s(mux_s),      // 2비트 선택 신호 mux_s 연결
        .f(mux_f)       // 출력을 mux_f 와이어에 연결
    );
    
    // 1-to-4 디멀티플렉서 인스턴스화
    demux_1_4_d demux4 (
        .d(mux_f),      // 입력으로 mux 출력 연결
        .s(demux_s),    // 2비트 선택 신호 demux_s 연결
        .f(f)           // 4비트 출력 f에 연결
    );
    
endmodule