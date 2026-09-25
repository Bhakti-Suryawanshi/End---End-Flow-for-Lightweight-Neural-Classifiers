# ============================================================
# perceptron_constraints.sdc
# Timing constraint for Quartus TimeQuest Timing Analyzer.
# 50 MHz is the DE1-SoC onboard oscillator frequency - a realistic,
# standard target even though no board is actually used here.
# Adjust -period to try other clock targets when exploring Fmax.
# ============================================================
create_clock -name clk -period 20.000 [get_ports {clk}]
derive_clock_uncertainty
