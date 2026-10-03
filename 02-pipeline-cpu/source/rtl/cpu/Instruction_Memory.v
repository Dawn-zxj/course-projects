module InsMEM(
    input [31:0] curPC,      // PC值
    output reg [7:0] op,     // 操作码位段
    output reg [2:0] funct3, // 3位功能码位段
    output reg [6:0] funct7, // 7位功能码位段
    output reg [4:0] rs1,    // rs1地址位段
    output reg [4:0] rs2,    // rs2地址位段
    output reg [4:0] rd,     // rd地址位段
    output reg [24:0] imm,   // 立即数位段传给extend模块拼接扩展
    input [31:0] instr  // 读取得到32位指令
);

    // 指令存储器定义 (ROM)
//    reg [7:0] rom [0:1023];  // 1KB 指令存储器，按字节寻址
   
    
//    // 小端模式, PC改变就取指令
//    always @(curPC) begin
//        // 检查PC是否超出ROM范围
//        if (curPC + 3 < 1024) begin
//            // 取指令（小端模式）
//            instr[7:0]   = rom[curPC];
//            instr[15:8]  = rom[curPC + 1];
//            instr[23:16] = rom[curPC + 2];
//            instr[31:24] = rom[curPC + 3];
//        end else begin
//            // PC超出范围，输出空指令（nop: 0x00000013）
//            instr = 32'h00000013;
//        end
//    end
    
    // 切割指令
    always @(instr) begin
        // 提取指令各字段
        op = {1'b0, instr[6:0]};     // 操作码，补0到8位
        rs1 = instr[19:15];          // 源寄存器1地址
        rs2 = instr[24:20];          // 源寄存器2地址
        rd = instr[11:7];            // 目的寄存器地址
        funct3 = instr[14:12];       // 3位功能码
        funct7 = instr[31:25];       // 7位功能码（修正：应该是[31:25]）
        imm = instr[31:7];           // 立即数字段，供扩展模块使用
    end

endmodule