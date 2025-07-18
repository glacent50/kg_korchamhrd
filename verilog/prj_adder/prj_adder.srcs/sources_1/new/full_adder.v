`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2025 04:13:02 PM
// Design Name: 
// Module Name: full_adder
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


module full_adder_structural(
    input a, b, cin,                // 입력비트 3개 (이전자리 올라온 자리올림 cin) 
    output sum, carry               // 출력
);

    wire sum_0;
    wire carry_0;
    wire carry_1;

    // 
    half_adder_structural ha0(
        .a(a),
        .b(b),
        .s(sum_0),
        .c(carry_0)
    );

    half_adder_structural ha1(
        .a(sum_0),
        .b(cin),
        .s(sum),
        .c(carry_1)
    );

    // 최종자리 올림은 두자리 올림의 OR 연산 (carry_0, carry_1)
    // 둘중 하나라도 1이면 carry 출력은 1
    or (carry, carry_0, carry_1);

endmodule


// 전가산기 (Behavioral)
module full_adder_behavioral (
    input a, b, cin,
    output reg sum, carry
);

    always @(a, b, cin) begin
        // 입력 3 비트를 하나의 값으로 묶어서 case 처리
        case ({a, b, cin})
            3'b000 : begin sum = 0; carry = 0; end // 0+0+0 = sum 0, carry 0
            3'b001 : begin sum = 1; carry = 0; end // 0+0+1 = sum 1, carry 0
            3'b010 : begin sum = 1; carry = 0; end // 0+1+0 = sum 1, carry 0
            3'b011 : begin sum = 0; carry = 1; end // 0+1+1 = sum 0, carry 1
            3'b100 : begin sum = 1; carry = 0; end // 1+0+0 = sum 1, carry 0
            3'b101 : begin sum = 0; carry = 1; end // 1+0+1 = sum 0, carry 1
            3'b110 : begin sum = 0; carry = 1; end // 1+1+0 = sum 0, carry 1
            3'b111 : begin sum = 1; carry = 1; end // 1+1+1 = sum 1, carry 1
        endcase
    end
    
endmodule

// dataflow
module full_adder_dataflow (
    input a, b, cin,      // <-- 쉼표 추가
    output sum, carry     // <-- 쉼표 추가
);

    wire [1:0] sum_value;          //2 비트 와이어 --> 덧셈 결과 (하위 : sum, 상위 : carry)

    assign sum_value = a + b + cin;

    assign sum = sum_value[0];
    assign carry = sum_value[1];
    
endmodule


module fadder_4bit_structural (
    input [3:0] a, b,         // 4bit input
    input cin,
    output [3:0] sum,         // result 4bit
    output carry              // final carry (MSB)
);
    wire [2:0] carry_w;       // 내부 전가산기 캐리 연결용 (수정: 3비트로 변경)

    // 첫번째 비트 : cin 과 함께 계산
    full_adder_structural fa0(
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .carry(carry_w[0])
    );

    // 두번째 비트 : 이전 자리 캐리를(carry_w[0]) cin 으로 사용
    full_adder_structural fa1(
        .a(a[1]),
        .b(b[1]),
        .cin(carry_w[0]),
        .sum(sum[1]),
        .carry(carry_w[1])
    );

    // 세번째 비트 
    full_adder_structural fa2(
        .a(a[2]),
        .b(b[2]),
        .cin(carry_w[1]),
        .sum(sum[2]),
        .carry(carry_w[2])
    );

    // 네번째 비트
    full_adder_structural fa3(
        .a(a[3]),
        .b(b[3]),
        .cin(carry_w[2]),
        .sum(sum[3]),
        .carry(carry)
    );


endmodule

module fadder_sub_4bit_structural (
    input [3:0] a, b,         // 4bit input
    input s,                  // select signal ( 0: add , 1:sub)
    output [3:0] sum,         // result 4bit
    output carry              // final carry (MSB)
);
   wire [2:0] carry_w;       // 각자리의 중간 캐리 연결용 (수정: 3비트로 변경)
   wire [3:0] b_w;

   // b의 가 비트와 s를 xor
   // s가 0이면 b_w는 b와 같음
   // s가 1이면 b_w는 b의 각 비트가 반전됨 (뺄샘 모드, 2의 보수 연산 준비)
   xor (b_w[0], b[0], s);
   xor (b_w[1], b[1], s);
   xor (b_w[2], b[2], s);
   xor (b_w[3], b[3], s);

   // 4개의 전 가산기로 4비트 덧셈/뺄셈
   // 첫번째 가산기에는 s를 초기 태리 입력(cin)으로 사용
   // s = 0 이면 덧셈 (cin = 0)
   // s = 1 이면 뺄셈 (cin = 1) 2의 보수로 연산 
   full_adder_structural fa0(.a(a[0]), .b(b_w[0]), .cin(s),          .sum(sum[0]), .carry(carry_w[0]));
   full_adder_structural fa1(.a(a[1]), .b(b_w[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
   full_adder_structural fa2(.a(a[2]), .b(b_w[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
   full_adder_structural fa3(.a(a[3]), .b(b_w[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));

endmodule


module fadder_sub_4bit_dataflow (
    input [3:0] a, b,         // 4bit input
    input s,                  // select signal ( 0: add , 1:sub)
    output [3:0] sum,         // result 4bit
    output carry              // final carry (MSB)
);

    wire [4:0] sum_value;

    assign sum_value = s ? a - b : a + b;

    assign sum = sum_value[3:0];
    
    assign carry = s ? ~sum_value[4] : sum_value[4];

endmodule


module fadder_sub_4bit_behavioral(
    input [3:0] a, b,
    input s,
    output reg [3:0] sum,
    output reg carry
);

    reg [4:0] temp; // 5bit 임시변수

    always @(*) begin
        if (s==0) begin
            temp = a+b;
            sum = temp[3:0];
            carry = temp[4]; // 덧셈 시 carry out
        end
        else begin
            temp = a-b;
            sum = temp[3:0];
            carry = (a < b) ? 1'b1 : 1'b0; // 뺄셈 시 borrow 발생 조건 수정
        end
    end

endmodule