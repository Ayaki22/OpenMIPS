`include "defines.v"

module pc_reg(
    input clk,
    input rst,
    output reg [`InstAddrBus] pc,
    output reg ce
);

    always @(posedge clk)
        ce <= (rst == `RstEnable) ? `ChipDisable : `ChipEnable;

    always @(posedge clk)
        pc <= (ce == `ChipDisable) ? 32'h00000000 : pc + 4'h4;

endmodule