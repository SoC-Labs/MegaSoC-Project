#include "uart_stdout.h"
#include <stdio.h>
#include "system.h"

int main(void) {
    uint32_t errors = 0;
    UartStdOutInit();

    printf("Mem Tests - SoCLabs MegaSoC\n");

    errors += access_addr_wdata(0x60000000,16,0xCAFECAFE);

    if(errors!=0){
        TEST_FAIL();
    } else {
        TEST_PASS();
    }
    UartEndSimulation();
}