# 최종 추천: GY-65(BMP085) I2C 제어 Verilog 프로젝트 (Basys3 보드용)

이 문서는 Basys3 FPGA 보드에서 GY-65(BMP085) 기압 및 온도 센서를 I2C 통신으로 제어하기 위한 최종 추천 코드와 프로젝트 빌드 가이드를 포함합니다. 제공된 여러 버전의 코드를 검토한 결과, 아래 코드가 가장 안정적이고 구조적으로 우수하여 이를 기반으로 작성되었습니다.

## 1. 프로젝트 개요

- **목표**: Basys3 보드를 사용하여 GY-65 센서로부터 원시(raw) 온도 및 기압 데이터를 주기적으로 읽어옵니다.
- **주요 기능**:
    - 100kHz 표준 속도로 동작하는 안정적인 I2C 마스터 컨트롤러.
    - BMP085 데이터시트 사양에 맞춘 정밀한 측정 시퀀스 (온도 측정 → 압력 측정).
    - 최상위 모듈에서 측정된 16비트 원시 온도 값을 LED로 출력하여 동작을 시각적으로 확인.
- **하드웨어**:
    - Xilinx Artix-7 FPGA (Basys3 보드)
    - GY-65 (BMP085) 센서 모듈

---

## 2. Verilog 모듈 코드

### 2.1. I2C 마스터 모듈 (`i2c_master_combined`)

I2C 통신을 위한 핵심 모듈입니다. Start/Stop/Repeated Start 조건, 데이터 송수신, ACK/NACK 처리를 모두 담당합니다. `inout` 포트를 직접 사용하여 간결하고 표준적인 오픈 드레인(Open-drain)을 구현합니다.

