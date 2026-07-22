`timescale 1ns / 1ps
//------------------------------------------------------------------------
// Self-checking testbench for Approx_8x8_multi_M1
//
// Strategy:
//   1. Directed sanity checks (a handful of hand-picked values, incl.
//      edge cases like 0, max value, and powers of two) so waveforms
//      are easy to eyeball in GTKWave.
//   2. Exhaustive sweep over all 256 x 256 = 65536 input combinations,
//      comparing the approximate product against the exact product,
//      and computing standard approximate-computing accuracy metrics:
//        - Error Rate (ER)   : % of inputs where approx != exact
//        - MRED              : Mean Relative Error Distance
//        - Max absolute error observed
//------------------------------------------------------------------------

module tb_Approx_8x8_multi_M1;

    reg  [7:0]  A, B;
    wire [15:0] P;          // approximate product (DUT output)
    reg  [15:0] exact;      // exact product (golden reference, computed in TB)

    integer i, j;
    integer error_count;
    integer total_count;
    real    abs_err;
    real    rel_err;
    real    sum_rel_err;
    integer max_abs_err;

    // Device under test
    Approx_8x8_multi_M1 DUT (
        .A(A),
        .B(B),
        .P(P)
    );

    // Dump waveforms for GTKWave
    initial begin
        $dumpfile("tb_Approx_8x8_multi_M1.vcd");
        $dumpvars(0, tb_Approx_8x8_multi_M1);
    end

    //--------------------------------------------------------------
    // Task: apply one input pair, wait for combinational settle,
    // compute the exact product, and self-check against the DUT.
    //--------------------------------------------------------------
    task run_case(input [7:0] a_in, input [7:0] b_in);
        begin
            A = a_in;
            B = b_in;
            #5; // allow combinational logic to settle

            exact = a_in * b_in; // golden reference (unsigned mult)
            total_count = total_count + 1;

            if (P !== exact) begin
                error_count = error_count + 1;
                abs_err = (P > exact) ? (P - exact) : (exact - P);
                if (abs_err > max_abs_err)
                    max_abs_err = abs_err;

                // Avoid divide-by-zero when exact result is 0
                if (exact != 0)
                    rel_err = abs_err / exact;
                else
                    rel_err = 0.0;

                sum_rel_err = sum_rel_err + rel_err;
            end
        end
    endtask

    //--------------------------------------------------------------
    // Directed sanity checks — easy to inspect by hand in waveforms
    //--------------------------------------------------------------
    task run_directed_checks;
        begin
            $display("---- Directed sanity checks ----");
            run_case(8'd0,   8'd0);    // 0 x 0
            run_case(8'd0,   8'd255);  // 0 x max
            run_case(8'd1,   8'd1);    // identity
            run_case(8'd255, 8'd255);  // max x max
            run_case(8'd16,  8'd16);   // power-of-two operands
            run_case(8'd170, 8'd85);   // alternating bit patterns (0xAA, 0x55)
            run_case(8'd12,  8'd11);   // small arbitrary values
            $display("Directed checks complete. Errors so far: %0d", error_count);
        end
    endtask

    //--------------------------------------------------------------
    // Main stimulus
    //--------------------------------------------------------------
    initial begin
        error_count  = 0;
        total_count  = 0;
        sum_rel_err  = 0.0;
        max_abs_err  = 0;

        run_directed_checks();

        $display("---- Exhaustive sweep: all 65536 input combinations ----");
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                run_case(i[7:0], j[7:0]);
            end
        end

        $display("==================================================");
        $display("Total test cases   : %0d", total_count);
        $display("Mismatches (errors): %0d", error_count);
        $display("Error Rate (ER)    : %0.4f %%", (error_count * 100.0) / total_count);
        $display("MRED               : %0.6f", sum_rel_err / total_count);
        $display("Max absolute error : %0d", max_abs_err);
        $display("==================================================");

        if (error_count == 0)
            $display("NOTE: Zero mismatches means either the sweep didn't run correctly, or this build is behaving as an exact multiplier — double check DUT instantiation if you expected approximation error.");

        $finish;
    end

endmodule
