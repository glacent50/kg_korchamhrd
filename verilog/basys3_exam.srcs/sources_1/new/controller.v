`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 02:30:18 PM
// Design Name: 
// Module Name: controller
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


module fnd_cntr(
    input clk, reset_p,
    input [15:0] fnd_value,
    input hex_bcd,
    output [7:0] seg_7,
    output [3:0] com);

    wire [15:0] bcd_value;
    bin_to_dec bcd(.bin(fnd_value[11:0]), .bcd(sec_bcd));

    reg [16:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;

    anode_selector ring_com(
        .scan_count(clk_div[16:15]), .an_out(com));

    reg [3:0] digit_value;
    wire [15:0] out_value;

    assign out_value = hex_bcd ? fnd_value : bcd_value;

    always @(posedge clk or posedge reset_p) begin // 수정: reset_p 조건을 posedge로 변경
        if(reset_p) begin
            digit_value = 0;
        end
        else begin
            case(com)
                4'b1110 : digit_value = out_value[3:0];
                4'b1101 : digit_value = out_value[7:4];
                4'b1011 : digit_value = out_value[11:8];
                4'b0111 : digit_value = out_value[15:12];
            endcase
        end
    end

    seg_decoder dec(.digit_in(digit_value), .seg_out(seg_7)); // 수정: 세미콜론 추가

endmodule



module bin_to_dec(
    input [11:0] bin,           // 12비트 이진 입력
    output reg [15:0] bcd       // 4자리의 BCD를 출력 (4비트 x 4자리)
    );

    integer i;      // 반복문

    always @(bin) begin

        bcd = 0;    // initial value

        for(i = 0; i < 12; i = i + 1) begin
            // 1) 알고리즘 각 단위비트 자리별로 5이상이면 +3 해줌
            if(bcd[3:0] >= 5) bcd[3:0] = bcd[3:0] + 3;          // 1의 자리수
            if(bcd[7:4] >= 5) bcd[7:4] = bcd[7:4] + 3;          // 10의 자리수
            if(bcd[11:8] >= 5) bcd[11:8] = bcd[11:8] + 3;       // 100의 자리수
            if(bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] +3;     // 1000의 자리수

            // 2) 1비트 left shift + 새로운 비트 붙임
            bcd = {bcd[14:0], bin[11 - i]};
        end

    end
endmodule

module debounce (
    input clk,
    input btn_in,
    output reg btn_out
);

    reg [15:0] count;
    reg btn_sync_0, btn_sync_1;
    wire stable = (count == 16'hFFFF);

    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk) begin
        if(btn_sync_1 == btn_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if(stable)
                btn_out <= btn_sync_1;
        end
    end

endmodule

module btn_cntr (
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_nedge);

    wire debounced_btn;
    debounce btn_0 (.clk(clk), .btn_in(btn), .btn_out(debounced_btn));

    edge_detector_p btn_ed(
        .clk(clk), .reset_p(reset_p), .cp(debounced_btn),
        .p_edge(btn_pedge), .n_edge(btn_nedge)); 
    
endmodule