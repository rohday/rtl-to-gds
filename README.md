# 4-bit Unsigned Array Multiplier: RTL to GDSII (SkyWater SKY130)

Digital VLSI Design, team assignment. The design is a registered 4 x 4 unsigned array multiplier
(`mult_array`), taken from RTL through synthesis, static timing analysis and place-and-route in the
`sky130_fd_sc_hd` standard-cell library using the open-source flow provided in IIC-OSIC-TOOLS.

## Team

| Member | Roll number |
|--------|-------------|
| Udhav Malpani | 2024112009 |
| Samyak Soni | 2024112004 |

## Repository layout

```
README.md
rtl/      full_adder.v, mult_array.v
tb/       tb_mult.v
synth/    synth.tcl, mult_array_netlist.v (generated), mult_array_stat.rpt (generated)
sta/      sta.tcl, mult_array_timing.rpt (generated)
pnr/      config.json, metrics.json, mult_array.gds
report/   report.pdf
```

All commands below were executed from the repository root unless a `cd` is shown. The tool versions
are those shipped in the IIC-OSIC-TOOLS Docker image; `$PDK_ROOT` points to the SKY130A installation.

## Summary of results

| Stage | Result |
|-------|--------|
| RTL simulation | `PASS: 256 vectors checked, 0 errors` |
| Error injection (`sum = a ^ b`) | `FAIL: 256 vectors checked, 95 errors` |
| Synthesis (Yosys) | 73 cells, 805.773 um^2, 16 flip-flops (49.69 % of area) |
| Gate-level simulation | `PASS: 256 vectors checked, 0 errors` |
| STA (typical corner) | T_min = 2.60 ns, F_max = 384.62 MHz |
| Place and route (LibreLane) | CLOCK_PERIOD = 7.0 ns, 0 DRC errors, 0 LVS errors, worst setup slack +0.335 ns |

The complete discussion, the filled-in tables and the answers to the questions of Section 10 of the
assignment are given in `report/report.pdf`.

## Commands, in the order executed

### 1. Environment check

```bash
iverilog -V | head -1
yosys -V
sta -version
sak-pdk sky130A
echo $PDK_ROOT $PDK
```

### 2. Part A: RTL design and verification

```bash
# Exhaustive self-checking simulation of the RTL
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim

# Waveform inspection
gtkwave mult.vcd

# Error-injection test: sum was temporarily changed to "a ^ b" in rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim          # prints FAIL

# The edit was reverted and the testbench was run again
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim          # prints PASS
```

### 3. Part B: logic synthesis

```bash
yosys -c synth/synth.tcl

CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

### 4. Part C: static timing analysis

```bash
# T = 10.0 ns in sta/sta.tcl: worst setup slack 7.404 ns, hence T_min = 10.0 - 7.404 = 2.596 ns
sta sta/sta.tcl

# T set to 2.60 ns in sta/sta.tcl: worst setup slack +0.004 ns
sta sta/sta.tcl
```

### 5. Part D: physical design

The initial clock period follows from 1.2 x T_min = 1.2 x 2.60 ns = 3.12 ns, rounded up to the next
0.5 ns, i.e. 3.5 ns. Each run was started with

```bash
cd pnr
librelane config.json
```

after editing `CLOCK_PERIOD` in `config.json`. LibreLane performs signoff timing at nine
process-voltage-temperature corners. The typical corner (`nom_tt_025C_1v80`) met timing in every run,
whereas the slow corner (`max_ss_100C_1v60`) did not until the period reached 7.0 ns. DRC and LVS
reported zero errors in all eight runs.

| Run | CLOCK_PERIOD (ns) | Setup slack, TT corner (ns) | Setup slack, worst corner `max_ss_100C_1v60` (ns) | Outcome |
|-----|-------------------|-----------------------------|----------------------------------------------------|---------|
| 1 | 3.5 | +0.591 | -2.144 | setup violation (SS) |
| 2 | 4.0 | +1.091 | -1.644 | setup violation (SS) |
| 3 | 4.5 | +1.592 | -1.144 | setup violation (SS) |
| 4 | 5.0 | +2.091 | -0.644 | setup violation (SS) |
| 5 | 5.5 | +2.591 | -0.144 | setup violation (SS) |
| 6 | 6.0 | +2.909 | -0.082 | setup violation (SS) |
| 7 | 6.5 | +3.187 | -0.165 | setup violation (SS) |
| 8 | 7.0 | +3.687 | +0.335 | all corners met |

The final run (`RUN_2026-10-19_23-08-13`) provided the submitted files:

```bash
cp runs/RUN_2026-10-19_23-08-13/final/metrics.json .
cp runs/RUN_2026-10-19_23-08-13/final/gds/mult_array.gds .

# Layout inspection (screenshots in the report)
klayout mult_array.gds
```

The `runs/` directory is not part of the repository because of its size.
