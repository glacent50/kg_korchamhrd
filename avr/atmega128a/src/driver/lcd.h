#ifndef LCD_H
#define LCD_H

#include "../common/def.h"

#define LCD_DATA_DDR        DDRF
#define LCD_DATA_PORT       PORTF

#define LCD_RS_DDR          DDRE
#define LCD_RW_DDR          DDRE
#define LCD_E_DDR           DDRE
#define LCD_RS_PORT         PORTE
#define LCD_RW_PORT         PORTF
#define LCD_E_PORT          PORTE
#define LCD_RS              7
#define LCD_RW              6
#define LCD_E               5

// 명령어 세팅
#define COMMAND_DISPLAY_CLEAR   0x01
#define COMMAND_DISPLAY_ON      0x0c
#define COMMAND_DISPLAY_OFF     0x08
#define COMMAND_ENTRY_MODE      0x06
#define COMMAND_8BIT_MODE       0x38

// 4bit mode
#define COMMAND_4BIT_MODE       0x28

void LCD_Data(uint8_t data);      // 8bit
void LCD_Data_4Bit(uint8_t data); // 4bit

void LCD_WritePin();
void LCD_EnablePin();
void LCD_WriteCommand(uint8_t commandData);
void LCD_WriteData(uint8_t charData);
void LCD_GotoXY(uint8_t row, uint8_t col);
void LCD_WriteString(char *string);
void LCD_WriteStringXY(uint8_t row, uint8_t col, char *string);
void LCD_Init();

#endif / LCD_H /
