`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 09:22:24 AM
// Design Name: 
// Module Name: comparator
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


module comparator_dataflow(
    input a, b,             // 입력 a, b (각 1비트)
    output equal,           // a == b --> 1
    output greater,         // a > b  --> 1
    output less            // a < b  --> 1
    );

    assign equal =    (a == b) ? 1'b1 : 1'b0;  // a와 b가 같은면 equal  = 1
    assign greater =  (a > b)  ? 1'b1 : 1'b0;
    assign less =     (a < b)  ? 1'b1 : 1'b0;
endmodule


module comparator_structural (
    input a, b,
    output equal, greater, less
);
    // equal = (~a & ~b) | (a & b)
    // greater = a & ~b
    // less = ~a & b

    wire nota, notb;
    wire a_and_b, nota_and_notb;
    wire a_and_notb, nota_and_b;

    not (nota, a);  // nota = ~a
    not (notb, b);  // notb = ~b

    and (nota_and_notb, nota, notb);      // ~a & ~b
    and (a_and_b, a, b);                  // a & b
    or  (equal, nota_and_notb, a_and_b);  // equal = (~a & ~b) | (a & b)

    and (greater, a, notb);            // a & ~b
    and (less, nota, b);               // ~a & b

endmodule


module comparator_behavioral (
    input a, b,
    output reg equal, greater, less
);
    
    always @(a, b) begin
        equal = 0;
        greater = 0;
        less = 0;

        if (a == b)
            equal = 1;
        else if (a > b)
            greater = 1;
        else 
            less = 1;
    end

endmodule

// N bit Comparator
// use dataflow modudle
module comparator_Nbit #(parameter N = 8) (
    input [N-1:0] a, b,
    output equal,
    output greater,
    output less
);
    assign equal = (a==b) ? 1'b1 : 1'b0;
    assign greater = (a>b) ? 1'b1 : 1'b0;
    assign less = (a<b) ? 1'b1 : 1'b0;

endmodule



module comparator_test_4bit (
    input [3:0] a, b,
    output equal,
    output greater,
    output less
);

comparator_Nbit # (.N(4)) test(
    .a(a),
    .b(b),
    .equal(equal),
    .greater(greater),
    .less(less)
);
    
endmodule


module comparator_Nbit_behavioral #(parameter N=8)(
    input [N-1:0] a, b,
    output reg equal, greater, less
);

always @(*) begin
    equal = 0;
    greater = 0;
    less = 0;

    if (a == b) begin
        equal = 1;
    end
    else if ( a > b) begin
        greater = 1;
    end
    else if ( a < b) begin
        less = 1;
    end
end
    
endmodule