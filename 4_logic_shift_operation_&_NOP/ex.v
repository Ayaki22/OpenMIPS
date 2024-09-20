`include "defines.v"

module ex(
    input rst,

    //從id傳來的資料
    input [`AluOpBus] aluop_i,//exe階段要進行的運算的子類型
    input [`AluSelBus] alusel_i,//exe階段要進行的運算的類型
    input [`RegBus] reg1_i,
    input [`RegBus] reg2_i,
    input [`RegAddrBus] wd_i,//exe階段要寫入的目的暫存器位址
    input wreg_i,//exe階段是否要寫入暫存器

    //執行結果
    output reg [`RegAddrBus] wd_o,//要寫入的目的暫存器位址
    output reg wreg_o,//是否要寫入暫存器
    output reg [`RegBus] wdata_o//exe階段要寫入目的暫存器的值
);

    reg [`RegBus] logicout;//保存邏輯運算的結果
    reg [`RegBus] shiftres;//保存位移運算的結果

    //依據aluop_i指示的運算子類型進行邏輯運算
    always @(*)begin
        if (rst == `RstEnable)begin
            logicout <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logicout <= reg1_i | reg2_i;//運算結果先存這裡
                end
                `EXE_AND_OP: begin
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_NOR_OP: begin
                    logicout <= ~(reg1_i | reg2_i);
                end
                `EXE_XOR_OP: begin
                    logicout <= reg1_i ^ reg2_i;
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end

    //依據aluop_i指示的運算子類型進行位移運算
    always @(*)begin
        if (rst == `RstEnable)begin
            shiftres <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_SLL_OP: begin//邏輯左移
                    shiftres <= reg2_i << reg1_i[4:0];
                end
                `EXE_SRL_OP: begin//邏輯右移
                    shiftres <= reg2_i >> reg1_i[4:0];
                end
                `EXE_SRA_OP: begin//算術右移
                    shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]}))
                    | reg2_i >> reg1_i[4:0];
                end
                default: begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end
    end

    //依據alusel_i指示的運算類型，選擇一個運算結果作為最終結果
    always @(*)begin
        wd_o <= wd_i;//要寫入的目標暫存器位址
        wreg_o <= wreg_i;//是否要寫入暫存器
        //wd_o和wreg_o來自id階段
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;//邏輯運算的結果當作最終結果
            end
            `EXE_RES_SHIFT: begin
                wdata_o <= shiftres;//位移運算的結果當作最終結果
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule