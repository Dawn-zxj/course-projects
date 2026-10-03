// PipelineReg_IF_ID.v
module PipelineReg_IF_ID(
    input CLK,
    input Reset,
    input Stall,
    input Flush,
    
    // 来自IF阶段的信号
    input [31:0] Instr_F,
    input [31:0] PCPlus4_F,
    input [31:0] PC_F,  // 新增：传递IF阶段的PC值
    
    // 输出到ID阶段
    output reg [31:0] Instr_D,
    output reg [31:0] PCPlus4_D,
    output reg [31:0] PC_F_D  // 新增：传递IF阶段的PC值到ID阶段
);

always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        Instr_D <= 32'b0;
        PCPlus4_D <= 32'b0;
        PC_F_D <= 32'b0;
    end
    else if (Flush) begin
        Instr_D <= 32'b0;
        PCPlus4_D <= 32'b0;
        PC_F_D <= 32'b0;
    end
    else if (!Stall) begin
        Instr_D <= Instr_F;
        PCPlus4_D <= PCPlus4_F;
        PC_F_D <= PC_F;  // 传递PC_F
    end
end

endmodule