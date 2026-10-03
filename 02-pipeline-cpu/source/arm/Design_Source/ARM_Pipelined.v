// ARM_Pipelined.v
module ARM_Pipelined(
    input CLK,
    input Reset,
    input [31:0] Instr,
    input [31:0] ReadData,
    
    output MemWrite,
    output [31:0] PC,
    output [31:0] ALUResult,
    output [31:0] WriteData
);

// ================================================
//                 IF阶段
// ================================================
wire [31:0] PCPlus4_F;
wire PCSrc_E;
wire [31:0] BranchTarget_E;

ProgramCounter_Pipelined PC1(
    .CLK(CLK),
    .Reset(Reset),
    .StallF(StallF),
    .PCSrc(PCSrc_E),
    .BranchTarget(BranchTarget_E),
    .PC(PC),
    .PCPlus4(PCPlus4_F)
);

// ================================================
//                 IF/ID流水线寄存器
// ================================================
wire [31:0] Instr_D;
wire [31:0] PCPlus4_D;
wire [31:0] PC_F;

PipelineReg_IF_ID reg_if_id(
    .CLK(CLK),
    .Reset(Reset),
    .Stall(StallD),
    .Flush(FlushD),
    .Instr_F(Instr),
    .PCPlus4_F(PCPlus4_F),
    .PC_F(PC),  // 传递PC值
    .Instr_D(Instr_D),
    .PCPlus4_D(PCPlus4_D),
    .PC_F_D(PC_F)
);

// ================================================
//                 ID阶段
// ================================================
wire MemtoReg_D, MemWrite_D, ALUSrc_D;
wire [1:0] ImmSrc_D;
wire RegWrite_D;
wire [2:0] RegSrc_D;
wire [1:0] ALUControl_D;
wire PCSrc_D;
wire M_Start_D;
wire [1:0] MCycleOp_D;
wire M_Write_D;
wire [1:0] FlagW_D;
wire CondEx_D;
wire [3:0] FlagOut_D;

// 计算ID阶段的PC值
wire [31:0] PC_D;
assign PC_D = PCPlus4_D - 32'd4;

