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
    input [`RegBus] inst_i,

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

    input [`DoubleRegBus] hilo_temp_i,
    input [1:0] cnt_i,

    input [`DoubleRegBus] div_result_i,
    input div_ready_i,

    input [`RegBus] link_address_i,//處於執行階段的轉移指令要保存的返回地址
    input is_in_delayslot_i,//目前執行階段是否在延遲槽中

    //MEM階段的指令是否要寫入CP0暫存器，檢測資料相依問題
    input mem_cp0_reg_we,
    input [4:0] mem_cp0_reg_write_addr,
    input [`RegBus] mem_cp0_reg_data,

    //WB階段的指令是否要寫入CP0暫存器，檢測資料相依問題
    input wb_cp0_reg_we,
    input [4:0] wb_cp0_reg_write_addr,
    input [`RegBus] wb_cp0_reg_data,

    //與CP0相接，讀取其中指定暫存器的值
    input [`RegBus] cp0_reg_data_i,
    output reg [4:0] cp0_reg_read_addr_o,

    //pipeline下一級傳遞，寫入CP0指定暫存器
    output reg cp0_reg_we_o,
    output reg [4:0] cp0_reg_write_addr_o,
    output reg [`RegBus] cp0_reg_data_o,

    //EX階段對HI、LO的寫入請求
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,

    //執行結果
    output reg [`RegAddrBus] wd_o,//要寫入的目的暫存器位址
    output reg wreg_o,//是否要寫入暫存器
    output reg [`RegBus] wdata_o,//exe階段要寫入目的暫存器的值

    //for load、store
    output [`AluOpBus] aluop_o,
    output [`RegBus] mem_addr_o,
    output [`RegBus] reg2_o,

    output reg [`DoubleRegBus] hilo_temp_o,
    output reg [1:0] cnt_o,

    output reg [`RegBus] div_opdata1_o,
    output reg [`RegBus] div_opdata2_o,
    output reg div_start_o,
    output reg signed_div_o,

    output reg stallreq
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
    reg [`DoubleRegBus] hilo_temp1;//暫時保存乘法運算的結果64位
    reg stallreq_for_madd_msub;
    reg stallreq_for_div;

    //輸出DIV module 控制資訊、獲得輸出結果
    always @(*) begin
        if (rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end
        else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
            case (aluop_i)
                `EXE_DIV_OP: begin//div指令
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;//被除數
                        div_opdata2_o <= reg2_i;//除數
                        div_start_o <= `DivStart;//開始執行除法
                        signed_div_o <= 1'b1;//有號除法
                        stallreq_for_div <= `Stop;//暫停管線
                    end
                    else if (div_ready_i == `DivResultReady)begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;//結束除法運算
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;//不暫停管線
                    end
                    else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                `EXE_DIVU_OP: begin//divu指令
                    if (div_ready_i == `DivResultNotReady)begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;//無號除法
                        stallreq_for_div <= `Stop;
                    end
                    else if (div_ready_i == `DivResultReady)begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                    else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                default: begin
                end
            endcase
        end
    end

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

    //aluop_o會傳遞到MEM階段，來確認load、store指令的類型
    assign aluop_o = aluop_i;

    //load、store指令對應的記憶體位址
    //reg1_i是base的通用暫存器的值，inst[15:0]是offset
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};

    //reg2_i是儲存指令要儲存的資料，或lwl、lwr指令要載入到目的暫存器的原始值
    assign reg2_o = reg2_i;

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
    assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || 
                            (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) ||
                            (aluop_i == `EXE_MSUB_OP)) &&
                            (reg1_i[31] == 1'b1)) ? (~reg1_i) + 1 : reg1_i;

    //取得乘數，如果是有號乘法且乘數為負數，則取補碼
    assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || 
                            (aluop_i == `EXE_MULT_OP) ||
                            (aluop_i == `EXE_MADD_OP) ||
                            (aluop_i == `EXE_MSUB_OP)) &&
                            (reg2_i[31] == 1'b1)) ? (~reg2_i) + 1 : reg2_i;

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
        else if ((aluop_i == `EXE_MULT_OP) || 
                (aluop_i == `EXE_MUL_OP) ||
                (aluop_i == `EXE_MADD_OP) ||
                (aluop_i == `EXE_MSUB_OP))begin
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

    //乘累加、乘累減指令
    //MADD、MADDU、MSUB、MSUBU指令
    always @(*)begin
        if (rst == `RstEnable)begin
            hilo_temp_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
            stallreq_for_madd_msub <= `NoStop;
        end
        else begin
            case (aluop_i)
                `EXE_MADD_OP, `EXE_MADDU_OP: begin
                    if (cnt_i == 2'b00)begin
                        hilo_temp_o <= mulres;
                        cnt_o <= 2'b01;
                        hilo_temp1 <= {`ZeroWord, `ZeroWord};
                        stallreq_for_madd_msub <= `Stop;
                    end
                    else if (cnt_i == 2'b01)begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;//如果因其他原因導致管線保持暫停，那因為設定10可以讓EX不再計算，防止累加重複執行
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                `EXE_MSUB_OP, `EXE_MSUBU_OP: begin
                    if (cnt_i == 2'b00)begin
                        hilo_temp_o <= ~mulres + 1;
                        cnt_o <= 2'b01;
                        stallreq_for_madd_msub <= `Stop;
                    end
                    else if (cnt_i == 2'b01)begin
                        hilo_temp_o <= {`ZeroWord, `ZeroWord};
                        cnt_o <= 2'b10;
                        hilo_temp1 <= hilo_temp_i + {HI, LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                default: begin
                    hilo_temp_o <= {`ZeroWord, `ZeroWord};
                    cnt_o <= 2'b00;
                    stallreq_for_madd_msub <= `NoStop;
                end
            endcase
        end
    end

    //暫停管線
    always @(*)begin
        stallreq = stallreq_for_madd_msub || stallreq_for_div;
    end

    //獲得CP0中暫存器的值
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
                `EXE_MFC0_OP: begin
                    cp0_reg_read_addr_o <= inst_i[15:11];//要從CP0中讀取的暫存器位址
                    moveres <= cp0_reg_data_i;//從CP0中讀取的暫存器的值

                    //判斷資料相依
                    if (mem_cp0_reg_we == `WriteEnable &&
                        mem_cp0_reg_write_addr == inst_i[15:11]) begin
                        moveres <= mem_cp0_reg_data;
                    end
                    else if (wb_cp0_reg_we == `WriteEnable &&
                        wb_cp0_reg_write_addr == inst_i[15:11]) begin
                        moveres <= wb_cp0_reg_data;
                    end
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

    //確定最終要寫入目的暫存器的值
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
            `EXE_RES_JUMP_BRANCH: begin
                wdata_o <= link_address_i;//跳躍、分支指令的結果當作最終結果
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
        else if ((aluop_i == `EXE_DIV_OP) ||
                    (aluop_i == `EXE_DIVU_OP))begin//div、divu指令
            whilo_o <= `WriteEnable;
            hi_o <= div_result_i[63:32];
            lo_o <= div_result_i[31:0];
        end
        else if ((aluop_i == `EXE_MSUB_OP) ||
                    (aluop_i == `EXE_MSUBU_OP))begin//msub、msubu指令
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
        end
        else if ((aluop_i == `EXE_MADD_OP) ||
                    (aluop_i == `EXE_MADDU_OP))begin//madd、maddu指令
            whilo_o <= `WriteEnable;
            hi_o <= hilo_temp1[63:32];
            lo_o <= hilo_temp1[31:0];
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

    //給出mtc0指令的執行結果
    always @(*) begin
        if (rst == `RstEnable) begin
            cp0_reg_write_addr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_data_o <= `ZeroWord;
        end
        else if (aluop_i == `EXE_MTC0_OP) begin
            cp0_reg_write_addr_o <= inst_i[15:11];
            cp0_reg_we_o <= `WriteEnable;
            cp0_reg_data_o <= reg1_i;
        end
        else begin
            cp0_reg_write_addr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_data_o <= `ZeroWord;
        end
    end

endmodule