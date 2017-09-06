/// TODO: ADD TIMEOUT SO THAT WE DON'T HANG IF THERE IS AN ISSUE WITH 1 SIGNAL

.origin 0
.entrypoint MEMACCESS_DDR_PRUSHAREDRAM

#include "PRU_memAcc_DDR_sharedRAM.hp"
#include "pru_setup.hp"

#define ULTRASONIC_LEFT_GPIO    PRU0_GPIO_INPUT_P9_24
#define ULTRASONIC_CENTER_GPIO  PRU0_GPIO_INPUT_P9_28
#define ULTRASONIC_RIGHT_GPIO   PRU0_GPIO_INPUT_P9_30

#define ULTRASONIC_LEFT_SHARED_RAM_OFFSET   0
#define ULTRASONIC_CENTER_SHARED_RAM_OFFSET 4 
#define ULTRASONIC_RIGHT_SHARED_RAM_OFFSET  8 

CONTINUE:

	MOV   r0, ULTRASONIC_LEFT_GPIO
	MOV   r1, ULTRASONIC_LEFT_SHARED_RAM_OFFSET
	CALL  CALCULATE_PULSE_WIDTH

	//MOV   r0, ULTRASONIC_CENTER_GPIO
	//MOV   r1, ULTRASONIC_CENTER_SHARED_RAM_OFFSET
	//CALL  CALCULATE_PULSE_WIDTH
	//
	//MOV   r0, ULTRASONIC_RIGHT_GPIO
	//MOV   r1, ULTRASONIC_RIGHT_SHARED_RAM_OFFSET
	//CALL  CALCULATE_PULSE_WIDTH

	CALL	CONTINUE

CALL  EXIT

/**
 * Blocking function to calculate pulse width of input on GPIO pin. Note that r2/r3
 * are used by the function and we don't save them.
 *
 * @param r0(GPIO PIN) - Determines which GPIO pin to read from. See 
 *                       <a href=http://elinux.org/Ti_AM33XX_PRUSSv2#Beaglebone_PRU_connections_and_modes>
 *                       for more details.
 * @param r1(Shared Memory Address) - Offset in shared memory address location to store pulse width.
 */
CALCULATE_PULSE_WIDTH:

    // waiting for 0 on GPIO pin (gpio pin number stored in r0). This will allow
    // us to look for a positive edge
    WAIT_FOR_ZERO:
        LSR   r2, r31, r0
        AND   r2, r2,  1
        QBNE  WAIT_FOR_ZERO, r2, 0

    // waiting for positive edge on GPIO pin
    WAIT_FOR_POSITIVE_EDGE:
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

    // returning to caller
    RET


EXIT:

    // Send notification to Host for program completion
    MOV       r31.b0, PRU0_ARM_INTERRUPT+16

    // Halt the processor
    HALT

