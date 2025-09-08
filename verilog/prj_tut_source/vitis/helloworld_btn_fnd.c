/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdint.h>
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xparameters.h"
#include "xgpio.h"

#define BTN_ADDR XPAR_AXI_GPIO_BTN_BASEADDR
#define BTN_CHANNEL 1

#define FND_ADDR XPAR_AXI_GPIO_FND_BASEADDR
#define COM_CHANNEL 1
#define SEG_CHANNEL 2




int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application\n");

    XGpio btn_inst, fnd_inst;
    XGpio_Initialize(&btn_inst, BTN_ADDR);
    XGpio_SetDataDirection(&btn_inst, 
                    BTN_CHANNEL, 0xf);
    XGpio_Initialize(&fnd_inst, FND_ADDR);
    XGpio_SetDataDirection(&fnd_inst, 
                    COM_CHANNEL, 0);
    XGpio_SetDataDirection(&fnd_inst, 
                    SEG_CHANNEL, 0);                                    
    uint32_t btn_data;                      
    while(1){
        print("hello\n");
        btn_data = XGpio_DiscreteRead(&btn_inst, 
                        BTN_CHANNEL);
        printf("Button value : %x\n", btn_data);        
        sleep(1);    
    }
    cleanup_platform();
    return 0;
}
