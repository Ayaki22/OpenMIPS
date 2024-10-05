`include "defines.v"

module ctrl(
    input rst,
    input stallreq_from_id,
    input stallreq_from_ex,

    input stallreq_from_if,
    input stallreq_from_mem,

    //from MEM
    input [31:0] excepttype_i,
    input [`RegBus] cp0_epc_i,

    output reg [`RegBus] new_pc,
    output reg flush,

    output reg [5:0] stall
    //stall[0]代表PC stall[1]代表IF stall[2]代表ID stall[3]代表EX stall[4]代表MEM stall[5]代表WB
);
    always @(*)begin
        if (rst == `RstEnable)begin
            stall <= 6'b000000;
            flush <= 1'b0;
            new_pc <= `ZeroWord;
        end
        else if (excepttype_i != `ZeroWord)begin//不為0表示有異常
            flush <= 1'b1;
            stall <= 6'b000000;
            case (excepttype_i)
                32'h00000001: begin//中斷
                    new_pc <= 32'h00000020;
                end
                32'h00000008: begin//系統呼叫異常syscall
                    new_pc <= 32'h00000040;
                end
                32'h0000000a: begin//無效指令異常
                    new_pc <= 32'h00000040;
                end
                32'h0000000d: begin//自陷異常
                    new_pc <= 32'h00000040;
                end
                32'h0000000c: begin//溢位異常
                    new_pc <= 32'h00000040;
                end
                32'h0000000e: begin//異常返回指令eret
                    new_pc <= cp0_epc_i;
                end
                default: begin

                end
            endcase
        end
        else if (stallreq_from_mem == `Stop)begin
            stall <= 6'b011111;
            flush <= 1'b0;
        end
        else if (stallreq_from_ex == `Stop)begin
            stall <= 6'b001111;
            flush <= 1'b0;
        end
        else if (stallreq_from_id == `Stop)begin
            stall <= 6'b000111;
            flush <= 1'b0;
        end
        else if (stallreq_from_if == `Stop)begin
            stall <= 6'b000111;
            flush <= 1'b0;
        end
        else begin
            stall <= 6'b000000;
            flush <= 1'b0;
            new_pc <= `ZeroWord;
        end
    end

endmodule