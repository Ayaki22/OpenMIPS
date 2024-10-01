`include "defines.v"

module pc_reg(
    input clk,
    input rst,
    input [5:0] stall,

    //from ID
    input branch_flag_i,
    input [`RegBus] branch_target_address_i,

    output reg [`InstAddrBus] pc,
    output reg ce
);

    always @(posedge clk)begin
        if (rst == `RstEnable)begin
            ce <= `ChipDisable;
        end
        else begin
            ce <= `ChipEnable;
        end
    end

    always @(posedge clk)begin
        if (ce == `ChipDisable)begin
            pc <= 32'h00000000;
        end
        else if (stall[0] == `NoStop)begin
            if (branch_flag_i == `Branch)begin
                pc <= branch_target_address_i;
            end
            else begin
                pc <= pc + 4'h4;
            end
        end
    end

endmodule