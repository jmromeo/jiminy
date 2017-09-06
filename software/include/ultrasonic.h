#ifndef __ULTRASONIC_H__
#define __ULTRASONIC_H__

#include "pru.h"

class Ultrasonic
{
  private:

    // pointers to PRU shared memory setup
    unsigned int *_prumem;
    unsigned int _pruindex;

  public:

    // constructor
    Ultrasonic(PRU *pru, unsigned int sharedmem_index);

    // retrieve sensor data from pru
    double GetPulseWidth();
};

#endif // __ULTRASONIC_H__
