#include "uart_stdout.h"
#include <stdio.h>
#include "system.h"
#include "sys_memory_map.h"
#include "dma_350_command_lib.h"
#include "sys_intr_map.h"
#include "gic400.h"

#define HW32_REG(ADDRESS)  (*((volatile unsigned long  *)(ADDRESS)))
#define HW8_REG(ADDRESS)   (*((volatile unsigned char  *)(ADDRESS)))

#define EXP_SRAM_0_BASE       0x60000000UL
#define EXP_SRAM_1_BASE       0x60040000UL
#define EXP_SRAM_0_HI_BASE    0x68000000UL
#define EXP_SRAM_1_HI_BASE    0x68040000UL

#define DATA_SIZE             64

// IRQ Handlers
static void DMA_CH0_IRQ();
static void DMA_CH1_IRQ();
static void DMA_CH2_IRQ();
static void DMA_CH3_IRQ();
void DMAClearChIrq(uint8_t ch);

int* data = (int*) EXP_SRAM_0_BASE;
int* dest = (int*) EXP_SRAM_1_BASE;

AdaChannelSettingsType ch_settings = {
    .CHPRIO         = 0,
    .CLEARCMD       = 1,
    .REGRELOADTYPE  = RELOAD_DISABLED,
    .DONETYPE       = DONETYPE_EOF_CMD,
    .DONEPAUSEEN    = 0,
    .SRCMAXBURSTLEN = 15,
    .DESMAXBURSTLEN = 15
  };
AdaChannelSrcAttrType ch_srcattr = {
    .SRCMEMATTRLO  = 4,
    .SRCMEMATTRHI  = 4,
    .SRCSHAREATTR  = 0,
    .SRCNONSECATTR = 1,
    .SRCPRIVATTR   = 0
  };
AdaChannelDesAttrType ch_desattr = {
    .DESMEMATTRLO  = 4,
    .DESMEMATTRHI  = 4,
    .DESSHAREATTR  = 0,
    .DESNONSECATTR = 1,
    .DESPRIVATTR   = 0
  };
AdaChannelLinkAttrType ch_linkattr = {
    .LINKMEMATTRLO = 4,
    .LINKMEMATTRHI = 4,
    .LINKSHAREATTR = 0
  };
AdaBaseCommandType command_base = {
    .SRCADDR  = EXP_SRAM_0_BASE, // Read from M0 interface
    .DESADDR  = EXP_SRAM_1_HI_BASE, // Write to M0 interface
    .SRCXSIZE = DATA_SIZE,
    .DESXSIZE = DATA_SIZE,
    .TRANSIZE = BITS_32
  };

Ada1DIncrCommandType command_1d_incr = {
    .SRCXADDRINC = 1,           // Autoincrement by transaction size
    .DESXADDRINC = 1            // Autoincrement by transaction size
  };

  // Set the transfer types (2D and wrapping support)
  // The transaction type is 1D basic transfer
  AdaWrapCommandType command_1d_wrap = {
    .FILLVAL  = 0,
    .XTYPE    = OPTYPE_CONTINUE,
    .YTYPE    = OPTYPE_DISABLE
  };
AdaIrqEnType ch_irqs = {
    .INTREN_DONE     = 1,
    .INTREN_ERR      = 1,
    .INTREN_DISABLED = 0,
    .INTREN_STOPPED  = 0
  };

