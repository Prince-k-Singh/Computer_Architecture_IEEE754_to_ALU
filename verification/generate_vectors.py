import random

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

NUM_TESTS = 10000
OUTPUT_FILE = "verification/vectors.txt"

random.seed(20260923)


# ------------------------------------------------------------
# Generate random normal FP64 bit pattern
# ------------------------------------------------------------

def random_normal():

    sign = random.randint(0, 1)

    # 1 to 2046 = normal FP64 exponent
    exponent = random.randint(1, 2046)

    # 52-bit fraction
    fraction = random.getrandbits(52)

    return (
        (sign << 63)
        | (exponent << 52)
        | fraction
    )


# ------------------------------------------------------------
# Generate vectors
# ------------------------------------------------------------

with open(OUTPUT_FILE, "w") as f:

    for _ in range(NUM_TESTS):

        a = random_normal()
        b = random_normal()

        # 0 = ADD
        # 1 = SUB
        # 2 = MUL
        # 3 = DIV
        op = random.randint(0, 3)

        f.write(
            f"{a:016X} {b:016X} {op}\n"
        )


print(f"Generated {NUM_TESTS} random FP64 test vectors.")
print(f"Output: {OUTPUT_FILE}")