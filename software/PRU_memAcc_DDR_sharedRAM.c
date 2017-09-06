/*
 * PRU_memAccess_DDR_PRUsharedRAM.c
 *
 * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/
 *
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

/*
 * ============================================================================
 * Copyright (c) Texas Instruments Inc 2010-12
 *
 * Use of this software is controlled by the terms and conditions found in the
 * license agreement under which this software has been supplied or provided.
 * ============================================================================
 */

#include <stdio.h>
#include <unistd.h>

#include <pruss_intc_mapping.h>
#include <prussdrv.h>




#define PRU_NUM           0
#define PRU_CLOCKSPEED    200000000.0

int main (void)
{
    unsigned int ret;
    unsigned int result_left;
    unsigned int result_center;
    unsigned int result_right;
    double       pulse_width_left;
    double       pulse_width_center;
    double       pulse_width_right;
    unsigned int *pru_sharedmem;

    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

    /* Initialize the PRU */
    prussdrv_init ();

    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }

    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Loading firmware onto PRU to read pulse width sensors (ultrasonic and motor ESC) */
    prussdrv_exec_program (PRU_NUM, "./firmware/pulsewidth_sensors.bin");

    /* Allocate Shared PRU memory. */
    prussdrv_map_prumem(PRUSS0_SHARED_DATARAM, (void**)&pru_sharedmem);

    while(1)
    {
        // reading shared mem that contains pulse width values. 
        // values are stored in number of PRU clock cycles. to get
        // speed in MS we will divide by (PRU_CLOCKSPEED / 1000)
        result_left   = pru_sharedmem[0];
        result_center = pru_sharedmem[1];
        result_right  = pru_sharedmem[2];

        pulse_width_left   = (double)(result_left) / (PRU_CLOCKSPEED / 1000);
        pulse_width_center = (double)(result_center) / (PRU_CLOCKSPEED / 1000);
        pulse_width_right  = (double)(result_right) / (PRU_CLOCKSPEED / 1000);

        printf("pulse width left   %.2f ms\n", pulse_width_left);
        printf("pulse width center %.2f ms\n", pulse_width_center);
        printf("pulse width right  %.2f ms\n", pulse_width_right);

        usleep(10000);
    }

    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable(PRU_NUM);
    prussdrv_exit ();

    return(0);
}

