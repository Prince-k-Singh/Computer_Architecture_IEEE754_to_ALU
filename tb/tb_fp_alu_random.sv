`timescale 1ns/1ps

module tb_fp_alu_random;

    logic [63:0] a;
    logic [63:0] b;
    logic [1:0]  op;

    logic [63:0] result;

    integer vector_file;
    integer result_file;
    integer scan_result;
    integer count;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    fp_alu #(
        .WIDTH(64)
    ) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );


    // ------------------------------------------------------------
    // Simulation
    // ------------------------------------------------------------

    initial begin

        vector_file = $fopen(
            "verification/vectors.txt",
            "r"
        );

        result_file = $fopen(
            "verification/results.txt",
            "w"
        );


        if (vector_file == 0) begin
            $display("ERROR: Could not open vectors.txt");
            $finish;
        end

        if (result_file == 0) begin
            $display("ERROR: Could not open results.txt");
            $finish;
        end


        count = 0;


        // --------------------------------------------------------
        // Process every vector
        // --------------------------------------------------------

        while (!$feof(vector_file)) begin

            scan_result = $fscanf(
                vector_file,
                "%h %h %d\n",
                a,
                b,
                op
            );


            if (scan_result == 3) begin

                #1;

                $fwrite(
                    result_file,
                    "%016h\n",
                    result
                );

                count = count + 1;

            end

        end


        // --------------------------------------------------------
        // Close files
        // --------------------------------------------------------

        $fclose(vector_file);
        $fclose(result_file);


        $display("");
        $display("=============================================");
        $display("RANDOM VECTOR SIMULATION");
        $display("=============================================");
        $display("Vectors processed = %0d", count);
        $display("Results written   = verification/results.txt");
        $display("=============================================");

        $finish;

    end

endmodule