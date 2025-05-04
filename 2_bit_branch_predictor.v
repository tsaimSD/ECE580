module two_bit_branch_predictor #(
    parameter INDEX_WIDTH = 6  // Number of PC index bits → 2^6 = 64-entry table
)(
    input  wire                   clk,
    input  wire                   rst,

    // Prediction interface
    input  wire                   predict_request,
    input  wire [INDEX_WIDTH-1:0] pc_index,         // Lower bits of PC
    output reg                    predicted_taken,  // 1 if predicted taken

    // Update interface
    input  wire                   update_enable,
    input  wire                   actual_taken      // Actual result of resolved branch
);

    // === Local Prediction Table (2-bit counters) ===
    reg [1:0] pht [0:(1 << INDEX_WIDTH) - 1];  // Pattern History Table

    // === Prediction logic ===
    always @(*) begin
        if (predict_request)
            predicted_taken = (pht[pc_index] >= 2);  // Taken if counter ≥ 2
        else
            predicted_taken = 1'b0;
    end

    // === Update logic ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < (1 << INDEX_WIDTH); i = i + 1)
                pht[i] <= 2'b10; // Weakly taken by default
        end else if (update_enable) begin
            case (actual_taken)
                1'b1: if (pht[pc_index] < 2'b11) pht[pc_index] <= pht[pc_index] + 1;
                1'b0: if (pht[pc_index] > 2'b00) pht[pc_index] <= pht[pc_index] - 1;
            endcase
        end
    end

endmodule
