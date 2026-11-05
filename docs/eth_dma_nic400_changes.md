# NIC-400 changes for Ethernet + DMA-350 (Socrates input sheet)

Config: `megasoc_tech/socrates/nic400_megasoc_main/nic400_megasoc_main.xml`
(NIC-400 r1p2). Add four interfaces in **one** regeneration. Everything
else stays as it is. All new interfaces use `clk0` and `gd0`, like the
existing ones.

## New slave interfaces (masters coming into the NIC)

| Name | Protocol | Copy settings from | Data | Address | Notes |
|---|---|---|---|---|---|
| `ETH_M` | AHB-Lite (initiator) | `ADP` | 32 | 32 | Ethernet MAC DMA. No lock. |
| `DMA_M` | AXI4 | `SDIO_M` | 64 | 44 | DMA-350. 2-bit ID, same as `SDIO_M` (and the old `AWID_DMA350[1:0]` hookup). |

## New master interfaces (targets going out of the NIC)

| Name | Protocol | Group | Data | Address | Copy settings from |
|---|---|---|---|---|---|
| `ETH_S` | APB4 | `apb_group0` | 32 | 32 | `FLASH_CTRL` |
| `DMA_S` | APB4 | `apb_group0` | 32 | 32 | `FLASH_CTRL` |

APB4 because both blocks use PSTRB (and the DMA also uses PPROT).

## Address map additions

| Target | Base | Size | Visible from |
|---|---|---|---|
| `ETH_S` | `0x0_0102_0000` | 64 KB (MAC 0x0000, PTP 0x1000, checksum 0x2000) | `A53`, `ADP` |
| `DMA_S` | `0x0_0103_0000` | 64 KB (DMA uses 8 KB) | `A53`, `ADP` |

Both fit between SDIO_S (`0x0101_xxxx`) and GIC (`0x0110_0000`).

## What the new masters can reach

| Master | ROM | FLASH | RAM | PERIPHERAL | DRAM | Others |
|---|---|---|---|---|---|---|
| `ETH_M` | | | yes | | yes: `0x8000_0000`, 2 GB (32-bit address, same as `ADP`) | none |
| `DMA_M` | yes | yes | yes | **yes** (peripheral transfers) | yes: full 8 GB | none |

## Exact edits in Socrates terms

The XML holds three things: **Interfaces**, **Memory Maps** (one per
master) and **Paths** (master → reachable targets). Socrates builds the
internal switches (bm0/bm1/bm2) from the Paths, so there's nothing to place
by hand.

| Section | Existing entry | Edit |
|---|---|---|
| Memory map `CPU_MM` (source `A53`) | 11 blocks | **add** `ETH_S` 0x01020000 / 0x10000, `DMA_S` 0x01030000 / 0x10000 |
| Memory map `ADP_MM` (source `ADP`) | 11 blocks | **add** the same two blocks |
| Memory map **`ETH_MM`** (new, source `ETH_M`) | – | `RAM` 0x00800000 / 0x10000; `DRAM` 0x80000000 / 0x80000000 |
| Memory map **`DMA_MM`** (new, source `DMA_M`) | – | `ROM` 0x0 / 0x10000; `FLASH` 0x00400000 / 0x400000; `RAM` 0x00800000 / 0x10000; `PERIPHERAL` 0x40000000 / 0x20000000; `DRAM` 0x80000000 / 0x200000000 |
| Path `A53` | ROM … SDIO_S | **add** `ETH_S`, `DMA_S` |
| Path `ADP` | ROM … EXP_M | **add** `ETH_S`, `DMA_S` |
| Path **`ETH_M`** (new) | – | `RAM`, `DRAM` |
| Path **`DMA_M`** (new) | – | `ROM`, `FLASH`, `RAM`, `PERIPHERAL`, `DRAM` |
| Paths `SDIO_M`, `EXP_S` | | unchanged |

## As built (2026-11-03, Socrates CLI, GUI unavailable)

- Specification edited by hand as above. The `<Architecture>` block (the
  escaped NIC config) was also edited by hand, because the CLI build only
  checks Specification against Architecture and does not rebuild it:
  - asib `ETH_M` (copy of ADP, AHB) and asib `DMA_M` (copy of SDIO_M, AXI)
    with ETH_MM / DMA_MM decoders; ETH_S / DMA_S ranges added to the CPU_MM
    and ADP_MM decoders
  - `apb_group0` gains APB slots `ETH_S`, `DMA_S`
  - `bm0` gains inputs `axi_s_4` (ETH_M: DRAM, RAM, default slave) and
    `axi_s_5` (DMA_M: FLASH, ROM, DRAM, PERIPHERAL, RAM, default slave)
  - 6 new `connect` entries and matching `<architecture>` links
- Global ID width raised 9 -> 10 (Specification `GlobalIDWidth` and
  Architecture `pl_id_width`), required because bm0 now has 6 inputs.
- `make build_nic400`: DRC status WARNING only (validator 22.1 vs 24.4, and
  44-bit masters vs 33-bit global address width, both pre-existing), RTL
  generator 0 errors / 0 warnings.
- Generated output: 37 new files (asib_ETH_M, asib_DMA_M, ib_ETH_M_ib, bm0
  slots 4/5), none removed or renamed. `flist/IP/nic400_megasoc_main.flist`
  updated (+29 files, +3 incdirs).

## After regeneration

- Generated port names follow the existing pattern (`HADDR_ETH_M`,
  `PSELx_ETH_S`, `AWADDR_DMA_M`, `PADDR_DMA_S`, …). Send me the regenerated
  `nic400_megasoc_main` port list or the flist update, and I'll wire it into
  `megasoc_tech_wrapper.sv`.
- Without `INC_ETH` / `INC_DMA`, those ports are tied off in RTL, so the
  default build behaves the same as today.
