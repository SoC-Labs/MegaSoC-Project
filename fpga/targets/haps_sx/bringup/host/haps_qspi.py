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
  haps_qspi.py [-p PORT] linux2 ld2.bin shim.bin dtb Image [--baud N] [--keepalive S]  same, but through the
                                      stage-2 loader ld2 at N baud (default 1000000): ~1 minute instead of ten
  haps_qspi.py [-p PORT] linux shim.bin dtb Image [--keepalive S]   load the EL3 shim (80000000), DTB (80800000) and
                                      kernel Image (81000000), 'g 80000000', then a console with an auto-reset keep-alive
  haps_qspi.py [-p PORT] linuxterm [--keepalive S] [--pace MS]  attach to a Linux console that is already running
                                      (115200, keep-alive BEL, console.log + events.log in ~/haps_captures/linuxterm_*), no loading
      --pace MS   (linux, linux2, linuxterm; default 10) gap between the bytes forwarded to the board. The MPS2 UART
                  has a one-byte receive buffer and Linux on this core cannot take back-to-back bytes at 115200
                  ("ttyMPS0: N input overrun(s)", pasted text and arrow keys garbled), so typed/pasted input is paced.
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

def read_until_any(fd, tokens, timeout):
    """Like read_until, for several tokens: returns (buf, True) as soon as one of them has been received."""
    buf = b""; end = time.time() + timeout
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: buf += os.read(fd, 4096)
            except BlockingIOError: pass
            if any(t in buf for t in tokens): return buf, True
    return buf, False

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
    """write everything, waiting for the port when its buffer is full (the fd is non-blocking: EAGAIN-safe)"""
    while data:
        _, w, _ = select.select([], [fd], [], 1.0)
        if not w: continue
        try: n = os.write(fd, data)
        except BlockingIOError: continue
        data = data[n:]

def at_prompt(fd, log=None, wait=0.5):
    """Send a newline and return True only for a real monitor prompt: '> ' is the LAST thing received and the line then
    stays quiet. A running program whose output merely contains '> ' (seen 23 Nov 2026: sdio_tests printing while
    'program' probed, which then sent its erase command to the test) is not a prompt."""
    write_all(fd, b"\n")
    buf, ok = read_until(fd, b"> ", wait)
    more = b""
    if ok: more, _ = read_until(fd, b"\x00\x00no-such-token", 0.25)
    if log is not None: log.write(buf + more)
    return ok and buf.endswith(b"> ") and not more

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

# build 64 (haps_reset_ctrl.sv): the board resets when UART_RX has been held low for >= 4 ms and is released. A 0x00
# character at 1200 baud is 7.5 ms low. The DAPLink CDC bridge on the bench turns a serial BREAK into a reset of its own
# target MCU and never touches the line, so tcsendbreak() is useless here. Set HAPS_RESET_REQ=0 for builds <= 63, where the
# character would only be a stray byte that re-arms the 215 s hold-off.
RESET_REQ = os.environ.get("HAPS_RESET_REQ", "1") == "1"
# build 65 (monitor v6.0): 'n D 1' starts the flash image with the CPU caches on, as the stock bootloader does; a third
# argument 0 starts it with the caches off, as the monitor did up to v5.2. HAPS_BOOT_CACHES=0 selects that for the
# 'suite --winbond' boots (older monitors ignore the extra argument).
BOOT_CACHES_OFF = os.environ.get("HAPS_BOOT_CACHES", "1") == "0"

def request_reset(fd):
    """Ask a build-64+ board to reset: one 0x00 at 1200 baud, then back to 115200. Returns once the line is idle again."""
    saved = termios.tcgetattr(fd)
    slow = list(saved); slow[4] = slow[5] = termios.B1200
    termios.tcdrain(fd)
    termios.tcsetattr(fd, termios.TCSADRAIN, slow)
    write_all(fd, b"\x00")
    termios.tcdrain(fd); time.sleep(0.05)          # 10 bit-times at 1200 baud = 8.3 ms; margin for the bridge
    termios.tcsetattr(fd, termios.TCSADRAIN, saved)

