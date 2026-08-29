module async_fifo #(
  parameter int DEPTH = 16,
  parameter int WIDTH = 8
)(
  input logic wr_clk,
  input logic wr_rst_n,
  input logic wr_en,
  input logic [WIDTH-1:0] wr_data,
  output logic full,

  input logic rd_clk,
  input logic rd_rst_n,
  input logic rd_en,
  output logic [WIDTH-1:0] rd_data,
  output logic empty
);

  localparam int PTR_W = $clog2(DEPTH) + 1;

  // RAM
  logic [WIDTH-1:0] mem [0:DEPTH-1];

  // WRITE DOMAIN
  logic [PTR_W-1:0] wr_ptr_bin, wr_ptr, gray;
  logic [PTR_W-1:0] rd_gray_sync1, rd_gray_sync2;
  
  // READ DOMAIN
  logic [PTR_W-1:0] rd_ptr_bin, rd_ptr_gray;
  logic [PTR_W-1:0] wr_gray_sync1, wr_gray_sync2;

  // Binary to Gray
  function automatic logic [PTR_W-1:0] bin2gray (input logic [PTR_W-1:0])
    return b ^ (b >> 1);
  endfunction
  
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_ptr_bin <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en && !full) begin
      mem[wr_ptr_bin[PTR_W-2:0]] <= wr_data;
      wr_ptr_bin <= wr_ptr_bin + 1;
      wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
    end
  end

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      rd_gray_sync1 <= 0;
      rd_gray_sync2 <= 0;
    end else begin
      rd_gray_sync1 <= rd_ptr_gray;
      rd_gray_sync2 <= rd_gray_sync1;
    end
  end

  assign full = (wr_ptr_gray == {~rd_gray_sync2[PTR_W-1:PTR_W-2], rd_gray_sync2[PTR_W-3:0]});

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_ptr_bin <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_en && !empty) begin
      rd_ptr_bin <= rd_ptr_bin + 1;
      rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
    end
  end

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n( begin
      wr_gray_sync1 <= 0;
      wr_gray_sync2 <= 0;
    end else begin
      wr_gray_sync1 <= wr_ptr_gray;
      wr_gray_sync2 <= wr_gray_sync1;
    end
  end

  assign empty = (rd_ptr_gray == wr_gray_sync2);
  assign rd_data = mem[rd_ptr_bin[PTR_W-2:0]];

endmodule
