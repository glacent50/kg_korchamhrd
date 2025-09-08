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

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xgpio.h"

#define GPIO_ADDR XPAR_AXI_GPIO_LED_SW_BASEADDR
#define LED_CHANNEL 1
#define SW_CHANNEL 2

int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application");

    XGpio gpio_device;
    XGpio_Initialize(&gpio_device, GPIO_ADDR);
    XGpio_SetDataDirection(&gpio_device, 
                        LED_CHANNEL, 0);
    XGpio_DiscreteWrite(&gpio_device, 
                        LED_CHANNEL, 0xac0f);
    XGpio_SetDataDirection(&gpio_device, 
                        SW_CHANNEL, 0xffff);
    u32 data;    
    
    while(1){
        print("Hello\n");
        sleep(1);
        data = XGpio_DiscreteRead(&gpio_device, 
                        SW_CHANNEL);
        printf("switch : %x\n", data);
        XGpio_DiscreteWrite(&gpio_device, 
                        LED_CHANNEL, data);
    }

    cleanup_platform();
    return 0;
}
