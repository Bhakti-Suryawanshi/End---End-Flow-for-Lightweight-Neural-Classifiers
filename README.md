# End---End-Flow-for-Lightweight-Neural-Classifiers 


## Project Overview

This project presents the implementation of a neural-network-based classifier targeting an Intel Cyclone V FPGA. The project combines Python-based model development and quantization with synthesizable Verilog RTL implementation and FPGA-oriented verification.

The design was functionally verified using ModelSim and synthesized using Intel Quartus Prime.

---

## Objectives

- Develop a neural-network classifier using Python.
- Prepare and quantize the trained model for hardware implementation.
- Implement the classifier using synthesizable Verilog RTL.
- Design a serial input loading interface for hardware-friendly data transfer.
- Verify RTL functionality using ModelSim.
- Synthesize the RTL design using Intel Quartus Prime.
- Evaluate FPGA resource utilization and timing performance.

---

## Tools Used

- Python
- Verilog HDL
- ModelSim
- Intel Quartus Prime 20.1
- Cyclone V FPGA target
- GitHub

---

## System Architecture

```text
Input Data
    |
    v
+----------------------+
| Serial Load Interface|
| load_en              |
| load_addr             |
| load_data             |
+----------+-----------+
           |
           v
+----------------------+
| Input / Pixel Memory |
+----------+-----------+
           |
           v
+----------------------+
| Neural Network       |
| Computation          |
+----------+-----------+
           |
           v
+----------------------+
| FSM Controller       |
+----------+-----------+
           |
           v
+----------------------+
| Best Score /         |
| Class Decision       |
+----------+-----------+
           |
           v
       class_out

RTL Implementation

The classifier was implemented using synthesizable Verilog RTL.

A serial loading interface is used instead of a very wide parallel input interface. The interface uses:

load_en
load_addr
load_data

This reduces external I/O requirements and makes the design more suitable for FPGA implementation.


Functional Verification
The RTL implementation was verified using ModelSim.
# vlog -reportprogress 300 perceptron.v tb_perceptron.v 
# -- Compiling module perceptron
# -- Compiling module tb_perceptron
# 
# Top level modules:
# 	tb_perceptron
# End time: 12:10:14 on Sep 25,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
# vsim tb_perceptron 
# Start time: 12:10:14 on Sep 25,2026
# Loading work.tb_perceptron
# Loading work.perceptron
# =======================================================
#  RESULT: 50 / 50 test vectors matched the golden model
#  Accuracy (RTL vs golden model) = 100.00 %
#  STATUS: ALL TESTS PASSED - RTL is bit-exact with the Python fixed-point model
# =======================================================
# ** Note: $finish    : tb_perceptron.v(104)
#    Time: 369025 ns  Iteration: 1  Instance: /tb_perceptron
# 1
# Break in Module tb_perceptron at tb_perceptron.v line 104
# 0 ps
# 387476250 ps

write format wave -window .main_pane.wave.interior.cs.body.pw.wf {C:/Users/Bhakti Suryawanshi/Downloads/nn_classifier_project/nn_classifier_project/rtl/wave.do}



Quartus Synthesis Results
| Parameter             |                Final Result |
| --------------------- | --------------------------: |
| FPGA                  |      Cyclone V 5CSEMA5F31C6 |
| Logic utilization     | **199 ALMs / 32,070 (<1%)** |
| Registers             |                     **107** |
| Block memory          |                **512 bits** |
| DSP blocks            |             **1 / 87 (1%)** |
| I/O pins              |           **24 / 457 (5%)** |
| Fmax                  |               **97.32 MHz** |
| ModelSim verification |     **50/50 matched, 100%** |





Future Improvements
Optimize fixed-point arithmetic.
Explore pipelined neural-network computation.
Improve parallel processing throughput.
Evaluate power consumption.
Support additional neural-network layers.
Implement hardware acceleration for larger datasets.