def wait_reset_then_prompt(fd, log, max_wait=300.0):
    """Take the boot ROM's key window after the next reset, then the monitor prompt.
    build 64+: request the reset (request_reset) and expect the banner within ~15 s; otherwise, or if that fails,
    stay silent until the board's own reset (builds <= 63: ~215 s after the last byte sent, then the 10 s period)."""
    # The banner's first lines can reach the host while its port is still at 1200 baud (the board resets ~8 ms after the
    # request byte starts, the host switches back ~50 ms later; seen 19 Nov: "y\xf1[mon] JEDEC=..."), so accept any early
    # monitor line as the banner, not only "press any key". The key window is ~5.5 s, the JEDEC line comes ~10 ms in.
    BANNER = (b"press any key", b"[mon] JEDEC=", b"[mon] build")
    if RESET_REQ:
        request_reset(fd)
        # The DAPLink bridge delivers the banner late, in part, or not at all after the baud switch (19 Nov: intact after
        # 1.7 s, a fragment, or nothing until the auto-start line 5.5 s later), so do not wait for it: press a key every
        # 0.3 s from right after the request until the prompt answers. Keys sent before the window are ignored.
        end = time.time() + 12.0
        while time.time() < end:
            write_all(fd, b"\n")
            buf, ok = read_until(fd, b"> ", 0.3); log.write(buf)
            if ok:
                return True
        print("  (no monitor prompt within 12 s of the reset request - waiting for the board's own reset)")
    ok = False
    if not ok:
        buf, ok = read_until_any(fd, BANNER, max_wait)
    log.write(buf)
    if not ok:
        return False
    # The markers above sit in the banner's first line, before the monitor opens its ~5.5 s key window: let the line
    # finish, pause, then press; press once more if the prompt has not come (19 Nov: a key sent at once was lost).
    # Part of the banner can be lost in the bridge around the baud switch, so the window's start is uncertain: press a
    # key every 0.4 s until the prompt answers (the monitor ignores keys before the window; the window is ~5.5 s).
    buf, _ = read_until(fd, b"press any key", 1.0); log.write(buf)
    end = time.time() + 12.0
    ok = False
    while time.time() < end and not ok:
        write_all(fd, b"\n")
        buf, ok = read_until(fd, b"> ", 0.4); log.write(buf)
    if not ok:
        buf, ok = read_until(fd, b"> ", 20.0); log.write(buf)
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
        write_all(fd, (f"n {d} 1 0\n" if BOOT_CACHES_OFF else f"n {d} 1\n").encode())
        buf, ended = read_until(fd, b"\x04", 3.0)          # a mismatch returns to the prompt quickly
        txt = buf.decode(errors="replace")
        if "Booting" in txt:
            if ended:                                      # build 65: with the CPU caches on a test can finish inside
                log.write(buf)                             # these 3 s; its end marker is already here, do not wait again
                return txt, d
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
        if os.path.exists(sram):                  # old per-region images; single-load-region images carry their own RW/ZI
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
            got = at_prompt(fd, slog)
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
                write_all(fd, c)
            if fd in r:
                try: sys.stdout.buffer.write(os.read(fd, 4096)); sys.stdout.flush()
                except BlockingIOError: pass
    finally:
        termios.tcsetattr(0, termios.TCSANOW, old); print()


SHIM_ADDR, DTB_ADDR, KERNEL_ADDR = 0x80000000, 0x80800000, 0x81000000

VERIFY_CHUNK = 0x10000   # 64 KB: one 'k' per chunk takes ~0.1 s, so a 6 MB image is checked in ~10 s

