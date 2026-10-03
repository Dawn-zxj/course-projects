// HazardUnit_with_Flags.v
module HazardUnit_with_Flags(
    // 时钟和复位信号
    input CLK,
    input Reset,
    
    // 来自流水线的寄存器地址
    input [3:0] RA1_D, RA2_D,
    input [3:0] RA1_E, RA2_E,
    input [3:0] RA2_M,  // 新增：MEM阶段的RA2
    input [3:0] WA3_E, WA3_M, WA3_W,
    
    // 控制信号
    input RegWrite_E, RegWrite_M, RegWrite_W,
    input MemtoReg_E, MemtoReg_M, MemtoReg_W,
    input MemWrite_E, MemWrite_M,  // 新增：MemWrite信号
    input PCSrc_E,
    input M_Start_E,
    input M_Busy,
    input [1:0] MCycleOp_E,  // 多周期操作类型
    
    // 条件码前推相关信号
    input [3:0] ALUFlags_E,
    input [3:0] ALUFlags_M,
    input [1:0] FlagW_E, FlagW_M,
    input CondEx_E, CondEx_M,
    
    // 输出控制信号
    output reg StallF, StallD, StallE,
    output reg FlushE, FlushD,
    output reg [1:0] ForwardAE, ForwardBE,
    output reg ForwardAD, ForwardBD,
    output reg ForwardStore_E,  // EX阶段的Store前推
    output reg ForwardStore_M,  // MEM阶段的Store前推
    output reg [1:0] ForwardFlagsD,
    
    // NOP插入计数
    output reg [2:0] NOPCount  // 需要插入的NOP数量
);

// ================================================
//                匹配条件变量
// ================================================
wire Match_1E_M;  // RA1_E == WA3_M
wire Match_2E_M;  // RA2_E == WA3_M
wire Match_1E_W;  // RA1_E == WA3_W
wire Match_2E_W;  // RA2_E == WA3_W
wire Match_2M_W;  // RA2_M == WA3_W（MEM阶段Store匹配WB阶段Load）

