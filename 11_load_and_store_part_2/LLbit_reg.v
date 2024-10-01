`include "defines.v"

module LLbit_reg(
    input clk,
    input rst,

    input flush,//異常發生時為1

    //write
    input LLbit_i,
    input we,

    //LLbit reg
    output reg LLbit_o
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            LLbit_o <= 1'b0;
        end
        else if ((flush == 1'b1)) begin
            LLbit_o <= 1'b0;
        end
        else if (we == `WriteEnable) begin
            LLbit_o <= LLbit_i;
        end
    end
    

endmodule