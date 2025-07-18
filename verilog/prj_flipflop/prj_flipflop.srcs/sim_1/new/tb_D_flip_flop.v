`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 03:14:08 PM
// Design Name: 
// Module Name: tb_D_flip_flop
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


module tb_D_flip_flop;

    reg clk;
    reg d;
    wire q;

    D_flip_flop_Basic uut(
        .clk(clk),
        .d(d),
        .q(q)
    );

    // 클럭 생성
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk; // 10ns 주기 클럭 (100MHz)
        end
    end
    
    // 테스트 시나리오
    initial begin        
        // 초기값 설정
        d = 0;
        
        // 시뮬레이션 시작 메시지 출력
        $display("D 플립플롭 테스트벤치 시작 (시간: %0t)", $time);
        $display("----------------------------------------");
        $display("| 시간  | 클럭 | D 입력 | Q 출력 |");
        $display("----------------------------------------");

        // $monitor 명령어: 모니터링 중인 신호($time, clk, d, q)가 
        $monitor("| %5t |  %b   |   %b    |   %b    |", $time, clk, d, q);

        
        // 15ns 이후에 d = 1 (clk 상승에지에서 q에 반영)
        #15 d = 1;
        
        // 20ns 
        #20 d = 0;

        // 20ns
        #20 d = 1;
        
        // 시뮬레이션 종료
        #30 $finish;
    end

endmodule


module tb_D_flip_flop_n;

    reg d;
    reg clk;
    reg reset_p;
    reg enable;
    wire q;

    D_flip_flop_n dut(
        .d(d),
        .clk(clk),
        .reset_p(reset_p),
        .enable(enable),
        .q(q)
    );

    initial begin
        // 신호 초기화
        clk = 0;
        d = 0;
        reset_p = 1;  // 액티브 하이 리셋, 리셋 활성화 상태로 시작
        enable = 0;   // 인에이블 비활성화 상태로 시작
        
        // 테스트 헤더 출력
        $display("\nD 플립플롭 (리셋/인에이블) 테스트벤치 시작 (시간: %0t)", $time);
        $display("------------------------------------------------------");
        $display("| 시간  | 클럭 | 리셋 | 인에이블 | D 입력 | Q 출력 |");
        $display("------------------------------------------------------");
        $monitor("| %5t |  %b   |   %b   |    %b     |   %b    |   %b    |", 
                 $time, clk, reset_p, enable, d, q);
        
        // 10ns 후 리셋 해제
        #10 reset_p = 0;
        
        // 인에이블=1로 테스트
        #10 enable = 1;
        
        // 다양한 데이터 값 테스트
        #10 d = 1;
        #10 d = 0;
        #10 d = 1;
        
        // 동작 중 리셋 테스트
        #10 reset_p = 1;
        #10 reset_p = 0;
        
        // 인에이블=0으로 테스트 (출력이 변경되지 않아야 함)
        #10 enable = 0;
        #10 d = 0;  // 이 변경은 q에 영향을 주지 않아야 함
        #10 d = 1;  // 이 변경은 q에 영향을 주지 않아야 함
        
        // 인에이블 다시 활성화
        #10 enable = 1;
        #10 d = 0;
        
        // 시뮬레이션 종료
        #10 $finish;
    end
    
    // 클럭 생성기
    always begin
        #5 clk = ~clk;  // 10ns 주기 클럭 (100MHz)
    end
endmodule