```verilog
// I2C combined transaction master specialized for register-based sensors.
// Supports: Start -> [Addr+W] -> RegAddr -> [opt: W bytes] -> [opt: RepeatedStart -> Addr+R -> R bytes] -> Stop
// Open-drain SCL/SDA (drive-low or release-high). No clock-stretching support.
// Parameters: CLK_FREQ in Hz, I2C_FREQ in Hz
module i2c_master_combined #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000
)(
    input  wire        clk,
    input  wire        rst_n,

    // Transaction descriptor
    input  wire        start,         // pulse to start transaction
    input  wire [6:0]  dev_addr,      // 7-bit I2C address (e.g., 7'h77 for BMP085)
    input  wire [7:0]  reg_addr,      // register address
    input  wire [1:0]  wlen,          // number of data bytes to write (0..3)
    input  wire [23:0] wdata,         // write data payload. Byte order: [23:16]=byte2, [15:8]=byte1, [7:0]=byte0
    input  wire [2:0]  rlen,          // number of bytes to read (0..4)

    // Status
    output reg         busy,
    output reg         done,          // 1-cycle pulse when the whole transaction completes
    output reg         ack_error,     // goes high if any slave NACK happened (sticky until next start)

    // Readback
    output reg  [31:0] rdata,         // read payload packed MSB-first: first byte at [31:24]
    output reg  [2:0]  rcount,        // number of bytes filled in rdata
    output reg         rvalid,        // 1-cycle pulse when rdata/rcount are valid (end of transaction)

    // I2C lines (open-drain)
    inout  wire        i2c_scl,
    inout  wire        i2c_sda
);

    // Open-drain drivers
    reg scl_oe_n; // 1: release (Z=high), 0: drive low
    reg sda_oe_n; // 1: release, 0: drive low
    assign i2c_scl = scl_oe_n ? 1'bz : 1'b0;
    assign i2c_sda = sda_oe_n ? 1'bz : 1'b0;

    wire sda_in = i2c_sda;

    // Clock divider to generate SCL half-period enables
    localparam integer HALF_TICKS = (CLK_FREQ/(I2C_FREQ*2));
    localparam integer CNTW = $clog2(HALF_TICKS);
    reg [CNTW-1:0] div_cnt;
    reg            tick;       // half-period tick for SCL toggling

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 0;
            tick    <= 1'b0;
        end else if (busy) begin
            if (div_cnt == HALF_TICKS-1) begin
                div_cnt <= 0;
                tick    <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1'b1;
                tick    <= 1'b0;
            end
        end else begin
            div_cnt <= 0;
            tick    <= 1'b0;
        end
    end

    reg scl_high;

    reg [7:0] byte_tx;
    reg [2:0] bit_idx;
    reg       byte_phase;

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_START_A, ST_START_B,
        ST_SEND_ADDR_W, ST_SEND_REG, ST_SEND_WBYTE,
        ST_REP_START_A, ST_REP_START_B,
        ST_SEND_ADDR_R, ST_READ_RBYTE,
        ST_STOP_A, ST_STOP_B,
        ST_DONE, ST_ERROR
    } state_t;

    state_t st;

    reg [1:0] wleft;
    reg [2:0] rleft;

    reg [6:0] dev_addr_l;
    reg [7:0] reg_addr_l;
    reg [1:0] wlen_l;
    reg [23:0] wdata_l;
    reg [2:0] rlen_l;

    reg [31:0] rshift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st        <= ST_IDLE;
            busy      <= 1'b0;
            done      <= 1'b0;
            rvalid    <= 1'b0;
            ack_error <= 1'b0;
            scl_high  <= 1'b1;
            scl_oe_n  <= 1'b1;
            sda_oe_n  <= 1'b1;
            dev_addr_l<= 7'd0;
            reg_addr_l<= 8'd0;
            wlen_l    <= 2'd0;
            wdata_l   <= 24'd0;
            rlen_l    <= 3'd0;
            rshift    <= 32'd0;
            rcount    <= 3'd0;
            rdata     <= 32'd0;
        end else begin
            done   <= 1'b0;
            rvalid <= 1'b0;

            if (st == ST_IDLE) begin
                scl_oe_n  <= 1'b1;
                sda_oe_n  <= 1'b1;
                scl_high  <= 1'b1;
                if (start && !busy) begin
                    dev_addr_l <= dev_addr;
                    reg_addr_l <= reg_addr;
                    wlen_l     <= wlen;
                    wdata_l    <= wdata;
                    rlen_l     <= rlen;
                    wleft      <= wlen;
                    rleft      <= rlen;
                    rshift     <= 32'd0;
                    rcount     <= 3'd0;
                    ack_error  <= 1'b0;
                    busy       <= 1'b1;
                    st         <= ST_START_A;
                end
            end else if (st == ST_START_A) begin
                if (tick) begin
                    sda_oe_n <= 1'b0;
                    st       <= ST_START_B;
                end
            end else if (st == ST_START_B) begin
                if (tick) begin
                    scl_oe_n <= 1'b0;
                    scl_high <= 1'b0;
                    byte_tx   <= {dev_addr_l, 1'b0};
                    bit_idx   <= 3'd7;
                    byte_phase<= 1'b0;
                    st        <= ST_SEND_ADDR_W;
                end
            end else if (st == ST_SEND_ADDR_W || st == ST_SEND_REG || st == ST_SEND_WBYTE || st == ST_SEND_ADDR_R) begin
                if (!byte_phase) begin
                    if (!scl_high && tick) {sda_oe_n, scl_oe_n, scl_high} <= {byte_tx[bit_idx] ? 1'b1 : 1'b0, 1'b1, 1'b1};
                    else if (scl_high && tick) begin
                        {scl_oe_n, scl_high} <= {1'b0, 1'b0};
                        if (bit_idx == 0) byte_phase <= 1'b1; else bit_idx <= bit_idx - 1;
                    end
                end else begin
                    if (!scl_high && tick) {sda_oe_n, scl_oe_n, scl_high} <= {1'b1, 1'b1, 1'b1};
                    else if (scl_high && tick) begin
                        if (sda_in && st != ST_SEND_ADDR_R) {ack_error, st} <= {1'b1, ST_ERROR};
                        else begin
                            {scl_oe_n, scl_high} <= {1'b0, 1'b0};
                            if (st == ST_SEND_ADDR_W) begin
                                byte_tx <= reg_addr_l; bit_idx <= 3'd7; byte_phase <= 1'b0; st <= ST_SEND_REG;
                            end else if (st == ST_SEND_REG) begin
                                if (wleft > 0) begin
                                    case(wleft)
                                        3: byte_tx <= wdata_l[23:16];
                                        2: byte_tx <= wdata_l[15:8];
                                        1: byte_tx <= wdata_l[7:0];
                                    endcase
                                    bit_idx <= 3'd7; byte_phase <= 1'b0; wleft <= wleft - 1; st <= ST_SEND_WBYTE;
                                end else if (rlen_l > 0) st <= ST_REP_START_A;
                                else st <= ST_STOP_A;
                            end else if (st == ST_SEND_WBYTE) begin
                                if (wleft > 0) begin
                                    case(wleft)
                                        3: byte_tx <= wdata_l[23:16];
                                        2: byte_tx <= wdata_l[15:8];
                                        1: byte_tx <= wdata_l[7:0];
                                    endcase
                                    bit_idx <= 3'd7; byte_phase <= 1'b0; wleft <= wleft - 1;
                                end else if (rlen_l > 0) st <= ST_REP_START_A;
                                else st <= ST_STOP_A;
                            end else if (st == ST_SEND_ADDR_R) begin
                                bit_idx <= 3'd7; byte_phase <= 1'b0; st <= ST_READ_RBYTE;
                            end
                        end
                    end
                end
            end else if (st == ST_READ_RBYTE) begin
                if (!byte_phase) begin
                    if (!scl_high && tick) {scl_oe_n, scl_high} <= {1'b1, 1'b1};
                    else if (scl_high && tick) begin
                        rshift <= {rshift[30:0], sda_in};
                        {scl_oe_n, scl_high} <= {1'b0, 1'b0};
                        if (bit_idx == 0) byte_phase <= 1'b1; else bit_idx <= bit_idx - 1;
                    end
                end else begin
                    if (!scl_high && tick) begin
                        sda_oe_n <= (rleft > 1) ? 1'b0 : 1'b1;
                        {scl_oe_n, scl_high} <= {1'b1, 1'b1};
                    end else if (scl_high && tick) begin
                        {scl_oe_n, scl_high} <= {1'b0, 1'b0};
                        sda_oe_n <= 1'b1;
                        rleft <= rleft - 1;
                        if (rleft > 1) begin bit_idx <= 3'd7; byte_phase <= 1'b0; end
                        else st <= ST_STOP_A;
                    end
                end
            end else if (st == ST_REP_START_A) begin
                if (tick) {sda_oe_n, scl_oe_n, scl_high} <= {1'b1, 1'b1, 1'b1};
                if (tick) st <= ST_REP_START_B;
            end else if (st == ST_REP_START_B) begin
                if (tick) begin
                    sda_oe_n <= 1'b0;
                    st <= ST_START_B;
                    byte_tx <= {dev_addr_l, 1'b1};
                    st <= ST_SEND_ADDR_R;
                end
            end else if (st == ST_STOP_A) begin
                if (tick) begin sda_oe_n <= 1'b0; st <= ST_STOP_B; end
            end else if (st == ST_STOP_B) begin
                if (tick) begin {scl_oe_n, scl_high} <= {1'b1, 1'b1}; st <= ST_DONE; end
            end else if (st == ST_DONE) begin
                if (tick) begin
                    sda_oe_n <= 1'b1;
                    if (rlen_l > 0) begin
                        rcount <= rlen_l;
                        rdata <= rshift << (32 - rlen_l*8);
                        rvalid <= 1'b1;
                    end
                    done <= 1'b1;
                    busy <= 1'b0;
                    st <= ST_IDLE;
                end
            end else if (st == ST_ERROR) begin
                st <= ST_STOP_A;
            end
        end
    end
endmodule
```

