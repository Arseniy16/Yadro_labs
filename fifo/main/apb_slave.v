
module apb_slave(
    input  wire         PCLK,
    input  wire         PRESET,
    input  wire [31:0]  PADDR,
    input  wire         PSEL,
    input  wire         PENABLE,
    input  wire         PWRITE,
    input  wire [31:0]  PWDATA,

    output wire         PREADY,
    output wire [31:0]  PRDATA,
    output wire         PSLVERR,

    // input wire          err_read,
    // input wire          err_write,
    input wire  [31:0]  data_read,
    output wire [31:0]  data_write,
    output wire         write,
    output wire         read,

    input wire          empty,
    input wire          full
);

    assign write = (~full & PSEL & PWRITE & PENABLE & (PADDR == 32'b1) );
    assign read = (~empty & PSEL & ~PWRITE & PENABLE & (PADDR == 32'b10) );

    assign PREADY = (PSEL & PENABLE) ;
    assign PSLVERR = ( (full & PWRITE) | (empty & ~PWRITE) );
    
    assign data_write = PWDATA;
    assign PRDATA = data_read;

endmodule
