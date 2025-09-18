`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2025 10:14:34 AM
// Design Name: 
// Module Name: vga_disp_top
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


module vga_disp_top(
    input clk100,          // 100MHz 시스템 클럭
    input btn,             // 리셋 버튼 (Center button)
    output [3:0] vga_red,   
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output vga_hsync,
    output vga_vsync,
    output [3:0] LED       // 디버깅용 LED
    );
    
    // 내부 신호
    reg clk25 = 0;         // 25MHz VGA 클럭
    reg [1:0] clk_count = 0; // 클럭 분주 카운터
    wire [9:0] h_cnt, v_cnt;
    wire [16:0] frame_addr;
    reg [11:0] frame_pixel;
    wire reset;
    
    // 리셋 신호 (버튼을 누르면 리셋)
    assign reset = btn;
    
    // 100MHz에서 25MHz 클럭 생성 (100MHz / 4 = 25MHz)
    always @(posedge clk100 or posedge reset) begin
        if (reset) begin
            clk_count <= 0;
            clk25 <= 0;
        end else begin
            clk_count <= clk_count + 1;
            if (clk_count == 2'b01) begin  // 2번째 사이클에서 토글
                clk25 <= ~clk25;
                clk_count <= 0;
            end
        end
    end
    
    // VGA 모듈 인스턴스화
    vga_disp vga_inst (
        .clk25(clk25),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .HCnt(h_cnt),
        .VCnt(v_cnt),
        .frame_addr(frame_addr),
        .frame_pixel(frame_pixel)
    );
    
    // 디버깅용 LED - 동작 상태 표시
    assign LED[0] = clk25;           // 25MHz 클럭 표시
    assign LED[1] = |h_cnt[9:8];     // 수평 카운터 상위 비트
    assign LED[2] = |v_cnt[9:8];     // 수직 카운터 상위 비트  
    assign LED[3] = ~reset;          // 리셋 상태 (리셋 안될 때 켜짐)
    
    // 테스트 패턴 생성 로직
    always @(*) begin
        frame_pixel = 12'h000; // 기본값: 검은색
        
        // 화면 영역 체크 (640x480 해상도)
        if (h_cnt < 640 && v_cnt < 480) begin
            // 화면을 세 개 영역으로 분할
            if (h_cnt < 213) begin
                // 좌측 1/3: 빨간색 그라데이션
                frame_pixel = {h_cnt[7:4], 8'h00};
            end else if (h_cnt < 426) begin
                // 중앙 1/3: 녹색 그라데이션
                frame_pixel = {4'h0, h_cnt[7:4], 4'h0};
            end else begin
                // 우측 1/3: 파란색 그라데이션
                frame_pixel = {8'h00, h_cnt[7:4]};
            end
            
            // 가로 중앙선 (화면 중앙에 흰색 선)
            if (v_cnt == 240)
                frame_pixel = 12'hFFF;
                
            // 세로 중앙선 (화면 중앙에 흰색 선)
            if (h_cnt == 320)
                frame_pixel = 12'hFFF;
                
            // 테스트 박스 (좌상단에 작은 흰색 사각형)
            if (h_cnt >= 10 && h_cnt < 50 && v_cnt >= 10 && v_cnt < 50)
                frame_pixel = 12'hFFF;
        end
    end
    
    
endmodule