### 2.2. BMP085 컨트롤러 모듈 (`bmp085_gy65`)

`i2c_master_combined` 모듈을 인스턴스화하여 BMP085의 동작 시퀀스를 제어합니다. 주기적으로 온도와 압력 측정을 트리거하고, 변환이 완료될 때까지 대기한 후, 결과 값을 읽어옵니다.

```verilog
// BMP085 (GY-65) simple controller: periodically triggers temperature and pressure conversions,
// then reads raw UT (16-bit) and UP (20-bit, aligned) via I2C.
// Note: This module does NOT compute compensated temperature/pressure. It outputs raw UT/UP.
module bmp085_gy65 #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer SAMPLE_MS = 100, // measurement cycle
    parameter integer OSS       = 0    // 0..3, oversampling setting
)(
    input  wire        clk,
    input  wire        rst_n,

    // I2C lines
    inout  wire        i2c_scl,
    inout  wire        i2c_sda,

    // Raw outputs
    output reg  [15:0] ut,        // 16-bit raw temperature
    output reg         ut_valid,  // 1-cycle pulse when ut updated
    output reg  [19:0] up,        // right-aligned 20-bit raw pressure
    output reg         up_valid,  // 1-cycle pulse when up updated

    // Status
    output reg         busy_cycle,
    output reg         i2c_error
);

    localparam [6:0] DEV_ADDR = 7'h77;

    wire m_busy, m_done, m_rvalid, m_ack_error;
    wire [31:0] m_rdata;
    reg m_start;
    reg [6:0] m_dev_addr;
    reg [7:0] m_reg_addr;
    reg [1:0] m_wlen;
    reg [23:0] m_wdata;
    reg [2:0] m_rlen;

    i2c_master_combined #(
        .CLK_FREQ(CLK_FREQ)
    ) i2c_master (
        .clk(clk), .rst_n(rst_n),
        .start(m_start), .dev_addr(m_dev_addr), .reg_addr(m_reg_addr),
        .wlen(m_wlen), .wdata(m_wdata), .rlen(m_rlen),
        .busy(m_busy), .done(m_done), .rvalid(m_rvalid), .ack_error(m_ack_error),
        .rdata(m_rdata),
        .i2c_scl(i2c_scl), .i2c_sda(i2c_sda)
    );

    localparam integer TEMP_WAIT_CYC = (CLK_FREQ/1000) * 5; // 5ms wait

    function integer press_delay_ms(input [1:0] oss);
        case(oss) 0: press_delay_ms=5; 1: press_delay_ms=8; 2: press_delay_ms=14; 3: press_delay_ms=26; endcase
    endfunction

    function integer ms_to_cycles(input integer ms);
        ms_to_cycles = (CLK_FREQ/1000) * ms;
    endfunction

    reg [31:0] wait_cnt;
    reg [31:0] press_wait_cycles;

    typedef enum logic [3:0] {
        S_IDLE, S_TRIG_TEMP, S_WAIT_TEMP, S_READ_UT,
        S_TRIG_PRESS, S_WAIT_PRESS, S_READ_UP, S_NEXT
    } st_t;
    st_t st;

    reg [31:0] sample_cnt;
    localparam integer SAMPLE_CYCLES = (CLK_FREQ/1000) * SAMPLE_MS;

    wire mc_ready = !m_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE;
            m_start <= 1'b0;
            ut <= 16'd0; up <= 20'd0;
            ut_valid <= 1'b0; up_valid <= 1'b0;
            busy_cycle <= 1'b0; i2c_error <= 1'b0;
            sample_cnt <= 32'd0; wait_cnt <= 32'd0;
            press_wait_cycles <= ms_to_cycles(press_delay_ms(OSS));
        end else begin
            m_start <= 1'b0;
            ut_valid <= 1'b0; up_valid <= 1'b0;

            if (!busy_cycle) begin
                if (sample_cnt >= SAMPLE_CYCLES-1) sample_cnt <= 32'd0;
                else sample_cnt <= sample_cnt + 1;
            end

            case (st)
                S_IDLE: begin
                    busy_cycle <= 1'b0;
                    if (sample_cnt == SAMPLE_CYCLES-1) begin
                        busy_cycle <= 1'b1;
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR; m_reg_addr <= 8'hF4;
                            m_wlen <= 2'd1; m_wdata <= {16'd0, 8'h2E}; m_rlen <= 3'd0;
                            m_start <= 1'b1; st <= S_TRIG_TEMP;
                        end
                    end
                end
                S_TRIG_TEMP: if (m_done) begin wait_cnt <= 32'd0; st <= S_WAIT_TEMP; end
                S_WAIT_TEMP: begin
                    if (wait_cnt >= TEMP_WAIT_CYC-1) begin
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR; m_reg_addr <= 8'hF6;
                            m_wlen <= 2'd0; m_rlen <= 3'd2;
                            m_start <= 1'b1; st <= S_READ_UT;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_READ_UT: begin
                    if (m_done && m_rvalid) begin
                        ut <= {m_rdata[31:24], m_rdata[23:16]};
                        ut_valid <= 1'b1;
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR; m_reg_addr <= 8'hF4;
                            m_wlen <= 2'd1; m_wdata <= {16'd0, (8'h34 | (OSS[1:0] << 6))}; m_rlen <= 3'd0;
                            m_start <= 1'b1;
                            press_wait_cycles <= ms_to_cycles(press_delay_ms(OSS));
                            st <= S_TRIG_PRESS;
                        end
                    end
                end
                S_TRIG_PRESS: if (m_done) begin wait_cnt <= 32'd0; st <= S_WAIT_PRESS; end
                S_WAIT_PRESS: begin
                    if (wait_cnt >= press_wait_cycles-1) begin
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR; m_reg_addr <= 8'hF6;
                            m_wlen <= 2'd0; m_rlen <= 3'd3;
                            m_start <= 1'b1; st <= S_READ_UP;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_READ_UP: begin
                    if (m_done && m_rvalid) begin
                        reg [31:0] raw24;
                        raw24 = {m_rdata[31:8], 8'd0} >> (8 - OSS[1:0]);
                        up <= raw24[19:0];
                        up_valid <= 1'b1;
                        st <= S_NEXT;
                    end
                end
                S_NEXT: begin busy_cycle <= 1'b0; st <= S_IDLE; end
                default: st <= S_IDLE;
            endcase
            if (m_ack_error) i2c_error <= 1'b1;
        end
    end
endmodule
```

