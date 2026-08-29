//design

module fixed_priority_arbiter #(parameter WIDTH = 4)(
  input clk,
  input rst_n,
  input [WIDTH-1:0] req,
  output reg [WIDTH-1:0] gnt);
  
  reg found;
  integer i;
  
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        gnt <= {WIDTH{1'b0}};
      end else begin
        found = 1'b0;
        for (i=0;i<WIDTH;i++) begin
          if (!found && req[i] == 1'b1) begin
            gnt <= ({{WIDTH-1{1'b0}}, 1'b1} << i);
            found = 1'b1;
          end
        end
      end
    end
      
    
endmodule
