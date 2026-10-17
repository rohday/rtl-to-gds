# Part C: Static Timing Analysis with OpenSTA
set lib "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Clock period T in ns (start at 10.0 ns to find WNS, then update to T_min)
set T 2.60

# Step 1: Read the cell timing library
read_liberty $lib

# Step 2: Read and link the netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# Step 3: Define the clock with period T in ns
create_clock -name clk -period $T [get_ports clk]

# Step 4: Input arrival time (all inputs except clk)
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# Step 5: Output required time
set_output_delay 1.0 -clock clk [all_outputs]

# Step 6: Print the worst setup slack
report_worst_slack -max

# Step 7: Save the critical path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt
