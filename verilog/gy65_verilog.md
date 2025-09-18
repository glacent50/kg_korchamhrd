# GY-65(BMP085) I2C Verilog 예제

다음은 GY-65(BMP085) 기압 센서를 I2C(100 kHz)로 제어해 원시 측정값(UT, UP)을 주기적으로 읽는 Verilog 예제입니다.

- i2c_master_combined: 레지스터 접근에 최적화된 I2C 단일 트랜잭션 마스터(Write-Then-Read, Repeated START 지원)
- bmp085_gy65: BMP085 측정을 위한 시퀀서(온도/압력 측정 명령→대기→데이터 읽기). 보정계수 연산 없이 UT/UP만 출력
- gy65_top: Basys3(100 MHz)에서 구동 예제(LED에 UT를 표시). I2C 핀은 Pmod로 배치하세요.
- gy65_i2c.xdc: I2C 핀 제약 템플릿(실제 핀은 Basys3 Master XDC 참고하여 수정)

필요시 보정 연산(보정계수 읽기 및 보정 압력/온도 계산)을 추가해 드릴 수 있습니다.

추가 전제
- Basys3 시스템 클록: 100 MHz
- I2C 표준모드: 100 kHz
- GY-65는 보드에 풀업 저항이 포함되어 있어 별도 풀업 없이 연결 가능(3.3V 사용)

---

