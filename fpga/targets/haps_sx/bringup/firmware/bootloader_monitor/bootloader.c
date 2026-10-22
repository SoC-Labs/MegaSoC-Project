// 2026-10-19 BRING-UP BUILD ONLY (FPGA build 51, v5.2) - scratch copy, do not commit.
// v5.2: winbond_startup rewritten (see its comment): QPI JEDEC check, direct EBh+mode transaction, AHB_CMD = EBh.
// v5 (build 50): real on-board W25Q32FW again (no emulator), QSPI controller SPI-write fixes (N39 extra clock,
// N27 bit order) -> SPI writes are raw now (g_wrmode 0). Globals initialised in main() because the ROM's RW/ZI is
// never initialised (N35). No automatic flash writes at boot (the old write-order probe would wear the last
// sector at every 10 s auto-reset). 'n' = Winbond start-up as drafted for Daniel (QE volatile, 38h, C0h, EBh
// continuous read, XIP) with a selectable controller dummy count; auto-start boots from it if word0 = boot.s.
// --- v4 header follows ---
// 2026-10-15 BRING-UP BUILD ONLY (FPGA build 49, v4) - scratch copy, do not commit.
// v4 (build 49): production flash boot. With the in-FPGA SST26VF064B emulator (JEDEC BF 26 43) the ROM
// runs the UNMODIFIED library SPI_STARTUP() and jumps to 0x400000 exactly like bootloader.c (CG092 left
// in its reset state, caches off): automatically at reset when the image starts with boot.s, or on 'b'.
// The emulator's store is filled over UART at 0x8008_0000 (= flash offset 0).
// v3 (build 46): dsb barriers after control writes (build 45 aborted on a window read that
// overtook the CTRL write); time-bounded status polling; SPI-mode write bit order is MEASURED
// on the last 4 KB sector (only if erased) instead of guessed; QE is set with volatile writes
// only; auto-jump only when word 0 is D2800000 (first instruction of SoC Labs boot.s).
//
// Boot ROM with a UART monitor for the HAPS-SX on-board Winbond W25Q32FW:
//  * identifies the flash (recovers a chip left in QPI mode), prints the ID
//  * waits ~3 s for a key on UART0 RX; no key -> automatic start-up:
//      - SPI-mode XIP (Fast Read 0Bh, 8 dummy clocks), 4 words from 0x400000
//      - Winbond QPI (QE, 38h, C0h) + QPI XIP, 4 words, then back to SPI XIP
//      - if the flash holds code, jump to it; else drop into the monitor
//  * monitor: raw register/memory access, raw SPI commands, erase/program/
//    verify of the flash and memory load over UART (see 'h').
// Caches stay OFF (enable_caches() stops the boot - separate open issue).
#include "system.h"
#include "qspi_flash.h"
#include "cpu_asm_codes.h"
#include "uart_stdout.h"
#include "CMSDK.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define FLASH_WIN    0x00400000UL
#define LOAD_BUF     ((uint8_t *)0x00806000UL)   /* 4 KB scratch in SRAM, above the scatter regions (RWZI ends 0x806000) */
#define LOAD_MAX     4096
#define CMD_EN       SL_AHB_QSPI_SPI_CMD_Enable_Msk
#define CMD_RD       SL_AHB_QSPI_SPI_CMD_Rd_Enable_Msk
#define CMD_WR       SL_AHB_QSPI_SPI_CMD_Wr_Enable_Msk
#define CMD_ADDR     SL_AHB_QSPI_SPI_CMD_Addr_Enable_Msk
#define CMD_DUMMY(n) (((uint32_t)(n) & 0xFUL) << 12)
#define CMD_NBYTES(n) ((((uint32_t)(n) - 1UL) & 0xFUL) << 16)     /* n = 1..16 */
#define CTRL_QIO     SL_AHB_QSPI_CTRL_QIO_Msk
#define CTRL_XIP     SL_AHB_QSPI_CTRL_XiP_Msk
#define CTRL_CONT    SL_AHB_QSPI_CTRL_Cont_Rd_Msk
#define CTRL_NOCMD   SL_AHB_QSPI_CTRL_No_CMD_Msk
#define CTRL_MODE(m) (((uint32_t)(m) & 0xFFUL) << 16)

static uint32_t g_id = 0;
static int g_rx_seen = 0;
static int g_wrmode = 0;      /* SPI-mode write byte mapping: 0 raw, 1 nibble-reverse, 2 byte-reverse, 3 nibble-swap, -1 unknown */
static inline void dsb(void) { __asm volatile("dsb sy" ::: "memory"); }

/* ---------------- UART0 raw I/O (CMSDK APB UART, 1-byte RX buffer) ---------------- */
static inline int rx_ready(void) { return (CMSDK_UART0->STATE & CMSDK_UART_STATE_RXBF_Msk) != 0; }
static inline uint8_t rx_byte(void) { while (!rx_ready()) {} return (uint8_t)CMSDK_UART0->DATA; }
static int rx_wait(uint32_t loops) { while (loops--) { if (rx_ready()) return 1; } return 0; }
static void tx_byte(uint8_t c) { while (CMSDK_UART0->STATE & CMSDK_UART_STATE_TXBF_Msk) {} CMSDK_UART0->DATA = c; }
static void delay_loops(uint32_t n) { while (n--) { __asm volatile("nop"); } }

