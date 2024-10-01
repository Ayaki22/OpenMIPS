`include "defines.v"

module ex_mem(
    input clk,
    input rst,
    input [5:0] stall,

    //從ex傳來的資料
    input [`RegAddrBus] ex_wd,
    input ex_wreg,
    input [`RegBus] ex_wdata,
    input [`RegBus] ex_hi,
    input [`RegBus] ex_lo,
    input ex_whilo,
    input [`DoubleRegBus] hilo_i,
    input [1:0] cnt_i,
    input [`AluOpBus] ex_aluop,
    input [`RegBus] ex_mem_addr,
    input [`RegBus] ex_reg2,

    input ex_cp0_reg_we,
    input [4:0] ex_cp0_reg_write_addr,
    input [`RegBus] ex_cp0_reg_data,

    //輸出至mem的資料
    output reg mem_cp0_reg_we,
    output reg [4:0] mem_cp0_reg_write_addr,
    output reg [`RegBus] mem_cp0_reg_data,

    output reg [`RegAddrBus] mem_wd,
    output reg mem_wreg,
    output reg [`RegBus] mem_wdata,
    output reg [`RegBus] mem_hi,
    output reg [`RegBus] mem_lo,
    output reg mem_whilo,
    output reg [`DoubleRegBus] hilo_o,
    output reg [1:0] cnt_o,
    output reg [`AluOpBus] mem_aluop,
    output reg [`RegBus] mem_mem_addr,
    output reg [`RegBus] mem_reg2
);

    always @(posedge clk)begin
        if (rst == `RstEnable)begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
            mem_aluop <= `EXE_NOP_OP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
            mem_cp0_reg_we <= `WriteDisable;
            mem_cp0_reg_write_addr <= 5'b00000;
            mem_cp0_reg_data <= `ZeroWord;
        end
        else if (stall[3] == `Stop && stall[4] == `NoStop)begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            mem_whilo <= `WriteDisable;
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;
            mem_aluop <= `EXE_NOP_OP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
            mem_cp0_reg_we <= `WriteDisable;
            mem_cp0_reg_write_addr <= 5'b00000;
            mem_cp0_reg_data <= `ZeroWord;
        end
        else if (stall[3] == `NoStop)begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;
            mem_whilo <= ex_whilo;
            hilo_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
            mem_aluop <= ex_aluop;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;
            //在EXE階段沒有暫停時，將對CP0中暫存器的寫入資訊傳到MEM階段
            mem_cp0_reg_we <= ex_cp0_reg_we;
            mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
            mem_cp0_reg_data <= ex_cp0_reg_data;
        end
        else begin
            hilo_o <= hilo_i;
            cnt_o <= cnt_i;
        end
    end

endmodule