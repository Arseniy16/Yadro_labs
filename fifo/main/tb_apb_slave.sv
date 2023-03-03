`timescale 1ns/1ps

module tb_apb_slave;

    localparam WIDTH = 32;

    reg clk;
    initial begin
        clk = 0;
        forever #(2) clk = ~clk;
    end

    // input
    reg              PRESET;
    reg [WIDTH-1:0]  PADDR;
    reg              PSEL;
    reg              PENABLE;
    reg              PWRITE;
    reg [WIDTH-1:0]  PWDATA;

    // output
    wire             PREADY;
    wire [WIDTH-1:0] PRDATA;
    wire             PSLVERR;

    reg full, empty;
    wire write, read;
    reg [WIDTH-1:0] data_read;
    reg [WIDTH-1:0] data_write;

    //PADDR <= 1 if write, else 2

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
        .full    (full),
        .empty   (empty),
        .PSLVERR (PSLVERR),

        .write   (write),
        .read    (read),
        .data_write(data_write),
        .data_read (data_read)
    );


    int cnt_test = 0;
    int num_test = 0;


    function int verify(int iter, int cnt_test, int num_test);
        if (cnt_test == iter)
            $display ("Test %0d passed!\n", num_test);
        else
            $display ("Test %0d failed!\n", num_test);
        
        return ++num_test;

    endfunction : verify

    task init(input int delay_rst = 10);

        PSEL <= 0;
        PENABLE <= 0;

        full <= 0;
        empty <= 0;

        PRESET <= 0;
        #(delay_rst);
        PRESET <= 1;

    endtask : init

    task reset_param;

        PENABLE <= 0;
        PSEL <= 0;
        full <= 0;
        empty <= 0;

    endtask : reset_param

    task write_block(input [WIDTH-1:0] pwdata, input int CNT_CLK1 = 1, input int CNT_CLK2 = 1);

        PADDR <= 1;
        PWRITE <= 1;
        PSEL <= 1;
        PWDATA <= pwdata;
        repeat (CNT_CLK1) @(posedge clk);
        PENABLE <= 1;
        repeat (CNT_CLK2) @(posedge clk);

    endtask : write_block

    task read_block(input [WIDTH-1:0] value_read, input int CNT_CLK1 = 1, input int CNT_CLK2 = 1);

        PADDR <= 2;
        data_read <= value_read;
        PWRITE <= 0;
        PSEL <= 1;
        repeat (CNT_CLK1) @(posedge clk);
        PENABLE <= 1;
        repeat (CNT_CLK2) @(posedge clk);
    
    endtask : read_block

    task write_test(input int iter, inout int num_test);
        cnt_test = 0;
        $display("Write test:");

        for(int i = 0; i < iter; i=i+1) begin
            write_block(i);

            $display("write[%0d] = %0d", i, PWDATA);

            if ((write == 1) & (read == 0) & (data_write == PWDATA) & (PSLVERR == 0) & (PREADY == 1) )
                cnt_test++;

            reset_param();
            @(posedge clk);

        end

        num_test = verify(iter, cnt_test, num_test);

    endtask : write_test

    task read_test(input int iter, inout int num_test);
        cnt_test = 0;
        $display("Read test:");

        for(int i = 0; i < iter; i=i+1) begin
            read_block(i*10);

            $display("read[%0d] = %0d", i, PRDATA);

            if ((read == 1) & (write == 0) & (PRDATA == data_read) & (PSLVERR == 0) & (PREADY == 1) )
                cnt_test++;

            reset_param();
            @(posedge clk);
        end

        num_test = verify(iter, cnt_test, num_test);

    endtask : read_test

    task err_read_test(inout int num_test);
        cnt_test = 0; 
        $display("Error read_test:");

        full <= 0;
        empty <= 1;
        // try to read
        read_block(32'hfa);

        $display("read[%0d] = %0d", 0, PRDATA);

        if ((read == 0) & (write == 0) & (PRDATA == 32'hfa) & (PSLVERR == 1) & (PREADY == 1) )
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

        cnt_test = 0;
        full <= 1;
        empty <= 1;
        // try to read
        read_block(32'hfb);

        $display("read[%0d] = %0d", 1, PRDATA);

        if ((read == 0) & (write == 0) & (PRDATA == 32'hfb) & (PSLVERR == 1) & (PREADY == 1))
            cnt_test++;
            
        num_test = verify(1, cnt_test, num_test);

    endtask : err_read_test

    task err_write_test(inout int num_test);
        cnt_test = 0;
        $display("Error write_test:");

        full <= 1;
        empty <= 0;
        // try to write
        write_block(32'hfc);

        $display("write[%0d] = %0d", 0, PWDATA);

        if ((read == 0) & (write == 0) & (data_write == 32'hfc) & (PSLVERR == 1) & (PREADY == 1))
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

        
        cnt_test = 0;

        full <= 1;
        empty <= 1;
        write_block(32'hfd);
    /*
        PWDATA <= 32'hfd;
        @(posedge clk);
    */
        $display("write[%0d] = %0d", 1, PWDATA);

        if ((read == 0) & (write == 0) & (data_write == 32'hfd) & (PSLVERR == 1) & (PREADY == 1))
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

    endtask : err_write_test

    initial begin
        
        localparam delay = 10;

        $dumpfile("dump.vcd");
        $dumpvars;
        $display("READY TO TEST ABP-SLAVE!");

        init();
        #(delay);
        write_test(5, num_test);
        #(delay);
        read_test(5, num_test);
        #(delay);
        err_read_test(num_test);
        #(delay);
        err_write_test(num_test);
        #(delay);
        reset_param();
        #(delay);
        $finish;

    end

endmodule : tb_apb_slave