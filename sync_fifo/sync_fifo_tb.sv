`timescale 1ns/1ps

module sync_fifo_tb;

  // ── Parameters 
  localparam int DEPTH = 8;
  localparam int WIDTH = 8;

  // ── DUT ports 
  logic                   clk, rst_n;
  logic                   wr_en, rd_en;
  logic [WIDTH-1:0]       wr_data, rd_data;
  logic                   full, empty;
  logic [$clog2(DEPTH):0] count;

  // Instantiate DUT
  sync_fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dut (.*);

  // ── Clock 
  always #5 clk = ~clk;

  // ── Helpers 
  int pass_cnt = 0, fail_cnt = 0;

  task automatic clk_cycle (int n = 1);
    repeat (n) @(posedge clk); #1;
  endtask

  task automatic assert_eq (logic [31:0] got, expected, string label);
    if (got === expected) begin

      $display("  PASS  %s", label);
      pass_cnt++;
    end else begin
      $display("  FAIL  %s  got=%0h expected=%0h", label, got, expected);
      fail_cnt++;
    end
  endtask

  // ── Stimulus 
  initial begin
    clk = 0; rst_n = 0; wr_en = 0; rd_en = 0; wr_data = '0;
    // ── VCD waveform dump (generates waveform viewer data) 
    $dumpfile("dump.vcd");
    $dumpvars(0, sync_fifo_tb);
    // 
    $display("=== sync_fifo testbench (depth=%0d width=%0d) ===", DEPTH, WIDTH);

    // 1. Reset
    clk_cycle(2);
    rst_n = 1;
    assert_eq(empty, 1, "empty after reset");
    assert_eq(full,  0, "not full after reset");
    assert_eq(count, 0, "count=0 after reset");

    // 2. Fill to capacity
    $display("-- Fill FIFO --");
    for (int i = 0; i < DEPTH; i++) begin
      wr_en = 1; wr_data = 8'(i + 1);
      clk_cycle();
    end
    wr_en = 0;
    assert_eq(full,  1, "full after filling");
    assert_eq(count, DEPTH, "count==DEPTH");

    // 3. Overflow protection — write while full should be ignored
    wr_en = 1; wr_data = 8'hFF;
    clk_cycle();
    wr_en = 0;
    assert_eq(count, DEPTH, "count unchanged after overflow attempt");

    // 4. Drain FIFO
    $display("-- Drain FIFO --");
    for (int i = 0; i < DEPTH; i++) begin
      rd_en = 1; clk_cycle();
    end
    rd_en = 0;
    assert_eq(empty, 1, "empty after drain");
    assert_eq(count, 0, "count=0 after drain");

    // 5. Underflow protection
    rd_en = 1; clk_cycle(); rd_en = 0;
    assert_eq(empty, 1, "still empty after underflow attempt");

    // 6. Simultaneous rd+wr — count must not change
    wr_en = 1; wr_data = 8'hAA; clk_cycle(); wr_en = 0; // push one
    wr_en = 1; wr_data = 8'h55;
    rd_en = 1;
    clk_cycle();
    wr_en = 0; rd_en = 0;
    assert_eq(count, 1, "count unchanged on simultaneous rd+wr");

    $display("\n=== %0d passed, %0d failed ===", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("PASS");
    else               $display("FAIL");
    $finish;
  end

endmodule
