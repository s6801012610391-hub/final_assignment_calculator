# Calculator DE10-Lite — VHDL Full Project

**Platform:** Terasic DE10-Lite, Intel MAX 10 `10M50DAF484C7G`, 50 MHz clock.  
**Based on:** [final_assignment_calculator](https://github.com/s6801012610391-hub/final_assignment_calculator) — five original arithmetic modules (see `original_github/`).  
**Assignment:** `docs/assignment_reference.pdf` (provided by the student).  
**Status:** Integrated RTL and Quartus pin/project files are prepared, testbenches supplied; **not actually compiled or simulated with Quartus/GHDL in this environment**. Run the tests and synthesize before using on hardware.

## 1. How to open in Quartus

1. Extract the ZIP to a normal folder (prefer an ASCII-only folder path on Windows).
2. Open **Quartus Prime Lite** and select `Calculator_DE10_Lite.qpf` under **File > Open Project**.
3. Check the device is `10M50DAF484C7G`, top-level entity is `Calculator_DE10_Lite`.
4. Use **Processing > Start Compilation**. Inspect any errors, warnings, resource utilization, and timing report. The `.sdc` file declares 50 MHz.
5. Connect the DE10-Lite via USB Blaster and program the generated `output_files/Calculator_DE10_Lite.sof` from **Tools > Programmer** (the `.sof` is **not prebuilt** in the ZIP).
6. Reset with **KEY0** (active-low). **KEY1** advances a stage **when released**, once for each complete press-release.

### Physical signal mapping

| Board | Purpose |
|---|---|
| CLOCK_50 | 50 MHz input |
| KEY0 | asynchronous active-low reset |
| KEY1 | debounced press-release START |
| SW9..SW0 | signed 10-bit input (A then B), two's complement [-512, 511] |
| SW1..SW0 | 2-bit operation when selecting function |
| HEX5..HEX0 | active-low 7-segment, complete pin mapping incl. decimal points |
| LEDR0 | DONE, active-high |
| LEDR9..LEDR1 | unused / off |

**Important:** SW1..SW0 are reused for BOTH the numeric input and OP selection. After saving A, change SW1/SW0 to choose the operation; after saving OP, change all switches to set B.

## 2. Operation codes

| SW1 SW0 | Function | Module |
|---|---|---|
| `11` | A+B | `AdderSubtractor10`, M=0 |
| `10` | A−B | `AdderSubtractor10`, M=1 |
| `01` | A×B | `Multiplier10` (shift & add) |
| `00` | A÷B | `Divider10` (shift-right divisor) |

Both sequential arithmetic cores were already present in the public repository. The controller triggers either module with one clock of `START`, then observes `MUL_DONE` / `DIV_DONE`.

## 3. Human interaction: six KEY1 releases

| Stage | HEX display | KEY1 RELEASE action |
|---|---|---|
| S0 IDLE | `SELECT` (approximated on 7-seg) | S1 live input A |
| S1 SHOW_A | Signed SW[9:0] in decimal | save A, next S2 |
| S2 SELECT_OP | `OP` prompt | S3 function preview |
| S3 SHOW_OP | two symbols `++`, `--`, `xx` or `dd` | save OP, next S4 |
| S4 PROMPT_B | `InP b` | S5 live input B |
| S5 SHOW_B | Signed SW[9:0] in decimal | save B, S6 CALC |
| S6 START_CALC | `------` | ADD/SUB immediate result; trigger MUL or DIV once |
| S7 WAIT_CALC | `------` | wait for MUL_DONE or DIV_DONE |
| S8 RESULT | result | DONE=1; KEY1 ignored; KEY0 resets |
| S9 ERROR | `FFFFFF` | DONE=1; KEY1 ignored; KEY0 resets |

This behavior follows the assignment's staged prompts and latching, not the shorter 6/7-state simplified illustration. See `docs/state_diagram.svg` and `docs/state_diagram.md`.

## 4. 7-segment output conventions

The DE10-Lite display is **active-low**; bits 0..6 correspond to **a,b,c,d,e,f,g** and bit 7 is **decimal point**. Do not reverse HEX digit order: HEX0 is the rightmost display.

| Result type | HEX5 | HEX4 | HEX3 | HEX2 | HEX1 | HEX0 |
|---|---|---|---|---|---|---|
| ADD/SUB/MUL positive | operation symbol | up to 5 decimal magnitude digits across HEX4..HEX0 | | | | |
| ADD/SUB/MUL negative | operation symbol | `-` | up to 4 decimal magnitude digits across HEX3..HEX0 | | | |
| DIV | `d` for divide (or `-` for negative quotient) | quotient tens | quotient units | 3 horizontal bars `=` | remainder tens | remainder units |
| Error/too many digits | F | F | F | F | F | F |

**Signs of DIV:** signed arithmetic is calculated fully in hardware. For a negative quotient, HEX5 displays `-` instead of `d`. For a negative remainder, **HEX1 decimal point lights** (an additional custom sign indicator). Remainder digits show absolute value. This is a documented display convention: conventional seven-segment digits cannot simultaneously display division operator, two signed values, and two 2-digit magnitudes with the fixed six-digit layout. This custom indicator is an engineering choice, **not explicitly required by the PDF**.

For non-division, HEX5 shows OP, and HEX4 shows a negative sign only when needed. Positive results up to 99999 and negative results down to -9999 are supported. The maximum product is larger than display capacity: such a result shows FFFFFF.

In DIV layout, quotient and remainder magnitudes must each fit 00..99. A quotient 512, for instance, triggers FFFFFF. Division by zero also triggers FFFFFF. This is another engineering choice: the PDF explicitly calls for FFFFFF for results that do not fit; handling B=0 uses the same ERROR state.

## 5. Project tree

```text
Calculator_DE10_Lite_Project/
├── Calculator_DE10_Lite.qpf      Quartus project
├── Calculator_DE10_Lite.qsf      Original board pin assignments & source list
├── Calculator_DE10_Lite.sdc      50MHz timing constraint
├── rtl/
│   ├── FullAdder.vhd
│   ├── AdderSubtractor10.vhd
│   ├── Magnitude10.vhd
│   ├── Multiplier10.vhd
│   ├── Divider10.vhd
│   ├── ButtonRelease.vhd
│   ├── Calculator_Core.vhd
│   ├── Display6.vhd
│   └── Calculator_DE10_Lite.vhd
├── original_github/              Copies of the five public original modules
├── sim/
│   ├── tb_calculator_core.vhd
│   ├── tb_button_release.vhd
│   ├── tb_display.vhd
│   └── run_ghdl.sh
└── docs/
    ├── state_diagram.svg
    ├── state_diagram.dot
    ├── state_diagram.md
    ├── origin_notes.md
    └── assignment_reference.pdf
```

## 6. Simulation

### GHDL (VHDL-2008)

Install GHDL, then run:

```bash
bash sim/run_ghdl.sh
```

The bash script compiles RTL and runs 3 testbenches. For a Windows installation without bash, run the same commands from ModelSim or use WSL.

### ModelSim / Questa

Create a VHDL-2008 simulation project, compile `rtl/` files in the same order listed in `Calculator_DE10_Lite.qsf`, then compile files in `sim/`. Simulate `tb_calculator_core`, `tb_button_release`, and `tb_display`. In `tb_calculator_core`, watch `state_code`, `pulse`, `sw`, `done`, `value`, `q`, and `r`. `--stop-time` of about `100 us` is sufficient; tests use a 10ns period, so simulation is accelerated compared with actual hardware.

Suggested tests: positive and negative signed addition/subtraction, multiplication, division with remainder, negative quotient/remainder, division by zero, display overflow, reset during a calculation, long-held KEY1, and repeated KEY1 presses after DONE.

## 7. Notes and limits

- `original_github/` files are normalized-format transcriptions from GitHub raw source (same algorithms and interfaces, not byte-for-byte downloads). Sources have not been modified in `rtl/`.
- `AdderSubtractor10.V` is not relied upon for display overflow; 11-bit `S` is sufficient for 10-bit signed addition/subtraction.
- 50 MHz clock; debouncer is **20ms per stable press/release** using `DEBOUNCE_CYCLES=1000000`. In simulation the generic may be reduced.
- Quartus/GHDL were unavailable when this archive was prepared. **No successful compile, synthesis or hardware test is claimed.** Verify with the supplied testbenches and Quartus before grading.
- For a waveform demonstrating timing, run simulation and export the waveform in ModelSim; the archive provides testbench sources but no fabricated `.vwf` or simulation screenshots.

Board pin mappings were cross-checked against a publicly listed [DE10-Lite pin assignment reference](https://gist.github.com/unaimillan/ae4ba3d418200ddb24e983be502bc402).
