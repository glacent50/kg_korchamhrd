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
    output [3:0] com
);

    wire [15:0] bcd_value;
    bin_to_dec bcd(.bin(fnd_value[11:0]), .bcd(bcd_value));

    reg [16:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;

    anode_selector ring_com(
        .scan_count(clk_div[16:15]), 
        .an_out(com)
    );

    reg [3:0] digit_value; 
    wire [15:0] out_value;
    assign out_value = hex_bcd ? fnd_value : bcd_value;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            digit_value = 0;
        end else begin
            case (com)
                4'b1110: digit_value = out_value[3:0];
                4'b1101: digit_value = out_value[7:4];
                4'b1011: digit_value = out_value[11:8];
                4'b0111: digit_value = out_value[15:12];
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
        if (btn_sync_1 == btn_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if (stable)
                btn_out <= btn_sync_1;
        end
    end

endmodule

module btn_cntr(
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_nedge
);

    wire debounced_btn;
    debounce btn_0(.clk(clk), .btn_in(btn), .btn_out(debounced_btn));

    edge_detector_p btn_ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(debounced_btn),
        .p_edge(btn_pedge), 
        .n_edge(btn_nedge)
    );

endmodule

module dht11_cntr (
    input clk, reset_p,
    inout dht11_data,                           // Input + Output, reg Declaration Not Possible
    output reg [7:0] humidity, temperature,     // Output Measurement
    output [15:0] led                           // for Debugging
);

    // Change Status Using Shift
    localparam S_IDLE       = 6'b00_0001;       // Standby Status
    localparam S_LOW_18MS   = 6'b00_0010;       // MCU Sends Out Start Signal
    localparam S_HIGH_20US  = 6'b00_0100;       // MCU Pull Up & Wait for Sensor Response
    localparam S_LOW_80US   = 6'b00_1000;       // DHT Sends Out Response Signal
    localparam S_HIGH_80US  = 6'b01_0000;       // DHT Pull Up & Get Ready Data
    localparam S_READ_DATA  = 6'b10_0000;       // DHT Data Read

    localparam S_WAIT_PEDGE = 2'b01;            // Start to Transmit 1-bit Data
    localparam S_WAIT_NEDGE = 2'b10;            // Voltage Length Measurement


    // Clock Divide 100, 10ns x 100 = 1us
    wire clk_usec_nedge;                        // Divide Clock 1us
    clock_div_100 us_clk (.clk(clk), .reset_p(reset_p), .nedge_div_100(clk_usec_nedge));

    // us Unit Count
    reg [21:0] cnt_usec;                        // us Count
    reg cnt_usec_e;                             // us Count Enable
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) cnt_usec = 0;              // Count Clear
        else if (clk_usec_nedge && cnt_usec_e) begin    // Count Start when Enable & us Negative Edge
            cnt_usec = cnt_usec + 1;            // Count During Enable
        end else if (!cnt_usec_e) cnt_usec = 0; // Count Clear when Disable
    end

    // Edge Detection of DHT Signal
    wire dht_nedge, dht_pedge;
    edge_detector_p btn_ed (
        .clk(clk), 
        .reset_p(reset_p),
        .cp(dht11_data), 
        .p_edge(dht_pedge), 
        .n_edge(dht_nedge)
    );

    // Input Cannot be Declared as reg, Use Buffer
    reg dht11_buffer;                           // Buffer
    reg dht11_data_out_e;                       // Write Mode Enable Output, Disable Input
    assign dht11_data = dht11_data_out_e ? dht11_buffer : 'bz; // Output dout, Input Impedance Value

    reg [5:0] state, next_state;                // Current & Next Status
    reg [1:0] read_state;                       // Data Read Status
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = S_IDLE;            // Basic Standby Status
        else state = next_state;                // Change Status in Negative Edge
    end

    reg [39:0] temp_data;                       // DHT Output Data 40-bit
    reg [5:0] data_cnt;                         // Counting to 40
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            next_state = S_IDLE;                // Basic Stanby Status
            temp_data = 0;                      // DHT Data Reset
            data_cnt = 0;                       // DHT Data Count Reset
            dht11_data_out_e = 0;               // DHT Write Disable, Input
            read_state = S_WAIT_PEDGE;          // Data Read Pull-Up High
        end else begin
            case (state)
                S_IDLE: begin                   // Standby Status
                    if (cnt_usec < 22'd3_000_000) begin     // Real 3_000_000, Test 3_000
                        cnt_usec_e = 1;         // Count Enable
                        dht11_data_out_e = 0;   // DHT Input Mode
                    end else begin
                        cnt_usec_e = 0;         // Count Clear
                        next_state = S_LOW_18MS;// Change Status
                    end
                end
                S_LOW_18MS: begin               // MCU Sends Out Start Signal
                    if (cnt_usec < 22'd18_000) begin        // Real 18_000, Test 18
                        cnt_usec_e = 1;         // us Count Enable
                        dht11_data_out_e = 1;
                        dht11_buffer = 0;
                    end else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_HIGH_20US;   // Change Status
                        dht11_data_out_e = 0;   // Impedance
                    end
                end
                S_HIGH_20US: begin              // MCU Pull Up & Wait for Sensor Response
                    cnt_usec_e = 1;
                    if (cnt_usec > 22'd100_000) begin
                        cnt_usec_e = 0;
                        next_state = S_IDLE;
                    end

                    if (dht_nedge) begin
                        next_state = S_LOW_80US;    // Change Status
                        cnt_usec_e = 0;     // us Count Disable, Clear
                    end
                end
                S_LOW_80US: begin               // DHT Sends Out Response Signal
                    cnt_usec_e = 1;
                    if (cnt_usec > 22'd100_000) begin
                        cnt_usec_e = 0;
                        next_state = S_IDLE;
                    end
                    
                    if (dht_pedge) begin 
                        next_state = S_HIGH_80US;    // No Need to Count, Change Status
                        cnt_usec_e = 0;
                    end
                end
                S_HIGH_80US: begin              // DHT Pull Up & Get Ready Data
                    cnt_usec_e = 1;
                    if (cnt_usec > 22'd100_000) begin
                        cnt_usec_e = 0;
                        next_state = S_IDLE;
                    end                    
                    
                    if (dht_nedge) begin 
                        next_state = S_READ_DATA;    // No Need to Count, Change Status
                        cnt_usec_e = 0;
                    end
                end
                S_READ_DATA: begin              // DHT Data Read
                    case (read_state)
                        S_WAIT_PEDGE: begin
                            if (dht_pedge) read_state = S_WAIT_NEDGE;
                            cnt_usec_e = 0;     // us Count Disable, Clear
                        end
                        S_WAIT_NEDGE: begin
                            if (dht_nedge) begin
                                read_state = S_WAIT_PEDGE;
                                data_cnt = data_cnt + 1;
                                if (cnt_usec < 50) begin
                                    temp_data = {temp_data[38:0], 1'b0};
                                end
                                else begin
                                    cnt_usec_e = 1; // us Count Enable
                                    if (cnt_usec > 22'd100_000) begin
                                        cnt_usec_e = 0;
                                        next_state = S_IDLE;
                                        data_cnt = 0;
                                        read_state = S_WAIT_PEDGE;
                                    end 
                                end
                            end
                        end
                    endcase
                    if (data_cnt >= 40) begin   // 40-bit Read Completed
                        next_state = S_IDLE;    // Basic Stanby Status
                        data_cnt = 0;           // DHT Data Count Reset
                        // Checksum Validation
                        if (temp_data[7:0] == (temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8])) begin
                            humidity = temp_data[39:32];
                            temperature = temp_data[23:16];
                        end 
                    end
                end
                default: next_state = S_IDLE;
            endcase
        end
    end
endmodule


module keypad_cntr(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] column,
    output reg [3:0] key_value,
    output reg key_valid);

    localparam [4:0] SCAN_0 = 5'b00001;
    localparam [4:0] SCAN_1 = 5'b00010;
    localparam [4:0] SCAN_2 = 5'b00100;
    localparam [4:0] SCAN_3 = 5'b01000;
    localparam [4:0] KEY_PROCESS = 5'b10000;

    reg [19:0] clk_10ms;
    always @(posedge clk) clk_10ms = clk_10ms + 1; 

    wire clk_10ms_nedge, clk_10ms_pedge;
    edge_detector_p btn_ed (
        .clk(clk), 
        .reset_p(reset_p),
        .cp(clk_10ms[19]), 
        .p_edge(clk_10ms_pedge), 
        .n_edge(clk_10ms_nedge)
    );


    // 상태 레지스터와 상태 전환 로직 (키패드 스캐닝용)
    reg [4:0] state, next_state;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) state = SCAN_0;
        else if (clk_10ms_pedge) state = next_state;
    end

    // 조합 논리: next_state, column, key_value, key_valid 결정
    always @* begin
        case (state)
            SCAN_0: begin
                if (row ==0) next_state = SCAN_1;
                else next_state = KEY_PROCESS;
            end
            SCAN_1: begin
                if (row ==0) next_state = SCAN_2;
                else next_state = KEY_PROCESS;
            end
            SCAN_2: begin
                if (row ==0) next_state = SCAN_3;
                else next_state = KEY_PROCESS;
            end
            SCAN_3: begin
                if (row ==0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
            KEY_PROCESS: begin
                if (row ==0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
            default: next_state = SCAN_1;
        endcase
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            column = 4'b0001;
            key_value = 0;
            key_valid = 0; 
        end
        else if (clk_10ms_nedge) begin //채터링 방지
            case (state)
                SCAN_0: begin
                    column = 4'b0001;
                    key_valid = 0;
                end
                SCAN_1: begin
                    column = 4'b0010;
                    key_valid = 0;
                end
                SCAN_2: begin
                    column = 4'b0100;
                    key_valid = 0;
                end
                SCAN_3: begin
                    column = 4'b1000;
                    key_valid = 0;
                end
                KEY_PROCESS: begin
                    key_valid = 1;
                    case ({column, row})
                        8'b0001_0001: key_value = 4'h0;
                        8'b0001_0010: key_value = 4'h1;
                        8'b0001_0100: key_value = 4'h2;
                        8'b0001_1000: key_value = 4'h3;
                        8'b0010_0001: key_value = 4'h4;
                        8'b0010_0010: key_value = 4'h5;
                        8'b0010_0100: key_value = 4'h6;
                        8'b0010_1000: key_value = 4'h7;
                        8'b0100_0001: key_value = 4'h8;
                        8'b0100_0010: key_value = 4'h9;
                        8'b0100_0100: key_value = 4'hA;
                        8'b0100_1000: key_value = 4'hB;
                        8'b1000_0001: key_value = 4'hC;
                        8'b1000_0010: key_value = 4'hD;
                        8'b1000_0100: key_value = 4'hE;
                        8'b1000_1000: key_value = 4'hF;
                        //default: key_value = 4'h0;
                    endcase
                end
            endcase
        end
    end

endmodule


module I2C_master(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] data,
    input rd_wr, comm_start,
    output reg scl, sda,
    output [15:0] led);

    localparam IDLE         = 7'b000_0001;
    localparam COMM_START   = 7'b000_0010;
    localparam SEND_ADDR    = 7'b000_0100;
    localparam RD_ACK       = 7'b000_1000;
    localparam SEND_DATA    = 7'b001_0000;
    localparam SCL_STOP     = 7'b010_0000;
    localparam COMM_STOP    = 7'b100_0000;
    
    wire clk_usec_nedge;
    clock_div_100 us_clk(.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge));
    
    wire comm_start_pedge;
    edge_detector_p comm_start_ed(
        .clk(clk), .reset_p(reset_p), .cp(comm_start),
        .p_edge(comm_start_pedge));
        
    wire scl_nedge, scl_pedge;
    edge_detector_p scl_ed(
        .clk(clk), .reset_p(reset_p), .cp(scl),
        .p_edge(scl_pedge), .n_edge(scl_nedge));
        
    reg [2:0] count_usec5;
    reg scl_e;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            count_usec5 = 0;
            scl = 0;
        end
        else if(scl_e)begin
            if(clk_usec_nedge)begin
                if(count_usec5 >= 4)begin
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end
        end
        else if(!scl_e)begin
            count_usec5 = 0;
            scl = 1;
        end
    end
    
    reg [6:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    wire [7:0] addr_rd_wr;
    assign addr_rd_wr = {addr, rd_wr};
    reg [2:0] cnt_bit;
    reg stop_flag;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            scl_e = 0;
            sda = 1;
            cnt_bit = 7;
            stop_flag = 0;
        end
        else begin
            case(state)
                IDLE        : begin
                    scl_e = 0;
                    sda = 1;
                    if(comm_start_pedge)next_state = COMM_START;
                end
                COMM_START  : begin
                    sda = 0;
                    scl_e = 1;
                    next_state = SEND_ADDR;
                end
                SEND_ADDR   : begin
                    if(scl_nedge)sda = addr_rd_wr[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                RD_ACK      : begin
                    if(scl_nedge)sda = 'bz;
                    else if(scl_pedge)begin
                        if(stop_flag)begin
                            stop_flag = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            stop_flag = 1;
                            next_state = SEND_DATA;
                        end
                    end
                end 
                SEND_DATA   : begin
                    if(scl_nedge)sda = data[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                SCL_STOP    : begin
                    if(scl_nedge)sda = 0;
                    if(scl_pedge)next_state = COMM_STOP;
                end
                COMM_STOP   : begin
                    if(count_usec5 >= 3)begin
                        scl_e = 0;
                        sda = 1;
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end
endmodule


module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr, 
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy,
    output [15:0] led);

    localparam IDLE                     = 6'b00_0001;
    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
    localparam SEND_DISABLE             = 6'b10_0000;
    
    wire clk_usec_nedge;
    clock_div_100 us_clk(.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge));
    
    reg [7:0] data;
    reg comm_start;
    
    wire send_pedge;
    edge_detector_p send_ed(
        .clk(clk), .reset_p(reset_p), .cp(send),
        .p_edge(send_pedge));
        
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end    
    
    I2C_master master(clk, reset_p, addr, data, 1'b0, comm_start, scl, sda);
    
    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)begin
            state = IDLE;
        end
        else begin
            state = next_state;
        end
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            comm_start = 0;
            count_usec_e = 0;
            data = 0;
            busy = 0;
        end
        else begin
            case(state)
                IDLE                    :begin
                    if(send_pedge)begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                        busy = 1;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE  :begin
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[3:0], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                        comm_start = 0;
                    end
                end
                SEND_DISABLE            :begin 
                    if(count_usec <= 22'd200)begin
                                //d7 d6 d5 d4       BL en rw rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1; 
                    end
                    else begin
                        next_state = IDLE;
                        count_usec_e = 0;
                        comm_start = 0;
                        busy = 0;
                    end
                end
            endcase
        end
    end
endmodule


module pwm_Nfreq_Nstep (
    input clk, reset_p,
    input [6:0] duty,
    output reg pwm);

    parameter sys_clk_freq = 100_000_000;
    parameter pwm_freq = 10_000;
    parameter duty_step_N = 128;
    parameter temp = sys_clk_freq / pwm_freq / duty_step_N / 2;

    integer cnt;
    reg pwm_freqXN;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt = 0;
            pwm_freqXN = 0;
        end
        else begin
            if (cnt >= temp - 1) begin
                cnt = 0;
                pwm_freqXN = ~pwm_freqXN;
            end
            else cnt = cnt + 1;
        end
    end
    
    wire pwm_freqXN_nedge;
    edge_detector_p pwm_freqX128_ed (
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqXN),
        .n_edge(pwm_freqXN_nedge)
    );

    reg [6:0] cnt_duty;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_duty = 0;
            pwm = 0;
        end
        else if (pwm_freqXN_nedge) begin
            cnt_duty = cnt_duty + 1;
            if (cnt_duty < duty) pwm = 1;
            else pwm = 0;
        end
    end

endmodule
















