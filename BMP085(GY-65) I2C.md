# BMP085(GY-65) I2C 센서 Top 모듈 및 전체 구성 (Basys3)

본 문서는 Basys3 보드(Artix-7)에서 GY-65(BMP085/BMP180 호환) 센서를 I2C로 제어하기 위한 전체 Verilog 코드와 Top 모듈, 제약(XDC), 그리고 동작 이슈 점검/수정 포인트를 포함합니다. 이전 코드베이스(gy65_final_verilog.md)와 질의 내용을 반영하여 안정성 향상과 합성 호환성을 고려한 버전입니다.

- I2C 속도: 100 kHz (기본)
- 시스템 클럭: 100 MHz (Basys3)
- 오픈드레인 방식: inout + 내부 PULLUP 사용
- Clock-stretching: 미지원(일반 BMP085/180에서 문제 없음)

---

## 1) I2C 마스터 (i2c_master_combined)

- 기능: 레지스터형 센서에 최적화된 결합 트랜잭션 수행
  Start → [Addr+W] → RegAddr → [옵션: write bytes] → [옵션: RepeatedStart → Addr+R → read bytes] → Stop
- Verilog-2001 문법으로 작성(typedef 등 SystemVerilog 의존 제거)

```verilog
// I2C combined transaction master for register-based sensors.
// Start -> [Addr+W] -> RegAddr -> [opt: W bytes] -> [opt: RepStart -> Addr+R -> R bytes] -> Stop
// Open-drain SCL/SDA (drive-low or release-high). No clock-stretching.
module i2c_master_combined #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000
)(
    input  wire        clk,
    input  wire        rst_n,

    // Transaction descriptor
    input  wire        start,       // pulse to start transaction
    input  wire [6:0]  dev_addr,    // 7-bit address (e.g., 7'h77)
    input  wire [7:0]  reg_addr,    // register address
    input  wire [1:0]  wlen,        // 0..3
    input  wire [23:0] wdata,       // [23:16]=byte2, [15:8]=byte1, [7:0]=byte0
    input  wire [2:0]  rlen,        // 0..4

    // Status
    output reg         busy,
    output reg         done,        // 1-cycle pulse
    output reg         ack_error,   // sticky until next start

    // Readback
    output reg  [31:0] rdata,       // first byte at [31:24]
    output reg  [2:0]  rcount,
    output reg         rvalid,      // 1-cycle pulse with done

    // I2C lines (open-drain)
    inout  wire        i2c_scl,
    inout  wire        i2c_sda
);
    // Open-drain drivers: oe_n=1 => Z (HIGH via pull-up), oe_n=0 => drive LOW
    reg scl_oe_n, sda_oe_n;
    assign i2c_scl = scl_oe_n ? 1'bz : 1'b0;
    assign i2c_sda = sda_oe_n ? 1'bz : 1'b0;
    wire sda_in = i2c_sda;

    // Divider: half-period tick generator
    localparam integer HALF_TICKS = (CLK_FREQ/(I2C_FREQ*2));
    localparam integer CNTW = (HALF_TICKS <= 2) ? 2 : $clog2(HALF_TICKS);
    reg [CNTW-1:0] div_cnt;
    reg            tick;

    reg scl_high; // 1 during SCL high half-cycle (for sequencing)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 0; tick <= 1'b0;
        end else if (busy) begin
            if (div_cnt == HALF_TICKS-1) begin div_cnt <= 0; tick <= 1'b1; end
            else begin div_cnt <= div_cnt + 1'b1; tick <= 1'b0; end
        end else begin
            div_cnt <= 0; tick <= 1'b0;
        end
    end

    // FSM state encoding (Verilog-2001)
    localparam [3:0]
        ST_IDLE        = 4'd0,
        ST_START_A     = 4'd1,
        ST_START_B     = 4'd2,
        ST_SEND_ADDR_W = 4'd3,
        ST_SEND_REG    = 4'd4,
        ST_SEND_WBYTE  = 4'd5,
        ST_REP_START_A = 4'd6,
        ST_REP_START_B = 4'd7,
        ST_SEND_ADDR_R = 4'd8,
        ST_READ_RBYTE  = 4'd9,
        ST_STOP_A      = 4'd10,
        ST_STOP_B      = 4'd11,
        ST_DONE        = 4'd12,
        ST_ERROR       = 4'd13;

    reg [3:0] st;

    reg [6:0]  dev_addr_l; reg [7:0] reg_addr_l;
    reg [1:0]  wlen_l, wleft;
    reg [23:0] wdata_l;
    reg [2:0]  rlen_l, rleft;

    reg [7:0]  byte_tx; reg [2:0] bit_idx; reg byte_ack_phase;
    reg [31:0] rshift;

    // Helper to load next write byte
    function [7:0] sel_wbyte;
        input [23:0] wd; input [1:0] left;
        begin
            case (left)
                2'd3: sel_wbyte = wd[23:16];
                2'd2: sel_wbyte = wd[15:8];
                default: sel_wbyte = wd[7:0];
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= ST_IDLE; busy <= 1'b0; done <= 1'b0; rvalid <= 1'b0; ack_error <= 1'b0;
            scl_oe_n <= 1'b1; sda_oe_n <= 1'b1; scl_high <= 1'b1;
            dev_addr_l <= 7'd0; reg_addr_l <= 8'd0; wlen_l <= 2'd0; wdata_l <= 24'd0; rlen_l <= 3'd0;
            wleft <= 2'd0; rleft <= 3'd0; rshift <= 32'd0; rcount <= 3'd0; rdata <= 32'd0;
        end else begin
            done <= 1'b0; rvalid <= 1'b0;

            case (st)
                ST_IDLE: begin
                    scl_oe_n <= 1'b1; sda_oe_n <= 1'b1; scl_high <= 1'b1;
                    if (start && !busy) begin
                        busy <= 1'b1; ack_error <= 1'b0; rshift <= 32'd0; rcount <= 3'd0;
                        dev_addr_l <= dev_addr; reg_addr_l <= reg_addr; wlen_l <= wlen; wdata_l <= wdata; rlen_l <= rlen;
                        wleft <= wlen; rleft <= rlen;
                        st <= ST_START_A;
                    end
                end

                // START: SDA high->low while SCL high, then pull SCL low
                ST_START_A: if (tick) begin sda_oe_n <= 1'b0; st <= ST_START_B; end
                ST_START_B: if (tick) begin scl_oe_n <= 1'b0; scl_high <= 1'b0;
                                   byte_tx <= {dev_addr_l, 1'b0}; bit_idx <= 3'd7; byte_ack_phase <= 1'b0; st <= ST_SEND_ADDR_W; end

                // Byte Tx states (AddrW, Reg, WByte, AddrR):
                ST_SEND_ADDR_W, ST_SEND_REG, ST_SEND_WBYTE, ST_SEND_ADDR_R: begin
                    if (!byte_ack_phase) begin
                        // Bit phase: present bit during SCL low -> then raise SCL -> then lower SCL
                        if (!scl_high && tick) begin sda_oe_n <= (byte_tx[bit_idx] ? 1'b1 : 1'b0); scl_oe_n <= 1'b1; scl_high <= 1'b1; end
                        else if (scl_high && tick) begin
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 3'd0) byte_ack_phase <= 1'b1; else bit_idx <= bit_idx - 3'd1;
                        end
                    end else begin
                        // ACK phase: release SDA, raise SCL, sample sda_in, then lower SCL
                        if (!scl_high && tick) begin sda_oe_n <= 1'b1; scl_oe_n <= 1'b1; scl_high <= 1'b1; end
                        else if (scl_high && tick) begin
                            scl_oe_n <= 1'b0; scl_high <= 1'b0; // falling edge completes ACK phase
                            if (sda_in && (st != ST_SEND_ADDR_R)) begin ack_error <= 1'b1; st <= ST_ERROR; end
                            else begin
                                // Advance state machine
                                if (st == ST_SEND_ADDR_W) begin
                                    byte_tx <= reg_addr_l; bit_idx <= 3'd7; byte_ack_phase <= 1'b0; st <= ST_SEND_REG;
                                end else if (st == ST_SEND_REG) begin
                                    if (wleft > 0) begin
                                        byte_tx <= sel_wbyte(wdata_l, wleft); bit_idx <= 3'd7; byte_ack_phase <= 1'b0; wleft <= wleft - 2'd1; st <= ST_SEND_WBYTE;
                                    end else if (rlen_l > 0) st <= ST_REP_START_A; else st <= ST_STOP_A;
                                end else if (st == ST_SEND_WBYTE) begin
                                    if (wleft > 0) begin
                                        byte_tx <= sel_wbyte(wdata_l, wleft); bit_idx <= 3'd7; byte_ack_phase <= 1'b0; wleft <= wleft - 2'd1;
                                    end else if (rlen_l > 0) st <= ST_REP_START_A; else st <= ST_STOP_A;
                                end else if (st == ST_SEND_ADDR_R) begin
                                    bit_idx <= 3'd7; byte_ack_phase <= 1'b0; st <= ST_READ_RBYTE;
                                end
                            end
                        end
                    end
                end

                // REPEATED START
                ST_REP_START_A: if (tick) begin sda_oe_n <= 1'b1; scl_oe_n <= 1'b1; scl_high <= 1'b1; st <= ST_REP_START_B; end
                ST_REP_START_B: if (tick) begin sda_oe_n <= 1'b0; // SDA low while SCL high
                                          // next: Addr+R
                                          byte_tx <= {dev_addr_l, 1'b1}; bit_idx <= 3'd7; byte_ack_phase <= 1'b0; st <= ST_SEND_ADDR_R; end

                // READ one byte (then master sends ACK/NACK)
                ST_READ_RBYTE: begin
                    if (!byte_ack_phase) begin
                        // bit sampling during SCL high
                        if (!scl_high && tick) begin scl_oe_n <= 1'b1; scl_high <= 1'b1; end
                        else if (scl_high && tick) begin
                            rshift <= {rshift[30:0], sda_in};
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 3'd0) byte_ack_phase <= 1'b1; else bit_idx <= bit_idx - 3'd1;
                        end
                    end else begin
                        // After 8 bits: drive ACK (LOW) if more bytes to read, else NACK (release)
                        if (!scl_high && tick) begin
                            sda_oe_n <= (rleft > 3'd1) ? 1'b0 : 1'b1; // ACK for more, NACK for last
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            // complete ACK/NACK
                            scl_oe_n <= 1'b0; scl_high <= 1'b0; sda_oe_n <= 1'b1;
                            rleft <= rleft - 3'd1;
                            if (rleft > 3'd1) begin
                                bit_idx <= 3'd7; byte_ack_phase <= 1'b0; // next byte
                            end else begin
                                st <= ST_STOP_A; // last byte done
                            end
                        end
                    end
                end

                // STOP: SDA low, then with SCL high release SDA
                ST_STOP_A: if (tick) begin sda_oe_n <= 1'b0; st <= ST_STOP_B; end
                ST_STOP_B: if (tick) begin scl_oe_n <= 1'b1; scl_high <= 1'b1; st <= ST_DONE; end

                ST_DONE: if (tick) begin
                    sda_oe_n <= 1'b1; // release SDA -> STOP complete
                    if (rlen_l > 0) begin
                        rcount <= rlen_l;
                        rdata  <= rshift << (32 - (rlen_l*8)); // pack MSB-first
                        rvalid <= 1'b1;
                    end
                    done <= 1'b1; busy <= 1'b0; st <= ST_IDLE;
                end

                ST_ERROR: begin
                    // go to STOP to gracefully finish
                    st <= ST_STOP_A;
                end

                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
```

