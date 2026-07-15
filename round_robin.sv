module round_robin_arbiter (
  input            clk,
  input            rst_n,
  input      [3:0] req,
  output reg [3:0] gnt
);

  reg [1:0] last_winner;   // WHO won last cycle — this is the only thing that persists
  reg [3:0] rotated_req;
  reg [3:0] next_gnt;
  integer   i, real_idx;
  reg       found;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gnt         <= 4'b0000;
      last_winner <= 2'd3;     // arbitrary start: makes req[0] top priority on cycle 1
    end else begin
      // Step 1: build a ROTATED VIEW of req (temporary, doesn't touch req itself)
      case (last_winner)
        2'd0: rotated_req = {req[0],   req[3:1]};
        2'd1: rotated_req = {req[1:0], req[3:2]};
        2'd2: rotated_req = {req[2:0], req[3]  };
        2'd3: rotated_req = req;
      endcase

      // Step 2: fixed-priority scan — you've written this exact idea before
      found    = 1'b0;
      next_gnt = 4'b0000;
      for (i = 0; i < 4; i = i + 1) begin
        if (!found && rotated_req[i]) begin
          real_idx           = (i + last_winner + 1) % 4;  // map back to the true bit position
          next_gnt[real_idx] = 1'b1;
          found = 1'b1;
        end
      end

      gnt <= next_gnt;

      // Step 3: only update "who won" if someone actually did
      if (found)
        last_winner <= real_idx;
    end
  end

endmodule