/* ---------------- QSPI controller primitives ---------------- */
static uint8_t rev4(uint8_t n) { return (uint8_t)(((n & 1) << 3) | ((n & 2) << 1) | ((n & 4) >> 1) | ((n & 8) >> 3)); }
/* Controller quirk (qspi_controller.sv DATA_O, QIO=0): write data is shifted out LSB-first
   per nibble, so a byte X reaches the flash as {rev4(X[7:4]), rev4(X[3:0])}. Pre-swap in SPI
   mode so the flash sees X. QPI-mode writes are correct as they are. Verified via SR2 readback. */
static uint8_t rev8(uint8_t b) { return (uint8_t)((rev4((uint8_t)(b & 0xF)) << 4) | rev4((uint8_t)(b >> 4))); }
static uint8_t map_wr(uint8_t b, int mode) {
  switch (mode) {
    case 1:  return (uint8_t)((rev4((uint8_t)(b >> 4)) << 4) | rev4((uint8_t)(b & 0xF)));
    case 2:  return rev8(b);
    case 3:  return (uint8_t)((b << 4) | (b >> 4));
    default: return b;
  }
}
static uint8_t fix_wr(uint8_t b) {
  if (SL_QSPI->CTRL & CTRL_QIO) return b;
  return map_wr(b, g_wrmode > 0 ? g_wrmode : 0);
}
static void qspi_cmd(uint32_t cmd, uint32_t addr, const uint8_t *wd, int nwr) {
  SL_QSPI->SPI_ADDR = addr & 0x3FFFFFUL;
  if (wd) {
    uint32_t w[4] = {0, 0, 0, 0};
    for (int i = 0; i < nwr && i < 16; i++) w[i >> 2] |= (uint32_t)fix_wr(wd[i]) << (8 * (i & 3));
    for (int i = 0; i < 4; i++) SL_QSPI->WRITE_DATA[i] = w[i];
  }
  dsb();
  SL_QSPI->SPI_CMD = cmd & ~CMD_EN;
  SL_QSPI->SPI_CMD = cmd | CMD_EN;
  dsb();
  SPI_WAIT_BUSY(SL_QSPI);
  SL_QSPI->SPI_CMD = cmd & ~CMD_EN;
  dsb();
}
/* READ_DATA[0] for n<=4 bytes holds byte k at bits [8*(4-n+k)+7 : 8*(4-n+k)] */
static uint8_t rd_byte(int k, int n) { return (uint8_t)(SL_QSPI->READ_DATA[0] >> (8 * (4 - n + k))); }
static uint8_t cmd_rd1(uint8_t op) { qspi_cmd(op | CMD_RD | CMD_NBYTES(1), 0, 0, 0); return rd_byte(0, 1); }
static uint32_t jedec(void) { qspi_cmd(0x9F | CMD_RD | CMD_NBYTES(4), 0, 0, 0); return SL_QSPI->READ_DATA[0] & 0xFFFFFFUL; }
static void set_qio(int on) { if (on) SL_QSPI->CTRL |= CTRL_QIO; else SL_QSPI->CTRL &= ~CTRL_QIO; dsb(); }
static uint8_t sr1(void) { return cmd_rd1(0x05); }
static uint8_t sr2(void) { return cmd_rd1(0x35); }
/* each sr1() is a 16-clock SPI transaction (~7 us at CLK_DIV=4) plus APB overhead */
static int wait_wip(uint32_t loops, const char *what) {
  uint8_t s = 0xFF;
  while (loops--) { s = sr1(); if (!(s & 1)) return 0; }
  printf("[mon] %s: still busy, SR1=%02X\n", what, s); return -1;
}
static void cache_off(void) { CG092->CCR = 0; dsb(); }
static void cache_on(void) { CG092->CCR = 0; dsb(); CG092->CCR = 1; dsb(); for (uint32_t i = 0; i < 100000; i++) if ((CG092->SR & 3) == 2) break; dsb(); }

