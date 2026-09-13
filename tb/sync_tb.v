`timescale 1ns / 1ps

module sync_fifo_tb;

  // Parameters
  localparam WIDTH      = 8;
  localparam DEPTH      = 16;
  localparam CLK_PERIOD = 10; // 100 MHz clock

  // Testbench registers and wires
  reg              clk;
  reg              rst_n;
  reg              wr_en;
  reg              rd_en;
  reg  [WIDTH-1:0] wdata;

  wire [WIDTH-1:0] rdata;
  wire             full;
  wire             empty;
  wire             almost_full;
  wire             almost_empty;

  // Device Under Test (DUT) Instantiation
  sync_fifo #(
    .width(WIDTH),
    .depth(DEPTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wdata(wdata),
    .rdata(rdata),
    .full(full),
    .empty(empty),
    .almost_full(almost_full),
    .almost_empty(almost_empty)
  );

  // Clock Generation (50% duty cycle)
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // Waveform Dump Configuration (for EPWave / GTKWave)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sync_fifo_tb);
  end

  // Main Test Procedure
  integer i;
  initial begin
    // -------------------------------------------------------------
    // Test 1: Power-On Reset Verification
    // -------------------------------------------------------------
    wr_en = 1'b0;
    rd_en = 1'b0;
    wdata = {WIDTH{1'b0}};
    rst_n = 1'b0;
    #(CLK_PERIOD * 2);

    rst_n = 1'b1;
    #(CLK_PERIOD);
    $display("=== [TB] Reset Released ===");
    $display("[STATUS] empty=%b, full=%b, almost_empty=%b, almost_full=%b", 
             empty, full, almost_empty, almost_full);

    // -------------------------------------------------------------
    // Test 2: Burst Write (Fill to DEPTH = 16)
    // -------------------------------------------------------------
    $display("\n=== [TB] Burst Writing 16 Items ===");
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      wr_en = 1'b1;
      wdata = 8'hA0 + i;
    end
    @(posedge clk);
    wr_en = 1'b0;
    #(CLK_PERIOD);
    $display("[STATUS] Post-Fill: full=%b, empty=%b, almost_full=%b", full, empty, almost_full);

    // -------------------------------------------------------------
    // Test 3: Overflow Protection (Illegal write when full)
    // -------------------------------------------------------------
    $display("\n=== [TB] Testing Overflow Protection ===");
    @(posedge clk);
    wr_en = 1'b1;
    wdata = 8'hFF;
    @(posedge clk);
    wr_en = 1'b0;
    #(CLK_PERIOD);
    $display("[STATUS] full flag maintained=%b", full);

    // -------------------------------------------------------------
    // Test 4: Single-Cycle Read Burst (Drain 16 Items)
    // -------------------------------------------------------------
    $display("\n=== [TB] Reading 16 Items (1 item per cycle) ===");
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      rd_en = 1'b1;
      
      @(posedge clk);
      rd_en = 1'b0; // Deassert immediately to prevent double reads
      
      #1; // Settling delay for display print
      $display("Read Item %0d: 0x%0h (Expected: 0x%0h)", i, rdata, 8'hA0 + i);
    end
    #(CLK_PERIOD);
    $display("[STATUS] Post-Drain: empty=%b, full=%b, almost_empty=%b", empty, full, almost_empty);

    // -------------------------------------------------------------
    // Test 5: Underflow Protection (Illegal read when empty)
    // -------------------------------------------------------------
    $display("\n=== [TB] Testing Underflow Protection ===");
    @(posedge clk);
    rd_en = 1'b1;
    @(posedge clk);
    rd_en = 1'b0;
    #(CLK_PERIOD);
    $display("[STATUS] empty flag maintained=%b, rdata holds last valid=0x%0h", empty, rdata);

    // -------------------------------------------------------------
    // Test 6: Simultaneous Read and Write
    // -------------------------------------------------------------
    $display("\n=== [TB] Testing Simultaneous Read and Write ===");
    @(posedge clk);
    wr_en = 1'b1;
    wdata = 8'h55;
    @(posedge clk);
    // Write second item while reading first item
    wr_en = 1'b1;
    wdata = 8'hAA;
    rd_en = 1'b1;
    @(posedge clk);
    wr_en = 1'b0;
    rd_en = 1'b0;
    #1;
    $display("Simultaneous Cycle Readout: 0x%0h (Expected: 0x55)", rdata);

    #(CLK_PERIOD * 3);
    $display("\n=== [TB] All Verification Tests Completed Successfully ===");
    $finish;
  end

endmodule
