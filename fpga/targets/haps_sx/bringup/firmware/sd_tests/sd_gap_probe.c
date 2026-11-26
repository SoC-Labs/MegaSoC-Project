// sd_gap_probe.c - HAPS-SX, 25 November 2026: why do multi-block writes fail? (MBT-72, MBT-73, MBT-75)
//
// The card is initialised by the driver; everything after that is done register by register, without the DMA, so the
// program decides when each block goes out.
//   A. single block (CMD24): how long after the CRC status token does the CONTROLLER report the card busy (CARDBUSY),
//      and how long is the CARD really busy (CMD13 until READY_FOR_DATA in state tran)?
//   B. multi block (CMD25, one block sent): how long is the card busy BETWEEN blocks (CMD13 until READY_FOR_DATA)?
//   C. multi block (CMD25, two blocks): block 2 is sent GAP microseconds after the token of block 1. Does the card
//      answer it with a token, and is block 2 on the card afterwards?
//   D. the same two blocks through the controller's DMA (the driver's path), with the error latches cleared first.
// v2: B, C and D are run "warm" (straight after the previous write) and "cold" (after an idle pause), because the
// first run showed a card busy that is short between consecutive writes and long on the first write after a pause.
// Only the scratch sectors 0x1040 and 0x1041 are written. Build with -DSDIO_DEBUG=0.
#include "uart_stdout.h"
#include "system.h"
#include "sys_memory_map.h"
#include "system_level_functions.h"
#include "cpu_asm_codes.h"
#include <stdio.h>
#include "sdiodrv.h"
#include <stdint.h>
#include <string.h>

#define B_NULL     0x00000080u
#define B_CMD      0x00000040u
#define B_R1       0x00000100u
#define B_R1b      0x00000300u
#define B_WRITE    0x00000400u      // status: o_tx_en || r_tx_request
#define B_MEM      0x00000800u
#define B_FIFO     0x00001000u
#define B_DMA      0x00002000u
#define B_CMDBUSY  0x00004000u
#define B_ERR      0x00008000u
#define B_CARDBUSY 0x00100000u
#define B_XFERERR  0x00400000u      // status: r_transfer_err (token time-out or NAK on a write)
#define B_ECODE    0x00800000u      // status: 0 = no token, 1 = NAK token
#define B_ACK      0x04000000u
#define C_CMD24    ((B_CMD | B_R1b | B_ERR | B_ACK | B_WRITE | B_MEM) + 24u)
#define C_CMD25    ((B_CMD | B_R1b | B_ERR | B_ACK | B_WRITE | B_MEM) + 25u)
#define C_CMD25DMA ((B_CMD | B_R1b | B_ACK | B_WRITE | B_MEM | B_DMA) + 25u)   // the driver's SDIO_WRMULTI | SDIO_DMA
#define C_NEXTBLK  (B_WRITE | B_MEM | B_ACK)
#define C_CMD12    ((B_CMD | B_R1b | B_ERR) + 12u)
#define C_CMD13    ((B_CMD | B_R1  | B_ERR) + 13u)
#define SECTOR     0x1040u
#define TICKS_US   20u               // generic counter: 20 MHz
#ifndef PROBE_N
#define PROBE_N    10u
#endif

static SDIO    *sd = (SDIO *)SYS_SDIO_BASE;
static SDIODRV *drv = NULL;
static uint32_t blk[2][128];
static uint8_t  rb[512];

static uint64_t cnt(void) { uint64_t v; __asm volatile("mrs %0, cntpct_el0" : "=r"(v)); return v; }
static uint32_t us_since(uint64_t t0) { return (uint32_t)((cnt() - t0) / TICKS_US); }

