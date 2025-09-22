// Basys3 Top for GY-65 (BMP085/180) I2C sensor
// - 100MHz system clock
// - btnC: reset (active high)
// - btnU: toggle display mode (UT vs UP)
// - JA1: I2C SCL (inout, open-drain with board pullups)
// - JA2: I2C SDA (inout)
// - LED: show UT[15:0] or UP[19:4]

module gy65_top (
    input  wire        CLK100MHZ,  // Basys3 시스템 클럭 (100MHz)
    input  wire        btnC,       // 중앙 버튼 (리셋)
    input  wire        btnU,       // 상단 버튼 (디스플레이 모드 변경)

    // I2C 라인 (Pmod 헤더에 연결)
    inout  wire        JA1,        // SCL 라인
    inout  wire        JA2,        // SDA 라인

    // 출력 표시
    output wire [15:0] LED,        // 16개 LED 배열
    output wire [3:0]  AN,         // 7-세그먼트 애노드 (미사용)
    output wire [6:0]  SEG,        // 7-세그먼트 세그먼트 (미사용)
    output wire        DP          // 7-세그먼트 소수점 (미사용)
);
    // 리셋 신호 생성 (버튼은 눌렸을 때 HIGH)
    wire rst_n = ~btnC;

    // BMP085 센서 데이터
    wire [15:0] ut;         // 원시 온도 데이터 (16비트)
    wire        ut_valid;   // 온도 데이터 유효 신호
    wire [19:0] up;         // 원시 압력 데이터 (20비트)
    wire        up_valid;   // 압력 데이터 유효 신호
    wire        busy_cycle; // 측정 사이클 중 표시
    wire        i2c_error;  // I2C 에러 표시

    // 표시 모드 (버튼으로 전환): 0=온도, 1=압력
    reg display_mode;
    reg [25:0] btn_debounce_cnt;
    reg btn_prev;

    // 버튼 디바운싱 및 모드 전환
    always @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            display_mode      <= 1'b0;
            btn_debounce_cnt  <= 26'd0;
            btn_prev          <= 1'b0;
        end else begin
            if (btn_debounce_cnt != 26'd0) begin
                btn_debounce_cnt <= btn_debounce_cnt - 26'd1;
            end else if (btnU != btn_prev) begin
                btn_prev <= btnU;
                if (btnU) begin
                    display_mode     <= ~display_mode;  // 모드 전환
                    btn_debounce_cnt <= 26'd5_000_000;  // 약 50ms 디바운스
                end
            end
        end
    end

    // 데이터 래치 (유효한 값 유지)
    reg [15:0] latched_ut;
    reg [19:0] latched_up;

    always @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            latched_ut <= 16'h0000;
            latched_up <= 20'h00000;
        end else begin
            if (ut_valid) latched_ut <= ut;
            if (up_valid) latched_up <= up;
        end
    end

    // LED 출력 설정 (압력은 상위 16비트로 축약 표시)
    assign LED = display_mode ? latched_up[19:4] : latched_ut;

    // 7-세그먼트 표시기 미사용
    assign AN  = 4'b1111;      // 모든 디지트 비활성화
    assign SEG = 7'b111_1111;  // 모든 세그먼트 꺼짐
    assign DP  = 1'b1;         // 소수점 꺼짐

    // BMP085 센서 제어 모듈 인스턴스 (주기적 측정 수행)
    bmp085_gy65 #(
        .CLK_FREQ (100_000_000),  // 100 MHz
        .SAMPLE_MS(100),          // 100ms 샘플링 주기
        .OSS      (0)             // 오버샘플링 설정 (0: 표준)
    ) u_gy65 (
        .clk       (CLK100MHZ),
        .rst_n     (rst_n),
        .i2c_scl   (JA1),
        .i2c_sda   (JA2),
        .ut        (ut),
        .ut_valid  (ut_valid),
        .up        (up),
        .up_valid  (up_valid),
        .busy_cycle(busy_cycle),
        .i2c_error (i2c_error)
    );

    // 선택: i2c_error 또는 busy_cycle을 LED와 결합해 상태 시각화 가능
    // 예) assign LED[15] = i2c_error;

endmodule
