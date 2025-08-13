//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2025 10:27:47 AM
// Design Name: 
// Module Name: exam02_sequential_logic
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

module D_flip_flop_n(
    input d,
    input clk,
    input enable,
    input reset_p,
    output reg q
);

    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            q = 1'b0;
        end
        else begin
            if(enable) begin
                q = d;
            end
        end
    end

endmodule


module D_flip_flop_p(
    input d,
    input clk,
    input enable,
    input reset_p,
    output reg q
);

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            q = 1'b0;
        end
        else begin
            if(enable) begin
                q = d;
            end
        end
    end

endmodule


module T_flip_flop_n(
    input clk, reset_p,
    input enable,
    input t,
    output reg q
);

    always @(negedge clk or posedge reset_p) begin
        if(reset_p)
            q = 1'b0;
        else begin
            if(enable) begin
                if(t) q = ~q;
                else q = q;
            end
        end
    end

endmodule

module T_flip_flop_p(
    input clk, reset_p,
    input enable,
    input t,
    output reg q
);

    always @(posedge clk or posedge reset_p) begin
        if(reset_p)
            q = 1'b0;
        else begin
            if(enable) begin
                if(t) q = ~q;
                else q = q;
            end
        end
    end

endmodule

module up_counter_async(
    input clk, reset_p,
    output [3:0] count
);

    //wire [2:0] q;
    T_flip_flop_n cnt0(.clk(clk),      .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[0]));
    T_flip_flop_n cnt1(.clk(count[0]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[1]));
    T_flip_flop_n cnt2(.clk(count[1]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[2]));
    T_flip_flop_n cnt3(.clk(count[2]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[3]));

endmodule

module down_counter_async(
    input clk, reset_p,
    output [3:0] count
);

    //wire [2:0] q;
    T_flip_flop_p cnt0(.clk(clk),      .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[0]));
    T_flip_flop_p cnt1(.clk(count[0]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[1]));
    T_flip_flop_p cnt2(.clk(count[1]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[2]));
    T_flip_flop_p cnt3(.clk(count[2]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[3]));

endmodule


// 순차 회로는 always 구문을 만들어서 처리.

module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count = 0;
        else count = count + 1;
    end

endmodule

/**
 * @brief 음의 엣지 클록과 네거티브 리셋에 동작하는 4비트 업 카운터
 * @param clk 클록 입력 (negedge에서 동작)
 * @param reset_p 비동기 리셋 입력 (active high)
 * @param count 4비트 카운트 출력
 */
module up_counter_n(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(negedge clk, negedge reset_p) begin
        if(reset_p)
            count = 0;
        else
            count = count + 1;
    end

endmodule

/**
 * @brief 양의 엣지 클록과 포지티브 리셋에 동작하는 4비트 다운 카운터
 * @param clk 클록 입력 (posedge에서 동작)
 * @param reset_p 비동기 리셋 입력 (active high)
 * @param count 4비트 카운트 출력
 */
module down_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count = 0;
        else count = count - 1;
    end

endmodule


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
                q <= {q[2:0], 1'b0}; //회로가 없음. 쉬프트 연산 사용안함.
        end
    end

    
endmodule


module ring_counter_p (
    input clk,
    input reset_p,
    output reg [3:0] q
);
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) q <= 4'b0001;       // 초기갑 0001 설정
        else q <= {q[2:0], q[3]};
    end
    
endmodule


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


module ring_counter_led (
    input clk,
    input reset_p,
    output reg [15:0] q
);
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) q <= 16'b0000_0000_0000_0001;       // 초기갑 0001 설정
        else q <= {q[2:0], q[3]};
    end
    
endmodule