int main(){
    int i = 0;
    uint32_t ch_num;
    uint32_t trig_in_num;
    uint32_t trig_out_num;

    UartStdOutInit();

    printf("DMA 350 tests - SoCLabs MegaSoC\n");

    for (i=0; i<DATA_SIZE;i++){
      data[i]=i;
    }

    printf("Init IRQs\n");
    gic_initialise_intr(EXP_DMA350_CH0_INTR, 0, 1, 0);
    gic_install_handler(EXP_DMA350_CH0_INTR, &DMA_CH0_IRQ);
    gic_enable_interrupt(EXP_DMA350_CH0_INTR);

    gic_initialise_intr(EXP_DMA350_CH1_INTR, 0, 1, 0);
    gic_install_handler(EXP_DMA350_CH1_INTR, &DMA_CH1_IRQ);
    gic_enable_interrupt(EXP_DMA350_CH1_INTR);

    gic_initialise_intr(EXP_DMA350_CH2_INTR, 0, 1, 0);
    gic_install_handler(EXP_DMA350_CH2_INTR, &DMA_CH2_IRQ);
    gic_enable_interrupt(EXP_DMA350_CH2_INTR);

    gic_initialise_intr(EXP_DMA350_CH3_INTR, 0, 1, 0);
    gic_install_handler(EXP_DMA350_CH3_INTR, &DMA_CH3_IRQ);
    gic_enable_interrupt(EXP_DMA350_CH3_INTR);

    enable_irq();


    //Get the configuration information
    ch_num = AdaGetChNum(DMA_EXP_INFO_S);
    trig_in_num = AdaGetTrigInNum(DMA_EXP_INFO_S);
    trig_out_num = AdaGetTrigOutNum(DMA_EXP_INFO_S);

    //Display the config parameters read
    printf("Number of DMA channels: %d \n", ch_num);
    printf("Number of DMA trigger inputs: %d \n", trig_in_num);
    printf("Number of DMA trigger outputs: %d \n", trig_out_num);

    AdaSecAllChStopReq(DMA_EXP_SECCTRL_S);

    printf("TEST 1: DMA transfer EXP_SRAM_0 to EXP_SRAM_1\n");
    // In the GIC Software library the Expansion DMA channels
    // are set to an offset of 4, so EXP_CH0 = CH4 etc.
    for (uint32_t ch=4; ch < ch_num+4; ch++) {
      //
      // Write all settings to the DMA registers
      AdaChannelInit(ch_settings, ch_srcattr, ch_desattr, ch, SECURE);
      Ada1DIncrCommand(command_base, command_1d_incr, ch, SECURE);
      SetAdaWrapRegs(command_1d_wrap, ch, SECURE);
      AdaSetIntEn(ch_irqs, ch, SECURE);    
      // Start DMA operation and wait for done IRQ
      printf("DMA CH:%d Enabling\n",ch);
      AdaEnable(ch, SECURE);
      call_wfi();
      printf("DMA CH:%d transfer finished\n",ch);
    }

    for(i=0;i<DATA_SIZE;i++){
      if(dest[i]!=i){
        TEST_FAIL();
      }
    }

    TEST_PASS();
}

void DMAClearChIrq(uint8_t ch) {
  // Check the source of the interrupt and clear interrupts
  AdaStatType ST = AdaReadStatus(ch, NON_SECURE);
  if (ST.STAT_DONE == 1) {
    AdaClearChDone(ch, NON_SECURE);
  } else if (ST.STAT_ERR == 1) {
    AdaClearChError(ch, NON_SECURE);
  } else if (ST.STAT_DISABLED == 1) {
    AdaClearChDisabled(ch, NON_SECURE);
  } else if (ST.STAT_STOPPED == 1) {
    AdaClearChStopped(ch, NON_SECURE);
  } else {
    printf("Unknown IRQ on CH%d!\n", ch);
  }
}

void DMA_CH0_IRQ(){
  disable_irq();
  DMAClearChIrq(4);
  printf("DMA CH4 IRQ\n");
  enable_irq();
}

void DMA_CH1_IRQ(){
  disable_irq();
  DMAClearChIrq(5);
  printf("DMA CH5 IRQ\n");
  enable_irq();
}

void DMA_CH2_IRQ(){
  disable_irq();
  DMAClearChIrq(6);
  printf("DMA CH6 IRQ\n");
  enable_irq();
}

void DMA_CH3_IRQ(){
  disable_irq();
  DMAClearChIrq(7);
  printf("DMA CH7 IRQ\n");
  enable_irq();
}