---

## 2) BMP085 컨트롤러 (bmp085_gy65)

- 기능: 주기적으로 온도 변환(0xF4=0x2E) → 5ms 대기 → 0xF6 2바이트 읽기(UT)
  이후 압력 변환(0xF4=0x34|(OSS<<6)) → OSS별 대기 → 0xF6 3바이트 읽기(UP) → 오른쪽 정렬
- 산출: ut[15:0], up[19:0], 각각 유효 펄스 신호와 상태 출력

```verilog
module bmp085_gy65 #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer SAMPLE_MS = 100,
    parameter integer OSS       = 0
)(
    input  wire        clk,
    input  wire        rst_n,

    inout  wire        i2c_scl,
    inout  wire        i2c_sda,

    output reg  [15:0] ut,
    output reg         ut_valid,
    output reg  [19:0] up,
    output reg         up_valid,

    output reg         busy_cycle,
    output reg         i2c_error
);
    localparam [6:0] DEV_ADDR = 7'h77; // BMP085/180

    // Master interface
    wire m_busy, m_done, m_rvalid, m_ack_error;
    wire [31:0] m_rdata;
    reg m_start;
    reg [6:0] m_addr; reg [7:0] m_reg;
    reg [1:0] m_wlen; reg [23:0] m_wdata; reg [2:0] m_rlen;

    i2c_master_combined #(
        .CLK_FREQ(CLK_FREQ), .I2C_FREQ(100_000)
    ) u_i2c (
        .clk(clk), .rst_n(rst_n),
        .start(m_start), .dev_addr(m_addr), .reg_addr(m_reg),
        .wlen(m_wlen), .wdata(m_wdata), .rlen(m_rlen),
        .busy(m_busy), .done(m_done), .ack_error(m_ack_error),
        .rdata(m_rdata), .rcount(), .rvalid(m_rvalid),
        .i2c_scl(i2c_scl), .i2c_sda(i2c_sda)
    );

    // Wait constants
    localparam integer TEMP_WAIT_CYC = (CLK_FREQ/1000) * 5; // 5ms

    function integer press_wait_ms;
        input [1:0] oss;
        begin
            case (oss)
                2'd0: press_wait_ms = 5;
                2'd1: press_wait_ms = 8;
                2'd2: press_wait_ms = 14;
                default: press_wait_ms = 26; // OSS=3
            endcase
        end
    endfunction

    function integer ms_to_cycles;
        input integer ms;
        begin ms_to_cycles = (CLK_FREQ/1000) * ms; end
    endfunction

    reg [31:0] wait_cnt;
    reg [31:0] press_wait_cycles;

    localparam [3:0]
        S_IDLE       = 4'd0,
        S_TRIG_TEMP  = 4'd1,
        S_WAIT_TEMP  = 4'd2,
        S_READ_UT    = 4'd3,
        S_TRIG_PRESS = 4'd4,
        S_WAIT_PRESS = 4'd5,
        S_READ_UP    = 4'd6,
        S_NEXT       = 4'd7;

    reg [3:0] st;

    reg [31:0] sample_cnt;
    localparam integer SAMPLE_CYCLES = (CLK_FREQ/1000) * SAMPLE_MS;

    wire mc_ready = !m_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE; m_start <= 1'b0; ut <= 16'd0; up <= 20'd0; ut_valid <= 1'b0; up_valid <= 1'b0;
            busy_cycle <= 1'b0; i2c_error <= 1'b0; sample_cnt <= 32'd0; wait_cnt <= 32'd0;
            press_wait_cycles <= ms_to_cycles(press_wait_ms(OSS));
        end else begin
            m_start <= 1'b0; ut_valid <= 1'b0; up_valid <= 1'b0;
            if (!busy_cycle) begin
                if (sample_cnt >= SAMPLE_CYCLES-1) sample_cnt <= 32'd0; else sample_cnt <= sample_cnt + 1;
            end

            case (st)
                S_IDLE: begin
                    busy_cycle <= 1'b0;
                    if (sample_cnt == SAMPLE_CYCLES-1) begin
                        busy_cycle <= 1'b1;
                        if (mc_ready) begin
                            m_addr <= DEV_ADDR; m_reg <= 8'hF4; // control
                            m_wlen <= 2'd1; m_wdata <= {16'd0, 8'h2E}; m_rlen <= 3'd0; // temp cmd
                            m_start <= 1'b1; st <= S_TRIG_TEMP;
                        end
                    end
                end

                S_TRIG_TEMP: if (m_done) begin wait_cnt <= 32'd0; st <= S_WAIT_TEMP; end

                S_WAIT_TEMP: begin
                    if (wait_cnt >= TEMP_WAIT_CYC-1) begin
                        if (mc_ready) begin
                            m_addr <= DEV_ADDR; m_reg <= 8'hF6; // result MSB
                            m_wlen <= 2'd0; m_rlen <= 3'd2; m_start <= 1'b1; st <= S_READ_UT;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end

                S_READ_UT: begin
                    if (m_done && m_rvalid) begin
                        ut <= {m_rdata[31:24], m_rdata[23:16]};
                        ut_valid <= 1'b1;
                        if (mc_ready) begin
                            m_addr <= DEV_ADDR; m_reg <= 8'hF4; // control
                            m_wlen <= 2'd1; m_wdata <= {16'd0, (8'h34 | (OSS[1:0] << 6))}; m_rlen <= 3'd0; // press cmd
                            m_start <= 1'b1; press_wait_cycles <= ms_to_cycles(press_wait_ms(OSS)); st <= S_TRIG_PRESS;
                        end
                    end
                end

                S_TRIG_PRESS: if (m_done) begin wait_cnt <= 32'd0; st <= S_WAIT_PRESS; end

                S_WAIT_PRESS: begin
                    if (wait_cnt >= press_wait_cycles-1) begin
                        if (mc_ready) begin
                            m_addr <= DEV_ADDR; m_reg <= 8'hF6; // result MSB
                            m_wlen <= 2'd0; m_rlen <= 3'd3; m_start <= 1'b1; st <= S_READ_UP;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end

                S_READ_UP: begin
                    if (m_done && m_rvalid) begin
                        // rdata holds: [31:24]=MSB, [23:16]=LSB, [15:8]=XLSB
                        // align: ((MSB<<16)|(LSB<<8)|XLSB) >> (8-OSS)
                        reg [23:0] raw24;
                        raw24 = {m_rdata[31:24], m_rdata[23:16], m_rdata[15:8]};
                        up <= (raw24 >> (8 - OSS[1:0]))[19:0];
                        up_valid <= 1'b1; st <= S_NEXT;
                    end
                end

                S_NEXT: begin busy_cycle <= 1'b0; st <= S_IDLE; end

                default: st <= S_IDLE;
            endcase

            if (m_ack_error) i2c_error <= 1'b1; // sticky until reset
        end
    end
endmodule
```

