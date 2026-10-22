#!/usr/bin/env python3
"""Host side of the MegaSoC build-45 QSPI/flash monitor ROM (console UART, 115200 8N1).

  haps_qspi.py [-p /dev/ttyACM0] cmd  "<monitor line>"        one command, print the reply
  haps_qspi.py [-p PORT] cmds "<line1>" "<line2>" ...           several commands in one session
  haps_qspi.py [-p PORT] program <image> [flash_offset_hex]    erase + program + verify (sum32)
  haps_qspi.py [-p PORT] load    <image> <mem_addr_hex>        load raw bytes into memory (SRAM)
  haps_qspi.py [-p PORT] go      [addr_hex]                    jump
  haps_qspi.py [-p PORT] boot                                  production flash boot (build 49+)
  haps_qspi.py [-p PORT] term                                  interactive terminal (Ctrl-] to quit)
  haps_qspi.py [-p PORT] suite [--timeout S] [--addr HEX] img... load+run each image unattended (RAM: 80000000)
  haps_qspi.py [-p PORT] suite --flash <test>_flash.bin ...     build 49: each from the emulated flash (+ _sram.bin)
  haps_qspi.py [-p PORT] suite --winbond <test>_flash.bin ...   build 50+: program the real chip, boot with 'n'
      --baud-after uart_tests=2000000   follow a test that changes the console speed after its boot line


<image> may be a raw binary or a one-byte-per-line hex file (fromelf output such as
build/<test>/host0/app_flash.v8-a.hex/EXEC_ROM). The ROM must be at its prompt ('> ');
press a key on the console within ~3 s of reset, or let it fall into the monitor by itself.
No pyserial needed (termios).
"""
import os, sys, time, termios, tty, select

PORT = "/dev/ttyACM0"
CHUNK = 4096

