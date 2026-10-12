`timescale 1ns / 1ps

module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    // Instantiate the Unit Under Test (UUT)
    mult_array uut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // Generate clock with 10 ns period (5 ns high, 5 ns low)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    integer i, j;
    integer errors;
    integer checked;
    reg [7:0] expected;

    initial begin
        // Write waveform file mult.vcd
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        // Initialize signals and hold rst_n low for the first 2 cycles (20 ns)
        rst_n   = 1'b0;
        a       = 4'd0;
        b       = 4'd0;
        errors  = 0;
        checked = 0;

        // Wait 2 rising clock edges while rst_n is low, then release after edge
        @(posedge clk);
        @(posedge clk);
        #1 rst_n = 1'b1;

        // Apply all 256 input combinations (a = 0...15, b = 0...15)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i[3:0];
                b = j[3:0];
                expected = a * b;

                // Wait for 2-cycle latency:
                // Edge 1 captures a and b into a_reg and b_reg
                @(posedge clk);
                // Edge 2 captures the combinational product into output register p
                @(posedge clk);
                // Wait 2 ns after rising edge to allow gate-level unit delays (#1) to settle
                #2;

                checked = checked + 1;
                if (p !== expected) begin
                    $display("MISMATCH: a = %0d, b = %0d | expected p = %0d (0x%02h), got p = %0d (0x%02h)",
                             a, b, expected, expected, p, p);
                    errors = errors + 1;
                end
            end
        end

        // Print summary line
        if (errors == 0) begin
            $display("PASS: %0d vectors checked, 0 errors", checked);
        end else begin
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);
        end

        #10;
        $finish;
    end

endmodule
