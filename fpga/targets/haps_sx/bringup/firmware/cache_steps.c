// FPGA bring-up scratch (2026-10-20, N25): enable the caches one bit at a time with a console checkpoint after each
// step, to see which side (instruction or data) stops the core.
#include "uart_stdout.h"
#include "system.h"
#include <stdio.h>
#include <stdint.h>
static inline uint64_t rd_sctlr(void) { uint64_t v; __asm volatile("mrs %0, sctlr_el3" : "=r"(v)); return v; }
static inline void wr_sctlr(uint64_t v) { __asm volatile("dsb sy\n\tmsr sctlr_el3, %0\n\tisb" :: "r"(v) : "memory"); }
static uint32_t work(uint32_t n) { uint32_t a = 0, b = 1; for (uint32_t i = 0; i < n; i++) { uint32_t t = a + b; a = b; b = t; } return a; }
static int memtest(volatile uint32_t *p, uint32_t words, uint32_t seed) {
  uint32_t x = seed, errors = 0;
  for (uint32_t i = 0; i < words; i++) { x = x * 1664525u + 1013904223u; p[i] = x; }
  x = seed;
  for (uint32_t i = 0; i < words; i++) { x = x * 1664525u + 1013904223u; if (p[i] != x) errors++; }
  return (int)errors;
}
int main(void) {
  UartStdOutInit();
  uint64_t s = rd_sctlr();
  printf("Cache steps - SoCLabs MegaSoC (FPGA scratch, N25)\nSCTLR_EL3 = %08lX (M=%d C=%d I=%d)\n", (unsigned long)s, (int)(s & 1), (int)((s >> 2) & 1), (int)((s >> 12) & 1));
  printf("step 1: ic iallu + dsb ... "); __asm volatile("ic iallu\n\tdsb sy\n\tisb" ::: "memory"); printf("ok\n");
  printf("step 2: SCTLR.I = 1 ... "); wr_sctlr(s | (1u << 12)); printf("ok, code with I-cache: "); printf("%08lX ", (unsigned long)work(50000)); printf("ok\n");
  printf("step 3: SCTLR.I = 0 ... "); wr_sctlr(s); printf("ok\n");
  printf("step 4: SCTLR.C = 1 (I off) ... "); wr_sctlr(s | (1u << 2)); printf("ok, SRAM 1 KB: "); printf("%d errors, ", memtest((volatile uint32_t *)0x00808000UL, 256, 0x77)); printf("RAM 64 KB: "); printf("%d errors\n", memtest((volatile uint32_t *)0x80020000UL, 16384, 0x99));
  printf("step 5: SCTLR.C = 0 ... "); wr_sctlr(s); printf("ok\n");
  printf("step 6: C = 1 and I = 1 ... "); wr_sctlr(s | (1u << 2) | (1u << 12)); printf("ok, RAM 64 KB: "); printf("%d errors\n", memtest((volatile uint32_t *)0x80020000UL, 16384, 0x33));
  wr_sctlr(s);
  printf("all steps done, caches off again\n");
  TEST_PASS();
}
