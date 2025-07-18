`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2025 03:43:05 PM
// Design Name: 
// Module Name: half_adder
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


// Half Adder Behavioral
// 두개의 1비트를 입력 (a, b)
// 합(S), 자리올림(c) 출력하는 반가산기

module half_adder_behavioral(
    input a,                    // 1bit 입력 a 
    input b,                    // 1bit 입력 b
    output reg s,               // 합 (sum) 을 저장할 레지스터 타입의 출력
    output reg c                // 자리올림 (c) 를 저장할 레지스터 타입의 출력
    );

    // a 또는 b의 변화가 생길때 마다 always 블록 실행
    always @(a, b) begin
        case ({a, b})
            2'b00: begin        // a = 0 , b = 0 --> 합 = 0, 자리올림 = 0
                s = 0;
                c = 0;
            end 
            2'b01: begin        // a = 0 , b = 1 --> 합 = 1, 자리올림 = 0
                s = 1;
                c = 0;
            end 
            2'b10: begin        // a = 1 , b = 0 --> 합 = 1, 자리올림 = 0
                s = 1;
                c = 0;
            end 
            2'b11: begin        // a = 1 , b = 1 --> 합 = 0, 자리올림 = 1
                s = 0;
                c = 1;
            end 
        endcase
    end

endmodule


module half_adder_structural (
    input a, b,
    output s, c
);
    and (c, a, b);
    xor (s, a, b);
endmodule


module half_adder_dataflow (
    input a, b,
    output s, c    
);
    // a 와 b의 합을 저장할 2비트 와이어
    // 최대값은 1 + 1 = 2 (2'b10) 이므로 2비트가 필요
    wire [1:0] sum_value;

    //verilog 에서 "+" 연산자는 벡터를 생성해서 결과를 sum_value에 저장
    // ex) sum_value = a + b;
    assign sum_value = a + b;

    // sum_value 의 최하위 비트(LSB) 인 sum_value[0] 를 s에 할당
    // 결과값은 XOR 연산 결과와 같음
    assign s = sum_value[0];

    // sum_value의 최상위비트(MSB) 인 sum_value[1] 를  c 에 할당
    // 결과값은 AND 연산 결과와 같음 (둘다 1일 경우에만 캐리 발생)
    assign c = sum_value[1];

endmodule


module half_adder_N_bit # (parameter N = 8) (  //n의 기본값 8bit
    input inc,                      //더 할 값
    input [N-1:0] load_data,        // 입력 데이터
    output [N-1:0] sum              // 출력 합계 결과 (N비트)
);

    wire [N-1:0] carry_out;          // 각 자리의 캐리 출력을 저장 할 배열

    half_adder_dataflow ha0 (        // 첫번째 비트(LSB)는 inc와 load_data[0]를 하프애더로 연산
        .a(inc),
        .b(load_data[0]),
        .s(sum[0]),
        .c(carry_out[0])
    );

    genvar i;                               // generate 문을 위한 변수 선언
    generate
        for (i = 1; i< N; i = i + 1 )begin : hagen  // label을 "hagen"로 블록 지정
            half_adder_dataflow ha(
                .a(carry_out[i - 1]),       // 이전 자리의 캐리 입력
                .b(load_data[i]),           // 현재 자리의 입력 비트
                .s(sum[i]),                 // 현재 자리의 합 출력
                .c(carry_out[i])            // 다음 자리로 전달 될 캐릭 출력
            );
        end
    endgenerate

endmodule


// N bit 하프에더
// module half_adder_N_bit # (parameter N = 8) (
//     input inc,                         // 더할 값
//     input [N-1:0] load_data,
//     output [N-1:0] sum
// );
    
//     wire [N-1:0] carry_out;                // 캐리 신호들
    
//     // 최하위 비트 (LSB) - inc와 load_data[0]를 더함
//     half_adder_structural ha0 (
//         .a(inc),
//         .b(load_data[0]),
//         .s(sum[0]),
//         .c(carry_out[0])
//     );
    
//     // 나머지 비트들 - 이전 비트의 캐리와 현재 비트를 더함
//     genvar i;
//     generate
//         for (i = 1; i < N; i = i + 1) begin : adder_chain
//             half_adder_structural ha (
//                 .a(carry_out[i-1]),
//                 .b(load_data[i]),
//                 .s(sum[i]),
//                 .c(carry_out[i])
//             );
//         end
//     endgenerate
    
// endmodule
    
// endmodule

