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

#define ULTRASONIC_LEFT_LOWTIME   r27
#define ULTRASONIC_LEFT_HIGHTIME  r26
#define ULTRASONIC_LEFT_PINSTATUS r25

#define ULTRASONIC_CENTER_LOWTIME   r24
#define ULTRASONIC_CENTER_HIGHTIME  r23
#define ULTRASONIC_CENTER_PINSTATUS r22

#define ULTRASONIC_RIGHT_LOWTIME   r21
#define ULTRASONIC_RIGHT_HIGHTIME  r20
#define ULTRASONIC_RIGHT_PINSTATUS r19




INIT:
    MOV r28, 0
    MOV r27, 0
    MOV r26, 0
    MOV r25, 0

CONTINUE:

    ADD     r28, r28, 10
    MOV     r2, ULTRASONIC_LEFT_GPIO
    MOV     r3, ULTRASONIC_LEFT_SHARED_RAM_OFFSET
    MOV     r6, ULTRASONIC_LEFT_LOWTIME
    MOV     r7, ULTRASONIC_LEFT_HIGHTIME
    MOV     r9, ULTRASONIC_LEFT_PINSTATUS
    JAL     r29.w0, CALCULATE_PULSEWIDTH
    MOV     ULTRASONIC_LEFT_LOWTIME, r6
    MOV     ULTRASONIC_LEFT_HIGHTIME, r7
    MOV     ULTRASONIC_LEFT_PINSTATUS, r9

    ADD     r28, r28, 10
    MOV     r2, ULTRASONIC_CENTER_GPIO
    MOV     r3, ULTRASONIC_CENTER_SHARED_RAM_OFFSET
    MOV     r6, ULTRASONIC_CENTER_LOWTIME
    MOV     r7, ULTRASONIC_CENTER_HIGHTIME
    MOV     r9, ULTRASONIC_CENTER_PINSTATUS
    JAL     r29.w0, CALCULATE_PULSEWIDTH
    MOV     ULTRASONIC_CENTER_LOWTIME, r6
    MOV     ULTRASONIC_CENTER_HIGHTIME, r7
    MOV     ULTRASONIC_CENTER_PINSTATUS, r9

    ADD     r28, r28, 10
    MOV     r2, ULTRASONIC_RIGHT_GPIO
    MOV     r3, ULTRASONIC_RIGHT_SHARED_RAM_OFFSET
    MOV     r6, ULTRASONIC_RIGHT_LOWTIME
    MOV     r7, ULTRASONIC_RIGHT_HIGHTIME
    MOV     r9, ULTRASONIC_RIGHT_PINSTATUS
    JAL     r29.w0, CALCULATE_PULSEWIDTH
    MOV     ULTRASONIC_RIGHT_LOWTIME, r6
    MOV     ULTRASONIC_RIGHT_HIGHTIME, r7
    MOV     ULTRASONIC_RIGHT_PINSTATUS, r9

    ADD     r28, r28, 2
    JMP	    CONTINUE

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
    ADD   r28, r28, 4
    LSR   r8, r31, r2
    AND   r8, r8,  1
    QBNE  SIGNAL_EDGE, r8, r9
    QBEQ  PIN_HIGH, r8, 1
    JMP   PIN_LOW

    // storing current timer value if pin is high and we haven't found a signal edge.
    PIN_HIGH:
        ADD   r28, r28, 5
        MOV   r7, r28
        MOV   r9, r8
        JMP   r29.w0

    // storing current timer value if pin is low and we haven't found a signal edge.
    // once we find signal edge we can use this timer value to
    PIN_LOW:
        ADD   r28, r28, 6
        MOV   r6, r28
        MOV   r9, r8
        JMP   r29.w0

    // if positive signal edge do nothing. if negative signal edge, calculate pulse
    // width and store in appropriate offset
    SIGNAL_EDGE:
        ADD   r28, r28, 5
        AND   r8, r8, 1
        QBEQ  STORE_PULSEWIDTH, r8, 0
        MOV   r9, r8
        JMP   r29.w0

    // calculating pulsewidth and storing
    STORE_PULSEWIDTH:
        ADD     r28, r28, 5
        SUB     r10, r7, r6
        SBCO    r10, CONST_PRUSHAREDRAM, ULTRASONIC_LEFT_SHARED_RAM_OFFSET, 4
        MOV     r9, r8
        JMP     r29.w0

EXIT:

    // Send notification to Host for program completion
    MOV       r31.b0, PRU0_ARM_INTERRUPT+16

    // Halt the processor
    HALT

