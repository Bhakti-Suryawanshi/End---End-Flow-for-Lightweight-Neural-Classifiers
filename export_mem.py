"""
Step 3: Export the quantized weights, bias, test inputs and expected
outputs as .mem hex files that Verilog's $readmemh() can load directly.
These 4 files are the bridge between the Python side and the RTL side.
"""
import numpy as np

Wq = np.load("Wq.npy")           # (10,64) int, range [-128,127]
bq = np.load("bq.npy")           # (10,)   int, range fits int16
Xq = np.load("Xq.npy")           # (N,64)  int, range [0,16]
y_test = np.load("y_test.npy")
golden_preds = np.load("golden_preds.npy")

NUM_TESTS = 50   # keep the testbench run fast; raise this for a fuller sweep

def to_hex_2c(val, nbits):
    """two's-complement hex string, no '0x' prefix, sized to nbits (multiple of 4)"""
    nhex = nbits // 4
    uval = val & ((1 << nbits) - 1)
    return f"{uval:0{nhex}x}"

OUT = "../rtl"   # write straight into the rtl/ folder -> readmemh finds them next to the .v files
import os
os.makedirs(OUT, exist_ok=True)

# ---- weights.mem : 10*64 = 640 lines, 8-bit signed, class-major order (class0's 64 weights, then class1's, ...) ----
with open(f"{OUT}/weights.mem", "w") as f:
    for c in range(10):
        for i in range(64):
            f.write(to_hex_2c(int(Wq[c, i]), 8) + "\n")

# ---- bias.mem : 10 lines, 16-bit signed ----
with open(f"{OUT}/bias.mem", "w") as f:
    for c in range(10):
        f.write(to_hex_2c(int(bq[c]), 16) + "\n")

# ---- test_inputs.mem : NUM_TESTS*64 lines, 8-bit unsigned (values 0..16) ----
with open(f"{OUT}/test_inputs.mem", "w") as f:
    for n in range(NUM_TESTS):
        for i in range(64):
            f.write(to_hex_2c(int(Xq[n, i]), 8) + "\n")

# ---- expected_outputs.mem : NUM_TESTS lines, 4-bit class label (what the golden model predicts) ----
with open(f"{OUT}/expected_outputs.mem", "w") as f:
    for n in range(NUM_TESTS):
        f.write(to_hex_2c(int(golden_preds[n]), 4) + "\n")

match = (golden_preds[:NUM_TESTS] == y_test[:NUM_TESTS]).mean()
print(f"[export_mem.py] Wrote weights.mem, bias.mem, test_inputs.mem, expected_outputs.mem to {OUT}/")
print(f"[export_mem.py] First {NUM_TESTS} test samples -> golden model accuracy vs true labels = {match*100:.2f}%")
