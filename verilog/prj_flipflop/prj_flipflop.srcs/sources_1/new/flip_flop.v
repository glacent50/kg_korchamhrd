`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 02:35:48 PM
// Design Name: 
// Module Name: flip_flop
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

// 플립플롭 -> 저장소자
// 클럭신호에 동기화 -> 상태가 변경 -> 엣지 트리거
// 타이밍제어가 정확
// 용도 : 동기식 레지스터. , FSM상태 저장, 파이프라인 레지스트, 카운터등


// 레치 -> 기억소자
// 클럭대신에 제어신호에 의해서 동장 (비동기적 -> 레벨트리거)
// 타이밍제어가 힘듬. (비동기)
// SR 래치, D 래치
// 안전성이 낮음

// 비바도에서 권장은 플립플롭, 래치는 특수한 경우만....



// D Flip-Flop
// 입력된 데이터(D)를 클럭신호(clk)

// 시간  clk   D   Q
// t0    0    1   0
// t1   1(R)  1   1  <- 상승에지에지에서 D=1 이니까 ...Q = 1 
// t2   0     0   1  <- 엣지가 없음 .. Q 유지
// t3   1(R)  0   0  <- 상승에지에서 D =0 이니까  ...  Q = 0 


module D_flip_flop_Basic(
    input clk,          // 클럭 입력
    input d,            // 데이터 입력
    output reg q        // 출력
    );

    always @(posedge clk) begin // 상승엣지 일때 ...
        q <= d;      // q 에 d를 저장
    end
endmodule


module D_flip_flop_n (
    input d,
    input clk,
    input reset_p,    // 비동기식 리셋 신호
    input enable,     // 
    output reg q
);

    always @(negedge clk or posedge reset_p) begin
        if (reset_p)
            q <= 1'b0;  // 비동기 리셋이 활성화(1)되면 q를 0으로 초기화
        else if (enable)
            q <= d;     // enable이 활성화(1)된 경우에만 d 값을 q에 전달
                        // enable이 0 인 경우 q를 이전값으로 유지
    end
    
endmodule
