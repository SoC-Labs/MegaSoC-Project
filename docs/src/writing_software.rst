*********************
Writing Software
*********************

Address Map 
=============

Summary
----------

+---------------------------+-------------------+---------------+
| Region                    | Start Address     | End Address   |
+===========================+===================+===============+
| Boot-Rom                  | 0x00000000        | 0x0000FFFF    |
+---------------------------+-------------------+---------------+
| Flash (off chip QSPI)     | 0x00400000        | 0x007FFFFF    |
+---------------------------+-------------------+---------------+
| Data Memory (SRAM)        | 0x00800000        | 0x0080FFFF    |
+---------------------------+-------------------+---------------+
| Flash Control             | 0x01000000        | 0x0100FFFF    |
+---------------------------+-------------------+---------------+
| DMA Control               | 0x01010000        | 0x01011FFF    |
+---------------------------+-------------------+---------------+
| GIC (Interrupt control)   | 0x01100000        | 0x01107FFF    |
+---------------------------+-------------------+---------------+
| PCK Control               | 0x01200000        | 0x01207FFF    |
+---------------------------+-------------------+---------------+
| Peripherals               | 0x40000000        | 0x5FFFFFFF    |
+---------------------------+-------------------+---------------+
| Debug                     | 0x60000000        | 0x7FFFFFFF    |
+---------------------------+-------------------+---------------+
| DRAM                      | 0x80000000        | 0xFFFFFFFF    |
+---------------------------+-------------------+---------------+


System IO Region
---------------------
Below are the address regions for the System IO/Peripherals, detailed address
maps for each peripheral

+---------------------------+-------------------+---------------+
| Region                    | Start Address     | End Address   |
+===========================+===================+===============+
| Timer 0                   | 0x40000000        | 0x40000FFF    |
+---------------------------+-------------------+---------------+
| Timer 1                   | 0x40001000        | 0x40001FFF    |
+---------------------------+-------------------+---------------+
| Dual Timer                | 0x40002000        | 0x40002FFF    |
+---------------------------+-------------------+---------------+
| USRT 0                    | 0x40003000        | 0x40003FFF    |
+---------------------------+-------------------+---------------+
| USRT 1                    | 0x40004000        | 0x40004FFF    |
+---------------------------+-------------------+---------------+
| UART 0                    | 0x40005000        | 0x40005FFF    |
+---------------------------+-------------------+---------------+
| UART 1                    | 0x40006000        | 0x40006FFF    |
+---------------------------+-------------------+---------------+
| Watchdog Timer            | 0x40007000        | 0x40007FFF    |
+---------------------------+-------------------+---------------+
| Real Time Clock           | 0x40008000        | 0x40008FFF    |
+---------------------------+-------------------+---------------+
| SPI                       | 0x40009000        | 0x40009FFF    |
+---------------------------+-------------------+---------------+


Adding Tests
================
To add your own testcodes to run on nanosoc in the simulation environment,
you can add these to the accelerator-project/system/testcodes directory.

    1. Create a new directory for your testcode
    2. Create a .c source file with the same name as the directory
    3. Copy the makefile from one of the example testcodes to your test code directory
    4. Edit the TESTNAME variable in the new makefile to the name of your test
    5. If you want to run any ADP code before your test, add an adp.cmp file (example in the adp v4 cmd tests)
    6. If you want to preload expansion memories, add an expram l.hex and/or expram h.hex
    7. Add the name of your test to the accelerator-project/system/software list.txt file
