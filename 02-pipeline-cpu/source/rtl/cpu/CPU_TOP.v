`include "CPU_define.v"
module CPU (
    input         clk,
    input         rst_n,
    input         run,
    

    // Interface to IROM
    output [31:0]  pc,
    input  [31:0]  instruction,

    // Interface to DRAM & MMIO
    output [31:0]  perip_addr,
    output [31:0]  perip_wdata,
    output         perip_wen,
    output [1:0]   perip_mask,
    input  [31:0]  perip_rdata
);


    // ========== 内部信号声明 ==========
    wire [31:0] curPC, nextPC;
    wire [4:0] rs1, rs2, rd;
    wire [31:0] ReadData1, ReadData2;
    wire [31:0] AluOutput;
    wire [31:0] DB;
    //wire [31:0] instr;
    wire [7:0] op;
    wire [24:0] imm;        // 指令分割imm段
    wire [31:0] extend;     // 立即数
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] DataOut;   // 存储器读数据
    wire [1:0] cmp;        // 比较器输出
    
    // 控制信号
    wire PCSrc;
    wire [2:0] AluOp;
    wire AluSrc1;
    wire AluSrc2;
    wire RegWr;
    wire [1:0] RegDst;
    wire [2:0] ExtSel;
    wire Sign;
    wire [1:0] Digit;
    wire DataWr;
    wire immres;
// 在CPU顶层添加
wire pc_pause;

// ControlUnit检测特定指令
//assign instruction_pause = (op == 7'b0000011) ? 1'b1 : 1'b0;
    
    // ========== 模块实例化 ==========
    
    // PC模块 - 注意调整复位信号
    PC pc_module(
        .CLK(clk),                    // 时钟
        .Reset(!rst_n),               // 将低有效复位转换为高有效
        .PCSrc(PCSrc),                // PC选择信号
        .AluOutput(AluOutput),        // ALU计算结果
        .curPC(curPC),                // 当前指令地址
        .nextPC(nextPC) ,              // 下条指令地址
        .op(op)
    );
    
    // 连接IROM接口
    assign pc = curPC;  // 输出PC到外部指令存储器
    
    // 指令存储器接口
    InsMEM insmem(
        .curPC(curPC),      // PC值
        .op(op),            // 操作码位段
        .funct3(funct3),    // 3位功能码位段
        .funct7(funct7),    // 7位功能码位段
        .rs1(rs1),          // rs1地址位段
        .rs2(rs2),          // rs2地址位段
        .rd(rd),            // rd地址位段
        .imm(imm),          // 立即数位段
        .instr(instruction) // 从外部输入的指令
    );
    
    // 立即数扩展
    Extend ext(
        .imm(imm),          // 立即数字段
        .Sign(Sign),        // 扩展符号
        .ExtSel(ExtSel),    // 扩展方式
        .extend(extend)     // 扩展后立即数
    );
    
    // 控制单元
    ControlUnit control(
        .cmp(cmp),          // 比较器结果
        .op(op),            // 操作码
        .funct3(funct3),    // 3位功能码
        .funct7(funct7),    // 7位功能码
        .PCSrc(PCSrc),      // PC下一步取值方式
        .AluOp(AluOp),      // ALU操作
        .Alu1Src(AluSrc1),  // ALU1口
        .Alu2Src(AluSrc2),  // ALU2口
        .RegDst(RegDst),    // Rd位选
        .RegWr(RegWr),      // Rd写使能
        .ExtSel(ExtSel),    // 立即数扩展式
        .Sign(Sign),        // 立即数符号扩展
        .Digit(Digit),      // 读写位数
        .DataWr(DataWr),    // 存储器写使能
        .immres(immres)   // rd是否选择imm直接作为数据
    );
    
    // 寄存器文件
    RegisterFile regfile(
        .CLK(clk),            // 时钟
        .immres(immres),      // 立即数直接写入信号
        .rs1(rs1),            // rs1寄存器地址
        .rs2(rs2),            // rs2寄存器地址
        .WriteReg(rd),        // rd地址
        .AluOutput(AluOutput),  // ALU输出
        .extend(extend),      // 扩展后立即数
        .perip_rdata(perip_rdata),     // 存储器输出
        .PC(curPC),           // 当前PC值
        .cmp(cmp),            // 比较器输出
        .RegDst(RegDst),      // 输入具体数据位选
        .RegWr(RegWr),        // 写使能信号
        .DB(DB),              // DB总线数据
        .ReadData1(ReadData1),  // rs1内数据
        .ReadData2(ReadData2)   // rs2内数据
    );
    
    // ALU
    ALU alu_module(
        .ALUSrc1(AluSrc1),     // 输入端1位选
        .ALUSrc2(AluSrc2),     // 输入端2位选
        .ReadData1(ReadData1), // rs1寄存器读取数据
        .ReadData2(ReadData2), // rs2寄存器读取数据
        .extend(extend),       // 扩展后立即数
        .PC(curPC),            // 当前地址用于计算跳转地址
        .AluOp(AluOp),         // ALU功能码
        .cmp(cmp),             // 比较器输出结果
        .AluOutput(AluOutput),  // ALU计算结果
        .funct3(funct3),
        .op(op)
    );
    
    // 数据存储器
    DataMEM datamem(
        .DataWr(DataWr),      // 存储器写使能
        .Digit(Digit),        // 读写位数
        .CLK(clk),            // 时钟
        .DAddr(AluOutput),    // 写入地址
        .perip_rdata(ReadData2),   // 写入数据
        .DataOut(DataOut)     // 输出数据
    );
    
    // ========== 连接外部DRAM/MMIO接口 ==========
    // 将内部数据存储器接口连接到外部DRAM/MMIO接口
    assign perip_addr = AluOutput;    // ALU输出作为外设地址
    assign perip_wdata = ReadData2;   // rs2数据作为写入数据
    assign perip_wen = DataWr;        // 存储器写使能
    assign perip_mask = Digit;        // 读写位宽控制
endmodule