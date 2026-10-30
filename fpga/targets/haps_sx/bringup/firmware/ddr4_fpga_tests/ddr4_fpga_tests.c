//-----------------------------------------------------------------------------
// ddr4_fpga_tests - MegaSoC on HAPS-SX: the on-board DDR4 SODIMM behind the NIC-400 DRAM port
// (MGSOC-34 step 2, build 58, 28 October 2026).
//
// The DRAM window is 0x8000_0000-0x2_7FFF_FFFF (8 GB = rank 0 of the 16 GB DIMM); the bridge
// passes the low 33 address bits to the Xilinx DDR4 IP, so CPU 0x8000_0000.. maps to DRAM 2 GB..
// and CPU 0x2_0000_0000.. to DRAM 0..2 GB. The firmware page table maps 2-4 GB Normal write-back
// cacheable and everything above 4 GB Device-nGnRnE (so accesses there go straight to the bus) - but the
// library's enable_mmu() limits TCR_EL3 to 4 GB of VA and 32-bit PA (T0SZ 32, PS 0), so this test first
// widens TCR_EL3 to 39-bit VA / 40-bit PA (mmu_extend); without it any access above 4 GB is a level-0
// translation fault (seen on build 58, 29 October 2026).
//
//  T1 words      64 KB at +1 MB: fixed patterns and address-as-data, clean+invalidate, read back
//  T2 address    one cell per address bit 3..32 (from a +2 MB base, clear of the RAM image at
//                0x8000_0000) plus the 0x2_0000_0000 alias of DRAM offset 0 and the last word of the
//                window: all written first, all verified after -> any aliasing / stuck address bit shows
//  T3 block      4 MB at +4 MB, hashed pattern then its inverse, through the caches (exceeds the 256 KB L2,
//                so evictions interleave with the fills); 512 KB if the caches could not be enabled (an
//                uncached run from the flash XIP window is ~30x slower and the board auto-resets ~3.5 min
//                after the last console byte)
//  T4 strobes    8/16/32-bit stores to Device memory (>4 GB) -> narrow AXI writes and WSTRB/DM lanes
//  T5 L2 ways    lines sharing one L2 set (same address bits 13:6, tags differing in bits 14..30) written and read
//                back while cache-resident (no DRAM in a hit), then from DRAM after clean+invalidate: a false hit
//                shows as "got <address of another line>" - L2 tag fault vs DRAM path (build 58 run 3 diagnosis)
//  T6 paths      1 MB written cached and verified with the data cache OFF (DRAM holds what the bursts wrote?),
//                then written uncached and verified cached (line fills right?)
//  T8 DDR4 evict 64 KB of dirty DDR4 lines evicted by a 512 KB read sweep (eviction write-backs while reads are in
//                flight, no write streaming), verified from DRAM
//  T7 SRAM evict (RAM image only) the on-chip SRAM remapped Normal cacheable, 32 KB dirtied, evicted by the same
//                read sweep: the DRAM port carries reads only, so a wrong SRAM word indicts the L2, not the bridge.
//                Cells 0x808000-0x80FFFF: the NIC-400 decodes only 64 KB of RAM at 0x800000 (asib_A53 decode_int[2],
//                memory_map.xml range 0x10000) although the FPGA SRAM wrapper holds 128 KB. v7 used 0x810000, which is
//                unmapped: the default slave answered the write-allocate line fill with DECERR, reported asynchronously
//                -> SError ESR_EL3 BF000000 right after the pgtbl2 line (builds 58 and 59, 29-30 October 2026)
//  code          (RAM image) this program itself is fetched from DDR4 at 0x8000_0000
//
// Run: RAM image (dram scatter) with  haps_qspi.py suite ddr4_fpga_tests_dram.bin  (load at 80000000, 'g');
//      flash image with  haps_qspi.py suite --winbond ddr4_fpga_tests_flash.bin  (code from flash, data in DDR4).
// Expected: "** TEST PASSED **". Any mismatch prints address / expected / got.
//
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
// Contributors: Anastasios Dimitriou (ad1u25@soton.ac.uk)
//-----------------------------------------------------------------------------
#include "uart_stdout.h"
#include "system.h"
#include <stdio.h>
#include <stdint.h>

