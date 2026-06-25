`ifndef GUARD_SDIO_VIP_TC3_TEST_SV
`define GUARD_SDIO_VIP_TC3_TEST_SV

`include "sdio_base_test.sv"

// Block size/sector/pattern shared between the test and its CMD0 subscriber.
localparam int unsigned TC3_BLOCK_SIZE = 512;
localparam int unsigned TC3_SECTOR     = 'h1000;
// Recognisable, non-0xA5 pattern so TC3's "buffer changed from the 0xA5
// fill" check is meaningful, and the value is easy to spot in a dump.
localparam bit [7:0] TC3_PATTERN_BYTE = 8'hC3;

// Root cause of the all-zero CMD17 read: the memserver instance backing
// this card logs "data-bits=4096" at creation -- its native addressable
// word IS one full 512-byte SD block (4096 bits), not one byte. The
// original version of this file called poke() 512 times at addresses
// TC3_SECTOR*512 .. +511, each carrying a single 8-bit value -- under a
// block-addressed memory that pokes 512 *separate* blocks, each with
// only its lowest byte set to 0xC3 and the rest defaulting to 0, never
// touching block TC3_SECTOR (0x1000) itself, which is what CMD17 (arg
// = the raw sector number, since this is an SDHC card) actually reads.
// The peek-after-poke self-check still "passed" because it happened to
// check the exact same (wrong) addresses, making the bug self-consistent
// and invisible until checked against an actual SD read.
//
// The fix: one poke() of one TC3_BLOCK_SIZE*8-bit-wide value, at address
// TC3_SECTOR.
function svt_mem_data_t tc3_build_pattern_word();
  svt_mem_data_t word;
  word = '0;
  for (int unsigned i = 0; i < TC3_BLOCK_SIZE; i++) begin
    word[i*8 +: 8] = TC3_PATTERN_BYTE;
  end
  return word;
endfunction : tc3_build_pattern_word

function void tc3_poke_pattern(svt_mem_backdoor mem_back_door);
  mem_back_door.poke(TC3_SECTOR, tc3_build_pattern_word());
endfunction : tc3_poke_pattern

/**
 * Re-pokes the TC3 pattern every time the card monitor observes a CMD0
 * (GO_IDLE_STATE). The real RTL host sends CMD0 multiple times during
 * its normal SD initialisation handshake (standard SD behaviour), and
 * each one clears the card model's data array, wiping out whatever was
 * backdoor-poked before it. A single start_of_simulation_phase poke is
 * wiped out long before CMD17 ever reads sector 0x1000. Re-poking after
 * every CMD0 closes that gap without depending on exact timing.
 */
class tc3_cmd0_repoke_subscriber extends uvm_subscriber #(svt_emmc_card_transaction);

  svt_mem_backdoor mem_back_door;

  `uvm_component_utils(tc3_cmd0_repoke_subscriber)

  function new(string name = "tc3_cmd0_repoke_subscriber", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void write(svt_emmc_card_transaction t);
    if (t.cmd_type == svt_emmc_types::CMD0) begin
      tc3_poke_pattern(mem_back_door);
      `uvm_info("write", $sformatf(
        "CMD0 observed -- re-poked block 0x%0h with 8'h%0h x %0d bytes.",
        TC3_SECTOR, TC3_PATTERN_BYTE, TC3_BLOCK_SIZE), UVM_LOW)
    end
  endfunction : write

endclass : tc3_cmd0_repoke_subscriber

/**
 * TC3-equivalent: single-block read, verified against data backdoor-poked
 * into the VIP card model before the embedded software (TC1..TC14, the
 * same megasoc_tech/software/src/sdio_tests/sdio_tests.c image already
 * used by the mdl_sdio.v BEHAV flow) runs test_sdio_single_block_read(),
 * which issues CMD17 for sector SDIO_TEST_SECTOR_BASE (0x1000) through
 * the existing AXI-Lite/sdiodrv.c path -- no new AXI driving code here.
 *
 * Addressing: this card's backdoor memory is block-addressed (one
 * 4096-bit/512-byte word per address, matching the SDHC block size), so
 * sector S maps directly to backdoor address S. See tc3_poke_pattern's
 * comment for how this was found (an AXI-Lite read-data tap during the
 * actual CMD17 transfer showing all zero, despite a self-consistent but
 * wrongly-addressed peek-after-poke check passing).
 */
class sdio_vip_tc3_test extends sdio_base_test;

  tc3_cmd0_repoke_subscriber cmd0_repoke;

  `uvm_component_utils(sdio_vip_tc3_test)

  function new(string name = "sdio_vip_tc3_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cmd0_repoke = tc3_cmd0_repoke_subscriber::type_id::create("cmd0_repoke", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sd_env.card_agent.card_mon.rx_card_xact_observed_port.connect(cmd0_repoke.analysis_export);
  endfunction : connect_phase

  function void start_of_simulation_phase(uvm_phase phase);
    svt_mem_backdoor mem_back_door;
    svt_mem_data_t   rd_word;
    svt_mem_data_t   expected_word;
    bit              self_check_ok;

    super.start_of_simulation_phase(phase);

    mem_back_door = sd_env.card_agent.mem_sequencer.get_backdoor();
    if (mem_back_door == null) begin
      `uvm_fatal("start_of_simulation_phase", "Could not obtain card memory backdoor handle.");
    end
    cmd0_repoke.mem_back_door = mem_back_door;

    tc3_poke_pattern(mem_back_door);

    expected_word = tc3_build_pattern_word();
    void'(mem_back_door.peek(TC3_SECTOR, rd_word));
    self_check_ok = (rd_word == expected_word);

    if (self_check_ok) begin
      `uvm_info("start_of_simulation_phase", $sformatf(
        "Backdoor self-check passed: block 0x%0h poked and peeked back as %0d bytes of 8'h%0h.",
        TC3_SECTOR, TC3_BLOCK_SIZE, TC3_PATTERN_BYTE), UVM_LOW)
    end else begin
      `uvm_error("start_of_simulation_phase", $sformatf(
        "Backdoor self-check failed at block 0x%0h: wrote %0h, peeked back %0h.",
        TC3_SECTOR, expected_word, rd_word));
      `uvm_fatal("start_of_simulation_phase", "Backdoor self-check failed -- aborting before the embedded software runs against unverified card data.");
    end
  endfunction : start_of_simulation_phase

endclass : sdio_vip_tc3_test

`endif // GUARD_SDIO_VIP_TC3_TEST_SV
