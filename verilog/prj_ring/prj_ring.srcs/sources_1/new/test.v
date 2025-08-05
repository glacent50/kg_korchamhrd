`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2025 11:25:02 AM
// Design Name: 
// Module Name: test
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


module edge_detector_n(
    input clk,
    input reset_p,
    input cp,
    output p_edge,
    output n_edge
    );

    reg ff_cur, ff_old;

    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 0;
            ff_old <= 0;
        end else begin
            ff_old <= ff_cur;
            ff_cur <= cp;
        end
    end

    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule

    // cur = 1, old = 0 => p = 1
    // cur = 1, old = 1 => p = 0
    // cur = 0, old = 1 => n = 1


module edge_detector_p(
    input clk,
    input reset_p,
    input cp,
    output p_edge,
    output n_edge
    );

    reg ff_cur, ff_old;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 1'b0;
            ff_old <= 1'b0;
        end else begin
            ff_old <= ff_cur;
            ff_cur <= cp;
        end
    end

    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1'b1 : 1'b0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1'b1 : 1'b0;
endmodule



////////////////////////////////////////
// ring_counter
// 1개의 비트가 정해진 순서대로 한비트씩 이동 순환
////////////////////////////////

// ring counter BASIC
module ring_counter (
    input clk,
    input reset_p,
    output reg [3:0] q
);
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b0001;       // 초기갑 0001 설정
        end
        else begin
            case (q)
                4'b0001 : q <= 4'b0010;
                4'b0010 : q <= 4'b0100;
                4'b0100 : q <= 4'b1000;
                4'b1000 : q <= 4'b0001;
                default : q <= 4'b0001; // 문제 생기면 초기값으로 !!
            endcase
        end
    end
    
endmodule


module ring_counter_shift (
    input clk, 
    input reset_p,
    output reg [3:0] q
);

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b0001;
        end
        else begin
            if (q == 4'b1000)
                q <= 4'b0001;
            else if (q == 4'b0000 || q > 4'b1000)
                q <= 4'b0001;
            else
                q <= {q[2:0], 1'b0};
        end
    end

    
endmodule



module ring_counter_fnd (
    input clk, reset_p,
    output reg [3:0] q
);

    reg [3:0] clk_div = 0;     // 17비트면,, 10만 이상
    //클럭 분주
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    wire clk_div_16_p;

    edge_detector_n ed(
        .clk(clk),
        .reset_p(reset_p),
        .cp(clk_div[3]),
        .n_edge(clk_div_16_p)
    );

    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b1110;
        end
        else if (clk_div_16_p) begin
            if (q == 4'b0111)
                q <= 4'b1110;
            else
                q <= {q[2:0], 1'b1};
        end
    end
    
endmodule




module ring_counter_led (
    input clk, reset_p,
    output reg [15:0] led
);

    reg [20:0] clk_div = 0;
    
    always @(posedge clk) begin
        clk_div = clk_div + 1;
    end

    wire clk_div_20_p;

    edge_detector_p ed(
        .clk(clk),
        .reset_p(reset_p),
        .cp(clk_div[20]),
        .p_edge(clk_div_20_p)
    );

    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            led = 16'b0000_0000_0000_0001;
        else if(clk_div_20_p)
            led = {led[14:0], led[15]};
    end
    
endmodule