// 条件标志转发
wire [3:0] ALUFlags_D_forwarded;
wire [3:0] stored_ALUFlags_D;
assign stored_ALUFlags_D = FlagOut_D;
assign ALUFlags_D_forwarded = (ForwardFlagsD == 2'b01) ? ALUFlags_E :
                             (ForwardFlagsD == 2'b10) ? ALUFlags_M :
                             stored_ALUFlags_D;

ControlUnit_Pipelined ControlUnit_D(
    .Instr(Instr_D),
    .ALUFlags(ALUFlags_D_forwarded),
    .CLK(CLK),
    .Reset(Reset),
    .MemtoReg(MemtoReg_D),
    .MemWrite(MemWrite_D),
    .ALUSrc(ALUSrc_D),
    .ImmSrc(ImmSrc_D),
    .RegWrite(RegWrite_D),
    .RegSrc(RegSrc_D),
    .ALUControl(ALUControl_D),
    .PCSrc(PCSrc_D),
    .M_Start(M_Start_D),
    .MCycleOp(MCycleOp_D),
    .M_Write(M_Write_D),
    .FlagW(FlagW_D),
    .CondEx(CondEx_D),
    .FlagOut(FlagOut_D)
);

wire [3:0] RA1_D, RA2_D, RA3_D;
wire [31:0] R15_D;
wire [31:0] RD1_D, RD2_D;

assign RA1_D = RegSrc_D[2] ? Instr_D[11:8] : (RegSrc_D[0] ? 4'd15 : Instr_D[19:16]);
assign RA2_D = RegSrc_D[1] ? Instr_D[15:12] : Instr_D[3:0];
assign RA3_D = RegSrc_D[2] ? Instr_D[19:16] : Instr_D[15:12];
assign R15_D = PCPlus4_D + 32'd4;

// 寄存器文件读数据的中间寄存器
reg [31:0] RD1_D_reg, RD2_D_reg;

always @(negedge CLK or posedge Reset) begin
    if (Reset) begin
        RD1_D_reg <= 32'b0;
        RD2_D_reg <= 32'b0;
    end else if (!StallD) begin
        RD1_D_reg <= RD1_D;
        RD2_D_reg <= RD2_D;
    end
end

wire [31:0] RD1_D_final = RD1_D_reg;
wire [31:0] RD2_D_final = RD2_D_reg;

RegisterFile_Pipelined RF_D(
    .CLK(CLK),
    .WE3(RegWrite_W),
    .A1(RA1_D),
    .A2(RA2_D),
    .A3(RA3_W),
    .WD3(Result_W),
    .R15(R15_D),
    .RD1(RD1_D),
    .RD2(RD2_D)
);

wire [31:0] ExtImm_D;
Extend Extend_D(
    .ImmSrc(ImmSrc_D),
    .InstrImm(Instr_D[23:0]),
    .ExtImm(ExtImm_D)
);

// ================================================
//                冒险检测单元
// ================================================
wire StallF, StallD, StallE;
wire FlushE, FlushD;
wire [1:0] ForwardAE, ForwardBE;
wire ForwardAD, ForwardBD;
wire ForwardStore_E, ForwardStore_M;
wire [1:0] ForwardFlagsD;
wire [2:0] NOPCount;

wire [3:0] RA1_E, RA2_E, RA3_E;
wire [3:0] RA2_M, RA3_M, RA3_W;  // 修正：明确定义各个阶段的寄存器地址
wire RegWrite_E, RegWrite_M, RegWrite_W;
wire MemtoReg_E, MemtoReg_M, MemtoReg_W;
wire MemWrite_E, MemWrite_M;
wire PCSrc_E;
wire M_Start_E, M_Busy;
wire [1:0] FlagW_E, FlagW_M;
wire CondEx_E, CondEx_M;
wire [3:0] ALUFlags_E, ALUFlags_M;
wire [1:0] MCycleOp_E;

// 修改：为RA2_M定义明确的信号
wire [3:0] RA2_M_wire;  // 明确的wire信号

HazardUnit_with_Flags HazardUnit1(
    // 时钟和复位信号
    .CLK(CLK),
    .Reset(Reset),
    
    // 寄存器地址
    .RA1_D(RA1_D), .RA2_D(RA2_D),
    .RA1_E(RA1_E), .RA2_E(RA2_E),
    .RA2_M(RA2_M_wire),  // 使用明确的信号
    .WA3_E(RA3_E), .WA3_M(RA3_M), .WA3_W(RA3_W),
    
    // 控制信号
    .RegWrite_E(RegWrite_E), .RegWrite_M(RegWrite_M), .RegWrite_W(RegWrite_W),
    .MemtoReg_E(MemtoReg_E), .MemtoReg_M(MemtoReg_M), .MemtoReg_W(MemtoReg_W),
    .MemWrite_E(MemWrite_E), .MemWrite_M(MemWrite_M),
    .PCSrc_E(PCSrc_E),
    .M_Start_E(M_Start_E),
    .M_Busy(M_Busy),
    .MCycleOp_E(MCycleOp_E),
    
    // 条件标志转发相关信号
    .ALUFlags_E(ALUFlags_E),
    .ALUFlags_M(ALUFlags_M),
    .FlagW_E(FlagW_E), .FlagW_M(FlagW_M),
    .CondEx_E(CondEx_E), .CondEx_M(CondEx_M),
    
    // 输出控制信号
    .StallF(StallF), .StallD(StallD), .StallE(StallE),
    .FlushE(FlushE), .FlushD(FlushD),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .ForwardAD(ForwardAD), .ForwardBD(ForwardBD),
    .ForwardStore_E(ForwardStore_E),
    .ForwardStore_M(ForwardStore_M),
    .ForwardFlagsD(ForwardFlagsD),
    .NOPCount(NOPCount)
);

// ================================================
//                ID/EX流水线寄存器
// ================================================
wire [31:0] RD1_E, RD2_E, ExtImm_E, PCPlus4_E, PC_E;
wire [31:0] Instr_E;

// 分支目标地址计算
wire [31:0] BranchTarget_D;
assign BranchTarget_D = PC_D + (ExtImm_D << 2);

PipelineReg_ID_EX reg_id_ex(
    .CLK(CLK),
    .Reset(Reset),
    .Stall(StallE),
    .Flush(FlushE),
    
    // ID阶段的控制信号
    .MemtoReg_D(MemtoReg_D), .MemWrite_D(MemWrite_D),
    .ALUSrc_D(ALUSrc_D), .RegWrite_D(RegWrite_D),
    .ALUControl_D(ALUControl_D), .ImmSrc_D(ImmSrc_D),
    .RegSrc_D(RegSrc_D), .PCSrc_D(PCSrc_D),
    .M_Start_D(M_Start_D), .MCycleOp_D(MCycleOp_D),
    .M_Write_D(M_Write_D), .FlagW_D(FlagW_D), .CondEx_D(CondEx_D),
    
    // ID阶段的数据信号
    .RD1_D(RD1_D_final), .RD2_D(RD2_D_final), .ExtImm_D(ExtImm_D),
    .PCPlus4_D(PCPlus4_D), .PC_D(PC_D),
    .RA1_D(RA1_D), .RA2_D(RA2_D), .RA3_D(RA3_D),
    .Instr_D(Instr_D),
    
    // 输出到EX阶段
    .MemtoReg_E(MemtoReg_E), .MemWrite_E(MemWrite_E),
    .ALUSrc_E(ALUSrc_E), .RegWrite_E(RegWrite_E),
    .ALUControl_E(ALUControl_E), .ImmSrc_E(ImmSrc_E),
    .RegSrc_E(RegSrc_E), .PCSrc_E(PCSrc_E),
    .M_Start_E(M_Start_E), .MCycleOp_E(MCycleOp_E),
    .M_Write_E(M_Write_E), .FlagW_E(FlagW_E), .CondEx_E(CondEx_E),
    .RD1_E(RD1_E), .RD2_E(RD2_E), .ExtImm_E(ExtImm_E),
    .PCPlus4_E(PCPlus4_E), .PC_E(PC_E),
    .RA1_E(RA1_E), .RA2_E(RA2_E), .RA3_E(RA3_E),
    .Instr_E(Instr_E)
);

// 在EX阶段重新计算分支目标地址
wire [31:0] BranchTarget_E;
assign BranchTarget_E = PC_E + (ExtImm_E << 2);

// ================================================
//                 EX阶段
// ================================================
wire [31:0] ForwardedRD1_E, ForwardedRD2_E;
assign ForwardedRD1_E = (ForwardAE == 2'b10) ? ALUResult_M :
                       (ForwardAE == 2'b01) ? Result_W :
                       RD1_E;

assign ForwardedRD2_E = (ForwardBE == 2'b10) ? ALUResult_M :
                       (ForwardBE == 2'b01) ? Result_W :
                       RD2_E;

// Store数据转发（EX阶段）
wire [31:0] StoreData_E;
assign StoreData_E = ForwardStore_E ? 
                    ((ForwardBE == 2'b10) ? ALUResult_M : 
                     (ForwardBE == 2'b01) ? Result_W : 
                     ForwardedRD2_E) : 
                    ForwardedRD2_E;

wire [31:0] ShOut_E;
Shifter Shifter_E(
    .Sh(Instr_E[6:5]),
    .Shamt5(Instr_E[11:7]),
    .ShIn(ForwardedRD2_E),
    .ShOut(ShOut_E)
);

wire [31:0] SrcA_E, SrcB_E;
assign SrcA_E = ForwardedRD1_E;
assign SrcB_E = ALUSrc_E ? ExtImm_E : ShOut_E;

wire [31:0] ALUResult_E;
ALU ALU_E(
    .Src_A(SrcA_E),
    .Src_B(SrcB_E),
    .ALUControl(ALUControl_E),
    .ALUResult(ALUResult_E),
    .ALUFlags(ALUFlags_E)
);

wire [31:0] MCycleResult_E;
MCycle MCycle_E(
    .CLK(CLK),
    .RESET(Reset),
    .Start(M_Start_E),
    .MCycleOp(MCycleOp_E[0]),  // 只使用最低位
    .Operand1(ForwardedRD1_E),
    .Operand2(ForwardedRD2_E),
    .Result(MCycleResult_E),
    .Busy(M_Busy)
);

wire [31:0] OpResult_E;
assign OpResult_E = M_Write_E ? MCycleResult_E : ALUResult_E;

// ================================================
//                EX/MEM流水线寄存器
// ================================================
wire [31:0] ALUResult_M, WriteData_M, PCPlus4_M;
wire [31:0] Instr_M;

// 修改：使用中间信号传递RA2_E到RA2_M
assign RA2_M_wire = RA2_E;  // 明确的赋值

PipelineReg_EX_MEM reg_ex_mem(
    .CLK(CLK),
    .Reset(Reset),
    .Stall(1'b0),
    .Flush(1'b0),
    
    // EX阶段的控制信号
    .MemtoReg_E(MemtoReg_E), .MemWrite_E(MemWrite_E), .RegWrite_E(RegWrite_E),
    .FlagW_E(FlagW_E), .CondEx_E(CondEx_E),
    
    // EX阶段的数据信号
    .ALUResult_E(OpResult_E),
    .WriteData_E(StoreData_E),
    .PCPlus4_E(PCPlus4_E),
    .RA2_E(RA2_E),  // 明确的连接
    .RA3_E(RA3_E),
    .Instr_E(Instr_E),
    
    // 输出到MEM阶段
    .MemtoReg_M(MemtoReg_M), .MemWrite_M(MemWrite_M), .RegWrite_M(RegWrite_M),
    .FlagW_M(FlagW_M), .CondEx_M(CondEx_M),
    .ALUResult_M(ALUResult_M), .WriteData_M(WriteData_M),
    .PCPlus4_M(PCPlus4_M),
    .RA2_M(RA2_M),  // 输出
    .RA3_M(RA3_M),
    .Instr_M(Instr_M)
);

// ================================================
//                MEM阶段
// ================================================
// Store数据转发（MEM阶段）- 解决Load-Store冒险
wire [31:0] FinalWriteData_M;
assign FinalWriteData_M = ForwardStore_M ? Result_W : WriteData_M;

assign MemWrite = MemWrite_M;
assign WriteData = FinalWriteData_M;
assign ALUResult = ALUResult_M;

wire [31:0] ReadData_M;
assign ReadData_M = ReadData;

// ================================================
//                MEM/WB流水线寄存器
// ================================================
wire MemtoReg_W, RegWrite_W;
wire [31:0] ALUResult_W, ReadData_W, PCPlus4_W;
wire [31:0] Instr_W;

PipelineReg_MEM_WB reg_mem_wb(
    .CLK(CLK),
    .Reset(Reset),
    .Stall(1'b0),
    .Flush(1'b0),
    
    // MEM阶段的控制信号
    .MemtoReg_M(MemtoReg_M), .RegWrite_M(RegWrite_M),
    
    // MEM阶段的数据信号
    .ALUResult_M(ALUResult_M),
    .ReadData_M(ReadData_M),
    .PCPlus4_M(PCPlus4_M),
    .RA3_M(RA3_M),
    .Instr_M(Instr_M),
    
    // 输出到WB阶段
    .MemtoReg_W(MemtoReg_W), .RegWrite_W(RegWrite_W),
    .ALUResult_W(ALUResult_W), .ReadData_W(ReadData_W),
    .PCPlus4_W(PCPlus4_W),
    .RA3_W(RA3_W),
    .Instr_W(Instr_W)
);

// ================================================
//                WB阶段
// ================================================
wire [31:0] Result_W;
assign Result_W = MemtoReg_W ? ReadData_W : ALUResult_W;

endmodule