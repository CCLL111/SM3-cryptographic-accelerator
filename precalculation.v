/*
 * File: barrel_shifter.v
 * Project: rtl
 * File Created: Sunday, 5th August 2018 9:03:57 am
 * Author: Chen Rui (raymond.rui.chen@qq.com>)
 * -----
 * Last Modified: Sunday, 5th August 2018 9:12:40 am
 * Modified By: Chen Rui (raymond.rui.chen@qq.com>)
 * -----
 * Copyright (c) 2018 - Chen Rui
 * All rights reserved.
 */
module precalculation
	(
		input               clk,
		input               reset_n,
		input	[31 : 0]	word_out,
		input	[31 : 0]	word_p_out,

		input   [31 : 0]    reg_d,

		input   [31 : 0]	reg_h,
		output	reg	[31 : 0]	DW,
		output	reg	[31 : 0]	HW		
		
	);



always@(posedge clk or negedge reset_n)begin
	if (!reset_n)begin
		DW <= 32'b0;
		HW <= 32'b0;
	end
	else begin
		DW <= word_p_out + reg_d;
		HW <= word_out + reg_h;
	end

end


endmodule	