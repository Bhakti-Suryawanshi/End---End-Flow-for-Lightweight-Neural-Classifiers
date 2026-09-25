"""
Step 1: Train a single-layer perceptron (softmax regression) on the
sklearn digits dataset using plain numpy (no black-box library),
so we get full, explicit weight matrices we can quantize ourselves.
"""
import numpy as np
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split

np.random.seed(0)

# ---- Load data ----
digits = load_digits()
X = digits.data.astype(np.float64)     # (1797, 64), pixel values 0-16
y = digits.target.astype(np.int64)     # (1797,), classes 0-9

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=0, stratify=y
)

N_train, D = X_train.shape
C = 10

# ---- One-hot labels ----
Y_train = np.zeros((N_train, C))
Y_train[np.arange(N_train), y_train] = 1.0

# ---- Init weights ----
W = np.zeros((C, D))     # (10, 64)
b = np.zeros(C)          # (10,)

lr = 0.05
epochs = 300

def softmax(z):
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)

for epoch in range(epochs):
    logits = X_train @ W.T + b          # (N,10)
    probs = softmax(logits)
    grad_logits = (probs - Y_train) / N_train
    grad_W = grad_logits.T @ X_train    # (10,64)
    grad_b = grad_logits.sum(axis=0)
    W -= lr * grad_W
    b -= lr * grad_b

# ---- Evaluate float model ----
def predict(X, W, b):
    return np.argmax(X @ W.T + b, axis=1)

train_acc = (predict(X_train, W, b) == y_train).mean()
test_acc = (predict(X_test, W, b) == y_test).mean()
print(f"[train.py] Float model  train acc = {train_acc*100:.2f}%   test acc = {test_acc*100:.2f}%")

np.save("W_float.npy", W)
np.save("b_float.npy", b)
np.save("X_test.npy", X_test)
np.save("y_test.npy", y_test)
print("[train.py] Saved W_float.npy, b_float.npy, X_test.npy, y_test.npy")
