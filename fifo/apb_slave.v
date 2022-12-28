
`define IDLE    2'b00
`define READ   2'b01
`define WRITE  2'b10

module apb_slave(
    input  wire         PCLK,
    input  wire         PRESETn,
    input  wire [7:0]   PADDR,
    input  wire         PSELx,
    input  wire         PENABLE,
    input  wire         PWRITE,
    input  wire [31:0]  PWDATA,
    output reg          PREADY,
    output reg  [31:0]  PRDATA,
    output reg          PSLVERR

    );

reg [31:0] RAM [127:0];

reg [1:0] state;

always @(negedge PRESETn or posedge PCLK) begin
    if (PRESETn == 0) begin
        state <= `IDLE;
        PRDATA <= 0;
        PREADY <= 0;
        PSLVERR <= 0;
    end 
end

always @(negedge PRESETn or posedge PCLK) begin
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

                    RAM[PADDR] <= PWDATA;
                PREADY <= 1;
            end
            state <= `IDLE;
        end

        `READ : begin
            if (PSEL & ~PWRITE) begin
                PREADY <= 1;
                PRDATA <= RAM[PADDR];
            end
            state = `IDLE;
        end
        default : begin
            state <= `IDLE;
        end
    endcase


end

endmodule