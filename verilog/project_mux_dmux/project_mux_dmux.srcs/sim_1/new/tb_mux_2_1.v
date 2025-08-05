`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 03:49:35 PM
// Design Name: 
// Module Name: tb_mux_2_1
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


module tb_mux_2_1;
    reg [1:0] d;
    reg s;
    wire f;

    mux_2_1 uut(
        .d(d),
        .s(s),
        .f(f)
    );


    initial begin
        $monitor("time = %0t | s=%b | d=%b | f=%b ", $time, s, d, f);

        d = 2'b10; s = 0 ; #10;
                   s = 1 ; #10;
        d = 2'b01; s = 0 ; #10;
                   s = 1 ; #10;
    end
    
endmodule

module tb_mux_8_1;

    reg [7:0] d;
    reg [2:0] s;
    wire f;
    
    mux_8_1 uut(
        .d(d),
        .s(s),
        .f(f)
    );
    
    initial begin
        $monitor("time = %0t | s=%b | d=%b | f=%b", $time, s, d, f);
        
        // Test case 1: Select first input (s=000)
        d = 8'b10101010; s = 3'b000; #10;
        // Test case 2: Select second input (s=001)
        d = 8'b10101010; s = 3'b001; #10;
        // Test case 3: Select third input (s=010)
        d = 8'b10101010; s = 3'b010; #10;
        // Test case 4: Select fourth input (s=011)
        d = 8'b10101010; s = 3'b011; #10;
        // Test case 5: Select fifth input (s=100)
        d = 8'b10101010; s = 3'b100; #10;
        // Test case 6: Select sixth input (s=101)
        d = 8'b10101010; s = 3'b101; #10;
        // Test case 7: Select seventh input (s=110)
        d = 8'b10101010; s = 3'b110; #10;
        // Test case 8: Select eighth input (s=111)
        d = 8'b10101010; s = 3'b111; #10;
        
        // Additional test with different data pattern
        d = 8'b11001100; s = 3'b010; #10;
        d = 8'b00110011; s = 3'b110; #10;
    end
    
endmodule


module tb_mux_4_1;
    reg [3:0] d;    // 4개 데이터 입력
    reg [1:0] s;    // 2비트 선택 신호
    wire f;         // 출력

    // mux_4_1_structual 모듈 인스턴스화
    mux_4_1_structual uut(
        .d(d),
        .s(s),
        .f(f)
    );
    
    initial begin
        $monitor("time = %0t | s=%b | d=%b | f=%b", $time, s, d, f);
        
        // 테스트 케이스 1: 첫 번째 입력 선택 (s=00)
        d = 4'b1010; s = 2'b00; #10;
        // 테스트 케이스 2: 두 번째 입력 선택 (s=01)
        d = 4'b1010; s = 2'b01; #10;
        // 테스트 케이스 3: 세 번째 입력 선택 (s=10)
        d = 4'b1010; s = 2'b10; #10;
        // 테스트 케이스 4: 네 번째 입력 선택 (s=11)
        d = 4'b1010; s = 2'b11; #10;
        
        // 다른 데이터 패턴으로 추가 테스트
        d = 4'b0101; s = 2'b00; #10;
        d = 4'b0101; s = 2'b01; #10;
        d = 4'b0101; s = 2'b10; #10;
        d = 4'b0101; s = 2'b11; #10;
    end
    
endmodule

module tb_demux_1_4;

    reg d;
    reg [1:0] s;
    wire [3:0] f;

    demux_1_4_d uut(
        .d(d),
        .s(s),
        .f(f)
    );

    initial begin
        $monitor("time = %0t | d=%b | s=%b | f=%b", $time, d, s, f);
        
        // Test case 1: Route to first output (s=00)
        d = 1'b1; s = 2'b00; #10;
        // Test case 2: Route to second output (s=01)
        d = 1'b1; s = 2'b01; #10;
        // Test case 3: Route to third output (s=10)
        d = 1'b1; s = 2'b10; #10;
        // Test case 4: Route to fourth output (s=11)
        d = 1'b1; s = 2'b11; #10;
        
        // Additional test with data = 0
        d = 1'b0; s = 2'b00; #10;
        d = 1'b0; s = 2'b11; #10;
    end
    
endmodule


module tb_mux_demux_test;

    reg [3:0] d;        // mux input
    reg [1:0] mux_s;    // mux signal
    reg [1:0] demux_s;  // demux signal

    wire [3:0] f;       // output

    mux_demux_test uut(
        .d(d),
        .mux_s(mux_s),
        .demux_s(demux_s),
        .f(f)
    );
    
    initial begin
        $display("Time\t d\t    mux_s\t  demux_s\t  | f\t");
        $monitor("%0t    d=%b   mux_s=%b demux_s=%b | f=%b", $time, d, mux_s, demux_s, f);
        
        // d 입력값 설정
        d = 4'b1010;

        mux_s = 2'b00; demux_s = 2'b00; #10;      // d[0]->f[0]
        mux_s = 2'b01; demux_s = 2'b01; #10;      // d[1]->f[1]
        mux_s = 2'b10; demux_s = 2'b10; #10;      // d[2]->f[2]
        mux_s = 2'b11; demux_s = 2'b11; #10;      // d[3]->f[3]

        // 다르게
        mux_s = 2'b11; demux_s = 2'b00; #10;
        mux_s = 2'b00; demux_s = 2'b11; #10;
        

        $finish;
    end
    
endmodule