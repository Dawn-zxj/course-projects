// TOP_Pipelined.v
`timescale 1ns / 1ps

module TOP_Pango
#(
  parameter N_LEDs_OUT = 8,
  parameter N_DIPs = 7,
  parameter N_SEVEN_SEG_DIGITs = 8,
  parameter CLK_DIV_BITS = 24
)
(
  input  [N_DIPs-1:0] DIP,
  output [N_LEDs_OUT-1:0] LED,
  output [N_SEVEN_SEG_DIGITs-1:0] SevenSegAn,
  output [15:0] SevenSegCatHL,
  input PAUSE_n,
  input RESET_n,
  input CLK_undiv
);

//----------------------------------------------------------------
// Wrapper信号
//----------------------------------------------------------------    
wire [31:0] SEVENSEGHEX;         
wire CLK;    
    
wire  PAUSE = ~PAUSE_n;
wire  RESET = ~RESET_n;

//----------------------------------------------------------------
// 实例化五级流水线Wrapper
//----------------------------------------------------------------
wire [15:0] LED_16bit;
Wrapper_Pipelined #(
    .N_LEDs_OUT(16),
    .N_DIPs(7)
) wrapper_pipelined (
  .DIP(DIP),
  .LED_16bit(LED_16bit),
  .SEVENSEGHEX(SEVENSEGHEX),
  .RESET(RESET),
  .CLK(CLK)
);

// 根据Lab2的TOP_Pango.v，只使用LED_16bit的部分位
assign LED = LED_16bit[9:2];

//----------------------------------------------------------------
// 时钟分频器（与原始TOP_Pango.v相同）
//----------------------------------------------------------------
generate
  if (CLK_DIV_BITS == 0) begin
    assign CLK = CLK_undiv;
  end
  else begin
    reg [CLK_DIV_BITS:0] clk_counter;
    always @(posedge CLK_undiv or posedge RESET) begin
      if(RESET)
        clk_counter <= 'b0;
      else if(~PAUSE)
        clk_counter <= clk_counter + 1;
    end
    assign CLK = clk_counter[CLK_DIV_BITS];
  end
endgenerate

//----------------------------------------------------------------
// 七段数码管显示（与原始TOP_Pango.v相同）
//----------------------------------------------------------------
reg [7:0] enable = 8'b0000_0001;
reg [3:0] data_disp = 4'h0;
reg [16:0] count_fast;
reg seven_seg_enable;
reg [6:0] cathode = 7'b111_1111;

always @(posedge CLK_undiv or posedge RESET) begin
  if(RESET) begin
    count_fast <= 17'b0;
    seven_seg_enable <= 1'b0;
  end
  else begin
    count_fast <= count_fast+1;
    if(count_fast == 17'h1869F) begin
      seven_seg_enable <= 1'b1;
      count_fast <= 17'b0;
    end
    else seven_seg_enable <= 0;
  end
end

always @(posedge CLK_undiv or posedge RESET) begin
  if(RESET) begin
    enable <= 8'b00000001;
  end
  else begin
    if(seven_seg_enable) begin
      enable <= (enable == 8'h80)? 8'h01 : (enable << 1);
    end
  end
end

assign SevenSegAn = ~enable;

always @ (*) begin                       
  case (SevenSegAn)
      8'b11111110 : data_disp = SEVENSEGHEX[3:0];
      8'b11111101 : data_disp = SEVENSEGHEX[7:4];
      8'b11111011 : data_disp = SEVENSEGHEX[11:8];
      8'b11110111 : data_disp = SEVENSEGHEX[15:12];
      8'b11101111 : data_disp = SEVENSEGHEX[19:16];
      8'b11011111 : data_disp = SEVENSEGHEX[23:20];
      8'b10111111 : data_disp = SEVENSEGHEX[27:24];
      8'b01111111 : data_disp = SEVENSEGHEX[31:28];
      default : data_disp = 4'h0;
  endcase 
  case (data_disp)
      4'h0 : cathode = 7'b1000000; 
      4'h1 : cathode = 7'b1111001;
      4'h2 : cathode = 7'b0100100;
      4'h3 : cathode = 7'b0110000;
      4'h4 : cathode = 7'b0011001;
      4'h5 : cathode = 7'b0010010;
      4'h6 : cathode = 7'b0000010;
      4'h7 : cathode = 7'b1111000;
      4'h8 : cathode = 7'b0000000;
      4'h9 : cathode = 7'b0010000;
      4'hA : cathode = 7'b0001000;
      4'hB : cathode = 7'b0000011;
      4'hC : cathode = 7'b1000110;
      4'hD : cathode = 7'b0100001;
      4'hE : cathode = 7'b0000110;
      4'hF : cathode = 7'b0001110;
   endcase
end 

assign SevenSegCatHL = ((&SevenSegAn[3:0]) == 1'b0) ? {8'hff, 1'b1, cathode} : {1'b1, cathode, 8'hff};

endmodule