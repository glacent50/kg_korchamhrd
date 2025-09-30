#ifndef LLM_LCD_H_
#define LLM_LCD_H_


#include <stdint.h>
#include <stdio.h>
#include <xiic_l.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"


/*
 * I2C LCD는 4bit 통신
 */


#define LCD_ADDR    0x27  // I2C LCD 주소 (일반적으로 0x27 또는 0x3F)

// LCD 제어 비트 정의 (PCF8574 기준)
#define LCD_BACKLIGHT   0x08
#define LCD_ENABLE      0x04
#define LCD_READ_WRITE  0x02
#define LCD_REGISTER_SELECT 0x01

// LCD 명령어 정의
#define LCD_CLEAR_DISPLAY   0x01
#define LCD_RETURN_HOME     0x02
#define LCD_ENTRY_MODE_SET  0x04
#define LCD_DISPLAY_CONTROL 0x08
#define LCD_CURSOR_SHIFT    0x10
#define LCD_FUNCTION_SET    0x20
#define LCD_SET_CGRAM_ADDR  0x40
#define LCD_SET_DDRAM_ADDR  0x80

void lcd_send_nibble(uint8_t nibble, uint8_t flags);
void lcd_send_byte(uint8_t data, uint8_t flags);
// LCD 명령어 전송
void lcd_send_command(uint8_t command);
void lcd_send_data(uint8_t data);

// LCD 초기화
void lcd_init();
void lcd_print(const char* str);
void lcd_set_cursor(uint8_t row, uint8_t col);
void lcd_clear();


#endif /* LLM_LCD_H_ */