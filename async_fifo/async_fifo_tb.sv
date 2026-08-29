`timescale 1ns/1ps

module async_fifo_tb;

  localparam int DEPTH = 8;
  localparam int WIDTH = 8;

  logic wr_clk = 0, rd_clk = 0;
  always #5 wr_clk = ~wr_clk;
  always #6.67 rd_clk = ~rd_clk;

  logic wr_rst_n, rd_rst_n;
  logic wr_en, rd_en;
  logic [WIDTH-1:0] wr_data, rd_data;
  logic full, emptyl

  async_fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dut (.*);

  int pass_cnt = 0, fail_cnt = 0;

  logic [WIDTH-1:0] ref_q[$];

  initial begin
    logic [WIDTH-1:0] exp, captured;

    $dumpfile("dump.vcd");
    $dumpvars(0, async_fifo_tb);

    wr_rst_n = 0; rd_rst_n = 0;
    wr_en = 0; rd_en = 0; wr_data = 0;

    $display("ASYNC FIFO TB");

    repeat(4) @(posedge wr_clk);
    wr_rst_n = 1; rd_rst_n = 1;
    repeat(2) @(posedge wr_clk); #1;

    // Initial State
    if (empty && !full) begin $display("PASS Initial: empty = 1, full = 0"); pass_cnt++; end
    else begin $display("FAIL Initial State Mismatch"); fail_cnt++; end

    // WRITE DEPTH ITEMS
    $display("WRITING %0d items", DEPTH);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge wr_clk); #1;
      wr_en = 1; wr_data = 8'(i+1);
      ref_q.push_back(8'(i+1));
    end
    @(posedge wr_clk); #1; wr_en = 0;
    repeat(4) @(posedge wr_clk); #1;
    if (full) begin $display("PASS full asserted"); pass_cnt++; end
    else begin $display("FAIL full not asserted"); fail_cnt++; end

    // READ ALL ITEMS, CHECK DATA INTEGRITY
    $display("Reading and checking data");
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge rd_clk); #1;
      captured = rd_data;
      rd_en = 1;
      @(posedge rd_clk); #1;
      exp = ref_q.pop_front();
      if (captured === exp) begin
        $display("PASS rd_data = %0h", captured); pass_cnt++;
      end else begin
        $display("FAIL rd_data = %0h expected = %0h", captured, exp);
        fail_cnt++;
      end
    end

    $display("\n--- %0d passed, %0d failed ---", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("PASS");
    else $display("FAIL");
    $finish;
  end
endmodule
    
