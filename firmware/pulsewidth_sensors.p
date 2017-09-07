/// TODO: ADD TIMEOUT SO THAT WE DON'T HANG IF THERE IS AN ISSUE WITH 1 SIGNAL

.origin 0
.entrypoint MEMACCESS_DDR_PRUSHAREDRAM

#include "PRU_memAcc_DDR_sharedRAM.hp"
#include "pru_setup.hp"

#define DWORD_MAX   0xFFFF

#define ULTRASONIC_LEFT_GPIO    PRU0_GPIO_INPUT_P9_24
#define ULTRASONIC_CENTER_GPIO  PRU0_GPIO_INPUT_P9_28
#define ULTRASONIC_RIGHT_GPIO   PRU0_GPIO_INPUT_P9_30

#define ULTRASONIC_LEFT_SHARED_RAM_OFFSET   0
#define ULTRASONIC_CENTER_SHARED_RAM_OFFSET 4 
#define ULTRASONIC_RIGHT_SHARED_RAM_OFFSET  8 

#define PRU_CLOCKSPEED  200000000

#define TIMEOUT_ESC_MS    20
#define TIMEOUT_ESC       (((PRU_CLOCKSPEED / 1000) * TIMEOUT_ESC_MS) / DWORD_MAX)
 


CONTINUE:

    MOV   r0, ULTRASONIC_LEFT_GPIO
    MOV   r1, ULTRASONIC_LEFT_SHARED_RAM_OFFSET
    MOV   r4, TIMEOUT_ESC
    JAL   r29.w0, CALCULATE_PULSE_WIDTH

    MOV   r0, ULTRASONIC_CENTER_GPIO
    MOV   r1, ULTRASONIC_CENTER_SHARED_RAM_OFFSET
    MOV   r4, TIMEOUT_ESC
    JAL   r29.w0, CALCULATE_PULSE_WIDTH
    
    MOV   r0, ULTRASONIC_RIGHT_GPIO
    MOV   r1, ULTRASONIC_RIGHT_SHARED_RAM_OFFSET
    MOV   r4, TIMEOUT_ESC
    JAL   r29.w0, CALCULATE_PULSE_WIDTH

    JMP	  CONTINUE

JMP  EXIT


CHECK_TIMEOUT:
    MOV   r8, 0
    ADD   r6, r6, 5
    SUB   r5, r5, r6
    QBGE  RESET_MAX_DWORDS, r5, r6
    JMP   r30.w0

    RESET_MAX_DWORDS:
        SUB   r4, r4, 1
        QBEQ  TIMEDOUT, r4, 0
        ADD   r6, r6, 3
        MOV   r5, DWORD_MAX
        JMP   r30.w0
       
    TIMEDOUT:
        MOV   r8, 1
        JMP   r30.w0 

/**
 * Blocking function to calculate pulse width of input on GPIO pin. Note that r2-r8
 * are used by the function and we don't save them.
 *
 * @param r0(GPIO PIN) - Determines which GPIO pin to read from. See 
 *                       <a href=http://elinux.org/Ti_AM33XX_PRUSSv2#Beaglebone_PRU_connections_and_modes>
 *                       for more details.
 * @param r1(Shared Memory Address) - Offset in shared memory address location to store pulse width.
 * @param r4(TIMEOUT VALUE) - Value calculated using:  Value = (((PRU_CLOCKSPEED / TIMEOUT_MS) * 1000) / 65535)
 */
CALCULATE_PULSE_WIDTH:

    // resetting timeout registers
    MOV   r5, DWORD_MAX

    // waiting for 0 on GPIO pin (gpio pin number stored in r0). This will allow
    // us to look for a positive edge
    WAIT_FOR_ZERO:
        MOV   r6, 6
        JAL   r30.w0, CHECK_TIMEOUT 
        QBEQ  FAILED, r8, 1
        LSR   r2, r31, r0
        AND   r2, r2,  1
        QBNE  WAIT_FOR_ZERO, r2, 0

    // waiting for positive edge on GPIO pin
    WAIT_FOR_POSITIVE_EDGE:
        MOV   r6, 6
        JAL   r30.w0, CHECK_TIMEOUT 
        QBEQ  FAILED, r8, 1
        LSR   r2, r31, r0
        AND   r2, r2,  1
        QBNE WAIT_FOR_POSITIVE_EDGE, r2, 1

    // calculating pulse width. every instruction used in calculating pulse
    // width takes 1 clock cycle, so we will add 1 for each instruction in the 
    // calculate loop (total of 4 in this case).
    CALC_PULSE_WIDTH:
        LSR   r2, r31, r0
        AND   r2, r2,  1
        ADD   r3, r3,  4
        QBNE  CALC_PULSE_WIDTH, r2, 0

    // Storing pulse width to the shared memory address specified in r1
    STORE_PULSE_WIDTH:
        SBCO    r3, CONST_PRUSHAREDRAM, r1, 4
        MOV     r3, 0
        JMP     r29.w0

    FAILED:
        MOV   r3, 0xFFFFFFFF
        JMP   STORE_PULSE_WIDTH


EXIT:

    // Send notification to Host for program completion
    MOV       r31.b0, PRU0_ARM_INTERRUPT+16

    // Halt the processor
    HALT