---

## 3) Top 모듈 (gy65_top)

- Basys3의 100 MHz 클럭과 리셋 버튼(btnC) 연결
- JA 헤더로 I2C 라인 연결 (핀은 XDC에서 지정)
- 원시 온도값 UT[15:0]을 LED에 표시 (필요시 UP를 선택 출력하도록 쉽게 변경 가능)

```verilog
module gy65_top (
    input  wire CLK100MHZ,
    input  wire btnC,

    inout  wire JA_SCL,
    inout  wire JA_SDA,

    output wire [15:0] LED
);
    wire rst_n = ~btnC;

    wire [15:0] ut; wire ut_valid; wire [19:0] up; wire up_valid; wire busy; wire i2c_err;

    bmp085_gy65 #(
        .CLK_FREQ(100_000_000),
        .SAMPLE_MS(100),
        .OSS(0)
    ) u_gy65 (
        .clk(CLK100MHZ), .rst_n(rst_n),
        .i2c_scl(JA_SCL), .i2c_sda(JA_SDA),
        .ut(ut), .ut_valid(ut_valid), .up(up), .up_valid(up_valid),
        .busy_cycle(busy), .i2c_error(i2c_err)
    );

    assign LED = ut; // 필요시 up[19:4] 등으로 변경 가능
endmodule
```

