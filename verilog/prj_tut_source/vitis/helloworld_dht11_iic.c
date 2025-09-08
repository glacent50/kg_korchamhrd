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
#include "sleep.h"
#include "xiic.h"


#define DHT11_ADDR XPAR_MYIP_DHT11_0_BASEADDR
#define IIC_ADDR XPAR_AXI_IIC_0_BASEADDR

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
  XIic_Send(iic_instance.BaseAddress, 0x27, 
        data_array, 4, XIIC_STOP);
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
  msleep(2);
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
  usleep(2000);
}


int main()
{
    init_platform();

    print("Start\n\r");
    volatile unsigned int *dht11_instance = (volatile unsigned int*)DHT11_ADDR;
    XIic_Initialize(&iic_instance, IIC_ADDR);
    i2cLcd_Init();
       
    lcdString("Humidity    : 00");
    moveCursor(1, 0); 
    lcdString("Temperature : 00");       
    char humidity_lcd[17];   
    char temperature_lcd[17];

    int humi;
    int tmpr;
    
    while(1){
        // printf("Humidity : %d\n", dht11_instance[0]);
        // printf("Temperature : %d\n", dht11_instance[1]);
        sleep(4);
        humi = (int)dht11_instance[0];
        moveCursor(0, 14);
        lcdData(humi / 10 % 10 + '0');
        lcdData(humi % 10 + '0');
        tmpr = (int)dht11_instance[1];
        moveCursor(1, 14);
        lcdData(tmpr / 10 % 10 + '0');
        lcdData(tmpr % 10 + '0');
    }
    cleanup_platform();
    return 0;
}
