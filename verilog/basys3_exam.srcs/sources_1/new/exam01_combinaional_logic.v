module and_gate(
    input A,      // 입력 A
    input B,      // 입력 B
    output F      // 출력 F
    );

   assign F = A & B;  // AND 연산 결과를 F에 할당

endmodule



module half_adder_structural(
    input A, B,           // 입력 A, B
    output sum, carry     // 출력 sum, carry
    );

    xor (sum, A, B);      // sum = A XOR B (합)
    and (carry, A, B);    // carry = A AND B (자리올림)

endmodule //한글주석 



module half_adder_behavioral(
    input A, B,           // 입력 A, B
    output reg sum, carry // 출력 sum, carry (reg 타입)
    );

    always @(A, B) begin
        case({A,B})       // A와 B의 조합에 따라
            2'b00: begin sum=0; carry = 0; end // 00: sum=0, carry=0
            2'b01: begin sum=1; carry = 0; end // 01: sum=1, carry=0
            2'b10: begin sum=1; carry = 0; end // 10: sum=1, carry=0
            2'b11: begin sum=0; carry = 1; end // 11: sum=0, carry=1
        endcase
    end

endmodule


module half_adder_dataflow(
    input A, B,
    output sum, carry
    );
    
    wire [1:0] sum_value;
    
    assign sum_value = A + B;      // 두 입력의 합을 2비트로 저장
    assign sum = sum_value[0];     // 합의 하위 비트가 sum
    assign carry = sum_value[1];   // 합의 상위 비트가 carry
    
endmodule


module full_adder_behavioral(
    input A, B, cin,         // 입력: A, B, cin(캐리 입력)
    output reg sum, carry    // 출력: sum(합), carry(캐리 출력)
    );

    always @(A, B, cin) begin
        case({A,B,cin})       // A, B, cin의 조합에 따라 동작 결정
            3'b000: begin sum=0; carry = 0; end // 0+0+0: sum=0, carry=0
            3'b001: begin sum=1; carry = 0; end // 0+0+1: sum=1, carry=0
            3'b010: begin sum=1; carry = 0; end // 0+1+0: sum=1, carry=0
            3'b011: begin sum=0; carry = 1; end // 0+1+1: sum=0, carry=1
            3'b100: begin sum=1; carry = 0; end // 1+0+0: sum=1, carry=0
            3'b101: begin sum=0; carry = 1; end // 1+0+1: sum=0, carry=1
            3'b110: begin sum=0; carry = 1; end // 1+1+0: sum=0, carry=1
            3'b111: begin sum=1; carry = 1; end // 1+1+1: sum=1, carry=1
        endcase
    end
    
endmodule

module full_adder_structual(
    input A, B, cin, 
    output sum, carry
    );

    wire sum_0;
    wire carry_0, carry_1;

    // 첫 번째 half adder로 A, B를 더함
    half_adder_structural ha0(.A(A), .B(B), .sum(sum_0), .carry(carry_0));
    // 두 번째 half adder로 sum_0과 cin을 더함
    half_adder_structural ha1(.A(sum_0), .B(cin), .sum(sum), .carry(carry_1));
    // 두 half adder의 carry를 OR 연산하여 최종 carry 생성
    or (carry, carry_0, carry_1);

endmodule


module full_adder_dataflow(
    input A, B, cin,
    output sum, carry
    );

    wire [1:0] sum_value;
    
    assign sum_value = A + B + cin;    // 세 입력의 합을 2비트로 저장
    assign sum = sum_value[0];         // 합의 하위 비트가 sum
    assign carry = sum_value[1];       // 합의 상위 비트가 carry

endmodule


module fadder_4bit_dataflow(
    input [3:0] A, B,      // 4비트 입력 A, B
    input cin,             // 캐리 입력
    output [3:0] sum,      // 4비트 합 출력
    output carry           // 캐리 출력
    );

    wire [4:0] sum_value;  // 5비트 내부 합(캐리 포함)

    assign sum_value = A + B + cin; // A, B, cin을 더해서 sum_value에 저장
    assign sum = sum_value[3:0];    // 하위 4비트를 sum에 할당
    assign carry = sum_value[4];    // 최상위 비트를 carry에 할당

