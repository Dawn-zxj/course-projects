// PipelineReg_ID_EX.v
module PipelineReg_ID_EX(
    input CLK,
    input Reset,
    input Stall,
    input Flush,
    
    // 来自ID阶段的控制信号
    input MemtoReg_D,
    input MemWrite_D,
    input ALUSrc_D,
    input RegWrite_D,
    input [1:0] ALUControl_D,
    input [1:0] ImmSrc_D,
    input [2:0] RegSrc_D,
    input PCSrc_D,
    input M_Start_D,
    input [1:0] MCycleOp_D,  // 修改为[1:0]
    input M_Write_D,
    input [1:0] FlagW_D,
    input CondEx_D,
    
    // 来自ID阶段的数据信号
    input [31:0] RD1_D,
    input [31:0] RD2_D,
    input [31:0] ExtImm_D,
    input [31:0] PCPlus4_D,
    input [31:0] PC_D,
    input [3:0] RA1_D,
    input [3:0] RA2_D,
    input [3:0] RA3_D,
    input [31:0] Instr_D,
    
    // 输出到EX阶段
    output reg MemtoReg_E,
    output reg MemWrite_E,
    output reg ALUSrc_E,
    output reg RegWrite_E,
    output reg [1:0] ALUControl_E,
    output reg [1:0] ImmSrc_E,
    output reg [2:0] RegSrc_E,
    output reg PCSrc_E,
    output reg M_Start_E,
    output reg [1:0] MCycleOp_E,  // 修改为[1:0]
    output reg M_Write_E,
    output reg [1:0] FlagW_E,
    output reg CondEx_E,
    
    output reg [31:0] RD1_E,
    output reg [31:0] RD2_E,
    output reg [31:0] ExtImm_E,
    output reg [31:0] PCPlus4_E,
    output reg [31:0] PC_E,
    output reg [3:0] RA1_E,
    output reg [3:0] RA2_E,
    output reg [3:0] RA3_E,
    output reg [31:0] Instr_E
);

always @(posedge CLK or posedge Reset) begin
    if (Reset) begin
        // 控制信号复位
        MemtoReg_E <= 1'b0;
        MemWrite_E <= 1'b0;
        ALUSrc_E <= 1'b0;
        RegWrite_E <= 1'b0;
        ALUControl_E <= 2'b00;
        ImmSrc_E <= 2'b00;
        RegSrc_E <= 3'b000;
        PCSrc_E <= 1'b0;
        M_Start_E <= 1'b0;
        MCycleOp_E <= 2'b00;
        M_Write_E <= 1'b0;
        FlagW_E <= 2'b00;
        CondEx_E <= 1'b0;
        
        // 数据信号复位
        RD1_E <= 32'b0;
        RD2_E <= 32'b0;
        ExtImm_E <= 32'b0;
        PCPlus4_E <= 32'b0;
        PC_E <= 32'b0;
        RA1_E <= 4'b0000;
        RA2_E <= 4'b0000;
        RA3_E <= 4'b0000;
        Instr_E <= 32'b0;
    end
    else if (Flush) begin
        // 清空控制信号（插入NOP）
        MemtoReg_E <= 1'b0;
        MemWrite_E <= 1'b0;
        ALUSrc_E <= 1'b0;
        RegWrite_E <= 1'b0;
        ALUControl_E <= 2'b00;
        ImmSrc_E <= 2'b00;
        RegSrc_E <= 3'b000;
        PCSrc_E <= 1'b0;
        M_Start_E <= 1'b0;
        MCycleOp_E <= 2'b00;
        M_Write_E <= 1'b0;
        FlagW_E <= 2'b00;
        CondEx_E <= 1'b0;
        
        // 部分数据信号清空
        RD1_E <= 32'b0;
        RD2_E <= 32'b0;
        ExtImm_E <= 32'b0;
    end
    else if (!Stall) begin
        // 传递控制信号
        MemtoReg_E <= MemtoReg_D;
        MemWrite_E <= MemWrite_D;
        ALUSrc_E <= ALUSrc_D;
        RegWrite_E <= RegWrite_D;
        ALUControl_E <= ALUControl_D;
        ImmSrc_E <= ImmSrc_D;
        RegSrc_E <= RegSrc_D;
        PCSrc_E <= PCSrc_D;
        M_Start_E <= M_Start_D;
        MCycleOp_E <= MCycleOp_D;
        M_Write_E <= M_Write_D;
        FlagW_E <= FlagW_D;
        CondEx_E <= CondEx_D;
        
        // 传递数据信号
        RD1_E <= RD1_D;
        RD2_E <= RD2_D;
        ExtImm_E <= ExtImm_D;
        PCPlus4_E <= PCPlus4_D;
        PC_E <= PC_D;
        RA1_E <= RA1_D;
        RA2_E <= RA2_D;
        RA3_E <= RA3_D;
        Instr_E <= Instr_D;
    end
end

endmodule