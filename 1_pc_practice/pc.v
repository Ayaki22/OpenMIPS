module pc_reg(
    input clk,
    input rst,
    
    output reg [5:0] pc,
    output reg ce
);

always @(posedge clk or posedge rst) begin
    ce <= (rst) ? 1'b0 : 1'b1;
    pc <= (ce) ? pc + 1'b1 : 6'h0;
end

endmodule