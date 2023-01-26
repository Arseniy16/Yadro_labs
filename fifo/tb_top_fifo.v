`timescale 1ns/1ps

module tb_top_fifo();

    reg         clk;
    reg         reset;
    reg         write;
    reg         read;
    reg  [31:0] data_write;
    wire [31:0] data_read;
    wire        full;
    wire        empty;
    wire [7:0]  status;
    wire        err_read;
    wire        err_write;

    integer period = 6;
    integer seed = 2; // for random
    integer delay = 5;

    top_fifo top_fifo_inst
        (
            .clk        (clk),
            .reset      (reset),
            .write      (write),
            .read       (read),
            .data_write (data_write),
            .data_read  (data_read),
            .full       (full),
            .empty      (empty),
            .status     (status),
            .err_read   (err_read),
            .err_write  (err_write)
        );

    always #(period/2) clk = ~clk;
    
    initial begin
        $dumpvars;
        $display("SUCCESS");

        clk         <= 0;
        reset       <= 0;
        write       <= 0;
        read        <= 0;
        data_write  <= 0;

        #5 reset <= 1;


        // status <= 0;

        for (integer i = 0; i < 10; i=i+1) begin
            //delay = $urandom(seed) % 10 + 1;
            // if (err_read == 1) status <= 0;
            // if (err_write == 1) status <= {1'b0, {7{1'b1}}};
            
            #(delay) 
            read <= ~read;

            #(delay + 3)
            write <= ~write;

            #5 data_write <= $random(seed);

        end

        $finish;
        
    end

endmodule
