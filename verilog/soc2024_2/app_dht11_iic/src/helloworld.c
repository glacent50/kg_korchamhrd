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
#include <xiic_l.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"

//#define LCD_LLM_VER

#ifdef LCD_LLM_VER
#include "lcd_llm.h"
#endif

#define DHT11_ADDR  XPAR_MYIP_DHT11_0_BASEADDR
#define IIC_ADDR    XPAR_XIIC_0_BASEADDR

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

    print("Start \n\r");

    // DHT11 인스턴스
    volatile unsigned int* dht11_instance = (volatile unsigned int*)DHT11_ADDR;

    // I2C 초기화
    XIic_Initialize(&iic_instance, IIC_ADDR);
    i2cLcd_Init();

    //--

#ifdef LCD_LLM_VER
    // LCD 초기화
    lcd_init();
#endif

    // uint8_t data_array[4]; 
    // data_array[0] = 0b00001000;

    char humidity_lcd[17];   
    char temperature_lcd[17];

    while (1) {
        int humi = (int)dht11_instance[0];
        int temp = (int)dht11_instance[1];
        printf("Humidity : %d\n",dht11_instance[0]);
        printf("Temperature : %d\n",dht11_instance[1]);
        sleep(4);

        Display_clear();
        usleep(2000);
        snprintf(humidity_lcd,    sizeof(humidity_lcd),    "Humidity:%3d", humi);
        snprintf(temperature_lcd, sizeof(temperature_lcd), "Temp    :%3d", temp);
        moveCursor(0, 0);
        lcdString(humidity_lcd);
        moveCursor(1, 0);
        lcdString(temperature_lcd);

#ifdef LCD_LLM_VER
        // LCD에 센서 데이터 업데이트
        char temp_str[16];
        char hum_str[16];
        
        snprintf(hum_str,  sizeof(hum_str),  "H:  %d", (int)dht11_instance[0]);
        snprintf(temp_str, sizeof(temp_str), "T:  %d", (int)dht11_instance[1]);
        
        lcd_set_cursor(0, 0);  // 첫 번째 줄 0번째 위치
        lcd_print(hum_str);
        
        lcd_set_cursor(1, 0);  // 두 번째 줄 0번째 위치  
        lcd_print(temp_str);
#endif

        // bit toggle add
        // data_array[0] = data_array[0] ^ 0b00001000; // d7 d6 d5 d4 BL en rw rs
        // XIic_Send(iic_instance.BaseAddress, 0x27, 
        //             data_array, 1, XIIC_STOP);

    }

    cleanup_platform();
    return 0;
}
