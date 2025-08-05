`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:32:45 AM
// Design Name: 
// Module Name: tb_led_blink
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


module tb_led_blink;

    // 신호 선언
    reg clk;
    reg reset;
    wire [7:0] led;

    // DUT 인스턴스화
    led_blink_1s uut (
        .clk(clk),
        .reset(reset),
        .led(led)
    );

    // 클럭 생성
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz 기준 (10ns period)

    // 리셋 시퀀스
    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    // 시뮬레이션 종료
    initial begin
        #200000000; // 충분한 시간 시뮬레이션 (200ms)
        $finish;
    end

    // LED 출력 모니터링
    initial begin
        $monitor("Time=%0t | reset=%b | led=%b", $time, reset, led);
    end

endmodule


module tb_led_shift_R;
    // 신호 선언
    reg clk;
    reg reset;
    wire [7:0] led;

    // DUT 인스턴스화 (led_shift_R 모듈명은 실제 DUT에 맞게 수정 필요)
    led_shift_R uut (
        .clk(clk),
        .reset(reset),
        .led(led)
    );

    // 클럭 생성
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz 기준 (10ns period)

    // 리셋 시퀀스
    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    // 시뮬레이션 종료
    initial begin
        #200000000; // 충분한 시간 시뮬레이션 (200ms)
        $finish;
    end

    // LED 출력 모니터링
    initial begin
        $monitor("Time=%0t | reset=%b | led=%b", $time, reset, led);
    end
endmodule