---

## 4) Basys3 제약(XDC) 예시

주의: JA_SCL/JA_SDA의 PACKAGE_PIN은 실제 연결한 JA 헤더의 핀 번호에 맞추어 수정하세요.

```xdc
# Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports CLK100MHZ]

# Reset button (Center)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# I2C Pmod JA (example pins)
set_property PACKAGE_PIN J1 [get_ports JA_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports JA_SCL]
set_property PULLUP true [get_ports JA_SCL]

set_property PACKAGE_PIN L2 [get_ports JA_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports JA_SDA]
set_property PULLUP true [get_ports JA_SDA]

# LEDs
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
set_property PACKAGE_PIN V3 [get_ports {LED[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
set_property PACKAGE_PIN W3 [get_ports {LED[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
set_property PACKAGE_PIN U3 [get_ports {LED[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
set_property PACKAGE_PIN P3 [get_ports {LED[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]
set_property PACKAGE_PIN N3 [get_ports {LED[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]
set_property PACKAGE_PIN P1 [get_ports {LED[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]
set_property PACKAGE_PIN L1 [get_ports {LED[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]
```

---

## 5) 동작 이슈 점검/수정 포인트 (중요)

다음 항목을 천천히 점검하세요. 현장에서 동작 불량의 주된 원인이 되는 부분입니다.

