`timescale 1ns/1ps

module testbench;

  // === Global Predictor parameters ===
  parameter GHR_WIDTH = 4;
  parameter NUM_CYCLES = 50;
  parameter STALL_PENALTY = 5;

  // === Signals ===
  reg clk, rst;
  reg predict_request, update_enable;
  reg actual_taken;
  wire predicted_taken;

  // === Stall tracking ===
  integer total_cycles = 0;
  integer total_stalls = 0;

  // === Branch outcome pattern (1 bit only, no PC needed) ===
  reg actual_taken_trace [0:NUM_CYCLES-1];
  integer i;

  // === Instantiate the global predictor ===
  global_branch_predictor #(.GHR_WIDTH(GHR_WIDTH)) uut (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // === Clock generation ===
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    total_cycles = 0;
    total_stalls = 0;

    // === Simple loop-like branch pattern
    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      if (i % 4 == 3)
        actual_taken_trace[i] = 1'b0;  // not taken every 4th iteration
      else
        actual_taken_trace[i] = 1'b1;
    end

    // === Simulate ===
    #10 rst = 0;

    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      @(negedge clk);
      predict_request = 1;
      @(negedge clk);
      predict_request = 0;

      actual_taken = actual_taken_trace[i];
      update_enable = 1;

      if (predicted_taken !== actual_taken) begin
        total_stalls = total_stalls + STALL_PENALTY;
      end

      @(negedge clk);
      update_enable = 0;
      total_cycles = total_cycles + 1;
    end

    // === Print results ===
    $display("\n=== Global Branch Predictor Stall Results ===");
    $display("Total Instructions     : %0d", NUM_CYCLES);
    $display("Total Cycles           : %0d", total_cycles + total_stalls);
    $display("Total Stalls (cycles)  : %0d", total_stalls);
    $display("Average CPI            : %0.2f", (1.0 * (total_cycles + total_stalls)) / NUM_CYCLES);
    $finish;
  end

endmodule
