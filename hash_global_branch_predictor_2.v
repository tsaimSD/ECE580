// ==============================
// File: complex_hashed_global_branch_predictor.v
// ==============================

module complex_hashed_global_branch_predictor #(
    parameter GHR_WIDTH = 8,
    parameter ROUNDS = 4
)(
    input  wire              clk,
    input  wire              rst,
    input  wire              predict_request,
    output reg               predicted_taken,
    input  wire              update_enable,
    input  wire              actual_taken
);

    // === Global History Register ===
    reg [GHR_WIDTH-1:0] ghr;

    // === Pattern History Table ===
    reg [1:0] pht [0:(1 << GHR_WIDTH)-1];

    // === Hashed index ===
    wire [GHR_WIDTH-1:0] index;

    complex_ghr_hasher #(
        .GHR_WIDTH(GHR_WIDTH),
        .ROUNDS(ROUNDS)
    ) hasher_inst (
        .ghr(ghr),
        .hashed_index(index)
    );

    // === Prediction ===
    always @(*) begin
        if (predict_request)
            predicted_taken = (pht[index] >= 2);
        else
            predicted_taken = 0;
    end

    // === Update logic ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ghr <= 0;
            for (i = 0; i < (1 << GHR_WIDTH); i = i + 1)
                pht[i] <= 2'b10; // weakly taken
        end else if (update_enable) begin
            if (actual_taken && pht[index] < 3)
                pht[index] <= pht[index] + 1;
            else if (!actual_taken && pht[index] > 0)
                pht[index] <= pht[index] - 1;

            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end

endmodule