/* Reset + identify; if the chip was left in QPI mode (volatile), exit it first. */
static uint32_t flash_identify(void) {
  SL_QSPI->CTRL = 0; dsb(); /* SPI mode, XIP off */
  qspi_cmd(0x66, 0, 0, 0); qspi_cmd(0x99, 0, 0, 0); delay_loops(2000);
  uint32_t id = jedec();
  if ((id & 0xFF) != 0xEF && (id & 0xFF) != 0xBF && (id & 0xFF) != 0x20) {
    set_qio(1); qspi_cmd(0xFF, 0, 0, 0);               /* Winbond Exit QPI */
    qspi_cmd(0x66, 0, 0, 0); qspi_cmd(0x99, 0, 0, 0);  /* reset in QPI too, in case */
    set_qio(0); delay_loops(2000);
    qspi_cmd(0x66, 0, 0, 0); qspi_cmd(0x99, 0, 0, 0); delay_loops(2000);
    id = jedec();
  }
  return id;
}
static void xip_spi(void) {            /* Fast Read 0Bh, 8 dummy clocks, 1-bit */
  SL_QSPI->AHB_CMD = CMD_DUMMY(8) | 0x0B;
  SL_QSPI->CTRL = CTRL_XIP;
  dsb();
}
/* Winbond: QE must be 1 before 38h; QE is non-volatile (S9) - try the volatile write first. */
static int winbond_enter_qpi(int dummy_sel) {
  uint8_t d = 0x02;
  if (g_wrmode < 0) { printf("[mon] QE: SPI write mapping unknown - run the probe first ('o' to force)\n"); return -1; }
  qspi_cmd(0x50, 0, 0, 0);                              /* volatile SR write enable: nothing is permanent */
  qspi_cmd(0x31 | CMD_WR | CMD_NBYTES(1), 0, &d, 1);
  uint8_t s2 = sr2();
  if (!(s2 & 2)) { printf("[mon] QE did not set (SR2=%02X, wrmode %d)\n", s2, g_wrmode); return -1; }
  qspi_cmd(0x38, 0, 0, 0);            /* Enter QPI (chip) */
  set_qio(1);                          /* controller to 4-bit */
  dsb();
  uint8_t p = (uint8_t)((dummy_sel & 3) << 4);   /* C0h P5P4: 0->2, 1->4, 2->6, 3->8 dummy clocks */
  qspi_cmd(0xC0 | CMD_WR | CMD_NBYTES(1), 0, &p, 1);
  return 0;
}
static void winbond_exit_qpi(void) { qspi_cmd(0xFF, 0, 0, 0); set_qio(0); }
static void xip_qpi(uint8_t op, int ndummy, int cont) {
  SL_QSPI->AHB_CMD = CMD_DUMMY(ndummy) | op;
  SL_QSPI->CTRL = CTRL_QIO | CTRL_XIP | (cont ? (CTRL_CONT | CTRL_MODE(0xA0)) : 0);
  dsb();
  if (cont) { volatile uint32_t *f = (volatile uint32_t *)FLASH_WIN; (void)f[0]; dsb(); SL_QSPI->CTRL |= CTRL_NOCMD; dsb(); }
}
static void show_window(const char *tag) {
  volatile uint32_t *f = (volatile uint32_t *)FLASH_WIN;
  cache_off();
  dsb();
  printf("[mon] %s: flash[0..3]=%08lX %08lX %08lX %08lX  CTRL=%08lX AHB_CMD=%08lX\n", tag,
         (unsigned long)f[0], (unsigned long)f[1], (unsigned long)f[2], (unsigned long)f[3],
         (unsigned long)SL_QSPI->CTRL, (unsigned long)SL_QSPI->AHB_CMD);
}

/* ---------------- flash erase / program ---------------- */
static int flash_erase_4k(uint32_t off) {
  uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL &= ~(CTRL_XIP | CTRL_NOCMD); dsb();
  qspi_cmd(0x06, 0, 0, 0);
  qspi_cmd(0x20 | CMD_ADDR, off, 0, 0);
  int r = wait_wip(100000, "erase");       /* ~1 s; tSE max 400 ms */
  SL_QSPI->CTRL = saved; dsb(); return r;
}
static int flash_program(uint32_t off, const uint8_t *src, uint32_t n) {   /* n multiple of 16 */
  uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL &= ~(CTRL_XIP | CTRL_NOCMD); dsb();
  int r = 0;
  for (uint32_t i = 0; i < n && r == 0; i += 16) {
    qspi_cmd(0x06, 0, 0, 0);
    qspi_cmd(0x02 | CMD_WR | CMD_ADDR | CMD_NBYTES(16), off + i, src + i, 16);
    r = wait_wip(2000, "program");          /* ~20 ms; tPP max 3 ms */
  }
  SL_QSPI->CTRL = saved; dsb(); return r;
}
static uint32_t sum32(uint32_t addr, uint32_t n) {
  volatile uint8_t *p = (volatile uint8_t *)(uintptr_t)addr; uint32_t s = 0;
  for (uint32_t i = 0; i < n; i++) s += p[i];
  return s;
}
/* receive n raw bytes + 4-byte LE sum into dst; returns 0 ok, -1 checksum, -2 overrun */
static int rx_block(uint8_t *dst, uint32_t n) {
  CMSDK_UART0->STATE = CMSDK_UART_STATE_RXOR_Msk;   /* clear overrun flag */
  uint32_t s = 0;
  for (uint32_t i = 0; i < n; i++) { uint8_t b = rx_byte(); dst[i] = b; s += b; }
  uint32_t cs = 0; for (int i = 0; i < 4; i++) cs |= (uint32_t)rx_byte() << (8 * i);
  if (CMSDK_UART0->STATE & CMSDK_UART_STATE_RXOR_Msk) return -2;
  return (cs == s) ? 0 : -1;
}

/* ---------------- SPI-mode write-order probe (last 4 KB sector, only if erased) ----------------
   Programs a known 16-byte pattern raw (no mapping), reads it back through the APB command path
   (03h) and through the XIP window, prints both, derives the byte mapping the controller applies
   to SPI-mode write data, then erases the sector again. Also shows APB-vs-AHB byte order.      */
