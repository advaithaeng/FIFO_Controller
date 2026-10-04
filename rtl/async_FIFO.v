module async_FIFO #(
    parameter width = 8,
    parameter depth = 16,
    parameter addr_width = $clog2(depth),
    parameter ptr_width = addr_width+1
) (
    input wire wr_en,
    input wire rd_en,
    input wire wr_clk,
    input wire rd_clk,
    input wire wr_rst_n,
    input wire rd_rst_n,
    input wire [width-1:0] wdata,
    
    output reg [width-1:0] rdata,
    output wire full,
    output wire empty,
    output wire almost_full,
    output wire almost_empty
);
    wire [ptr_width-1:0] wr_ptr_bin;
    wire [ptr_width-1:0] wr_ptr_gray;
    wire [ptr_width-1:0] wr_e1;
    wire [ptr_width-1:0] wr_e2;
    wire [ptr_width-1:0] wr_ptr_sync;

    wire [ptr_width-1:0] rd_ptr_bin;
    wire [ptr_width-1:0] rd_ptr_gray;
    wire [ptr_width-1:0] rd_e1;
    wire [ptr_width-1:0] rd_e2;
    wire [ptr_width-1:0] rd_ptr_sync;

    reg [width-1:0] mem [0: depth-1];

    assign wr_ptr_gray = (wr_ptr_bin >> 1) ^ wr_ptr_bin;
    assign rd_ptr_gray = (rd_ptr_bin >> 1) ^ rd_ptr_bin;

    


endmodule