// FPGA bring-up scratch (2026-10-20, N25): enable the CPU caches the way bootloader.c does, then exercise memory
// and code with the caches on. On builds up to 52 the boot stopped right after enable_caches().
#include "uart_stdout.h"
#include "system.h"
#include "cpu_asm_codes.h"
#include <stdio.h>
#include <stdint.h>
extern void disable_caches(void);   /* platform.c */
static uint32_t lcg(uint32_t x) { return x * 1664525u + 1013904223u; }
static int memtest(volatile uint32_t *p, uint32_t words, uint32_t seed, const char *tag) {
  uint32_t x = seed, errors = 0;
  for (uint32_t i = 0; i < words; i++) { x = lcg(x); p[i] = x; }
  x = seed;
  for (uint32_t i = 0; i < words; i++) { x = lcg(x); if (p[i] != x) { if (errors < 4) printf("  %s mismatch @%p got %08lX exp %08lX\n", tag, (void *)&p[i], (unsigned long)p[i], (unsigned long)x); errors++; } }
  printf("%s: %lu words, %lu errors\n", tag, (unsigned long)words, (unsigned long)errors);
  return errors != 0;
}
static uint32_t fib(uint32_t n) { uint32_t a = 0, b = 1; for (uint32_t i = 0; i < n; i++) { uint32_t t = a + b; a = b; b = t; } return a; }
int main(void) {
  int errors = 0;
  UartStdOutInit();
  printf("Cache probe - SoCLabs MegaSoC (FPGA scratch, N25)\n");
  printf("SRAM test with caches off: "); errors += memtest((volatile uint32_t *)0x00808000UL, 1024, 0x1234, "SRAM/off");
  printf("enabling caches (EL3, SCTLR I+C) ...\n");
  enable_caches();
  printf("caches ON - still alive\n");
  errors += memtest((volatile uint32_t *)0x00808000UL, 2048, 0xBEEF, "SRAM/on");          /* 8 KB in SRAM */
  errors += memtest((volatile uint32_t *)0x80020000UL, 16384, 0xCAFE, "RAM/on");          /* 64 KB > L1 D (32 KB): L2 data RAM in play */
  errors += memtest((volatile uint32_t *)0x80020000UL, 16384, 0x5A5A, "RAM/on pass2");
  uint32_t f = fib(100000);
  printf("code loop with I-cache: fib(100000) mod 2^32 = %08lX (%s)\n", (unsigned long)f, f == 0x34164A7BUL ? "as expected" : "UNEXPECTED");
  if (f != 0x34164A7BUL) errors++;
  disable_caches();
  printf("caches off again\n");
  errors += memtest((volatile uint32_t *)0x80020000UL, 4096, 0x0F0F, "RAM/off after");
  if (errors) { TEST_FAIL(); } else { TEST_PASS(); }
}