#define PROBE_OFF 0x3FF000UL
static const uint8_t probe_pat[16] = {0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x55,0xAA,0x0F,0xF0,0x12,0x34,0x56,0x78};
static void apb_read16(uint32_t off, uint8_t *dst) {
  qspi_cmd(0x03 | CMD_RD | CMD_ADDR | CMD_NBYTES(16), off, 0, 0);
  for (int i = 0; i < 16; i++) dst[i] = (uint8_t)(SL_QSPI->READ_DATA[i >> 2] >> (8 * (i & 3)));
}
static void hex16(const char *tag, const uint8_t *b) {
  printf("[mon] %s:", tag); for (int i = 0; i < 16; i++) printf(" %02X", b[i]); printf("\n");
}
static int probe_write_order(void) {
  uint8_t rb[16], win[16];
  uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL = 0; dsb();
  apb_read16(PROBE_OFF, rb);
  int erased = 1; for (int i = 0; i < 16; i++) if (rb[i] != 0xFF) erased = 0;
  if (!erased) { hex16("probe sector 3FF000 not erased, skipping write probe", rb); SL_QSPI->CTRL = saved; dsb(); return -1; }
  int old = g_wrmode; g_wrmode = 0;
  qspi_cmd(0x06, 0, 0, 0);
  qspi_cmd(0x02 | CMD_WR | CMD_ADDR | CMD_NBYTES(16), PROBE_OFF, probe_pat, 16);
  wait_wip(2000, "probe program");
  apb_read16(PROBE_OFF, rb);
  hex16("probe wrote  ", probe_pat);
  hex16("probe APB 03h", rb);
  xip_spi(); cache_off(); dsb();
  volatile uint32_t *f = (volatile uint32_t *)(FLASH_WIN + PROBE_OFF);
  for (int i = 0; i < 4; i++) { uint32_t w = f[i]; for (int k = 0; k < 4; k++) win[4 * i + k] = (uint8_t)(w >> (8 * k)); }
  hex16("probe window ", win);
  SL_QSPI->CTRL = 0; dsb();
  int found = -1;
  for (int m = 0; m < 4 && found < 0; m++) { int ok = 1; for (int i = 0; i < 16; i++) if (rb[i] != map_wr(probe_pat[i], m)) ok = 0; if (ok) found = m; }
  if (found >= 0) printf("[mon] SPI write mapping = %d (%s): to send X the controller needs %s\n", found,
                         found == 0 ? "raw" : found == 1 ? "nibble-reverse" : found == 2 ? "byte-reverse" : "nibble-swap",
                         found == 0 ? "X" : "map(X) - the ROM now pre-swaps");
  else printf("[mon] SPI write mapping: no simple match - keep raw\n");
  int swapped = 1; for (int i = 0; i < 16; i++) if (win[i] != rb[i]) swapped = 0;
  printf("[mon] window byte order %s APB order\n", swapped ? "==" : "!=");
  g_wrmode = found >= 0 ? found : old;
  qspi_cmd(0x06, 0, 0, 0); qspi_cmd(0x20 | CMD_ADDR, PROBE_OFF, 0, 0); wait_wip(100000, "probe erase");
  apb_read16(PROBE_OFF, rb); erased = 1; for (int i = 0; i < 16; i++) if (rb[i] != 0xFF) erased = 0;
  printf("[mon] probe sector erased again: %s\n", erased ? "yes" : "NO");
  SL_QSPI->CTRL = saved; dsb();
  return found;
}

/* ---------------- exception reporting ---------------- */
void abort_handler(void) {
  uint64_t esr, elr, far;
  __asm volatile("mrs %0, esr_el3" : "=r"(esr));
  __asm volatile("mrs %0, elr_el3" : "=r"(elr));
  __asm volatile("mrs %0, far_el3" : "=r"(far));
  printf("[mon] sync exception: ESR_EL3=%08lX EC=0x%02lX ISS=0x%06lX ELR_EL3=%08lX FAR_EL3=%08lX\n",
         (unsigned long)esr, (unsigned long)(esr >> 26), (unsigned long)(esr & 0x1FFFFFFUL),
         (unsigned long)elr, (unsigned long)far);
  TEST_FAIL();
}

