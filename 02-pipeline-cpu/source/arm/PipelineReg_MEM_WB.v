// PipelineReg_MEM_WB.v
module PipelineReg_MEM_WB(
    input CLK,
    input Reset,
    input Stall,
    input Flush,
    
    // 来自MEM阶段的控制信号
    input MemtoReg_M,
    input RegWrite_M,
    
    // 来自MEM阶段的数据信号
    input [31:0] ALUResult_M,
    input [31:0] ReadData_M,
    input [31:0] PCPlus4_M,
    input [3:0] RA3_M,
    input [31:0] Instr_M,  // 新增：传递指令
    
    // 传递到WB阶段
    output reg MemtoReg_W,
    output reg RegWrite_W,
    
    output reg [31:0] ALUResult_W,
    output reg [31:0] ReadData_W,
    output reg [31:0] PCPlus4_W,
    output reg [3:0] RA3_W,
    output reg [31:0] Instr_W  // 新增：传递指令
);

always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        MemtoReg_W <= 1'b0;
        RegWrite_W <= 1'b0;
        
        ALUResult_W <= 32'b0;
        ReadData_W <= 32'b0;
        PCPlus4_W <= 32'b0;
        RA3_W <= 4'b0000;
        Instr_W <= 32'b0;
    end
    else if (Flush) begin
        MemtoReg_W <= 1'b0;
        RegWrite_W <= 1'b0;
    end
    else if (!Stall) begin
        MemtoReg_W <= MemtoReg_M;
        RegWrite_W <= RegWrite_M;
        
        ALUResult_W <= ALUResult_M;
        ReadData_W <= ReadData_M;
        PCPlus4_W <= PCPlus4_M;
        RA3_W <= RA3_M;
        Instr_W <= Instr_M;  // 传递指令
    end
end

endmodule