`timescale 1ns/1ps

module testbench;

  // === Configurable Parameters ===
  parameter NUM_INSTRUCTIONS = 50;
  parameter BRANCH_FREQ      = 5;   // Every Nth instruction is a branch
  parameter BRANCH_STALL     = 5;   // Stall cycles per branch (no speculation)

  // === Internal counters ===
  integer total_cycles = 0;
  integer stall_cycles = 0;
  integer total_branches = 0;
  integer i;
  real cpi;

  initial begin
    $display("\n=== Baseline CPI Simulation: No Branch Prediction ===");

    for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
        total_cycles = total_cycles + 1;

      // Every BRANCH_FREQ instructions, simulate a branch
      
        total_branches = total_branches + 1;
        total_cycles = total_cycles + BRANCH_STALL;
        stall_cycles = stall_cycles + BRANCH_STALL;
    end

    // === Results ===
    cpi = total_cycles * 1.0 / NUM_INSTRUCTIONS;

    $display("Total Instructions      : %0d", NUM_INSTRUCTIONS);
    $display("Total Branches          : %0d", total_branches);
    $display("Stall Cycles from Branches : %0d", stall_cycles);
    $display("Total Cycles Executed   : %0d", total_cycles);
    $display("Naive CPI (No Prediction): %0.2f", cpi);
    $finish;
  end

endmodule

