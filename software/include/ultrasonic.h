#ifndef __ULTRASONIC_H__
#define __ULTRASONIC_H__

class Ultrasonic
{
  private:

    // pointers to PRU shared memory setup
    unsigned int *_prumem;
    unsigned int _pruindex;

  public:

    // constructor
    Ultrasonic(unsigned int *pru_sharedmem, unsigned int sharedmem_index);

    // setup and receive/transmit
    double GetPulseWidth();

};

#endif // __ULTRASONIC_H__
