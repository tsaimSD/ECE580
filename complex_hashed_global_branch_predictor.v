module hashed_global_branch_predictor #(
    parameter GHR_WIDTH = 8,
    parameter ROUNDS = 4
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

    // === Pattern History Table (2-bit saturating counters) ===
    reg [1:0] pht [0:(1 << GHR_WIDTH)-1];

    // === Hashed index from GHR ===
    wire [GHR_WIDTH-1:0] index;

    // === Instantiate complex hash logic ===
    complex_ghr_hasher #(
        .GHR_WIDTH(GHR_WIDTH),
        .ROUNDS(ROUNDS)
    ) hasher (
        .ghr(ghr),
        .hashed_index(index)
    );

    // === Prediction Logic ===
    always @(*) begin
        if (predict_request)
            predicted_taken = (pht[index] >= 2);  // 2 or 3 = taken
        else
            predicted_taken = 1'b0;
    end

    // === Update Logic ===
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ghr <= 0;
            for (i = 0; i < (1 << GHR_WIDTH); i = i + 1)
                pht[i] <= 2'b10; // weakly taken
        end else if (update_enable) begin
            // Update the saturating counter
            if (actual_taken && pht[index] < 2'b11)
                pht[index] <= pht[index] + 1;
            else if (!actual_taken && pht[index] > 2'b00)
                pht[index] <= pht[index] - 1;

            // Update the GHR
            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end

endmodule

module complex_ghr_hasher #(
    parameter GHR_WIDTH = 8,
    parameter ROUNDS = 4
)(
    input  wire [GHR_WIDTH-1:0] ghr,
    output reg  [GHR_WIDTH-1:0] hashed_index
);

    integer i;
    reg [GHR_WIDTH-1:0] hash_val;

    always @(*) begin
        hash_val = ghr;
        for (i = 0; i < ROUNDS; i = i + 1) begin
            // Shift & XOR mixing
            hash_val = {hash_val[GHR_WIDTH-2:0], hash_val[GHR_WIDTH-1]} ^
                       ((hash_val << 3) | (hash_val >> (GHR_WIDTH - 3)));
        end
        hashed_index = hash_val;
    end

endmodule