### 2.3. 최상위 모듈 (`gy65_top`)

프로젝트의 최상위 모듈입니다. Basys3 보드의 100MHz 클럭과 리셋 버튼을 시스템에 연결하고, `bmp085_gy65` 모듈을 인스턴스화합니다. I2C 핀을 Pmod 헤더에 연결하고, 측정된 온도 값을 16개의 LED에 출력합니다.

```verilog
// Basys3 top example to interface BMP085 (GY-65) via I2C.
// - Clock: 100 MHz (Basys3)
// - Reset: btnC active-low
// - I2C: connect to a Pmod header (SCL,SDA).
// - LEDs: show UT[15:0] raw temperature.
module gy65_top (
    input  wire CLK100MHZ,
    input  wire btnC,

    // I2C lines to Pmod header
    inout  wire JA_SCL,
    inout  wire JA_SDA,

    output wire [15:0] LED
);
    wire rst_n = ~btnC;

    wire [15:0] ut;

    bmp085_gy65 #(
        .CLK_FREQ(100_000_000),
        .SAMPLE_MS(100),
        .OSS(0)
    ) u_gy65 (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .i2c_scl(JA_SCL),
        .i2c_sda(JA_SDA),
        .ut(ut)
        // Other outputs are not used in this example
    );

    assign LED = ut;

endmodule
```

