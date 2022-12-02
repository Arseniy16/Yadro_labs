module top_fifo(
		input write_flag,
		input read_flag,
		input  [31:0] data_write,
		output [31:0] data_read,
		output full,
		output empty,
		output status,
		output err_read,
		output err_write
		
	);

	assign full = 0, empty = 0, status = 0, err_read = 0, err_write = 0;

	reg [31:0] mem [127:0];
	
	integer unsigned cnt_ptr = 0;
	integer unsigned cnt_read = 0;
	integer unsigned cnt_busy = 0; 
	
	
	always @(*) begin
		
		while (write_flag && (cnt_busy < 128) begin
			mem[cnt_ptr] = data_write;
			cnt_ptr = cnt_ptr + 1;
			cnt_busy = cnt_busy + 1;
		end
		
		if (!write_flag) err_write = 1;
		
		if (cnt_busy >= 128) full = 1;

		status = cnt_busy; 
		
	end
		
	always @(*) begin
		while (read_flag && (cnt_busy > 0) begin
			data_read = mem[cnt_read];
			cnt_read = cnt_status + 1;
			cnt_busy = cnt_busy - 1;
			
		end
		
		if (cnt_busy == 0) empty = 1;
		
		if (!read_flag) err_read = 1;
		
		status = cnt_busy;
	end
	
endmodule 
