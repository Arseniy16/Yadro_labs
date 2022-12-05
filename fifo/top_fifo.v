
module top_fifo(
        input  wire clk,
        input  wire reset,
        input  wire write,
        input  wire read,
        input  wire [31:0] data_write,
        output wire [31:0] data_read,
        output wire full,
        output wire empty,
        output reg [7:0] status,
        output wire err_read,
        output wire err_write
        
    );

    reg [31:0] mem [127:0];
    
    reg [7:0] cnt_write;
    reg [7:0] cnt_read;
        
    always @(posedge clk or negedge reset) begin
        if(~reset) begin
            cnt_read <= 8'b0;
        end
        else if(read & ~err_read) begin
            cnt_read <= cnt_read + 1'b1 ;
        end
    end

    always @(posedge clk or negedge reset) begin
        if(~reset) begin
            cnt_write <= 8'b0;
        end
        else if(write & ~err_write) begin
            cnt_write <= cnt_write + 1'b1 ;
        end
    end

    always @(posedge clk or negedge reset) begin
        if(~reset) begin
            status <= 8'b0;
        end
        else if(write & ~read & ~err_write) begin
            status <= status + 1'b1 ;
        end
        else if(~write & read & ~err_read) begin
            status <= status - 1'b1 ;
        end
    end
            
    assign full = (status == {1'b0, {7{1'b1}}}) ;
    assign empty = (status == {8{1'b0}}) ;

    assign data_read = mem[cnt_read] ;

    always @(posedge clk) begin
        if(write & ~err_write) begin
            mem[cnt_write] <= data_write;
        end
    end

    assign err_read = read & empty ;
    assign err_write = write & full ;

    
endmodule 
