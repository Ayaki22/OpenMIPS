module inst_fetch_tb;
reg CLOCK;
reg rst;
wire [31:0] inst;

initial begin
    CLOCK = 1'b0;
    forever #10 CLOCK = ~CLOCK;
end

initial begin
    rst = 1'b1;
    #195 rst = 1'b0;
    #1000 $stop;
end

inst_fetch inst_fetch0(
    .clk(CLOCK),
    .rst(rst),
    
    .inst_o(inst)
);

initial begin
    $monitor($time, "inst = %h",inst);
end

initial begin
    $dumpfile("inst_fetch.vcd");
    $dumpvars;
end
endmodule