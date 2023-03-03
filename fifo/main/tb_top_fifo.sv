`timescale 1ns/1ps

module tb_top_fifo();

    localparam WIDTH = 32, DEPTH = 8;

    reg clk;
    initial begin
        clk = 0;
        forever #(2) clk = ~clk;
    end

    reg         reset;
    reg         write;
    reg         read;
    reg  [WIDTH-1:0] data_write;
    wire [WIDTH-1:0] data_read;
    wire        full;
    wire        empty;
    wire [DEPTH-1:0] status;
    wire        err_read;
    wire        err_write;
    //reg [WIDTH-1:0] mem [127:0];

    int cnt_test = 0;
    int num_test = 0;

    top_fifo top_fifo_inst(
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
        //.mem        (mem)
    );


    function int verify(int iter, int cnt_test, int num_test);
        if (cnt_test == iter)
            $display ("Test %0d passed!\n", num_test);
        else
            $display ("Test %0d failed!\n", num_test);
        
        return ++num_test;

    endfunction : verify


    task init(input int delay_rst = 10);

        write <= 0;
        read <= 0;
        reset <= 0;
        #(delay_rst);
        reset <= 1;

    endtask : init

    task write_test(input int iter, inout int num_test);
        cnt_test = 0;
        init();
        $display("Write test:");

        write <= 1;
        // @(posedge clk);

        for (int i = 0; i < iter; i++) begin
            @(negedge clk);
            data_write = i*10;
            // #(0.001)
            $display("data_write[%0d] = %0d", i, data_write);
        end

        @(negedge clk);

        if ((write == 1) & (status == iter) & ~err_write & ~empty)
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

    endtask : write_test


    task read_test(input int iter, inout int num_test);
        cnt_test = 0;
        init();
        $display("Read test:");
 
        write <= 1;
        read <= 0;

        // @(posedge clk);

        for (int i = 0; i < iter; i++) begin
            @(negedge clk);
            data_write <= i;
            // @(negedge clk);
            #(0.01)
            $display("data_write[%0d] = %0d", i, data_write);

        end

        @(negedge clk);

        //        $display("my = %0d", mem[0]);

        //        for (int i = 0; i < iter; i++) 
        //            $display("mem[%0d] = %0d", i, mem[i]);

        read <= 1;
        write <= 0;
        // @(posedge clk);
        // #(1);
        for (int i = 0; i < iter; i++) begin

            @(posedge clk);
            $display("data_read[%0d] = %0d", i, data_read);
            if (data_read == i) cnt_test++;
        end

        @(posedge clk);

        if ((write == 0) & (read == 1) & (status == 0) & err_read  & empty & ~full & (cnt_test == iter))
            cnt_test++;

        num_test = verify(iter+1, cnt_test, num_test);

    endtask : read_test

    task wr_rd_test(inout int num_test);
        cnt_test = 0;
        init();
        $display("Write-Read test:");

        write <= 1;
        read <= 0;

        @(posedge clk); //?
        data_write <= 32'haa;
        @(posedge clk);
        $display("data_write[0] = %0d", data_write);
        // @(posedge clk);
        data_write <= 32'hab;
        @(posedge clk);
        $display("data_write[1] = %0d", data_write);

        @(posedge clk);

        if ((data_read == 32'haa) & (status == 2) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        write <= 1;
        read <= 1;
        @(posedge clk) #(0.001);
        if ((data_read == 32'hab) & (status == 3) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        data_write <= 32'hff;
        @(posedge clk);

        $display("data_write[2] = %0d", data_write);
        $display("data_read = %0d", data_read);
        if ((data_read == 32'hab) & (status == 3) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        @(posedge clk);
        if ((data_read == 32'hab) & (status == 3) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        write <= 0;
        read <= 1;
        @(posedge clk) #(0.001);
        $display("data_read = %0d", data_read);
        if ((data_read == 32'hff) & (status == 2) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        @(posedge clk) #(0.001);
        $display("data_read = %0d", data_read);
        if ((data_read == 32'hff) & (status == 1) & ~err_read & ~err_write & ~full & ~empty)
            cnt_test++;

        @(posedge clk) #(0.001);

        if ((data_write == 32'hff) & (status == 0) & err_read & ~err_write & ~full & empty)
            cnt_test++;

        num_test = verify(7, cnt_test, num_test);

    endtask : wr_rd_test

    task err_test(inout int num_test);
        cnt_test = 0;
        init();
        $display("Error_test:");

        @(posedge clk);
        write <= 1;
        read <= 0;

        // data_write <= 0;
        // @(posedge clk);
        // #4;
        // write <= 1;
        // read <= 1;

        for (int i = 0; i < 128; i++) begin
            @(negedge clk);
            data_write = i;
            // #(0.001)
            $display("data_write[%0d] = %0d", i, data_write);
            // @(posedge clk) ;
            // $display("data_read[%0d] = %0d", i, data_read);
        end

        @(posedge clk) #(0.001);

        if ((status == 8'd128) & err_write & ~err_read & full & ~empty)
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

    endtask : err_test


    initial begin

        localparam delay = 10;

        $dumpfile("dump.vcd");
        $dumpvars;
        $display("READY TO TEST FIFO!\n");

        write_test(5, num_test);
        #(delay);
        read_test(4, num_test);
        #(delay);
        wr_rd_test(num_test);
        #(delay);
        err_test(num_test);
        #(delay);

        $finish;

    end

endmodule : tb_top_fifo