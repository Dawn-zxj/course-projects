// CondLogic.v
module CondLogic(
    input CLK,
    input Reset,      // 添加Reset输入
    input PCS,
    input RegW,
    input MemW,
    input NoWrite,
    input [1:0] FlagW,
    input [3:0] Cond,
    input [3:0] ALUFlags,
    input M_W,
    
    output PCSrc,
    output RegWrite,
    output MemWrite,
    output M_Write,
    output CondEx,
    output [3:0] FlagOut      // 输出条件码寄存器值
);

reg CondEx_reg;
reg N, Z, C, V;  // 条件码寄存器

// 条件码更新逻辑
always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        N <= 1'b0;
        Z <= 1'b0;
        C <= 1'b0;
        V <= 1'b0;
    end
    else begin
        if (FlagW[1] && CondEx_reg) begin  // 更新NZ标志
            N <= ALUFlags[3];
            Z <= ALUFlags[2];
        end
        if (FlagW[0] && CondEx_reg) begin  // 更新CV标志
            C <= ALUFlags[1];
            V <= ALUFlags[0];
        end
    end
end

// 条件判断逻辑
always @(*) begin
    case(Cond)
        4'b0000: CondEx_reg = Z;
        4'b0001: CondEx_reg = ~Z;
        4'b0010: CondEx_reg = C;
        4'b0011: CondEx_reg = ~C;
        4'b0100: CondEx_reg = N;
        4'b0101: CondEx_reg = ~N;
        4'b0110: CondEx_reg = V;
        4'b0111: CondEx_reg = ~V;
        4'b1000: CondEx_reg = C & ~Z;
        4'b1001: CondEx_reg = ~C | Z;
        4'b1010: CondEx_reg = ~(N ^ V);
        4'b1011: CondEx_reg = N ^ V;
        4'b1100: CondEx_reg = ~Z & ~(N ^ V);
        4'b1101: CondEx_reg = Z | (N ^ V);
        4'b1110: CondEx_reg = 1;
        default: CondEx_reg = 0;
    endcase
end

assign CondEx = CondEx_reg;
assign FlagOut = {N, Z, C, V};  // 输出条件码寄存器

// 条件执行的控制信号
assign PCSrc    = CondEx_reg & PCS;
assign RegWrite = CondEx_reg & RegW & ~NoWrite;
assign MemWrite = CondEx_reg & MemW;
assign M_Write  = CondEx_reg & M_W;

endmodule