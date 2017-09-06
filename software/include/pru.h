#ifndef __PRU_H__
#define __PRU_H__

#define PRU0                      0
#define PRU1                      1

#define PRU_CYCLES_PER_SECOND     200000000.0

class PRU
{
    private:
        unsigned int *_prumem;
        unsigned int _prunum;

    public:
        PRU(const char *pru_firmware, unsigned int pru_num);
        ~PRU();

        unsigned int *GetSharedMemPointer();
};

#endif // __PRU_H__
