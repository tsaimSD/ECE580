module tb_global_predictor_checker;

  parameter GHR_WIDTH = 8;
  parameter ROUNDS = 4;

  logic clk, rst;
  logic predict_request, update_enable, actual_taken;
  logic predicted_taken;

  complex_hashed_global_branch_predictor #(
    .GHR_WIDTH(GHR_WIDTH),
    .ROUNDS(ROUNDS)
  ) dut (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    actual_taken = 0;
    #10 rst = 0;
  end

  // === Formal properties ===
  // Example functional sanity check
  property p_stable_prediction_when_same_input;
    @(posedge clk)
    disable iff (rst)
    (predict_request && update_enable && actual_taken === predicted_taken);
  endproperty
  assert property (p_stable_prediction_when_same_input);

endmodule