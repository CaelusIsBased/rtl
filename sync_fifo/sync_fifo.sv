module sync_fifo #(
  parameter int DEPTH = 16,
  parameter int WIDTH = 8
)(
  input  logic                       clk,
  input  logic                       rst_n,    // Active-low synchronous reset

  // ── Write port
  input  logic                       wr_en,
  input  logic [WIDTH-1:0]           wr_data,

  // ── Read port
  input  logic                       rd_en,
  output logic [WIDTH-1:0]           rd_data,

  // ── Status
  output logic                       full,
  output logic                       empty,
  output logic [$clog2(DEPTH):0]     count     // Current occupancy (0..DEPTH)
);

  // ── Internal storage
  logic [WIDTH-1:0]          mem [0:DEPTH-1];
  logic [$clog2(DEPTH)-1:0]  wr_ptr, rd_ptr;   // Circular pointers
  logic [$clog2(DEPTH):0]    cnt;               // One extra bit for DEPTH value

  // ── Registered write + count
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      cnt    <= '0;
    end else begin
      // Count update — three mutually exclusive cases:
      if      (wr_en && !full  && !rd_en) cnt <= cnt + 1;  // write only
      else if (rd_en && !empty && !wr_en) cnt <= cnt - 1;  // read only
      // simultaneous rd+wr: count unchanged (one in, one out)

      // Write data
      if (wr_en && !full) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= wr_ptr + 1;  // wraps automatically at $clog2(DEPTH) bits
      end
    end
  end

  // ── Read pointer 
  always_ff @(posedge clk) begin
    if (!rst_n)
      rd_ptr <= '0;
    else if (rd_en && !empty)
      rd_ptr <= rd_ptr + 1;
  end

  // ── Combinational outputs 
  assign full    = (cnt == DEPTH[($clog2(DEPTH)):0]);
  assign empty   = (cnt == '0);
  assign rd_data = mem[rd_ptr];   
  assign count   = cnt;

endmodule
