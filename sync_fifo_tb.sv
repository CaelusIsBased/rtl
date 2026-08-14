module tb;
  localparam DEPTH               = 8;
  localparam WIDTH               = 8;
  localparam ALMOST_FULL_THRESHOLD  = 6;
  localparam ALMOST_EMPTY_THRESHOLD = 2;

  logic              clk;
  logic              rst_n;
  logic              write_en;
  logic [WIDTH-1:0]  write_data;
  logic              read_en;
  logic [WIDTH-1:0]  read_data;
  logic              full, empty, almost_full, almost_empty;
  int                p = 0, f = 0;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;
  // DUT instantiation
  sync_fifo #(
    .DEPTH               (DEPTH),
    .WIDTH               (WIDTH),
    .ALMOST_FULL_THRESHOLD  (ALMOST_FULL_THRESHOLD),
    .ALMOST_EMPTY_THRESHOLD (ALMOST_EMPTY_THRESHOLD)
  ) dut (.*);

  task automatic push(input logic [WIDTH-1:0] d);
    
    @(negedge clk); write_en = 1;
    write_data = d;
    @(posedge clk); @(negedge clk);
    write_en = 0;
  endtask

  task automatic pop(output logic [WIDTH-1:0] d);
    @(negedge clk); read_en = 1;
    d = read_data;  // capture before posedge advances ptr
    @(posedge clk); @(negedge clk);
    read_en = 0;
  endtask

  logic [WIDTH-1:0] rd;

  initial begin
    // Reset sequence
    rst_n      = 0;
    write_en   = 0;
    read_en    = 0;
    write_data = 0;
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // =========================================================
    // TC1 — Basic FIFO Order
    // =========================================================
    push(8'hAA); push(8'hBB); push(8'hCC);
    pop(rd);
    if (rd == 8'hAA) begin p++; $display("PASS: TC1 pop 0xAA"); end
    else begin f++; $display("FAIL: TC1 pop 0xAA got %h", rd); end
    pop(rd);
    if (rd == 8'hBB) begin p++; $display("PASS: TC1 pop 0xBB"); end
    else begin f++; $display("FAIL: TC1 pop 0xBB got %h", rd); end
    pop(rd);
    if (rd == 8'hCC) begin p++; $display("PASS: TC1 pop 0xCC"); end
    else begin f++; $display("FAIL: TC1 pop 0xCC got %h", rd); end

    // =========================================================
    // TC2 — Full Flag Boundary (fill all 8 slots)
    // =========================================================
    repeat (8) push(8'hFF);
    @(negedge clk);
    if (full) begin p++; $display("PASS: TC2 full after 8 writes"); end
    else begin f++; $display("FAIL: TC2 full not set"); end
    // Overflow attempt must be ignored
    push(8'hEE);
    @(negedge clk);
    if (full) begin p++; $display("PASS: TC2 still full after overflow attempt"); end
    else begin f++; $display("FAIL: TC2 full cleared unexpectedly"); end

    // Reset before TC3
    rst_n = 0; @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);

    // =========================================================
    // TC3 — Empty Flag Boundary
    // =========================================================
    push(8'h01); push(8'h02); push(8'h03);
    pop(rd); pop(rd); pop(rd);
    @(negedge clk);
    if (empty) begin p++; $display("PASS: TC3 empty after 3 reads"); end
    else begin f++; $display("FAIL: TC3 empty not set"); end
    read_en = 1; @(posedge clk); read_en = 0; @(negedge clk);
    if (empty) begin p++; $display("PASS: TC3 still empty after underflow attempt"); end
    else begin f++; $display("FAIL: TC3 empty cleared unexpectedly"); end

    // Reset before TC4
    rst_n = 0; @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);

    // =========================================================
    // TC4 — Almost-Full Threshold (threshold=6)
    // =========================================================
    repeat (6) push(8'hAA);
    @(negedge clk);
    if (almost_full && !full) begin p++; $display("PASS: TC4 almost_full=1 at count=6"); end
    else begin f++; $display("FAIL: TC4 almost_full"); end

    // =========================================================
    // TC5 — Almost-Empty Threshold (threshold=2)
    // =========================================================
    rst_n = 0; @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
    repeat (3) push(8'hBB);
    begin : tc5
      bit tc5_ok;
      tc5_ok = 1;
      pop(rd); @(negedge clk);  // count=2
      if (!(almost_empty && !empty)) begin tc5_ok = 0; $display("FAIL: TC5 expected almost_empty=1, empty=0 at count=2"); end
      pop(rd); @(negedge clk);  // count=1
      if (!(almost_empty && !empty)) begin tc5_ok = 0; $display("FAIL: TC5 expected almost_empty=1, empty=0 at count=1"); end
      pop(rd); @(negedge clk);  // count=0
      if (!empty) begin tc5_ok = 0; $display("FAIL: TC5 expected empty=1 at count=0"); end
      if (tc5_ok) begin p++; $display("PASS: TC5 almost_empty threshold (count=2,1,0)"); end
      else f++;
    end


    // =========================================================
    // TC6 — Simultaneous Read+Write
    // =========================================================
    rst_n = 0; @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
    repeat (4) push(8'hAA);  // count=4, neither full nor empty
    @(negedge clk);
    write_en = 1; write_data = 8'hBB;
    read_en  = 1;
    @(posedge clk); @(negedge clk);
    write_en = 0; read_en = 0;
    if (!full && !empty) begin p++; $display("PASS: TC6 simultaneous R+W"); end
    else begin f++; $display("FAIL: TC6 simultaneous R+W full=%0b empty=%0b", full, empty); end

    // Summary
    $display("=== %0d passed %0d failed ===", p, f);
    $finish;
  end
endmodule
