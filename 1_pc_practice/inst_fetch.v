module inst_fetch(
    input clk,
    input rst,
    
    output [31:0] inst_o
);

wire [5:0] pc;
wire rom_ce;

pc_reg pc0(
    .clk(clk),
    .rst(rst),
    
    .pc(pc),
    .ce(rom_ce)
);

rom rom0(
    .ce(rom_ce),
    .addr(pc),

    .inst(inst_o)
);

endmodule