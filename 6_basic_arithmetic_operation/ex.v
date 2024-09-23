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

    //arithmetic
    wire ov_sum;//保存溢位情況
    wire reg1_eq_reg2;//第一個運算元和第二個運算元是否相等
    wire reg1_lt_reg2;//第一個運算元是否小於第二個運算元
    reg [`RegBus] arithmeticres;//保存算術運算的結果
    wire [`RegBus] reg2_i_mux;//保存輸入的第二個運算元reg2_i的補碼
    wire [`RegBus] reg1_i_not;//保存輸入的第一個運算元reg1_i取反後的值
    wire [`RegBus] result_sum;//保存加法運算的結果
    wire [`RegBus] opdata1_mult;//乘法運算的被乘數
    wire [`RegBus] opdata2_mult;//乘法運算的乘數
    wire [`DoubleRegBus] hilo_temp;//暫時保存乘法運算的結果64位
    reg [`DoubleRegBus] mulres;//保存乘法運算的結果64位

    //arithmetic
    //如果是減法或是有號比較運算，那要對第二個運算元取補碼
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                            (aluop_i == `EXE_SUBU_OP) ||
                            (aluop_i == `EXE_SLT_OP)) ?
                            (~reg2_i) + 1 : reg2_i;

    //1.如果是加法運算，reg2_i_mux = reg2_i
    //2.如果是減法運算，reg2_i_mux = reg2_i的補碼
    //3.如果是有號比較運算，reg2_i_mux = reg2_i的補碼，可透過減法結果是否小於0來判斷reg1_i是否小於reg2_i
    assign result_sum = reg1_i + reg2_i_mux;

    //計算是否溢位、add、addi、sub時需要判斷是否溢位滿足下面兩種情況代表溢位
    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||//reg1_i正數、reg2_i_mux正數、結果負數
                        ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));//reg1_i負數、reg2_i_mux負數、結果正數

    //計算reg1_i是否小於reg2_i有兩種情況
    //1.aluop_i為EXE_SLT_OP表示有號比較有3種情況
    //1-1.reg1_i為負數、reg2_i為正數，reg1_i < reg2_i
    //1-2.reg1_i為正數、reg2_i為正數，reg1_i-reg2_i<0，reg1_i < reg2_i
    //1-3.reg1_i為負數、reg2_i為負數，reg1_i-reg2_i<0，reg1_i < reg2_i
    //2.無號數比較時，直接使用比較運算子比較reg1_i和reg2_i
    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
                            ((reg1_i[31] && !reg2_i[31]) ||
                            (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
                            (reg1_i[31] && reg2_i[31] && !result_sum[31])) 
                            : (reg1_i < reg2_i);

    //對reg1_i逐位元取反，並指派給reg1_i_not
    assign reg1_i_not = ~reg1_i;

    always @(*)begin
        if (rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `EXE_SLT_OP, `EXE_SLTU_OP: begin
                    arithmeticres <= reg1_lt_reg2;//比較運算
                end
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
                    arithmeticres <= result_sum;//加法運算
                end
                `EXE_SUB_OP, `EXE_SUBU_OP: begin
                    arithmeticres <= result_sum;//減法運算
                end
                `EXE_CLZ_OP: begin
                    arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 :
                                    reg1_i[29] ? 2 : reg1_i[28] ? 3 :
                                    reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                                    reg1_i[25] ? 6 : reg1_i[24] ? 7 :
                                    reg1_i[23] ? 8 : reg1_i[22] ? 9 :
                                    reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                    reg1_i[19] ? 12 : reg1_i[18] ? 13 :
                                    reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                                    reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                                    reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                                    reg1_i[11] ? 20 : reg1_i[10] ? 21 :
                                    reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                                    reg1_i[7] ? 24 : reg1_i[6] ? 25 :
                                    reg1_i[5] ? 26 : reg1_i[4] ? 27 :
                                    reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                                    reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
                end
                `EXE_CLO_OP: begin
                    arithmeticres <= (reg1_i_not[31] ? 0 :
                                    reg1_i_not[30] ? 1 :
                                    reg1_i_not[29] ? 2 :
                                    reg1_i_not[28] ? 3 :
                                    reg1_i_not[27] ? 4 :
                                    reg1_i_not[26] ? 5 :
                                    reg1_i_not[25] ? 6 :
                                    reg1_i_not[24] ? 7 :
                                    reg1_i_not[23] ? 8 :
                                    reg1_i_not[22] ? 9 :
                                    reg1_i_not[21] ? 10 :
                                    reg1_i_not[20] ? 11 :
                                    reg1_i_not[19] ? 12 :
                                    reg1_i_not[18] ? 13 :
                                    reg1_i_not[17] ? 14 :
                                    reg1_i_not[16] ? 15 :
                                    reg1_i_not[15] ? 16 :
                                    reg1_i_not[14] ? 17 :
                                    reg1_i_not[13] ? 18 :
                                    reg1_i_not[12] ? 19 :
                                    reg1_i_not[11] ? 20 :
                                    reg1_i_not[10] ? 21 :
                                    reg1_i_not[9] ? 22 :
                                    reg1_i_not[8] ? 23 :
                                    reg1_i_not[7] ? 24 :
                                    reg1_i_not[6] ? 25 :
                                    reg1_i_not[5] ? 26 :
                                    reg1_i_not[4] ? 27 :
                                    reg1_i_not[3] ? 28 :
                                    reg1_i_not[2] ? 29 :
                                    reg1_i_not[1] ? 30 :
                                    reg1_i_not[0] ? 31 : 32);
                end
                default: begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end

    //乘法運算
    //取得被乘數，如果是有號乘法且被乘數為負數，則取補碼
    assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
                            && (reg1_i[31] == 1'b1)) ? (~reg1_i) + 1 : reg1_i;

    //取得乘數，如果是有號乘法且乘數為負數，則取補碼
    assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
                            && (reg2_i[31] == 1'b1)) ? (~reg2_i) + 1 : reg2_i;

    //得到臨時的乘法結果
    assign hilo_temp = opdata1_mult * opdata2_mult;

    //對臨時乘法結果進行修正，最終結果存放在mulres
    //1.如果是有號乘法指令mult、mul
    //1-1.如果乘數和被乘數一正一負，那須對hilo_temp取補碼
    //1-2.如果乘數和被乘數同號，那hilo_temp就是最終結果
    //2.如果是無號乘法指令multu，那hilo_temp就是最終結果
    always @(*)begin
        if (rst == `RstEnable)begin
            mulres <= {`ZeroWord, `ZeroWord};
        end
        else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))begin
            if (reg1_i[31] ^ reg2_i[31] == 1'b1)begin
                mulres <= ~hilo_temp + 1;
            end
            else begin
                mulres <= hilo_temp;
            end
        end
        else begin
            mulres <= hilo_temp;
        end
    end

    //arithmetic結束

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
        //wd_o和wreg_o來自id階段
        //如果是add、addi、sub、subi且發生溢位，那wreg_o = WriteDisable
        if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
            (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1))begin
            wreg_o <= `WriteDisable;
            end
        else begin
            wreg_o <= wreg_i;//是否要寫入暫存器
        end

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
            `EXE_RES_ARITHMETIC: begin
                wdata_o <= arithmeticres;//算術運算的結果當作最終結果
            end
            `EXE_RES_MUL: begin
                wdata_o <= mulres[31:0];//乘法運算的結果當作最終結果
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
        else if ((aluop_i == `EXE_MULT_OP) ||
                    (aluop_i == `EXE_MULTU_OP))begin//mult、multu指令
            whilo_o <= `WriteEnable;
            hi_o <= mulres[63:32];
            lo_o <= mulres[31:0];
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