def load_progress(fd, path, addr, label):
    """Load with verify and a progress line (the monitor takes 1000-byte blocks, ~10 KB/s at 115200).
    The DDR4 keeps its contents across the SoC's auto-reset, so a file already in memory is detected
    chunk by chunk with 'k' and only the chunks that differ are sent again (Linux frees and reuses its
    init section, so after a boot the Image typically needs a partial reload, not a full one)."""
    data = load_image(path)
    t0 = time.time()
    todo = [(0, len(data))]
    if len(data) > VERIFY_CHUNK:
        bad = []
        for c in range(0, len(data), VERIFY_CHUNK):
            blob = data[c:c+VERIFY_CHUNK]
            okc, _, _ = verify(fd, addr + c, blob)
            if not okc: bad.append((c, len(blob)))
            sys.stdout.write(f"\r{label}: checking what is already in DDR4 {c+len(blob)}/{len(data)}  ({len(bad)} chunks to send)   "); sys.stdout.flush()
        print()
        todo = bad
        if not bad:
            print(f"{label}: already in DDR4 at {addr:08x}, nothing to send ({time.time()-t0:.0f} s)")
            return True
        print(f"{label}: {len(bad)} of {(len(data)+VERIFY_CHUNK-1)//VERIFY_CHUNK} chunks differ -> sending {sum(n for _, n in bad)} bytes")
    total = sum(n for _, n in todo); sent = 0; t1 = time.time()
    for off, n in todo:
        for i in range(off, off + n, CHUNK):
            blob = data[i:min(i+CHUNK, off+n)]
            send_block(fd, "m", addr + i, blob)
            sent += len(blob)
            if (sent // CHUNK) % 50 == 0 or sent >= total:
                el = time.time() - t1; rate = sent / el if el > 0 else 0
                eta = (total - sent) / rate if rate > 0 else 0
                sys.stdout.write(f"\r{label}: {sent}/{total} bytes at {addr:08x}  {rate/1024:.1f} KB/s  eta {eta:4.0f} s   "); sys.stdout.flush()
    print()
    okv, want, got = verify(fd, addr, data)
    print(f"{label}: verify %s (sum %08X/%08X) in %.0f s" % ("OK" if okv else "MISMATCH", want, got, time.time() - t0))
    return okv

def term_keepalive(fd, log, period, pace=0.010):
    """Console for a Linux session. The board resets itself ~215 s after the last byte it RECEIVED
    (haps_top.sv auto-reset hold-off: any start bit on UART_RX re-arms it), so a BEL byte (0x07) is sent whenever
    the host has been quiet for 'period' s. BEL, not NUL: BusyBox's line editor (UNICODE_SUPPORT=y) cannot decode a
    NUL with mbstowcs and turns it into the substitution character '?', which it INSERTS into the command line (the
    "~ # ?????" prompts after a long idle); a control byte it has no binding for, such as BEL, is discarded.
    Bytes typed or pasted are forwarded one at a time with a gap of 'pace' s: the MPS2 UART has a one-byte receive
    buffer and Linux on this core cannot service back-to-back bytes at 115200 ("ttyMPS0: N input overrun(s)";
    pasted commands and 3-byte arrow-key sequences arrive garbled). All writes wait for the port (EAGAIN-safe).
    Ctrl-] quits. Everything received is appended to 'log'; host-side timestamps of every byte sent (TX / KA) and of
    every chunk received (RX) go to events.log next to it, so kernel printk times can be matched to wall-clock time."""
    print(f"console (Ctrl-] to quit; keep-alive BEL every {period:.0f} s of silence; input paced at {pace*1000:.0f} ms/byte)")
    evt = None
    try:
        evt = open(os.path.join(os.path.dirname(os.path.abspath(log.name)), "events.log"), "a", buffering=1)
    except Exception:
        evt = None
    def ev(msg):
        if evt is None: return
        t = time.time()
        evt.write(time.strftime("%H:%M:%S", time.localtime(t)) + ".%03d %s\n" % (int(t * 1000) % 1000, msg))
    def rx():
        try:
            buf = os.read(fd, 4096)
        except BlockingIOError:
            return
        sys.stdout.buffer.write(buf); sys.stdout.flush(); log.write(buf); log.flush()
        ev("RX %d %r" % (len(buf), buf[:48]))
    ev(f"START keepalive={period:.0f}s pace={pace*1000:.0f}ms")
    old = termios.tcgetattr(0); tty.setraw(0)
    last_tx = time.time()
    try:
        while True:
            r, _, _ = select.select([0, fd], [], [], 1.0)
            if 0 in r:
                chunk = os.read(0, 256)
                if b"\x1d" in chunk: chunk = chunk[:chunk.index(b"\x1d")]; quit_now = True
                else: quit_now = False
                for i, b in enumerate(chunk):
                    write_all(fd, bytes([b])); last_tx = time.time(); ev("TX %02x" % b)
                    if i + 1 < len(chunk) and pace > 0: time.sleep(pace)
                    # keep showing the board's echo while a long paste is being paced out
                    rr, _, _ = select.select([fd], [], [], 0)
                    if rr: rx()
                if quit_now: break
            if fd in r: rx()
            if time.time() - last_tx > period:
                write_all(fd, b"\x07"); last_tx = time.time(); ev("KA 07")   # BEL: ignored by the BusyBox line editor, re-arms the board hold-off
    finally:
        ev("QUIT")
        if evt is not None: evt.close()
        termios.tcsetattr(0, termios.TCSANOW, old); print()

def linux_term(fd, keepalive=100.0, pace=0.010):
    """Attach to a Linux console that is already running (nothing is loaded, nothing is sent until you type)."""
    outdir = os.path.expanduser(time.strftime("~/haps_captures/linuxterm_%Y%m%d_%H%M%S"))
    os.makedirs(outdir, exist_ok=True)
    log = open(os.path.join(outdir, "console.log"), "ab")
    log.write(f"--- {time.ctime()} linuxterm attach at 115200\n".encode())
    print(f"linuxterm: attached at 115200; log {outdir}/console.log")
    term_keepalive(fd, log, keepalive, pace)
    log.close()
    print(f"console log: {outdir}/console.log")

LD2_ADDR, LD2_MAGIC, PCLK_HZ = 0x80020000, 0x2132444c, 20000000

def ld2_rx(fd, n, timeout):
    buf = b""; end = time.time() + timeout
    while len(buf) < n and time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: buf += os.read(fd, n - len(buf))
            except BlockingIOError: pass
    return buf

def ld2_send(fd, addr, data, label):
    """one framed block through ld2; returns True when the loader's byte sum matches"""
    t0 = time.time()
    write_all(fd, LD2_MAGIC.to_bytes(4, "little") + addr.to_bytes(4, "little") + len(data).to_bytes(4, "little") + (0).to_bytes(4, "little"))
    write_all(fd, data)
    rep = ld2_rx(fd, 8, 30.0 + len(data) / 20000.0)
    if len(rep) < 8:
        print(f"{label}: no reply from ld2 (got {rep!r})"); return False
    got = int.from_bytes(rep[:4], "little"); state = int.from_bytes(rep[4:8], "little")
    want = sum(data) & 0xFFFFFFFF
    el = time.time() - t0
    print(f"{label}: {len(data)} bytes to {addr:08x} in {el:.1f} s ({len(data)/el/1024:.0f} KB/s), sum %s%s" % ("OK" if got == want else f"MISMATCH {got:08X}/{want:08X}", "" if not (state & 8) else " - RX OVERRUN seen by the loader"))
    return got == want and not (state & 8)

def linux2_boot(fd, ld2, shim, dtb, image, baud=1000000, keepalive=100.0, pace=0.010):
    outdir = os.path.expanduser(time.strftime("~/haps_captures/linux_%Y%m%d_%H%M%S"))
    os.makedirs(outdir, exist_ok=True)
    log = open(os.path.join(outdir, "console.log"), "ab")
    div = round(PCLK_HZ / baud)
    print(f"linux2: ld2 @ {LD2_ADDR:08x}, then at {baud} baud (divisor {div}): shim @ {SHIM_ADDR:08x}, dtb @ {DTB_ADDR:08x}, Image @ {KERNEL_ADDR:08x}; log {outdir}/console.log")
    t0 = time.time()
    if not load_progress(fd, ld2, LD2_ADDR, "ld2"):
        print("ld2 did not verify - stopping"); return
    write_all(fd, f"g {LD2_ADDR:x}\n".encode())
    buf, ok = read_until(fd, b"ld2 ready", 10.0)
    if not ok: print("ld2 did not start: %r" % buf[-200:]); return
    write_all(fd, div.to_bytes(4, "little"))
    buf, ok = read_until(fd, b"ok", 5.0)
    if not ok: print("ld2 did not take the divisor: %r" % buf[-200:]); return
    time.sleep(0.05)
    set_baud(fd, baud)
    termios.tcflush(fd, termios.TCIFLUSH)
    good = True
    for path, addr, label in ((shim, SHIM_ADDR, "shim"), (dtb, DTB_ADDR, "dtb"), (image, KERNEL_ADDR, "Image")):
        data = load_image(path)
        good = ld2_send(fd, addr, data, label) and good
        if not good: break
    if not good:
        set_baud(fd, 115200)
        print("a block failed - not booting (try --baud 500000; the board resets itself in ~4 min)"); return
    print(f"all images loaded in {time.time()-t0:.0f} s; go {SHIM_ADDR:08x}")
    log.write(f"--- {time.ctime()} ld2 go {SHIM_ADDR:x} at {baud} baud\n".encode())
    write_all(fd, LD2_MAGIC.to_bytes(4, "little") + SHIM_ADDR.to_bytes(4, "little") + (0).to_bytes(4, "little") + (1).to_bytes(4, "little"))
    set_baud(fd, 115200)      # right away (tcdrain inside): ld2 waits 200 ms at 115200 before it branches to the shim
    term_keepalive(fd, log, keepalive, pace)
    log.close()
    print(f"console log: {outdir}/console.log")

def linux_boot(fd, shim, dtb, image, keepalive=100.0, pace=0.010):
    outdir = os.path.expanduser(time.strftime("~/haps_captures/linux_%Y%m%d_%H%M%S"))
    os.makedirs(outdir, exist_ok=True)
    log = open(os.path.join(outdir, "console.log"), "ab")
    print(f"linux: shim {shim} @ {SHIM_ADDR:08x}, dtb {dtb} @ {DTB_ADDR:08x}, Image {image} @ {KERNEL_ADDR:08x}; log {outdir}/console.log")
    t0 = time.time()
    ok = load_progress(fd, shim, SHIM_ADDR, "shim")
    ok = load_progress(fd, dtb, DTB_ADDR, "dtb") and ok
    ok = load_progress(fd, image, KERNEL_ADDR, "Image") and ok
    if not ok:
        print("a load did not verify - not booting"); return
    print(f"all images loaded and verified in {time.time()-t0:.0f} s; 'g {SHIM_ADDR:x}'")
    log.write(f"--- {time.ctime()} g {SHIM_ADDR:x}\n".encode())
    write_all(fd, f"g {SHIM_ADDR:x}\n".encode())
    term_keepalive(fd, log, keepalive, pace)
    log.close()
    print(f"console log: {outdir}/console.log")

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
    if verb in ("linux", "linux2"):
        # One probe only: every byte we send re-arms the board's ~215 s auto-reset hold-off, so if a test is
        # spinning the prompt would never come. Like 'suite', stay silent and take the ROM's key window instead.
        write_all(fd, b"\n")
        buf, ok = read_until(fd, b"> ", 1.0)
        if not ok:
            print("no prompt - board busy (a test spinning, or the auto-reset held off); waiting silently for the next reset, up to ~5 min ...")
            class _Discard:
                def write(self, b): pass
            if not wait_reset_then_prompt(fd, _Discard(), 330.0):
                sys.exit("no monitor prompt on %s: no 'press any key' seen in 5 min - is build 46+ running and the RX wire connected?" % port)
    else:
        for _ in range(0 if verb in ("suite", "term", "linuxterm") else 40):
            if at_prompt(fd): break
        else:
            if verb not in ("suite", "term", "linuxterm"):
                # build 64+: a spinning test or a running Linux never answers; request a reset and take the window
                print("no prompt - requesting a board reset (build 64+) ...")
                class _Discard:
                    def write(self, b): pass
                if not wait_reset_then_prompt(fd, _Discard(), 60.0):
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
    elif verb == "linux2":                    # linux2 ld2.bin shim.bin dtb Image [--baud N] [--keepalive S] [--pace MS]
        ka, baud, pace, files = 100.0, 1000000, 10.0, []
        it = iter(args[1:])
        for a in it:
            if a == "--keepalive": ka = float(next(it))
            elif a == "--baud": baud = int(next(it))
            elif a == "--pace": pace = float(next(it))
            else: files.append(a)
        if len(files) != 4: sys.exit("linux2: need ld2.bin shim.bin dtb Image")
        linux2_boot(fd, files[0], files[1], files[2], files[3], baud, ka, pace / 1000.0)
    elif verb == "linux":                     # linux shim.bin dtb Image [--keepalive S] [--pace MS]
        ka, pace, files = 100.0, 10.0, []
        it = iter(args[1:])
        for a in it:
            if a == "--keepalive": ka = float(next(it))
            elif a == "--pace": pace = float(next(it))
            else: files.append(a)
        if len(files) != 3: sys.exit("linux: need shim.bin dtb Image")
        linux_boot(fd, files[0], files[1], files[2], ka, pace / 1000.0)
    elif verb == "linuxterm":                 # linuxterm [--keepalive S] [--pace MS]: attach to a running Linux console
        ka, pace = 100.0, 10.0
        it = iter(args[1:])
        for a in it:
            if a == "--keepalive": ka = float(next(it))
            elif a == "--pace": pace = float(next(it))
            else: sys.exit(f"linuxterm: unknown argument {a}")
        linux_term(fd, ka, pace / 1000.0)
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
