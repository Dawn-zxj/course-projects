// PipelineReg_EX_MEM.v
module PipelineReg_EX_MEM(
    input CLK,
    input Reset,
    input Stall,
    input Flush,
    
    // 来自EX阶段的控制信号
    input MemtoReg_E,
    input MemWrite_E,
    input RegWrite_E,
    input [1:0] FlagW_E,
    input CondEx_E,
    
    // 来自EX阶段的数据信号
    input [31:0] ALUResult_E,
    input [31:0] WriteData_E,
    input [31:0] PCPlus4_E,
    input [3:0] RA2_E,  // 新增：传递RA2
    input [3:0] RA3_E,
    input [31:0] Instr_E,
    
    // 输出到MEM阶段
    output reg MemtoReg_M,
    output reg MemWrite_M,
    output reg RegWrite_M,
    output reg [1:0] FlagW_M,
    output reg CondEx_M,
    
    output reg [31:0] ALUResult_M,
    output reg [31:0] WriteData_M,
    output reg [31:0] PCPlus4_M,
    output reg [3:0] RA2_M,  // 新增
    output reg [3:0] RA3_M,
    output reg [31:0] Instr_M
);

always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        MemtoReg_M <= 1'b0;
        MemWrite_M <= 1'b0;
        RegWrite_M <= 1'b0;
        FlagW_M <= 2'b00;
        CondEx_M <= 1'b0;
        
        ALUResult_M <= 32'b0;
        WriteData_M <= 32'b0;
        PCPlus4_M <= 32'b0;
        RA2_M <= 4'b0000;
        RA3_M <= 4'b0000;
        Instr_M <= 32'b0;
    end
    else if (Flush) begin
        MemtoReg_M <= 1'b0;
        MemWrite_M <= 1'b0;
        RegWrite_M <= 1'b0;
        FlagW_M <= 2'b00;
        CondEx_M <= 1'b0;
        
        ALUResult_M <= 32'b0;
        WriteData_M <= 32'b0;
    end
    else if (!Stall) begin
        MemtoReg_M <= MemtoReg_E;
        MemWrite_M <= MemWrite_E;
        RegWrite_M <= RegWrite_E;
        FlagW_M <= FlagW_E;
        CondEx_M <= CondEx_E;
        
        ALUResult_M <= ALUResult_E;
        WriteData_M <= WriteData_E;
        PCPlus4_M <= PCPlus4_E;
        RA2_M <= RA2_E;  // 传递RA2
        RA3_M <= RA3_E;
        Instr_M <= Instr_E;
    end
end

endmodule