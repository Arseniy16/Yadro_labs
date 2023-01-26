
`timescale 1ns/1ps

module tb_apb_slave (); /* this is automatically generated */

	// clock
	logic clk;
	initial begin
		clk = '0;
		forever #(0.5) clk = ~clk;
	end

	// asynchronous reset
	logic PRESET;
	initial begin
		PRESET <= '0;
		#10
		PRESET <= '1;
	end

	// synchronous reset
	logic srstb;
	initial begin
		srstb <= '0;
		repeat(10)@(posedge clk);
		srstb <= '1;
	end

	// (*NOTE*) replace reset, clock, others

	logic  [7:0] PADDR;
	logic        PSEL;
	logic        PENABLE;
	logic        PWRITE;
	logic [31:0] PWDATA;
	logic        PREADY;
	logic [31:0] PRDATA;
	logic        PSLVERR;

	apb_slave inst_apb_slave
		(
			.PCLK    (clk),
			.PRESET  (PRESET),
			.PADDR   (PADDR),
			.PSEL    (PSEL),
			.PENABLE (PENABLE),
			.PWRITE  (PWRITE),
			.PWDATA  (PWDATA),
			.PREADY  (PREADY),
			.PRDATA  (PRDATA),
			.PSLVERR (PSLVERR)
		);

	task init();
		PADDR   <= '0;
		PSEL    <= '0;
		PENABLE <= '0;
		PWRITE  <= '0;
		PWDATA  <= '0;
	endtask

	task drive(int iter);
		for(int it = 0; it < iter; it++) begin
			PADDR   <= '0;
			PSEL    <= '0;
			PENABLE <= '0;
			PWRITE  <= '0;
			PWDATA  <= '0;
			@(posedge clk);
		end
	endtask

	initial begin
		// do something

		init();
		repeat(10)@(posedge clk);

		drive(20);

		repeat(10)@(posedge clk);
		$finish;
	end

	// dump wave
	initial begin
		$display("random seed : %0d", $unsigned($get_initial_random_seed()));
		if ( $test$plusargs("fsdb") ) begin
			$fsdbDumpfile("tb_apb_slave.fsdb");
			$fsdbDumpvars(0, "tb_apb_slave", "+mda", "+functions");
		end
	end

endmodule
