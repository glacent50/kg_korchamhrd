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
#include <math.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"
#include "bmp180.h"
#include "xuartlite_l.h"   // 추가: UART Lite 매크로/인라인 (IsTransmitFull/IsReceiveEmpty 등)

// UART1 베이스 주소 (platform_gy_uart의 두 번째 UART)
#define UART1_BASE      XPAR_AXI_UARTLITE_1_BASEADDR

static void uart1_putc(uint8_t c) {
    // TX FIFO가 가득 차 있으면 대기
    while (XUartLite_IsTransmitFull(UART1_BASE)) { }
    XUartLite_SendByte(UART1_BASE, (u8)c);
}

static int uart1_getc_nonblock(uint8_t* out) {
    if (XUartLite_IsReceiveEmpty(UART1_BASE)) {
        return 0; // 수신 데이터 없음
    }
    *out = (uint8_t)XUartLite_RecvByte(UART1_BASE);
    return 1;
}


static void uart1_write(const char* s) {
    while (*s) {
        uart1_putc((uint8_t)*s++);
    }
}


int main()
{
    init_platform();

    // BMP180 초기화
    if (bmp180_init() != 0) {
        printf("BMP180 initialization failed!\r\n");
        cleanup_platform();
        return -1;
    }

    // 메인 루프
    int count = 0;
    BMP180_ResultData bmpResultData;
    bmpResultData.pressure = 0;
    bmpResultData.pressureMod = 0;
    bmpResultData.temperature = 0;
    bmpResultData.temperatureMod = 0;
    bmpResultData.altitude = 0;

    while (1) {
        ++count;

        if ((count % 4000) == 0) {
            printf("====================================\r\n");
        }        
        // UART1 에코 (수신 시 그대로 송신)
        uint8_t ch;
        if (uart1_getc_nonblock(&ch)) {
            //uart1_putc(ch);  // UART1로 에cho

            printf("receive [%c] \r\n", ch);     // 콘솔(UART0)에도 표시
        }

        // //예: 주기적으로 메시지 송신 (필요시 주석 해제)
        if ((count % 4000) == 0) {
            //uart1_write("[UART1] tick\r\n");
            //printf("[UART1] tick\r\n");
            uart1_putc('1');
        }


        printf("====================================\r\n");
        printf("BMP180 Sensor Reading #%d\r\n", ++count);
        if (bmp180_GetResultData(&bmpResultData) == 1) {
            printf("Temperature: %d.%d°C\r\n", bmpResultData.temperature, bmpResultData.temperatureMod);
            printf("Pressure:    %d.%d hPa\r\n", bmpResultData.pressure, bmpResultData.pressureMod); 
            if (bmpResultData.altitude > 0) {
                printf("Altitude:    %d m\r\n", bmpResultData.altitude);
            } else {
                printf("Altitude:    ERROR\r\n");
            }
        } else {
            printf("bmp180_GetResultData:    ERROR\r\n");
        }
        printf("====================================\r\n");

        // 1초 대기
        usleep(500);
    }
    
    cleanup_platform();
    return 0;
}
