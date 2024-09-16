`include "defines.v"

module id(
    input rst,
    input [`InstAddrBus] pc_i,//解碼當前的指令對應位置
    input [`InstBus] inst_i,//解碼當前的指令

    //exe result
    input ex_wreg_i,
    input [`RegBus] ex_wdata_i,
    input [`RegAddrBus] ex_wd_i,

    //mem result
    input mem_wreg_i,
    input [`RegBus] mem_wdata_i,
    input [`RegAddrBus] mem_wd_i,
    
    //read regfile
    input [`RegBus] reg1_data_i,
    input [`RegBus] reg2_data_i,

    //write regfile
    output reg reg1_read_o,//讀取暫存器1啟用訊號
    output reg reg2_read_o,//讀取暫存器2啟用訊號
    output reg [`RegAddrBus] reg1_addr_o,//讀取暫存器1地址
    output reg [`RegAddrBus] reg2_addr_o,//讀取暫存器2地址

    //to execute
    output reg [`AluOpBus] aluop_o,//opcode
    output reg [`AluSelBus] alusel_o,//運算類型
    output reg [`RegBus] reg1_o,//要運算的來源暫存器1
    output reg [`RegBus] reg2_o,//要運算的來源暫存器2
    output reg [`RegAddrBus] wd_o,//寫入暫存器地址
    output reg wreg_o//指令是否寫入暫存器
);

    //指令的指令碼、功能碼
    //ori指令只要判斷31-26位即可
    wire [5:0] op = inst_i[31:26];//是否為6'b001101
    wire [4:0] op2 = inst_i[10:6];
    wire [5:0] op3 = inst_i[5:0];
    wire [4:0] op4 = inst_i[20:16];

    //指令immediate
    reg [`RegBus] imm;
    //指令是否有效
    reg instValid;

    //指令解碼
    always @(*) begin
        if (rst == `RstEnable)begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instValid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= `ZeroWord;
        end
        else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            instValid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[25:21];//rs
            reg2_addr_o <= inst_i[20:16];//rt
            imm <= `ZeroWord;

            //從opcode判斷是否是ori指令
            case(op)
                `EXE_ORI: begin
                    //ori指令將結果寫入目標暫存器
                    wreg_o <= `WriteEnable;

                    aluop_o <= `EXE_OR_OP;

                    //運算類型是邏輯運算
                    alusel_o <= `EXE_RES_LOGIC;

                    //需要透過regfile的port1讀取暫存器
                    reg1_read_o <= 1'b1;

                    //不需要透過regfile的port2讀取暫存器
                    reg2_read_o <= 1'b0;

                    //指令需要的immediate
                    imm <= {16'h0, inst_i[15:0]};

                    //指令執行要寫入的目標暫存器位址
                    wd_o <= inst_i[20:16];//rt

                    //ori 指令有效
                    instValid <= `InstValid;
                end
                default: begin
                end
            endcase
        end
    end

    //確定進行運算的來源運算元1
    always @(*) begin
        if (rst == `RstEnable)begin
            reg1_o <= `ZeroWord;
        end
        else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))begin
            reg1_o <= ex_wdata_i;//exe的結果
        end
        else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))begin
            reg1_o <= mem_wdata_i;//mem的結果
        end
        else if (reg1_read_o == 1'b1)begin
            reg1_o <= reg1_data_i;//regfile讀取port1的輸出
        end
        else if (reg1_read_o == 1'b0)begin
            reg1_o <= imm;//immediate
        end
        else begin
            reg1_o <= `ZeroWord;
        end
    end

    //確定進行運算的來源運算元2
    always @(*) begin
        if (rst == `RstEnable)begin
            reg2_o <= `ZeroWord;
        end
        else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))begin
            reg2_o <= ex_wdata_i;//exe的結果
        end
        else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))begin
            reg2_o <= mem_wdata_i;//mem的結果
        end
        else if (reg2_read_o == 1'b1)begin
            reg2_o <= reg2_data_i;//regfile讀取port2的輸出
        end
        else if (reg2_read_o == 1'b0)begin
            reg2_o <= imm;//immediate
        end
        else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule