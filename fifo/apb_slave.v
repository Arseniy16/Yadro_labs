
`define IDLE   2'b00
`define READ   2'b01
`define WRITE  2'b10

module apb_slave(
    input  wire         PCLK,
    input  wire         PRESET,
    input  wire [7:0]   PADDR,
    input  wire         PSEL,
    input  wire         PENABLE,
    input  wire         PWRITE,
    input  wire [31:0]  PWDATA,

    output wire         PREADY,
    output wire [31:0]  PRDATA,
    output wire         PSLVERR

    input wire          err_read,
    input wire          err_write,
    input wire  [31:0]  data_read,
    output wire [31:0]  data_write,
    output wire         write // ?

    );


// reg [31:0] RAM [127:0];

reg [1:0] state;

always @(negedge PRESET or posedge PCLK) begin
    if (PRESET == 0) begin
        state <= `IDLE;
        PRDATA <= 0;
        PREADY <= 0;
        PSLVERR <= 0;

    end 

    if (err_read | err_write) PSLVERR <= 1;
    else if (~err_read & ~err_write) PSLVERR <= 0;
end

always @(negedge PRESET or posedge PCLK) begin
    case(state)
        `IDLE : begin
            PRDATA <= 0;
            if (PSEL) begin
                if (PWRITE) begin
                    state <= `WRITE;
                end
                else begin
                    state <= `READ;
                end    
            end
        end

        `WRITE : begin
            if (PSEL & PWRITE) begin
                if (PENABLE) begin
                    write <= 1;
                    data_write <= PWDATA;
                    PREADY <= 1;
                end
            end
            state <= `IDLE;
        end

        `READ : begin
            if (PSEL & ~PWRITE) begin
                if (PENABLE) begin
                    write <= 0;
                    PRDATA <= data_read;
                    PREADY <= 1;
                end
            end
            state <= `IDLE;
        end

        default : begin
            state <= `IDLE;
        end
    endcase

end

endmodule