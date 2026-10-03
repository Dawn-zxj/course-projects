// ProgramCounter_Pipelined.v
module ProgramCounter_Pipelined(
    input CLK,
    input Reset,
    input StallF,
    input PCSrc,
    input [31:0] BranchTarget,
    
    output [31:0] PC,
    output [31:0] PCPlus4
);

reg [31:0] current_PC;
wire [31:0] next_PC;

always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        current_PC <= 32'b0;
    end
    else if (!StallF) begin
        // 优化：直接使用BranchTarget作为下一条PC，避免额外的加法器
        // 当PCSrc为1时，跳转到BranchTarget；否则顺序执行PC+4
        current_PC <= next_PC;
    end
end

// 优化后的PC更新逻辑
// 使用PCPlus4_F来避免额外的加法器
wire [31:0] PC_plus_4 = current_PC + 32'd4;
assign next_PC = PCSrc ? BranchTarget : PC_plus_4;

// 输出当前PC和PC+4
assign PC = current_PC;
assign PCPlus4 = PC_plus_4;  // 提前计算PC+4，供后续阶段使用

endmodule