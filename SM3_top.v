/*
 * File: SM3_top.v
 * Project: rtl
 * File Created: Sunday, 5th August 2018 9:03:57 am
 * Author: Chen Rui (raymond.rui.chen@qq.com>)
 * -----
 * Last Modified: Sunday, 5th August 2018 9:12:50 am
 * Modified By: Chen Rui (raymond.rui.chen@qq.com>)
 * -----
 * Copyright (c) 2018 - Chen Rui
 * All rights reserved.
 */
module SM3_top
	(
		clk_in,
		reset_n_in,
		SM3_en_in,
		msg_in,
		sm3_result_out,
		sm3_finished_out
	);
	
`define		IDLE		2'b00
`define		PADDING		2'b01
`define		ITERATION	2'b10	

localparam	WIDTH = 512;	

input					clk_in,
						reset_n_in,
						SM3_en_in;
input	[WIDTH - 1 : 0]	msg_in;	

output	[255 : 0]		sm3_result_out;		
output					sm3_finished_out;	

reg						padding_en,
						iteration_en;
reg						sm3_finished_out;
reg		[1:0]			current_state,
						next_state;		
reg		[5:0]			index_j;
wire					padding_1_block_finished;
wire	[511:0]			msg_padded;
wire					padding_all_finished;
wire	[31:0]			word_expanded_p;
wire	[31:0]			word_expanded;
wire					msg_exp_finished;



always@(posedge clk_in)					
	if(!reset_n_in)
		current_state	<=	`IDLE;
	else
		current_state	<=	next_state;
		
always@(*)
	begin	
		next_state	=	`IDLE;
		case(current_state)
			`IDLE:
				if(SM3_en_in == 1'b1)	
					next_state = `ITERATION;
				else
					next_state = `IDLE;
			`ITERATION:
				if(msg_exp_finished)
					next_state = `IDLE;
				else
					next_state = `ITERATION;
			default:
					next_state = `IDLE;
		endcase
	end

always@(posedge clk_in)
	if(!reset_n_in)
		begin
			iteration_en		<=	1'b0;
			sm3_finished_out	<=	1'b0;
		end
	else
		begin
			
			if(current_state == `ITERATION)
				iteration_en	<=	1'b1;
			else
				iteration_en	<=	1'b0;
			
			if(current_state == `ITERATION && next_state == `IDLE)
				sm3_finished_out	<=	1'b1;
			else
				sm3_finished_out	<=	1'b0;								
		end

reg [5:0] index_j_reg;
//reg		  working_en;			
always@(posedge clk_in)
	if(!reset_n_in)begin
		index_j	<=	'd0;
//		working_en <= 1'b0;
	end
	else if(iteration_en)begin
		index_j	<=	index_j	+	1'b1;
//		working_en <= 1'b1;
	end
	else
		index_j	<=	'd0;

always@(posedge clk_in)begin
	index_j_reg <= index_j;
end
		
/*msg_padding #(WIDTH) U_pad
	(
		.clk_in(						clk_in),
		.reset_n_in(					reset_n_in),
		.SM3_en_in(						SM3_en_in),
		.padding_en_in(					padding_en),
		.msg_in(						msg_in),
		.msg_valid_in(					msg_valid_in),
		.is_last_word_in(				is_last_word_in),
		.last_word_byte_in(				last_word_byte_in),
		.is_1st_msg_block_out(			is_1st_msg_block),
		.msg_padded_out(				msg_padded),
		.padding_1_block_finished_out(	padding_1_block_finished),
		.padding_all_finished_out(		padding_all_finished)
	);*/

	
wire [31:0] DW_wire_in;
wire [31:0] HW_wire_in;		
wire [31:0] reg_c_wire;
wire [31:0] reg_g_wire;
wire [31:0] tmp_for_ss1_1;	
//--------------precalculation-------------//
precal U_precalculation(
		.clk(clk_in),
		.reset_n(reset_n_in),
		.word_out(word_expanded),
		.word_p_out(word_expanded_p),
		.index_j(index_j),
//		.DW_in(dw_out_wire),
//		.HW_in(hw_out_wire),
		.pre_cal_en(1'b1),
		.reg_c(reg_c_wire),
		.reg_g(reg_g_wire),
		.DW(DW_wire_in),
		.HW(HW_wire_in)
);	
	
	
//--------------Tj<<<j---------------//	
TJ_logic U_Tj(
	.clk(clk_in),
	.index_addr(index_j),
	.tmp_for_ss1_1(tmp_for_ss1_1)
);

	
msg_expansion U_exp
	(
		.clk_in(						clk_in),
		.reset_n_in(					reset_n_in),
		.message_in(					msg_in),
		.start_in(						SM3_en_in),
		.index_j_in(					index_j_reg),
		.word_p_out(					word_expanded_p),
		.word_out(						word_expanded),
		.msg_exp_finished_out(			msg_exp_finished)
	);	

compression_function U_cf
	(
		.clk_in(						clk_in),
		.reset_n_in(					reset_n_in),
		.start_in(						SM3_en_in),
		.index_j_in(					index_j_reg),
		.tmp_for_ss1_1(					tmp_for_ss1_1),
		.word_expanded_p_in(			word_expanded_p),
		.word_expanded_in(				word_expanded),
		.dw_in(DW_wire_in),
		.hw_in(HW_wire_in),
		.data_after_cf_out(				sm3_result_out),
		.reg_c(reg_c_wire),
		.reg_g(reg_g_wire),
		.iteration_en(iteration_en)
//		.pre_cal_en(iteration_en)
	);	
	
		
endmodule		