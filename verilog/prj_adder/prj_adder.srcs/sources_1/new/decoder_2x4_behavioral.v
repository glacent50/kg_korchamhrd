`timescale 1ns / 1ps

module decoder_2x4_behavioral(
    input [1:0] code,
    output reg [3:0] signal
);

    always @(*) begin
        case (code)
            2'b00: signal = 4'b0001;
            2'b01: signal = 4'b0010;
            2'b10: signal = 4'b0100;
            2'b11: signal = 4'b1000;
            default: signal = 4'b0000;
        endcase
    end

endmodule
