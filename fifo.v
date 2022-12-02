module top_fifo(
        input wire write_flag,
        input wire read_flag,
        input  wire [31:0] data_write,
        output wire [31:0] data_read,
        output wire full,
        output wire empty,
        output wire status,
        output wire err_read,
        output wire err_write
        
    );

    assign full = 0, empty = 0, status = 0, err_read = 0, err_write = 0;

    reg [31:0] mem [127:0];
    
    integer unsigned cnt_ptr = 0;
    integer unsigned cnt_read = 0;
    integer unsigned cnt_busy = 0; 
    
    
    always @(*) begin
        
        while (write_flag && (cnt_busy < 128)) begin
            mem[cnt_ptr] = data_write;
            cnt_ptr = cnt_ptr + 1;
            cnt_busy = cnt_busy + 1;
        end
        
        if (!write_flag) assign err_write = 1;
        
        if (cnt_busy >= 128) assign full = 1;

        assign status = cnt_busy; 
        
    end
        
    always @(*) begin
        while (read_flag && (cnt_busy > 0)) begin
            assign data_read = mem[cnt_read];
            cnt_read = cnt_status + 1;
            cnt_busy = cnt_busy - 1;
            
        end
        
        if (cnt_busy == 0) assign empty = 1;
        
        if (!read_flag) assign err_read = 1;
        
        assign status = cnt_busy;
    end
    
endmodule 
