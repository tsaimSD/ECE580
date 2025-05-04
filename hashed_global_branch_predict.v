module hashed_global_branch_predictor #(
    parameter GHR_WIDTH = 8,
    parameter HASH_KEY  = 8'b10111010  // Example secret mask
)(
    input  wire              clk,
    input  wire              rst,

    // Prediction interface
    input  wire              predict_request,
    output reg               predicted_taken,

    // Update interface
    input  wire              update_enable,
    input  wire              actual_taken
);

    // === Global History Register ===
    reg [GHR_WIDTH-1:0] ghr;

    // === Pattern History Table with 2-bit counters ===
    reg [1:0] pht [0:(1 << GHR_WIDTH)-1];

    // === Hashed index calculation ===
    wire [GHR_WIDTH-1:0] index;
    assign index = ghr ^ HASH_KEY;  // Simple obfuscation via XOR

    // === Prediction phase ===
    always @(*) begin
        if (predict_request)
            predicted_taken = (pht[index] >= 2);  // taken if counter is 2 or 3
        else
            predicted_taken = 1'b0;
    end

    // === Update phase ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ghr <= 0;
            for (i = 0; i < (1 << GHR_WIDTH); i = i + 1)
                pht[i] <= 2'b10;  // initialize to weakly taken
        end else if (update_enable) begin
            // Update the 2-bit counter
            if (actual_taken) begin
                if (pht[index] < 2'b11)
                    pht[index] <= pht[index] + 1;
            end else begin
                if (pht[index] > 2'b00)
                    pht[index] <= pht[index] - 1;
            end

            // Shift new result into GHR
            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end

endmodule