assign Match_1E_M = (RA1_E == WA3_M) && (RA1_E != 4'b0);
assign Match_2E_M = (RA2_E == WA3_M) && (RA2_E != 4'b0);
assign Match_1E_W = (RA1_E == WA3_W) && (RA1_E != 4'b0);
assign Match_2E_W = (RA2_E == WA3_W) && (RA2_E != 4'b0);
assign Match_2M_W = (RA2_M == WA3_W) && (RA2_M != 4'b0);

// ================================================
//                Load-Use冒险检测
// ================================================

// 1. 检查Decode阶段的源寄存器是否与Execute阶段的目的寄存器匹配
wire Match_12D_E = ((RA1_D == WA3_E) || (RA2_D == WA3_E)) && (WA3_E != 4'b0);

// 2. 检查Execute阶段是否是LDR指令且存在匹配
wire ldrstall = Match_12D_E & MemtoReg_E & RegWrite_E;

// ================================================
//                数据前推逻辑（EX阶段）
// ================================================
always @(*) begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    
    // 条件1：EX阶段的源寄存器1匹配MEM阶段的目的寄存器
    if (Match_1E_M && RegWrite_M && !FlushE) begin
        ForwardAE = 2'b10;  // 从MEM阶段前推
    end
    // 条件2：EX阶段的源寄存器1匹配WB阶段的目的寄存器
    else if (Match_1E_W && RegWrite_W && !FlushE) begin
        ForwardAE = 2'b01;  // 从WB阶段前推
    end
    // 默认：从寄存器文件读取
    
    // 条件1：EX阶段的源寄存器2匹配MEM阶段的目的寄存器
    if (Match_2E_M && RegWrite_M && !FlushE) begin
        ForwardBE = 2'b10;  // 从MEM阶段前推
    end
    // 条件2：EX阶段的源寄存器2匹配WB阶段的目的寄存器
    else if (Match_2E_W && RegWrite_W && !FlushE) begin
        ForwardBE = 2'b01;  // 从WB阶段前推
    end
    // 默认：从寄存器文件读取
end

// ================================================
//                分支指令的数据前推（ID阶段）
// ================================================
always @(*) begin
    ForwardAD = 1'b0;
    ForwardBD = 1'b0;
    
    // 如果分支需要EX阶段的结果
    if ((RA1_D == WA3_E) && RegWrite_E && !ldrstall && !FlushD) begin
        ForwardAD = 1'b1;
    end
    
    if ((RA2_D == WA3_E) && RegWrite_E && !ldrstall && !FlushD) begin
        ForwardBD = 1'b1;
    end
end

// ================================================
//                Store指令数据前推（EX阶段）
// ================================================
always @(*) begin
    ForwardStore_E = 1'b0;
    
    // 如果Store的数据来自MEM阶段
    if (Match_2E_M && RegWrite_M && !FlushE) begin
        ForwardStore_E = 1'b1;
    end
    // 如果Store的数据来自WB阶段
    else if (Match_2E_W && RegWrite_W && !FlushE) begin
        ForwardStore_E = 1'b1;
    end
end

// ================================================
//                Store指令数据前推（MEM阶段）
// ================================================
always @(*) begin
    ForwardStore_M = 1'b0;
    
    // 检查MEM阶段的Store指令是否使用WB阶段Load指令的结果
    if (Match_2M_W && MemWrite_M && MemtoReg_W && RegWrite_W) begin
        ForwardStore_M = 1'b1;
    end
end

// ================================================
//                条件码前推逻辑（ID阶段）
// ================================================
always @(*) begin
    ForwardFlagsD = 2'b00;
    
    // 情况1：条件码来自EX阶段
    if ((FlagW_E != 2'b00) && CondEx_E && !FlushD) begin
        ForwardFlagsD = 2'b01;
    end
    // 情况2：条件码来自MEM阶段
    else if ((FlagW_M != 2'b00) && CondEx_M && !FlushD) begin
        ForwardFlagsD = 2'b10;
    end
end

// ================================================
//                控制冒险和停顿逻辑
// ================================================
always @(*) begin
    // 默认值
    StallF = 1'b0;
    StallD = 1'b0;
    StallE = 1'b0;
    FlushE = 1'b0;
    FlushD = 1'b0;
    NOPCount = 3'b0;
    
    // 情况1：Load-Use冒险
    if (ldrstall) begin
        StallF = 1'b1;
        StallD = 1'b1;
        FlushE = 1'b1;  // 清空EX阶段（插入NOP）
        FlushD = 1'b0;  // 不清空ID阶段
        NOPCount = 3'd1;  // Load-Use冒险需要1个NOP
    end
    // 情况2：控制冒险（分支预测失败）- Early BTA
    else if (PCSrc_E) begin
        // 分支时需要清空两个较早阶段
        FlushD = 1'b1;  // 清空ID阶段
        FlushE = 1'b1;  // 清空EX阶段
        // 分支时需要插入NOPs
        NOPCount = 3'd2;  // 分支通常需要2个NOP
        // 注意：不需要停顿流水线，因为分支决定已经做出
        StallF = 1'b0;
        StallD = 1'b0;
        StallE = 1'b0;
    end
    // 情况3：多周期指令数据依赖
    else if (M_Busy && ((RA1_D == WA3_E) || (RA2_D == WA3_E)) && (WA3_E != 4'b0)) begin
        // 多周期指令执行中且有数据依赖
        StallF = 1'b1;
        StallD = 1'b1;
        // 注意：我们不应该停顿EX阶段，让多周期指令继续执行
        StallE = 1'b0;
        // 根据多周期操作类型设置NOP数量
        case (MCycleOp_E)
            2'b01: NOPCount = 3'd4;  // 乘法：4个NOP
            2'b10: NOPCount = 3'd8;  // 除法：8个NOP
            default: NOPCount = 3'd0;
        endcase
    end
    // 情况4：多周期指令正在执行，但不一定有数据依赖
    else if (M_Busy) begin
        // 即使没有数据依赖，我们也可以记录NOP数量用于调试
        case (MCycleOp_E)
            2'b01: NOPCount = 3'd4;  // 乘法：4个NOP
            2'b10: NOPCount = 3'd8;  // 除法：8个NOP
            default: NOPCount = 3'd0;
        endcase
    end
end

endmodule