/* ---------------- monitor ---------------- */
static char line[96];
static int get_line(void) {
  int n = 0;
  for (;;) {
    uint8_t c = rx_byte(); g_rx_seen = 1;
    if (c == '\r' || c == '\n') { tx_byte('\r'); tx_byte('\n'); line[n] = 0; return n; }
    if ((c == 8 || c == 127) && n > 0) { n--; tx_byte(8); tx_byte(' '); tx_byte(8); continue; }
    if (c >= 32 && c < 127 && n < (int)sizeof(line) - 1) { line[n++] = (char)c; tx_byte(c); }
  }
}
static int split(char *s, char **argv, int max) {
  int argc = 0;
  while (*s && argc < max) {
    while (*s == ' ') s++;
    if (!*s) break;
    argv[argc++] = s;
    while (*s && *s != ' ') s++;
    if (*s) *s++ = 0;
  }
  return argc;
}
static uint32_t hex(const char *s) {
  uint32_t v = 0;
  if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s += 2;
  for (; *s; s++) {
    char c = *s; uint32_t d;
    if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
    else if (c >= 'a' && c <= 'f') d = (uint32_t)(c - 'a' + 10);
    else if (c >= 'A' && c <= 'F') d = (uint32_t)(c - 'A' + 10);
    else break;
    v = (v << 4) | d;
  }
  return v;
}
static void help(void) {
  printf("commands (hex args):\n"
         " r A        read word      | w A V      write word    | x A N    dump N words\n"
         " c CMD [A] [D0 D1 D2 D3]   raw SPI_CMD (no Enable bit), optional addr + write words\n"
         " j          JEDEC id       | q 0|1      controller QIO | i        SR1/SR2/CTRL/STATUS\n"
         " s 0        SPI XIP 0Bh/8 dummy      | s 1 [P]   Winbond QPI (C0h P=0..3) + XIP 0Bh\n"
         " s 2 [P]    Winbond QPI + XIP EBh continuous (mode A0, No_CMD)   | s 9   exit QPI\n"
         " e A        erase 4 KB sector at flash offset A\n"
         " p A N      program N bytes (<=1000, x16) at offset A: send N raw bytes + 4-byte LE sum\n"
         " m A N      load N bytes (<=1000) into memory at A: same wire format\n"
         " k A N      sum32 of N bytes read from address A (verify)\n"
         " g [A]      jump to A (default 400000) with the flash cache on | a   re-run auto start\n"
         " t          write-order probe on sector 3FF000 (only if erased)  | o M   set SPI write mapping 0..3\n"
         " b          production flash boot: SPI_STARTUP() then jump to 400000, flash cache untouched\n"
         " n [D] [1]  Winbond start-up (Daniel's draft), controller N_Dummy D (default 6), 1 = boot if image\n"
         " flash emulator store = 80080000..800FFFFF (flash offset 0..7FFFF); RAM = 80000000..8007FFFF\n");
}
static void info(void) {
  printf("[mon] CTRL=%08lX STATUS=%08lX AHB_CMD=%08lX CLK_DIV=%08lX CG092 CCR=%08lX SR=%08lX\n",
         (unsigned long)SL_QSPI->CTRL, (unsigned long)SL_QSPI->STATUS, (unsigned long)SL_QSPI->AHB_CMD,
         (unsigned long)SL_QSPI->CLK_DIV, (unsigned long)CG092->CCR, (unsigned long)CG092->SR);
  uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL &= ~(CTRL_XIP | CTRL_NOCMD);
  printf("[mon] SR1=%02X SR2=%02X SR3=%02X JEDEC=%06lX\n", sr1(), sr2(), cmd_rd1(0x15), (unsigned long)jedec());
  SL_QSPI->CTRL = saved;
}
static void jump_to(uint32_t a) {
  printf("***Flash Enabled...Booting*** -> %08lX\n\n", (unsigned long)a);
  cache_on();
  dsb(); __asm volatile("isb");
  ((void (*)(void))(uintptr_t)a)();
}
static void qpi_exit_any(void);
extern void QPI_READ_WORDS_no_data(SL_AHB_QSPI_TypeDef *SL_AHB_QSPI, uint32_t addr, uint8_t n_words, uint32_t n_dummy, uint8_t cont_read);
/* N38: the library SPI_WAIT_BUSY waits for BUSY to rise first and can miss a short transaction
   (a 2-clock QPI command). Wait for not-busy only, after a short delay. */
static void qspi_cmd_short(uint32_t cmd, const uint8_t *wd, int n) {
  if (wd) { uint32_t w = 0; for (int i = 0; i < n && i < 4; i++) w |= (uint32_t)wd[i] << (8 * i); SL_QSPI->WRITE_DATA[0] = w; }
  dsb();
  SL_QSPI->SPI_CMD = cmd & ~CMD_EN;
  SL_QSPI->SPI_CMD = cmd | CMD_EN;
  dsb();
  for (volatile int i = 0; i < 200; i++) { }
  for (uint32_t t = 0; t < 100000 && (SL_QSPI->STATUS & 1); t++) { }
  SL_QSPI->SPI_CMD = cmd & ~CMD_EN;
  dsb();
}

/* Winbond W25Qxx start-up, the sequence drafted for Daniel (SPI_STARTUP_winbond_branch.c):
   QE via the volatile SR2 write, 38h enter QPI, C0h P=3 (8 dummy clocks), EBh continuous read
   (mode A0, No_CMD), then XIP. ndummy = the controller's N_Dummy for EBh: 8 if the part counts
   its dummy clocks after the mode byte, 6 if the mode byte is part of them - 'n 8' / 'n 6' tell.
   Prints a 1-bit 03h reference read of the same 16 bytes first. Jumps to 0x400000 if go and the
   window starts with boot.s. Returns 0 if the window matches the reference. */