// wait until none of the mask bits is set in the status; returns the last status, *t = counter at that moment
static uint32_t wait_clear(uint32_t mask, uint32_t tmo_us, uint64_t *t) {
    uint64_t t0 = cnt(); uint32_t st = sd->sd_cmd;
    while ((st & mask) && us_since(t0) < tmo_us) st = sd->sd_cmd;
    if (t) *t = cnt();
    return st;
}
static uint32_t cmd13(uint32_t *st) {
    sd->sd_data = (uint32_t)drv->d_RCA << 16; sd->sd_cmd = C_CMD13;
    *st = wait_clear(B_CMDBUSY, 5000u, NULL);
    return sd->sd_data;
}
// poll CMD13 until READY_FOR_DATA (and, if want_tran, state tran); returns microseconds since t0, 0xFFFFFFFF on time-out
static uint32_t card_ready_us(uint64_t t0, int want_tran, uint32_t tmo_us, uint32_t *last_r1) {
    uint32_t st, r1;
    for (;;) {
        r1 = cmd13(&st); *last_r1 = r1;
        if (!(st & B_ERR) && (r1 & 0x100u) && (!want_tran || ((r1 >> 9) & 0xFu) == 4u)) return us_since(t0);
        if (us_since(t0) > tmo_us) return 0xFFFFFFFFu;
    }
}
static void fill(uint32_t seed) {
    for (uint32_t b = 0; b < 2u; b++) for (uint32_t w = 0; w < 128u; w++) blk[b][w] = 0x9E3779B9u * (seed + b * 131u + w + 1u);
}
static void load_fifo(uint32_t b) {
    if (b & 1u) { for (uint32_t w = 0; w < 128u; w++) sd->sd_fifb = blk[1][w]; }
    else        { for (uint32_t w = 0; w < 128u; w++) sd->sd_fifa = blk[0][w]; }
}
// end a write session and bring the card back to tran; returns microseconds until ready
static uint32_t stop_and_settle(int send_cmd12) {
    uint32_t r1; uint64_t t0 = cnt();
    if (send_cmd12) { sd->sd_data = 0; sd->sd_cmd = C_CMD12; (void)wait_clear(B_CMDBUSY, 20000u, NULL); }
    uint32_t us = card_ready_us(t0, 1, 2000000u, &r1);
    sd->sd_cmd = B_ERR | B_NULL;                 // clear the error latches
    return us;
}
// is block b (0 or 1) of the current pattern on the card?  1 = yes, 0 = no, -1 = read error
static int on_card(uint32_t b) {
    if (sdio_read(drv, SECTOR + b, 1, (char *)rb) != 0) return -1;
    for (uint32_t w = 0; w < 128u; w++) {
        uint32_t v = (uint32_t)rb[4*w] | ((uint32_t)rb[4*w+1] << 8) | ((uint32_t)rb[4*w+2] << 16) | ((uint32_t)rb[4*w+3] << 24);
        if (v != blk[b][w]) return 0;
    }
    return 1;
}
static void stats(const char *what, const uint32_t *v, uint32_t n) {
    uint32_t mn = 0xFFFFFFFFu, mx = 0, to = 0; uint64_t sum = 0; uint32_t m = 0;
    for (uint32_t i = 0; i < n; i++) { if (v[i] == 0xFFFFFFFFu) { to++; continue; } if (v[i] < mn) mn = v[i]; if (v[i] > mx) mx = v[i]; sum += v[i]; m++; }
    printf("  %s: n=%u min %u avg %u max %u us", what, (unsigned)m, (unsigned)(m ? mn : 0), (unsigned)(m ? sum / m : 0), (unsigned)mx);
    if (to) printf(", %u timed out", (unsigned)to);
    printf("\n");
}

static void pause_us(uint32_t us) { uint64_t t0 = cnt(); while (us_since(t0) < us) { } }
static void list(const char *what, const uint32_t *v, uint32_t n) {
    printf("  %s:", what);
    for (uint32_t i = 0; i < n; i++) { if (v[i] == 0xFFFFFFFFu) printf(" T/O"); else printf(" %u", (unsigned)v[i]); }
    printf("\n");
}
static uint8_t * const DTX = (uint8_t *)0x80100000u;

