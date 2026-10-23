`timescale 1ns / 1ps

module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    // Device under test
    mult_array uut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // 10 ns clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    integer i, j;
    integer errors;
    integer checked;
    reg [7:0] expected;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        // Hold reset low for the first 2 clock cycles
        rst_n   = 1'b0;
        a       = 4'd0;
        b       = 4'd0;
        errors  = 0;
        checked = 0;

        @(posedge clk);
        @(posedge clk);
        #1 rst_n = 1'b1;

        // Try every combination of a and b
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i[3:0];
                b = j[3:0];
                expected = a * b;

                // The product is available after 2 clock edges.
                // The extra delay lets gate-level simulation settle.
                @(posedge clk);
                @(posedge clk);
                #2;

                checked = checked + 1;
                if (p !== expected) begin
                    $display("MISMATCH: a = %0d, b = %0d | expected p = %0d (0x%02h), got p = %0d (0x%02h)",
                             a, b, expected, expected, p, p);
                    errors = errors + 1;
                end
            end
        end

        // Summary
        if (errors == 0) begin
            $display("PASS: %0d vectors checked, 0 errors", checked);
        end else begin
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);
        end

        #10;
        $finish;
    end

endmodule