static int winbond_startup(int ndummy, int go) {
  /* Measured 19 Oct on the board: with C0h P=0x30 (8 dummy clocks) the right controller N_Dummy for EBh is 6 -
     the chip counts the 2 mode-byte clocks as part of its 8 (N_Dummy 8 returned the data one byte late).
     0Bh (no mode byte) needs N_Dummy 8. 38h, QPI JEDEC, C0h and continuous read all confirmed working.
     v5.2 (build 51): the v5 version used the library QPI_READ_WORDS_no_data, which hard-codes opcode 0Bh.
     In Winbond QPI mode 0Bh has no mode byte, so continuous-read mode was never entered and every No_CMD
     window read was an invalid command (window read CC.. = floating lines). Now: JEDEC check in QPI right
     after 38h (tells whether the chip entered QPI and whether IO2/IO3 work), C0h, then EBh + mode A0 by a
     direct SPI_CMD transaction, then the XIP window with AHB_CMD = EBh + the same dummy count. */
  uint8_t ref[16], rd[16], two = 0x02, p = 0x30;
  qpi_exit_any();
  SL_QSPI->CLK_DIV = 0x4; dsb();
  apb_read16(0, ref); hex16("ref 03h (1-bit)", ref);
  uint8_t s2 = sr2();
  if (!(s2 & 2)) {
    qspi_cmd(0x50, 0, 0, 0);                                  /* write enable for VOLATILE status register */
    qspi_cmd(0x31 | CMD_WR | CMD_NBYTES(1), 0, &two, 1);      /* SR2 = 02 (QE) */
    s2 = sr2();
  }
  printf("[mon] SR1=%02X SR2=%02X SR3=%02X (QE %s)\n", sr1(), s2, cmd_rd1(0x15), (s2 & 2) ? "set" : "NOT set");
  if (!(s2 & 2)) return -1;
  qspi_cmd(0x38, 0, 0, 0);                                    /* Enter QPI (chip) */
  set_qio(1);                                                 /* controller to 4-bit */
  qspi_cmd_short(0x9F | CMD_RD | CMD_NBYTES(4), 0, 0);
  uint32_t jq = SL_QSPI->READ_DATA[0] & 0xFFFFFFUL;
  printf("[mon] JEDEC read in QPI = %06lX (%s)\n", (unsigned long)jq, jq == g_id ? "chip in QPI, 4 lines OK" : "no valid 4-bit answer");
  if (jq != g_id) { qpi_exit_any(); return -2; }
  qspi_cmd_short(0xC0 | CMD_WR | CMD_NBYTES(1), &p, 1);       /* Set Read Parameters: P5:P4 = 11 -> 8 dummy */
  /* Fast Read Quad I/O EBh + 24-bit address + mode A0 (continuous) + ndummy clocks, 16 bytes */
  SL_QSPI->CTRL = CTRL_QIO | CTRL_CONT | CTRL_MODE(0xA0); dsb();
  SL_QSPI->SPI_ADDR = 0; dsb();
  qspi_cmd_short(0xEB | CMD_RD | CMD_ADDR | CMD_DUMMY(ndummy) | CMD_NBYTES(16), 0, 0);
  for (int i = 0; i < 16; i++) rd[i] = (uint8_t)(SL_QSPI->READ_DATA[i >> 2] >> (8 * (i & 3)));
  hex16("EBh direct (QPI)", rd);
  int same = 1; for (int i = 0; i < 16; i++) if (rd[i] != ref[i]) same = 0;
  printf("[mon] EBh N_Dummy %d: %s the 1-bit reference\n", ndummy, same ? "MATCHES" : "DIFFERS FROM");
  if (!same) { SL_QSPI->CTRL = CTRL_QIO; dsb(); qpi_exit_any(); return 1; }
  SL_QSPI->AHB_CMD = CMD_DUMMY(ndummy) | 0xEB; dsb();
  SL_QSPI->CTRL |= CTRL_NOCMD | CTRL_XIP; dsb();              /* chip is in continuous read: address-only reads */
  volatile uint32_t *f = (volatile uint32_t *)FLASH_WIN;
  for (int i = 0; i < 4; i++) { uint32_t w = f[i]; for (int k = 0; k < 4; k++) rd[4 * i + k] = (uint8_t)(w >> (8 * k)); }
  hex16("window (XIP, No_CMD)", rd);
  same = 1; for (int i = 0; i < 16; i++) if (rd[i] != ref[i]) same = 0;
  printf("[mon] Winbond QPI XIP, N_Dummy %d, CTRL=%08lX: window %s the 1-bit reference\n", ndummy, (unsigned long)SL_QSPI->CTRL, same ? "MATCHES" : "DIFFERS FROM");
  if (go && same && f[0] == 0xD2800000UL) {
    printf("***Flash Enabled...Booting***\n\n\n");
    dsb(); __asm volatile("isb");
    ((void (*)(void))(uintptr_t)FLASH_WIN)();
  }
  if (!same) { SL_QSPI->CTRL = CTRL_QIO; dsb(); qpi_exit_any(); }
  return same ? 0 : 1;
}

