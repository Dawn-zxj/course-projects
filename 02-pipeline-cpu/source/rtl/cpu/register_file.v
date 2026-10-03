module RegisterFile(
    input CLK,              // 时钟信号
    input immres,           // 立即数直接写入信号
    input [4:0] rs1,        // rs1寄存器地址输入端口
    input [4:0] rs2,        // rs2寄存器地址输入端口
    input [4:0] WriteReg,   // rd输入地址
    input [31:0] AluOutput, // ALU输出
    input [31:0] extend,    // 立即数扩展器输出
    input [31:0] perip_rdata,//Datain,    // 存储器输出
    input [31:0] PC,        // 当前PC值
    input [1:0] cmp,        // 比较器输出
    input [1:0] RegDst,     // 输入具体数据位选
    input RegWr,            // 写使能信号，时钟下降沿触发写入
    output reg [31:0] DB,    // 输入总线数据
    output reg [31:0] ReadData1, // rs1寄存器数据输出端口
    output reg [31:0] ReadData2  // rs2寄存器数据输出端口
);

    // 寄存器文件定义 (32个32位寄存器)
    reg [31:0] regFile [0:31];
        wire [31:0] R0 = regFile[0];
    wire [31:0] R1 = regFile[1];
    wire [31:0] R2 = regFile[2];
    wire [31:0] R3 = regFile[3];
    wire [31:0] R4 = regFile[4];
    wire [31:0] R5 = regFile[5];
    wire [31:0] R6 = regFile[6];
    wire [31:0] R7 = regFile[7];
    wire [31:0] R8 = regFile[8];
    wire [31:0] R9 = regFile[9];
    wire [31:0] R10 = regFile[10];
    wire [31:0] R11 = regFile[11];
    wire [31:0] R12 = regFile[12];
    wire [31:0] R13 = regFile[13];
    wire [31:0] R14 = regFile[14];
    wire [31:0] R15 = regFile[15];
    wire [31:0] R16 = regFile[16];
    wire [31:0] R17 = regFile[17];
    wire [31:0] R18 = regFile[18];
    wire [31:0] R19 = regFile[19];
wire [31:0] R20 = regFile[20];
wire [31:0] R21 = regFile[21];
wire [31:0] R22 = regFile[22];
wire [31:0] R23 = regFile[23];
wire [31:0] R24 = regFile[24];
wire [31:0] R25 = regFile[25];
wire [31:0] R26 = regFile[26];
wire [31:0] R27 = regFile[27];
wire [31:0] R28 = regFile[28];  // 你的t3
wire [31:0] R29 = regFile[29];  // 你的t4
wire [31:0] R30 = regFile[30];
wire [31:0] R31 = regFile[31];
    // 初始化寄存器文件
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regFile[i] = 32'd0;
        end
        // 确保x0寄存器始终为0
        regFile[0] = 32'd0;
    end

    // 组合逻辑读取：实时读取rs1和rs2的数据
    // 注意：这里使用always@(*)实现组合逻辑，当rs1、rs2或regFile内容变化时立即更新
    always@(*) begin
        // 读取rs1
        if (rs1 == 5'b00000) begin
            ReadData1 = 32'd0;  // x0寄存器始终为0
        end else begin
            ReadData1 = regFile[rs1];
        end
        
        // 读取rs2
        if (rs2 == 5'b00000) begin
            ReadData2 = 32'd0;  // x0寄存器始终为0
        end else begin
            ReadData2 = regFile[rs2];
        end
    end

    // 时序逻辑写入：时钟下降沿时更新rd地址的值
    always@(negedge CLK) begin
        // 如果写使能有效且目标寄存器不是x0
        if (RegWr && (WriteReg != 5'b00000)) begin
            if (immres) begin
                // immres为1时，直接写入扩展后的立即数
                regFile[WriteReg] = extend;
                DB = extend;
            end else begin
                // immres为0时，根据RegDst选择写入的数据源
                case (RegDst)
                    2'b00: begin
                        // 从ALU输出写入
                        regFile[WriteReg] = AluOutput;
                        DB = AluOutput;
                    end 
                    2'b01: begin
                        // 从数据存储器写入
                        regFile[WriteReg] = perip_rdata;
                        DB = perip_rdata;
                    end 
                    2'b10: begin
                        // 写入PC+4（用于JAL, JALR指令）
                        regFile[WriteReg] = PC + 4;
                        DB = PC + 4;
                    end 
                    2'b11: begin
                        // 写入比较结果（用于SLT, SLTI, SLTU, SLTIU指令）
                        // cmp[0] = 0: >=, cmp[0] = 1: <
                        regFile[WriteReg] = {31'b0, cmp[0]};
                        DB = {31'b0, cmp[0]};
                    end
                    default: begin
                        // 默认情况，保持原值
//                        regFile[WriteReg] = regFile[WriteReg];
                        DB = 32'b0;
                    end
                endcase
            end
        end else begin
            // 写使能无效或目标寄存器是x0，不写入
            // 不更新DB，保持DB当前值
        end
        
        // 确保x0寄存器始终为0（防御性编程）
        regFile[0] = 32'd0;
    end

endmodule