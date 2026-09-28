import random

NUM_TESTS = 10000
OUTPUT_FILE = "verification/vectors.txt"

random.seed(20260923)

#for random normal FP64 num. 1st is sign bit. Last 52 are fractional part taken randomly. Exponenet part me we avoid 0/2047(inf) because inf toh kyu hi chahiye.
#Exponent 0 pe significant bit is not 1.
def random_normal():

    sign = random.randint(0, 1)
    # 1 to 2046 =FP64 exponent
    exponent = random.randint(1, 2046)
    # 52-bit fraction
    fraction = random.getrandbits(52)

    return (
        (sign << 63)
        | (exponent << 52)
        | fraction
    )

#Vector generation
with open(OUTPUT_FILE, "w") as f:

    for _ in range(NUM_TESTS):

        a = random_normal()
        b = random_normal()
        # 0 pe add,1 pe sub,2 pe mult,3 pe division
        op = random.randint(0, 3)
        f.write(
            f"{a:016X} {b:016X} {op}\n"
        )

print(f"Generated {NUM_TESTS} random FP64 test vectors.")
print(f"Output: {OUTPUT_FILE}")
