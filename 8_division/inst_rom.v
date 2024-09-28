`include "defines.v"

module inst_rom(
    input ce,
    input [`InstAddrBus] addr,
    output reg [`InstBus] inst
);

    reg [`InstBus] inst_mem[0:`InstMemNum-1];

    initial $readmemh("inst_rom.data", inst_mem);

    always @(*) begin
        if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end
        else begin
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];//右移2
            //讀取0xC的指令，對應ROM的inst_mem[3]
        end
    end

endmodule