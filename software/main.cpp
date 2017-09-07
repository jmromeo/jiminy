#include <stdio.h>
#include <unistd.h>


#include "pru.h"
#include "ultrasonic.h"

int main (void)
{
    PRU pru0_sensors("./firmware/pulsewidth_sensors.bin", PRU0);

    // Setting up ultrasonic sensors
    Ultrasonic left_sensor(&pru0_sensors,   0);
    Ultrasonic center_sensor(&pru0_sensors, 1);
    Ultrasonic right_sensor(&pru0_sensors,  2);

    while(1)
    {
        printf("pulse width left   %.2f ms\n", left_sensor.GetPulseWidth());
        printf("pulse width center %.2f ms\n", center_sensor.GetPulseWidth());
        printf("pulse width right  %.2f ms\n", right_sensor.GetPulseWidth());

        usleep(100000);
    }

    return(0);
}