- 전원/레벨
  - GY-65는 3.3V 동작. Basys3 Pmod는 3.3V. VCC/GND 정확히 연결.
  - 센서 보드에 풀업저항이 실장되어 있는 경우가 많습니다. XDC의 PULLUP true 설정과 중복되어도 일반적으로 문제는 없지만, 라인이 과도하게 강하게 풀업되면 신호 왜곡 가능. 필요시 XDC PULLUP 제거.

- 핀 매핑
  - JA_SCL/JA_SDA 핀 PACKAGE_PIN이 실제 연결 핀과 일치하는지 확인. JA 헤더의 1,2번 핀을 사용했는지 점검.

- I2C 파형 타이밍
  - 오실로스코프로 SCL/SDA 확인. START(High에서 SDA Low), STOP(High에서 SDA High) 시퀀스 확인.
  - 바이트 전송 중 SDA는 SCL High에서 안정되어야 함. 코드에서 SCL Low에서 데이터 설정, SCL High에서 샘플.

- 대기시간(변환시간)
  - TEMP 5ms, PRESS OSS별 5/8/14/26ms. 샘플링 주기(SAMPLE_MS)가 너무 짧으면 이전 변환과 겹칠 수 있음. 100ms 이상 권장.

- 주소/명령
  - BMP085/BMP180 주소 0x77(7-bit). 레지스터 주소 0xF4(컨트롤), 0xF6(MSB). 명령 0x2E(온도), 0x34|(OSS<<6)(압력).

