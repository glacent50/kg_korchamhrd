`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2025 11:58:23 AM
// Design Name: 
// Module Name: multi_mode_watch
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

module multi_mode_watch(
    input clk, reset_p,
    input [3:0] btn,
    output reg [7:0] seg_7,
    output reg [3:0] com,
    output reg [15:0] led,
    output reg alarm
);

    // btn[3] 을 mode 선택을 위한 버튼
    wire btn_mode;
    btn_cntr mode_btn(
        .clk(clk), 
        .reset_p(reset_p),
        .btn(btn[3]), 
        .btn_pedge(btn_mode)
    );

    // mode 상태 (0: watch, 1: cook_timer, 2: stop_watch)
    reg [1:0] mode = 2'b00;
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            // skip reset
        end
        else if(btn_mode) begin
            case(mode)
                2'b00: mode = 2'b01;    // watch -> cook_timer
                2'b01: mode = 2'b10;    // cook_timer -> stop_watch
                2'b10: mode = 2'b00;    // stop_watch -> watch
                default: mode = 2'b00;  // 예외 상황 시 초기 상태로
            endcase
        end
    end
    

    // watch_top 모듈 신호 선언
    wire [7:0] watch_seg_7;
    wire [3:0] watch_com;
    wire [15:0] watch_led;
    
    // watch_top 인스턴스
    watch_top watch_top_mode(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn[2:0]),  // btn[2:0]을 watch_top의 버튼으로 사용
        .seg_7(watch_seg_7),
        .com(watch_com),
        .led(watch_led)
    );
    
    // cook_timer 모듈 신호 선언
    wire [7:0] cook_timer_seg_7;
    wire [3:0] cook_timer_com;
    wire [15:0] cook_timer_led;
    wire cook_timer_alarm;
    
    // cook_timer 인스턴스
    cook_timer cook_timer_mode(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn[3:0]),  // btn[3:0]을 cook_timer의 버튼으로 사용
        .seg_7(cook_timer_seg_7),
        .com(cook_timer_com),
        .alarm(cook_timer_alarm),
        .led(cook_timer_led)
    );
    
    // stop_watch 모듈 신호 선언
    wire [7:0] stop_watch_seg_7;
    wire [3:0] stop_watch_com;
    wire [15:0] stop_watch_led;
    
    // stop_watch 인스턴스
    stop_watch stop_watch_mode(
        .clk(clk),
        .reset_p(reset_p),
        .btn(btn[2:0]),  // btn[2:0]을 stop_watch의 버튼으로 사용
        .seg_7(stop_watch_seg_7),
        .com(stop_watch_com),
        .led(stop_watch_led)
    );

    // mode에 따른 출력
    always @(*) begin
        case(mode)
            2'b00: begin  // watch mode
                seg_7 = watch_seg_7;
                com = watch_com;
                led = watch_led;
                alarm = 0;
            end
            2'b01: begin  // cook_timer mode
                seg_7 = cook_timer_seg_7;
                com = cook_timer_com;
                led = cook_timer_led;
                alarm = cook_timer_alarm;
            end
            2'b10: begin  // stop_watch mode
                seg_7 = stop_watch_seg_7;
                com = stop_watch_com;
                led = stop_watch_led;
                alarm = 0;
            end
            default: begin
                seg_7 = 0;
                com = 0;
                led = 0;    // 전체 LED를 0으로 설정
                alarm = 0;  // 기본값
            end
        endcase
    end
    
endmodule

