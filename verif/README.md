# MegaSoC Verification Plan
megaSoC is built using pre-verified IP, so the only real verification task is integration testing. This means we can mostly rely on functional verification. Each of the IPs should be verified individually before integration in the system (as is the case with the Arm IP).

Percentage Verified: X%

### Table of Contents
1. [CPU - Cortex A53](#cortex-a53)
2. [Interrupt Controller - GIC](#gic)
3. [Peripheral Subsystem](#peripheral-subsystem)
    - [AHB Default Slave](#ahb-default-slave)
    - [GPIO 0 & 1](#gpio-0--1)
    - [Timer 0 & 1](#timer-0--1)
    - [Dualtimer](#dualtimers)
    - [UART 0 & 1](#uart-0--1)
    - [Watchdog Timer](#watchdog-timer)
    - [Real Time Clock](#real-time-clock)
    - [SPI Controller](#spi-controller)
4. [ASCII Debugger](#acii-debugger)

## Cortex A53

- [ ] Neon

## GIC

## Peripheral Subsystem
The Peripheral subsystem contains multiple pieces of IP. 

Peripheral Subsytem test file: [peripheral_test.c](../megasoc_tech/software/src/peripheral_test/peripheral_test.c)
- [x] Read PID + CID of all IPs in peripheral subsystem

### AHB Default Slave

- [ ] Bus Read (should give OKAY response)
### GPIO 0 & 1

- [ ] Loopback test values on P0
- [ ] Loopback test values on P1[3:0]
- [ ] Interrupt generation on each pin P0[15:0] and P1[3:0]
- [ ] Low level, falling, high level and rising interrupts
- [ ] Change altfunction on P1

### Timer 0 & 1
Test file: [timer_tests.c](../megasoc_tech/software/src/timer_tests/timer_tests.c)
- [ ] Use Timer
- [ ] Interrupt Generation
- [ ] External Input

### Dualtimers

- [ ] Use Timer 1
- [ ] Use Timer 2
- [ ] Generate TIMINT1
- [ ] Generate TIMINT2

### UART 0 & 1
Test file: [uart_test.c](../megasoc_tech/software/src/uart_tests/uart_tests.c)
- [x] Transmit Data
- [x] Recieve Data
- [x] Rx Interrupt
- [ ] Tx Interrupt
- [ ] Rx Overflow IRQ
- [ ] Tx Overflow IRQ

### Watchdog Timer

- [ ] Enable Timer
- [ ] Generate Interrupt
- [ ] Reset from Watchdog

### Real Time Clock

### SPI Controller

## Acii Debugger

- [x] Communicate from EXTIO to System using ADP

## 
