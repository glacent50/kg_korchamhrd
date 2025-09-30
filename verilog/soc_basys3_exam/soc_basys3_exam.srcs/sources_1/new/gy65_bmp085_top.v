`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2025 03:42:39 PM
// Design Name: 
// Module Name: gy65_bmp085_top
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


module gy65_bmp085_top(
    // Basys3 기본 신호
    input wire clk,                // 100MHz 시스템 클록 (W5)
    input wire reset_p,            // 리셋 (활성 High)
    
    // I2C 연결 (PMOD JA)
    inout wire sda,               // JA1 (J1)
    output wire scl,              // JA2 (L2)
    
    // Basys3 출력 장치
    output [7:0] seg_7,           // 7세그먼트 세그먼트 {dp, CG, CF, CE, CD, CC, CB, CA}
    output [3:0] com,             // 7세그먼트 자릿수 선택 (com[3:0] = AN[3:0])
    output [15:0] led_0           // 16개 LED
);

    // 내부 리셋 신호 (활성 Low로 변환)
    wire rst_n;
    assign rst_n = ~reset_p;
    
    // GY-65 센서 인터페이스 신호
    reg start_measure;
    wire [15:0] temperature;
    wire [19:0] pressure;
    wire data_ready;
    wire sensor_busy;
    wire sensor_error;
    
    // 7세그먼트 디스플레이용 신호
    reg [15:0] display_value;
//    wire [6:0] seg_out;
//    wire dp_out;
//    wire [3:0] com_out;
    
    // 상태 및 제어 신호
    reg [1:0] display_mode;        // 0: 온도, 1: 기압
    reg [15:0] temp_display;
    reg [15:0] press_display;
    
    // 자동 측정 타이머 (3초마다 측정)
    reg [25:0] auto_measure_counter;
    reg auto_measure_trigger;
    reg system_initialized;
    
    // 초기화 지연 타이머 (전원 후 1초 대기)
    reg [25:0] init_delay_counter;
    reg init_complete;
    
    // LED 상태 표시
    reg [15:0] led_status;
    
    // GY-65 BMP085 컨트롤러 인스턴스
    gy65_bmp085_controller gy65_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_measure(start_measure),
        .temperature(temperature),
        .pressure(pressure),
        .data_ready(data_ready),
        .busy(sensor_busy),
        .sensor_error(sensor_error),
        .sda(sda),
        .scl(scl)
    );
        
//    // 7세그먼트 디스플레이 컨트롤러
//    seven_segment_controller seg_ctrl (
//        .clk(clk),
//        .rst_n(rst_n),
//        .display_data(display_value),
//        .dp_enable(4'b0010),     // 소수점 위치 (온도는 두 번째 자리)
//        .seg(seg_out),
//        .dp(dp_out),
//        .com(com_out)
//    );
    
    wire [13:0] temperature_bcd;
    bin_to_dec bcd_humi(.bin(temperature), .bcd(temperature_bcd));   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value(temperature_bcd),
        .hex_bcd(1),
        .seg_7(seg_7), .com(com));
    
    
    
    
    // 출력 할당
    assign led_0 = led_status;
    
    //assign seg_7 = {dp_out, seg_out};  // {DP, CG, CF, CE, CD, CC, CB, CA}
    //assign com = com_out;
    
    // 메인 제어 로직
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_mode <= 2'b00;
            start_measure <= 0;
            auto_measure_counter <= 0;
            auto_measure_trigger <= 0;
            init_delay_counter <= 0;
            init_complete <= 0;
            system_initialized <= 0;
            temp_display <= 0;
            press_display <= 0;
            led_status <= 16'hAAAA;  // 초기화 패턴
            display_value <= 16'h0000;
        end else begin
            // 초기화 지연 (1초)
            if (!init_complete) begin
                init_delay_counter <= init_delay_counter + 1;
                if (init_delay_counter >= 26'd100_000_000) begin  // 1초 = 100M 클록
                    init_complete <= 1;
                    init_delay_counter <= 0;
                end
            end else begin
                // 시스템 초기화 완료 후 자동 측정 시작
                if (!system_initialized) begin
                    system_initialized <= 1;
                    auto_measure_trigger <= 1;
                    auto_measure_counter <= 0;
                end else begin
                    // 자동 측정 타이머 (3초마다)
                    auto_measure_counter <= auto_measure_counter + 1;
                    if (auto_measure_counter >= 26'd300_000_000) begin  // 3초 = 300M 클록
                        auto_measure_counter <= 0;
                        auto_measure_trigger <= 1;
                    end else begin
                        auto_measure_trigger <= 0;
                    end
                end
                
                // 측정 시작 제어
                start_measure <= 0;
                if (auto_measure_trigger && !sensor_busy) begin
                    start_measure <= 1;
                end
                
                // 데이터 저장 및 디스플레이 모드 자동 전환
                if (data_ready) begin
                    temp_display <= temperature;
                    press_display <= pressure[19:4];  // 기압 상위 16비트만 사용
                    
                    // 온도와 기압을 번갈아 표시 (6초 주기)
                    display_mode <= display_mode + 1;
                end
                
                // 디스플레이 모드별 값 설정
                case (display_mode)
                    2'b00, 2'b10: display_value <= temp_display;       // 온도 표시
                    2'b01, 2'b11: display_value <= press_display;      // 기압 표시
                    default: display_value <= temp_display;
                endcase
                
                // LED 상태 표시
                led_status[15:14] <= display_mode;           // 디스플레이 모드
                led_status[13] <= system_initialized;        // 시스템 초기화 완료
                led_status[12] <= sensor_busy;               // 센서 비지
                led_status[11] <= data_ready;                // 데이터 준비
                led_status[10] <= sensor_error;              // 센서 에러
                led_status[9] <= init_complete;              // 초기화 완료
                led_status[8:0] <= temperature[8:0];         // 온도 하위 비트
            end
        end
    end

endmodule

module gy65_bmp085_controller (
    input wire clk,
    input wire rst_n,
    input wire start_measure,
    output reg [15:0] temperature,
    output reg [19:0] pressure,
    output reg data_ready,
    output reg busy,
    output reg sensor_error,
    inout wire sda,
    output wire scl
);

    // BMP085 I2C 주소 및 명령어
    localparam BMP085_ADDR = 7'h77;
    localparam TEMP_CMD = 8'h2E;
    localparam PRESS_CMD = 8'h34;  // OSS=0
    localparam CTRL_REG = 8'hF4;
    localparam DATA_REG = 8'hF6;
    
    // 컨트롤러 상태 정의
    localparam CS_IDLE      = 3'b000;
    localparam CS_TEMP_CMD  = 3'b001;
    localparam CS_TEMP_WAIT = 3'b010;
    localparam CS_TEMP_READ = 3'b011;
    localparam CS_PRES_CMD  = 3'b100;
    localparam CS_PRES_WAIT = 3'b101;
    localparam CS_PRES_READ = 3'b110;
    localparam CS_DONE      = 3'b111;

    reg [2:0] ctrl_state;
    
    // I2C 마스터 인터페이스
    reg i2c_start;
    reg [6:0] i2c_device_addr;
    reg i2c_read_write;
    reg [7:0] i2c_reg_addr;
    reg [7:0] i2c_write_data;
    wire [7:0] i2c_read_data;
    wire i2c_busy;
    wire i2c_complete;
    wire i2c_error;
    
    // 타이머
    reg [15:0] delay_counter;
    
    // I2C 마스터 인스턴스
    i2c_master i2c_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(i2c_start),
        .device_addr(i2c_device_addr),
        .read_write(i2c_read_write),
        .reg_addr(i2c_reg_addr),
        .write_data(i2c_write_data),
        .read_data(i2c_read_data),
        .busy(i2c_busy),
        .complete(i2c_complete),
        .error(i2c_error),
        .sda(sda),
        .scl(scl)
    );
    
    // 측정 데이터
    reg [15:0] temp_raw;
    reg [15:0] press_raw_msb;
    reg [7:0] press_raw_lsb;
    
    // 메인 제어 상태머신
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_state <= CS_IDLE;
            busy <= 0;
            data_ready <= 0;
            sensor_error <= 0;
            i2c_start <= 0;
            delay_counter <= 0;
            temperature <= 0;
            pressure <= 0;
        end else begin
            case (ctrl_state)
                CS_IDLE: begin
                    busy <= 0;
                    data_ready <= 0;
                    sensor_error <= 0;
                    if (start_measure) begin
                        busy <= 1;
                        ctrl_state <= CS_TEMP_CMD;
                        i2c_device_addr <= BMP085_ADDR;
                        i2c_reg_addr <= CTRL_REG;
                        i2c_write_data <= TEMP_CMD;
                        i2c_read_write <= 0;  // Write
                        i2c_start <= 1;
                    end
                end
                
                CS_TEMP_CMD: begin
                    if (i2c_complete) begin
                        i2c_start <= 0;
                        delay_counter <= 16'd5000;  // 5ms delay
                        ctrl_state <= CS_TEMP_WAIT;
                    end else if (i2c_error) begin
                        ctrl_state <= CS_IDLE;
                        sensor_error <= 1;
                        busy <= 0;
                    end
                end
                
                CS_TEMP_WAIT: begin
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        ctrl_state <= CS_TEMP_READ;
                        i2c_reg_addr <= DATA_REG;
                        i2c_read_write <= 1;  // Read
                        i2c_start <= 1;
                    end
                end
                
                CS_TEMP_READ: begin
                    if (i2c_complete) begin
                        temp_raw[15:8] <= i2c_read_data;
                        i2c_start <= 0;
                        // Read LSB
                        i2c_reg_addr <= DATA_REG + 1;
                        i2c_start <= 1;
                        ctrl_state <= CS_PRES_CMD;
                    end else if (i2c_error) begin
                        ctrl_state <= CS_IDLE;
                        sensor_error <= 1;
                        busy <= 0;
                    end
                end
                
                CS_PRES_CMD: begin
                    if (i2c_complete) begin
                        temp_raw[7:0] <= i2c_read_data;
                        i2c_start <= 0;
                        // Start pressure measurement
                        i2c_reg_addr <= CTRL_REG;
                        i2c_write_data <= PRESS_CMD;
                        i2c_read_write <= 0;
                        i2c_start <= 1;
                        ctrl_state <= CS_PRES_WAIT;
                    end
                end
                
                CS_PRES_WAIT: begin
                    if (i2c_complete) begin
                        i2c_start <= 0;
                        delay_counter <= 16'd5000;  // 5ms delay
                        ctrl_state <= CS_PRES_READ;
                    end else if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        i2c_reg_addr <= DATA_REG;
                        i2c_read_write <= 1;
                        i2c_start <= 1;
                        ctrl_state <= CS_DONE;
                    end
                end
                
                CS_PRES_READ: begin
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else begin
                        i2c_reg_addr <= DATA_REG;
                        i2c_read_write <= 1;
                        i2c_start <= 1;
                        ctrl_state <= CS_DONE;
                    end
                end
                
                CS_DONE: begin
                    if (i2c_complete) begin
                        press_raw_msb <= {i2c_read_data, 8'h00};
                        // 간소화된 계산 (실제로는 BMP085 보정 공식 필요)
                        temperature <= temp_raw;
                        pressure <= {press_raw_msb[15:8], 12'h000};
                        data_ready <= 1;
                        busy <= 0;
                        ctrl_state <= CS_IDLE;
                    end else if (i2c_error) begin
                        ctrl_state <= CS_IDLE;
                        sensor_error <= 1;
                        busy <= 0;
                    end
                end
                
                default: ctrl_state <= CS_IDLE;
            endcase
        end
    end

endmodule





module i2c_master #(
    parameter CLOCK_FREQ = 100_000_000,  // 100MHz 시스템 클록
    parameter I2C_FREQ = 100_000          // 100kHz I2C 클록
)(
    input wire clk,
    input wire rst_n,
    
    // 제어 인터페이스
    input wire start,
    input wire [6:0] device_addr,
    input wire read_write,    // 0: write, 1: read
    input wire [7:0] reg_addr,
    input wire [7:0] write_data,
    output reg [7:0] read_data,
    output reg busy,
    output reg complete,
    output reg error,
    
    // I2C 버스
    inout wire sda,
    output reg scl
);

    // 클록 분주 계산
    localparam CLK_DIVIDER = CLOCK_FREQ / (I2C_FREQ * 4);
    
    // 상태 정의 (localparam 사용)
    localparam S_IDLE           = 4'b0000;
    localparam S_START          = 4'b0001;
    localparam S_SEND_ADDR_WR   = 4'b0010;
    localparam S_WAIT_ACK1      = 4'b0011;
    localparam S_SEND_REG_ADDR  = 4'b0100;
    localparam S_WAIT_ACK2      = 4'b0101;
    localparam S_RESTART        = 4'b0110;
    localparam S_SEND_ADDR_RD   = 4'b0111;
    localparam S_WAIT_ACK3      = 4'b1000;
    localparam S_READ_DATA      = 4'b1001;
    localparam S_SEND_NACK      = 4'b1010;
    localparam S_SEND_DATA      = 4'b1011;
    localparam S_WAIT_ACK4      = 4'b1100;
    localparam S_STOP           = 4'b1101;
    localparam S_ERROR          = 4'b1110;

    reg [3:0] state, next_state;
    
    // 클록 분주기
    reg [15:0] clk_div_counter;
    reg [1:0] clk_phase;  // 0,1,2,3 for quarter periods
    
    // 비트 카운터 및 데이터 시프트
    reg [3:0] bit_counter;
    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;
    
    // SDA 제어
    reg sda_out;
    reg sda_oe;
    
    assign sda = sda_oe ? sda_out : 1'bz;
    wire sda_in = sda;
    
    // 레지스터 저장
    reg [6:0] stored_device_addr;
    reg [7:0] stored_reg_addr;
    reg [7:0] stored_write_data;
    reg stored_read_write;
    
    // 클록 분주 및 4상 클록 생성
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_counter <= 0;
            clk_phase <= 0;
        end else if (state != S_IDLE) begin
            if (clk_div_counter == CLK_DIVIDER - 1) begin
                clk_div_counter <= 0;
                clk_phase <= clk_phase + 1;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end else begin
            clk_div_counter <= 0;
            clk_phase <= 0;
        end
    end
    
    // SCL 생성
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl <= 1;
        end else begin
            case (state)
                S_IDLE, S_START, S_RESTART, S_STOP: scl <= 1;
                default: begin
                    case (clk_phase)
                        2'd0, 2'd1: scl <= 0;  // SCL Low
                        2'd2, 2'd3: scl <= 1;  // SCL High
                    endcase
                end
            endcase
        end
    end
    
    // 상태 전이
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 주상태 머신
    always @(*) begin
        next_state = state;
        
        case (state)
            S_IDLE: begin
                if (start && !busy) begin
                    next_state = S_START;
                end
            end
            
            S_START: begin
                if (clk_phase == 2'd3) begin
                    next_state = S_SEND_ADDR_WR;
                end
            end
            
            S_SEND_ADDR_WR: begin
                if (bit_counter == 0 && clk_phase == 2'd3) begin
                    next_state = S_WAIT_ACK1;
                end
            end
            
            S_WAIT_ACK1: begin
                if (clk_phase == 2'd3) begin
                    if (sda_in == 0) begin
                        if (stored_read_write) begin
                            next_state = S_SEND_REG_ADDR;
                        end else begin
                            next_state = S_SEND_DATA;
                        end
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end
            
            S_SEND_REG_ADDR: begin
                if (bit_counter == 0 && clk_phase == 2'd3) begin
                    next_state = S_WAIT_ACK2;
                end
            end
            
            S_WAIT_ACK2: begin
                if (clk_phase == 2'd3) begin
                    if (sda_in == 0) begin
                        if (stored_read_write) begin
                            next_state = S_RESTART;
                        end else begin
                            next_state = S_SEND_DATA;
                        end
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end
            
            S_RESTART: begin
                if (clk_phase == 2'd3) begin
                    next_state = S_SEND_ADDR_RD;
                end
            end
            
            S_SEND_ADDR_RD: begin
                if (bit_counter == 0 && clk_phase == 2'd3) begin
                    next_state = S_WAIT_ACK3;
                end
            end
            
            S_WAIT_ACK3: begin
                if (clk_phase == 2'd3) begin
                    if (sda_in == 0) begin
                        next_state = S_READ_DATA;
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end
            
            S_READ_DATA: begin
                if (bit_counter == 0 && clk_phase == 2'd3) begin
                    next_state = S_SEND_NACK;
                end
            end
            
            S_SEND_NACK: begin
                if (clk_phase == 2'd3) begin
                    next_state = S_STOP;
                end
            end
            
            S_SEND_DATA: begin
                if (bit_counter == 0 && clk_phase == 2'd3) begin
                    next_state = S_WAIT_ACK4;
                end
            end
            
            S_WAIT_ACK4: begin
                if (clk_phase == 2'd3) begin
                    if (sda_in == 0) begin
                        next_state = S_STOP;
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end
            
            S_STOP: begin
                if (clk_phase == 2'd3) begin
                    next_state = S_IDLE;
                end
            end
            
            S_ERROR: begin
                next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end
    
    // 출력 제어 로직
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 0;
            complete <= 0;
            error <= 0;
            sda_out <= 1;
            sda_oe <= 0;
            bit_counter <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            read_data <= 0;
        end else begin
            complete <= 0;
            error <= 0;
            
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    sda_oe <= 0;
                    sda_out <= 1;
                    if (start && !busy) begin
                        busy <= 1;
                        stored_device_addr <= device_addr;
                        stored_reg_addr <= reg_addr;
                        stored_write_data <= write_data;
                        stored_read_write <= read_write;
                    end
                end
                
                S_START: begin
                    busy <= 1;
                    if (clk_phase == 2'd0) begin
                        sda_oe <= 1;
                        sda_out <= 0;  // Start condition
                        tx_shift_reg <= {stored_device_addr, 1'b0}; // Write address
                        bit_counter <= 7;
                    end
                end
                
                S_SEND_ADDR_WR: begin
                    sda_oe <= 1;
                    if (clk_phase == 2'd1) begin
                        sda_out <= tx_shift_reg[bit_counter];
                    end else if (clk_phase == 2'd3) begin
                        if (bit_counter > 0) begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                end
                
                S_WAIT_ACK1: begin
                    if (clk_phase == 2'd1) begin
                        sda_oe <= 0;  // Release SDA for ACK
                    end
                end
                
                S_SEND_REG_ADDR: begin
                    sda_oe <= 1;
                    if (clk_phase == 2'd0 && bit_counter == 7) begin
                        tx_shift_reg <= stored_reg_addr;
                    end else if (clk_phase == 2'd1) begin
                        sda_out <= tx_shift_reg[bit_counter];
                    end else if (clk_phase == 2'd3) begin
                        if (bit_counter > 0) begin
                            bit_counter <= bit_counter - 1;
                        end else begin
                            bit_counter <= 7;
                        end
                    end
                end
                
                S_WAIT_ACK2: begin
                    if (clk_phase == 2'd1) begin
                        sda_oe <= 0;
                    end
                end
                
                S_RESTART: begin
                    if (clk_phase == 2'd0) begin
                        sda_oe <= 1;
                        sda_out <= 1;
                    end else if (clk_phase == 2'd1) begin
                        sda_out <= 0;  // Restart condition
                        tx_shift_reg <= {stored_device_addr, 1'b1}; // Read address
                        bit_counter <= 7;
                    end
                end
                
                S_SEND_ADDR_RD: begin
                    sda_oe <= 1;
                    if (clk_phase == 2'd1) begin
                        sda_out <= tx_shift_reg[bit_counter];
                    end else if (clk_phase == 2'd3) begin
                        if (bit_counter > 0) begin
                            bit_counter <= bit_counter - 1;
                        end else begin
                            bit_counter <= 7;
                        end
                    end
                end
                
                S_WAIT_ACK3: begin
                    if (clk_phase == 2'd1) begin
                        sda_oe <= 0;
                    end
                end
                
                S_READ_DATA: begin
                    sda_oe <= 0;
                    if (clk_phase == 2'd2) begin
                        rx_shift_reg[bit_counter] <= sda_in;
                    end else if (clk_phase == 2'd3) begin
                        if (bit_counter > 0) begin
                            bit_counter <= bit_counter - 1;
                        end else begin
                            read_data <= rx_shift_reg;
                        end
                    end
                end
                
                S_SEND_NACK: begin
                    sda_oe <= 1;
                    sda_out <= 1;  // NACK
                end
                
                S_SEND_DATA: begin
                    sda_oe <= 1;
                    if (clk_phase == 2'd0 && bit_counter == 7) begin
                        tx_shift_reg <= stored_write_data;
                    end else if (clk_phase == 2'd1) begin
                        sda_out <= tx_shift_reg[bit_counter];
                    end else if (clk_phase == 2'd3) begin
                        if (bit_counter > 0) begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                end
                
                S_WAIT_ACK4: begin
                    if (clk_phase == 2'd1) begin
                        sda_oe <= 0;
                    end
                end
                
                S_STOP: begin
                    sda_oe <= 1;
                    if (clk_phase == 2'd0) begin
                        sda_out <= 0;
                    end else if (clk_phase == 2'd1) begin
                        sda_out <= 1;  // Stop condition
                    end else if (clk_phase == 2'd3) begin
                        complete <= 1;
                    end
                end
                
                S_ERROR: begin
                    error <= 1;
                    sda_oe <= 0;
                end
                
            endcase
        end
    end

endmodule






