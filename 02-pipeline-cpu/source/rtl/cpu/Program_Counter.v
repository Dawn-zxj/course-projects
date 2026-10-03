//m`timescale 1ns / 1ps
module PC(
        input CLK,               //时钟
        input Reset,             //是否重置地址。1-初始化PC，否则接受新地址
        input PCSrc,             //数据选择器输入
        input [31:0] AluOutput,  //ALU计算结果
        input [6:0] op,
        output reg[31:0] curPC,  //当前指令的地址
        output reg[31:0] nextPC  //下条指令的地址
    );

  // 检测是否为load指令（RISC-V中load指令的opcode为7'b0000011）
    wire is_load_instr = (op == 7'b0000011);
    
    // load指令暂停状态寄存器
    reg load_stall_reg;
    
    initial begin
        curPC <= 0; // 初始值为0
        nextPC <= 4;
        load_stall_reg <= 1'b0;
    end

    // 暂停状态控制逻辑
    always @(posedge CLK) begin
        if (Reset) begin
            load_stall_reg <= 1'b0;
        end else if (load_stall_reg) begin 
            // 如果当前处于暂停状态，下一个周期清除暂停标志
            load_stall_reg <= 1'b0; 
        end else begin
            // 检测到load指令时设置暂停标志
            load_stall_reg <= is_load_instr;
        end
    end
    
    // 检测时钟下降沿计算新指令地址 
    always @(negedge CLK) begin
        if (Reset) begin
            nextPC <= 4;
        end else if (is_load_instr && ~load_stall_reg) begin
            // 遇到load指令且不在暂停状态，保持nextPC不变
            nextPC <= nextPC;
        end else begin
            // 正常计算下一条指令地址
            case(PCSrc)
                1'b0:   nextPC <= curPC + 4;
                1'b1:   nextPC <= AluOutput;
                default: nextPC <= curPC + 4;
            endcase
        end
    end
    
    // 检测时钟上升沿更新PC或复位信号
    always @(posedge CLK or posedge Reset) begin
        if (Reset) begin
            // 复位置1时把PC归零
            curPC <= 0;
        end else if (is_load_instr && ~load_stall_reg) begin
            // 遇到load指令且不在暂停状态，暂停一个周期
            curPC <= curPC;  // PC保持不变
        end else begin
            // 正常执行或暂停后恢复执行
            curPC <= nextPC;
        end
    end

endmodule