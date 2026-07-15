module round_robin_arbiter #(parameter WIDTH = 4)(
  input clk,
  input rst_n,
  input  [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt
);

  integer i;
  integer scan_idx;
  integer win_idx;
  reg found;
  reg [WIDTH-1:0] next_gnt;

  // pointer to the current highest-priority index
  reg [$clog2(WIDTH)-1:0] ptr;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gnt <= {WIDTH{1'b0}};
      ptr <= {$clog2(WIDTH){1'b0}};
    end else begin
      next_gnt = {WIDTH{1'b0}};
      found    = 1'b0;
      win_idx  = 0;

      // scan WIDTH slots starting at ptr, wrapping via modulo
      for (i = 0; i < WIDTH; i = i + 1) begin
        scan_idx = (ptr + i) % WIDTH;
        if (!found && req[scan_idx]) begin
          next_gnt[scan_idx] = 1'b1;
          win_idx            = scan_idx;
          found              = 1'b1;
        end
      end

      gnt <= next_gnt;
      if (found)
        ptr <= (win_idx + 1) % WIDTH;   // next cycle's priority starts after the winner
      // if nobody requested, ptr holds — priority order doesn't change
    end
  end

endmodule
