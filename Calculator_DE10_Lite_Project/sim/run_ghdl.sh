#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p sim/work
cd sim/work
for f in ../../rtl/{FullAdder,AdderSubtractor10,Magnitude10,Multiplier10,Divider10,ButtonRelease,Calculator_Core,Display6,Calculator_DE10_Lite}.vhd; do
    ghdl -a --std=08 "$f"
done
for TB in tb_calculator_core tb_button_release tb_display; do
    ghdl -a --std=08 "../${TB}.vhd"
    ghdl -e --std=08 "$TB"
    ghdl -r --std=08 "$TB" --assert-level=error --stop-time=100us
 done
