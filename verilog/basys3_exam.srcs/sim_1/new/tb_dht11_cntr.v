`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/18/2025 12:14:39 PM
// Design Name: 
// Module Name: tb_dht11_cntr
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

// Testbench dht11_cnrt
module tb_dht11_cntr ();
    localparam [7:0] humi_value = 8'd70;
    localparam [7:0] tmpr_value = 8'd25;
    localparam [7:0] check_sum = humi_value + tmpr_value;
    localparam [39:0] data = {humi_value, 8'b0, tmpr_value, 8'b0, check_sum};

    // input → reg, output → wire
    reg clk, reset_p;
    wire [7:0] humidity, temperature;

    // for inout, Using Buffer
    reg dout, wr_e;
    tri1 dht11_data;                            // wire with Pull-Up
    assign dht11_data = wr_e ? dout : 'bz;      // Write Mode Output dout, Input Impedance Value

    // Connect in Order
    dht11_cntr dut (clk, reset_p, dht11_data, humidity, temperature);

    initial begin                               // Reset
        clk = 0;
        reset_p = 1;
        wr_e = 0;
    end

    always #5 clk = ~clk;                       // Create Clock, Low 5ns + High 5ns = 10ns

    integer i;

    initial begin
        #10;
        reset_p = 0; #10;
        wait(!dht11_data);                      // Start bit
        wait(dht11_data);                       // Pull Up Voltage
        #20_000;
        dout = 0; wr_e = 1; #80_000;            // Write Mode, DHT11 Send Out Response
        wr_e = 0; #80_000;                      // Pull-Up, High
        wr_e = 1;                               // Write Mode
        for (i = 0; i < 40; i = i + 1) begin    // DHT11 Data 40-bit Send
            dout = 0; #50_000;                  // Start Send to 1-bit Data
            dout = 1;
            if (data[39-i]) #70_000;            // Data 1, Voltage Length 70us
            else #27_000;                       // Data 0, Voltage Length 27us
        end
        dout = 0; #10;                          // Send End
        wr_e = 0; #1_000;                       // Check the Results
        $stop;                                  // humi_value, tmpr_value Check Value Correct
    end
endmodule