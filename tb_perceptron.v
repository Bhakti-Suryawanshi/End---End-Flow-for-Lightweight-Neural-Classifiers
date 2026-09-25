// =============================================================
// tb_perceptron.v
// Self-checking testbench: loads test_inputs.mem + expected_outputs.mem
// (produced by export_mem.py), drives the DUT for each test image,
// compares the RTL prediction against the Python golden model, and
// prints a final PASS/FAIL summary with accuracy.
// =============================================================
`timescale 1ns/1ps

module tb_perceptron;

    localparam INPUT_DIM   = 64;
    localparam NUM_CLASSES = 10;
    localparam DATA_W      = 8;
    localparam NUM_TESTS   = 50;   // must match NUM_TESTS in export_mem.py

    reg clk;
    reg rst_n;
    reg load_en;
    reg [6:0] load_addr;
    reg [DATA_W-1:0] load_data;
    reg start;
    wire [3:0] class_out;
    wire done;

    perceptron #(
        .INPUT_DIM(INPUT_DIM), .NUM_CLASSES(NUM_CLASSES), .DATA_W(DATA_W)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .load_en(load_en), .load_addr(load_addr), .load_data(load_data),
        .start(start), .class_out(class_out), .done(done)
    );

    // 100MHz functional clock (timing itself is checked later in Quartus, not here)
    always #5 clk = ~clk;

    // ---- test vectors ----
    reg [DATA_W-1:0] test_data [0:NUM_TESTS*INPUT_DIM-1];
    reg [3:0]        expected_data [0:NUM_TESTS-1];

    integer t, i;
    integer pass_count;
    integer fail_list [0:NUM_TESTS-1];
    integer fail_count;

    initial begin
        $readmemh("test_inputs.mem",     test_data);
        $readmemh("expected_outputs.mem", expected_data);

        clk = 0; rst_n = 0; start = 0; load_en = 0; load_addr = 0; load_data = 0;
        pass_count = 0; fail_count = 0;

        @(negedge clk);
        rst_n = 1;      // release reset mid-cycle (away from any posedge)
        @(negedge clk); // one settle cycle

        for (t = 0; t < NUM_TESTS; t = t + 1) begin
            // Serially load this test image, one pixel per clock. Stimulus is
            // changed only at @(negedge clk) - i.e. mid-cycle, a full half
            // period away from the posedge the DUT samples on. This avoids
            // the classic same-edge race where the testbench and the DUT's
            // clocked block are both triggered by the same posedge and their
            // relative execution order is simulator-dependent (undefined by
            // the Verilog LRM) - some simulators may read updated values,
            // others stale ones, if stimulus changes happen AT the posedge
            // itself rather than safely before it.
            for (i = 0; i < INPUT_DIM; i = i + 1) begin
                @(negedge clk);
                load_addr = i[6:0];
                load_data = test_data[t*INPUT_DIM + i];
                load_en   = 1;
            end
            @(negedge clk);
            load_en = 0;

            // pulse start (same negedge-driven pattern)
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;

            // wait for done
            wait (done == 1);

            if (class_out === expected_data[t]) begin
                pass_count = pass_count + 1;
            end else begin
                fail_list[fail_count] = t;
                fail_count = fail_count + 1;
                $display("  [MISMATCH] test %0d : RTL=%0d  expected=%0d", t, class_out, expected_data[t]);
            end

            @(posedge clk); // small gap before next start pulse
        end

        $display("=======================================================");
        $display(" RESULT: %0d / %0d test vectors matched the golden model", pass_count, NUM_TESTS);
        $display(" Accuracy (RTL vs golden model) = %0.2f %%", (pass_count * 100.0) / NUM_TESTS);
        if (fail_count == 0)
            $display(" STATUS: ALL TESTS PASSED - RTL is bit-exact with the Python fixed-point model");
        else
            $display(" STATUS: %0d MISMATCH(ES) FOUND - see list above", fail_count);
        $display("=======================================================");
        $finish;
    end

endmodule
