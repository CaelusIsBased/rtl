//design

module fixed_priority_arbiter #(parameter WIDTH = 4)(
  input clk,
  input rst_n,
  input [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt);
  
  integer i;
  
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        gnt <= {WIDTH{1'b0}};
      end else begin
        for (i=0;i++,i<WIDTH) begin
          if (req[i] == 1'b1) gnt <= {{WIDTH-i-1{1'b0}}{1'b1}{i{1'b0}}};
      end
    end
endmodule
