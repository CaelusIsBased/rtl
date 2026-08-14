module sync_fifo #(
  parameter int unsigned DEPTH = 8,
  parameter int unsigned WIDTH = 8,

  parameter int unsigned ALMOST_FULL_THRESHOLD = DEPTH - 1,
  parameter int unsigned ALMOST_EMPTY_THRESHOLD = 1
)(
  input logic clk,
  input logic rst_n,

  input logic write_en,
  input logic [WIDTH-1:0] write_data,

  input logic read_en,
  output logic [WIDTH-1:0] read_data,

  output logic full,
  output logic empty,
  output logic almost_full,
  output logic almost_empty
);

  localparam int unsigned ADDR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  logic [ADDR_W-1:0] rd_ptr, wr_ptr;
  logic [ADDR_W:0] count;

  initial begin
    if (DEPTH < 2 || (DEPTH & (DEPTH-1)) != 0) begin
      $fatal(1, "Invalid Depth");
    end else if (ALMOST_FULL_THRESHOLD > DEPTH) begin
      $fatal(1, "almost_full > depth!!");
    end else if (ALMOST_FULL_THRESHOLD < ALMOST_EMPTY_THRESHOLD) begin
      $fatal(1, "almost_empty > almost_full!!");
    end
  end

  logic write_fire, read_fire;

  assign write_fire = write_en && (!full);
  assign read_fire = read_en && !empty;

  assign full = (count == DEPTH);
  assign empty = (count == 0);
  assign almost_full = (count >= ALMOST_FULL_THRESHOLD);
  assign almost_empty = ( ALMOST_EMPTY_THRESHOLD >= count);


  always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
  
    rd_ptr <= 0;
    wr_ptr <= 0;
    count <= 0;
    
    // read_data <= 0;
  end else begin
  
    if (write_fire) begin
      mem[wr_ptr] <= write_data;
      wr_ptr <= wr_ptr + 1;
    end
    if (read_fire) begin
      // read_data <= mem[rd_ptr];
      rd_ptr <= rd_ptr + 1;
    end

    case ({write_fire, read_fire})
    2'b10: count <= count + 1;
    2'b01: count <= count - 1;
    default: count <= count;
    endcase
  
  end
  end

  assign read_data = mem[rd_ptr];

endmodule
  