static void qpi_exit_any(void) {      /* leave QPI / continuous read on any SST/Winbond-like part */
  /* v5.2 (measured on the board, 19 Oct): a chip left in QPI *continuous-read* mode treats every short
     transaction as address nibbles, so 2-clock FFh commands never get it out. Sequence that works:
     1. 4-bit, 10 clocks of all ones (FFh + 4 x FF): in continuous mode = address FFFFFF + mode FF
        (M5:4 != 10 -> continuous mode ends); in plain QPI it is a harmless over-long FFh.
     2. 4-bit FFh (2 clocks): Exit QPI.    3. 1-bit 66h/99h: software reset (also clears volatile QE). */
  static const uint8_t ones[4] = {0xFF, 0xFF, 0xFF, 0xFF};
  SL_QSPI->CTRL = CTRL_QIO; dsb();
  qspi_cmd_short(0xFF | CMD_WR | CMD_NBYTES(4), ones, 4);
  qspi_cmd_short(0xFF, 0, 0);
  SL_QSPI->CTRL = 0; dsb();
  qspi_cmd(0x66, 0, 0, 0); qspi_cmd(0x99, 0, 0, 0);
  delay_loops(2000);
}
/* Same steps as bootloader.c main() after the banner, minus enable_caches (N25). */
static void prod_boot(void) {
  qpi_exit_any();
  SL_QSPI->CLK_DIV = 0x4; dsb();
  int rc = SPI_STARTUP(SL_QSPI);
  dsb();
  volatile uint32_t *f = (volatile uint32_t *)FLASH_WIN;
  uint32_t w0 = f[0], w1 = f[1], w2 = f[2], w3 = f[3];
  printf("[mon] SPI_STARTUP rc=%d CTRL=%08lX  flash[0..3]=%08lX %08lX %08lX %08lX\n", rc, (unsigned long)SL_QSPI->CTRL,
         (unsigned long)w0, (unsigned long)w1, (unsigned long)w2, (unsigned long)w3);
  if (rc == 0 && w0 == 0xD2800000UL) {
    printf("***Flash Enabled...Booting***\n\n\n");
    dsb(); __asm volatile("isb");
    ((void (*)(void))(uintptr_t)FLASH_WIN)();
  }
  printf("[mon] no boot.s image at 0x400000 (load one at 80080000, then 'b') - monitor\n");
  qpi_exit_any();
}

static void auto_start(void) {
  g_id = flash_identify();
  printf("[mon] JEDEC=%06lX (%s)\n", (unsigned long)g_id,
         (g_id & 0xFF) == 0xEF ? "Winbond" : (g_id & 0xFF) == 0xBF ? "SST" : (g_id & 0xFF) == 0x20 ? "Micron" : "unknown");
  printf("[mon] CG092 CCR=%08lX SR=%08lX  QSPI CTRL=%08lX\n", (unsigned long)CG092->CCR, (unsigned long)CG092->SR, (unsigned long)SL_QSPI->CTRL);
  { uint8_t b[16]; SL_QSPI->CTRL = 0; dsb(); apb_read16(0, b); hex16("flash[0..15] via APB 03h", b); }
  xip_spi();
  show_window("SPI XIP 0Bh/8");
  volatile uint32_t *f = (volatile uint32_t *)FLASH_WIN;
  uint32_t w0 = f[0];
  if ((g_id & 0xFF) == 0xEF) {        /* v5: Winbond start-up and boot (no automatic flash writes) */
    if (winbond_startup(6, 1) != 0) {
      printf("[mon] retrying with N_Dummy 8\n");
      (void)winbond_startup(8, 1);
    }
    qpi_exit_any();
    printf("[mon] Winbond: no bootable image - monitor\n");
    return;
  }
  if (0) {
    if (g_wrmode >= 0 && winbond_enter_qpi(3) == 0) {
      printf("[mon] QPI entered: SR1=%02X SR2=%02X\n", sr1(), sr2());
      xip_qpi(0x0B, 8, 0);  show_window("QPI XIP 0Bh/8");
      xip_qpi(0xEB, 8, 1);  show_window("QPI XIP EBh cont/A0 No_CMD");
      SL_QSPI->CTRL = CTRL_QIO;
      winbond_exit_qpi();
    }
    xip_spi();
    show_window("back to SPI XIP");
  }
  if ((g_id & 0xFF) == 0xBF) {        /* SST26VF064B (the in-FPGA emulator): production boot */
    SL_QSPI->CTRL = 0; dsb();
    prod_boot();
    return;
  }
  if (w0 == 0xD2800000UL) {           /* MOV x0,#0 - first instruction of SoC Labs boot.s */
    jump_to(FLASH_WIN);
  }
  printf("[mon] word0=%08lX is not a boot.s entry - monitor\n", (unsigned long)w0);
}