## 코드

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

    // Engine clock when busy
    wire engine_en = busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 0;
            tick    <= 1'b0;
        end else if (engine_en) begin
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

    // SCL high/low phase flag (for sequencing)
    reg scl_high; // 1: SCL released high, 0: SCL driven low

    // Byte-level controls
    reg [7:0] byte_tx;
    reg [2:0] bit_idx;    // 7..0
    reg       byte_phase; // 0: sending/reading 8 bits; 1: ACK/NACK bit phase
    reg       reading;    // 0: writing byte; 1: reading byte

    // Transaction planner
    typedef enum logic [4:0] {
        ST_IDLE = 0,
        ST_START_A,
        ST_START_B,
        ST_SEND_ADDR_W, ST_SEND_REG, ST_SEND_WBYTE,
        ST_REP_START_A, ST_REP_START_B,
        ST_SEND_ADDR_R, ST_READ_RBYTE,
        ST_STOP_A, ST_STOP_B,
        ST_DONE, ST_ERROR
    } state_t;

    state_t st, st_next;

    // Byte counters
    reg [1:0] wleft;   // remaining write bytes
    reg [2:0] rleft;   // remaining read bytes

    // Helpers to pull out wdata bytes MSB-first
    wire [7:0] wbyte2 = wdata[23:16];
    wire [7:0] wbyte1 = wdata[15:8];
    wire [7:0] wbyte0 = wdata[7:0];

    function [7:0] wdata_sel(input [1:0] idx, input [1:0] total_minus1);
        // idx is zero-based from most-significant byte among the provided wlen
        // Ex: wlen=3 => total_minus1=2: idx=0->wbyte2, 1->wbyte1, 2->wbyte0
        begin
            case (total_minus1)
                2'd0: wdata_sel = wbyte0;            // wlen=1
                2'd1: wdata_sel = (idx==0) ? wbyte1 : wbyte0; // wlen=2
                default: begin // wlen=3
                    case (idx)
                        2'd0: wdata_sel = wbyte2;
                        2'd1: wdata_sel = wbyte1;
                        default: wdata_sel = wbyte0;
                    endcase
                end
            endcase
        end
    endfunction

    // Latches for input descriptor at start
    reg [6:0] dev_addr_l;
    reg [7:0] reg_addr_l;
    reg [1:0] wlen_l;
    reg [23:0] wdata_l;
    reg [2:0] rlen_l;

    // Read accumulator
    reg [31:0] rshift;
    reg [2:0]  rcount_l;

    // Control: begin new transaction
    wire has_write = (wlen_l != 0);
    wire has_read  = (rlen_l != 0);

    // Sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st        <= ST_IDLE;
            busy      <= 1'b0;
            done      <= 1'b0;
            rvalid    <= 1'b0;
            ack_error <= 1'b0;
            scl_high  <= 1'b1; // bus idle: SCL high, SDA high
            scl_oe_n  <= 1'b1;
            sda_oe_n  <= 1'b1;
            bit_idx   <= 3'd7;
            byte_phase<= 1'b0;
            reading   <= 1'b0;
            wleft     <= 2'd0;
            rleft     <= 3'd0;
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

            case (st)
                ST_IDLE: begin
                    scl_oe_n  <= 1'b1; // release high
                    sda_oe_n  <= 1'b1; // release high
                    scl_high  <= 1'b1;
                    ack_error <= 1'b0;
                    if (start && !busy) begin
                        // Latch descriptor
                        dev_addr_l <= dev_addr;
                        reg_addr_l <= reg_addr;
                        wlen_l     <= wlen;
                        wdata_l    <= wdata;
                        rlen_l     <= rlen;
                        wleft      <= wlen;
                        rleft      <= rlen;
                        rshift     <= 32'd0;
                        rcount     <= 3'd0;

                        busy       <= 1'b1;
                        st         <= ST_START_A;
                    end
                end

                // START: while SCL high, pull SDA low
                ST_START_A: begin
                    // Ensure SCL released high
                    scl_oe_n <= 1'b1;
                    if (tick) begin
                        // Generate start condition: SDA goes low while SCL high
                        sda_oe_n <= 1'b0; // pull low
                        st       <= ST_START_B;
                    end
                end
                ST_START_B: begin
                    if (tick) begin
                        // Pull SCL low to start bit transfers
                        scl_oe_n <= 1'b0; // drive low
                        scl_high <= 1'b0;
                        // First byte: device addr + write(0)
                        byte_tx   <= {dev_addr_l, 1'b0};
                        bit_idx   <= 3'd7;
                        byte_phase<= 1'b0;
                        reading   <= 1'b0;
                        st        <= ST_SEND_ADDR_W;
                    end
                end

                // Send address+W -> ACK
                ST_SEND_ADDR_W: begin
                    if (!byte_phase) begin
                        // data bit phase
                        if (!scl_high && tick) begin
                            // Set SDA on SCL low
                            sda_oe_n <= byte_tx[bit_idx] ? 1'b1 : 1'b0;
                            // raise SCL
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            // lower SCL
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 0) begin
                                byte_phase <= 1'b1; // go to ACK
                            end else begin
                                bit_idx <= bit_idx - 1;
                            end
                        end
                    end else begin
                        // ACK bit from slave: release SDA, raise SCL, sample on high
                        if (!scl_high && tick) begin
                            sda_oe_n <= 1'b1; // release for ACK
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            // sample ACK (0 = ACK)
                            if (sda_in) begin
                                ack_error <= 1'b1;
                                st        <= ST_ERROR;
                            end else begin
                                // next byte: reg address
                                scl_oe_n  <= 1'b0; scl_high <= 1'b0;
                                byte_tx   <= reg_addr_l;
                                bit_idx   <= 3'd7;
                                byte_phase<= 1'b0;
                                st        <= ST_SEND_REG;
                            end
                        end
                    end
                end

                // Send register address -> ACK
                ST_SEND_REG: begin
                    if (!byte_phase) begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= byte_tx[bit_idx] ? 1'b1 : 1'b0;
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 0) byte_phase <= 1'b1;
                            else bit_idx <= bit_idx - 1;
                        end
                    end else begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= 1'b1;
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            if (sda_in) begin
                                ack_error <= 1'b1;
                                st        <= ST_ERROR;
                            end else begin
                                scl_oe_n <= 1'b0; scl_high <= 1'b0;
                                if (wleft != 0) begin
                                    // send first write data byte
                                    byte_tx   <= wdata_sel( (wlen_l- wleft), (wlen_l-1) );
                                    bit_idx   <= 3'd7;
                                    byte_phase<= 1'b0;
                                    st        <= ST_SEND_WBYTE;
                                end else if (rleft != 0) begin
                                    // go to repeated start for read
                                    st        <= ST_REP_START_A;
                                end else begin
                                    // no more, go to stop
                                    st        <= ST_STOP_A;
                                end
                            end
                        end
                    end
                end

                // Send write data bytes -> ACK per byte
                ST_SEND_WBYTE: begin
                    if (!byte_phase) begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= byte_tx[bit_idx] ? 1'b1 : 1'b0;
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 0) byte_phase <= 1'b1;
                            else bit_idx <= bit_idx - 1;
                        end
                    end else begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= 1'b1; // release for slave ACK
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            if (sda_in) begin
                                ack_error <= 1'b1;
                                st        <= ST_ERROR;
                            end else begin
                                scl_oe_n <= 1'b0; scl_high <= 1'b0;
                                // decrement remaining
                                wleft <= wleft - 1;
                                if (wleft > 1) begin
                                    // load next
                                    byte_tx   <= wdata_sel( (wlen_l- wleft + 1), (wlen_l-1) );
                                    bit_idx   <= 3'd7;
                                    byte_phase<= 1'b0;
                                    st        <= ST_SEND_WBYTE;
                                end else if (rleft != 0) begin
                                    st        <= ST_REP_START_A;
                                end else begin
                                    st        <= ST_STOP_A;
                                end
                            end
                        end
                    end
                end

                // Repeated START
                ST_REP_START_A: begin
                    // Ensure SDA low while SCL high (Repeated START)
                    if (!scl_high) begin
                        // first raise SCL
                        if (tick) begin scl_oe_n <= 1'b1; scl_high <= 1'b1; end
                    end else if (tick) begin
                        sda_oe_n <= 1'b1; // ensure released high before restart edge
                        // generate START: SDA low while SCL high
                        sda_oe_n <= 1'b0;
                        st       <= ST_REP_START_B;
                    end
                end
                ST_REP_START_B: begin
                    if (tick) begin
                        // pull SCL low and prepare read address
                        scl_oe_n  <= 1'b0; scl_high <= 1'b0;
                        byte_tx   <= {dev_addr_l, 1'b1}; // Addr+R
                        bit_idx   <= 3'd7;
                        byte_phase<= 1'b0;
                        reading   <= 1'b0;
                        st        <= ST_SEND_ADDR_R;
                    end
                end

                // Send address+R -> ACK
                ST_SEND_ADDR_R: begin
                    if (!byte_phase) begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= byte_tx[bit_idx] ? 1'b1 : 1'b0;
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 0) byte_phase <= 1'b1;
                            else bit_idx <= bit_idx - 1;
                        end
                    end else begin
                        if (!scl_high && tick) begin
                            sda_oe_n <= 1'b1; // release for slave ACK
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            if (sda_in) begin
                                ack_error <= 1'b1;
                                st        <= ST_ERROR;
                            end else begin
                                scl_oe_n  <= 1'b0; scl_high <= 1'b0;
                                // start read byte
                                bit_idx   <= 3'd7;
                                byte_phase<= 1'b0;
                                reading   <= 1'b1;
                                st        <= ST_READ_RBYTE;
                            end
                        end
                    end
                end

                // Read N bytes, ACK each except last (NACK)
                ST_READ_RBYTE: begin
                    if (!byte_phase) begin
                        // bit read phase
                        if (!scl_high && tick) begin
                            sda_oe_n <= 1'b1; // release for slave to drive
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            // sample bit
                            rshift <= {rshift[30:0], sda_in};
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            if (bit_idx == 0) begin
                                byte_phase <= 1'b1;
                            end else begin
                                bit_idx <= bit_idx - 1;
                            end
                        end
                    end else begin
                        // Master ACK/NACK
                        if (!scl_high && tick) begin
                            // ACK if more to read, else NACK
                            if (rleft > 1) sda_oe_n <= 1'b0; // ACK=0
                            else           sda_oe_n <= 1'b1; // NACK=1
                            scl_oe_n <= 1'b1; scl_high <= 1'b1;
                        end else if (scl_high && tick) begin
                            // complete ACK/NACK
                            scl_oe_n <= 1'b0; scl_high <= 1'b0;
                            sda_oe_n <= 1'b1; // release
                            rcount   <= rcount + 1;
                            rleft    <= rleft - 1;
                            if (rleft > 1) begin
                                // next byte
                                bit_idx    <= 3'd7;
                                byte_phase <= 1'b0;
                                st         <= ST_READ_RBYTE;
                            } else begin
                                st         <= ST_STOP_A;
                            end
                        end
                    end
                end

                // STOP: while SCL high, release SDA from low to high
                ST_STOP_A: begin
                    // Ensure SDA low before STOP
                    sda_oe_n <= 1'b0;
                    if (!scl_high && tick) begin
                        scl_oe_n <= 1'b1; scl_high <= 1'b1;
                    end else if (scl_high && tick) begin
                        // Release SDA high -> STOP
                        sda_oe_n <= 1'b1;
                        st       <= ST_STOP_B;
                    end
                end
                ST_STOP_B: begin
                    if (tick) begin
                        // Latch read result if any
                        if (rlen_l != 0) begin
                            // Align rshift to MSB-first packing
                            // rshift currently has last byte LSB-aligned; pack to MSB side
                            // Simpler: compute by shifting left so first received byte is at [31:24].
                            // Since we shifted in one bit per sample, rshift holds exactly rcount*8 bits at LSB side.
                            // We pack as:
                            rdata  <= rshift << (32 - (rcount*8));
                            rcount <= rcount; // keep
                            rvalid <= 1'b1;
                        end
                        st   <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    st   <= ST_IDLE;
                end

                ST_ERROR: begin
                    // Generate STOP to free bus
                    // Try to issue STOP quickly: release SDA and SCL
                    sda_oe_n <= 1'b1;
                    scl_oe_n <= 1'b1; scl_high <= 1'b1;
                    if (tick) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        st   <= ST_IDLE;
                    end
                end

                default: st <= ST_IDLE;
            endcase
        end
    end

