module ControlUnit(
    input [1:0] cmp,        // 比较器结果
    input [7:0] op,         // 操作码
    input [2:0] funct3,     // 3位功能码
    input [6:0] funct7,     // 7位功能码
    output reg PCSrc,       // PC下一步取值方式
    output reg [2:0] AluOp, // ALU操作方式
    output reg Alu1Src,     // ALU1口位选
    output reg Alu2Src,     // ALU2口位选
    output reg [1:0] RegDst, // Rd输入数据来源
    output reg RegWr,       // Rd写使能信号
    output reg [2:0] ExtSel, // 立即数拼接方式
    output reg Sign,        // 立即数符号扩展信号
    output reg [1:0] Digit,  // 读写位数
    output reg DataWr,      // 存储器写使能
    output reg immres      // rd是否选择imm直接作为数据
);

    // 内部信号
    wire [6:0] opcode = op[6:0];  // 取7位操作码
    
    // 主控制逻辑
    always @(*) begin
        // 默认值设置
        PCSrc = 0;      // PC = PC + 4
        AluOp = 3'b000; // ADD
        Alu1Src = 0;    // A = ReadData1
        Alu2Src = 0;    // B = ReadData2
        RegDst = 2'b00; // WRdata = ALU输出
        RegWr = 0;      // 禁止写寄存器
        ExtSel = 3'b000; // I型扩展
        Sign = 1;       // 有符号扩展
        Digit = 2'b10;  // 32位读写
        DataWr = 0;     // 禁止写存储器
        immres = 0;     // rd写入看RegDst选择器
        
        // 根据操作码和功能码判断指令类型
        case(opcode)
            // R型指令
            7'b0110011: begin
                RegWr = 1;
               // Alu1Src = 0;
               // Alu2Src = 0;
               // RegDst = 2'b00;
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
                
                // 根据funct3和funct7确定具体R型指令
                case(funct3)
                    3'b000: begin
                        if (funct7[5] == 1'b0) begin // ADD
                            AluOp = 3'b000;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
end
                        else        begin             // SUB
                            AluOp = 3'b001;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
end
                    end
                    3'b001: begin               // SLL
                        AluOp = 3'b101;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
                    end
                    3'b010: begin               // SLT
                        AluOp = 3'b010;  // 有符号比较
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b11;
                    end
                    3'b011: begin               // SLTU
                        AluOp = 3'b011;  // 无符号比较
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b11;
                    end
                    3'b100: begin               // XOR
                        AluOp = 3'b010;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
                    end
                    3'b101: begin
                        if (funct7[5] == 1'b0) begin // SRL
                            AluOp = 3'b110;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
end
                        else    begin                 // SRA
                            AluOp = 3'b111;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
end
                    end
                    3'b110: begin               // OR
                        AluOp = 3'b011;
                Alu1Src = 0;
                Alu2Src = 0;
                RegDst = 2'b00;
                    end
                    3'b111: begin               // AND
                        AluOp = 3'b100; 
                Alu1Src = 0;
                Alu2Src = 0; // 注意：与XOR共用操作码，由ALU内部区分
                RegDst = 2'b00;
                    end
                endcase
            end
            
            // I型指令（算术逻辑立即数）
            7'b0010011: begin
                RegWr = 1;
                //Alu1Src = 0;
              //  Alu2Src = 1;      // 使用立即数
               // RegDst = 2'b00;
               // ExtSel = 3'b000;  // I型扩展
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
                
                // 根据funct3确定具体I型指令
                case(funct3)
                    3'b000: begin               // ADDI
                        AluOp = 3'b000;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
                        ExtSel = 3'b000; // I型直接扩展
                        Sign = 1;        // 有符号扩展


                    end
                    3'b001: begin               // SLLI
                        AluOp = 3'b101;
                        Sign = 1;
                        ExtSel = 3'b101;  // 移位立即数特殊扩展
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出

                    end
                    3'b010: begin               // SLTI
                        AluOp = 3'b010;
                        Sign = 1;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用lijishu
                        RegDst = 2'b11;  
                        ExtSel = 3'b000; // I型直接扩展
                    end
                    3'b011: begin               // SLTIU
                        AluOp = 3'b011;
                        Sign = 0;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b11;  // WRdata = ALU输出
                        ExtSel = 3'b000; // I型直接扩展
                    end
                    3'b100: begin               // XORI
                        AluOp = 3'b100;
                        Sign = 1;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
                        ExtSel = 3'b000; // I型直接扩展
                    end
                    3'b101: begin               // SRLI/SRAI
                        if (funct7[5] == 1'b0)begin  // SRLI
                            AluOp = 3'b110;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
                        ExtSel = 3'b101; // I型直接扩展
end
                        else     begin                // SRAI
                            AluOp = 3'b111;
                        Sign = 1;
                        ExtSel = 3'b101;  // 移位立即数特殊扩展
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
end
                    end
                    3'b110: begin               // ORI
                        AluOp = 3'b011;
                        Sign = 1;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
                        ExtSel = 3'b000; // I型直接扩展
                    end
                    3'b111: begin               // ANDI
                        AluOp = 3'b100;  // 注意：与XORI共用操作码
                        Sign = 1;
                        Alu1Src = 0;     // 使用ReadData1
                        Alu2Src = 1;     // 使用立即数
                        RegDst = 2'b00;  // WRdata = ALU输出
                        ExtSel = 3'b000; // I型直接扩展
                    end
                endcase
            end
            
            // I型指令（加载指令）
            7'b0000011: begin
                RegWr = 1;
                Alu1Src = 0;
                Alu2Src = 1;      // 使用立即数
                RegDst = 2'b01;   // WRdata = DataMEM输出
                ExtSel = 3'b000;  // I型扩展
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
                AluOp = 3'b000;   // ADD用于地址计算
                
                // 根据funct3确定具体加载类型
                case(funct3)
                    3'b000: begin  // LB
                        Digit = 2'b00;
                        Sign = 1;

                    end
                    3'b001: begin  // LH
                        Digit = 2'b01;
                        Sign = 1;

                    end
                    3'b010: begin  // LW
                        Digit = 2'b10;
                        Sign = 1;

                    end
                    3'b100: begin  // LBU
                        Digit = 2'b00;
                        Sign = 0;

                    end
                    3'b101: begin  // LHU
                        Digit = 2'b01;
                        Sign = 0;

                    end
                endcase
            end
            
            // S型指令（存储指令）
            7'b0100011: begin
                RegWr = 0;        // 存储指令不写寄存器
                Alu1Src = 0;
                Alu2Src = 1;      // 使用立即数
                ExtSel = 3'b001;  // S型扩展
                Sign = 1;
                DataWr = 1;       // 允许写存储器
                immres = 0;
                AluOp = 3'b000;   // ADD用于地址计算
                
                // 根据funct3确定具体存储类型
                case(funct3)
                    3'b000: begin  // SB
                        Digit = 2'b00;
                    end
                    3'b001: begin  // SH
                        Digit = 2'b01;
                    end
                    3'b010: begin  // SW
                        Digit = 2'b10;
                    end
                    default: Digit = 2'b10;
                endcase
            end
            
            // B型指令（分支指令）- 关键修正！
            7'b1100011: begin
                RegWr = 0;        // 分支指令不写寄存器
                Alu1Src = 1;
                Alu2Src = 1;      // 使用立即数
                ExtSel = 3'b010;  // B型扩展
               // Sign = 1;
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
                AluOp = 3'b000;   // ADD用于地址计算
                
                // 根据funct3确定具体分支类型
                // 注意：ControlUnit没有ReadData输入，所以比较必须在ALU中完成
                // 这里只需要根据funct3设置PCSrc的逻辑
                // ALU的cmp输出已经包含了比较结果
                case(funct3)
                    3'b000: begin  // BEQ
                        // 相等跳转：cmp=00表示相等
                        PCSrc = (cmp == 2'b00);
Sign = 1;
                    end
                    3'b001: begin  // BNE
                        // 不等跳转：cmp≠00表示不相等
                        PCSrc = (cmp != 2'b00);
Sign = 1;
                    end
                    3'b100: begin  // BLT (关键！你的程序使用这个)
                        // 有符号小于跳转：cmp=01表示小于

                        PCSrc = (cmp == 2'b01);
Sign = 1;
                    end
                    3'b101: begin  // BGE
                        // 有符号大于等于跳转：cmp≠01表示大于等于

                        PCSrc = (cmp != 2'b01);
Sign = 1;
                    end
                    3'b110: begin  // BLTU
                        // 无符号小于跳转：比较在ALU中完成
                        // 这里使用cmp[1]位表示无符号比较结果

                        PCSrc = (cmp == 2'b01);
Sign = 0;
                    end
                    3'b111: begin  // BGEU
                        // 无符号大于等于跳转

                        PCSrc = (cmp == 2'b01);
Sign = 0;
                    end
                endcase
            end
            
            // U型指令（LUI）
            7'b0110111: begin
                RegWr = 1;
                RegDst = 2'b00;
                ExtSel = 3'b011;  // U型扩展
                Sign = 1;
                Digit = 2'b10;
                DataWr = 0;
                immres = 1;      // WRdata = extend
                AluOp = 3'b000;  // 不关心
            end
            
            // U型指令（AUIPC）
            7'b0010111: begin
                RegWr = 1;
                Alu1Src = 1;     // A = PC
                Alu2Src = 1;     // B = 立即数
                AluOp = 3'b000;  // ADD
                RegDst = 2'b00;
                ExtSel = 3'b011;  // U型扩展
                Sign = 1;
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
            end
            
            // J型指令（JAL）
            7'b1101111: begin
                RegWr = 1;
                Alu1Src = 1;     // A = PC
                Alu2Src = 1;     // B = 立即数
                AluOp = 3'b000;  // ADD
                RegDst = 2'b10;  // WRdata = PC + 4
                PCSrc = 1;       // 跳转
                ExtSel = 3'b100; // J型扩展
                Sign = 1;
                Digit = 2'b10;
                DataWr = 0;
                immres = 0;
            end
            
            // I型指令（JALR）
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    RegWr = 1;
                    Alu1Src = 0;     // A = ReadData1
                    Alu2Src = 1;     // B = 立即数
                    AluOp = 3'b000;  // ADD
                    RegDst = 2'b10;  // WRdata = PC + 4
                    PCSrc = 1;       // 跳转
                    ExtSel = 3'b000; // I型扩展
                    Sign = 1;
                    Digit = 2'b10;
                    DataWr = 0;
                    immres = 0;
                end
            end
            
            // 默认情况
            default: begin
                // 所有控制信号保持默认值
                PCSrc = 0;
                RegWr = 0;
                DataWr = 0;
            end
        endcase
    end

endmodule