#define DRAM_BASE   0x80000000UL
#define DEV_BASE    0x100000000UL           // first Device-mapped DRAM address (4 GB)
#define ALIAS_BASE  0x200000000UL           // CPU address of DRAM offset 0 (address bit 33 dropped by the bridge)
#define MAX_PRINT   4

static inline void     wr64(uintptr_t a, uint64_t v) { *(volatile uint64_t *)a = v; }
static inline uint64_t rd64(uintptr_t a)             { return *(volatile uint64_t *)a; }
static inline void     dsb(void)                     { __asm volatile("dsb sy" ::: "memory"); }
static inline void     dc_civac(uintptr_t a)         { __asm volatile("dc civac, %0" :: "r"(a) : "memory"); }
static void clean_inv(uintptr_t a, uint64_t n) {     // clean + invalidate [a, a+n) by cache line, Normal memory only
    if (a >= DEV_BASE) return;
    for (uintptr_t p = a & ~63UL; p < a + n; p += 64) dc_civac(p);
    dsb();
}
// TCR_EL3 as programmed by the library: 0x00102F20 = T0SZ 32 (4 GB VA), PS 0 (32-bit PA), TBI, 4 KB granule.
// The level-1 table (pgtbl1, 512 x 1 GB) already describes 512 GB, so widen the walk: T0SZ 25 (39-bit VA) and
// PS 0b010 (40-bit PA = the Cortex-A53 PARange). Done with the MMU on: the code and data stay mapped by the same
// unchanged entries, so a context synchronisation plus a TLB invalidate is all that is needed.
static void mmu_extend(void) {
    uint64_t tcr, tcr_new;
    __asm volatile("mrs %0, tcr_el3" : "=r"(tcr));
    tcr_new = (tcr & ~0x7003FUL) | (2UL << 16) | 25UL;
    __asm volatile("msr tcr_el3, %0 \n\t isb \n\t tlbi alle3 \n\t dsb sy \n\t isb" :: "r"(tcr_new) : "memory");
    printf("TCR_EL3 %08lx -> %08lx (VA 39-bit, PA 40-bit: DRAM window above 4 GB reachable)\n", (unsigned long)tcr, (unsigned long)tcr_new);
}
static uint64_t mix(uint64_t x) {                    // 64-bit hash (splitmix finaliser) - address -> pattern
    x ^= x >> 33; x *= 0xff51afd7ed558ccdULL; x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53ULL; x ^= x >> 33; return x;
}
static uint32_t total_errors;
static int from_flash;                               // code fetched through the QSPI XIP window (flash image)
static int caches_on;                                // SCTLR_EL3.C and .I both set when the tests start
extern void enable_caches(void);                     // lib cpu_asm_codes.c: SCTLR_EL3 |= C | I (boot.s only enables the MMU)
__attribute__((weak)) extern char Image$$RW$$Base[], Image$$ZI$$Limit[];   // RW+ZI of the RAM image (dram.scat); the
                                                     // flash image's scatter names them differently -> weak = 0 = skipped
static void dcache(int on) {                         // SCTLR_EL3.C; caller has cleaned/invalidated what matters
    uint64_t sc; __asm volatile("mrs %0, sctlr_el3" : "=r"(sc));
    sc = on ? (sc | 4UL) : (sc & ~4UL);
    __asm volatile("dsb sy \n\t msr sctlr_el3, %0 \n\t isb" :: "r"(sc) : "memory");
}
static uint64_t cnt_frq;                             // CNTFRQ_EL0 (0 if the generic timer is not set up)
static uint64_t ticks(void) { uint64_t t; __asm volatile("isb \n\t mrs %0, cntpct_el0" : "=r"(t)); return t; }
static void lap(const char *tag, uint64_t t0) {      // elapsed time of one test, for the flash-vs-DDR4 speed comparison
    uint64_t dt = ticks() - t0;
    if (cnt_frq) printf("            %s took %lu ms\n", tag, (unsigned long)(dt * 1000 / cnt_frq));
    else         printf("            %s took %lu ticks\n", tag, (unsigned long)dt);
}
static uint32_t check64(const char *tag, uintptr_t a, uint64_t exp, uint32_t *shown) {
    uint64_t got = rd64(a);
    if (got == exp) return 0;
    if ((*shown)++ < MAX_PRINT) printf("  %s MISMATCH @%09lx exp %016lx got %016lx\n", tag, (unsigned long)a, (unsigned long)exp, (unsigned long)got);
    return 1;
}

