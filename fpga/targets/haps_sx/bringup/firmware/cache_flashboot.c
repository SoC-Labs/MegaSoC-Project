// FPGA bring-up scratch (2026-10-20, N25): the stock bootloader.c sequence with the caches ON, then boot the image
// in the on-board W25Q32FW from the XIP window - i.e. what the production boot ROM does, as a RAM program.
// Sequence: enable_caches(); enable_caches_el1(); Winbond start-up (QE, 38h, C0h P=30, EBh + mode A0, N_Dummy 6,
// AHB_CMD EBh/6, XIP No_CMD); check word 0 = boot.s; jump to 0x400000 with the flash cache (CG092) left in bypass.
#include "uart_stdout.h"
#include "system.h"
#include "cpu_asm_codes.h"
#include "qspi_flash.h"
#include <stdio.h>
#include <stdint.h>
#define Q ((SL_AHB_QSPI_TypeDef *)0x01000000UL)
#define EN   (1u << 8)
#define RD   (1u << 9)
#define WR   (1u << 10)
#define ADDR (1u << 11)
#define DUM(n) ((uint32_t)(n) << 12)
#define NB(n)  (((uint32_t)(n) - 1u) << 16)
static inline void dsb(void) { __asm volatile("dsb sy" ::: "memory"); }
static void cmd(uint32_t c) { Q->SPI_CMD = c & ~EN; Q->SPI_CMD = c | EN; dsb(); for (volatile int i = 0; i < 200; i++) { } for (uint32_t t = 0; t < 100000 && (Q->STATUS & 1); t++) { } Q->SPI_CMD = c & ~EN; dsb(); }
static uint8_t rd1(uint8_t op) { cmd(op | RD | NB(1)); return (uint8_t)(Q->READ_DATA[0] >> 24); }
int main(void) {
  UartStdOutInit();
  printf("Cache + flash boot probe - SoCLabs MegaSoC (FPGA scratch, N25)\n");
  enable_caches(); enable_caches_el1();
  printf("caches ON (EL3 + EL1)\n");
  Q->CLK_DIV = 4; dsb();
  /* leave any QPI/continuous state, reset the chip, 1-bit */
  Q->CTRL = 1; dsb(); Q->WRITE_DATA[0] = 0xFFFFFFFFu; cmd(0xFF | WR | NB(4)); cmd(0xFF); Q->CTRL = 0; dsb(); cmd(0x66); cmd(0x99);
  for (volatile int i = 0; i < 20000; i++) { }
  cmd(0x9F | RD | NB(4)); uint32_t id = Q->READ_DATA[0] & 0xFFFFFFu;
  printf("JEDEC %06lX\n", (unsigned long)id);
  if ((id & 0xFF) != 0xEF) { printf("not the Winbond part\n"); TEST_FAIL(); }
  cmd(0x50); Q->WRITE_DATA[0] = 0x02; cmd(0x31 | WR | NB(1));
  uint8_t s2 = rd1(0x35); printf("SR2 %02X (QE %s)\n", s2, (s2 & 2) ? "set" : "NOT set"); if (!(s2 & 2)) TEST_FAIL();
  cmd(0x38); Q->CTRL = 1; dsb();                                   /* chip and controller to 4-bit */
  cmd(0x9F | RD | NB(4)); printf("JEDEC in QPI %06lX\n", (unsigned long)(Q->READ_DATA[0] & 0xFFFFFFu));
  Q->WRITE_DATA[0] = 0x30; cmd(0xC0 | WR | NB(1));                 /* 8 dummy clocks */
  Q->CTRL = 1u | (1u << 24) | (0xA0u << 16); dsb(); Q->SPI_ADDR = 0; dsb();
  cmd(0xEB | RD | ADDR | DUM(6) | NB(16));                         /* enters continuous read */
  Q->AHB_CMD = DUM(6) | 0xEB; dsb();
  Q->CTRL |= (1u << 25) | (1u << 8); dsb();                        /* No_CMD + XiP */
  volatile uint32_t *f = (volatile uint32_t *)0x00400000UL;
  uint32_t w0 = f[0];
  printf("flash[0..3] = %08lX %08lX %08lX %08lX (caches on)\n", (unsigned long)w0, (unsigned long)f[1], (unsigned long)f[2], (unsigned long)f[3]);
  if (w0 != 0xD2800000UL) { printf("no boot.s image in the flash\n"); TEST_FAIL(); }
  printf("***Flash Enabled...Booting*** (caches on)\n\n\n");
  dsb(); __asm volatile("isb");
  ((void (*)(void))0x00400000UL)();
  TEST_FAIL();
}
