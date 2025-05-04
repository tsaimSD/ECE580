module global_branch_predictor #(
    parameter GHR_WIDTH = 4  // Number of bits in the Global History Register
)(
    input  wire              clk,
    input  wire              rst,

    // Prediction phase
    input  wire              predict_request,   // Assert when making a prediction
    output reg               predicted_taken,   // 1 if predicted taken

    // Update phase
    input  wire              update_enable,     // Assert when updating the predictor
    input  wire              actual_taken       // Actual result of resolved branch
);

    // === Global History Register ===
    reg [GHR_WIDTH-1:0] ghr;

    // === Pattern History Table (PHT) ===
    reg [1:0] pht [0:(1 << GHR_WIDTH) - 1];  // 2-bit saturating counters

    // === Index derived from current GHR state ===
    wire [GHR_WIDTH-1:0] index;
    assign index = ghr;

    // === Prediction Logic ===
    always @(*) begin
        if (predict_request)
            predicted_taken = (pht[index] >= 2); // Counter ≥ 2 → Predict Taken
        else
            predicted_taken = 0;
    end

    // === Update Logic ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ghr <= 0;
            for (i = 0; i < (1 << GHR_WIDTH); i = i + 1)
                pht[i] <= 2'b10; // Initialize to "weakly taken"
        end else if (update_enable) begin
            // Update the 2-bit counter in the PHT
            case (actual_taken)
                1'b1: if (pht[index] < 2'b11) pht[index] <= pht[index] + 1;
                1'b0: if (pht[index] > 2'b00) pht[index] <= pht[index] - 1;
            endcase

            // Update the GHR with the newest outcome
            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end

endmodule