// ---- T1: 64 KB of patterns, verified from DRAM ----
static uint32_t t1_words(void) {
    const uintptr_t base = DRAM_BASE + 0x100000; const uint64_t n = 0x10000;
    static const uint64_t pat[4] = {0, ~0UL, 0x5555555555555555UL, 0xAAAAAAAAAAAAAAAAUL};
    uint32_t err = 0, shown = 0;
    for (int p = 0; p < 5; p++) {
        for (uintptr_t a = base; a < base + n; a += 8) wr64(a, p < 4 ? pat[p] : (uint64_t)a);
        dsb(); clean_inv(base, n);
        for (uintptr_t a = base; a < base + n; a += 8) err += check64("T1", a, p < 4 ? pat[p] : (uint64_t)a, &shown);
    }
    printf("T1 words    64 KB x 5 patterns: %lu errors\n", (unsigned long)err);
    return err;
}

// ---- T2: one cell per address bit, all written before any is verified ----
// The cells sit at +2 MB + 2^k, not at DRAM_BASE + 2^k: the RAM image occupies 0x8000_0000..+66 KB, so cells
// for bits 3..16 placed from DRAM_BASE overwrite the running program (vectors at +0x200 included) - the first
// build 58 run hung exactly so. +2 MB + 2^k still toggles one distinct address bit per cell against the base.
static uint32_t t2_address(void) {
    const uintptr_t t2b = DRAM_BASE + 0x200000;
    uint32_t err = 0, shown = 0, cells = 0;
    uintptr_t cell[40]; uint64_t val[40];
    cell[cells] = t2b; val[cells] = mix(0x100); cells++;                            // reference cell (+2 MB)
    for (int k = 3; k <= 32; k++) { cell[cells] = t2b + (1UL << k); val[cells] = mix(k); cells++; }
    cell[cells] = ALIAS_BASE; val[cells] = mix(0x33); cells++;                      // DRAM offset 0 (bit 33 dropped)
    cell[cells] = ALIAS_BASE + 0x7FFFFFF8UL; val[cells] = mix(0x34); cells++;      // last word of the window
    for (uint32_t i = 0; i < cells; i++) wr64(cell[i], val[i]);
    dsb();
    for (uint32_t i = 0; i < cells; i++) clean_inv(cell[i], 8);
    for (uint32_t i = 0; i < cells; i++) err += check64("T2", cell[i], val[i], &shown);
    // and the inverse, to catch a stuck data bit coinciding with the hash
    for (uint32_t i = 0; i < cells; i++) wr64(cell[i], ~val[i]);
    dsb();
    for (uint32_t i = 0; i < cells; i++) clean_inv(cell[i], 8);
    for (uint32_t i = 0; i < cells; i++) err += check64("T2", cell[i], ~val[i], &shown);
    printf("T2 address  %lu cells (+2 MB + bit 3..32, alias of offset 0, top of window): %lu errors\n", (unsigned long)cells, (unsigned long)err);
    return err;
}

// ---- T3: 4 MB block through the caches, hashed pattern and its inverse ----
static uint32_t t3_block(void) {
    const uintptr_t base = DRAM_BASE + 0x400000; const uint64_t n = caches_on ? 0x400000 : 0x80000;
    uint32_t err = 0, shown = 0;
    for (int pass = 0; pass < 2; pass++) {
        uint64_t t0 = ticks();
        for (uintptr_t a = base; a < base + n; a += 8) wr64(a, pass ? ~mix(a) : mix(a));
        dsb(); clean_inv(base, n);
        lap(pass ? "  T3 pass 1 write+clean" : "  T3 pass 0 write+clean", t0);   // progress: shows the run is alive
        for (uintptr_t a = base; a < base + n; a += 8) err += check64("T3", a, pass ? ~mix(a) : mix(a), &shown);
    }
    printf("T3 block    %lu KB x 2 passes: %lu errors\n", (unsigned long)(n >> 10), (unsigned long)err);
    return err;
}

