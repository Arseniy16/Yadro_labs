
module top_module(
		input wire PCLK,
		input wire PRESET,
		input wire PSEL,
		input wire PENABLE,
		input wire PWRITE,
		input wire [31:0] PWDATA,

		output wire PREADY,
		output wire [31:0] PRDATA,
		output wire PSLVERR
	);
	
	reg [31:0] data_write;
	reg [31:0] data_read;
	reg err_read;
	reg err_write;
	reg write;

	apb_slave apb_slave_inst(
			.PCLK    (PCLK),
			.PRESET  (PRESET),
			// .PADDR   (PADDR),
			.PSEL    (PSEL),
			.PENABLE (PENABLE),
			.PWRITE  (PWRITE),
			.PWDATA  (PWDATA),
			.PREADY  (PREADY),
			.PRDATA  (PRDATA),
			.PSLVERR (PSLVERR)

			.data_write(data_write),
			.data_read(data_read),
			.err_read(err_read),
			.err_write(err_write),
			.write(write)
		);

	top_fifo top_fifo_inst(
            .clk        (PCLK),
            .reset      (PRESET),
            .write      (write),
            .read       (~write),
            .data_write (data_write),
            .data_read  (data_read),
            // .full       (full),
            // .empty      (empty),
            // .status     (status),
            .err_read   (err_read),
            .err_write  (err_write)
        );


endmodule