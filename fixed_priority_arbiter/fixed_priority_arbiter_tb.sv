//testbench
module tb_fixed_priority_arbiter;
  
  reg clk;
  reg rst_n;
  reg [3:0] req;
  wire [3:0] gnt;
  
  fixed_priority_arbiter dut(
    .clk (clk),
    .rst_n (rst_n),
    .req (req),
    .gnt (gnt)
  );
  
  localparam WIDTH = 4;
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  function automatic [WIDTH-1:0] expected_gnt(input [WIDTH-1:0] r);
    integer j;
    reg found;
    begin
      expected_gnt = {WIDTH{1'b0}};
      found = 1'b0;
      for (j = 0; j < WIDTH; j = j + 1) begin
        if (!found && r[j]) begin
          expected_gnt = (1 << j);
          found = 1'b1;
        end
      end
    end
  endfunction
  
  integer k;
  
  initial begin
    
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_fixed_priority_arbiter);
    
    rst_n = 0;
    req   = 4'b0000;
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;
  
    for (k = 0; k<(1<<WIDTH); k++) begin

      req = k[WIDTH-1:0];
      @(posedge clk)
      #1


      if (gnt !== expected_gnt(req))
        $display("FAIL! Req:%b Gnt:%b Expected:%b", req, gnt, expected_gnt(req));
      else
        $display("PASS! Req:%b Gnt:%b", req, gnt);
      end
  
    $display("TEST OWARI");
    $finish;
  
  end
  
endmodule
