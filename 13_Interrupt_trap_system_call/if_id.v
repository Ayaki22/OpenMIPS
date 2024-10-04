`include "defines.v"

module if_id(
    input clk,
    input rst,
    input [`InstAddrBus] if_pc,
    input [`InstBus] if_inst,
    input [5:0] stall,

    //for Exception related instructions
    input flush,

    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);

    always @(posedge clk)
        if (rst == `RstEnable)begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (flush == 1'b1)begin//清除管線
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (stall[1] == `Stop && stall[2] == `NoStop)begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (stall[1] == `NoStop)begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end

endmodule