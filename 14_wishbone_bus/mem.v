`include "defines.v"

module mem(
    input rst,

    //從ex傳來的資料
    input [`RegAddrBus] wd_i,
    input wreg_i,
    input [`RegBus] wdata_i,
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,
    input whilo_i,
    input [`AluOpBus] aluop_i,
    input [`RegBus] mem_addr_i,
    input [`RegBus] reg2_i,

    //from RAM
    input [`RegBus] mem_data_i,

    input cp0_reg_we_i,
    input [4:0] cp0_reg_write_addr_i,
    input [`RegBus] cp0_reg_data_i,

    //for Exception related instructions
    input [31:0] excepttype_i,
    input is_in_delayslot_i,
    input [`RegBus] current_inst_address_i,

    //for Exception related instructions from CP0
    input [`RegBus] cp0_status_i,
    input [`RegBus] cp0_cause_i,
    input [`RegBus] cp0_epc_i,

    //for Exception related instructions from WB
    input wb_cp0_reg_we,
    input [4:0] wb_cp0_reg_write_addr,
    input [`RegBus] wb_cp0_reg_data,

    //for LLbit
    input LLbit_i,
    input wb_LLbit_we_i,
    input wb_LLbit_value_i,

    output reg LLbit_we_o,
    output reg LLbit_value_o,

    //存取mem的資料
    output reg [`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg [`RegBus] wdata_o,
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,

    //to RAM
    output reg [`RegBus] mem_addr_o,
    output mem_we_o,
    output reg [3:0] mem_sel_o,
    output reg [`RegBus] mem_data_o,
    output reg mem_ce_o,

    output reg cp0_reg_we_o,
    output reg [4:0] cp0_reg_write_addr_o,
    output reg [`RegBus] cp0_reg_data_o,

    //for Exception related instructions
    output reg [31:0] excepttype_o,
    output [`RegBus] cp0_epc_o,
    output is_in_delayslot_o,
    output [`RegBus] current_inst_address_o
);

    wire [`RegBus] zero32;
    reg mem_we;

    reg LLbit;

    reg [`RegBus] cp0_status;
    reg [`RegBus] cp0_cause;
    reg [`RegBus] cp0_epc;

    assign zero32 = `ZeroWord;

    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_address_o = current_inst_address_i;

    //得到CP0的最新值
    //判斷目前處於回寫階段的指令是否要寫入CP0中STATUS暫存器
    //如果要寫入，則寫入最新值，反之，CP0暫存器給出的值cp0_status_i是最新值
    always @(*) begin
        if (rst == `RstEnable) begin
            cp0_status <= `ZeroWord;
        end
        else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_STATUS)) begin
            cp0_status <= wb_cp0_reg_data;
        end
        else begin
            cp0_status <= cp0_status_i;
        end
    end

    //得到CP0中EPC暫存器的最新值
    //判斷目前處於回寫階段的指令是否要寫入CP0中EPC暫存器
    //如果要寫入，則寫入EPC最新值，反之，CP0暫存器給出的值cp0_epc_i是最新值
    always @(*) begin
        if (rst == `RstEnable) begin
            cp0_epc <= `ZeroWord;
        end
        else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_EPC)) begin
            cp0_epc <= wb_cp0_reg_data;
        end
        else begin
            cp0_epc <= cp0_epc_i;
        end
    end

    //將EPC暫存器的最新值透過cp0_epc_o輸出
    assign cp0_epc_o = cp0_epc;

    //得到CP0中CAUSE暫存器的最新值
    //判斷目前處於回寫階段的指令是否要寫入CP0中CAUSE暫存器
    //如果要寫入，則寫入CAUSE最新值，反之，CP0暫存器給出的值cp0_cause_i是最新值
    always @(*) begin
        if (rst == `RstEnable) begin
            cp0_cause <= `ZeroWord;
        end
        else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_CAUSE)) begin
            cp0_cause[9:8] <= wb_cp0_reg_data[9:8];//IP[1:0]欄位是可寫入的
            cp0_cause[22] <= wb_cp0_reg_data[22];//WP欄位是可寫入的
            cp0_cause[23] <= wb_cp0_reg_data[23];//IV欄位是可寫入的
        end
        else begin
            cp0_cause <= cp0_cause_i;
        end
    end

    //給出最終的異常類型
    always @(*) begin
        if (rst == `RstEnable) begin
            excepttype_o <= `ZeroWord;
        end
        else begin
            excepttype_o <= `ZeroWord;
            if (current_inst_address_i != `ZeroWord) begin
                if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
                        (cp0_status[1] == 1'b0) &&
                        (cp0_status[0] == 1'b1)) begin
                            excepttype_o <= 32'h00000001; //Interrupt
                end
                else if (excepttype_i[8] == 1'b1) begin
                    excepttype_o <= 32'h00000008; //Syscall
                end
                else if (excepttype_i[9] == 1'b1) begin
                    excepttype_o <= 32'h0000000a; //inst_invalid
                end
                else if (excepttype_i[10] == 1'b1) begin
                    excepttype_o <= 32'h0000000d; //trap
                end
                else if (excepttype_i[11] == 1'b1) begin
                    excepttype_o <= 32'h0000000c; //ov
                end
                else if (excepttype_i[12] == 1'b1) begin
                    excepttype_o <= 32'h0000000e; //eret
                end
            end
        end
    end

    //給出對資料記憶體的寫入操作
    //mem_we_o輸出到資料記憶體，表示是否對資料記憶體進行寫入操作
    //如果發生異常，那需要取消對資料記憶體的寫入操作
    assign mem_we_o = mem_we & (~(|excepttype_o));

    //如果WB要寫入LLbit，則寫入LLbit最新值，反之，LLbit給出的值LLbit_i是最新值
    always @(*) begin
        if (rst == `RstEnable) begin
            LLbit <= 1'b0;
        end
        else begin
            if (wb_LLbit_we_i == 1'b1) begin
                LLbit <= wb_LLbit_value_i;
            end
            else begin
                LLbit <= LLbit_i;
            end
        end
    end

    always @(*) begin
        if (rst == `RstEnable)begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            whilo_o <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_we <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            mem_ce_o <= `ChipDisable;
            LLbit_we_o <= 1'b0;
            LLbit_value_o <= 1'b0;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_write_addr_o <= 5'b00000;
            cp0_reg_data_o <= `ZeroWord;
        end
        else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
            whilo_o <= whilo_i;
            mem_we <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_sel_o <= 4'b1111;
            mem_ce_o <= `ChipDisable;
            LLbit_we_o <= 1'b0;
            LLbit_value_o <= 1'b0;
            cp0_reg_we_o <= cp0_reg_we_i;
            cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
            cp0_reg_data_o <= cp0_reg_data_i;
            case (aluop_i)
                `EXE_LL_OP: begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    wdata_o <= mem_data_i;
                    LLbit_we_o <= 1'b1;
                    LLbit_value_o <= 1'b1;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                end
                `EXE_SC_OP: begin
                    if (LLbit == 1'b1) begin
                        LLbit_we_o <= 1'b1;
                        LLbit_value_o <= 1'b0;
                        mem_addr_o <= mem_addr_i;
                        mem_we <= `WriteEnable;
                        mem_data_o <= reg2_i;
                        wdata_o <= 32'b1;
                        mem_sel_o <= 4'b1111;
                        mem_ce_o <= `ChipEnable;
                    end
                    else begin
                        wdata_o <= 32'b0;
                    end
                end
                `EXE_LB_OP: begin //lb指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        2'b01: begin
                            wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b10: begin
                            wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b11: begin
                            wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_LBU_OP: begin //lbu指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        2'b01: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b10: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b11: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_LH_OP: begin //lh指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        2'b10: begin
                            wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_LHU_OP: begin //lhu指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        2'b10: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_LW_OP: begin //lw指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    wdata_o <= mem_data_i;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                end
                `EXE_LWL_OP: begin //lwl指令
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_we <= `WriteDisable;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= mem_data_i[31:0];
                        end
                        2'b01: begin
                            wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
                        end
                        2'b10: begin
                            wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
                        end
                        2'b11: begin
                            wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_LWR_OP: begin //lwr指令
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_we <= `WriteDisable;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
                        end
                        2'b01: begin
                            wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
                        end
                        2'b10: begin
                            wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
                        end
                        2'b11: begin
                            wdata_o <= mem_addr_i;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                `EXE_SB_OP: begin //sb指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteEnable;
                    mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1000;
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b0100;
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b0010;
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b0001;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `EXE_SH_OP: begin //sh指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteEnable;
                    mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1100;
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b0011;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `EXE_SW_OP: begin //sw指令
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;
                end
                `EXE_SWL_OP: begin //swl指令
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_we <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1111;
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b0111;
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b0011;
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b0001;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `EXE_SWR_OP: begin //swr指令
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_we <= `WriteEnable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1000;
                            mem_data_o <= {reg2_i[7:0], zero32[23:0]};
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b1100;
                            mem_data_o <= {reg2_i[15:0], zero32[15:0]};
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b1110;
                            mem_data_o <= {reg2_i[23:0], zero32[7:0]};
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b1111;
                            mem_data_o <= reg2_i[31:0];
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                default: begin
                    //do nothing
                end
            endcase
        end
    end

endmodule