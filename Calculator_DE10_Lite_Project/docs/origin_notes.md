# Source provenance and design changes

Source repository: https://github.com/s6801012610391-hub/final_assignment_calculator
Reviewed on 2026-10-14 (branch main).

The five files in original_github/ are **manual transcriptions with normalized formatting** of the publicly viewed raw source; the algorithms and port lists are preserved. The same copies are compiled from rtl/.

| Existing design | Added integration |
|---|---|
| FullAdder | Base for ripple carry datapaths |
| Magnitude10 | Absolute signed operands inside MUL/DIV |
| AdderSubtractor10 | Immediate 11-bit ADD/SUB result, sign-extended to 20-bit |
| Multiplier10 | Sequential 10-step shift-and-add, one-cycle start pulse + latched DONE |
| Divider10 | Sequential signed divide, checks DIV_BY_ZERO |

New modules:
- ButtonRelease.vhd: synchronizer, debounce, one-clock release pulse
- Calculator_Core.vhd: 10-state FSM, operand and OP latches, result bounds check
- Display6.vhd: 6x seven-segment driver (active-low and DP off), BCD conversion
- Calculator_DE10_Lite.vhd: FPGA top-level for DE10-Lite

The original adder V overflow flag V is **not used** by the integration: signed 11-bit S holds the entire 10-bit operand sum/difference without overflow; display range is checked independently.
