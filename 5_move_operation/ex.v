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

    //HILO暫存器的值
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,

    //WB階段的指令是否寫入HI、LO，檢測HI、LO的相依問題
    input [`RegBus] wb_hi_i,
    input [`RegBus] wb_lo_i,
    input wb_whilo_i,

    //MEM階段的指令是否寫入HI、LO，檢測HI、LO的相依問題
    input [`RegBus] mem_hi_i,
    input [`RegBus] mem_lo_i,
    input mem_whilo_i,

    //EX階段對HI、LO的寫入請求
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,

    //執行結果
    output reg [`RegAddrBus] wd_o,//要寫入的目的暫存器位址
    output reg wreg_o,//是否要寫入暫存器
    output reg [`RegBus] wdata_o//exe階段要寫入目的暫存器的值
);

    reg [`RegBus] logicout;//保存邏輯運算的結果
    reg [`RegBus] shiftres;//保存位移運算的結果
    reg [`RegBus] moveres;//移動操作的結果
    reg [`RegBus] HI;//暫存HI的值
    reg [`RegBus] LO;//暫存LO的值

    //得到最新的HI、LO的值，解決資料相依問題
    always @(*)begin
        if (rst == `RstEnable)begin
            {HI, LO} <= {`ZeroWord, `ZeroWord};
        end
        else if (mem_whilo_i == `WriteEnable)begin
            {HI, LO} <= {mem_hi_i, mem_lo_i};//mem階段要寫入HI、LO
        end
        else if (wb_whilo_i == `WriteEnable)begin
            {HI, LO} <= {wb_hi_i, wb_lo_i};//wb階段要寫入HI、LO
        end
        else begin
            {HI, LO} <= {hi_i, lo_i};
        end
    end

    //MFHI、MFLO、MOVN、MOVZ指令
    always @(*)begin
        if (rst == `RstEnable)begin
            moveres <= `ZeroWord;
        end
        else begin
            moveres <= `ZeroWord;
            case (aluop_i)
                `EXE_MFHI_OP: begin
                    moveres <= HI;//將HI的值作為移動操作的結果
                end
                `EXE_MFLO_OP: begin
                    moveres <= LO;//將LO的值作為移動操作的結果
                end
                `EXE_MOVZ_OP: begin
                    moveres <= reg1_i;//MOVZ指令，將reg1_i的值作為移動操作的結果
                end
                `EXE_MOVN_OP: begin
                    moveres <= reg1_i;//MOVN指令，將reg1_i的值作為移動操作的結果
                end
                default: begin
                end
            endcase
        end
    end

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
            `EXE_RES_MOVE: begin
                wdata_o <= moveres;//移動操作的結果當作最終結果
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end

    //如果是MTHI、MTLO指令，那要給出WHILO_O、hi_o、lo_o的值
    always @(*)begin
        if (rst == `RstEnable)begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else if (aluop_i == `EXE_MTHI_OP)begin
            whilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;
        end
        else if (aluop_i == `EXE_MTLO_OP)begin
            whilo_o <= `WriteEnable;
            hi_o <= HI;
            lo_o <= reg1_i;
        end
        else begin
            whilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
    end

endmodule