#include "lcd.h"

void LCD_Data(uint8_t data)
{
    LCD_DATA_PORT = data;
}

void LCD_Data_4Bit(uint8_t data)
{
    LCD_DATA_PORT = (LCD_DATA_PORT & 0x0f) | (data & 0xf0); // 상위 4 비트 추출,

    LCD_EnablePin();

    LCD_DATA_PORT = (LCD_DATA_PORT & 0x0f) | ( (data & 0x0f) << 4 );

    LCD_EnablePin();
}

void LCD_WritePin()
{
    LCD_RW_PORT &= ~(1<<LCD_RW);    // RW핀을 low로 설정, 쓰기모드
    // 반대로 읽기모드라면?
    // LCD_RW_PORT |= (1<<LCD_RW);
}

void LCD_EnablePin()
{
    LCD_E_PORT &= ~(1<<LCD_E);  // E핀 low 설정
    LCD_E_PORT |= (1<<LCD_E);   // E핀 high 설정
    LCD_E_PORT &= ~(1<<LCD_E);  // 다시 low
    _delay_ms(10);            // 일정시간 대기
}

void LCD_WriteCommand(uint8_t commandData)
{
    LCD_RS_PORT &= ~(1<<LCD_RS);    // RS핀 low설정, 명령어모드
    LCD_WritePin();                 // LCD 쓰기모드
    
    /*8bit*/
    //LCD_Data(commandData);          // 명령어 전송
    //LCD_EnablePin();                // LCD 동작신호
    
    /*4bit*/
    LCD_Data_4Bit(commandData);         // 명령어 전송 4bit
    
}

void LCD_WriteData(uint8_t charData)
{
    LCD_RS_PORT |= (1<<LCD_RS);     // RS핀 HIGH설정, 데이터모드
    LCD_WritePin();                     // LCD 쓰기모드
    //LCD_Data(charData);             // 데이터 전송
    //LCD_EnablePin();                // LCD 동작신호

    /*4bit*/
    LCD_Data_4Bit(charData);
}

void LCD_GotoXY(uint8_t row, uint8_t col)
{
    col %= 16;      // 열 인덱스를 0~15제한
    row %= 2;       // 행 인덱스를 0~1제한
    
    uint8_t address = (0x40 * row) + col;   // 주소계산
    uint8_t command = 0x80 + address;       // 주소값을 알리는 커맨드?
    LCD_WriteCommand(command);              // 주소를 설정한 커맨드를 LCD로 전송
}

void LCD_WriteString(char *string)
{
    for(uint8_t i = 0; string[i]; i++)
    {
        LCD_WriteData(string[i]);
    }
    
}

void LCD_WriteStringXY(uint8_t row, uint8_t col, char *string)
{
    LCD_GotoXY(row, col);
    LCD_WriteString(string);
}

void LCD_Init()
{
    LCD_DATA_DDR = 0xff;            // data핀 설정 
    LCD_RS_DDR |= (1<<LCD_RS);      // RS핀 츨력 설정
    LCD_RW_DDR |= (1<<LCD_RW);      // RW핀 출력 설정
    LCD_E_DDR |= (1<< LCD_E);       // Enable핀 출력 설정

    // 8bit init
    // _delay_ms(20);                  // 초기 대기시간
    // LCD_WriteCommand(COMMAND_8BIT_MODE);
    // _delay_ms(5);
    // LCD_WriteCommand(COMMAND_8BIT_MODE);
    // _delay_ms(5);
    // LCD_WriteCommand(COMMAND_8BIT_MODE);
    // LCD_WriteCommand(COMMAND_8BIT_MODE);
    // LCD_WriteCommand(COMMAND_DISPLAY_OFF);
    // LCD_WriteCommand(COMMAND_DISPLAY_CLEAR);
    // LCD_WriteCommand(COMMAND_DISPLAY_ON);       // 데이터시트는 이거만 본인이 집어넣을것
    // LCD_WriteCommand(COMMAND_ENTRY_MODE);

    // 4bit 
    _delay_ms(20);                  // 초기 대기시간
    LCD_WriteCommand(0x03);
    _delay_ms(5);
    LCD_WriteCommand(0x03);
    _delay_ms(5);
    LCD_WriteCommand(0x03);
    LCD_WriteCommand(0x02);

    LCD_WriteCommand(COMMAND_4BIT_MODE);
    

    LCD_WriteCommand(COMMAND_DISPLAY_OFF);
    LCD_WriteCommand(COMMAND_DISPLAY_CLEAR);
    LCD_WriteCommand(COMMAND_DISPLAY_ON);       // 데이터시트는 이거만 본인이 집어넣을것
    LCD_WriteCommand(COMMAND_ENTRY_MODE);    
}