extern uint8_t SET_QIO_MODE_CMD;
int main(void) {
  /* N35: this ROM's RW/ZI region is never initialised - set every global explicitly */
  g_id = 0; g_rx_seen = 0; g_wrmode = 0; SET_QIO_MODE_CMD = 0x38;
  UartStdOutInit();
  printf("\n***SoCLabs MegaSoC***\n[mon] build 51 QSPI/flash monitor v5.2 (real W25Q32FW, fixed SPI writes), caches off\n");
  SL_QSPI->CLK_DIV = 0x4;
  g_id = flash_identify();
  printf("[mon] JEDEC=%06lX  press any key within ~3 s for the monitor\n", (unsigned long)g_id);
  if (rx_wait(3000000)) { g_rx_seen = 1; (void)rx_byte(); printf("[mon] rx ok\n"); }
  else auto_start();
  help();
  for (;;) {
    printf("> ");
    if (get_line() == 0) continue;
    char *av[8]; int ac = split(line, av, 8);
    if (ac == 0) continue;
    uint32_t a = ac > 1 ? hex(av[1]) : 0, n = ac > 2 ? hex(av[2]) : 0;
    switch (av[0][0]) {
      case 'h': help(); break;
      case 'r': printf("%08lX: %08lX\n", (unsigned long)a, (unsigned long)*(volatile uint32_t *)(uintptr_t)a); break;
      case 'w': *(volatile uint32_t *)(uintptr_t)a = n; printf("ok\n"); break;
      case 'x': for (uint32_t i = 0; i < n; i++) { if ((i & 3) == 0) printf("\n%08lX:", (unsigned long)(a + 4 * i)); printf(" %08lX", (unsigned long)*(volatile uint32_t *)(uintptr_t)(a + 4 * i)); } printf("\n"); break;
      case 'c': {
        uint32_t cmd = a, addr = ac > 2 ? n : 0; uint32_t wd[4] = {0, 0, 0, 0};
        for (int i = 0; i < 4 && ac > 3 + i; i++) wd[i] = hex(av[3 + i]);
        uint8_t bytes[16]; for (int i = 0; i < 16; i++) bytes[i] = (uint8_t)(wd[i >> 2] >> (8 * (i & 3)));
        uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL &= ~(CTRL_XIP | CTRL_NOCMD);
        qspi_cmd(cmd, addr, ac > 3 ? bytes : 0, 16);
        printf("READ_DATA: %08lX %08lX %08lX %08lX  STATUS=%08lX\n", (unsigned long)SL_QSPI->READ_DATA[0], (unsigned long)SL_QSPI->READ_DATA[1],
               (unsigned long)SL_QSPI->READ_DATA[2], (unsigned long)SL_QSPI->READ_DATA[3], (unsigned long)SL_QSPI->STATUS);
        SL_QSPI->CTRL = saved; break; }
      case 'j': { uint32_t saved = SL_QSPI->CTRL; SL_QSPI->CTRL &= ~(CTRL_XIP | CTRL_NOCMD); printf("JEDEC=%06lX\n", (unsigned long)jedec()); SL_QSPI->CTRL = saved; break; }
      case 'q': set_qio((int)a); printf("CTRL=%08lX\n", (unsigned long)SL_QSPI->CTRL); break;
      case 'i': info(); break;
      case 's':
        if (a == 0) { SL_QSPI->CTRL = 0; xip_spi(); show_window("SPI XIP 0Bh/8"); }
        else if (a == 1 || a == 2) { int p = ac > 2 ? (int)n : 3; SL_QSPI->CTRL = 0;
          if (winbond_enter_qpi(p) == 0) { printf("[mon] QPI entered, C0h P=%d\n", p); xip_qpi(a == 1 ? 0x0B : 0xEB, 2 * (p + 1), a == 2); show_window(a == 1 ? "QPI XIP 0Bh" : "QPI XIP EBh cont"); } }
        else if (a == 9) { SL_QSPI->CTRL = CTRL_QIO; winbond_exit_qpi(); printf("exited QPI, CTRL=%08lX\n", (unsigned long)SL_QSPI->CTRL); }
        break;
      case 'e': printf(flash_erase_4k(a) == 0 ? "OK\n" : "ERR timeout\n"); break;
      case 'p': case 'm': {
        if (n == 0 || n > LOAD_MAX || (av[0][0] == 'p' && (n & 15))) { printf("ERR size\n"); break; }
        uint8_t *dst = (av[0][0] == 'p') ? LOAD_BUF : (uint8_t *)(uintptr_t)a;
        tx_byte('+');
        int r = rx_block(dst, n);
        if (r == -1) { printf("ERR checksum\n"); break; }
        if (r == -2) { printf("ERR overrun\n"); break; }
        if (av[0][0] == 'p') r = flash_program(a, LOAD_BUF, n);
        printf(r == 0 ? "OK\n" : "ERR program\n"); break; }
      case 'k': printf("SUM=%08lX\n", (unsigned long)sum32(a, n)); break;
      case 'g': jump_to(ac > 1 ? a : FLASH_WIN); break;
      case 'a': auto_start(); break;
      case 'b': prod_boot(); break;
      case 'n': (void)winbond_startup(ac > 1 ? (int)a : 6, ac > 2 ? (int)n : 0); break;
      case 't': probe_write_order(); break;
      case 'o': g_wrmode = (int)a; printf("wrmode=%d\n", g_wrmode); break;
      default: printf("? (h for help)\n");
    }
  }
}
