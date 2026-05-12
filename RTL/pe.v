// pe.v：修正后的PE子模块（新增weight_out，支持权重垂直转发）
module pe #(
    parameter IN_WIDTH  = 8,    // 输入数据位宽（定点量化）
    parameter OUT_WIDTH = 24    // 乘加结果位宽（预留累加余量）
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,             // 运算使能
    input  wire signed [IN_WIDTH-1:0]  data_in,       // 水平输入数据（特征A）
    input  wire signed [IN_WIDTH-1:0]  weight_in,     // 垂直输入权重（W）
    input  wire                     clr_acc,        // 累加器清零信号
    output reg  signed [IN_WIDTH-1:0]  data_out,      // 水平转发数据（特征）
    output reg  signed [IN_WIDTH-1:0]  weight_out,    // 新增：垂直转发权重（关键）
    output reg  signed [OUT_WIDTH-1:0] acc_out       // 乘加结果输出
);

// 内部MAC运算逻辑（保持不变）
reg signed [2*IN_WIDTH-1:0] mul_result;  // 乘法结果（8bit×8bit=16bit）
reg signed [OUT_WIDTH-1:0] acc_reg;      // 累加寄存器

// 乘法+累加运算（保持不变）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_result <= 16'd0;
        acc_reg    <= 24'd0;
    end else if (en) begin
        mul_result <= data_in * weight_in;
        if (clr_acc) begin
            acc_reg <= {{OUT_WIDTH-2*IN_WIDTH{mul_result[2*IN_WIDTH-1]}}, mul_result};
        end else begin
            acc_reg <= acc_reg + {{OUT_WIDTH-2*IN_WIDTH{mul_result[2*IN_WIDTH-1]}}, mul_result};
        end
    end
end

// 特征转发逻辑（保持不变：左→右）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 8'd0;
    end else if (en) begin
        data_out <= data_in;
    end
end

// 新增：权重转发逻辑（上→下，延迟1拍，与特征转发时序对齐）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_out <= 8'd0;
    end else if (en) begin
        weight_out <= weight_in;  // 接收上方权重，延迟1拍转发给下方PE
    end
end

// 累加结果输出（保持不变）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc_out <= 24'd0;
    end else begin
        acc_out <= acc_reg;
    end
end

endmodule