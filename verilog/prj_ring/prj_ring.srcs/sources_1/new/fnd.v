`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2025 02:58:51 PM
// Design Name: 
// Module Name: fnd
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

/*
* 클럭 분주기 100MHz -> 1Hx
* 0 ~ 59 까지 카운트
* BCD 변환 (12분 34초) 1 2 3 4
* 세그먼트 구분
*/


module clock_divider_1Hz (
    input clk,
    input reset_p,
    output reg clk_1Hz
);
    reg [26:0] count;   // 자릿수가 약 6천만
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            count <= 0;
            clk_1Hz <= 0;
        end else begin
            if (count == 49_999_999) begin
                count <= 0;
                clk_1Hz <= ~clk_1Hz;
            end else begin
                count <= count + 1;
            end
        end
    end    
endmodule


// 1Hz 클럭을 이용하여 분,초를 BCD 형식으로 카운트
module time_counter (
    input clk_1Hz,
    input reset_p,
    output reg [3:0] sec_ones,  // 초 1의 자리
    output reg [3:0] sec_tens,  // 초 10의 자리
    output reg [3:0] min_ones,  // 분 1의 자리
    output reg [3:0] min_tens   // 분 10의 자리
);

    // 초 증가
    always @(posedge clk_1Hz or posedge reset_p) begin
        if (reset_p) begin
            sec_ones <= 0;
            sec_tens <= 0;
        end
        else begin
            if (sec_ones == 9) begin
                sec_ones <= 0;
                if(sec_tens == 5)   // 59초에서 0초로 넘어갈때 BCD 니까...
                    sec_tens <= 0;
                else
                    sec_tens <= sec_tens + 1;
            end
            else begin
                sec_ones <= sec_ones + 1;
            end
        end
    end

    // 분 증가
    always @(posedge clk_1Hz or posedge reset_p) begin
        if (reset_p) begin
            min_ones <= 0;
            min_tens <= 0;
        end
        else if (sec_tens == 5 && sec_ones == 9) begin
            if (min_ones == 9) begin
                min_ones <= 0;
                if(min_tens == 5)
                   min_tens <= 0;
                else
                   min_tens <= min_tens + 1;
            end
            else begin
                min_ones <= min_ones + 1;
            end
        end
    end
endmodule


// 100MHz 입력받아 2KHz 생성
// 이 클럭을 이용해서 7세그먼트 디스플레이 자리를 스캔
module clock_divider_2KHz (
    input clk,
    input reset_p,
    output reg clk_2KHz
);

    reg [15:0] count;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            count <= 0;
            clk_2KHz <= 0;
        end
        else begin
            if (count == 24_999) begin
                count <= 0;
                clk_2KHz <= ~clk_2KHz;
            end
            else begin
                count <= count + 1;
            end
        end
    end    
endmodule

// 2KHz 를 이용해서 어떤자리 표시 할지?
// 해당자리에 맞는 시간(select_digit)을 선택
module display_scan_controller (
    input scan_clk,
    input reset_p,
    input [3:0] sec_ones,
    input [3:0] sec_tens,
    input [3:0] min_ones,
    input [3:0] min_tens,
    output reg [1:0] scan_count,
    output reg [3:0] select_digit
);
    
    always @(posedge scan_clk or posedge reset_p) begin
        if (reset_p) begin
            scan_count <= 0;
        end
        else begin
            scan_count <= scan_count + 1;
        end
    end

    always @(*) begin
        case (scan_count)
            2'd0: select_digit = sec_ones;  // 첫번째 자리
            2'd1: select_digit = sec_tens;
            2'd2: select_digit = min_ones;
            2'd3: select_digit = min_tens;
            default: select_digit = 0;
        endcase
    end
endmodule

// BCD
// digit_in을 받아서 7세그먼트 디스플레이에 표시하기 위한 패턴
module seg_decoder (
    input [3:0] digit_in,
    output reg [7:0] seg_out
);

    always @(*) begin
        case (digit_in)
            4'd0: seg_out = 8'b1100_0000;   // 0 (dp 꺼짐)
            4'd1: seg_out = 8'b1111_1001; // 1
            4'd2: seg_out = 8'b1010_0100; // 2
            4'd3: seg_out = 8'b1011_0000; // 3
            4'd4: seg_out = 8'b1001_1001; // 4
            4'd5: seg_out = 8'b1001_0010; // 5
            4'd6: seg_out = 8'b1000_0010; // 6
            4'd7: seg_out = 8'b1111_1000; // 7
            4'd8: seg_out = 8'b1000_0000; // 8
            4'd9: seg_out = 8'b1001_0000; // 9
            default: seg_out = 8'b1111_1111;    
        endcase
    end    
endmodule

// 자릿수 선택
// dispaly_scan_controller 에서 넘어온 
// 현재 스캔중인 자리 인덱스(scan_count)를 기반으로 4자리 선택
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

module digital_clock_top (
    input clk,
    input reset_p,
    output [7:0] seg,
    output [3:0] an
);

    // 내부 연결 와이어
    wire  clk_1Hz;
    wire scan_clk_2KHz;
    wire [3:0] sec_ones_out;
    wire [3:0] sec_tens_out;
    wire [3:0] min_ones_out;
    wire [3:0] min_tens_out;
    wire [1:0] scan_count_out;
    wire [3:0] select_digit;

    clock_divider_1Hz u1(
        .clk(clk),
        .reset_p(reset_p),
        .clk_1Hz(clk_1Hz)
    );

    time_counter u2(
        .clk_1Hz(clk_1Hz),
        .reset_p(reset_p),
        .sec_ones(sec_ones_out),
        .sec_tens(sec_tens_out),
        .min_ones(min_ones_out),
        .min_tens(min_tens_out)
    );

    clock_divider_2KHz u3(
        .clk(clk),
        .reset_p(reset_p),
        .clk_2KHz(scan_clk_2KHz)
    );

    display_scan_controller u4(
        .scan_clk(scan_clk_2KHz),
        .reset_p(reset_p),
        .sec_ones(sec_ones_out),
        .sec_tens(sec_tens_out),
        .min_ones(min_ones_out),
        .min_tens(min_tens_out),
        .scan_count(scan_count_out),
        .select_digit(select_digit)
    );

    seg_decoder u5(
        .digit_in(select_digit),
        .seg_out(seg)
    );

    anode_selector u6(
        .scan_count(scan_count_out),
        .an_out(an)
    );

endmodule