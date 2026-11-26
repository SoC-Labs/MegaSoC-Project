// sd_mbw_tests.c - HAPS-SX, 25 November 2026: multi-block write statistics for MBT-72 and MBT-73.
//
//   1. sdio_init(), then the FIRST data operation of the session is a 2-block write (the MBT-73 shape).
//   2. For 2, 4, 8, 16 and 32 blocks: MBW_ITERS times { fill, sdio_write, sdio_read, compare }.
//
// The buffers are in the DDR4 (the on-chip SRAM of a flash image is 16 KB). The DMA reads and writes that memory
// behind the CPU's back, so the receive buffer is cleaned and invalidated before every read; the driver cleans the
// transmit buffer itself. Only the scratch sectors 0x1040..0x105F are written (unallocated gap before the FAT32
// partition at sector 8192). Build with -DSDIO_DEBUG=0: the driver then prints nothing per transfer.
#include "uart_stdout.h"
#include "system.h"
#include "sys_memory_map.h"
#include "system_level_functions.h"
#include "cpu_asm_codes.h"
#include <stdio.h>
#include "sdiodrv.h"
#include <stdint.h>
#include <string.h>

#ifndef MBW_ITERS
#define MBW_ITERS   20u
#endif
#define MBW_SECTOR  0x1040u
#define MBW_MAXBLK  32u
#define CNT_KHZ     20000u                      // generic counter: 20 MHz on the HAPS-SX

static SDIO    *SDIO_S   = (SDIO *)SYS_SDIO_BASE;
static SDIODRV *SDIO_DRV = NULL;
static uint8_t * const TX = (uint8_t *)0x80100000u;
static uint8_t * const RX = (uint8_t *)0x80200000u;

static uint64_t cnt(void) { uint64_t v; __asm volatile("mrs %0, cntpct_el0" : "=r"(v)); return v; }

static void clean_inval(const uint8_t *p, uint32_t len) {
    for (uint32_t o = 0; o < len; o += 64u) invalidateclean_cacheline((uint32_t *)(p + o));
}

// 0 = good, 1 = write error, 2 = read error, 3 = data mismatch
static int one(uint32_t count, uint32_t seed, uint32_t *ms_w, uint32_t *ms_r, uint32_t *st_cmd, uint32_t *st_dat) {
    uint32_t len = count * 512u;
    uint64_t t0, t1, t2;
    for (uint32_t i = 0; i < len; i++) TX[i] = (uint8_t)(seed * 31u + i * 7u + (i >> 9));
    memset(RX, 0xEE, len);
    clean_inval(RX, len);
    t0 = cnt();
    if (sdio_write(SDIO_DRV, MBW_SECTOR, count, (char *)TX) != 0) {
        *st_cmd = SDIO_S->sd_cmd; *st_dat = SDIO_S->sd_data; return 1;
    }
    t1 = cnt();
    if (sdio_read(SDIO_DRV, MBW_SECTOR, count, (char *)RX) != 0) {
        *st_cmd = SDIO_S->sd_cmd; *st_dat = SDIO_S->sd_data; return 2;
    }
    t2 = cnt();
    *ms_w += (uint32_t)((t1 - t0) / CNT_KHZ); *ms_r += (uint32_t)((t2 - t1) / CNT_KHZ);
    for (uint32_t i = 0; i < len; i++) if (RX[i] != TX[i]) { *st_cmd = i; *st_dat = ((uint32_t)RX[i] << 8) | TX[i]; return 3; }
    return 0;
}

int main(void) {
    static const uint32_t counts[] = { 2u, 4u, 8u, 16u, 32u };
    uint32_t total = 0, bad = 0, ms_w = 0, ms_r = 0, sc = 0, sd = 0;
    int r;

    UartStdOutInit();
    printf("MegaSoC SD multi-block write test (MBT-72, MBT-73)\n");
    SDIO_DRV = sdio_init(SDIO_S);
    if (SDIO_DRV == NULL) { printf("ERROR: sdio_init returned NULL\n"); TEST_FAIL(); return 1; }
    printf("init done, sd_phy = %08x, sd_cmd = %08x\n", (unsigned)SDIO_S->sd_phy, (unsigned)SDIO_S->sd_cmd);

    r = one(2u, 0x11u, &ms_w, &ms_r, &sc, &sd);
    printf("FIRST data operation after init = 2-block write: %s", (r == 0) ? "good" : (r == 1) ? "WRITE ERROR" : (r == 2) ? "READ ERROR" : "DATA MISMATCH");
    if (r != 0) printf(" (%08x:%08x)", (unsigned)sc, (unsigned)sd);
    printf("\n");
    total++; if (r != 0) bad++;

    for (uint32_t c = 0; c < sizeof(counts) / sizeof(counts[0]); c++) {
        uint32_t ew = 0, er = 0, ec = 0;
        ms_w = ms_r = 0;
        for (uint32_t it = 0; it < MBW_ITERS; it++) {
            r = one(counts[c], 0x100u * c + it, &ms_w, &ms_r, &sc, &sd);
            if (r == 1) ew++; else if (r == 2) er++; else if (r == 3) ec++;
            if (r != 0 && (ew + er + ec) <= 2u) printf("  blocks %u run %u: code %d (%08x:%08x)\n", (unsigned)counts[c], (unsigned)it, r, (unsigned)sc, (unsigned)sd);
        }
        total += MBW_ITERS; bad += ew + er + ec;
        printf("blocks %2u: %u runs, write errors %u, read errors %u, mismatches %u", (unsigned)counts[c], (unsigned)MBW_ITERS, (unsigned)ew, (unsigned)er, (unsigned)ec);
        printf(", good-run time write %u ms read %u ms\n", (unsigned)ms_w, (unsigned)ms_r);
    }
    printf("Total multi-block runs = %u, failed = %u\n", (unsigned)total, (unsigned)bad);
    if (bad == 0) { TEST_PASS(); } else { TEST_FAIL(); }
    return (int)bad;
}
