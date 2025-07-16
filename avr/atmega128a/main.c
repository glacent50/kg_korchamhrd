// #include <stdio.h>
// #include <avr/io.h>
// #include <util/delay.h>

// int main()
// {
//    DDRD=0xff; // 0b
//    while (1)
//    {
//       PORTD = 0x00; // 0b 0000 0000
//         _delay_ms(500);
//         PORTD = 0xff; // 0b 1111 1111
//         _delay_ms(500);
//    }
// }

// uint8_t ledArr[] = {
//     0x00, // 0000 0000
//     0x80, // 1000 0000
//     0xC0, // 1100 0000
//     0xE0, // 1110 0000
//     0xF0, // 1111 0000

//     0xF0, // 1111 0000
//     0xF8, // 1111 1000
//     0xFC, // 1111 1100
//     0xFE, // 1111 1110
//     0xFF, // 1111 1111

//     0x7F, // 0111 1111
//     0x3F, // 0011 1111
//     0x1F, // 0001 1111
//     0x0F, // 0000 1111

//     0x0F, // 0000 1111
//     0x07, // 0000 0111
//     0x03, // 0000 0011
//     0x01, // 0000 0001
// };

// int main()
// {
//    DDRD = 0xFF;

//    // uint8_t arrSize = sizeof(arrSize) / sizeof (ledArr[0]);
//    uint8_t arrSize = sizeof(arrSize); // same

//    while (1)
//    {
//       for (uint16_t i = 0; i < 8; i++)
//       {
//          PORTD = (1 << i);
//          _delay_ms(200);
//       }

//    }

//    return 0;
// }

// #define LED_DDR DDRD
// #define LED_PORT PORTD

// int main(){
//    LED_DDR = 0xff;

//    for(uint8_t i = 0 ; i < 4 ; i++){
//       LED_PORT = (0x01 << i) | (0x80 >> 1);
//       //LED_PORT = (0b00000001 << i) | (0b10000000 >> 1);
//       _delay_ms(500);
//    }

//    for(uint8_t i = 0 ; i < 4 ; i++){
//       LED_PORT =  (0x10 << i) | (0x08 >> i);
//       //LED_PORT =  (0b00010000 << i) | (0b00001000 >> i);
//       _delay_ms(500);
//    }

//    uint8_t aaaa = 0;
// }

// #define LED_DDR DDRD
// #define LED_PORT PORTD

// //LED 출력함수
// void GPIO_Output(uint8_t data) // LED 포트에 8비트 데이터 매개변수로 받음.
// {
//    LED_PORT = data;
// }

// void ledInit()
// {
//    LED_DDR = 0xFF;

// }

// //이동함수
// void ledShift(uint8_t i, uint8_t *data) // 포인터 선언
// {
//    // i번째 비트와 (7-i)번째 비트를 1로 설정합니다.
//    // 예를 들어, i=2이면 (1<<2)은 0b00000100, (1<<(7-2))는 0b00100000이므로
//    // 결과적으로 0b00100100이 됩니다.

//    *data = (1<<i) | (1 << (7-i));
//    //*data = (0b00000001 << i) | (0b00000001 << (7 - i));
// }

// int main()
// {
//    ledInit();

//    uint8_t ledData = 0x81;
//    // uint8_t ledData = 0b10000001; // 0x81, 2진수 리터럴로 변경

//    while (1)
//    {
//       for(uint8_t i = 0 ; i<8 ; i++)
//       {
//          ledShift(i, &ledData);
//          GPIO_Output(ledData);
//          _delay_ms(400);
//       }

//       // GPIO_Output(0x00);
//       // _delay_ms(500);
//       // GPIO_Output(0xff);
//       // _delay_ms(500);
//    }
// }

// #include "led.h"

// int main()
// {
//    uint8_t fndNumber[] = {
//       0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x27, 0x7F, 0x67
//    };

//    //int count = 0; //2byte
//    uint16_t count = 0;
//    DDRF = 0xFF; //fnd port

//    while (1)
//    {
//       PORTF = ~fndNumber[count];
//       count = (count +1) % 10;

//       _delay_ms(500);
//    }

// }

// int main()
// {
//    LED led;

//    led.port = &PORTD;
//    led.pinNumber = 0;
//    ledInit(&led);

//    while (1)
//    {
//       ledFlower(&led);

//       ledLeftShift(&led);

//       ledRightShift(&led);

//       ledOdd(&led);

//       ledEven(&led);

//    }
// }

// int main()
// {
//    LED led;
//    led.port = &PORTD;
//    led.pinNumber = 0;

//    ledInit(&led);

//    while (1)
//    {
//       ledOn(&led);

//       _delay_ms(500);

//       ledOff(&led);

//       _delay_ms(500);

//    }

// }

// int main()
// {
//    ledInit();

//    // 0x81, 2진수 리터럴로 변경
//    uint8_t ledData = 0x81; // 16진수
//    //unint8_t ledData = 0b10000001; // 2진수

//    while (1)
//    {
//       for(uint8_t i = 0 ; i<8 ; i++)
//       {
//          ledShift(i, &ledData);
//          GPIO_Output(ledData);
//          _delay_ms(400);
//       }
//    }

// }

// int main()
// {
//    uint8_t buttonData;

//    while (1)
//    {
//       buttonData = PING;
//       if (buttonData & (1 << 2) == 0)
//       {
//          PORTD = 0xff;
//       }

//       if (buttonData & (1 << 3) == 0)
//       {
//          // ledLeftShift()
//       }

//       if (buttonData & (1 << 4) == 0)
//       {
//          PORTD = 0x00;
//       }
//    }
// }

// #include "../src/driver/led.h"
// #include "../src/driver/button.h"

// int main()
// {
//    LED_DDR = 0xff;

//    // 버튼관련 변수 선얼
//    BUTTON btnOn;
//    BUTTON btnOff;
//    BUTTON btnToggle;

//    buttonInit(&btnOn, &BUTTON_DDR, &BUTTON_PIN, BUTTON_ON);
//    buttonInit(&btnOff, &BUTTON_DDR, &BUTTON_PIN, BUTTON_OFF);
//    buttonInit(&btnToggle, &BUTTON_DDR, &BUTTON_PIN, BUTTON_TOGGLE);

//    while (1)
//    {
//       if (buttonGetState(&btnOn) == ACT_PUSH)
//       {
//          LED_PORT = 0xff;
//       }

//       if (buttonGetState(&btnOff) == ACT_PUSH)
//       {
//          LED_PORT = 0x00;
//       }

//       if (buttonGetState(&btnToggle) == ACT_PUSH)
//       {
//          LED_PORT ^= 0xff;
//       }
//    }
// }


#include "src/ap/ap.h"
#include <avr/interrupt.h>

int main()
{
   apInit();   // 애플리케이션 초기화 함수 호출
   
   sei();      // 전역 인터럽트 활성화

   apMain();   // 애플리케이션 메인 로직 함수 호출

   while (1)   // 무한 루프
   {
      // 루프 내부는 비어있음 - 프로그램이 종료되지 않도록 유지
   }
}






