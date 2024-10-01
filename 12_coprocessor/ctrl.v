`include "defines.v"

module ctrl(
    input rst,
    input stallreq_from_id,
    input stallreq_from_ex,
    output reg [5:0] stall
    //stall[0]代表PC stall[1]代表IF stall[2]代表ID stall[3]代表EX stall[4]代表MEM stall[5]代表WB
);
    always @(*)begin
        if (rst == `RstEnable)begin
            stall <= 6'b000000;
        end
        else if (stallreq_from_ex == `Stop)begin
            stall <= 6'b001111;
        end
        else if (stallreq_from_id == `Stop)begin
            stall <= 6'b000111;
        end
        else begin
            stall <= 6'b000000;
        end
    end

endmodule