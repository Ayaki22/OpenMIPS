`include "defines.v"

module openmips_min_sopc(
    input clk,
    input rst
);

    wire [`InstAddrBus] inst_addr;
    wire [`InstBus] inst;
    wire rom_ce;

    wire mem_we_i;
    wire[`RegBus] mem_addr_i;
    wire[`RegBus] mem_data_i;
    wire[`RegBus] mem_data_o;
    wire[3:0] mem_sel_i;  
    wire mem_ce_i;
    wire [5:0] int;
    wire timer_int;

    assign int = {5'b00000, timer_int};

    openmips openmips0(
        .clk(clk),
        .rst(rst),

        .rom_data_i(inst),//從指令記憶體取得的指令
        .rom_addr_o(inst_addr),//輸出至指令記憶體的位置
        .rom_ce_o(rom_ce),//指令記憶體啟用訊號

        .int_i(int),//中斷輸入

        .ram_we_o(mem_we_i),
		.ram_addr_o(mem_addr_i),
		.ram_sel_o(mem_sel_i),
		.ram_data_o(mem_data_i),
		.ram_data_i(mem_data_o),
		.ram_ce_o(mem_ce_i),

        .timer_int_o(timer_int)//時脈中斷輸出
    );

    inst_rom inst_rom0(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );

    data_ram data_ram0(
		.clk(clk),
		.we(mem_we_i),
		.addr(mem_addr_i),
		.sel(mem_sel_i),
		.data_i(mem_data_i),
		.data_o(mem_data_o),
		.ce(mem_ce_i)		
	);

endmodule