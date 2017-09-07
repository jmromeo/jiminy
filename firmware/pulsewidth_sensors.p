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

#define ULTRASONIC_LEFT_LOWTIME   r27
#define ULTRASONIC_LEFT_HIGHTIME  r26
#define ULTRASONIC_LEFT_PINSTATUS r25

#define ULTRASONIC_CENTER_LOWTIME   r24
#define ULTRASONIC_CENTER_HIGHTIME  r23
#define ULTRASONIC_CENTER_PINSTATUS r22

#define ULTRASONIC_RIGHT_LOWTIME   r21
#define ULTRASONIC_RIGHT_HIGHTIME  r20
#define ULTRASONIC_RIGHT_PINSTATUS r19

/**
 * Macro to calculate pulse width.
 *
 * @param   Number representing which bit in r30 to read.
 * @param   Shared RAM address to store pulsewidth value when calculated.
 * @param   Register which will hold the last cycle number in which the signal was low.
 * @param   Register which will hold the last cycle number in which the signal was high.
 * @param   Register to hold whether the signal was high or low last call.
 *
 */
.macro  PWL
.mparam gpio, offset, lowtime, hightime, pinstatus

    // The macro takes 10 instructions to run, so add 10 to cycle count
    ADD   r28, r28, 10

    // Pushing variables into registers to be used in calculate_pulsewidth function call
    MOV   r2, gpio
    MOV   r3, offset
    MOV   r6, lowtime
    MOV   r7, hightime
    MOV   r9, pinstatus

    // Call pulse width instruction and load return address into r29.w0
    JAL   r29.w0, CALCULATE_PULSEWIDTH

    // Save output from function call to be used in future call
    MOV   lowtime,    r6
    MOV   hightime,   r7
    MOV   pinstatus,  r9

.endm


INIT:
    // Initialize all registers that will be used in pulse width calculations
    MOV r28,                          0
    MOV ULTRASONIC_LEFT_LOWTIME,      0
    MOV ULTRASONIC_LEFT_HIGHTIME,     0
    MOV ULTRASONIC_LEFT_PINSTATUS,    0
    MOV ULTRASONIC_CENTER_LOWTIME,    0
    MOV ULTRASONIC_CENTER_HIGHTIME,   0
    MOV ULTRASONIC_CENTER_PINSTATUS,  0
    MOV ULTRASONIC_RIGHT_LOWTIME,     0
    MOV ULTRASONIC_RIGHT_HIGHTIME,    0
    MOV ULTRASONIC_RIGHT_PINSTATUS,   0

CONTINUE:

    // Calling pulsewidth calculator, which will store the last pulse width
    // value seen to the appropriate shared memory offset
    PWL   ULTRASONIC_LEFT_GPIO,   ULTRASONIC_LEFT_SHARED_RAM_OFFSET,    ULTRASONIC_LEFT_LOWTIME,    ULTRASONIC_LEFT_HIGHTIME,   ULTRASONIC_LEFT_PINSTATUS
    PWL   ULTRASONIC_CENTER_GPIO, ULTRASONIC_CENTER_SHARED_RAM_OFFSET,  ULTRASONIC_CENTER_LOWTIME,  ULTRASONIC_CENTER_HIGHTIME, ULTRASONIC_CENTER_PINSTATUS
    PWL   ULTRASONIC_RIGHT_GPIO,  ULTRASONIC_RIGHT_SHARED_RAM_OFFSET,   ULTRASONIC_RIGHT_LOWTIME,   ULTRASONIC_RIGHT_HIGHTIME,  ULTRASONIC_RIGHT_PINSTATUS

    // Adding 2 to instruction count, 1 for the ADD and another for the jump
    ADD   r28, r28, 2
    JMP   CONTINUE

JMP  EXIT

// r2(INPUT):         GPIO PIN
// r3(INPUT):         Shared memory offset
// r6(INPUT/OUTPUT):  Track amount of time that signal is 0. Need to supply last output value from function as input.
// r7(INPUT/OUTPUT):  Track amount of time that signal is 1. Need to supply last output value from function as input.
// r8(INTERNAL):      Pin Status. Used internally. Not useful as input or output.
// r9(INPUT/OUTPUT):  Status of previous pin. Need to supply last output value from function as input.
// r10(INTERNAL):     Pulse Width Value. Will be written to appropriate shared memory offset on negedge.
// r28(GLOBAL):       Global timer.
CALCULATE_PULSEWIDTH:

    // Adding 4 to cycle count as there are 4 instructions before conditional branch.
    ADD   r28, r28, 4

    // Getting pins current value.
    LSR   r8, r31, r2
    AND   r8, r8,  1

    // If supplied input value is different than previous value we have 
    // a signal edge. Will branch to signal edge handler.
    QBNE  SIGNAL_EDGE, r8, r9

    // If no signal edge and pin is high, go to pin high handler.
    QBEQ  PIN_HIGH, r8, 1

    // If no signal edge and pin is low, go to pin low handler.
    JMP   PIN_LOW

    // storing current timer value if pin is high and we haven't found a signal edge.
    PIN_HIGH:
        ADD   r28, r28, 5
        MOV   r7,  r28
        MOV   r9,  r8
        JMP   r29.w0

    // storing current timer value if pin is low and we haven't found a signal edge.
    // once we find signal edge we can use this and pin high timer value to figure out pulsewidth.
    PIN_LOW:
        ADD   r28, r28, 6
        MOV   r6,  r28
        MOV   r9,  r8
        JMP   r29.w0

    // if positive signal edge do nothing. if negative signal edge, calculate pulse
    // width and store in appropriate shared memory area
    SIGNAL_EDGE:
        ADD   r28, r28, 5
        AND   r8,  r8, 1
        QBEQ  STORE_PULSEWIDTH, r8, 0
        MOV   r9, r8
        JMP   r29.w0

    // calculating and storing pulsewidth
    STORE_PULSEWIDTH:
        ADD   r28, r28, 5
        SUB   r10, r7, r6
        SBCO  r10, CONST_PRUSHAREDRAM, r3, 4
        MOV   r9,  r8
        JMP   r29.w0

EXIT:

    // Send notification to Host for program completion
    MOV   r31.b0, PRU0_ARM_INTERRUPT+16

    // Halt the processor
    HALT