endmodule



module fadder_4bit_structural(
    input [3:0] A, B,      // 4비트 입력 A, B
    input cin,             // 캐리 입력
    output [3:0] sum,      // 4비트 합 출력
    output carry           // 캐리 출력
);
    wire [2:0] carry_w;    // 내부 캐리 신호 (3비트)

    // 첫 번째 1비트 full adder: A[0], B[0], cin을 더함
    full_adder_structual fa0 (.A(A[0]), .B(B[0]), .cin(cin),        .sum(sum[0]), .carry(carry_w[0]));
    // 두 번째 1비트 full adder: A[1], B[1], 이전 캐리(carry_w[0])를 더함
    full_adder_structual fa1 (.A(A[1]), .B(B[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    // 세 번째 1비트 full adder: A[2], B[2], 이전 캐리(carry_w[1])를 더함
    full_adder_structual fa2 (.A(A[2]), .B(B[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    // 네 번째 1비트 full adder: A[3], B[3], 이전 캐리(carry_w[2])를 더함, 최종 캐리 출력
    full_adder_structual fa3 (.A(A[3]), .B(B[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));

endmodule


module mux_2_1(
    input [1:0] d,
    input s,         // s 입력 추가
    output f
);

    assign f = s ? d[1] : d[0];   // s가 1이면 d[1], 0이면 d[0] 선택

endmodule


module mux_4_1(
    input [3:0] d,
    input [1:0] s,         // s 입력 추가
    output f
);

    assign f = d[s];   // s값에 따라 d 배열에서 선택

endmodule


module mux_8_1(
    input [7:0] d,
    input [2:0] s,         // s 입력 추가
    output f
);

    assign f = d[s];   // s값에 따라 d 배열에서 선택

endmodule


module demux_1_4_d(
    input d,             // 입력 신호 d
    input [1:0] s,       // 2비트 선택 신호 s
    output [3:0] f       // 4비트 출력 f
);

    // 선택 신호 s에 따라 입력 d를 4개의 출력 중 하나에 할당
    assign f = (s == 2'b00) ? {3'b000, d} :      // s=00이면 f[0]=d, 나머지 0
               (s == 2'b01) ? {2'b00, d, 1'b0} : // s=01이면 f[1]=d, 나머지 0
               (s == 2'b10) ? {1'b0, d, 2'b00} : // s=10이면 f[2]=d, 나머지 0
                              {d, 3'b000};       // s=11이면 f[3]=d, 나머지 0
endmodule


module demux_1_8_d(
    input d,             // 입력 신호 d
    input [2:0] s,       // 3비트 선택 신호 s
    output [7:0] f       // 8비트 출력 f
);
    assign f = 8'b00000000 | (d << s); // s 위치에만 d가 할당되고 나머지는 0
endmodule


module mux_demux_test(
    input [3:0] d,           // 4비트 입력 d
    input [1:0] mux_s,       // 2비트 MUX 선택 신호
    input [1:0] demux_s,     // 2비트 DEMUX 선택 신호
    output [3:0] f           // 4비트 출력 f
);
   
    wire mux_f;              // MUX 출력 신호

    // 4:1 멀티플렉서 인스턴스: d와 mux_s로 mux_f 생성
    mux_4_1 mux_4(.d(d), .s(mux_s), .f(mux_f));
    // 1:4 디멀티플렉서 인스턴스: mux_f와 demux_s로 f 생성
    demux_1_4_d demux4(.d(mux_f), .s(demux_s), .f(f));

endmodule


//------------------------------------------------------------------------------
// 모듈명: encoder_4_2
// 설명: 4비트 입력 신호 중 하나가 1일 때 해당 위치를 2비트 이진 코드로 출력하는 4:2 인코더입니다.
// 입력:
//   - signal [3:0]: 4비트 입력 신호 (하나의 비트만 1이어야 함)
// 출력:
//   - code [1:0]: 입력 신호의 위치를 나타내는 2비트 이진 코드
//------------------------------------------------------------------------------
module encoder_4_2(
    input [3:0] signal,
    output reg [1:0] code);

//    assign code = (signal == 4'b1000) ? 2'b11 :
//                  (signal == 4'b0100) ? 2'b10 :
//                  (signal == 4'b0010) ? 2'b01 : 2'b00;

// 레치 안나도록 else 추가 주의
//    always @(signal) begin
//        if (signal == 4'b1000) code = 2'b11;
//        else if (signal == 4'b0100) code = 2'b10;
//        else if (signal == 4'b0010) code = 2'b01;
//        else if (signal == 4'b0001) code = 2'b00;
//        else code = 2'b00;
//    end 

//    always @(signal) begin
//        if (signal == 4'b1000) code = 2'b11;
//        else if (signal == 4'b0100) code = 2'b10;
//        else if (signal == 4'b0010) code = 2'b01;
//        else code = 2'b00;
//    end 

// 레치 안나도록 default 추가 주의
    always @(signal) begin
        case(signal)
            4'b0001: code = 2'b00;
            4'b0010: code = 2'b01;
            4'b0100: code = 2'b10;
            4'b1000: code = 2'b11;
            default: code = 2'b00; 
        endcase
    end

endmodule


module decoder_2_4 (
    input [1:0] code,
    output reg [3:0] signal);
    
//    assign signal = ( code == 2'b00 ) ? 4'b0001 :
//                    ( code == 2'b01 ) ? 4'b0010 :
//                    ( code == 2'b10 ) ? 4'b0100 : 4'b1000;
                    
                    
// 레치 안나도록 else 추가 주의
//    always @(code) begin
//        if (code == 2'b00) signal = 4'b0001;
//        else if (code == 2'b01) signal = 4'b0010;
//        else if (code == 2'b10) signal = 4'b0100;
//        else if (code == 2'b11) signal = 4'b1000;
//        else signal = 4'b1000;
//    end   
    

// 레치 안나도록 default 추가 주의
    always @(code) begin
        case(code)
            2'b00 : signal = 4'b0001;
            2'b01 : signal = 4'b0010;
            2'b10 : signal = 4'b0100;
            2'b11 : signal = 4'b1000;
            default : signal = 4'b1000;
        endcase
    end                      

endmodule


module seg_decoder (
    input [3:0] digit_in,
    output reg [7:0] seg_out
);

    always @(*) begin
        case (digit_in)      // pgfe_dcba (0 is LED on, 1 is LED off)
            4'd0: seg_out = 8'b1100_0000; // 0  (~0011_1111)
            4'd1: seg_out = 8'b1111_1001; // 1  (~0000_0110)
            4'd2: seg_out = 8'b1010_0100; // 2  (~0101_1011)
            4'd3: seg_out = 8'b1011_0000; // 3  (~0100_1111)
            4'd4: seg_out = 8'b1001_1001; // 4  (~0110_0110)
            4'd5: seg_out = 8'b1001_0010; // 5  (~0110_1101)
            4'd6: seg_out = 8'b1000_0010; // 6  (~0111_1101)
            4'd7: seg_out = 8'b1111_1000; // 7  (~0000_0111)
            4'd8: seg_out = 8'b1000_0000; // 8  (~0111_1111)
            4'd9: seg_out = 8'b1001_0000; // 9  (~0110_1111)
            4'hA: seg_out = 8'b1000_1000; // A  (~0111_0111)
            4'hB: seg_out = 8'b1000_0011; // B  (~0111_1100)
            4'hC: seg_out = 8'b1100_0110; // C  (~0011_1001)
            4'hD: seg_out = 8'b1010_0001; // D  (~0101_1110)
            4'hE: seg_out = 8'b1000_0110; // E  (~0111_1001)
            4'hF: seg_out = 8'b1000_1110; // F  (~0111_0001)
            default: seg_out = 8'b1111_1111; // All segments off (~0000_0000)
        endcase
    end
endmodule


module anode_selector (
    input [1:0] scan_count,
    output reg [3:0] an_out
);
    always @(*) begin
        case (scan_count)
            2'd0: an_out = 4'b1110; // an[0]
            2'd1: an_out = 4'b1101; // an[1]
            2'd2: an_out = 4'b1011; // an[2]
            2'd3: an_out = 4'b0111; // an[3]
            default: an_out = 4'b1111;
        endcase
    end
endmodule

