// ---- T4: narrow stores on Device memory -> partial write strobes through the width converter ----
static uint32_t t4_strobes(void) {
    const uintptr_t base = DEV_BASE + 0x1000;   // 4 GB + 4 KB, Device-nGnRnE: every store is its own AXI write
    uint32_t err = 0, shown = 0;
    volatile uint8_t  *b8  = (volatile uint8_t  *)base;
    volatile uint16_t *b16 = (volatile uint16_t *)(base + 64);
    volatile uint32_t *b32 = (volatile uint32_t *)(base + 128);
    for (int i = 0; i < 64; i++) wr64(base + i * 8, 0xDEADBEEFCAFEF00DUL);       // background in all three rows
    dsb();
    for (int i = 0; i < 64; i++) b8[i]  = (uint8_t)(0x10 + i);
    for (int i = 0; i < 32; i++) b16[i] = (uint16_t)(0x2000 + i * 0x101);
    for (int i = 0; i < 16; i++) b32[i] = 0x30000000UL + i * 0x01010101UL;
    dsb();
    for (int w = 0; w < 8; w++) {
        uint64_t e8 = 0, e16 = 0, e32 = 0;
        for (int j = 7; j >= 0; j--) e8 = (e8 << 8) | (uint8_t)(0x10 + w * 8 + j);
        for (int j = 3; j >= 0; j--) e16 = (e16 << 16) | (uint16_t)(0x2000 + (w * 4 + j) * 0x101);
        for (int j = 1; j >= 0; j--) e32 = (e32 << 32) | (0x30000000UL + (w * 2 + j) * 0x01010101UL);
        err += check64("T4.8",  base + w * 8,       e8,  &shown);
        err += check64("T4.16", base + 64 + w * 8,  e16, &shown);
        err += check64("T4.32", base + 128 + w * 8, e32, &shown);
    }
    // byte reads of a 64-bit write
    wr64(base + 256, 0x0807060504030201UL); dsb();
    for (int i = 0; i < 8; i++) if (b8[256 + i] != (uint8_t)(i + 1)) { err++; if (shown++ < MAX_PRINT) printf("  T4.rd8 MISMATCH byte %d got %02x\n", i, b8[256 + i]); }
    printf("T4 strobes  8/16/32-bit stores and byte reads on Device memory: %lu errors\n", (unsigned long)err);
    return err;
}

// ---- T5: L2 way aliasing, cache-resident ----
static uint32_t t5_l2ways(int kmax) {
    const uintptr_t b = DRAM_BASE + 0x1000000;       // +16 MB; every line below has address bits 13:6 = 0 (same L2 set)
    uintptr_t ln[20]; uint32_t nl = 0, err = 0, shown = 0;
    ln[nl++] = b;
    for (int k = 14; k <= kmax; k++) ln[nl++] = b + (1UL << k);
    for (uint32_t i = 0; i < nl; i++) { wr64(ln[i], ln[i]); wr64(ln[i] + 8, ~(uint64_t)ln[i]); }
    dsb();
    for (uint32_t i = 0; i < nl; i++) { err += check64("T5.res", ln[i], ln[i], &shown); err += check64("T5.res", ln[i] + 8, ~(uint64_t)ln[i], &shown); }
    uint32_t err_res = err;
    for (uint32_t i = 0; i < nl; i++) clean_inv(ln[i], 64);
    for (uint32_t i = 0; i < nl; i++) { err += check64("T5.dram", ln[i], ln[i], &shown); err += check64("T5.dram", ln[i] + 8, ~(uint64_t)ln[i], &shown); }
    printf("T5 L2 ways  %lu lines in one L2 set (tags differ in bits 14..%d): %lu errors resident, %lu from DRAM\n",
           (unsigned long)nl, kmax, (unsigned long)err_res, (unsigned long)(err - err_res));
    return err;
}

