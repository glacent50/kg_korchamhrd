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

//#include <stdint.h>
#include <stdio.h>
#include <sys/_intsup.h>
#include <sys/_types.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio.h"
#include "xintc.h"
#include "xuartlite.h"
#include "xil_exception.h"
#include "sleep.h"

#define UART_ADDR   XPAR_XUARTLITE_0_BASEADDR
#define BTN_ADDR    XPAR_AXI_GPIO_0_BASEADDR
#define INTC_ADDR   XPAR_XINTC_0_BASEADDR

#define UART_VEC_ID XPAR_FABRIC_AXI_UARTLITE_0_INTR
#define BTN_VECT_ID XPAR_FABRIC_AXI_GPIO_0_INTR

#define BTN_CHANNEL 1

XGpio btn_instance;
XIntc intc_instance;
XUartLite uart_instance;

void btn_isr(void *CallBackRef);
void ReceHandler(void *CallBackRef, unsigned int EventData);
void SendHandler(void *CallBackRef, unsigned int EventData);

int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Hello World application f \n");

    XUartLite_Initialize(&uart_instance, UART_ADDR);
    XGpio_Initialize(&btn_instance, BTN_ADDR);
    XIntc_Initialize(&intc_instance, INTC_ADDR);

    XGpio_SetDataDirection(&btn_instance, BTN_CHANNEL, 0b1111);

    XIntc_Connect(&intc_instance, UART_VEC_ID, (XInterruptHandler)XUartLite_InterruptHandler, (void *)&uart_instance);
    XIntc_Connect(&intc_instance, BTN_VECT_ID, (XInterruptHandler)btn_isr, (void *)&btn_instance);

    XIntc_Enable(&intc_instance, UART_VEC_ID);
    XIntc_Enable(&intc_instance, BTN_VECT_ID);

    XIntc_Start(&intc_instance, XIN_REAL_MODE);

    XGpio_InterruptEnable(&btn_instance, BTN_CHANNEL);
    XGpio_InterruptGetEnabled(&btn_instance);

    XUartLite_SetRecvHandler(&uart_instance, ReceHandler, &uart_instance);
    XUartLite_SetSendHandler(&uart_instance, SendHandler, &uart_instance);

    XUartLite_EnableInterrupt(&uart_instance);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XIntc_InterruptHandler, &intc_instance);
    Xil_ExceptionEnable();


    while (1) {
        sleep(1);
    }

    cleanup_platform();
    return 0;
}


void btn_isr(void *CallBackRef)
{
    unsigned int btn_value;
    print("Button Interrupt \n");
    XGpio *Gpio_ptr = (XGpio *)CallBackRef;
    
    btn_value = XGpio_DiscreteRead(Gpio_ptr, BTN_CHANNEL);
    if (btn_value == 1) {
        print("Button 0 rising \n");
         
    } else if (btn_value == 0) {
        print("Button 1 falling \n");
    }

    XGpio_InterruptClear(Gpio_ptr, BTN_CHANNEL);
    return;
}


void ReceHandler(void *CallBackRef, unsigned int EventData)
{
    u8 rxData;
    XUartLite_Recv(CallBackRef, &rxData, 1);

    printf("recv %c\n", rxData);
    return;
}

void SendHandler(void *CallBackRef, unsigned int EventData)
{
    return;
}





