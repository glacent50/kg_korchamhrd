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
#include "xparameters.h"
#include "xgpio.h"
#include "xiic.h"
#include "sleep.h"

#define BTN_ADDR XPAR_XGPIO_0_BASEADDR
#define STOPWATCH_ADDR XPAR_MYIP_STOP_WATCH_0_BASEADDR
#define IIC_ADDR XPAR_AXI_IIC_0_BASEADDR
#define BTN_CHANNEL 1


XIic iic_instance;

void lcdCommand(uint8_t command)
{
  uint8_t high_nibble, low_nibble;
  uint8_t data_array[4];
  high_nibble = command & 0xf0;
  low_nibble = (command <<4) & 0xf0;
  data_array[0] = high_nibble | 0x04 | 0x08;   
  data_array[1] = high_nibble | 0x00 | 0x08;   
  data_array[2] = low_nibble | 0x04 | 0x08;    
  data_array[3] = low_nibble | 0x00 | 0x08;    
  XIic_Send(iic_instance.BaseAddress, 0x27, data_array, 4, XIIC_STOP);
  usleep(50);
}

void lcdData(uint8_t data)
{
  uint8_t high_nibble, low_nibble;
  uint8_t data_array[4];
  high_nibble = data & 0xf0;
  low_nibble = (data << 4) & 0xf0;
  data_array[0] = high_nibble |0x05 |0x08;
  data_array[1] = high_nibble |0x01 |0x08;
  data_array[2] = low_nibble |0x05 |0x08;
  data_array[3] = low_nibble |0x01 |0x08;
  XIic_Send(iic_instance.BaseAddress, 0x27, data_array, 4, XIIC_STOP);
  usleep(50);
}

void i2cLcd_Init()
{
  msleep(50);
  lcdCommand(0x33);
  msleep(5);
  lcdCommand(0x32);
  msleep(5);
  lcdCommand(0x28);
  msleep(5);
  lcdCommand(0x0c);
  msleep(5);
  lcdCommand(0x06);
  msleep(5);
  lcdCommand(0x01);    //약 2ms 필요
  msleep(1);
}

void lcdString(char *str)
{
  while(*str)lcdData(*str++);
}

void moveCursor(uint8_t row, uint8_t col)
{
  lcdCommand(0x80 | row <<6 | col);
}

void Display_clear()
{
  lcdCommand(0x01);
}

int main()
{
    init_platform();

    print("Hello World\n\r");
    print("Successfully ran Hello World application\n");

    XGpio btn_instance;

    XGpio_Initialize(&btn_instance, BTN_ADDR );
    XGpio_SetDataDirection(&btn_instance, BTN_CHANNEL, 0b1111);

    XIic_Initialize(&iic_instance, IIC_ADDR);

    volatile unsigned int *stopwatch_instance = (volatile unsigned int*) STOPWATCH_ADDR;

    i2cLcd_Init();
    moveCursor(0, 0);
    lcdString("00:00:00");

    uint8_t btn_value;
    uint8_t btn_flag = 0;
    uint8_t lap_cnt = 0;

    while (1) {
        btn_value = XGpio_DiscreteRead(&btn_instance, BTN_CHANNEL);

        if(btn_value == 0) btn_flag = 0;
        else if(btn_value == 0b0001 && btn_flag == 0) {
            btn_flag = 1;
            stopwatch_instance[0] = stopwatch_instance[0] ^ 0b0001;
            
        }
        else if(btn_value == 0b0010 && btn_flag == 0) {
            btn_flag = 1;
            stopwatch_instance[0] = stopwatch_instance[0] | 0b0010;
            usleep(1);
            stopwatch_instance[0] = stopwatch_instance[0] & 0b1101;

            if (lap_cnt == 0){
                moveCursor(1, 0);
                //lcdString("~");
                lap_cnt = 1;
            }
            else if (lap_cnt == 1){
                moveCursor(1, 8);
                //lcdString("~");
                lap_cnt = 0;
            }

            lcdData(stopwatch_instance[6]/10%10 + '0');
            lcdData(stopwatch_instance[6]%10 + '0');
            lcdData(':');
            lcdData(stopwatch_instance[3]/10%10 + '0');
            lcdData(stopwatch_instance[3]%10 + '0');
            lcdData(':');
            lcdData(stopwatch_instance[4]/10%10 + '0');
            lcdData(stopwatch_instance[4]%10 + '0');
            msleep(1);
            
        }
        else if(btn_value == 0b0100 && btn_flag == 0) { // clear btn
            btn_flag = 1;

            // bit clear
            stopwatch_instance[0] = stopwatch_instance[0] | 0b0100;
            usleep(1);
            stopwatch_instance[0] = stopwatch_instance[0] & 0b1010; 

            //Display_clear();
            usleep(1);
            moveCursor(1, 0);
            lcdString("                 ");
            lap_cnt = 0;
        }

        moveCursor(0, 0);
        lcdData(stopwatch_instance[5]/10%10 + '0');
        lcdData(stopwatch_instance[5]%10 + '0');
        moveCursor(0, 3);
        lcdData(stopwatch_instance[1]/10%10 + '0');
        lcdData(stopwatch_instance[1]%10 + '0');
        moveCursor(0, 6);
        lcdData(stopwatch_instance[2]/10%10 + '0');
        lcdData(stopwatch_instance[2]%10 + '0');
        msleep(1);
    }

    cleanup_platform();
    return 0;
}