`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2025 11:05:17 AM
// Design Name: 
// Module Name: stop_watch
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
*   버튼 1 (btn_start_stop)
*   버튼 2 (btn_rest)
*   0.1초 단위로 증가 (10Hz)
*   MM : SS 형식
*/


//module clock_divider_10Hz(
//    input clk,
//    output reset_p,
//    output reg clk_10Hz
//);
    
//    reg [23:0] count;   // 100_000_000 / (10Hz *2) = 5_000_000

//    always @(posedge clk or posedge reset_p) begin
//        if (reset_p) begin
//            count <= 0;
//            clk_10Hz <= 0;
//        end
//        else begin
//            if (count == 24'd4_999_999) begin
//                count <= 0;
//                clk_10Hz <= ~clk_10Hz;
//            end else
//                count <= count + 1;
//        end
//    end

//endmodule


//module stopwatch_counter (
//    input clk_10Hz,
//    input reset_p,
//    input btn_start_stop,
//    input btn_reset,
//    output reg [3:0] sec_ones,
//    output reg [3:0] sec_tens,
//    output reg [3:0] min_ones,
//    output reg [3:0] min_tens
//);

//    parameter IDEL      = 2'b00;    // 대기
//    parameter RUNNING   = 2'b01;    // 동작
//    parameter PAUSED    = 2'b10;    // 일시정지

//    reg [1:0] current_state, next_state;

//    always @(posedge clk_10Hz or posedge reset_p) begin
//        if (reset_p)
//            current_state <= IDEL;          // 리셋시 idel로
//        else
//            current_state <= next_state;    // 다음 상태로
        
//    end

//    always @(*) begin
//        case (current_state)
//            IDEL:begin
//                // 정지에서 start 누르면 running
//                next_state = btn_start_stop ? RUNNING : IDEL;
//            end 
//            RUNNING:begin
//                // 동작일때 버튼 누르면 일시정지
//                next_state = btn_start_stop ? PAUSED : RUNNING;
//            end
//            PAUSED:begin
//                // 일시정지 에 reset 누르면 idel
//                // 아니면 start 누르면 running
//                if (btn_reset)
//                    next_state = IDEL;
//                else if (btn_start_stop)
//                    next_state = RUNNING;
//                else
//                    next_state = PAUSED;
//            end
//            default: next_state = IDEL;
//        endcase
//    end
    
//    always @(posedge clk_10Hz or posedge reset_p) begin
//        if (reset_p || current_state == IDEL) begin
//            // 리셋 누르거나 정지 상태면 모두 0으로
//            sec_ones <= 0;
//            sec_tens <= 0;
//            min_ones <= 0;
//            min_tens <= 0;
//        end
//        else if (current_state == RUNNING) begin
//            // 동작중일때만 시간 증가
//            if (sec_ones == 9) begin
//                sec_ones <= 0;
//                if (sec_tens == 5) begin
//                    sec_tens <= 0;
//                    if (min_ones == 9) begin
//                        min_ones <= 0;
//                        if (min_tens == 5)
//                            min_tens <= 0;                        
//                        else
//                            min_tens <= min_tens + 1;
//                    end 
//                    else begin
//                        min_ones <= min_ones + 1;
//                    end
//                end 
//                else begin
//                    sec_tens <= sec_tens + 1;
//                end
//            end 
//            else begin
//                sec_ones <= sec_ones + 1;
//            end           
//        end
//    end

//endmodule




//module debounce (
//    input clk,
//    input btn_in,
//    output reg btn_out
//);

//    reg [15:0] count;
//    reg btn_sync_0, btn_sync_1;
//    wire stable = (count == 16'hFFFF);

//    // 동기화
//    always @(posedge clk) begin
//        btn_sync_0 <= btn_in;
//        btn_sync_1 <= btn_sync_0;
//    end

//    // 카운터 기반으로 디바운스
//    always @(posedge clk) begin
//        if (btn_sync_1 == btn_out) begin
//            count <= 0;
//        end else begin
//            count <= count + 1;
//            if (stable)
//                btn_out <= btn_sync_1;
//        end
//    end
    
//endmodule

//// 나머지 모듈...재사용
//// clock_divider_2KHz
//// display_scan_controller
//// seg_decoder
//// anode_selector


//// 100MHz 입력받아 2KHz 생성
//// 이 클럭을 이용해서 7세그먼트 디스플레이 자리를 스캔
//module clock_divider_2KHz (
//    input clk,
//    input reset_p,
//    output reg clk_2KHz
//);

//    reg [15:0] count;

//    always @(posedge clk or posedge reset_p) begin
//        if (reset_p) begin
//            count <= 0;
//            clk_2KHz <= 0;
//        end
//        else begin
//            if (count == 24_999) begin
//                count <= 0;
//                clk_2KHz <= ~clk_2KHz;
//            end
//            else begin
//                count <= count + 1;
//            end
//        end
//    end    
//endmodule

//// 2KHz 를 이용해서 어떤자리 표시 할지?
//// 해당자리에 맞는 시간(select_digit)을 선택
//module display_scan_controller (
//    input scan_clk,
//    input reset_p,
//    input [3:0] sec_ones,
//    input [3:0] sec_tens,
//    input [3:0] min_ones,
//    input [3:0] min_tens,
//    output reg [1:0] scan_count,
//    output reg [3:0] select_digit
//);
    
//    always @(posedge scan_clk or posedge reset_p) begin
//        if (reset_p) begin
//            scan_count <= 0;
//        end
//        else begin
//            scan_count <= scan_count + 1;
//        end
//    end

//    always @(*) begin
//        case (scan_count)
//            2'd0: select_digit = sec_ones;  // 첫번째 자리
//            2'd1: select_digit = sec_tens;
//            2'd2: select_digit = min_ones;
//            2'd3: select_digit = min_tens;
//            default: select_digit = 0;
//        endcase
//    end
//endmodule

//// BCD
//// digit_in을 받아서 7세그먼트 디스플레이에 표시하기 위한 패턴
//module seg_decoder (
//    input [3:0] digit_in,
//    output reg [7:0] seg_out
//);

//    always @(*) begin
//        case (digit_in)
//            4'd0: seg_out = 8'b1100_0000;   // 0 (dp 꺼짐)
//            4'd1: seg_out = 8'b1111_1001; // 1
//            4'd2: seg_out = 8'b1010_0100; // 2
//            4'd3: seg_out = 8'b1011_0000; // 3
//            4'd4: seg_out = 8'b1001_1001; // 4
//            4'd5: seg_out = 8'b1001_0010; // 5
//            4'd6: seg_out = 8'b1000_0010; // 6
//            4'd7: seg_out = 8'b1111_1000; // 7
//            4'd8: seg_out = 8'b1000_0000; // 8
//            4'd9: seg_out = 8'b1001_0000; // 9
//            default: seg_out = 8'b1111_1111;    
//        endcase
//    end    
//endmodule

//// 자릿수 선택
//// dispaly_scan_controller 에서 넘어온 
//// 현재 스캔중인 자리 인덱스(scan_count)를 기반으로 4자리 선택
//module anode_selector (
//    input [1:0] scan_count,
//    output reg [3:0] an_out
//);
//    always @(*) begin
//        case (scan_count)
//            2'd0: an_out = 4'b1110; // an[0]
//            2'd1: an_out = 4'b1101; // an[1]
//            2'd2: an_out = 4'b1011; // an[2]
//            2'd3: an_out = 4'b0111; // an[3]
//            default: an_out = 4'b1111;
//        endcase
//    end
//endmodule



//module stopwatch_top (
//    input clk,
//    input reset_p,
//    input btn_start_stop,
//    input btn_reset,
//    output [7:0] seg,
//    output [3:0] an
//);
//    wire clk_10Hz;
//    wire [3:0] sec_ones, sec_tens, min_ones, min_tens;
//    wire [1:0] scan_count;
//    wire [3:0] select_digit;

//    wire start_stop_clean, reset_clean;

//    clock_divider_10Hz u1(
//        .clk(clk),
//        .reset_p(reset_p),
//        .clk_10Hz(clk_10Hz)
//    );

//    debounce du1(
//        .clk(clk),
//        .btn_in(btn_start_stop),
//        .btn_out(start_stop_clean)
//    );
//    debounce du2(
//        .clk(clk),
//        .btn_in(btn_reset),
//        .btn_out(reset_clean)
//    );

//    stopwatch_counter u2(
//        .clk_10Hz(clk_10Hz),
//        .reset_p(reset_p),
//        .btn_start_stop(start_stop_clean),
//        .btn_reset(reset_clean),
//        .sec_ones(sec_ones), .sec_tens(sec_tens),
//        .min_ones(min_ones), .min_tens(min_tens)
//    );

//    wire scan_clk;
//    clock_divider_2KHz u3(
//        .clk(clk),
//        .reset_p(reset_p),
//        .clk_2KHz(scan_clk)
//    );

//    display_scan_controller u4(
//        .scan_clk(scan_clk),
//        .reset_p(reset_p),
//        .sec_ones(sec_ones), .sec_tens(sec_tens),
//        .min_ones(min_ones), .min_tens(min_tens),
//        .scan_count(scan_count),
//        .select_digit(select_digit)
//    );

//    seg_decoder u5(
//        .digit_in(select_digit),
//        .seg_out(seg)
//    );

//    anode_selector u6(
//        .scan_count(scan_count),
//        .an_out(an)
//    );


//endmodule



/*
*   버튼 1 (btn_start_stop)
*   버튼 2 (btn_rest)
*   0.1초 단위로 증가 (10Hz)
*   MM : SS 형식
*/


module clock_divider_10Hz(
    input clk,
    output reset_p,
    output reg clk_10Hz
);
    
    reg [23:0] count;   // 100_000_000 / (10Hz *2) = 5_000_000

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            count <= 0;
            clk_10Hz <= 0;
        end
        else begin
            if (count == 24'd4_999_999) begin
                count <= 0;
                clk_10Hz <= ~clk_10Hz;
            end else
                count <= count + 1;
        end
    end

endmodule


module stopwatch_counter (
    input clk_10Hz,
    input reset_p,
    input btn_start_stop,
    input btn_reset,
    output reg [3:0] sec_ones,
    output reg [3:0] sec_tens,
    output reg [3:0] min_ones,
    output reg [3:0] min_tens
);

    parameter IDEL      = 2'b00;    // 대기
    parameter RUNNING   = 2'b01;    // 동작
    parameter PAUSED    = 2'b10;    // 일시정지

    reg [1:0] current_state, next_state;

    always @(posedge clk_10Hz or posedge reset_p) begin
        if (reset_p)
            current_state <= IDEL;          // 리셋시 idel로
        else
            current_state <= next_state;    // 다음 상태로
        
    end

    always @(*) begin
        case (current_state)
            IDEL:begin
                // 정지에서 start 누르면 running
                next_state = btn_start_stop ? RUNNING : IDEL;
            end 
            RUNNING:begin
                // 동작일때 버튼 누르면 일시정지
                next_state = btn_start_stop ? PAUSED : RUNNING;
            end
            PAUSED:begin
                // 일시정지 에 reset 누르면 idel
                // 아니면 start 누르면 running
                if (btn_reset)
                    next_state = IDEL;
                else if (btn_start_stop)
                    next_state = RUNNING;
                else
                    next_state = PAUSED;
            end
            default: next_state = IDEL;
        endcase
    end
    
    always @(posedge clk_10Hz or posedge reset_p) begin
        if (reset_p || current_state == IDEL) begin
            // 리셋 누르거나 정지 상태면 모두 0으로
            sec_ones <= 0;
            sec_tens <= 0;
            min_ones <= 0;
            min_tens <= 0;
        end
        else if (current_state == RUNNING) begin
            // 동작중일때만 시간 증가
            if (sec_ones == 9) begin
                sec_ones <= 0;
                if (sec_tens == 5) begin
                    sec_tens <= 0;
                    if (min_ones == 9) begin
                        min_ones <= 0;
                        if (min_tens == 5)
                            min_tens <= 0;                        
                        else
                            min_tens <= min_tens + 1;
                    end 
                    else begin
                        min_ones <= min_ones + 1;
                    end
                end 
                else begin
                    sec_tens <= sec_tens + 1;
                end
            end 
            else begin
                sec_ones <= sec_ones + 1;
            end           
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

    // 동기화
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // 카운터 기반으로 디바운스
    always @(posedge clk) begin
        if (btn_sync_1 == btn_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if (stable)
                btn_out <= btn_sync_1;
        end
    end
    
endmodule

// 나머지 모듈...재사용
// clock_divider_2KHz
// display_scan_controller
// seg_decoder
// anode_selector


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



module stopwatch_top (
    input clk,
    input reset_p,
    input btn_start_stop,
    input btn_reset,
    output [7:0] seg,
    output [3:0] an
);
    wire clk_10Hz;
    wire [3:0] sec_ones, sec_tens, min_ones, min_tens;
    wire [1:0] scan_count;
    wire [3:0] select_digit;

    wire start_stop_clean, reset_clean;

    clock_divider_10Hz u1(
        .clk(clk),
        .reset_p(reset_p),
        .clk_10Hz(clk_10Hz)
    );

    debounce du1(
        .clk(clk),
        .btn_in(btn_start_stop),
        .btn_out(start_stop_clean)
    );
    
    debounce du2(
        .clk(clk),
        .btn_in(btn_reset),
        .btn_out(reset_clean)
    );

    stopwatch_counter u2(
        .clk_10Hz(clk_10Hz),
        .reset_p(reset_p),
        .btn_start_stop(start_stop_clean),
        .btn_reset(reset_clean),
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens)
    );

    wire scan_clk;
    clock_divider_2KHz u3(
        .clk(clk),
        .reset_p(reset_p),
        .clk_2KHz(scan_clk)
    );

    display_scan_controller u4(
        .scan_clk(scan_clk),
        .reset_p(reset_p),
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .scan_count(scan_count),
        .select_digit(select_digit)
    );

    seg_decoder u5(
        .digit_in(select_digit),
        .seg_out(seg)
    );

    anode_selector u6(
        .scan_count(scan_count),
        .an_out(an)
    );


endmodule