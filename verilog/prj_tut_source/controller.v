`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 02:29:27 PM
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
    always @(posedge clk)clk_div = clk_div + 1;
    
    anode_selector ring_com(
        .scan_count(clk_div[16:15]), .an_out(com));
    reg [3:0] digit_value; 
    wire [15:0] out_value;
    assign out_value = hex_bcd ? fnd_value : bcd_value;   
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
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
    seg_decoder dec(.digit_in(digit_value), .seg_out(seg_7));
    
    
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

module btn_cntr(
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_nedge);
    wire debounced_btn;
    debounce btn_0(.clk(clk), .btn_in(btn), .btn_out(debounced_btn));
    
    edge_detector_p btn_ed(
        .clk(clk), .reset_p(reset_p), .cp(debounced_btn),
        .p_edge(btn_pedge), .n_edge(btn_nedge));

endmodule









































