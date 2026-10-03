// ControlUnit_Pipelined.v
module ControlUnit_Pipelined(
    input [31:0] Instr,
    input [3:0] ALUFlags,
    input CLK,
    input Reset,
    
    output MemtoReg,
    output MemWrite,
    output ALUSrc,
    output [1:0] ImmSrc,
    output RegWrite,
    output [2:0] RegSrc,
    output [1:0] ALUControl,
    output PCSrc,
    output M_Start,
    output [1:0] MCycleOp,  // ¸ÄÎª[1:0]
    output M_Write,
    output [1:0] FlagW,
    output CondEx,
    output [3:0] FlagOut
);

wire [3:0] Cond;
wire PSC, RegW, MemW, NoWrite;
wire [1:0] FlagW_internal;
wire M_W;
wire CondEx_internal;

assign Cond = Instr[31:28];

CondLogic CondLogic1(
    .CLK(CLK),
    .Reset(Reset),
    .PCS(PSC),
    .RegW(RegW),
    .MemW(MemW),
    .NoWrite(NoWrite),
    .FlagW(FlagW_internal),
    .Cond(Cond),
    .ALUFlags(ALUFlags),
    .M_W(M_W),
    
    .PCSrc(PCSrc),
    .RegWrite(RegWrite),
    .MemWrite(MemWrite),
    .M_Write(M_Write),
    .CondEx(CondEx_internal),
    .FlagOut(FlagOut)
);

Decoder Decoder1(
    .Instr(Instr),
    
    .PCS(PSC),
    .RegW(RegW),
    .MemW(MemW),
    .MemtoReg(MemtoReg),
    .ALUSrc(ALUSrc),
    .ImmSrc(ImmSrc),
    .RegSrc(RegSrc),
    .ALUControl(ALUControl),
    .FlagW(FlagW_internal),
    .NoWrite(NoWrite),
    .M_Start(M_Start),
    .MCycleOp(MCycleOp),
    .M_W(M_W)
);

assign FlagW = FlagW_internal;
assign CondEx = CondEx_internal;

endmodule