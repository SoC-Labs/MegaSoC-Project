#!/usr/bin/env python3
"""Summarise a debug_uart_probe capture, whole-bus format.
Usage: haps_parse_logger.py [--map 42|43|44] <logger.log>      (default map 44)
  --map 42 : bitstreams build 41/42 (haps_top_build42_sramfix_20261010.bit and earlier build 41)
  --map 43 : build 43 (caches-off diagnostic ROM; bits 10/12 raw outstanding levels)
  --map 44 : build 44 and later (bits 10/12 = outstanding > 1.6 ms)
Line format: T<8 hex cycle>:<8 hex bus><'=' | '!'>   ('!' = changes dropped/delayed since previous line)
Boot cycles are delimited by nreset_soc (bit 15) going 0 -> 1.
Value field bits 31:16:
  map 43: sampled every 50 ms from the LAST CPU AXI address accepted (AR or AW): {region[2:0], addr[14:2]}
          region 0/1 ROM (addr bit 15 = region bit 0), 2 SRAM, 3 QSPI flash window, 4 QSPI regs,
          5 peripherals, 7 >= 0x8000_0000.
  map 42: {ARPROT[2], ARADDR[16:2]}: first 50 ms = instruction fetch before the first EL3 vector-table
          fetch (the faulting fetch line); afterwards the next CPU AR handshake every 50 ms (I/D + address).
"""
import re, sys

MAPS = {
    43: {  # build 43 (haps_top.sv, 2026-10-12)
        0: "ARVALID", 1: "RVALID", 2: "ROMdata", 3: "SRAMwr", 4: "SRAMboot",
        5: "FLASH", 6: "UARTreg", 7: "UARTtx",
        8: "POR_n", 9: "WFE", 10: "WRpend", 11: "WFI", 12: "RDpend", 13: "VECTOR",
        14: "QSPIapb", 15: "nreset_soc",
    },
    44: {  # build 44 (haps_top.sv, 2026-10-13): bits 10/12 are now "stuck" (outstanding > 1.6 ms)
        0: "ARVALID", 1: "RVALID", 2: "ROMdata", 3: "SRAMwr", 4: "SRAMboot",
        5: "FLASH", 6: "UARTreg", 7: "UARTtx",
        8: "POR_n", 9: "WFE", 10: "WRstuck", 11: "WFI", 12: "RDstuck", 13: "VECTOR",
        14: "QSPIapb", 15: "nreset_soc",
    },
    42: {  # build 41/42 (haps_top.sv, 2026-10-08)
        0: "ARVALID", 1: "RVALID", 2: "ROMdata", 3: "SRAMwr", 4: "SRAMboot",
        5: "FLASH", 6: "UARTreg", 7: "UARTtx",
        8: "POR_n", 9: "ROM_RSTn", 10: "L2_RSTn", 11: "WFI", 12: "FETCHfar", 13: "VECTOR",
        14: "CORE_WRMRSTn", 15: "nreset_soc",
    },
}
MAP = 44
BITS = MAPS[MAP]
MILESTONES = [0, 1, 2, 3, 4, 5, 6, 7]
LEVELS = [8, 11, 9, 13, 14, 12, 10]
LINE = re.compile(r"^T([0-9A-F]{8}):([0-9A-F]{8})([=!])\s*$")
CLK_MHZ = 20.0

REGION = {0: "ROM", 1: "ROM", 2: "SRAM", 3: "FLASH", 4: "QSPIREG", 5: "PERIPH", 6: "?6", 7: "HI"}

def dec_val(v):
    """map 43: {region[2:0], addr[14:2]} -> region + offset; map 42: {ARPROT[2], ARADDR[16:2]} -> I/D:addr"""
    if v == 0:
        return "-"
    if MAP == 42:
        return f"{'I' if v & 0x8000 else 'D'}:0x{(v & 0x7FFF) << 2:05X}"
    r = v >> 13
    off = ((v & 0x1FFF) << 2) | (0x8000 if r == 1 else 0)
    return f"{REGION[r]}+0x{off:04X}"

