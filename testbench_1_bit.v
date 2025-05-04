`timescale 1ns/1ps

module testbench;

  parameter INDEX_WIDTH = 6;
  localparam NUM_BRANCHES = 20;

  reg clk, rst;
  reg predict_request, update_enable;
  reg actual_taken;
  reg [INDEX_WIDTH-1:0] pc_index;
  wire predicted_taken;

  integer total_predictions = 0;
  integer mispredictions = 0;

  // === DUT: One-bit predictor ===
  one_bit_branch_predictor #(.INDEX_WIDTH(INDEX_WIDTH)) uut (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .pc_index(pc_index),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // === Clock ===
  always #5 clk = ~clk;

  // === Branch trace data ===
  // Format: {PC_index[5:0], actual_taken}
  reg [INDEX_WIDTH:0] branch_trace [0:NUM_BRANCHES-1];
  integer i;

  initial begin
    // Fill with known loop and alternating patterns
    branch_trace[0]  = {6'd10, 1'b1};
    branch_trace[1]  = {6'd10, 1'b1};
    branch_trace[2]  = {6'd10, 1'b0};
    branch_trace[3]  = {6'd11, 1'b1};
    branch_trace[4]  = {6'd11, 1'b1};
    branch_trace[5]  = {6'd11, 1'b0};
    branch_trace[6]  = {6'd12, 1'b1};
    branch_trace[7]  = {6'd12, 1'b0};
    branch_trace[8]  = {6'd12, 1'b1};
    branch_trace[9]  = {6'd12, 1'b0};
    branch_trace[10] = {6'd13, 1'b1};
    branch_trace[11] = {6'd13, 1'b1};
    branch_trace[12] = {6'd13, 1'b1};
    branch_trace[13] = {6'd13, 1'b0};
    branch_trace[14] = {6'd10, 1'b1};
    branch_trace[15] = {6'd10, 1'b1};
    branch_trace[16] = {6'd10, 1'b0};
    branch_trace[17] = {6'd14, 1'b1};
    branch_trace[18] = {6'd14, 1'b1};
    branch_trace[19] = {6'd14, 1'b1};

    // === Simulate ===
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    #10 rst = 0;

    for (i = 0; i < NUM_BRANCHES; i = i + 1) begin
      @(negedge clk);
      pc_index = branch_trace[i][INDEX_WIDTH:1];
      predict_request = 1;
      @(negedge clk);
      predict_request = 0;

      actual_taken = branch_trace[i][0];
      update_enable = 1;

      if (predicted_taken !== actual_taken)
        mispredictions = mispredictions + 1;
      total_predictions = total_predictions + 1;

      @(negedge clk);
      update_enable = 0;
    end

    $display("\n===== One-Bit Branch Predictor Results =====");
    $display("Total Predictions     : %0d", total_predictions);
    $display("Mispredictions        : %0d", mispredictions);
    $display("Misprediction Rate    : %0.2f%%", 100.0 * mispredictions / total_predictions);
    $finish;
  end

endmodule
