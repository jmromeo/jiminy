#include "ultrasonic.h"
#include "pru.h"


/**
 * @brief Sets up instance of ultrasonic sensor that can read from PRU register.
 *
 * @param pru_sharedmem Pointer to pru shared memory.  
 * @param sharedmem_index Offset into shared memory to access calculated pulse width.
 *
 * Example usage:
 * @code
 *
 * @endcode
 */
Ultrasonic::Ultrasonic(PRU *pru, unsigned int sharedmem_index)
{
    _prumem   = pru->GetSharedMemPointer();
    _pruindex = sharedmem_index;
}


/**
 * @brief Returns pulse width from ultrasonic sensor.
 *
 * @return Returns double representing pulse width in milliseconds.
 *
 * Example usage:
 * @code
 *
 * @endcode
 */
double Ultrasonic::GetPulseWidth()
{
    volatile unsigned int pulsewidth_cycles;

    pulsewidth_cycles = _prumem[_pruindex];

    // dividing by 1000 to return in milliseconds
    return (double)((pulsewidth_cycles) / (PRU_CYCLES_PER_SECOND / 1000.0));
}