---

## 3. 제약 파일 (XDC)

Vivado 프로젝트에 사용할 XDC(Xilinx Design Constraints) 파일입니다. Basys3 보드의 클럭, 리셋 버튼, LED, Pmod 헤더 핀을 Verilog 코드의 포트와 매핑합니다.

**중요**: 아래 Pmod 핀 설정(`JA_SCL`, `JA_SDA`)은 **예시**입니다. 실제 하드웨어 연결에 사용하는 Pmod 헤더(JA, JB, JC, JD)와 핀 번호에 맞게 `PACKAGE_PIN` 값을 **반드시 수정**해야 합니다.

```xdc
# Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports CLK100MHZ]

# Reset button (Center)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## I2C Pmod connection (Example for JA header)
## IMPORTANT: Update PACKAGE_PIN to actual Basys3 Pmod pin assignment.
# Pmod JA1 for SCL
set_property PACKAGE_PIN J1 [get_ports JA_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports JA_SCL]
set_property PULLUP true [get_ports JA_SCL]

# Pmod JA2 for SDA
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

## 4. 프로젝트 빌드 및 실행 가이드

### 4.1. 하드웨어 연결

1.  **전원 및 GND**: GY-65 센서의 `VCC` 핀을 Basys3 Pmod 헤더의 `3.3V` 핀에, `GND` 핀을 `GND` 핀에 연결합니다.
2.  **I2C 신호선**:
    -   GY-65의 `SCL` 핀을 XDC 파일에 지정한 Pmod 핀(예: `JA1`, `J1` 핀)에 연결합니다.
    -   GY-65의 `SDA` 핀을 XDC 파일에 지정한 Pmod 핀(예: `JA2`, `L2` 핀)에 연결합니다.
3.  **풀업 저항**: XDC 파일에서 `PULLUP true` 설정을 통해 Basys3 내부 풀업 저항을 사용하므로, 별도의 외부 풀업 저항은 필요하지 않습니다.

### 4.2. Vivado 프로젝트 설정

1.  **새 프로젝트 생성**: Vivado를 실행하고 Basys3 보드(`xc7a35tcpg236-1`)를 타겟으로 새 프로젝트를 생성합니다.
2.  **소스 파일 추가**:
    -   위 Verilog 코드들을 각각의 `.v` 파일로 저장합니다. (예: `i2c_master.v`, `bmp085.v`, `top.v`)
    -   `Add Sources`를 통해 3개의 Verilog 파일을 프로젝트에 추가합니다.
    -   `gy65_top` 모듈이 최상위 모듈로 자동 설정되었는지 확인합니다.
3.  **제약 파일 추가**:
    -   위 XDC 내용을 `.xdc` 파일(예: `basys3_constraints.xdc`)로 저장합니다.
    -   `Add or create constraints`를 통해 XDC 파일을 프로젝트에 추가합니다.
4.  **프로젝트 빌드**:
    -   `Run Synthesis` → `Run Implementation` → `Generate Bitstream`을 순서대로 실행하여 프로젝트를 빌드합니다.
5.  **보드 프로그래밍**:
    -   `Hardware Manager`를 열고 Basys3 보드에 연결합니다.
    -   생성된 `.bit` 파일을 보드에 프로그래밍합니다.

### 4.3. 동작 확인

-   프로그래밍이 완료되면, 보드의 `btnC`를 눌러 리셋을 해제합니다.
-   `SAMPLE_MS` (기본 100ms) 주기로 센서 측정이 시작됩니다.
-   측정된 16비트 원시 온도 값이 16개의 `LED`에 실시간으로 표시됩니다.
-   센서에 손을 가까이 대거나 입김을 불어 온도를 변화시켰을 때, LED 패턴이 바뀌는 것을 통해 정상 동작을 확인할 수 있습니다.
