module rom(
    input ce,
    input [5:0] addr,

    output reg [31:0] inst
);

reg [31:0] rom [63:0];

initial $readmemh("rom.data", rom);

always @(*)
    inst <= (ce) ? rom[addr] : 32'h0;

endmodule