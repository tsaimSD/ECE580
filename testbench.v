`timescale 1ns/1ps

module testbench;

  parameter GHR_WIDTH = 4;

  reg clk, rst;
  reg predict_request, update_enable;
  reg actual_taken;
  wire predicted_taken;

  integer total_predictions = 0;
  integer mispredictions = 0;

  // Instantiate predictor
  global_branch_predictor #(GHR_WIDTH) uut (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // Clock generator
  always #5 clk = ~clk;

  // Branch outcome sequence (T = 1, NT = 0)
  reg [0:15] branch_trace = 16'b1101011011101001;
  integer i;

  initial begin
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    #10;
    rst = 0;

    // Loop through branch outcomes
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge clk);
      predict_request = 1;
      @(negedge clk); // Wait for prediction
      predict_request = 0;

      actual_taken = branch_trace[i];
      update_enable = 1;

      if (predicted_taken !== actual_taken) begin
        mispredictions = mispredictions + 1;
      end
      total_predictions = total_predictions + 1;

      @(negedge clk);
      update_enable = 0;
    end

    // Display results
    $display("Total predictions     = %0d", total_predictions);
    $display("Mispredictions        = %0d", mispredictions);
    $display("Misprediction rate    = %f%%", (100.0 * mispredictions) / total_predictions);
    $finish;
  end

endmodule
