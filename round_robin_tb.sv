module tb_round_robin_arbiter;

  parameter WIDTH = 4;   // change this to retest at any width

  reg clk;
  reg rst_n;
  reg  [WIDTH-1:0] req;
  wire [WIDTH-1:0] gnt;

  round_robin_arbiter #(.WIDTH(WIDTH)) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .req   (req),
    .gnt   (gnt)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  // ---- golden reference model, mirrors DUT's pointer state ----
  reg [$clog2(WIDTH)-1:0] ref_ptr;
  reg [WIDTH-1:0]         ref_gnt;
  integer i, scan_idx, win_idx;
  reg found;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ref_gnt <= {WIDTH{1'b0}};
      ref_ptr <= {$clog2(WIDTH){1'b0}};
    end else begin
      ref_gnt = {WIDTH{1'b0}};
      found   = 1'b0;
      win_idx = 0;
      for (i = 0; i < WIDTH; i = i + 1) begin
        scan_idx = (ref_ptr + i) % WIDTH;
        if (!found && req[scan_idx]) begin
          ref_gnt[scan_idx] = 1'b1;
          win_idx           = scan_idx;
          found             = 1'b1;
        end
      end
      ref_gnt <= ref_gnt;
      if (found)
        ref_ptr <= (win_idx + 1) % WIDTH;
    end
  end

  integer k, errors;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_round_robin_arbiter);

    errors = 0;
    rst_n  = 0;
    req    = {WIDTH{1'b0}};
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;

    // --- directed test: everyone always requesting, watch the pointer rotate ---
    req = {WIDTH{1'b1}};
    for (k = 0; k < 2*WIDTH; k = k + 1) begin
      @(posedge clk);
      #1;
      if (gnt !== ref_gnt) begin
        $display("FAIL(rotate)! t=%0t req=%b gnt=%b expected=%b", $time, req, gnt, ref_gnt);
        errors = errors + 1;
      end else begin
        $display("PASS(rotate)! t=%0t req=%b gnt=%b", $time, req, gnt);
      end
    end

    // --- random test: varying req patterns ---
    for (k = 0; k < 50; k = k + 1) begin
      req = $random;
      @(posedge clk);
      #1;
      if (gnt !== ref_gnt) begin
        $display("FAIL(rand)! t=%0t req=%b gnt=%b expected=%b", $time, req, gnt, ref_gnt);
        errors = errors + 1;
      end else begin
        $display("PASS(rand)! t=%0t req=%b gnt=%b", $time, req, gnt);
      end
    end

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("%0d TESTS FAILED", errors);

    $display("TEST OWARI");
    $finish;
  end

endmodule