endmodule
```

```verilog
// BMP085 (GY-65) simple controller: periodically triggers temperature and pressure conversions,
// then reads raw UT (16-bit) and UP (20-bit, aligned) via I2C.
// Note: This module does NOT compute compensated temperature/pressure. It outputs raw UT/UP.
// Parameters:
//  - CLK_FREQ: system clock frequency (Hz)
//  - SAMPLE_MS: period between measurements (ms)
//  - OSS: oversampling setting for pressure (0..3). Affects conversion time and UP bit alignment.
module bmp085_gy65 #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer SAMPLE_MS = 100, // measurement cycle
    parameter integer OSS       = 0    // 0..3
)(
    input  wire        clk,
    input  wire        rst_n,

    // I2C lines
    inout  wire        i2c_scl,
    inout  wire        i2c_sda,

    // Raw outputs
    output reg  [15:0] ut,
    output reg         ut_valid,  // 1-cycle pulse when ut updated

    output reg  [19:0] up,        // right-aligned 20-bit raw pressure
    output reg         up_valid,  // 1-cycle pulse when up updated

    // Status
    output reg         busy_cycle,
    output reg         i2c_error
);

    localparam [6:0] DEV_ADDR = 7'h77;

    // I2C master instance
    wire m_busy, m_done, m_rvalid;
    wire [31:0] m_rdata;
    wire [2:0]  m_rcount;
    reg         m_start;
    reg  [6:0]  m_dev_addr;
    reg  [7:0]  m_reg_addr;
    reg  [1:0]  m_wlen;
    reg  [23:0] m_wdata;
    reg  [2:0]  m_rlen;

    i2c_master_combined #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(100_000)
    ) u_i2c (
        .clk(clk),
        .rst_n(rst_n),
        .start(m_start),
        .dev_addr(m_dev_addr),
        .reg_addr(m_reg_addr),
        .wlen(m_wlen),
        .wdata(m_wdata),
        .rlen(m_rlen),
        .busy(m_busy),
        .done(m_done),
        .ack_error(i2c_error),
        .rdata(m_rdata),
        .rcount(m_rcount),
        .rvalid(m_rvalid),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );

    // Simple timer utilities
    function integer ms_to_cycles(input integer ms);
        ms_to_cycles = (CLK_FREQ/1000) * ms;
    endfunction

    // BMP085 conversion times (datasheet)
    // Temp: 4.5ms; Pressure: depends on OSS
    function integer press_delay_ms(input integer oss);
        case (oss)
            1: press_delay_ms = 8;   // 7.5ms
            2: press_delay_ms = 14;  // 13.5ms
            3: press_delay_ms = 26;  // 25.5ms
            default: press_delay_ms = 5; // 4.5ms
        endcase
    endfunction

    localparam integer TEMP_WAIT_CYC  = ms_to_cycles(5);
    localparam integer PRESS_WAIT_CYC = 1; // computed at runtime for OSS

    reg [31:0] wait_cnt;
    reg [31:0] press_wait_cycles;

    typedef enum logic [3:0] {
        S_IDLE=0,
        S_TRIG_TEMP, S_WAIT_TEMP, S_READ_UT,
        S_TRIG_PRESS, S_WAIT_PRESS, S_READ_UP,
        S_HOLD, S_NEXT
    } st_t;

    st_t st;

    // Periodic trigger
    reg [31:0] sample_cnt;
    localparam integer SAMPLE_CYCLES = (CLK_FREQ/1000) * SAMPLE_MS;

    // Helper
    wire mc_ready = !m_busy;

    // Control FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st         <= S_IDLE;
            m_start    <= 1'b0;
            m_dev_addr <= DEV_ADDR;
            m_reg_addr <= 8'd0;
            m_wlen     <= 2'd0;
            m_wdata    <= 24'd0;
            m_rlen     <= 3'd0;

            ut         <= 16'd0;
            up         <= 20'd0;
            ut_valid   <= 1'b0;
            up_valid   <= 1'b0;
            busy_cycle <= 1'b0;
            i2c_error  <= 1'b0;

            sample_cnt <= 32'd0;
            wait_cnt   <= 32'd0;
            press_wait_cycles <= ms_to_cycles(press_delay_ms(OSS));
        end else begin
            m_start  <= 1'b0;
            ut_valid <= 1'b0;
            up_valid <= 1'b0;

            // sample period counter
            if (!busy_cycle) begin
                if (sample_cnt >= SAMPLE_CYCLES-1) begin
                    sample_cnt <= 32'd0;
                end else begin
                    sample_cnt <= sample_cnt + 1;
                end
            end

            case (st)
                S_IDLE: begin
                    busy_cycle <= 1'b0;
                    if (sample_cnt == SAMPLE_CYCLES-1) begin
                        busy_cycle <= 1'b1;
                        // Trigger temperature conversion: write 0xF4 = 0x2E
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR;
                            m_reg_addr <= 8'hF4;
                            m_wlen     <= 2'd1;
                            m_wdata    <= {16'd0, 8'h2E};
                            m_rlen     <= 3'd0;
                            m_start    <= 1'b1;
                            st         <= S_TRIG_TEMP;
                        end
                    end
                end

                S_TRIG_TEMP: begin
                    if (m_done) begin
                        // start wait for temp
                        wait_cnt <= 32'd0;
                        st       <= S_WAIT_TEMP;
                    end
                end

                S_WAIT_TEMP: begin
                    if (wait_cnt >= TEMP_WAIT_CYC-1) begin
                        // Read UT from 0xF6 (MSB, LSB)
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR;
                            m_reg_addr <= 8'hF6;
                            m_wlen     <= 2'd0;
                            m_rlen     <= 3'd2;
                            m_start    <= 1'b1;
                            st         <= S_READ_UT;
                        end
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                S_READ_UT: begin
                    if (m_done && m_rvalid) begin
                        // rdata packed MSB-first at [31:24] and [23:16]
                        ut       <= {m_rdata[31:24], m_rdata[23:16]};
                        ut_valid <= 1'b1;
                        // Trigger pressure conversion: write 0xF4 = 0x34 | (OSS<<6)
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR;
                            m_reg_addr <= 8'hF4;
                            m_wlen     <= 2'd1;
                            m_wdata    <= {16'd0, (8'h34 | (OSS[1:0] << 6))};
                            m_rlen     <= 3'd0;
                            m_start    <= 1'b1;
                            press_wait_cycles <= ms_to_cycles(press_delay_ms(OSS));
                            st         <= S_TRIG_PRESS;
                        end
                    end
                end

                S_TRIG_PRESS: begin
                    if (m_done) begin
                        wait_cnt <= 32'd0;
                        st       <= S_WAIT_PRESS;
                    end
                end

                S_WAIT_PRESS: begin
                    if (wait_cnt >= press_wait_cycles-1) begin
                        // Read UP: 3 bytes from 0xF6..0xF8
                        if (mc_ready) begin
                            m_dev_addr <= DEV_ADDR;
                            m_reg_addr <= 8'hF6;
                            m_wlen     <= 2'd0;
                            m_rlen     <= 3'd3;
                            m_start    <= 1'b1;
                            st         <= S_READ_UP;
                        end
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                S_READ_UP: begin
                    if (m_done && m_rvalid) begin
                        // UP = ((MSB<<16) | (LSB<<8) | XLSB) >> (8-OSS)
                        // m_rdata: [31:24]=MSB, [23:16]=LSB, [15:8]=XLSB
                        // Align to 20-bit right-aligned number
                        // First build 24-bit:
                        // then shift right by (8-OSS) to get 19..16.. bits; cap to 20 bits.
                        // Keep right-aligned 20-bit.
                        // Use 32-bit intermediate
                        reg [31:0] raw24;
                        raw24 = {m_rdata[31:8], 8'd0} >> (8 - OSS[1:0]); // shift safe
                        up       <= raw24[19:0];
                        up_valid <= 1'b1;
                        st       <= S_NEXT;
                    end
                end

                S_NEXT: begin
                    busy_cycle <= 1'b0;
                    st         <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end

endmodule
```

```verilog
// Basys3 top example to interface BMP085 (GY-65) via I2C.
// - Clock: 100 MHz (Basys3)
// - Reset: btnC active-high (debounce not included)
// - I2C: connect to a Pmod header (SCL,SDA). Ensure 3.3V and GND.
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
    wire        ut_valid;
    wire [19:0] up;
    wire        up_valid;
    wire        busy;
    wire        i2c_err;

    bmp085_gy65 #(
        .CLK_FREQ(100_000_000),
        .SAMPLE_MS(100),
        .OSS(0)
    ) u_gy65 (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .i2c_scl(JA_SCL),
        .i2c_sda(JA_SDA),
        .ut(ut),
        .ut_valid(ut_valid),
        .up(up),
        .up_valid(up_valid),
        .busy_cycle(busy),
        .i2c_error(i2c_err)
    );

    // Display UT on LEDs; blink MSB on new sample
    assign LED = ut;

