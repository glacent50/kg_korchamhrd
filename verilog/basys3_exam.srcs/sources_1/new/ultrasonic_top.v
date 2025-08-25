`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2025 11:59:44 AM
// Design Name: 
// Module Name: ultrasonic_top
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


// HC-SR04 초음파센서 테스트 최상위 모듈
module ultrasonic_top(    
    input clk, reset_p,              // 시스템 클럭 및 리셋
    input echo,                      // 초음파센서 Echo 핀 입력
    output trigger,                  // 초음파센서 Trigger 핀 출력
    output [3:0] com,                // 7-segment 공통 제어 신호
    output [7:0] seg_7,              // 7-segment 세그먼트 신호
    output [15:0] led                // LED 출력
);
    
    // 내부 신호 선언
    wire [11:0] distance;            // 측정된 거리 (12비트)
    wire [15:0] distance_16bit;      // 16비트로 확장된 거리
    wire [15:0] bcd_distance;        // BCD 변환된 거리
    
    // 12비트 거리를 16비트로 확장
    assign distance_16bit = {4'b0000, distance};
    
    // HC-SR04 초음파센서 제어 모듈 인스턴스
    hc_sr04_cntr ultrasonic_sensor(
        .clk(clk), 
        .reset_p(reset_p), 
        .echo(echo), 
        .trigger(trigger), 
        .distance(distance), 
        .led(led[3:0])  // 하위 4비트 LED로 상태 표시
    );
    
    // 나머지 LED는 거리 값 표시
    assign led[15:4] = distance;
    
    // 이진수를 BCD로 변환
    bin_to_dec btd_distance(
        .bin(distance_16bit), 
        .bcd(bcd_distance)
    );
    
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value(bcd_distance),
        .hex_bcd(1),
        .seg_7(seg_7), .com(com));

endmodule


// HC-SR04 초음파센서용 58분주기 모듈 (거리 측정을 위한 타이밍 분주기)
module sr_04_div_58(        
    input clk, reset_p,
    input clk_usec, cnt_e,                  
    output reg [11:0] cm
);    
    integer cnt;                       
    
    always @(negedge clk or posedge reset_p) begin        
        if(reset_p) begin 
            cnt = 0;
            cm = 0;
        end      
        else if(cnt_e) begin
            if(clk_usec) begin
                // 58us마다 cm가 1씩 증가 (음속 기반 거리 계산)
                if(cnt >= 58) begin 
                    cnt = 0; 
                    cm = cm + 1; 
                end           
                else cnt = cnt + 1;         
            end
        end
        else begin
            cnt = 0;
            cm = 0;
        end            
    end            
endmodule

// HC-SR04 초음파센서 제어 모듈
module hc_sr04_cntr(
    input clk, reset_p,
    input echo,                    // 초음파센서 Echo 핀
    output reg trigger,            // 초음파센서 Trigger 핀
    output reg [11:0] distance,    // 측정된 거리 값 (cm)
    output [3:0] led               // 상태 표시용 LED
);
    
    // 상태 정의 (3단계 상태머신)
    localparam S_IDLE     = 3'b001;  // 대기 상태 (1초 딜레이)
    localparam TRI_10US   = 3'b010;  // 트리거 신호 생성 (10us)
    localparam ECHO_STATE = 3'b100;  // Echo 신호 측정
    
    // Echo 상태 정의 (상승에지/하강에지 대기)
    localparam S_WAIT_PEDGE = 2'b01; // 상승에지 대기
    localparam S_WAIT_NEDGE = 2'b10; // 하강에지 대기
    
    // 내부 신호 선언
    reg [21:0] count_usec;         // 마이크로초 카운터
    wire clk_usec;                 // 1us 클럭
    reg count_usec_e;              // 카운터 활성화 신호
    
    // 1us 클럭 생성 (100MHz -> 1MHz)
    clock_div_100 us_clk(
        .clk(clk), 
        .reset_p(reset_p), 
        .clk_div_100(clk_usec)
    );
    
    // 마이크로초 카운터 로직
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) 
            count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) 
                count_usec = count_usec + 1;
            else if(!count_usec_e) 
                count_usec = 0;
        end
    end
    
    // Echo 신호의 에지 검출
    wire echo_pedge, echo_nedge;
    edge_detector_n ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(echo), 
        .p_edge(echo_pedge), 
        .n_edge(echo_nedge)
    );
    
    // 상태 관련 레지스터
    reg [2:0] state, next_state;
    reg [1:0] read_state;
    
    // 58분주기 관련 신호
    reg cnt_e;
    wire [11:0] cm;
    sr_04_div_58 div58(
        .clk(clk), 
        .reset_p(reset_p), 
        .clk_usec(clk_usec), 
        .cnt_e(cnt_e), 
        .cm(cm)
    );
    
    // LED로 현재 상태 표시
    assign led[3:0] = {1'b0, state};
    
    // 상태 전환 로직 (네거티브 에지 클럭 사용)
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) 
            state = S_IDLE;
        else 
            state = next_state;
    end
    
    // 메인 상태머신 로직
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            count_usec_e = 0;
            next_state = S_IDLE;
            trigger = 0;
            read_state = S_WAIT_PEDGE;
            cnt_e = 0;
        end
        else begin
            case(state)
                S_IDLE: begin
                    // 100ms 대기 (측정 주기)
                    if(count_usec < 22'd100_000) begin
                        count_usec_e = 1; 
                    end
                    else begin 
                        next_state = TRI_10US;
                        count_usec_e = 0; 
                    end
                end
                
                TRI_10US: begin 
                    // 10us 동안 트리거 신호 생성
                    if(count_usec <= 22'd10) begin
                        count_usec_e = 1;
                        trigger = 1;
                    end
                    else begin
                        count_usec_e = 0;
                        trigger = 0;
                        next_state = ECHO_STATE;
                    end
                end
                
                ECHO_STATE: begin 
                    case(read_state)
                        S_WAIT_PEDGE: begin
                            // Echo 신호의 상승에지 대기
                            count_usec_e = 0;
                            if(echo_pedge) begin
                                read_state = S_WAIT_NEDGE;
                                cnt_e = 1;  // 거리 측정 시작
                            end
                        end
                        
                        S_WAIT_NEDGE: begin
                            // Echo 신호의 하강에지 대기
                            if(echo_nedge) begin       
                                read_state = S_WAIT_PEDGE;
                                count_usec_e = 0;                    
                                distance = cm;  // 측정된 거리 저장
                                cnt_e = 0;      // 거리 측정 종료
                                next_state = S_IDLE;
                            end
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                end
                
                default: next_state = S_IDLE;
            endcase
        end
    end

endmodule