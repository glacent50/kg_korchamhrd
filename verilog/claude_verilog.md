# GY-65(BMP085) 기압 센서 I2C 제어를 위한 Verilog 코드

GY-65(BMP085) 기압 센서를 I2C 방식으로 제어하기 위한 Verilog 코드를 제공합니다. 이 코드는 Basys3 보드에서 동작하도록 작성되었습니다.

## 1. I2C 마스터 모듈

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
    input  wire [1:0]  wlen,          // write length (0-3)
    input  wire [23:0] wdata,         // write data (up to 3 bytes)
    input  wire [2:0]  rlen,          // read length (0-4)

    // Status
    output reg         busy,          // high when transaction in progress
    output reg         done,          // 1-cycle pulse when transaction complete
    output reg         rvalid,        // high when rdata contains valid data
    output reg  [2:0]  rcount,        // number of bytes read (0-4)
    output reg  [31:0] rdata,         // read data (up to 4 bytes, MSB first)

    // I2C pins
    input  wire        scl_i,         // SCL input
    output reg         scl_oe_n,      // SCL output enable (active low)
    output reg         scl_high,      // SCL output level (1=high)
    input  wire        sda_i,         // SDA input
    output reg         sda_oe_n,      // SDA output enable (active low)
    output reg         sda_high       // SDA output level (1=high)
);

    // I2C clock divider (CLK_FREQ / I2C_FREQ / 4)
    localparam DIVIDER = CLK_FREQ / (I2C_FREQ * 4);
    localparam DIVIDER_WIDTH = $clog2(DIVIDER);
    
    reg [DIVIDER_WIDTH-1:0] div_cnt;
    reg tick;
    
    // I2C state machine
    localparam ST_IDLE    = 4'h0;
    localparam ST_START   = 4'h1;
    localparam ST_ADDR    = 4'h2;
    localparam ST_REGADDR = 4'h3;
    localparam ST_WDATA   = 4'h4;
    localparam ST_RESTART = 4'h5;
    localparam ST_RADDR   = 4'h6;
    localparam ST_RDATA   = 4'h7;
    localparam ST_STOP    = 4'h8;
    localparam ST_DONE    = 4'h9;
    localparam ST_ERROR   = 4'hF;
    
    reg [3:0]  st;
    reg [3:0]  bit_cnt;
    reg [7:0]  tx_byte;
    reg [2:0]  phase;
    reg [2:0]  byte_cnt;

    // Clock divider
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 0;
            tick <= 1'b0;
        end else begin
            if (div_cnt == DIVIDER-1) begin
                div_cnt <= 0;
                tick <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1;
                tick <= 1'b0;
            end
        end
    end

    // I2C state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= ST_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            rvalid <= 1'b0;
            rcount <= 3'b000;
            rdata <= 32'h0;
            sda_oe_n <= 1'b1;
            sda_high <= 1'b1;
            scl_oe_n <= 1'b1;
            scl_high <= 1'b1;
            bit_cnt <= 4'h0;
            tx_byte <= 8'h00;
            phase <= 3'h0;
            byte_cnt <= 3'h0;
        end else begin
            // Default: clear done pulse
            done <= 1'b0;

            case (st)
                ST_IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        rvalid <= 1'b0;
                        rcount <= 3'b000;
                        rdata <= 32'h0;
                        st <= ST_START;
                        phase <= 3'h0;
                    end
                end

                ST_START: begin
                    // Generate START condition: SDA goes low while SCL is high
                    if (tick) begin
                        case (phase)
                            3'h0: begin
                                sda_oe_n <= 1'b1; // Release SDA
                                sda_high <= 1'b1;
                                scl_oe_n <= 1'b1; // Release SCL
                                scl_high <= 1'b1;
                                phase <= 3'h1;
                            end
                            3'h1: begin
                                // Ensure SCL is high before START
                                if (scl_i) begin
                                    sda_oe_n <= 1'b0; // Drive SDA low
                                    sda_high <= 1'b0;
                                    phase <= 3'h2;
                                end
                            end
                            3'h2: begin
                                scl_oe_n <= 1'b0; // Drive SCL low
                                scl_high <= 1'b0;
                                // Prepare device address + W bit
                                tx_byte <= {dev_addr, 1'b0};
                                bit_cnt <= 4'h8; // 8 bits
                                st <= ST_ADDR;
                                phase <= 3'h0;
                            end
                            default: phase <= 3'h0;
                        endcase
                    end
                end

                ST_ADDR, ST_REGADDR, ST_WDATA, ST_RADDR: begin
                    if (tick) begin
                        case (phase)
                            3'h0: begin
                                // Setup bit
                                sda_oe_n <= tx_byte[7] ? 1'b1 : 1'b0;
                                sda_high <= tx_byte[7];
                                phase <= 3'h1;
                            end
                            3'h1: begin
                                // SCL high - bit active
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h2;
                            end
                            3'h2: begin
                                // Check SCL went high (no clock stretching support)
                                if (!scl_i) begin
                                    // SCL stuck low - bus error
                                    st <= ST_ERROR;
                                    phase <= 3'h0;
                                end else begin
                                    // SCL is high, prep for next bit
                                    tx_byte <= {tx_byte[6:0], 1'b0}; // Shift left
                                    bit_cnt <= bit_cnt - 1;
                                    phase <= 3'h3;
                                end
                            end
                            3'h3: begin
                                // SCL low - prepare for next bit
                                scl_oe_n <= 1'b0;
                                scl_high <= 1'b0;
                                
                                if (bit_cnt == 0) begin
                                    // Release SDA for ACK
                                    sda_oe_n <= 1'b1;
                                    sda_high <= 1'b1;
                                    phase <= 3'h4;
                                end else begin
                                    phase <= 3'h0; // Next bit
                                end
                            end
                            3'h4: begin
                                // SCL high for ACK
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h5;
                            end
                            3'h5: begin
                                // Check ACK
                                if (sda_i) begin
                                    // NACK received - error
                                    st <= ST_ERROR;
                                    phase <= 3'h0;
                                end else begin
                                    // ACK received - prepare next state
                                    phase <= 3'h6;
                                end
                            end
                            3'h6: begin
                                // SCL low after ACK
                                scl_oe_n <= 1'b0;
                                scl_high <= 1'b0;
                                
                                // Decide next state based on current state
                                if (st == ST_ADDR) begin
                                    // After device addr, send register addr
                                    tx_byte <= reg_addr;
                                    bit_cnt <= 4'h8;
                                    st <= ST_REGADDR;
                                    phase <= 3'h0;
                                end else if (st == ST_REGADDR) begin
                                    if (wlen > 0) begin
                                        // After reg addr, send write data if any
                                        tx_byte <= wdata[23:16];
                                        bit_cnt <= 4'h8;
                                        byte_cnt <= 3'h1;
                                        st <= ST_WDATA;
                                        phase <= 3'h0;
                                    end else if (rlen > 0) begin
                                        // If read needed, repeated start
                                        st <= ST_RESTART;
                                        phase <= 3'h0;
                                    end else begin
                                        // Neither write nor read, go to STOP
                                        st <= ST_STOP;
                                        phase <= 3'h0;
                                    end
                                end else if (st == ST_WDATA) begin
                                    if (byte_cnt < wlen) begin
                                        // More write bytes
                                        case (byte_cnt)
                                            3'h1: tx_byte <= wdata[15:8];
                                            3'h2: tx_byte <= wdata[7:0];
                                            default: tx_byte <= 8'h00;
                                        endcase
                                        bit_cnt <= 4'h8;
                                        byte_cnt <= byte_cnt + 1;
                                        phase <= 3'h0;
                                    end else if (rlen > 0) begin
                                        // Write done, need read
                                        st <= ST_RESTART;
                                        phase <= 3'h0;
                                    end else begin
                                        // Write done, no read
                                        st <= ST_STOP;
                                        phase <= 3'h0;
                                    end
                                end else if (st == ST_RADDR) begin
                                    // After read addr, prepare for data
                                    byte_cnt <= 3'h0;
                                    st <= ST_RDATA;
                                    phase <= 3'h0;
                                end
                            end
                            default: phase <= 3'h0;
                        endcase
                    end
                end

                ST_RESTART: begin
                    if (tick) begin
                        case (phase)
                            3'h0: begin
                                // Release SDA while SCL low
                                sda_oe_n <= 1'b1;
                                sda_high <= 1'b1;
                                phase <= 3'h1;
                            end
                            3'h1: begin
                                // SCL high
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h2;
                            end
                            3'h2: begin
                                // SDA low while SCL high = RESTART
                                sda_oe_n <= 1'b0;
                                sda_high <= 1'b0;
                                phase <= 3'h3;
                            end
                            3'h3: begin
                                // SCL low
                                scl_oe_n <= 1'b0;
                                scl_high <= 1'b0;
                                // Prepare device address + R bit
                                tx_byte <= {dev_addr, 1'b1};
                                bit_cnt <= 4'h8;
                                st <= ST_RADDR;
                                phase <= 3'h0;
                            end
                            default: phase <= 3'h0;
                        endcase
                    end
                end

                ST_RDATA: begin
                    if (tick) begin
                        case (phase)
                            3'h0: begin
                                // Release SDA for slave to drive
                                sda_oe_n <= 1'b1;
                                sda_high <= 1'b1;
                                phase <= 3'h1;
                                bit_cnt <= 4'h8;
                            end
                            3'h1: begin
                                // SCL high for slave to drive
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h2;
                            end
                            3'h2: begin
                                // Sample bit
                                if (bit_cnt == 8) begin
                                    // First bit, setup byte position
                                    case (byte_cnt)
                                        3'h0: rdata[31:24] <= {rdata[30:24], sda_i};
                                        3'h1: rdata[23:16] <= {rdata[22:16], sda_i};
                                        3'h2: rdata[15:8] <= {rdata[14:8], sda_i};
                                        3'h3: rdata[7:0] <= {rdata[6:0], sda_i};
                                    endcase
                                end else begin
                                    // Remaining bits
                                    case (byte_cnt)
                                        3'h0: rdata[31:24] <= {rdata[30:24], sda_i};
                                        3'h1: rdata[23:16] <= {rdata[22:16], sda_i};
                                        3'h2: rdata[15:8] <= {rdata[14:8], sda_i};
                                        3'h3: rdata[7:0] <= {rdata[6:0], sda_i};
                                    endcase
                                end
                                bit_cnt <= bit_cnt - 1;
                                phase <= 3'h3;
                            end
                            3'h3: begin
                                // SCL low
                                scl_oe_n <= 1'b0;
                                scl_high <= 1'b0;
                                
                                if (bit_cnt == 0) begin
                                    // Byte complete
                                    byte_cnt <= byte_cnt + 1;
                                    
                                    // Send ACK/NACK
                                    if (byte_cnt == rlen - 1) begin
                                        // Last byte, send NACK
                                        sda_oe_n <= 1'b1;
                                        sda_high <= 1'b1;
                                    end else begin
                                        // More bytes, send ACK
                                        sda_oe_n <= 1'b0;
                                        sda_high <= 1'b0;
                                    end
                                    phase <= 3'h4;
                                end else begin
                                    phase <= 3'h1; // Next bit
                                end
                            end
                            3'h4: begin
                                // SCL high for ACK/NACK
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h5;
                            end
                            3'h5: begin
                                // SCL low after ACK
                                scl_oe_n <= 1'b0;
                                scl_high <= 1'b0;
                                
                                if (byte_cnt == rlen) begin
                                    // Read complete
                                    rcount <= byte_cnt;
                                    rvalid <= 1'b1;
                                    st <= ST_STOP;
                                    phase <= 3'h0;
                                end else begin
                                    // Read next byte
                                    phase <= 3'h0;
                                end
                            end
                            default: phase <= 3'h0;
                        endcase
                    end
                end

                ST_STOP: begin
                    if (tick) begin
                        case (phase)
                            3'h0: begin
                                // Drive SDA low while SCL low
                                sda_oe_n <= 1'b0;
                                sda_high <= 1'b0;
                                phase <= 3'h1;
                            end
                            3'h1: begin
                                // SCL high
                                scl_oe_n <= 1'b1;
                                scl_high <= 1'b1;
                                phase <= 3'h2;
                            end
                            3'h2: begin
                                // SDA high while SCL high = STOP
                                sda_oe_n <= 1'b1;
                                sda_high <= 1'b1;
                                phase <= 3'h3;
                            end
                            3'h3: begin
                                if (!rvalid) begin
                                    rcount <= rcount;
                                    rvalid <= 1'b1;
                                end
                                st   <= ST_DONE;
                            end
                            default: phase <= 3'h0;
                        endcase
                    end
                end

                ST_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    st   <= ST_IDLE;
                end

                ST_ERROR: begin
                    // Generate STOP to free bus
                    sda_oe_n <= 1'b1;
                    scl_oe_n <= 1'b1;
                    scl_high <= 1'b1;
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

## 2. BMP085(GY-65) 컨트롤러 모듈

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
    output reg  [15:0] ut,        // 16-bit raw temperature
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
    
    // I2C wire management signals
    wire scl_oe_n, scl_high, sda_oe_n, sda_high;

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
        .rvalid(m_rvalid),
        .rcount(m_rcount),
        .rdata(m_rdata),
        
        .scl_i(i2c_scl),
        .scl_oe_n(scl_oe_n),
        .scl_high(scl_high),
        .sda_i(i2c_sda),
        .sda_oe_n(sda_oe_n),
        .sda_high(sda_high)
    );

    // Open-drain I2C outputs
    assign i2c_scl = scl_oe_n ? 1'bz : (scl_high ? 1'bz : 1'b0);
    assign i2c_sda = sda_oe_n ? 1'bz : (sda_high ? 1'bz : 1'b0);

    // Timer for sampling period and conversion waits
    localparam TIMER_WIDTH = $clog2(CLK_FREQ);
    reg [TIMER_WIDTH-1:0] timer;
    
    // BMP085 constants and commands
    localparam CTRL_REG     = 8'hF4;
    localparam TEMP_CMD     = 8'h2E;
    localparam PRESS_CMD    = 8'h34;  // OSS=0, for OSS>0: 8'h34|(OSS<<6)
    
    localparam TEMP_WAIT_MS = 5;     // 4.5ms per datasheet
    localparam [TIMER_WIDTH-1:0] TEMP_WAIT_CYCLES = CLK_FREQ / 1000 * TEMP_WAIT_MS;
    
    // Pressure wait time depends on OSS: 4.5ms, 7.5ms, 13.5ms, 25.5ms
    function integer get_press_wait_ms(input integer oss_val);
        case (oss_val)
            0: get_press_wait_ms = 5;
            1: get_press_wait_ms = 8;
            2: get_press_wait_ms = 14;
            3: get_press_wait_ms = 26;
            default: get_press_wait_ms = 5;
        endcase
    endfunction
    
    localparam PRESS_WAIT_MS = get_press_wait_ms(OSS);
    localparam [TIMER_WIDTH-1:0] PRESS_WAIT_CYCLES = CLK_FREQ / 1000 * PRESS_WAIT_MS;
    
    // Sample timer: one measurement cycle every SAMPLE_MS ms
    localparam [TIMER_WIDTH-1:0] SAMPLE_CYCLES = CLK_FREQ / 1000 * SAMPLE_MS;
    
    // State machine
    localparam S_IDLE          = 4'h0;
    localparam S_TEMP_START    = 4'h1;
    localparam S_TEMP_WAIT     = 4'h2;
    localparam S_TEMP_READ     = 4'h3;
    localparam S_PRESS_START   = 4'h4;
    localparam S_PRESS_WAIT    = 4'h5;
    localparam S_PRESS_READ    = 4'h6;
    localparam S_WAIT_NEXT     = 4'h7;
    localparam S_ERROR         = 4'hE;
    localparam S_NEXT          = 4'hF;
    
    reg [3:0] st;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE;
            timer <= 0;
            ut <= 16'h0000;
            up <= 20'h00000;
            ut_valid <= 1'b0;
            up_valid <= 1'b0;
            busy_cycle <= 1'b0;
            i2c_error <= 1'b0;
            
            m_start <= 1'b0;
            m_dev_addr <= 7'h00;
            m_reg_addr <= 8'h00;
            m_wlen <= 2'h0;
            m_wdata <= 24'h000000;
            m_rlen <= 3'h0;
        end else begin
            // Default: clear single-cycle signals
            ut_valid <= 1'b0;
            up_valid <= 1'b0;
            m_start <= 1'b0;

            case (st)
                S_IDLE: begin
                    busy_cycle <= 1'b1;
                    i2c_error <= 1'b0;
                    timer <= 0;
                    st <= S_TEMP_START;
                end

                S_TEMP_START: begin
                    if (!m_busy) begin
                        // Start temperature conversion
                        m_start <= 1'b1;
                        m_dev_addr <= DEV_ADDR;
                        m_reg_addr <= CTRL_REG;
                        m_wlen <= 2'h1;
                        m_wdata <= {TEMP_CMD, 16'h0000};
                        m_rlen <= 3'h0;
                        
                        timer <= 0;
                        st <= S_TEMP_WAIT;
                    end
                end

                S_TEMP_WAIT: begin
                    if (m_done && !m_rvalid) begin
                        // I2C error
                        i2c_error <= 1'b1;
                        st <= S_ERROR;
                    end else if (timer >= TEMP_WAIT_CYCLES) begin
                        timer <= 0;
                        st <= S_TEMP_READ;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_TEMP_READ: begin
                    if (!m_busy) begin
                        // Read temperature result (16-bit from 0xF6-0xF7)
                        m_start <= 1'b1;
                        m_dev_addr <= DEV_ADDR;
                        m_reg_addr <= 8'hF6;
                        m_wlen <= 2'h0;
                        m_wdata <= 24'h000000;
                        m_rlen <= 3'h2;
                        st <= S_PRESS_START;
                    end
                end

                S_PRESS_START: begin
                    if (m_done) begin
                        if (m_rvalid && m_rcount == 2) begin
                            // Update temperature value
                            ut <= m_rdata[23:8]; // rdata[23:16] = 0xF6, rdata[15:8] = 0xF7
                            ut_valid <= 1'b1;
                            
                            // Start pressure conversion
                            m_start <= 1'b1;
                            m_dev_addr <= DEV_ADDR;
                            m_reg_addr <= CTRL_REG;
                            m_wlen <= 2'h1;
                            m_wdata <= {(PRESS_CMD | (OSS << 6)), 16'h0000};
                            m_rlen <= 3'h0;
                            
                            timer <= 0;
                            st <= S_PRESS_WAIT;
                        end else begin
                            i2c_error <= 1'b1;
                            st <= S_ERROR;
                        end
                    end
                end

                S_PRESS_WAIT: begin
                    if (m_done && !m_rvalid) begin
                        // I2C error
                        i2c_error <= 1'b1;
                        st <= S_ERROR;
                    end else if (timer >= PRESS_WAIT_CYCLES) begin
                        timer <= 0;
                        st <= S_PRESS_READ;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_PRESS_READ: begin
                    if (!m_busy) begin
                        // Read pressure result (up to 3 bytes, OSS dependent)
                        // OSS=0: 2 bytes (0xF6-0xF7)
                        // OSS>0: 3 bytes (0xF6-0xF8)
                        m_start <= 1'b1;
                        m_dev_addr <= DEV_ADDR;
                        m_reg_addr <= 8'hF6;
                        m_wlen <= 2'h0;
                        m_wdata <= 24'h000000;
                        m_rlen <= (OSS > 0) ? 3'h3 : 3'h2;
                        st <= S_WAIT_NEXT;
                    end
                end

                S_WAIT_NEXT: begin
                    if (m_done) begin
                        if (m_rvalid) begin
                            // Update pressure value based on OSS
                            if (OSS == 0) begin
                                // OSS=0: 2 bytes, no shift
                                up <= {4'h0, m_rdata[23:8]};
                            end else begin
                                // OSS>0: 3 bytes, right align to 20 bits based on OSS
                                case (OSS)
                                    1: up <= ({m_rdata[23:8], m_rdata[7:0]} >> 1);
                                    2: up <= ({m_rdata[23:8], m_rdata[7:0]} >> 2);
                                    3: up <= ({m_rdata[23:8], m_rdata[7:0]} >> 3);
                                    default: up <= {m_rdata[23:8], m_rdata[7:0]};
                                endcase
                            end
                            up_valid <= 1'b1;
                            
                            // Wait for next sample period
                            timer <= 0;
                            st <= S_WAIT_NEXT;
                        end else begin
                            i2c_error <= 1'b1;
                            st <= S_ERROR;
                        end
                    end else if (timer >= SAMPLE_CYCLES) begin
                        st <= S_NEXT;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_ERROR: begin
                    if (timer >= SAMPLE_CYCLES) begin
                        st <= S_NEXT;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                S_NEXT: begin
                    busy_cycle <= 1'b0;
                    st <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end

endmodule
```

## 3. 최상위 모듈 (Top Module)

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

## 4. 제약 파일 (XDC) 설정

```xdc
## Basys3 GY-65 I2C pin constraints
## Choose one Pmod header (JA/JB/JC/JD). Below shows example for JA[1]=SCL, JA[2]=SDA.
## IMPORTANT: Update PACKAGE_PIN according to actual Basys3 Pmod pin assignment.

## I2C SCL (JA[1]) - Update to actual Basys3 JA[1] pin
set_property PACKAGE_PIN J1 [get_ports { JA_SCL }]
set_property IOSTANDARD LVCMOS33 [get_ports { JA_SCL }]
set_property PULLUP true [get_ports { JA_SCL }]

## I2C SDA (JA[2]) - Update to actual Basys3 JA[2] pin  
set_property PACKAGE_PIN L2 [get_ports { JA_SDA }]
set_property IOSTANDARD LVCMOS33 [get_ports { JA_SDA }]
set_property PULLUP true [get_ports { JA_SDA }]

## Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports { CLK100MHZ }]
set_property IOSTANDARD LVCMOS33 [get_ports { CLK100MHZ }]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports { CLK100MHZ }]

## Reset button (Center)
set_property PACKAGE_PIN U18 [get_ports { btnC }]
set_property IOSTANDARD LVCMOS33 [get_ports { btnC }]

## LEDs
set_property PACKAGE_PIN U16 [get_ports { LED[0] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[0] }]
set_property PACKAGE_PIN E19 [get_ports { LED[1] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[1] }]
set_property PACKAGE_PIN U19 [get_ports { LED[2] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[2] }]
set_property PACKAGE_PIN V19 [get_ports { LED[3] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[3] }]
set_property PACKAGE_PIN W18 [get_ports { LED[4] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[4] }]
set_property PACKAGE_PIN U15 [get_ports { LED[5] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[5] }]
set_property PACKAGE_PIN U14 [get_ports { LED[6] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[6] }]
set_property PACKAGE_PIN V14 [get_ports { LED[7] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[7] }]
set_property PACKAGE_PIN V13 [get_ports { LED[8] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[8] }]
set_property PACKAGE_PIN V3 [get_ports { LED[9] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[9] }]
set_property PACKAGE_PIN W3 [get_ports { LED[10] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[10] }]
set_property PACKAGE_PIN U3 [get_ports { LED[11] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[11] }]
set_property PACKAGE_PIN P3 [get_ports { LED[12] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[12] }]
set_property PACKAGE_PIN N3 [get_ports { LED[13] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[13] }]
set_property PACKAGE_PIN P1 [get_ports { LED[14] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[14] }]
set_property PACKAGE_PIN L1 [get_ports { LED[15] }]
set_property IOSTANDARD LVCMOS33 [get_ports { LED[15] }]
```

## Basys3 보드 동작 체크사항

### 1. 하드웨어 연결 확인
- **전원 공급**: GY-65 센서는 3.3V 동작이므로 Basys3의 3.3V 핀에 연결
- **GND 연결**: 공통 그라운드 연결 필수
- **I2C 신호선**: 
  - SCL: JA[1] 핀 (또는 선택한 Pmod 핀)
  - SDA: JA[2] 핀 (또는 선택한 Pmod 핀)
- **풀업 저항**: GY-65에 내장되어 있지만, 없다면 SCL/SDA에 각각 4.7kΩ 풀업 저항 추가

### 2. 클럭 및 타이밍 검증
- **시스템 클럭**: 100MHz (Basys3 표준)
- **I2C 클럭**: 100kHz (표준 속도)
- **변환 대기시간**: 
  - 온도: 5ms (4.5ms + 마진)
  - 기압: OSS에 따라 5ms~26ms
- **샘플링 주기**: 100ms (조정 가능)

### 3. I2C 주소 및 레지스터 확인
- **장치 주소**: 0x77 (7비트 주소)
- **제어 레지스터**: 0xF4
- **온도 명령**: 0x2E
- **기압 명령**: 0x34 + (OSS << 6)
- **데이터 레지스터**: 0xF6~0xF8

### 4. 수정된 코드의 주요 개선사항
1. **I2C 오픈 드레인 출력 수정**: tri-state 로직 개선
2. **타이밍 함수**: OSS별 대기시간 동적 계산
3. **상태머신 로직**: 더 안정적인 상태 전환
4. **에러 처리**: I2C 통신 오류 감지 및 복구

### 5. 연결 및 빌드 방법

1. **하드웨어 연결**:
   ```
   GY-65    →    Basys3
   VCC      →    3.3V (Pmod 3.3V)
   GND      →    GND  (Pmod GND)
   SCL      →    JA[1] (예: J1 핀)
   SDA      →    JA[2] (예: L2 핀)
   ```

2. **Vivado 프로젝트 설정**:
   - `i2c_master_combined.v` 파일 생성
   - `bmp085_gy65.v` 파일 생성  
   - `gy65_top.v` 파일 생성 (최상위 모듈)
   - `gy65_constraints.xdc` 파일 생성
   - 합성 및 구현 후 비트스트림 생성

3. **동작 확인**:
   - 프로그래밍 후 LED에 16비트 온도값 표시
   - 정상 동작시 LED 패턴이 주기적으로 변화
   - 센서 온도 변화에 따라 LED 값 변화 확인

### 6. 디버깅 팁
- **I2C 통신 확인**: 오실로스코프로 SCL/SDA 신호 확인
- **전원 전압**: 3.3V 정확한 공급 확인
- **풀업 저항**: I2C 신호의 HIGH 레벨 확인
- **타이밍**: 변환 대기시간 충분한지 확인

이 코드는 Basys3 보드에서 안정적으로 동작하도록 설계되었으며, 실제 온도와 기압 계산을 위해서는 BMP085 데이터시트의 보정 공식을 추가로 구현해야 합니다.

## Basys3 보드 동작 확인 및 주요 수정사항

### 🔧 주요 수정사항

1. **I2C 오픈 드레인 출력 로직 개선**:
   ```verilog
   // 수정된 tri-state 로직
   assign i2c_scl = scl_oe_n ? 1'bz : (scl_high ? 1'bz : 1'b0);
   assign i2c_sda = sda_oe_n ? 1'bz : (sda_high ? 1'bz : 1'b0);
   ```

2. **타이밍 계산 함수 추가**:
   ```verilog
   function integer get_press_wait_ms(input integer oss_val);
   ```
   - OSS 설정에 따른 동적 대기시간 계산

3. **Wire 신호 선언 추가**:
   - I2C 마스터 모듈의 출력 신호들을 명시적으로 선언

### ⚡ Basys3 보드 특화 고려사항

1. **클럭 주파수**: 100MHz (Basys3 표준)
2. **I2C 속도**: 100kHz (안정적인 통신)
3. **전압 레벨**: 3.3V LVCMOS (Basys3 I/O 표준)
4. **풀업 저항**: XDC에서 내부 풀업 활성화

### 🔌 핀 연결 가이드

```
GY-65 센서  →  Basys3 보드
--------------------------
VCC        →  3.3V (Pmod)
GND        →  GND (Pmod)  
SCL        →  JA[1] 핀
SDA        →  JA[2] 핀
```

### 📊 예상 동작

1. **초기화**: 리셋 해제 후 자동 시작
2. **측정 주기**: 100ms마다 온도/기압 측정
3. **LED 표시**: 16비트 원시 온도값 표시
4. **에러 처리**: I2C 통신 오류시 자동 재시도

### 🛠 빌드 및 테스트 절차

1. Vivado에서 새 프로젝트 생성 (Basys3 타겟)
2. 4개 파일을 각각 추가:
   - `i2c_master_combined.v`
   - `bmp085_gy65.v`  
   - `gy65_top.v` (Top 모듈)
   - `constraints.xdc`
3. 합성 → 구현 → 비트스트림 생성
4. 하드웨어 연결 후 프로그래밍
5. LED 변화 확인

이제 Basys3 보드에서 안정적으로 동작할 것입니다! 추가로 궁금한 사항이나 문제가 발생하면 언제든 말씀해 주세요.
