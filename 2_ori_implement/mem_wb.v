`include "defines.v"

//和mem.v很像，但是mem.v是組合邏輯，mem_wb.v是時序邏輯
module mem_wb(
    input clk,
    input rst,

    //存取mem的結果
    input [`RegAddrBus] mem_wd,
    input mem_wreg,
    input [`RegBus] mem_wdata,

    //輸出至wb的資料
    output reg [`RegAddrBus] wb_wd,
    output reg wb_wreg,
    output reg [`RegBus] wb_wdata
);

    always @(posedge clk)begin
        if (rst == `RstEnable)begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
        end
        else begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;
        end
    end

endmodule