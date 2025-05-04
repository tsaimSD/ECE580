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
        for (i = 0; i < ROUNDS; i = i + 1)
            hash_val = {hash_val[GHR_WIDTH-2:0], hash_val[GHR_WIDTH-1]} ^
                       ((hash_val << 3) | (hash_val >> (GHR_WIDTH - 3)));
        hashed_index = hash_val;
    end

endmodule