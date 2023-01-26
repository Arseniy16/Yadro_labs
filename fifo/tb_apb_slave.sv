`timescale 1ns/1ps

// `define ADDRWIDTH 8
// `define DATAWIDTH 32

module tb_apb_slave();

	reg clk;
	initial begin
		clk = 0;
		forever #(0.5) clk = ~clk;
	end

	reg PRESET;
	initial begin
		PRESET <= 0;
		#10
		PRESET <= 1;
	end

	// input  wire         PCLK,
    // input  wire         PRESET,
    reg [7:0]   PADDR;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg [31:0]  PWDATA;

    // output
    reg          PREADY;
    reg  [31:0]  PRDATA;
    reg          PSLVERR;

    // integer period = 6;
    // integer seed = 2; // for random
    // integer delay = 5;

	apb_slave apb_slave_inst(
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
		begin
			PADDR   <= 0;
			PSEL    <= 0;
			PENABLE <= 0;
			PWRITE  <= 0;
			// PWDATA  <= 0;
		end
	endtask


	task reset_param();
		begin
			PENABLE <= 0;
			PSEL <= 0;
			// PWDATA <= 0;
		end
	endtask

	task write_test(integer iter);

		for(integer i = 0; i < iter; i=i+1) begin
			PADDR <= i;
			PWRITE <= 1;
			PSEL <= 1;
			PWDATA  <= i;
			#5;
			PENABLE <= 1;

			repeat(2) @(posedge clk);
			reset_param();

			$display("write[%0d] = %0d", PADDR, PWDATA);
			@(posedge clk);
		end

		$display("write_test complete");

	endtask

	task read_test(integer iter);
		for(integer i = 0; i < iter; i=i+1) begin
			PADDR <= i;
			PWRITE <= 0;
			PSEL <= 1;
			#5;
			PENABLE <= 1;

			repeat(3) @(posedge clk);
			$display("read[%0d] = %0d", PADDR, PRDATA);
			reset_param();
			@(posedge clk);
			
		end
		$display("read_test complete");

	endtask

	task test1();
		PADDR <= 0;
		PSEL <= 1;
		repeat(2) @(posedge clk);
		PWRITE <= 1;
		PWDATA <= 'hff;
		@(posedge clk);
		PENABLE <= 1;
		#20;
		reset_param();
		$display("test_1");
		
	endtask



//test insert
	task test2(integer iter);
		
		for(integer i = 0; i < iter; i=i+2) begin
			PADDR <= i;
			PWRITE <= 1;
			PSEL <= 1;
			PWDATA  <= 'hf;
			#5;
			PENABLE <= 1;

			repeat(2) @(posedge clk);
			reset_param();

			$display("write[%0d] = %0d", PADDR, PWDATA);
			@(posedge clk);
		end

		$display("test_2");
		//read_test(iter);

	endtask

	task test3();
		PADDR <= 'x;
		PWRITE <= 1;
		PSEL <= 1;
		PWDATA <= 'ha;
		@(posedge clk);
		PENABLE <= 1;
		repeat(2) @(posedge clk);
		reset_param();
		// if (PREADY == 1) $display("test_3 failed");
		// else if (PREADY == 0) $display("test3 passed");

	endtask


	initial begin
		$dumpvars;
		$display("SUCCESS");

		init();
		#10;
		
		//write_test(10);
		#10;
		//read_test(5);
		#10;
		test3(10);
		#10;
		read_test(10);

		// test1();
		// #20;
		// test2();

		// random_test(); //TODO

		$finish;
	end

endmodule