// ---- T6: cached writes verified uncached, uncached writes verified cached ----
static uint32_t t6_paths(void) {
    const uintptr_t base = DRAM_BASE + 0x2000000; const uint64_t n = 0x100000;
    uint32_t errA = 0, errB = 0, shown = 0;
    for (uintptr_t a = base; a < base + n; a += 8) wr64(a, mix(a));          // cached: fills, evictions, write-backs
    dsb(); clean_inv(base, n);
    uintptr_t rw = (uintptr_t)Image$$RW$$Base, rwe = (uintptr_t)Image$$ZI$$Limit;
    if (rw && rw >= DRAM_BASE && rw < DEV_BASE) clean_inv(rw, rwe - rw);    // RAM image: no dirty RW lines left behind
    dcache(0);                                                                  // data accesses now bypass the caches
    for (uintptr_t a = base; a < base + n; a += 8) errA += check64("T6.A", a, mix(a), &shown);
    for (uintptr_t a = base; a < base + n; a += 8) wr64(a, ~mix(a));         // uncached single writes
    dsb();
    dcache(1);
    for (uintptr_t a = base; a < base + n; a += 8) errB += check64("T6.B", a, ~mix(a), &shown);   // cached line fills
    printf("T6 paths    1 MB: cached writes read uncached %lu errors, uncached writes read cached %lu errors\n",
           (unsigned long)errA, (unsigned long)errB);
    return errA + errB;
}

// ---- T8: dirty DDR4 lines evicted by allocation (read sweep), verified from DRAM ----
static uint32_t t8_ddr_evict(void) {
    const uintptr_t A = DRAM_BASE + 0x2800000; const uint64_t n = 0x10000;     // 64 KB dirty lines (4 per L2 set)
    const uintptr_t R = DRAM_BASE + 0x3000000; const uint64_t rn = 0x80000;    // 512 KB sweep = 2x the L2
    uint32_t err = 0, shown = 0; uint64_t sink = 0;
    for (uintptr_t a = A; a < A + n; a += 8) wr64(a, ~mix(a));
    dsb();
    for (uintptr_t a = R; a < R + rn; a += 64) sink += rd64(a);               // fills evict the dirty lines
    dsb(); clean_inv(A, n);
    for (uintptr_t a = A; a < A + n; a += 8) err += check64("T8", a, ~mix(a), &shown);
    printf("T8 DDR4 ev  64 KB dirty, evicted by a 512 KB read sweep, verified from DRAM: %lu errors (sink %02lx)\n",
           (unsigned long)err, (unsigned long)(sink & 0xff));
    return err;
}

// ---- T7: dirty SRAM lines evicted by the same read sweep (RAM image only: the page table must be writable) ----
extern uint64_t pgtbl2[];                            // library level-2 table, 2 MB blocks; [4] = 8-10 MB = on-chip SRAM
static uint32_t t7_sram_evict(void) {
    if (from_flash) { printf("T7 SRAM ev  skipped (page table in flash)\n"); return 0; }
    const uintptr_t S = 0x00808000; const uint64_t n = 0x8000;                // upper 32 KB of the 64 KB NIC-400 RAM window
                                                                                // (stack/heap 0x800000-0x803FFF, mem_tests cell 0x806000)
    const uintptr_t R = DRAM_BASE + 0x3000000; const uint64_t rn = 0x80000;
    uint64_t d = pgtbl2[4];
    pgtbl2[4] = d & ~(7UL << 2);                                                // AttrIndx 2 (Device) -> 0 (Normal WB)
    __asm volatile("dsb sy \n\t tlbi alle3 \n\t dsb sy \n\t isb" ::: "memory");
    printf("T7: pgtbl2[4] %016lx -> %016lx (SRAM Normal WB cacheable from here on)\n", (unsigned long)d, (unsigned long)pgtbl2[4]);
    uint32_t err = 0, shown = 0; uint64_t sink = 0;
    for (uintptr_t a = S; a < S + n; a += 8) wr64(a, mix(a));
    dsb();
    for (uintptr_t a = R; a < R + rn; a += 64) sink += rd64(a);               // DDR4 reads only; SRAM lines written back
    dsb(); clean_inv(S, n);
    for (uintptr_t a = S; a < S + n; a += 8) err += check64("T7", a, mix(a), &shown);
    printf("T7 SRAM ev  32 KB dirty, evicted by the 512 KB DDR4 read sweep, verified from SRAM: %lu errors (sink %02lx)\n",
           (unsigned long)err, (unsigned long)(sink & 0xff));
    return err;
}

