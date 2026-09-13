module sync_fifo #(
  parameter width = 8,
  parameter depth = 16,
  parameter addr_width = $clog2(depth),
  parameter ptr_width = addr_width+1
)(
  input wire wr_en,
  input wire rd_en,
  input wire clk,
  input wire rst_n,
  input wire [width-1:0] wdata,
  
  output reg [width-1:0] rdata,
  output wire full,
  output wire empty,
  output wire almost_full,
  output wire almost_empty);
  
  reg [width-1:0] mem [0: depth-1];
  
  reg [ptr_width-1:0] wr_ptr;
  reg [ptr_width-1:0] rd_ptr;
  
  wire [ptr_width-1:0] occupancy = (wr_ptr-rd_ptr);
  
  assign almost_full = (occupancy >= depth-2);
  assign almost_empty = (occupancy <= 2);
  
  assign empty = (wr_ptr == rd_ptr);
  
  assign full = (wr_ptr[addr_width] != rd_ptr[addr_width]) && (wr_ptr[addr_width-1:0] == rd_ptr[addr_width-1:0]);
  
// Write block
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
    end
    else if (wr_en && !full) begin
      mem[wr_ptr[addr_width-1:0]] <= wdata;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end
  
  
// Read block
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rdata <= 0;
    end 
    else if (rd_en && !empty) begin
      rdata <= mem[rd_ptr[addr_width-1:0]];
      rd_ptr <= rd_ptr + 1'b1;
    end
  end
  
endmodule
      
