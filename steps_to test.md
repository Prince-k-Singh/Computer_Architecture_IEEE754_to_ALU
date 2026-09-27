Seperate module testing:

    Addition/Subtraction:       iverilog -g2012 -o sim/fp_add_test rtl/fp_add.sv tb/tb_fp_add.sv && vvp sim/fp_add_test
    multiplication:             iverilog -g2012 -o sim/fp_mul_test rtl/fp_mul.sv tb/tb_fp_mul.sv && vvp sim/fp_mul_test
    Division:                   iverilog -g2012 -o sim/fp_div_test rtl/fp_div.sv tb/tb_fp_div.sv && vvp sim/fp_div_test


All modules together:
        First compile:              iverilog -g2012 \
    -o sim/fp_alu_test \
    rtl/fp_add.sv \
    rtl/fp_mul.sv \
    rtl/fp_div.sv \
    rtl/fp_alu.sv \
    tb/tb_fp_alu.sv


        then test:                  vvp sim/fp_alu_test



***Testing via generating random numbers and operations using python:

        First run:          python3 verification/generate_vectors.py    
        Then run:           iverilog -g2012 \
-o sim/fp_alu_random_test \
rtl/fp_add.sv \
rtl/fp_mul.sv \
rtl/fp_div.sv \
rtl/fp_alu.sv \
tb/tb_fp_alu_random.sv


    At last:                vvp sim/fp_alu_random_test
    Verify using:           python3 verification/reference.py
