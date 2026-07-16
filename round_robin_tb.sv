// Design
module round_robin_arbiter #(parameter WIDTH = 4) (
  input clk,
  input rst_n,
  input [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt);
  
  reg found;
  reg [$clog2(WIDTH)-1:0] ptr;
  reg [WIDTH-1:0] next_gnt;
  int scan_idx;
  int win_idx;
  int i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gnt <= {WIDTH{1'b0}};
      ptr <= 0;
    end else begin
      found = 1'b0;
      win_idx = 0;
      next_gnt = {WIDTH{1'b0}};
      for (i = 0; i < WIDTH; i++) begin
        scan_idx = (ptr + i)%WIDTH;
        if (!found && req[scan_idx]) begin
          found = 1'b1;
          win_idx = scan_idx;
          next_gnt[scan_idx] = 1'b1;
        end
      end
      gnt <= next_gnt;
        
      if (found) begin
        ptr <= (win_idx + 1)%WIDTH;
      end
    end
  end
endmodule
