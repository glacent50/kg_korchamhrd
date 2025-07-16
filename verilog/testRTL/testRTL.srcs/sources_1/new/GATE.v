`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2025 10:33:33 AM
// Design Name: 
// Module Name: GATE
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

// 동작적 : 동작을 코드로 표현 / 복잡한 로직 처리에 유리
// 구조적 : 게이트를 연결해서 회로 구조를 표현 / 실제 회로 구조 이해 적합
// 데이터플로우 : 출력 = 입력 서술 / 간단한 조합논리 회로에 적합


/// AND GATE

// Truth table 방식
module and_gate(
    input a, b,
    output reg q
    );

    always @(a, b) begin
        case ({a,b})
            2'b00: q = 0;
            2'b01: q = 0;
            2'b10: q = 0;
            2'b11: q = 1;
        endcase
    end
endmodule

// [동작적] 방식 :동작을 코드로 표현 / 복잡한 로직 처리에 유리
module and_gate_behavioral(
    input a,b,          // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a or b) begin                      // a 또는 b 신호가 변경될 때 실행
        if (a == 1'b1 && b == 1'b1) begin       // a와 b가 모두 1일 때
            q = 1'b1;                           // 출력 q를 1로 설정
        end else                                // 그렇지 않을 때
            q = 1'b0;                           // 출력 q를 0으로 설정
    end
endmodule

// [구조적] 방식 : 실제 게이트(AND) 이용해서 회로의 구조를 기술 하드웨어의 구성요소를 직접 인스턴스 화함.
module and_gate_structual (
    input a, b,
    output q // 여기 주의 !!! wire 타입이어야 함.
);
    and U1(q, a, b);
endmodule

// [데이터플로우] 방식 : 데이터의 흐름 중심 assign 문으로 출력과 입력간의 논리를 기술
module and_gate_dataflow (
    input a, b,
    output q // 여기 주의 !!! wire 타입이어야 함.
);
    assign q = a & b;
endmodule


/// OR GATE

module or_gate (
    input a, b,
    output reg q
);

always @(a,b) begin
    case({a, b})
        2'b00 : q=0;
        2'b10 : q=1;
        2'b01 : q=1;
        2'b11 : q=1;
    endcase 
end
    
endmodule


module or_gate_behavioral (
    input a, b,
    output reg q);

    always @(a,b) begin
        if (a == 1'b1 || b == 1'b1)
            q =  1'b1;
        else 
            q =  1'b0;
    end
endmodule


module or_gate_structural(
    input a, b,
    output q);

    or U1(q, a, b);

endmodule


module or_gate_dataflow (
    input a, b,
    output q // 여기 주의 !!! wire 타입이어야 함.
);
    assign q = a | b;
endmodule


/// NAND GATE
module nand_gate (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);

always @(a,b) begin     // a 또는 b 신호가 변경될 때 실행
    case({a, b})        // a와 b를 연결하여 2비트 값으로 처리
        2'b00 : q=1;    // 0,0 -> 1 (둘 다 0이므로 1)
        2'b10 : q=1;    // 1,0 -> 1 (하나라도 0이면 1)
        2'b01 : q=1;    // 0,1 -> 1 (하나라도 0이면 1)
        2'b11 : q=0;    // 1,1 -> 0 (둘 다 1이므로 0)
    endcase 
end
    
endmodule

module nand_gate_behavioral (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a,b) begin             // a 또는 b 신호가 변경될 때 실행
        if (a == 1'b1 && b == 1'b1) // 둘 다 1일 때
            q =  1'b0;              // 출력 0 (NAND는 둘 다 1일 때만 0)
        else                        // 하나라도 0이면
            q =  1'b1;              // 출력 1
    end
endmodule


module nand_gate_structural(
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);

    nand U1(q, a, b);   // 내장 NAND 게이트 인스턴스 생성

endmodule


module nand_gate_dataflow (
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);
    assign q = ~(a & b);  // AND 연산 후 반전하여 NAND 구현
endmodule



/// NOR GATE

module nor_gate (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);

always @(a,b) begin     // a 또는 b 신호가 변경될 때 실행
    case({a, b})        // a와 b를 연결하여 2비트 값으로 처리
        2'b00 : q = 1;  // 0,0 -> 1 (둘 다 0이므로 1)
        2'b01 : q = 0;  // 0,1 -> 0 (하나라도 1이면 0)
        2'b10 : q = 0;  // 1,0 -> 0 (하나라도 1이면 0)
        2'b11 : q = 0;  // 1,1 -> 0 (둘 다 1이므로 0)
    endcase 
end
    
endmodule

module nor_gate_behavioral (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a,b) begin             // a 또는 b 신호가 변경될 때 실행
        if (a == 1'b0 && b == 1'b0) // 둘 다 0일 때만
            q = 1'b1;               // 출력 1 (NOR 게이트는 모두 0일 때만 1)
        else                        // 하나라도 1이면
            q = 1'b0;               // 출력 0
    end
endmodule


module nor_gate_structural(
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);

    nor U1(q, a, b);    // 내장 NOR 게이트 인스턴스 생성

endmodule


module nor_gate_dataflow (
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);
    assign q = ~(a | b);  // OR 연산 후 반전하여 NOR 구현
endmodule



/// XOR GATE
module xor_gate (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);

always @(a,b) begin     // a 또는 b 신호가 변경될 때 실행
    case({a, b})        // a와 b를 연결하여 2비트 값으로 처리
        2'b00 : q = 0;  // 0,0 -> 0 (같은 값이므로 0)
        2'b01 : q = 1;  // 0,1 -> 1 (다른 값이므로 1)
        2'b10 : q = 1;  // 1,0 -> 1 (다른 값이므로 1)
        2'b11 : q = 0;  // 1,1 -> 0 (같은 값이므로 0)
    endcase 
end
    
endmodule

module xor_gate_behavioral (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a,b) begin     // a 또는 b 신호가 변경될 때 실행
        if (a == 1'b0 && b == 1'b0)      // 둘 다 0일 때
            q = 1'b0;                     // 출력 0 (같은 값)
        else if (a == 1'b1 && b == 1'b1) // 둘 다 1일 때
            q = 1'b0;                     // 출력 0 (같은 값)
        else                              // 하나는 0, 하나는 1일 때
            q = 1'b1;                     // 출력 1 (다른 값)
    end
endmodule


module xor_gate_structural(
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);

    xor U1(q, a, b);    // 내장 XOR 게이트 인스턴스 생성

endmodule


module xor_gate_dataflow (
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);
    assign q = a ^ b;   // XOR 연산자를 사용하여 논리 구현
endmodule


/// XNOR GATE
// (Truth table 방식)
module xnor_gate (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a, b) begin  // a 또는 b 신호가 변경될 때 실행
        case({a, b})      // a와 b를 연결하여 2비트 값으로 처리
            2'b00 : q = 1;  // 0,0 -> 1 (같은 값이므로 1)
            2'b01 : q = 0;  // 0,1 -> 0 (다른 값이므로 0)
            2'b10 : q = 0;  // 1,0 -> 0 (다른 값이므로 0)
            2'b11 : q = 1;  // 1,1 -> 1 (같은 값이므로 1)
        endcase 
    end
endmodule

module xnor_gate_behavioral (
    input a, b,         // 입력 신호 a, b
    output reg q        // 출력 신호 q (레지스터 타입)
);
    always @(a,b) begin  // a 또는 b 신호가 변경될 때 실행
        if (a == 1'b0 && b == 1'b0)  // 둘 다 0일 때
            q = 1'b1;                 // 출력 1 (같은 값)
        else if (a == 1'b1 && b == 1'b1)  // 둘 다 1일 때
            q = 1'b1;                      // 출력 1 (같은 값)
        else                          // 하나는 0, 하나는 1일 때
            q = 1'b0;                 // 출력 0 (다른 값)
    end
endmodule


module xnor_gate_structural(
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);

    xnor U1(q, a, b);   // 내장 XNOR 게이트 인스턴스 생성
endmodule


module xnor_gate_dataflow (
    input a, b,         // 입력 신호 a, b
    output q            // 출력 신호 q (wire 타입)
);
    assign q = ~(a ^ b);  // XOR 연산 후 반전하여 XNOR 구현
endmodule




module gates (
    input a, b,
    output q0, q1, q2, q3, q4, q5, q6
);

    assign q0 = ~a;         // NOT (a 입력만 사용)
    assign q1 = a & b;      // AND
    assign q2 = a | b;      // OR
    assign q3 = ~(a & b);   // NAND
    assign q4 = ~(a | b);   // NOR
    assign q5 = a ^ b;      // XOR
    assign q6 = ~(a ^ b);   // XNOR

endmodule