package fp_params_pkg;

    // ============================================================
    // IEEE-754 parameter calculations
    // ============================================================

    function automatic integer get_exp_width(input integer width);

        case (width)

            16: get_exp_width = 5;
            32: get_exp_width = 8;
            64: get_exp_width = 11;

            default: get_exp_width = 0;

        endcase

    endfunction


    function automatic integer get_frac_width(input integer width);

        get_frac_width =
            width - get_exp_width(width) - 1;

    endfunction


    function automatic integer get_bias(input integer width);

        case (width)

            16: get_bias = 15;
            32: get_bias = 127;
            64: get_bias = 1023;

            default: get_bias = 0;

        endcase

    endfunction

endpackage