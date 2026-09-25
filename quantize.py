"""
Step 2: Quantize the trained float weights to fixed-point integers,
and build a BIT-EXACT integer-only "golden model". This golden model
is what the Verilog RTL must match, cycle for cycle, sample for sample.
"""
import numpy as np

W = np.load("W_float.npy")     # (10,64) float
b = np.load("b_float.npy")     # (10,) float
X_test = np.load("X_test.npy") # (N,64) float but values are 0..16 ints
y_test = np.load("y_test.npy")

WEIGHT_W = 8   # int8 signed weights  -> range [-128,127]
BIAS_W   = 16  # int16 signed bias
DATA_W   = 8   # pixel stored in a byte, real range 0..16

# ---- Quantize weights: symmetric int8 ----
w_max = np.max(np.abs(W))
scale = 127.0 / w_max
Wq = np.round(W * scale).astype(np.int64)
Wq = np.clip(Wq, -128, 127)

# ---- Quantize bias in the SAME integer domain as (scale * W) ----
bq = np.round(b * scale).astype(np.int64)
assert bq.max() < 2**(BIAS_W-1) and bq.min() >= -2**(BIAS_W-1), "bias overflow, widen BIAS_W"

# ---- Inputs: pixels are already integers 0..16, used as-is ----
Xq = np.round(X_test).astype(np.int64)
assert Xq.min() >= 0 and Xq.max() < 2**DATA_W

# ---- Integer-only "golden model" inference (this is what RTL must reproduce) ----
def golden_predict(x_row):
    # x_row: (64,) ints
    scores = Xq_row_scores(x_row)
    return int(np.argmax(scores))

def Xq_row_scores(x_row):
    # pure integer MAC, no floats anywhere -> mirrors serial MAC hardware exactly
    scores = np.zeros(10, dtype=np.int64)
    for c in range(10):
        acc = 0
        for i in range(64):
            acc += int(Wq[c, i]) * int(x_row[i])
        acc += int(bq[c])
        scores[c] = acc
    return scores

N_check = len(y_test)
preds = np.array([golden_predict(Xq[n]) for n in range(N_check)])
quant_acc = (preds == y_test).mean()
print(f"[quantize.py] Weight scale factor = {scale:.4f}")
print(f"[quantize.py] Wq range = [{Wq.min()}, {Wq.max()}]   bq range = [{bq.min()}, {bq.max()}]")
print(f"[quantize.py] Quantized (int8) golden-model accuracy on {N_check} test samples = {quant_acc*100:.2f}%")

# accumulator range check (using the REAL max pixel value, not the full byte range)
import math
worst = 64 * 127 * int(Xq.max())
print(f"[quantize.py] Worst-case |accumulator| (real data) = {worst} -> needs >= {math.ceil(math.log2(worst))+1} bits signed (using ACC_W=20, plenty of margin)")

np.save("Wq.npy", Wq)
np.save("bq.npy", bq)
np.save("Xq.npy", Xq)
np.save("golden_preds.npy", preds)
print("[quantize.py] Saved Wq.npy, bq.npy, Xq.npy, golden_preds.npy")
