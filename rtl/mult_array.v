// 4-bit x 4-bit Unsigned Array Multiplier with Registered Inputs and Output
// Latency: 2 clock cycles (16 flip-flops total: 4 for a, 4 for b, 8 for p)
module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    // -------------------------------------------------------------------------
    // 1. Input Registers (8 Flip-Flops)
    // -------------------------------------------------------------------------
    reg [3:0] a_reg;
    reg [3:0] b_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // -------------------------------------------------------------------------
    // 2. Partial Products: 16 AND gates (pp_i[j] = a_reg[j] & b_reg[i])
    // -------------------------------------------------------------------------
    wire [3:0] pp0 = a_reg & {4{b_reg[0]}};
    wire [3:0] pp1 = a_reg & {4{b_reg[1]}};
    wire [3:0] pp2 = a_reg & {4{b_reg[2]}};
    wire [3:0] pp3 = a_reg & {4{b_reg[3]}};

    // -------------------------------------------------------------------------
    // 3. Array Structure (Row 0 to Row 3)
    // -------------------------------------------------------------------------
    wire [7:0] prod_comb;

    // Row 0: no adders
    assign prod_comb[0] = pp0[0];
    wire [3:0] r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    // Row 1: 4 full adders
    wire [3:0] s1;
    wire [4:0] c1;
    assign c1[0] = 1'b0;

    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : row1_fa
            full_adder fa (
                .a    (pp1[j]),
                .b    (r0[j]),
                .cin  (c1[j]),
                .sum  (s1[j]),
                .cout (c1[j+1])
            );
        end
    endgenerate

    assign prod_comb[1] = s1[0];
    wire [3:0] r1 = {c1[4], s1[3], s1[2], s1[1]};

    // Row 2: 4 full adders
    wire [3:0] s2;
    wire [4:0] c2;
    assign c2[0] = 1'b0;

    generate
        for (j = 0; j < 4; j = j + 1) begin : row2_fa
            full_adder fa (
                .a    (pp2[j]),
                .b    (r1[j]),
                .cin  (c2[j]),
                .sum  (s2[j]),
                .cout (c2[j+1])
            );
        end
    endgenerate

    assign prod_comb[2] = s2[0];
    wire [3:0] r2 = {c2[4], s2[3], s2[2], s2[1]};

    // Row 3: 4 full adders
    wire [3:0] s3;
    wire [4:0] c3;
    assign c3[0] = 1'b0;

    generate
        for (j = 0; j < 4; j = j + 1) begin : row3_fa
            full_adder fa (
                .a    (pp3[j]),
                .b    (r2[j]),
                .cin  (c3[j]),
                .sum  (s3[j]),
                .cout (c3[j+1])
            );
        end
    endgenerate

    assign prod_comb[3]   = s3[0];
    assign prod_comb[7:4] = {c3[4], s3[3], s3[2], s3[1]};

    // -------------------------------------------------------------------------
    // 4. Output Register (8 Flip-Flops)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 8'b00000000;
        end else begin
            p <= prod_comb;
        end
    end

endmodule
