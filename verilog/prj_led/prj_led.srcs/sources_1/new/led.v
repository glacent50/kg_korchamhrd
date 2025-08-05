`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:23:10 AM
// Design Name: 
// Module Name: led
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


module led_blink_1s(
    input clk,
    input reset,
    output reg [7:0] led
    );

    reg clk_1hz;
    reg [26:0] count;

    // 간단하게 1Hz 클럭 생성
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_1hz <= 0;
        end
        else begin
            if(count == 49999999) begin
                count <= 0;
                clk_1hz <= ~clk_1hz;
            end
            else begin
                count <= count + 1;
            end
        end
    end

    always @(posedge clk_1hz or posedge reset) begin
        if (reset) begin
            led <= 8'b00000000;
        end
        else begin
            led <= ~led;
        end
    end

endmodule


module led_shift_R (
    input clk,
    input reset,
    output reg [7:0] led
    );

    reg clk_1hz;
    reg [26:0] count;
    reg dir; // 방향 제어 신호 추가

    // 간단하게 1Hz 클럭 생성
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_1hz <= 0;
        end
        else begin
            if(count == 49999999) begin
                count <= 0;
                clk_1hz <= ~clk_1hz;
            end
            else begin
                count <= count + 1;
            end
        end
    end

    // LED 이동 상태 업데이트
    always @(posedge clk_1hz or posedge reset) begin
        if (reset) begin
            led <= 8'b10000000;   // 왼쪽 끝부터 시작
            dir <= 0;             // 오른쪽 방향으로 시작
        end else begin
            if (dir == 0) begin   // 오른쪽 이동
                if (led == 8'b00000001)
                    dir <= 1;     // 오른쪽 끝 도달하면 방향 반전
                else
                    led <= led >> 1;
            end else begin        // 왼쪽 이동
                if (led == 8'b10000000)
                    dir <= 0;     // 왼쪽 끝 도달하면 방향 반전
                else
                    led <= led << 1;
            end
        end
    end

endmodule


module button_led(
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    output reg [7:0] led
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 8'b0000_0000;
        end else begin
            if (btn_L)
                led <= 8'b0000_0000;
            else if (btn_R)
                led <= 8'b1111_1111;
        end
    end

endmodule

module debounce (
    input clk,
    input reset,
    input noise_btn,
    output reg clean_btn
);

    reg [16:0] cnt;
    reg btn_sync_0, btn_sync_1;
    reg btn_state;

    // 2단 동기화
    always @(posedge clk) begin
        btn_sync_0 <= noise_btn;
        btn_sync_1 <= btn_sync_0;
    end

    // 디바운스 로직
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= 0;
            btn_state <= 0;
            clean_btn <= 0;
        end else begin
            if (btn_sync_1 == btn_state) begin
                cnt <= 0;           // 입력이 이전 상태와 같으면: 안정된 상태 -> 카운터 리셋
            end else begin
                cnt <= cnt + 1;     // 이전상태와 다르면 카운트 증가

                if (cnt >= 100_000) begin  // 1ms 유지 확인
                    btn_state <= btn_sync_1;
                    clean_btn <= btn_sync_1;
                    cnt <= 0;
                end
            end
        end
    end
endmodule

module btn_led_blink (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    output reg [7:0] led
);

    wire btn_L_clean;
    wire btn_R_clean;

    debounce U1(
        .clk(clk), .reset(reset),
        .noise_btn(btn_L),          // 원래 버튼
        .clean_btn(btn_L_clean)     // 디바운싱된 출력
    );

    debounce U2(
        .clk(clk), .reset(reset),
        .noise_btn(btn_R),          // 원래 버튼
        .clean_btn(btn_R_clean)     // 세탁된 버튼 출력
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 8'b0000_0000;
        end
        else begin
            if (btn_L_clean)
                led <= 8'b0000_0000;
            else if (btn_R_clean)
                led <= 8'b1111_1111;
        end
    end

endmodule