def open_port(dev):
    fd = os.open(dev, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    attr = termios.tcgetattr(fd)
    tty.setraw(fd)
    attr = termios.tcgetattr(fd)
    attr[4] = attr[5] = termios.B115200
    attr[2] &= ~(termios.PARENB | termios.CSTOPB | termios.CSIZE | termios.CRTSCTS)
    attr[2] |= termios.CS8 | termios.CLOCAL | termios.CREAD
    attr[0] &= ~(termios.IXON | termios.IXOFF | termios.IXANY)
    termios.tcsetattr(fd, termios.TCSANOW, attr)
    termios.tcflush(fd, termios.TCIOFLUSH)
    return fd

def set_baud(fd, rate):
    """Change the line speed in place (uart_tests switches the console to 2 Mbaud = 20 MHz / BAUDDIV 10)."""
    attr = termios.tcgetattr(fd)
    attr[4] = attr[5] = getattr(termios, "B%d" % rate)
    termios.tcdrain(fd)
    termios.tcsetattr(fd, termios.TCSANOW, attr)

BAUD_AFTER = {}          # {name substring: rate}: switch the console speed once the test has started

def read_test_output(fd, log, test_timeout, name):
    """Read a test's output up to the end marker. For a test that changes the console speed right after its
    banner (uart_tests: UART0 BAUDDIV=10 = 2 Mbaud), switch the port as soon as the boot line has been seen."""
    rate = next((r for k, r in BAUD_AFTER.items() if k in name), None)
    if rate is None:
        buf, done = read_until(fd, b"\x04", test_timeout)
        log.write(buf); return buf.decode(errors="replace"), done
    head, _ = read_until(fd, b"Booting", 5.0)
    set_baud(fd, rate)
    body, done = read_until(fd, b"\x04", test_timeout)
    set_baud(fd, 115200)
    log.write(head + body)
    return (head + body).decode(errors="replace"), done

def read_until(fd, token, timeout):
    buf = b""; end = time.time() + timeout
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: buf += os.read(fd, 4096)
            except BlockingIOError: pass
            if token in buf: return buf, True
    return buf, False

def write_all(fd, data):
    while data:
        _, w, _ = select.select([], [fd], [], 1.0)
        n = os.write(fd, data); data = data[n:]

def cmd(fd, line, timeout=5.0, show=True):
    write_all(fd, (line + "\n").encode())
    buf, ok = read_until(fd, b"> ", timeout)
    txt = buf.decode(errors="replace")
    if show: sys.stdout.write(txt)
    if not ok: raise RuntimeError("no prompt after: " + line)
    return txt

def load_image(path):
    with open(path, "rb") as f: data = f.read()
    try:
        lines = data.decode().split()
        if lines and all(len(l) == 2 for l in lines[:64]):
            return bytes(int(l, 16) for l in lines)
    except UnicodeDecodeError:
        pass
    return data

def send_block(fd, verb, addr, blob):
    assert len(blob) <= CHUNK
    write_all(fd, f"{verb} {addr:x} {len(blob):x}\n".encode())
    buf, ok = read_until(fd, b"+", 5.0)
    if not ok: raise RuntimeError("no '+' for %s %x: %r" % (verb, addr, buf[-200:]))
    s = sum(blob) & 0xFFFFFFFF
    write_all(fd, blob + s.to_bytes(4, "little"))
    buf, ok = read_until(fd, b"> ", 30.0)
    txt = buf.decode(errors="replace")
    if "OK" not in txt: raise RuntimeError("block %s %x failed: %s" % (verb, addr, txt.strip()))

def verify(fd, addr, blob):
    txt = cmd(fd, f"k {addr:x} {len(blob):x}", timeout=60.0, show=False)
    want = sum(blob) & 0xFFFFFFFF
    got = int(txt.split("SUM=")[1].split()[0], 16)
    return want == got, want, got

def program(fd, image, off):
    data = load_image(image)
    pad = (-len(data)) % 16
    data += b"\xff" * pad
    print(f"image {image}: {len(data)} bytes -> flash offset 0x{off:06x}")
    sectors = range(off & ~0xFFF, off + len(data), 0x1000)
    t0 = time.time()
    for s in sectors:
        txt = cmd(fd, f"e {s:x}", timeout=10.0, show=False)
        if "OK" not in txt: raise RuntimeError("erase %x: %s" % (s, txt.strip()))
    print(f"erased {len(sectors)} sectors in {time.time()-t0:.1f}s")
    t0 = time.time()
    for i in range(0, len(data), CHUNK):
        blob = data[i:i+CHUNK]
        send_block(fd, "p", off + i, blob)
        sys.stdout.write(f"\rprogrammed {i+len(blob)}/{len(data)}"); sys.stdout.flush()
    print(f"\nprogrammed in {time.time()-t0:.1f}s")
    cmd(fd, "s 0", show=False)                # 1-bit XIP on, so the window can be read for the verify
    okv, want, got = verify(fd, 0x400000 + off, data)
    print("verify via XIP window: %s (sum want %08X got %08X)" % ("OK" if okv else "MISMATCH", want, got))
    return okv

def wait_reset_then_prompt(fd, log, max_wait=300.0):
    """Stay silent until the boot ROM's key window after the next reset, then take the monitor.
    Any byte sent to the board re-arms the ~215 s auto-reset hold-off, so nothing is sent while waiting."""
    buf, ok = read_until(fd, b"press any key", max_wait)
    log.write(buf)
    if not ok:
        return False
    write_all(fd, b"\n")
    buf, ok = read_until(fd, b"> ", 30.0)
    log.write(buf)
    return ok

# Boot ROM RW data is never initialised on the board (ticket N35): the library global SET_QIO_MODE_CMD
# (0x00804004, initial value 0x38 = SST "enter QPI") would hold whatever is in SRAM. Write it before
# every production boot. The word holds only that byte plus padding (initial image 38 00 00 00).
def fix_rom_rw(fd):
    txt = cmd(fd, "w 804004 38", show=False)
    txt = cmd(fd, "r 804004", show=False)
    return "00000038" in txt

def load_verify(fd, path, addr):
    data = load_image(path)
    for i in range(0, len(data), CHUNK):
        send_block(fd, "m", addr + i, data[i:i+CHUNK])
    return verify(fd, addr, data)

def winbond_boot(fd, log, test_timeout, name=""):
    """build 50+: 'n D 1' = Winbond start-up (Daniel's draft) and boot. Try N_Dummy 6, then 8."""
    for d in (6, 8):
        write_all(fd, f"n {d} 1\n".encode())
        buf, _ = read_until(fd, b"\x04", 3.0)              # a mismatch returns to the prompt quickly
        txt = buf.decode(errors="replace")
        if "Booting" in txt:
            rate = next((r for k, r in BAUD_AFTER.items() if k in name), None)
            if rate: set_baud(fd, rate)
            more, _ = read_until(fd, b"\x04", test_timeout)
            if rate: set_baud(fd, 115200)
            log.write(buf + more)
            return txt + more.decode(errors="replace"), d
        log.write(buf)
        if "> " not in txt:
            more, _ = read_until(fd, b"> ", 5.0); log.write(more)
    return txt, None

def run_one(fd, path, addr, test_timeout, log, flash=False, winbond=False):
    """RAM mode: load <path> at addr and jump. Flash mode (build 49+): <path> is <test>_flash.bin; load it at
    0x80080000 (= flash offset 0 of the emulator), load <test>_sram.bin at 0x800000, then production boot 'b'."""
    if winbond:
        sram = path.replace("_flash.bin", "_sram.bin")
        if not program(fd, path, 0):
            return "PROG-FAIL", "verify through the 1-bit window failed"
        okv, want, got = load_verify(fd, sram, 0x00800000)
        if not okv:
            return "LOAD-FAIL", "sram sum want %08X got %08X" % (want, got)
        t0 = time.time()
        txt, d = winbond_boot(fd, log, test_timeout, os.path.basename(path))
        dt = time.time() - t0
        if d is None:
            lines = [l.strip() for l in txt.replace("\r", "").split("\n") if l.strip()]
            return "NO-BOOT", " / ".join(lines[-3:])[:160]
        res = "PASS" if "TEST PASSED" in txt else "FAIL" if "TEST FAILED" in txt else "HANG"
        if "exception" in txt: res += "+EXC"
        lines = [l.strip() for l in txt.replace("\r", "").split("\n") if l.strip()]
        return res, "%.1f s, N_Dummy %d | %s" % (dt, d, " / ".join(lines[-3:])[:140])
    if flash:
        sram = path.replace("_flash.bin", "_sram.bin")
        for p_, a_ in ((path, 0x80080000), (sram, 0x00800000)):
            okv, want, got = load_verify(fd, p_, a_)
            if not okv:
                return "LOAD-FAIL", "%s sum want %08X got %08X" % (os.path.basename(p_), want, got)
        if not fix_rom_rw(fd):
            return "RW-FIX-FAIL", "could not set SET_QIO_MODE_CMD at 0x804004"
        t0 = time.time()
        write_all(fd, b"b\n")
    else:
        okv, want, got = load_verify(fd, path, addr)
        if not okv:
            return "LOAD-FAIL", "sum want %08X got %08X" % (want, got)
        t0 = time.time()
        write_all(fd, f"g {addr:x}\n".encode())
    txt, done = read_test_output(fd, log, test_timeout, os.path.basename(path))
    dt = time.time() - t0
    if "TEST PASSED" in txt:   res = "PASS"
    elif "TEST SKIPPED" in txt: res = "SKIPPED"
    elif "TEST FAILED" in txt: res = "FAIL"
    else:                      res = "HANG" if not done else "ENDED"
    if "exception" in txt:     res += "+EXC"
    lines = [l.strip() for l in txt.replace("\r", "").split("\n") if l.strip()]
    return res, "%.1f s | %s" % (dt, " / ".join(lines[-4:])[:160])

def suite(fd, files, addr, test_timeout, flash=False, winbond=False):
    stamp = time.strftime("%Y%m%d_%H%M%S")
    outdir = os.path.expanduser(f"~/haps_captures/suite_{stamp}")
    os.makedirs(outdir, exist_ok=True)
    mode = "from the REAL on-board flash (program, then Winbond boot 'n')" if winbond else ("from the emulated flash (production boot 'b')" if flash else f"at 0x{addr:08X}")
    print(f"suite: {len(files)} images {mode}, logs in {outdir}")
    print("each test ends in a spin loop; the board then resets by itself ~3.5 min after the last byte sent")
    results = []
    with open(os.path.join(outdir, "_session.log"), "wb") as slog:
        # get to a monitor prompt: try actively first, then wait for a reset
        got = False
        for _ in range(40):
            write_all(fd, b"\n")
            buf, got = read_until(fd, b"> ", 0.5)
            slog.write(buf)
            if got: break
        if not got:
            print("  board busy (spinning test?) - waiting silently for the auto-reset ...")
            if not wait_reset_then_prompt(fd, slog, 330.0):
                sys.exit("no monitor prompt - is build 48/49 programmed and the console free?")
        for n, path in enumerate(files, 1):
            name = os.path.basename(path).replace("_dram.bin", "").replace("_flash.bin", "").replace(".bin", "")
            print(f"[{n}/{len(files)}] {name}: load + run ...", flush=True)
            with open(os.path.join(outdir, name + ".log"), "wb") as log:
                try:
                    res, detail = run_one(fd, path, addr, test_timeout, log, flash, winbond)
                except Exception as e:
                    res, detail = "ERROR", str(e)[:160]
            print(f"      {res:12s} {detail}", flush=True)
            results.append((name, res, detail))
            if n < len(files):
                print("      waiting silently for the board to reset (up to ~4 min) ...", flush=True)
                if not wait_reset_then_prompt(fd, slog, 330.0):
                    print("      no reset/prompt seen - stopping"); break
    with open(os.path.join(outdir, "summary.txt"), "w") as f:
        for name, res, detail in results:
            f.write(f"{name:20s} {res:12s} {detail}\n")
    print("\nsummary:")
    for name, res, detail in results:
        print(f"  {name:20s} {res}")
    print(f"logs: {outdir}")

def term(fd):
    print("terminal - Ctrl-] to quit")
    old = termios.tcgetattr(0); tty.setraw(0)
    try:
        while True:
            r, _, _ = select.select([0, fd], [], [])
            if 0 in r:
                c = os.read(0, 1)
                if c == b"\x1d": break
                os.write(fd, c)
            if fd in r:
                try: sys.stdout.buffer.write(os.read(fd, 4096)); sys.stdout.flush()
                except BlockingIOError: pass
    finally:
        termios.tcsetattr(0, termios.TCSANOW, old); print()

def main():
    args = sys.argv[1:]
    port = PORT
    if args and args[0] == "-p": port = args[1]; args = args[2:]
    if not args: sys.exit(__doc__)
    fd = open_port(port)
    verb = args[0]
    # wake the monitor: keep sending newlines until the prompt appears (the ROM accepts a key
    # for ~3 s after each reset; with build 46 any key also suspends the board's auto-reset).
    # 'suite' and 'term' handle this themselves (suite waits silently for a reset if the board is busy).
    for _ in range(0 if verb in ("suite", "term") else 40):
        write_all(fd, b"\n")
        buf, ok = read_until(fd, b"> ", 0.5)
        if ok: break
    else:
        if verb not in ("suite", "term"):
            sys.exit("no monitor prompt on %s - is build 46+ running and the RX wire connected?" % port)
    if verb == "cmd": cmd(fd, " ".join(args[1:]))
    elif verb == "cmds":                      # several monitor lines in ONE session (one 10 s window on build 45)
        for line in args[1:]: cmd(fd, line, timeout=10.0)
    elif verb == "program": program(fd, args[1], int(args[2], 16) if len(args) > 2 else 0)
    elif verb == "load":
        data = load_image(args[1]); addr = int(args[2], 16)
        for i in range(0, len(data), CHUNK): send_block(fd, "m", addr + i, data[i:i+CHUNK])
        okv, want, got = verify(fd, addr, data); print("load %s (%08X/%08X)" % ("OK" if okv else "MISMATCH", want, got))
    elif verb == "go": write_all(fd, (f"g {args[1]}\n" if len(args) > 1 else "g\n").encode()); buf, _ = read_until(fd, b"\x04", 10.0); print(buf.decode(errors="replace"))
    elif verb == "boot":                      # build 49+: production flash boot (SPI_STARTUP, jump to 0x400000)
        print("SET_QIO_MODE_CMD fixed:", fix_rom_rw(fd))
        write_all(fd, b"b\n"); buf, _ = read_until(fd, b"\x04", 15.0); print(buf.decode(errors="replace"))
    elif verb == "term": term(fd)
    elif verb == "suite":                     # suite [--timeout S] [--addr HEX] img1 img2 ...
        tmo, addr, files, flash, winbond = 60.0, 0x80000000, [], False, False
        it = iter(args[1:])
        for a in it:
            if a == "--timeout": tmo = float(next(it))
            elif a == "--addr": addr = int(next(it), 16)
            elif a == "--flash": flash = True
            elif a == "--winbond": winbond = True
            elif a == "--baud-after": k, v = next(it).split("="); BAUD_AFTER[k] = int(v)
            else: files.append(a)
        suite(fd, files, addr, tmo, flash, winbond)
    else: sys.exit(__doc__)

if __name__ == "__main__":
    main()
