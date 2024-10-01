`include "defines.v"

module cp0_reg(
    input clk,
    input rst,

    input we_i,
    input [4:0] waddr_i,
    input [4:0] raddr_i,
    input [`RegBus] data_i,

    input [5:0] int_i,

    output reg [`RegBus] data_o,
    output reg [`RegBus] count_o,
    output reg [`RegBus] compare_o,
    output reg [`RegBus] status_o,
    output reg [`RegBus] cause_o,
    output reg [`RegBus] epc_o,
    output reg [`RegBus] config_o,
    output reg [`RegBus] prid_o,

    output reg timer_int_o
);

    //CP0暫存器寫入
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            count_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            status_o <= 32'b00010000000000000000000000000000;//status暫存器的CU為0001，表示協同處理器CP0存在
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            config_o <= 32'b00000000000000001000000000000000;//config暫存器的BE為1，表示Big-Endian；MT為00，表示沒有MMU
            //prid參考書中設定
            //製作者是L，對應的是0x48，類型是0x1，基本類型，版本編號是1.0
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end
        else begin
            count_o <= count_o + 1;
            cause_o[15:10] <= int_i;//保存外部中斷宣告

            //compare暫存器不為0，且count暫存器等於compare暫存器時，
            //將timer_int_o設為1，表示時脈中斷發生
            if (compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end

            if (we_i == `WriteEnable) begin
                case (waddr_i)
                    `CP0_REG_COUNT: begin //寫入count暫存器
                        count_o <= data_i;
                    end
                    `CP0_REG_COMPARE: begin //寫入compare暫存器
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS: begin //寫入status暫存器
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC: begin //寫入epc暫存器
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE: begin //寫入cause暫存器
                        //cause暫存器只有IP[1:0]、IV、WP欄位可寫入
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end
                endcase
            end
        end
    end

    //CP0暫存器讀取
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end
        else begin
            case (raddr_i)
                `CP0_REG_COUNT: begin //讀取count暫存器
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE: begin //讀取compare暫存器
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS: begin //讀取status暫存器
                    data_o <= status_o;
                end
                `CP0_REG_CAUSE: begin //讀取cause暫存器
                    data_o <= cause_o;
                end
                `CP0_REG_EPC: begin //讀取epc暫存器
                    data_o <= epc_o;
                end
                `CP0_REG_PrId: begin //讀取prid暫存器
                    data_o <= prid_o;
                end
                `CP0_REG_CONFIG: begin //讀取config暫存器
                    data_o <= config_o;
                end
                default: begin
                end
            endcase
        end
    end

endmodule