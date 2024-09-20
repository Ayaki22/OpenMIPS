`include "defines.v"

module ex_mem(
    input clk,
    input rst,

    //從ex傳來的資料
    input [`RegAddrBus] ex_wd,
    input ex_wreg,
    input [`RegBus] ex_wdata,

    //輸出至mem的資料
    output reg [`RegAddrBus] mem_wd,
    output reg mem_wreg,
    output reg [`RegBus] mem_wdata
);

    always @(posedge clk)begin
        if (rst == `RstEnable)begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
        end
        else begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
        end
    end

endmodule