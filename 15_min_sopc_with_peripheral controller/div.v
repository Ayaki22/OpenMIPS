`include "defines.v"
module div(
    input clk,
    input rst,
    input signed_div_i,
    input [31:0] opdata1_i,
    input [31:0] opdata2_i,
    input start_i,
    input annul_i,

    output reg [63:0] result_o,
    output reg ready_o
);

    wire [32:0] div_temp;
    reg [5:0] cnt; //紀錄試商法的次數，最多32次
    reg [64:0] dividend;
    reg [1:0] state;
    reg [31:0] divisor;
    reg [31:0] temp_op1;
    reg [31:0] temp_op2;

    //dividend的低32bit保存被除數
    //dividend[k:0]第k次迭代保存中間結果
    //dividend[k+1:0]保存還沒參與運算的資料
    //dividend的高32bit是每次迭代時的被減數
    //dividend[63:32]就是minuend
    //divisor是除數n
    //這裡進行minuend - n的運算存在div_temp中
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

    always @(posedge clk) begin
        if (rst == `RstEnable)begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= {`ZeroWord, `ZeroWord};
        end
        else begin
            case (state)
                //DivFree state
                //1. 開始除法，但除數為0，那進入DivByZero state
                //2. 開始除法，除數不為0，那進入DivOn state，初始化cnt=0
                //2.1 如果是有號除法，且除數或被除數為負數，那除數或被除數取補數
                //除數保存到divisor，被出數最高位保存到dividend的第32位元，準備第一次迭代
                //3. 沒有除法運算，保持ready_o為DivResultNotReady，result_o為0
                `DivFree: begin //DivFree state
                    if (start_i == `DivStart && annul_i == 1'b0)begin
                        if (opdata2_i == `ZeroWord) begin
                            state <= `DivByZero; //除數為0
                        end
                        else begin
                            state <= `DivOn;//除數不為0
                            cnt <= 6'b000000;
                            if (signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin
                                temp_op1 = ~opdata1_i + 1;//被除數取補數
                            end
                            else begin
                                temp_op1 = opdata1_i;
                            end
                            if (signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) begin
                                temp_op2 = ~opdata2_i + 1;//除數取補數
                            end
                            else begin
                                temp_op2 = opdata2_i;
                            end
                            dividend <= {`ZeroWord, `ZeroWord};
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                        end
                    end
                    else begin //沒有開始除法運算
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
                //DivByZero state
                //除數為0，那麼結果為0，進入DivEnd state
                `DivByZero: begin //DivByZero state
                    dividend <= {`ZeroWord, `ZeroWord};
                    state <= `DivEnd;
                end
                //DivOn state
                //1. 如果輸入訊號annul_i為1，表示處理器取消除法運算，那DIV module直接回到DivFree state
                //2. 如果輸入訊號annul_i為0，且cnt不為32，代表試商法還沒結束
                //2.1 如果減法結果div_temp為負數，那此次迭代結果是0
                //2.2 如果減法結果div_temp為正數，那此次迭代結果是1
                //2.3 dividend的最低位保存此次迭代結果，同時保持DivOn，cnt+1
                //3. 如果annual_i=0, cnt=32，代表試商法結束
                //3.1 如果是有號除法，且被除數、除數的符號不同，那將試商法結果取補數，此處的商、餘數都要取補數
                // 商保存在diviend的低32位，餘數保存在dividend的高32位，同時進入DivEnd state
                `DivOn: begin //DivOn state
                    if (annul_i == 1'b0) begin
                        if (cnt != 6'b100000) begin
                            if (div_temp[32] == 1'b1) begin
                                //如果div_temp[32]=1，表示(minuend-n)結果小於0
                                //將dividend向左移1位，這樣就將被除數還沒有參與運算的
                                //最高位加入到下一次迭代的被減數，同時將0追加到中間結果
                                dividend <= {dividend[63:0], 1'b0};
                            end
                            else begin
                                //如果div_temp[32]=0，表示(minuend-n)結果大於等於0
                                //將dividend向左移1位，這樣就將被除數還沒有參與運算的
                                //最高位加入到下一次迭代的被減數，同時將1追加到中間結果
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            end
                            cnt <= cnt + 1;
                        end
                        else begin
                            if ((signed_div_i == 1'b1) &&
                                ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                                    dividend[31:0] <= (~dividend[31:0] + 1);
                                end
                            if ((signed_div_i == 1'b1) &&
                                ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
                                dividend[64:33] <= (~dividend[64:33] + 1);
                            end
                            state <= `DivEnd;
                            cnt <= 6'b000000;
                        end
                    end
                    else begin
                        state <= `DivFree;//如果annul_i=1，那直接回到DivFree state
                    end
                end
                //DivEnd state
                //除法運算結束，result_o的寬度是64位，其高32位存餘數，低32位存商
                //設定輸出訊號ready_o為DivResultReady
                //等待EX module的DivStop訊號，當訊號送來時回到DivFree state
                `DivEnd: begin //DivEnd state
                    result_o <= {dividend[64:33], dividend[31:0]};
                    ready_o <= `DivResultReady;
                    if (start_i == `DivStop) begin
                        state <= `DivFree;
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord, `ZeroWord};
                    end
                end
            endcase
        end
    end

endmodule