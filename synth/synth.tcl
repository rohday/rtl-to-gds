# Synthesize mult_array to SKY130 cells
set lib "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Read the design
yosys read_verilog rtl/full_adder.v rtl/mult_array.v

# Generic synthesis, flattening the full adders into one module
yosys synth -top mult_array -flatten

# Map flip-flops to library cells
yosys dfflibmap -liberty $lib

# Map logic to library cells
yosys abc -liberty $lib

# Remove unused wires
yosys opt_clean -purge

# Cell and area report
yosys tee -o synth/mult_array_stat.rpt stat -liberty $lib

# Gate-level netlist
yosys write_verilog -noattr synth/mult_array_netlist.v
