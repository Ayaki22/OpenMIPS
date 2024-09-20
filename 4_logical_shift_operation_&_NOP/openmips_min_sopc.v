`include "defines.v"

module openmips_min_sopc(
    input clk,
    input rst
);

    wire [`InstAddrBus] inst_addr;
    wire [`InstBus] inst;
    wire rom_ce;

    openmips openmips0(
        .clk(clk),
        .rst(rst),
        .rom_data_i(inst),//從指令記憶體取得的指令
        .rom_addr_o(inst_addr),//輸出至指令記憶體的位置
        .rom_ce_o(rom_ce)//指令記憶體啟用訊號
    );

    inst_rom inst_rom0(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );

endmodule