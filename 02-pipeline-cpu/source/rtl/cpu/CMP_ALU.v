module ALU(
    input ALUSrc1,
    input ALUSrc2,
    input [31:0] ReadData1,
    input [31:0] ReadData2,
    input [31:0] extend,
    input [31:0] PC,
    input [2:0] AluOp,
    input [2:0] funct3,     // 功能码（用于判断有符号/无符号比较）
    input [6:0] op,
    output reg [1:0] cmp,
    output reg [31:0] AluOutput
);

    // 内部信号
    reg [31:0] A, B;
    
    // 根据指令类型选择正确的比较源
    wire [31:0] actual_operand2;
    
    // 关键修正：区分R型指令和I型指令的比较源
    assign actual_operand2 = (op == 7'b0010011 && 
                             (funct3 == 3'b010 || funct3 == 3'b011)) ? 
                            extend : ReadData2;
    
    // 有符号比较逻辑（使用正确的操作数源）
    wire signed_lt = (~ReadData1[31] & actual_operand2[31]) ? 1'b0 :
                     (ReadData1[31] & ~actual_operand2[31]) ? 1'b1 :
                     (ReadData1 < actual_operand2);
    
    wire unsigned_lt = (ReadData1 < actual_operand2);
    
    always@(*) begin
        // ALU运算输入保持原有逻辑
        A = (ALUSrc1 == 0) ? ReadData1 : PC;
        B = (ALUSrc2 == 0) ? ReadData2 : extend;
        
        // 比较器使用修正后的操作数源
        if (ReadData1 == actual_operand2) begin
            cmp = 2'b00;  // 相等
        end
        else begin
            case(funct3)
                3'b100, 3'b101, 3'b010:  // BLT, BGE, SLT/SLTI
                    cmp = signed_lt ? 2'b01 : 2'b10;
                3'b110, 3'b111, 3'b011:  // BLTU, BGEU, SLTU/SLTIU
                    cmp = unsigned_lt ? 2'b01 : 2'b10;
                default:
                    cmp = signed_lt ? 2'b01 : 2'b10;
            endcase
        end
        // -------------------------------
        // ALU算术逻辑运算
        // -------------------------------
        case(AluOp)
            3'b000: AluOutput = A + B;           // ADD
            3'b001: AluOutput = A - B;           // SUB
            3'b010: AluOutput = A ^ B;           // XOR
            3'b011: AluOutput = A | B;           // OR
            3'b100: AluOutput = A & B;           // AND
            3'b101: AluOutput = A << B[4:0];     // SLL
            3'b110: AluOutput = A >> B[4:0];     // SRL
            3'b111:
 begin
    // 算术右移
    if (B[4:0] == 5'b0) begin
        AluOutput = A;
    end else begin
        // 直接使用符号扩展
        AluOutput = (A[31] == 1'b0) ? (A >> B[4:0]) :  // 正数
                    ((A >> B[4:0]) | (~({32{1'b1}} >> B[4:0])));  // 负数
    end
end
            default: AluOutput = 32'b0;
        endcase
    end

endmodule