- Clock stretching 미지원
  - 본 마스터는 슬레이브 clock-stretching을 지원하지 않습니다. BMP085/180은 일반적으로 사용하지 않으므로 문제 없음. 다른 I2C 디바이스 사용 시 주의.

- 합성/시뮬레이션
  - Verilog-2001만 사용. case/state 인코딩 수동 지정.
  - 시뮬레이션에서 HALF_TICKS가 너무 작으면(CLK/I2C 비율) 타이밍이 급해짐. 기본값 유지 권장.

- 디버깅 팁
  - i2c_error 신호를 LED에 매핑해 NACK 여부 표시.
  - busy_cycle을 LED에 매핑해 측정 사이클 확인.
  - ILA 삽입 시 유용 신호: st, m_* (start, done, rvalid, rdata), scl_oe_n, sda_oe_n, sda_in.

---

## 6) 사용 방법 요약

1) 세 파일을 프로젝트에 추가
- i2c_master_combined.v
- bmp085_gy65.v
- gy65_top.v (Top)

2) 제약(XDC) 추가 및 Pmod 핀 확인

3) 합성/임플/비트스트림 생성 후 보드 프로그래밍

4) btnC로 리셋 해제 후 LED에 UT 값이 표시되는지 확인

필요 시 gy65_top에서 LED를 up[19:4]로 바꿔 압력 원시값도 확인 가능합니다.
