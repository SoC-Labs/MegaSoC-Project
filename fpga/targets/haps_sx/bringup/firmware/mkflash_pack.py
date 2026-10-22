#!/usr/bin/env python3
"""Turn a stock SoC Labs flash build (default.scat) into the two files the board needs:
   <test>_flash.bin  - EXEC_ROM region, goes to flash offset 0  (haps_qspi.py load <file> 80080000)
   <test>_sram.bin   - RW data + zeroed ZI of the RWZI region at 0x800000 (haps_qspi.py load <file> 800000)
The simulation testbench preloads RWZI into SRAM; on the board the monitor does it over UART."""
import sys, os, re
bdir, test, out = sys.argv[1], sys.argv[2], sys.argv[3]
hexdir = os.path.join(bdir, "app_flash.v8-a.hex")
def rdhex(name):
    return bytes(int(l, 16) for l in open(os.path.join(hexdir, name)).read().split())
ro = rdhex("EXEC_ROM")
rw = rdhex("RWZI") if os.path.exists(os.path.join(hexdir, "RWZI")) else b""
fl = open(os.path.join(bdir, "function_list.v8-a.txt")).read()
m = re.search(r"Execution Region RWZI \(Base: 0x([0-9a-fA-F]+), Size: 0x([0-9a-fA-F]+)", fl)
rwzi_size = int(m.group(2), 16) if m else len(rw)
sram = rw + bytes(rwzi_size - len(rw))
open(os.path.join(out, f"{test}_flash.bin"), "wb").write(ro)
open(os.path.join(out, f"{test}_sram.bin"), "wb").write(sram)
print(f"{test:18s} flash {len(ro):6d} B  sram {len(sram):5d} B (RW {len(rw)} + ZI {rwzi_size-len(rw)})  entry {ro[3]:02X}{ro[2]:02X}{ro[1]:02X}{ro[0]:02X}")
