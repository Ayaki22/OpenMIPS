`include "defines.v"

module regfile(
    input clk,
    input rst,
    input we,//write enable
    input [`RegAddrBus] waddr,//write address
    input [`RegBus] wdata,//write data

    input re1,//read enable 1
    input [`RegAddrBus] raddr1,//read address 1
    output reg [`RegBus] rdata1,//read data 1

    input re2,//read enable 2
    input [`RegAddrBus] raddr2,//read address 2
    output reg [`RegBus] rdata2//read data 2
);

    //32-32 bit register 
    reg [`RegBus] regs[0:`RegNum-1];

    //write data
    always @(posedge clk)begin
        if (rst == `RstDisable)begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0))begin//可寫且不是$0
                regs[waddr] <= wdata;
            end
        end
    end

    //read port 1
    always @(*)begin
        if (rst == `RstEnable)begin
            rdata1 <= `ZeroWord;
        end
        else if (raddr1 == `RegNumLog2'h0)begin//如果讀取$0
            rdata1 <= `ZeroWord;
        end
        else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))begin//如果讀取的是寫入的暫存器
            rdata1 <= wdata;
        end
        else if (re1 == `ReadEnable)begin//如果讀取的是其他暫存器
            rdata1 <= regs[raddr1];
        end
        else begin//如果不讀取
            rdata1 <= `ZeroWord;
        end
    end

    //read port 2
    always @(*)begin
        if (rst == `RstEnable)begin
            rdata2 <= `ZeroWord;
        end
        else if (raddr2 == `RegNumLog2'h0)begin//如果讀取$0
            rdata2 <= `ZeroWord;
        end
        else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))begin//如果讀取的是寫入的暫存器
            rdata2 <= wdata;
        end
        else if (re2 == `ReadEnable)begin//如果讀取的是其他暫存器
            rdata2 <= regs[raddr2];
        end
        else begin//如果不讀取
            rdata2 <= `ZeroWord;
        end
    end

endmodule