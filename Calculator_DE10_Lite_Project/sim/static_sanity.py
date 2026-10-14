#!/usr/bin/env python3
"""Static cross-checks only. NOT a substitute for HDL simulation/synthesis."""
from pathlib import Path
import random, re
root=Path(__file__).resolve().parents[1]
qsf=(root/'Calculator_DE10_Lite.qsf').read_text()
sources=re.findall(r'set_global_assignment -name VHDL_FILE (\S+)',qsf)
assert len(sources)==9 and len(set(sources))==9
assert all((root/f).exists() for f in sources)
assert len(list((root/'original_github').glob('*.vhd')))==5
locations=re.findall(r'set_location_assignment (PIN_\S+) -to (\S+)',qsf)
assert len(locations)==71 and len(set(p for p,n in locations))==len(locations)
assert len(set(n for p,n in locations))==len(locations)
for p,n in locations:
    if '[' in n: assert n.startswith('{') and n.endswith('}')
assert (root/'Calculator_DE10_Lite.qpf').exists()
assert '50 MHz' in (root/'Calculator_DE10_Lite.sdc').read_text()
glyph=(root/'rtl/Display6.vhd').read_text()
for c,hexval in {'0':'C0','1':'F9','2':'A4','3':'B0','6':'82','F':'8E','-':'BF'}.items():
    assert f"when '{c}' => return x\"{hexval}\"" in glyph

def double_dabble(n):
    b=0
    for bitpos in range(19,-1,-1):
        for k in range(6):
            d=(b>>(4*k))&15
            if d>4: b+=(3<<(4*k))
        b=(b<<1)|((n>>bitpos)&1)
        b &= 0xffffff
    return b
for n in list(range(0,1024))+[9999,10000,99999,100000,262144,524287]+[random.randrange(524288) for _ in range(5000)]:
    actual=''.join(str((double_dabble(n)>>(4*k))&15) for k in range(5,-1,-1))
    assert int(actual)==n,(n,actual)
assert 'state <= S9_ERROR' in (root/'rtl/Calculator_Core.vhd').read_text()
print('PASS static project checks (9 VHDL sources, 5 originals, 71 unique pins, BCD test).')
print('NOTE: Hardware compile + VHDL simulation were NOT run (Quartus/GHDL not installed).')
