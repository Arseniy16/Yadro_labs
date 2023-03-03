
`timescale 1ns/1ps

module tb_top_module ();

    localparam WIDTH = 32;
    
    // clock
    reg clk;
    initial begin
        clk = 0;
        forever #(2) clk = ~clk;
    end

    // input
    // reg          PCLK;
    reg [WIDTH-1:0] PADDR;
    reg             PRESET;
    reg             PSEL;
    reg             PENABLE;
    reg             PWRITE;
    reg [WIDTH-1:0] PWDATA;

    //output
    reg             PREADY;
    reg [WIDTH-1:0] PRDATA;
    reg             PSLVERR;

    int cnt_test = 0;
    int num_test = 0;

    top_module top_module_inst(
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

        PRESET <= 0;
        #(delay_rst);
        PRESET <= 1;

    endtask : init

    task write_block(input [WIDTH-1:0] pwdata, input int CNT_CLK1 = 1, input int CNT_CLK2 = 1);

        PADDR <= 1;
        PWRITE <= 1;
        PSEL <= 1;
        PWDATA <= pwdata;
        repeat (CNT_CLK1) @(posedge clk);
        PENABLE <= 1;
        repeat (CNT_CLK2) @(posedge clk);

    endtask : write_block

    task read_block(input int CNT_CLK1 = 1, input int CNT_CLK2 = 1);

        PADDR <= 2;
        // data_read <= value_read;
        PWRITE <= 0;
        PSEL <= 1;
        repeat (CNT_CLK1) @(posedge clk);
        PENABLE <= 1;
        repeat (CNT_CLK2) @(posedge clk);
    
    endtask : read_block

    task write_test(inout int num_test);
        cnt_test = 0;
        $display("Write test:");

        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);
      
        write_block(32'haa);  

        $display("write[%0d] = %0d", 0, PWDATA);
        #0.001;
        if (PREADY & ~PSLVERR & (PWDATA == 32'haa))
            cnt_test++;

        @(posedge clk);
    
        PADDR <= 2;
        PSEL <= 0;
        PENABLE <= 0;
    
        @(posedge clk);
        $display("read[%0d] = %0d", 0, PRDATA);

        if (~PREADY & ~PSLVERR & (PRDATA == 32'haa))
            cnt_test++;

        @(posedge clk);

        write_block(32'hab);  

        $display("write[%0d] = %0d", 1, PWDATA);
        // $display("read[%0d] = %0d", 1, PRDATA);
        #0.001;
        if (PREADY & ~PSLVERR & (PRDATA == 32'haa) & (PWDATA== 32'hab))
            cnt_test++;

        num_test = verify(3, cnt_test, num_test);

    endtask : write_test

    task read_test(input int iter, inout int num_test);

        cnt_test = 0;
        $display("Read test:");
    
        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);

        //write firstly
        write_block('x, 1, 0);

        for(int i = 0; i < iter; i++) begin
            PWDATA <= i*10;
            @(posedge clk);

            $display("write[%0d] = %0d", i, PWDATA);

            if (PREADY & ~PSLVERR & (PWDATA == i*10))
                cnt_test++;
        end

        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);

        // read data
        read_block(1, 0);

        for(int i = 0; i < iter; i++) begin
            
            @(posedge clk);
            $display("read[%0d] = %0d", i, PRDATA);
            
            if (PREADY & ~PSLVERR & (PRDATA == i*10))
                cnt_test++;
        end

        num_test = verify(2*iter, cnt_test, num_test);

    endtask : read_test

    task err_read_test(inout int num_test);
        cnt_test = 0;
        $display("Err_read_test:");
    
        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);
    
         // read all to erase mem
        read_block();

        while (~PSLVERR) begin
            // @(posedge clk);
            $display("read = %0d", PRDATA);
            @(posedge clk);
        end
        
        if (PREADY & PSLVERR & (PRDATA === 'x))
            cnt_test++;

        num_test = verify(1, cnt_test, num_test);

    endtask : err_read_test
    
    task err_addr_test(inout int num_test);
        cnt_test = 0;
        $display("Err_addr_test:");
        
        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);

         // read all to erase mem
        read_block();
    
        while (~PSLVERR) begin
            $display("read = %0d", PRDATA);
            @(posedge clk);
        end
        
        // test err_addr(write and read)
        write_block(4'ha, 1, 0);
       
        // #0.001;        
        $display("write = %0d", PWDATA);
        if (PREADY & ~PSLVERR)
            cnt_test++;
        $display("cnt_test = %0d", cnt_test);

        
        PADDR <= 5; //err
        PWDATA <= 4'hb;
        PWRITE <= 1;
        PSEL <= 1;
        @(posedge clk);
        PENABLE <= 1;
        
        // #0.001;        
        $display("write = %0d", PWDATA);
        if (PREADY & ~PSLVERR)
            cnt_test++;
        $display("cnt_test = %0d", cnt_test);           

        read_block(1, 0);
        // @(posedge clk);
        // #0.001;
        if (PREADY & ~PSLVERR & (PRDATA == 4'ha) )
            cnt_test++;
        $display("cnt_test = %0d", cnt_test);

        $display("read = %0d", PRDATA);
        
        @(posedge clk);
        
        if (PREADY & PSLVERR & (PRDATA === 'x) )
            cnt_test++;
        
        $display("read = %0d", PRDATA);
        
        num_test = verify(4, cnt_test, num_test);
        
    endtask : err_addr_test
    
    
    task err_test(inout int num_test);

        cnt_test = 0;
        $display("Error_test:");
        
        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);

        // read all to erase mem
        read_block();
    
        while (~PSLVERR) begin
            $display("read = %0d", PRDATA);
            @(posedge clk);
        end

        //write full 
        write_block('x, 1, 0);

        for(int i = 0; i < 128; i++) begin
            PWDATA <= i;
            @(posedge clk);

            $display("write[%0d] = %0d", i, PWDATA);

            if (PREADY & ~PSLVERR & (PWDATA == i) | (PREADY & PSLVERR & (PWDATA == 32'd127)))
                cnt_test++;
        end

        PSEL <= 0;
        PENABLE <= 0;
        @(posedge clk);

        // $display("c = %0d", cnt_test);
        if (~PREADY & PSLVERR & (PWDATA == 32'd127))
            cnt_test++;

        num_test = verify(129, cnt_test, num_test);
        
    endtask : err_test

    initial begin

        localparam delay = 10;

        $dumpfile("mod_dump.vcd");
        $dumpvars;
        $display("READY TO TEST TOP MODULE!\n");

        init();
        #(delay);
        read_test(10, num_test);
        #(delay);
        write_test(num_test);
        #(delay);
        err_read_test(num_test);
        #(delay);
        err_addr_test(num_test);
        #(delay);
        err_test(num_test);
        #(delay);
        $finish;
    end


endmodule : tb_top_module