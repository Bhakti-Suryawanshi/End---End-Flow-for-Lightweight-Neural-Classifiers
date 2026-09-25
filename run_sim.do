# ============================================================
# run_sim.do
# ModelSim script: compile + simulate + show waveform.
# Usage (with this folder as your working dir, so weights.mem/
# bias.mem/test_inputs.mem/expected_outputs.mem are visible):
#     ModelSim transcript >  do run_sim.do
# This keeps ModelSim open with the Wave window populated after
# the run finishes (does NOT close ModelSim).
# ============================================================
vlib work
vlog perceptron.v tb_perceptron.v
vsim tb_perceptron

add wave -radix decimal /tb_perceptron/clk
add wave -radix decimal /tb_perceptron/rst_n
add wave -radix decimal /tb_perceptron/start
add wave -radix decimal /tb_perceptron/done
add wave -radix decimal /tb_perceptron/class_out
add wave -radix decimal /tb_perceptron/dut/state
add wave -radix decimal /tb_perceptron/dut/class_idx
add wave -radix decimal /tb_perceptron/dut/elem_idx
add wave -radix decimal /tb_perceptron/dut/acc
add wave -radix decimal /tb_perceptron/dut/best_score
add wave -radix decimal /tb_perceptron/dut/best_class

run -all
wave zoom full