int main(void) {
    static const uint32_t pauses[] = { 0u, 1000u, 5000u, 20000u, 100000u };
    static const uint32_t gaps[]   = { 0u, 300u, 600u, 1000u, 1500u, 2000u, 3000u };
    uint32_t a[PROBE_N], c[PROBE_N], r1, st; uint64_t t0, t1;

    UartStdOutInit();
    printf("MegaSoC SD write gap probe v2 (MBT-72/73/75)\n");
    drv = sdio_init(sd);
    if (drv == NULL) { printf("ERROR: sdio_init returned NULL\n"); TEST_FAIL(); return 1; }
    printf("init done, sd_phy = %08x, RCA %04x\n", (unsigned)sd->sd_phy, (unsigned)drv->d_RCA);
    (void)stop_and_settle(0);

    // ---- A. single block: controller's CARDBUSY against the card's real busy
    printf("A. single-block write (CMD24), microseconds from the CRC status token:\n");
    for (uint32_t i = 0; i < PROBE_N; i++) {
        fill(0x100u + i); load_fifo(0);
        sd->sd_data = SECTOR; sd->sd_cmd = C_CMD24;
        st = wait_clear(B_CMDBUSY | B_WRITE, 50000u, &t0);
        if (st & B_ERR) printf("  run %u: CMD24 status %08x\n", (unsigned)i, (unsigned)st);
        (void)wait_clear(B_CARDBUSY, 2000000u, &t1); a[i] = (uint32_t)((t1 - t0) / TICKS_US);
        c[i] = card_ready_us(t0, 1, 2000000u, &r1);
        sd->sd_cmd = B_ERR | B_NULL;
    }
    list("controller CARDBUSY for", a, PROBE_N);
    list("card ready (CMD13 READY_FOR_DATA, tran) after", c, PROBE_N);

    // ---- B. one block of a multi-block write: the card's busy before it can take block 2, against the idle time before
    printf("B. CMD25, one block sent: card ready for block 2 (CMD13 READY_FOR_DATA), us from the token, %u runs:\n", (unsigned)PROBE_N);
    for (uint32_t p = 0; p < sizeof(pauses) / sizeof(pauses[0]); p++) {
        for (uint32_t i = 0; i < PROBE_N; i++) {
            fill(0x200u + 16u * p + i); load_fifo(0);
            pause_us(pauses[p]);
            sd->sd_data = SECTOR; sd->sd_cmd = C_CMD25;
            st = wait_clear(B_CMDBUSY | B_WRITE, 50000u, &t0);
            c[i] = (st & B_ERR) ? 0xFFFFFFFFu : card_ready_us(t0, 0, 2000000u, &r1);
            (void)stop_and_settle(1);
        }
        printf("  idle %6u us before the write", (unsigned)pauses[p]); list("", c, PROBE_N);
    }

    // ---- C. two blocks, block 2 requested GAP us after the token of block 1; warm and cold
    for (uint32_t cold = 0; cold < 2u; cold++) {
        printf("C. CMD25 two blocks by FIFO, block 2 requested GAP us after the token of block 1, %s (%u runs per gap):\n",
               cold ? "COLD: 20 ms idle before each write" : "WARM: no pause between writes", (unsigned)PROBE_N);
        for (uint32_t g = 0; g < sizeof(gaps) / sizeof(gaps[0]); g++) {
            uint32_t tok_err = 0, nak = 0, kept = 0, lost = 0, other = 0, mask = 0;
            for (uint32_t i = 0; i < PROBE_N; i++) {
                fill(0x1000u * (g + 1u) + 64u * cold + i);
                load_fifo(0);
                if (cold) pause_us(20000u);
                sd->sd_data = SECTOR; sd->sd_cmd = C_CMD25;
                load_fifo(1);
                st = wait_clear(B_CMDBUSY | B_WRITE, 50000u, &t0);
                if (st & B_ERR) { other++; (void)stop_and_settle(1); continue; }
                while (us_since(t0) < gaps[g]) { }
                sd->sd_cmd = C_NEXTBLK | B_FIFO;
                st = wait_clear(B_WRITE, 100000u, NULL);
                if (st & B_XFERERR) { if (st & B_ECODE) nak++; else tok_err++; mask |= 1u << i; }
                (void)stop_and_settle(1);
                { int k = on_card(1); if (k == 1) kept++; else if (k == 0) lost++; else other++; }
            }
            printf("  gap %5u us: no token %2u, NAK %u, block 2 on card %2u, not on card %2u, failing runs mask %03x", (unsigned)gaps[g], (unsigned)tok_err, (unsigned)nak, (unsigned)kept, (unsigned)lost, (unsigned)mask);
            if (other) printf(", other errors %u", (unsigned)other);
            printf("\n");
        }
    }

    // ---- D. two blocks through the DMA, as the driver does it
    for (uint32_t cold = 0; cold < 2u; cold++) {
        printf("D. CMD25 two blocks by DMA, %s:\n", cold ? "COLD: 20 ms idle before each write" : "WARM: no pause between writes");
        for (uint32_t i = 0; i < PROBE_N; i++) {
            uint32_t pre, dur, adr; int k0, k1;
            fill(0x9000u + 64u * cold + i);
            memcpy(DTX, blk, 1024u);
            for (uint32_t o = 0; o < 1024u; o += 64u) invalidateclean_cacheline((uint32_t *)(DTX + o));
            sd->sd_cmd = B_ERR | B_NULL; pre = sd->sd_cmd;                 // error latches must be clear before the DMA is armed
            if (cold) pause_us(20000u);
            sd->sd_dma_addr_lo = (uint32_t)(uintptr_t)DTX; sd->sd_dma_addr_hi = 0; sd->sd_dma_length = 2u;
            sd->sd_data = SECTOR;
            t0 = cnt(); sd->sd_cmd = C_CMD25DMA;
            st = wait_clear(B_DMA | B_CMDBUSY | B_WRITE | B_MEM, 200000u, NULL); dur = us_since(t0);
            r1 = sd->sd_data; adr = sd->sd_dma_addr_lo;
            if (stop_and_settle(0) == 0xFFFFFFFFu) (void)stop_and_settle(1);
            k0 = on_card(0); k1 = on_card(1);
            printf("  run %u: before %08x, after %08x, %5u us, R1 %08x, DMA addr +%u, block 1 on card %d, block 2 on card %d\n",
                   (unsigned)i, (unsigned)pre, (unsigned)st, (unsigned)dur, (unsigned)r1, (unsigned)(adr - (uint32_t)(uintptr_t)DTX), k0, k1);
        }
    }
    printf("probe done\n");
    TEST_PASS();
    return 0;
}