def main(path):
    ev, bad = [], 0
    for raw in open(path, "r", errors="replace"):
        m = LINE.match(raw.strip())
        if m:
            ev.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3) == "!"))
        elif raw.strip():
            bad += 1
    print(f"lines: {len(ev)} well-formed, {bad} garbled, {sum(d for _, _, d in ev)} flagged '!' (dropped/delayed)")
    if bad > 5 and bad > len(ev) * 0.02:
        print("WARNING: many garbled lines - second reader on the port? wrong baud / clock?")
    if not ev:
        return
    # split into boot cycles on nreset_soc rising
    cycles, cur, prev = [], [], None
    for cy, bus, d in ev:
        rst = (bus >> 15) & 1
        if prev is not None and rst == 1 and prev == 0 and cur:
            cycles.append(cur); cur = []
        cur.append((cy, bus, d)); prev = rst
    cycles.append(cur)
    print(f"boot cycles (nreset_soc rising): {len(cycles)}   bus changes per cycle: "
          + ", ".join(str(len(c)) for c in cycles))
    arv = 0
    for n, cyc in enumerate(cycles, 1):
        # t0 = reset release within this cycle (first line with nreset_soc=1), else first line
        t0 = next((cy for cy, bus, _ in cyc if (bus >> 15) & 1), cyc[0][0])
        def first_high(b):
            return next((cy for cy, bus, _ in cyc if cy >= t0 and (bus >> b) & 1), None)
        def ever(b):
            return any((bus >> b) & 1 for cy, bus, _ in cyc if cy >= t0)
        def t(b):
            x = first_high(b)
            return "-" if x is None else f"{(x - t0) / CLK_MHZ:.0f}us"
        arv += ever(0)
        ms = " ".join(f"{BITS[b]}={int(ever(b))}@{t(b)}" for b in MILESTONES)
        lv = " ".join(f"{BITS[b]}={int(ever(b))}" for b in LEVELS)
        final = cyc[-1][1]
        vals = []
        for cy, bus, _ in cyc:
            v = bus >> 16
            if v and (not vals or vals[-1][1] != v):
                vals.append((cy, v))
        from collections import Counter
        fc = Counter(dec_val(v) for cy, v in vals if (cy - t0) >= 40 * 1000 * CLK_MHZ)
        fetch = [f"{k} x{c}" for k, c in fc.most_common()]
        print(f"  cycle {n:2d} ({len(cyc):3d} ch, final bus {final & 0xFFFF:04X}): {ms} | {lv}"
              f"{' | DROPS' if any(d for _, _, d in cyc) else ''}")
        if MAP == 42:
            print(f"             reads sampled every 50 ms (I/D:addr): {', '.join(fetch) if fetch else '-'}   [val=- => no CPU read after the first 50 ms]")
        else:
            print(f"             last CPU access (sampled every 50 ms): {', '.join(fetch) if fetch else '-'}   [bit10/12 set => CPU write/read waiting on the bus]")
    print(f"ARVALID asserted in {arv}/{len(cycles)} cycles")
    # per-boot timeline of the first complete cycle, for the record
    full = next((c for c in cycles[1:] if len(c) > 2), None)
    if full:
        t0 = next((cy for cy, bus, _ in full if (bus >> 15) & 1), full[0][0])
        print("timeline of one boot (us after nreset_soc release, bus bits that are 1):")
        for cy, bus, d in full[:40]:
            on = [BITS[b] for b in range(16) if (bus >> b) & 1]
            print(f"   {(cy - t0) / CLK_MHZ:+10.1f}us  {bus & 0xFFFF:04X}{'!' if d else ' '}  val={dec_val(bus >> 16):<14} {' '.join(on)}")

if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) >= 2 and args[0] == "--map":
        MAP = int(args[1]); BITS = MAPS[MAP]; args = args[2:]
    if len(args) != 1:
        sys.exit(__doc__)
    print(f"bus map: build {MAP}")
    main(args[0])
