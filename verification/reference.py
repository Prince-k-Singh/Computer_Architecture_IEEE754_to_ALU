import struct
import math


VECTORS_FILE = "verification/vectors.txt"
RESULTS_FILE = "verification/results.txt"


# ============================================================
# IEEE-754 conversions
# ============================================================

def bits_to_float(bits):
    return struct.unpack(
        ">d",
        struct.pack(">Q", bits)
    )[0]


def float_to_bits(value):
    return struct.unpack(
        ">Q",
        struct.pack(">d", value)
    )[0]


# ============================================================
# IEEE-754 classification
# ============================================================

def is_nan(bits):

    exponent = (bits >> 52) & 0x7FF
    fraction = bits & ((1 << 52) - 1)

    return exponent == 0x7FF and fraction != 0


# ============================================================
# Reference operation
# ============================================================

def reference(a_bits, b_bits, op):

    a = bits_to_float(a_bits)
    b = bits_to_float(b_bits)

    # --------------------------------------------------------
    # ADD
    # --------------------------------------------------------

    if op == 0:

        result = a + b


    # --------------------------------------------------------
    # SUB
    # --------------------------------------------------------

    elif op == 1:

        result = a - b


    # --------------------------------------------------------
    # MUL
    # --------------------------------------------------------

    elif op == 2:

        result = a * b


    # --------------------------------------------------------
    # DIV
    # --------------------------------------------------------

    elif op == 3:

        if b == 0.0:

            if a == 0.0:
                result = float("nan")

            else:

                sign_a = math.copysign(1.0, a)
                sign_b = math.copysign(1.0, b)

                if sign_a == sign_b:
                    result = float("inf")
                else:
                    result = float("-inf")

        else:

            result = a / b


    else:

        raise ValueError("Invalid operation")


    return float_to_bits(result)


# ============================================================
# Compare
# ============================================================

def compare(actual, expected):

    # NaN payloads are not required to match.
    # If both are NaN, consider it correct.
    if is_nan(expected):

        return is_nan(actual)

    return actual == expected


# ============================================================
# Main verification
# ============================================================

with open(VECTORS_FILE, "r") as vf:
    vectors = vf.readlines()


with open(RESULTS_FILE, "r") as rf:
    results = rf.readlines()


if len(vectors) != len(results):

    print("ERROR: Number of vectors and results differ.")
    print(f"Vectors = {len(vectors)}")
    print(f"Results = {len(results)}")

    raise SystemExit(1)


total = 0
passed = 0
failed = 0
op_total = [0, 0, 0, 0]
op_failed = [0, 0, 0, 0]

first_failures = []

print()
print("=============================================")
print("PYTHON REFERENCE VERIFICATION")
print("=============================================")


for index, (vector_line, result_line) in enumerate(
    zip(vectors, results)
):

    a_str, b_str, op_str = vector_line.split()

    a = int(a_str, 16)
    b = int(b_str, 16)
    op = int(op_str)

    actual = int(
        result_line.strip(),
        16
    )

    expected = reference(
        a,
        b,
        op
    )


    total += 1
    op_total[op] += 1

    if compare(actual, expected):

        passed += 1

    else:

        failed += 1
        op_failed[op] += 1

        if len(first_failures) < 20:
            first_failures.append(
                (
                    index,
                    a,
                    b,
                    op,
                    actual,
                    expected
                )
            )

# ============================================================
# Summary
# ============================================================

print()
print("=============================================")
print("VERIFICATION SUMMARY")
print("=============================================")

print(f"TOTAL  = {total}")
print(f"PASSED = {passed}")
print(f"FAILED = {failed}")

print()
print("FAILURES BY OPERATION")
print("---------------------------------------------")
print(f"ADD : {op_failed[0]} / {op_total[0]}")
print(f"SUB : {op_failed[1]} / {op_total[1]}")
print(f"MUL : {op_failed[2]} / {op_total[2]}")
print(f"DIV : {op_failed[3]} / {op_total[3]}")

print()
print("FIRST FAILURES")
print("---------------------------------------------")

for (
    index,
    a,
    b,
    op,
    actual,
    expected
) in first_failures:

    print(
        f"Test={index:5d} "
        f"OP={op} "
        f"A={a:016X} "
        f"B={b:016X} "
        f"DUT={actual:016X} "
        f"EXP={expected:016X}"
    )

print("---------------------------------------------")

if failed == 0:
    print("STATUS = ALL TESTS PASSED")
else:
    print("STATUS = FAILURES DETECTED")

print("=============================================")