// Wrapper_Pipelined.v
`timescale 1ns / 1ps

module Wrapper_Pipelined
#(
    parameter N_LEDs_OUT = 16,
    parameter N_DIPs = 7
)
(
    input  [N_DIPs-1:0] DIP,
    output reg [N_LEDs_OUT-1:0] LED_16bit,  // 修改为LED_16bit以匹配TOP_Pango.v
    output reg [31:0] SEVENSEGHEX,
    input  RESET,
    input  CLK
);

//----------------------------------------------------------------
// ARM_Pipelined 信号
//----------------------------------------------------------------
wire[31:0] PC;
wire[31:0] Instr;
reg[31:0] ReadData;
wire MemWrite;
wire[31:0] ALUResult;
wire[31:0] WriteData;

//----------------------------------------------------------------
// 地址解码信号
//----------------------------------------------------------------
wire dec_DATA_CONST, dec_DATA_VAR;

//----------------------------------------------------------------
// IO读取信号
//----------------------------------------------------------------
wire [31:0] ReadData_IO;

//----------------------------------------------------------------
// 存储器声明
//-----------------------------------------------------------------
reg [31:0] INSTR_MEM [0:255];
reg [31:0] DATA_CONST_MEM [0:127];
reg [31:0] DATA_VAR_MEM [0:127];
integer i;

//----------------------------------------------------------------
// Instruction Memory
//----------------------------------------------------------------
initial begin
			INSTR_MEM[0] = 32'hE59F1204; 
			INSTR_MEM[1] = 32'hE59F2204; 
			INSTR_MEM[2] = 32'hE59F31F0; 
			INSTR_MEM[3] = 32'hE59F41F0; 
			INSTR_MEM[4] = 32'hE0815002; 
			INSTR_MEM[5] = 32'hE5835004; 
			INSTR_MEM[6] = 32'hE2833008; 
			INSTR_MEM[7] = 32'hE5135004; 
			INSTR_MEM[8] = 32'hE0416002; 
			INSTR_MEM[9] = 32'hE5046004; 
			INSTR_MEM[10] = 32'hE2444008; 
			INSTR_MEM[11] = 32'hE5946004; 
			INSTR_MEM[12] = 32'hE2013000; 
			INSTR_MEM[13] = 32'hE59FA1D8; 
			INSTR_MEM[14] = 32'hE181400A; 
			INSTR_MEM[15] = 32'hE1811004; 
			INSTR_MEM[16] = 32'hE0022003; 
			INSTR_MEM[17] = 32'hE0017801; 
			INSTR_MEM[18] = 32'hE0018821; 
			INSTR_MEM[19] = 32'hE0017447; 
			INSTR_MEM[20] = 32'hE0018848; 
			INSTR_MEM[21] = 32'hE0889005; 
			INSTR_MEM[22] = 32'hE047A006; 
			INSTR_MEM[23] = 32'hE04AB009; 
			INSTR_MEM[24] = 32'hE04BB009; 
			INSTR_MEM[25] = 32'hE001B86B; 
			INSTR_MEM[26] = 32'hE59FC1AC; 
			INSTR_MEM[27] = 32'hE18CB86B; 
			INSTR_MEM[28] = 32'hE59FA1A0; 
			INSTR_MEM[29] = 32'hE04AB00B; 
			INSTR_MEM[30] = 32'hE28BB003; 
			INSTR_MEM[31] = 32'hE28B3002; 
			INSTR_MEM[32] = 32'hE59F1194; 
			INSTR_MEM[33] = 32'hE59F2190; 
			INSTR_MEM[34] = 32'hE24BB001; 
			INSTR_MEM[35] = 32'hE2811001; 
			INSTR_MEM[36] = 32'hE35B0002; 
			INSTR_MEM[37] = 32'h1AFFFFFB; 
			INSTR_MEM[38] = 32'hE2433001; 
			INSTR_MEM[39] = 32'hE2822002; 
			INSTR_MEM[40] = 32'hE3530002; 
			INSTR_MEM[41] = 32'h1AFFFFFB; 
			INSTR_MEM[42] = 32'hE2822006; 
			INSTR_MEM[43] = 32'hE081B002; 
			INSTR_MEM[44] = 32'hE38BB001; 
			INSTR_MEM[45] = 32'hE59F1158; 
			INSTR_MEM[46] = 32'hE001B26B; 
			INSTR_MEM[47] = 32'hE59F1150; 
			INSTR_MEM[48] = 32'hE59F2144; 
			INSTR_MEM[49] = 32'hE59F3144; 
			INSTR_MEM[50] = 32'hE082B24B; 
			INSTR_MEM[51] = 32'hE082B22B; 
			INSTR_MEM[52] = 32'hE082B20B; 
			INSTR_MEM[53] = 32'hE082B26B; 
			INSTR_MEM[54] = 32'hE00BB221; 
			INSTR_MEM[55] = 32'hE183B20B; 
			INSTR_MEM[56] = 32'hE18BB44B; 
			INSTR_MEM[57] = 32'hE59FA11C; 
			INSTR_MEM[58] = 32'hE58AB000; 
			INSTR_MEM[59] = 32'hE59F9110; 
			INSTR_MEM[60] = 32'hE5891000; 
			INSTR_MEM[61] = 32'hEAFFFFFE; 
			for(i = 62; i < 128; i = i+1) begin 
				INSTR_MEM[i] = 32'h0; 
			end
end

//----------------------------------------------------------------
// Data (Constant) Memory
//----------------------------------------------------------------
initial begin
			DATA_CONST_MEM[0] = 32'h00000810; 
			DATA_CONST_MEM[1] = 32'h00000820; 
			DATA_CONST_MEM[2] = 32'h00000830; 
			DATA_CONST_MEM[3] = 32'h00000002; 
			DATA_CONST_MEM[4] = 32'h00000001; 
			DATA_CONST_MEM[5] = 32'hFFFFFFFF; 
			DATA_CONST_MEM[6] = 32'hFFFFFEFA; 
			for(i = 7; i < 128; i = i+1) begin 
				DATA_CONST_MEM[i] = 32'h0; 
			end
end


//----------------------------------------------------------------
// 实例化五级流水线ARM处理器
//----------------------------------------------------------------
ARM_Pipelined ARM_Pipelined_Inst(
    .CLK(CLK),
    .Reset(RESET),
    .Instr(Instr),
    .ReadData(ReadData),
    .MemWrite(MemWrite),
    .PC(PC),
    .ALUResult(ALUResult),
    .WriteData(WriteData)
);

//----------------------------------------------------------------
// 数据存储器地址解码
//----------------------------------------------------------------
assign dec_DATA_CONST = (ALUResult >= 32'h00000200 && ALUResult <= 32'h000003FC) ? 1'b1 : 1'b0;
assign dec_DATA_VAR   = (ALUResult >= 32'h00000800 && ALUResult <= 32'h000009FC) ? 1'b1 : 1'b0;

//----------------------------------------------------------------
// 数据存储器读取
//----------------------------------------------------------------
always @(*) begin
    if (dec_DATA_VAR)
        ReadData <= DATA_VAR_MEM[ALUResult[8:2]];
    else if (dec_DATA_CONST)
        ReadData <= DATA_CONST_MEM[ALUResult[8:2]];
    else
        ReadData <= 32'h0;
end

//----------------------------------------------------------------
// IO读取（用于七段数码管显示）
//----------------------------------------------------------------
assign ReadData_IO = DATA_VAR_MEM[DIP[6:0]];

//----------------------------------------------------------------
// 数据存储器写入
//----------------------------------------------------------------
always @(posedge CLK) begin
    if (MemWrite && dec_DATA_VAR)
        DATA_VAR_MEM[ALUResult[8:2]] <= WriteData;
end

//----------------------------------------------------------------
// 指令存储器读取
//----------------------------------------------------------------
assign Instr = INSTR_MEM[PC[9:2]];

//----------------------------------------------------------------
// LED显示：显示PC值（修改为LED_16bit）
//----------------------------------------------------------------
always @(posedge CLK or posedge RESET) begin
    if (RESET)
        LED_16bit <= 'b0;
    else
        LED_16bit <= PC[15:0];
end

//----------------------------------------------------------------
// 七段数码管显示：显示内存内容
//----------------------------------------------------------------
always @(posedge CLK or posedge RESET) begin
    if (RESET)
        SEVENSEGHEX <= 32'b0;
    else
        SEVENSEGHEX <= ReadData_IO;
end

endmodule