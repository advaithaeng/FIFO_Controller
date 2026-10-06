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
    // Write pointers
    reg [ptr_width-1:0] wr_ptr_bin;
    reg [ptr_width-1:0] wr_ptr_gray;
    reg [ptr_width-1:0] wr_e1;
    reg [ptr_width-1:0] wr_ptr_sync;

    // Read pointers
    reg [ptr_width-1:0] rd_ptr_bin;
    reg [ptr_width-1:0] rd_ptr_gray;
    reg [ptr_width-1:0] rd_e1;
    reg [ptr_width-1:0] rd_ptr_sync;

    // Next state pointers
    wire [ptr_width-1:0] wr_ptr_bin_next = wr_ptr_bin + 1'b1;
    wire [ptr_width-1:0] rd_ptr_bin_next = rd_ptr_bin + 1'b1;
    wire [ptr_width-1:0] wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    wire [ptr_width-1:0] rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    reg [width-1:0] mem [0: depth-1];

    

    // CDC

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_sync <= 0;
            rd_e1 <= 0;
        end
        else begin
            rd_e1 <= rd_ptr_gray;
            rd_ptr_sync <= rd_e1;
        end
    end


    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_sync <= 0;
            wr_e1 <= 0;
        end
        else begin
            wr_e1 <= wr_ptr_gray;
            wr_ptr_sync <= wr_e1;
        end
    end
            


    // Write block
    always @(posedge wr_clk or negedge wr_rst_n) begin
         if (!wr_rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
         end
        else if (wr_en && !full) begin
            mem[wr_ptr_bin[addr_width-1:0]] <= wdata;

            wr_ptr_bin <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    // Read block
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rdata <= 0;
        end
        else if (rd_en && !empty) begin
            rdata <= mem[rd_ptr_bin[addr_width-1:0]];
            rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end


    // Flags

    assign empty = wr_ptr_sync == rd_ptr_gray;
    assign almost_empty = wr_ptr_sync == rd_ptr_gray_next;

    assign full = wr_ptr_gray == {~rd_ptr_sync[ptr_width-1:ptr_width-2], rd_ptr_sync[ptr_width-3:0]};
    assign almost_full = wr_ptr_gray_next == {~rd_ptr_sync[ptr_width-1:ptr_width-2], rd_ptr_sync[ptr_width-3:0]};


endmodule