int main(void) {
    UartStdOutInit();
    uintptr_t pc; __asm volatile("adr %0, ." : "=r"(pc));
    printf("DDR4 FPGA tests - SoCLabs MegaSoC on HAPS-SX (MGSOC-34 step 2)\n");
    printf("running from %s (pc %09lx); DRAM window 0x80000000-0x27FFFFFFF\n", pc >= DRAM_BASE ? "DDR4" : "flash/ROM", (unsigned long)pc);
    from_flash = pc < DRAM_BASE;
    mmu_extend();
    // The application's boot.s only calls enable_mmu() (SCTLR_EL3.M); the data and instruction cache enables are
    // whatever the ROM left behind. The 29 Oct build 58 runs showed the flash-boot path ('n') arriving ~30x slower
    // than the RAM path ('g'), i.e. with the caches off - so report the state, enable them here, report again.
    uint64_t sctlr, ectlr;
    __asm volatile("mrs %0, sctlr_el3" : "=r"(sctlr));
    __asm volatile("mrs %0, s3_1_c15_c2_1" : "=r"(ectlr));   // CPUECTLR_EL1 (SMPEN = bit 6)
    __asm volatile("mrs %0, cntfrq_el0" : "=r"(cnt_frq));
    printf("SCTLR_EL3 %08lx (M=%lu C=%lu I=%lu) CPUECTLR %lx (SMPEN=%lu) CNTFRQ_EL0 %lu Hz\n", (unsigned long)sctlr,
           (unsigned long)(sctlr & 1), (unsigned long)((sctlr >> 2) & 1), (unsigned long)((sctlr >> 12) & 1),
           (unsigned long)ectlr, (unsigned long)((ectlr >> 6) & 1), (unsigned long)cnt_frq);
    if ((sctlr & 0x1004) != 0x1004) {
        if (!((ectlr >> 6) & 1)) {                   // Cortex-A53: SMPEN must be 1 before the caches are enabled
            ectlr |= 1UL << 6;
            __asm volatile("msr s3_1_c15_c2_1, %0 \n\t isb" :: "r"(ectlr));
            __asm volatile("mrs %0, s3_1_c15_c2_1" : "=r"(ectlr));
            printf("CPUECTLR.SMPEN was 0: set -> CPUECTLR %lx (the library's enable_caches() never sets it)\n", (unsigned long)ectlr);
        }
        enable_caches();
        __asm volatile("mrs %0, sctlr_el3" : "=r"(sctlr));
        printf("caches were off: enable_caches() -> SCTLR_EL3 %08lx (C=%lu I=%lu)\n", (unsigned long)sctlr,
               (unsigned long)((sctlr >> 2) & 1), (unsigned long)((sctlr >> 12) & 1));
    }
    caches_on = (sctlr & 0x1004) == 0x1004;
    uint64_t t0;
    t0 = ticks(); total_errors += t1_words();   lap("T1", t0);
    t0 = ticks(); total_errors += t2_address(); lap("T2", t0);
    t0 = ticks(); total_errors += t5_l2ways(28); lap("T5a", t0);     // 16 lines = the 16 ways
    t0 = ticks(); total_errors += t5_l2ways(30); lap("T5b", t0);     // 18 lines: 2 evictions
    t0 = ticks(); total_errors += t3_block();   lap("T3", t0);
    t0 = ticks(); total_errors += t6_paths();   lap("T6", t0);
    t0 = ticks(); total_errors += t8_ddr_evict(); lap("T8", t0);
    t0 = ticks(); total_errors += t7_sram_evict(); lap("T7", t0);   // last but T4: leaves the SRAM cacheable
    t0 = ticks(); total_errors += t4_strobes(); lap("T4", t0);
    printf("DDR4 total errors: %lu\n", (unsigned long)total_errors);
    if (total_errors) TEST_FAIL(); else TEST_PASS();
    return 0;
}
