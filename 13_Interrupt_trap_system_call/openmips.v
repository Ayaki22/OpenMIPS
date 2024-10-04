`include "defines.v"

module openmips(
    input clk,
    input rst,

    input [`RegBus] ram_data_i,//從資料記憶體取得的資料
    output [`RegBus] ram_addr_o,//輸出至資料記憶體的位置
    output [`RegBus] ram_data_o,//輸出至資料記憶體的資料
    output ram_we_o,//資料記憶體寫入訊號
    output [3:0] ram_sel_o,//資料記憶體選擇訊號
    output [3:0] ram_ce_o,//資料記憶體啟用訊號

    input [`RegBus] rom_data_i,//從指令記憶體取得的指令
    output [`RegBus] rom_addr_o,//輸出至指令記憶體的位置
    output rom_ce_o,//指令記憶體啟用訊號

    input int_i,
    output timer_int_o
);

    // IF/ID to ID
    wire [`InstAddrBus] pc;
    wire [`InstAddrBus] id_pc_i;
    wire [`InstBus] id_inst_i;

    // ID to ID/EX
    wire [`AluOpBus] id_aluop_o;
    wire [`AluSelBus] id_alusel_o;
    wire [`RegBus] id_reg1_o;
    wire [`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire [`RegAddrBus] id_wd_o;
    wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;
    wire[`RegBus] id_inst_o;
    wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_address_o;

    // ID/EX to EX
    wire [`AluOpBus] ex_aluop_i;
    wire [`AluSelBus] ex_alusel_i;
    wire [`RegBus] ex_reg1_i;
    wire [`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire [`RegAddrBus] ex_wd_i;
    wire ex_is_in_delayslot_i;	
    wire[`RegBus] ex_link_address_i;
    wire[`RegBus] ex_inst_i;
    wire[31:0] ex_excepttype_i;	
    wire[`RegBus] ex_current_inst_address_i;

    //EX to EX/MEM for CP0
    wire ex_cp0_reg_we_o;
	wire[4:0] ex_cp0_reg_write_addr_o;
	wire[`RegBus] ex_cp0_reg_data_o;

    // EX to EX/MEM & EXE to ID for RAW
    wire ex_wreg_o;
    wire [`RegAddrBus] ex_wd_o;
    wire [`RegBus] ex_wdata_o;

    //EX to EX/MEM for HI、LO
    wire [`RegBus] ex_hi_o;
    wire [`RegBus] ex_lo_o;
    wire ex_whilo_o;

    wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg1_o;
	wire[`RegBus] ex_reg2_o;
    wire[31:0] ex_excepttype_o;
	wire[`RegBus] ex_current_inst_address_o;
	wire ex_is_in_delayslot_o;

    // EX/MEM to MEM
    wire mem_wreg_i;
    wire [`RegAddrBus] mem_wd_i;
    wire [`RegBus] mem_wdata_i;

    //EX/MEM to MEM for CP0
    wire mem_cp0_reg_we_i;
	wire[4:0] mem_cp0_reg_write_addr_i;
	wire[`RegBus] mem_cp0_reg_data_i;

    //EX/MEM to MEM for HI、LO
    wire [`RegBus] mem_hi_i;
    wire [`RegBus] mem_lo_i;
    wire mem_whilo_i;

    wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;

    wire[31:0] mem_excepttype_i;	
	wire mem_is_in_delayslot_i;
	wire[`RegBus] mem_current_inst_address_i;

    //MEM to EX
    wire mem_cp0_reg_we_o;
	wire[4:0] mem_cp0_reg_write_addr_o;
	wire[`RegBus] mem_cp0_reg_data_o;

    // MEM to MEM/WB & MEM to ID for RAW
    wire mem_wreg_o;
    wire [`RegAddrBus] mem_wd_o;
    wire [`RegBus] mem_wdata_o;

    //MEM to MEM/WB for HI、LO
    wire [`RegBus] mem_hi_o;
    wire [`RegBus] mem_lo_o;
    wire mem_whilo_o;

    //MEM to MEM for LLbit
    wire mem_LLbit_value_o;
	wire mem_LLbit_we_o;

    //MEM to CP0
    wire[31:0] mem_excepttype_o;
	wire mem_is_in_delayslot_o;
	wire[`RegBus] mem_current_inst_address_o;

    // MEM/WB to WB
    wire wb_wreg_i;
    wire [`RegAddrBus] wb_wd_i;
    wire [`RegBus] wb_wdata_i;

    //MEM/WB to WB for HI、LO
    wire [`RegBus] wb_hi_i;
    wire [`RegBus] wb_lo_i;
    wire wb_whilo_i;

    //MEM/WB to MEM for LLbit
    wire wb_LLbit_value_i;
	wire wb_LLbit_we_i;

    //WB to EX
    wire wb_cp0_reg_we_i;
	wire[4:0] wb_cp0_reg_write_addr_i;
	wire[`RegBus] wb_cp0_reg_data_i;
    

    // ID to regfile
    wire reg1_read;
    wire reg2_read;
    wire [`RegBus] reg1_data;
    wire [`RegBus] reg2_data;
    wire [`RegAddrBus] reg1_addr;
    wire [`RegAddrBus] reg2_addr;

    //HI、LO to EXE
    wire [`RegBus] hi;
    wire [`RegBus] lo;

    //exe stage and exe_reg, multi-cycle for MADD、MADDU、MSUB、MSUBU
    wire [`DoubleRegBus] hilo_temp_o;
    wire [1:0] cnt_o;

    wire [`DoubleRegBus] hilo_temp_i;
    wire [1:0] cnt_i;

    wire[`DoubleRegBus] div_result;
	wire div_ready;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire div_annul;
	wire signed_div;

    wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;

    wire [5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;

    //LLbit to MEM
    wire LLbit_o;

    //CP0
    wire[`RegBus] cp0_data_o;
    wire[4:0] cp0_raddr_i;
    wire[`RegBus]   cp0_count;
	wire[`RegBus]	cp0_compare;
    wire[`RegBus]	cp0_status;
	wire[`RegBus]	cp0_cause;
	wire[`RegBus]	cp0_epc;
    wire[`RegBus]	cp0_config;
	wire[`RegBus]	cp0_prid;

    //Ctrl
    wire flush;
    wire[`RegBus] new_pc;
    wire[`RegBus] latest_epc;

    //pc_reg
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_flag_i(id_branch_flag_o),
        .branch_target_address_i(branch_target_address),
        .pc(pc),
        .flush(flush),
        .new_pc(new_pc),
        .ce(rom_ce_o)
    );

    assign rom_addr_o = pc;

    // IF/ID
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .if_pc(pc),
        .if_inst(rom_data_i),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i)
    );

    // ID
    id id0(
        .rst(rst),
        .pc_i(id_pc_i),
        .inst_i(id_inst_i),

        .ex_aluop_i(ex_aluop_o),

        //EXE to ID for RAW
        .ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

        //MEM to ID for RAW
        .mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

        //regfile
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),
        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),
        .reg2_addr_o(reg2_addr),

        //ID/EX to ID for delayslot
        .is_in_delayslot_i(is_in_delayslot_i),

        // ID to ID/EX
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),
        .reg1_o(id_reg1_o),
        .reg2_o(id_reg2_o),
        .wd_o(id_wd_o),
        .wreg_o(id_wreg_o),
        .inst_o(id_inst_o),
        .excepttype_o(id_excepttype_o),
        .current_inst_address_o(id_current_inst_address_o),

        .next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		
		.is_in_delayslot_o(id_is_in_delayslot_o),

        .stallreq(stallreq_from_id)
    );

    // regfile
    regfile regfile0(
        .clk(clk),
        .rst(rst),
        .we(wb_wreg_i),
        .waddr(wb_wd_i),
        .wdata(wb_wdata_i),
        .re1(reg1_read),
        .raddr1(reg1_addr),
        .rdata1(reg1_data),
        .re2(reg2_read),
        .raddr2(reg2_addr),
        .rdata2(reg2_data)
    );

    // ID/EX
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        // ID to ID/EX
        .id_aluop(id_aluop_o),
        .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),
        .id_wreg(id_wreg_o),
        .id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),
        .id_inst(id_inst_o),
        .id_excepttype(id_excepttype_o),
		.id_current_inst_address(id_current_inst_address_o),

        // ID/EX to EX
        .ex_aluop(ex_aluop_i),
        .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),
        .ex_wreg(ex_wreg_i),
        .ex_link_address(ex_link_address_i),
        .ex_is_in_delayslot(ex_is_in_delayslot_i),
        .ex_inst(ex_inst_i),
        .ex_excepttype(ex_excepttype_i),
		.ex_current_inst_address(ex_current_inst_address_i),

        // ID/EX to ID
		.is_in_delayslot_o(is_in_delayslot_i)
    );

    // EX
    ex ex0(
        .rst(rst),

        //from MEM for CP0
        .mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),

        //from WB for CP0
        .wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),

        //from CP0
        .cp0_reg_data_i(cp0_data_o),
        
        // ID/EX to EX
        .cp0_reg_read_addr_o(cp0_raddr_i),
        //向下一級管線傳遞，用於寫入CP0中的暫存器
		.cp0_reg_we_o(ex_cp0_reg_we_o),
		.cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
		.cp0_reg_data_o(ex_cp0_reg_data_o),
        .excepttype_i(ex_excepttype_i),
		.current_inst_address_i(ex_current_inst_address_i),

        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),
        .wreg_i(ex_wreg_i),
        .hi_i(hi),
        .lo_i(lo),
        .inst_i(ex_inst_i),

        .wb_hi_i(wb_hi_i),
        .wb_lo_i(wb_lo_i),
        .wb_whilo_i(wb_whilo_i),
        .mem_hi_i(mem_hi_i),
        .mem_lo_i(mem_lo_i),
        .mem_whilo_i(mem_whilo_i),

        .hilo_temp_i(hilo_temp_i),
        .cnt_i(cnt_i),

		.div_result_i(div_result),
		.div_ready_i(div_ready),

        .link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),

        // EX to EX/MEM
        .wd_o(ex_wd_o),
        .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),
        .hi_o(ex_hi_o),
        .lo_o(ex_lo_o),
        .whilo_o(ex_whilo_o),

        .excepttype_o(ex_excepttype_o),
		.is_in_delayslot_o(ex_is_in_delayslot_o),
		.current_inst_address_o(ex_current_inst_address_o),

        .aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

        .hilo_temp_o(hilo_temp_o),
        .cnt_o(cnt_o),
        .div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div),
        .stallreq(stallreq_from_ex)
    );

    //Div
    div div0(
        .clk(clk),
        .rst(rst),
        .signed_div_i(signed_div),
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
        .annul_i(flush),

        .result_o(div_result),
        .ready_o(div_ready)
    );

    // EX/MEM
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        // EX to EX/MEM
        .ex_wd(ex_wd_o),
        .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),
        .ex_whilo(ex_whilo_o),

        .ex_aluop(ex_aluop_o),
        .ex_mem_addr(ex_mem_addr_o),
        .ex_reg2(ex_reg2_o),

        .ex_excepttype(ex_excepttype_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_o),
		.ex_current_inst_address(ex_current_inst_address_o),

        .hilo_i(hilo_temp_o),
        .cnt_i(cnt_o),

        .ex_cp0_reg_we(ex_cp0_reg_we_o),
		.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		.ex_cp0_reg_data(ex_cp0_reg_data_o),

        // EX/MEM to MEM
        .mem_wd(mem_wd_i),
        .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),
        .mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),
        .mem_whilo(mem_whilo_i),

        .mem_aluop(mem_aluop_i),
        .mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),

        .mem_cp0_reg_we(mem_cp0_reg_we_i),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		.mem_cp0_reg_data(mem_cp0_reg_data_i),

        .mem_excepttype(mem_excepttype_i),
        .mem_is_in_delayslot(mem_is_in_delayslot_i),
		.mem_current_inst_address(mem_current_inst_address_i),

        .hilo_o(hilo_temp_i),
        .cnt_o(cnt_i)
    );

    // MEM
    mem mem0(
        .rst(rst),

        // EX/MEM to MEM
        .wd_i(mem_wd_i),
        .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),
        .hi_i(mem_hi_i),
        .lo_i(mem_lo_i),
        .whilo_i(mem_whilo_i),

        .aluop_i(mem_aluop_i),
        .mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),

        .excepttype_i(mem_excepttype_i),
		.is_in_delayslot_i(mem_is_in_delayslot_i),
		.current_inst_address_i(mem_current_inst_address_i),

        .cp0_reg_we_i(mem_cp0_reg_we_i),
		.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		.cp0_reg_data_i(mem_cp0_reg_data_i),

        //from ram
		.mem_data_i(ram_data_i),

        //to ram
        .mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o),

        //from cp0
        .cp0_status_i(cp0_status),
		.cp0_cause_i(cp0_cause),
		.cp0_epc_i(cp0_epc),

        // MEM to MEM/WB
        .wd_o(mem_wd_o),
        .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),
        .hi_o(mem_hi_o),
        .lo_o(mem_lo_o),
        .whilo_o(mem_whilo_o),
        .LLbit_we_o(mem_LLbit_we_o),
		.LLbit_value_o(mem_LLbit_value_o),

        .cp0_reg_we_o(mem_cp0_reg_we_o),
		.cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
		.cp0_reg_data_o(mem_cp0_reg_data_o),

        //MEM/WB to MEM
        //不一定是最新值，回寫階段可能要寫入LLbit，所以還要進一步判斷
		.wb_LLbit_we_i(wb_LLbit_we_i),
		.wb_LLbit_value_i(wb_LLbit_value_i),
        .wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),

        //to CP0
        .excepttype_o(mem_excepttype_o),
		.cp0_epc_o(latest_epc),//to ctrl
		.is_in_delayslot_o(mem_is_in_delayslot_o),
        .current_inst_address_o(mem_current_inst_address_o),

        //LLbit to MEM
        //LLbit_i是LLbit暫存器的值
		.LLbit_i(LLbit_o)
    );

    // MEM/WB
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),

        .stall(stall),
        .flush(flush),

        // MEM to MEM/WB
        .mem_wd(mem_wd_o),
        .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),
        .mem_hi(mem_hi_o),
        .mem_lo(mem_lo_o),
        .mem_whilo(mem_whilo_o),

        .mem_LLbit_we(mem_LLbit_we_o),
		.mem_LLbit_value(mem_LLbit_value_o),

        .mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),

        // MEM/WB to WB
        .wb_wd(wb_wd_i),
        .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(wb_hi_i),
        .wb_lo(wb_lo_i),
        .wb_whilo(wb_whilo_i),

        .wb_LLbit_we(wb_LLbit_we_i),
		.wb_LLbit_value(wb_LLbit_value_i),

        .wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i)
    );

    //HILO
    hilo_reg hilo_reg0(
        .clk(clk),
        .rst(rst),

        //MEM/WB to HILO
        .we(wb_whilo_i),
        .hi_i(wb_hi_i),
        .lo_i(wb_lo_i),

        //HILO to EXE
        .hi_o(hi),
        .lo_o(lo)
    );

    // ctrl
    ctrl ctrl0(
        .rst(rst),
        .excepttype_i(mem_excepttype_o),
        .cp0_epc_i(latest_epc),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .new_pc(new_pc),
        .flush(flush),
        .stall(stall)
    );

    LLbit_reg LLbit_reg0(
		.clk(clk),
		.rst(rst),
        .flush(flush),

		//寫入連接埠
		.LLbit_i(wb_LLbit_value_i),
		.we(wb_LLbit_we_i),
	
		//讀取連接埠1
		.LLbit_o(LLbit_o)
	);

    cp0_reg cp0_reg0(
		.clk(clk),
		.rst(rst),
		
		.we_i(wb_cp0_reg_we_i),
		.waddr_i(wb_cp0_reg_write_addr_i),
		.raddr_i(cp0_raddr_i),
		.data_i(wb_cp0_reg_data_i),
		
		.excepttype_i(mem_excepttype_o),
		.int_i(int_i),
		.current_inst_addr_i(mem_current_inst_address_o),
		.is_in_delayslot_i(mem_is_in_delayslot_o),
		
		.data_o(cp0_data_o),
        .count_o(cp0_count),
		.compare_o(cp0_compare),
        .status_o(cp0_status),
		.cause_o(cp0_cause),
		.epc_o(cp0_epc),
        .config_o(cp0_config),
		.prid_o(cp0_prid),
		
		.timer_int_o(timer_int_o)  			
	);
endmodule