endmodule
```

```xdc
## Basys3 GY-65 I2C pin constraints (template)
## Choose one Pmod header (JA/JB/JC/JD). Below shows example for JA[1]=SCL, JA[2]=SDA.
## IMPORTANT: Map pins to the correct PACKAGE_PIN using the Basys3 Master XDC.

## I2C SCL
#set_property PACKAGE_PIN <PIN_FOR_JA1> [get_ports { JA_SCL }]
#set_property IOSTANDARD LVCMOS33 [get_ports { JA_SCL }]
#set_property PULLUP true [get_ports { JA_SCL }]

## I2C SDA
#set_property PACKAGE_PIN <PIN_FOR_JA2> [get_ports { JA_SDA }]
#set_property IOSTANDARD LVCMOS33 [get_ports { JA_SDA }]
#set_property PULLUP true [get_ports { JA_SDA }]

## Clock 100 MHz
#set_property PACKAGE_PIN W5 [get_ports { CLK100MHZ }]
#set_property IOSTANDARD LVCMOS33 [get_ports { CLK100MHZ }]
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }]

## Button center as reset
#set_property PACKAGE_PIN U18 [get_ports { btnC }]
#set_property IOSTANDARD LVCMOS33 [get_ports { btnC }]

## LEDs
#set_property PACKAGE_PIN U16 [get_ports { LED[0] }]
#set_property PACKAGE_PIN E19 [get_ports { LED[1] }]
#set_property PACKAGE_PIN U19 [get_ports { LED[2] }]
#set_property PACKAGE_PIN V19 [get_ports { LED[3] }]
#set_property PACKAGE_PIN W18 [get_ports { LED[4] }]
#set_property PACKAGE_PIN U15 [get_ports { LED[5] }]
#set_property PACKAGE_PIN U14 [get_ports { LED[6] }]
#set_property PACKAGE_PIN V14 [get_ports { LED[7] }]
#set_property PACKAGE_PIN V13 [get_ports { LED[8] }]
#set_property PACKAGE_PIN V3  [get_ports { LED[9] }]
#set_property PACKAGE_PIN W3  [get_ports { LED[10] }]
#set_property PACKAGE_PIN U3  [get_ports { LED[11] }]
#set_property PACKAGE_PIN P3  [get_ports { LED[12] }]
#set_property PACKAGE_PIN N3  [get_ports { LED[13] }]
#set_property PACKAGE_PIN P1  [get_ports { LED[14] }]
#set_property PACKAGE_PIN L1  [get_ports { LED[15] }]
#set_property IOSTANDARD LVCMOS33 [get_ports { LED[*] }]
```

---

## 빌드/연결 안내
- 보드 연결: GY-65 VCC(3.3V), GND, SCL, SDA를 Basys3 Pmod의 동일한 헤더 2핀에 연결하세요. GY-65는 풀업 내장(보드 사양 확인).
- 핀 제약: gy65_i2c.xdc에서 JA_SCL/JA_SDA에 실제 Pmod 핀을 지정하세요. Basys-3-Master.xdc를 참고해 PACKAGE_PIN을 채우세요.
- 합성/구현: Vivado에서 gy65_top을 Top으로 설정 후 빌드.

## 질문
- I2C 핀을 어떤 Pmod 헤더(JA/JB/JC/JD)에 연결하실 예정인가요?
- I2C 속도(100 kHz 기본)와 샘플 주기, 압력 OSS(0..3) 설정은 기본값이면 될까요?
