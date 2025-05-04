`timescale 1ns/1ps

module testbench;

  // === Predictor parameters ===
  parameter INDEX_WIDTH = 4;
  parameter NUM_CYCLES = 50;
  parameter STALL_PENALTY = 5;

  // === Testbench control signals ===
  reg clk, rst;
  reg predict_request, update_enable;
  reg [INDEX_WIDTH-1:0] pc_index;
  reg actual_taken;
  wire predicted_taken;

  // === Stall accounting ===
  integer total_cycles = 0;
  integer total_stalls = 0;

  // === Branch behavior model ===
  // Format: {pc_index[3:0], actual_taken}
  reg [INDEX_WIDTH:0] branch_trace [0:NUM_CYCLES-1];
  integer i;

  // === DUT: One-bit predictor used here ===
  two_bit_branch_predictor #(.INDEX_WIDTH(INDEX_WIDTH)) predictor (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .pc_index(pc_index),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // === Clock generation ===
  always #5 clk = ~clk;

  // === Initialize simulation ===
  initial begin
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    total_cycles = 0;
    total_stalls = 0;

    // Example pattern: alternating behavior, loops
    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      if (i % 4 == 3)
        branch_trace[i] = {4'd5, 1'b0};  // not taken
      else
        branch_trace[i] = {4'd5, 1'b1};  // taken
    end

    #10 rst = 0;

    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      @(negedge clk);

      // Feed branch to predictor
      pc_index = branch_trace[i][INDEX_WIDTH:1];
      actual_taken = branch_trace[i][0];

      predict_request = 1;
      @(negedge clk);
      predict_request = 0;

      // Check prediction result
      update_enable = 1;
      if (predicted_taken !== actual_taken) begin
        total_stalls = total_stalls + STALL_PENALTY;
      end

      @(negedge clk);
      update_enable = 0;

      total_cycles = total_cycles + 1;
    end

    // === Final Results ===
    $display("\n=== Stall Simulation Results ===");
    $display("Total Instructions     : %0d", NUM_CYCLES);
    $display("Total Cycles           : %0d", total_cycles + total_stalls);
    $display("Total Stalls (cycles)  : %0d", total_stalls);
    $display("Average CPI            : %0.2f", (1.0 * (total_cycles + total_stalls)) / NUM_CYCLES);
    $finish;
  end

endmodule
