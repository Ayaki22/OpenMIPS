`include "defines.v"

module id_ex(
    input clk,
    input rst,
    input [5:0] stall,

    //從id傳來的資料
    input [`AluOpBus] id_aluop,//從id要執行的運算的子類型
    input [`AluSelBus] id_alusel,//從id要執行的運算的類型
    input [`RegBus] id_reg1,
    input [`RegBus] id_reg2,
    input [`RegAddrBus] id_wd,//從id要寫入的目的暫存器位址
    input id_wreg,//從id是否要寫入暫存器
    input [`RegBus] id_link_address,
    input id_is_in_delayslot,
    input next_inst_in_delayslot_i,

    //輸出至ex
    output reg [`AluOpBus] ex_aluop,
    output reg [`AluSelBus] ex_alusel,
    output reg [`RegBus] ex_reg1,
    output reg [`RegBus] ex_reg2,
    output reg [`RegAddrBus] ex_wd,
    output reg ex_wreg,

    //輸出至pc
    output reg [`RegBus] ex_link_address,
    output reg ex_is_in_delayslot,
    output reg is_in_delayslot_o
);

    always @(posedge clk)begin
        if (rst == `RstEnable)begin
            ex_aluop <= `EXE_NOP_OP;
            ex_alusel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;
            ex_link_address <= `ZeroWord;
            ex_is_in_delayslot <= `NotInDelaySlot;
            is_in_delayslot_o <= `NotInDelaySlot;
        end
        else if (stall[2] == `Stop && stall[3] == `NoStop)begin
            ex_aluop <= `EXE_NOP_OP;
            ex_alusel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;
            ex_link_address <= `ZeroWord;
            ex_is_in_delayslot <= `NotInDelaySlot;
        end
        else if (stall[2] == `NoStop)begin
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_wd <= id_wd;
            ex_wreg <= id_wreg;
            ex_link_address <= id_link_address;
            ex_is_in_delayslot <= id_is_in_delayslot;
            is_in_delayslot_o <= next_inst_in_delayslot_i;
        end
    end

endmodule