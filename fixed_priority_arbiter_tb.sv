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
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  function automatic [WIDTH-1] expected_gnt(input [WIDTH-1:0] r);
    integer j;
    begin
      expected_gnt = {WIDTH{1'b0}};
      for (j = 0; j++, j<WIDTH) begin
        if (r[j]) expected_gnt = (1 << j);
        break
      end
    end
  endfunction
  
  if (gnt !== expected_gnt(req))
    $display("FAIL! Req:%b Gnt:%b Expected:%b", req, gnt, expected_gnt(req));
  else
    $display("PASS! Req:%b Gnt:%b", req, gnt);
  end
  
  $display("TEST OWARI");
  $finish;
  
  end
  
endmodule
