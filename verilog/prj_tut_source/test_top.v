`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2025 11:23:59 AM
// Design Name: 
// Module Name: test_top
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


module ring_counter_led_top(
    input clk, reset_p,
    output reg [15:0] led);
    
    reg [20:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    wire clk_div_18;
    edge_detector_p clk_div_edge(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[18]),
        .p_edge(clk_div_18));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)led = 16'b0000_0000_0000_0001;
        else if(clk_div_18)led = {led[14:0], led[15]};
    end
    
endmodule

module watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [7:0] seg_7,
    output [3:0] com,
    output [15:0] led);
    
    wire btn_mode, inc_sec, inc_min;
    
    btn_cntr mode_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
    btn_cntr inc_sec__btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(inc_sec));
    btn_cntr inc_min_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(inc_min));
        
    reg set_watch;
    assign led[0] = set_watch;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            set_watch = 0;
        end
        else if(btn_mode)begin
            set_watch = ~set_watch;
        end
    end

    reg [26:0] cnt_sysclk;
    reg [7:0] sec, min;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            sec = 0;
            min = 0;
        end
        else begin
            if(set_watch)begin
                if(inc_sec)begin
                    if(sec >= 59)sec = 0;
                    else sec = sec + 1;
                end
                if(inc_min)begin
                    if(min >= 59)min = 0;
                    else min = min + 1;
                end
            end
            else begin
                if(cnt_sysclk >= 27'd99_999_999)begin
                    cnt_sysclk = 0;
                    if(sec >= 59)begin
                        sec = 0;
                        if(min >= 59)min = 0;
                        else min = min + 1;
                    end
                    else sec = sec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
        end
    end
    wire [15:0] sec_bcd, min_bcd;
    bin_to_dec bcd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value({min_bcd[7:0], sec_bcd[7:0]}), .hex_bcd(1),
        .seg_7(seg_7), .com(com));

endmodule

module cook_timer(
    input clk, reset_p,
    input [3:0] btn,
    output [7:0] seg_7,
    output [3:0] com,
    output reg alarm,
    output [14:0] led);
    
    reg [7:0] set_sec, set_min;
    reg start_set;
    reg [26:0] cnt_sysclk = 0;
    reg [7:0] sec, min;
    
    wire btn_mode, inc_sec, inc_min, alarm_off;
    wire [15:0] cur_time = {min, sec};
    wire [7:0] sec_bcd, min_bcd;    
    
    btn_cntr mode_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
    btn_cntr inc_sec__btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(inc_sec));
    btn_cntr inc_min_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(inc_min));
    btn_cntr alarm_off_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(alarm_off));
        
    assign led[0] = start_set;
    
    reg set_flag;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            start_set = 0;
            alarm = 0;
        end
        else if(btn_mode && cur_time != 0 && start_set == 0)begin
            start_set = 1;
            set_sec = sec;
            set_min = min;
        end
        else if(start_set && btn_mode)begin
            start_set = 0;
        end
        else if(start_set && min == 0 && sec == 0)begin
            start_set = 0;
            alarm = 1;
        end
        else if(alarm && (alarm_off || inc_sec || inc_min || btn_mode))begin
            alarm = 0;
            set_flag = 1;
        end
        else if(cur_time != 0)set_flag = 0;
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            sec = 0;
            min = 0;        
        end
        else begin
            if(start_set)begin
                if(cnt_sysclk >= 99_999_999)begin
                    cnt_sysclk = 0;
                    if(sec == 0)begin
                        if(min)begin
                            sec = 59;
                            min = min - 1;
                        end
                    end
                    else sec = sec - 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
            else begin
                if(inc_sec)begin
                    if(sec >= 59) sec = 0;
                    else sec = sec + 1;
                end
                else if(inc_min)begin
                    if(min >= 99)min = 0;
                    else min = min + 1;
                end
                if(set_flag)begin
                    sec = set_sec;
                    min = set_min;
                end
            end
        end
    end
    
    bin_to_dec bcd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec bcd_min(.bin(min), .bcd(min_bcd));
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value({min_bcd[7:0], sec_bcd[7:0]}), .hex_bcd(1),
        .seg_7(seg_7), .com(com));
    
endmodule

module stop_watch(
    input clk, reset_p,
    input [2:0] btn,
    output [7:0] seg_7, 
    output [3:0] com,
    output [15:0] led);

    wire btn_start, btn_lap, btn_clear;
    reg [7:0] sec, csec;
    wire [7:0] sec_bcd, csec_bcd;
    
    btn_cntr start_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
    btn_cntr lap__btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
    btn_cntr clear_btn(
        .clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));
        
    reg start_stop;
    assign led[0] = start_stop;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)start_stop = 0;
        else if(btn_start)start_stop = ~start_stop;
        else if(btn_clear)start_stop = 0;
    end
    
    reg lap;
    assign led[1] = lap;
    reg [7:0] lap_sec, lap_csec;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            lap = 0;
            lap_sec = 0;
            lap_csec = 0;
        end
        else if(btn_lap)begin
            lap = ~lap;
            lap_sec = sec;
            lap_csec = csec;
        end
        else if(btn_clear)begin
            lap = 0;
            lap_sec = 0;
            lap_csec = 0;
        end
    end
    
    reg [26:0] cnt_sysclk;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            sec = 0;
            csec = 0;
            cnt_sysclk = 0;
        end
        else begin
            if(start_stop)begin
                if(cnt_sysclk >= 999_999)begin
                    cnt_sysclk = 0;
                    if(csec >= 99)begin
                        csec = 0;
                        if(sec >= 99)sec = 0;
                        else sec = sec + 1;
                    end
                    else csec = csec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
            if(btn_clear)begin
                sec = 0;
                csec = 0;
                cnt_sysclk = 0;
            end
        end
    end
    
    wire [7:0] fnd_sec, fnd_csec;
    assign fnd_sec = lap ? lap_sec : sec;
    assign fnd_csec = lap ? lap_csec : csec;
    
    bin_to_dec bcd_sec(.bin(fnd_sec), .bcd(sec_bcd));
    bin_to_dec bcd_csec(.bin(fnd_csec), .bcd(csec_bcd));
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value({sec_bcd, csec_bcd}), .hex_bcd(1),
        .seg_7(seg_7), .com(com));


endmodule

























