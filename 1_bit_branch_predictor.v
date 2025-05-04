module one_bit_branch_predictor #(
    parameter INDEX_WIDTH = 6  // PC index width ⇒ 2^6 = 64-entry predictor
)(
    input  wire                   clk,
    input  wire                   rst,

    // Prediction interface
    input  wire                   predict_request,
    input  wire [INDEX_WIDTH-1:0] pc_index,
    output reg                    predicted_taken,

    // Update interface
    input  wire                   update_enable,
    input  wire                   actual_taken
);

    // === Local Prediction Table (1-bit entries) ===
    reg prediction_bit [0:(1 << INDEX_WIDTH) - 1];

    // === Prediction ===
    always @(*) begin
        if (predict_request)
            predicted_taken = prediction_bit[pc_index];
        else
            predicted_taken = 1'b0;
    end

    // === Update ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < (1 << INDEX_WIDTH); i = i + 1)
                prediction_bit[i] <= 1'b1;  // Start as "taken"
        end else if (update_enable) begin
            prediction_bit[pc_index] <= actual_taken;
        end
    end

endmodule
