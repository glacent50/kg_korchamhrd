#include "lcd_llm.h"

extern XIic iic_instance;

// I2C LCD에 4비트 데이터 전송
void lcd_send_nibble(uint8_t nibble, uint8_t flags) {
    uint8_t data = nibble | flags | LCD_BACKLIGHT;
    
    // Enable 펄스 생성
    XIic_Send(iic_instance.BaseAddress, LCD_ADDR, &data, 1, XIIC_STOP);
    usleep(1000);
    
    data |= LCD_ENABLE;
    XIic_Send(iic_instance.BaseAddress, LCD_ADDR, &data, 1, XIIC_STOP);
    usleep(1000);
    
    data &= ~LCD_ENABLE;
    XIic_Send(iic_instance.BaseAddress, LCD_ADDR, &data, 1, XIIC_STOP);
    usleep(1000);
}

// I2C LCD에 8비트 데이터 전송
void lcd_send_byte(uint8_t data, uint8_t flags) {
    uint8_t high_nibble = data & 0xF0;
    uint8_t low_nibble = (data << 4) & 0xF0;
    
    lcd_send_nibble(high_nibble, flags);
    lcd_send_nibble(low_nibble, flags);
}

// LCD 명령어 전송
void lcd_send_command(uint8_t command) {
    lcd_send_byte(command, 0);  // RS=0 (명령어 모드)
    usleep(2000);
}

// LCD 데이터 전송 (문자)
void lcd_send_data(uint8_t data) {
    lcd_send_byte(data, LCD_REGISTER_SELECT);  // RS=1 (데이터 모드)
    usleep(2000);
}

// LCD 초기화
void lcd_init() {
    sleep(1);  // 전원 안정화 대기
    
    // 4비트 모드 초기화 시퀀스
    lcd_send_nibble(0x30, 0);
    usleep(4500);
    lcd_send_nibble(0x30, 0);
    usleep(4500);
    lcd_send_nibble(0x30, 0);
    usleep(150);
    lcd_send_nibble(0x20, 0);  // 4비트 모드 설정
    
    // LCD 설정
    lcd_send_command(LCD_FUNCTION_SET | 0x08);    // 4비트, 2라인, 5x8 폰트
    lcd_send_command(LCD_DISPLAY_CONTROL | 0x04); // 디스플레이 ON, 커서 OFF
    lcd_send_command(LCD_CLEAR_DISPLAY);          // 화면 지우기
    lcd_send_command(LCD_ENTRY_MODE_SET | 0x02);  // 입력 모드 설정
    
    sleep(1);
}

// LCD에 문자열 출력
void lcd_print(const char* str) {
    while (*str) {
        lcd_send_data(*str++);
    }
}

// LCD 커서 위치 설정
void lcd_set_cursor(uint8_t row, uint8_t col) {
    uint8_t address = (row == 0) ? 0x80 + col : 0xC0 + col;
    lcd_send_command(address);
}

// LCD 화면 지우기
void lcd_clear() {
    lcd_send_command(LCD_CLEAR_DISPLAY);
    usleep(2000);
}
