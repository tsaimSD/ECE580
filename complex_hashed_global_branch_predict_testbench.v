`timescale 1ns/1ps

module testbench;

  // === Parameters ===
  parameter GHR_WIDTH     = 4;
  parameter NUM_CYCLES    = 50;
  parameter STALL_PENALTY = 5;

  // === Signals ===
  reg clk, rst;
  reg predict_request, update_enable;
  reg actual_taken;
  wire predicted_taken;

  // === Statistics ===
  integer total_cycles = 0;
  integer total_stalls = 0;
  integer mispredictions = 0;
  integer i;

  real cpi;
  real mispredict_rate;

  // === Branch pattern: T T T N ... repeating every 4 branches ===
  reg actual_taken_trace [0:NUM_CYCLES-1];

  // === Instantiate DUT ===
  hashed_global_branch_predictor #(
    .GHR_WIDTH(GHR_WIDTH)
  ) uut (
    .clk(clk),
    .rst(rst),
    .predict_request(predict_request),
    .predicted_taken(predicted_taken),
    .update_enable(update_enable),
    .actual_taken(actual_taken)
  );

  // === Clock generation ===
  always #5 clk = ~clk;

  // === Testbench procedure ===
  initial begin
    clk = 0;
    rst = 1;
    predict_request = 0;
    update_enable = 0;
    total_cycles = 0;
    total_stalls = 0;
    mispredictions = 0;

    // === Generate T T T N repeating pattern
    for (i = 0; i < NUM_CYCLES; i = i + 1)
      actual_taken_trace[i] = (i % 4 == 3) ? 1'b0 : 1'b1;

    // === Apply reset ===
    #10 rst = 0;

    // === Run simulation
    for (i = 0; i < NUM_CYCLES; i = i + 1) begin
      @(negedge clk);
      predict_request = 1;
      @(negedge clk);
      predict_request = 0;

      actual_taken = actual_taken_trace[i];
      update_enable = 1;

      if (predicted_taken !== actual_taken) begin
        total_stalls = total_stalls + STALL_PENALTY;
        mispredictions = mispredictions + 1;
      end

      @(negedge clk);
      update_enable = 0;
      total_cycles = total_cycles + 1;
    end

    // === Results ===
    cpi = (total_cycles + total_stalls) * 1.0 / NUM_CYCLES;
    mispredict_rate = 100.0 * mispredictions / NUM_CYCLES;

    $display("\n=== Hashed Global Branch Predictor Results ===");
    $display("Total Instructions     : %0d", NUM_CYCLES);
    $display("Mispredictions         : %0d", mispredictions);
    $display("Misprediction Rate     : %0.2f%%", mispredict_rate);
    $display("Total Stall Cycles     : %0d", total_stalls);
    $display("Total Cycles Executed  : %0d", total_cycles + total_stalls);
    $display("CPI                    : %0.2f", cpi);
    $finish;
  end

endmodule
