#include "led.h"



void ledInit(LED *led)      // 매개변수로 포인터 변수 선언
{
    //LED_DDR = 0xff;

    *(led->port - 1) |= (1 << led->pinNumber);
    // DDR 레지스터는 PORT 레지스터보다 1 낮게 위치하므로
    // *(led->port - 1) 를 이용해서 PORT에서 DDR로 접근
    // |= (1 << led->pinNumber) 를 OR연산을 통해서 
    // led->pinNumber로 지정된 포트를 출력으로 설정 !!!
}

void ledInitAll()
{
    LED_DDR = 0xff;
}

void ledOnAll()
{
    LED_PORT = 0xff;
}


void ledOn(LED *led)
{
    // 해당 핀 (내가 원하는 자리!!) HIGH로 설정해서 LED ON
    *(led->port) |= (1 << led->pinNumber);
}

void ledOff(LED *led)
{
    // 해당 핀 (내가 원하는 자리!!) LOW로 설정해서 LED OFF
    *(led->port) &= ~(1 << led-> pinNumber);
}

#if 0
#include "led.h"

void ledInit(LED *led)
{
    //    LED_DDR = 0xFF;

    *(led->port - 1) |= 0xFF;

    // 지정된 포트를 출력으로 설정
    // led->port가 PORTx를 가리키므로, (led->port - 1)은 해당 포트의 DDRx를 가리킴
    // led->pinNumber에 해당하는 비트를 1로 설정하여 출력으로 만듦

    //*(led->port - 1) |= (1 << led->pinNumber);
    //*(led->port - 1) = (*(led->port - 1)) | (1 << led->pinNumber);

    // DDR 레지스터는 PORT 레지스터보다 1 낮게 위치하므로
    // *(led->port -1) 를 이용해서 PORT에서  DDR로 접근
    // |= (1 << led->pinNumber) 를 OR 연산을 통해서
    // led->pinNumber로 지정된 포트를 출력으로 설정 !!!
}

void ledOn(LED *led)
{
    // 해당 핀 HIGH
    *(led->port) |= (1 << led->pinNumber);
}

void ledOff(LED *led)
{
    // 해당 핀 LOW
    *(led->port) &= ~(1 << led->pinNumber);
    //*(led->port) &= ~(0b00000001 << led->pinNumber);
}

void ledLeftShift(LED *led)
{
    for (uint8_t i = 0; i < 8; i++)
    {
        led->pinNumber = (i);

        ledOn(led);
        _delay_ms(500);

        ledOff(led);
        _delay_ms(500);
    }
}

void ledRightShift(LED *led)
{
    for (uint8_t i = 0; i < 8; i++)
    {
        led->pinNumber = (7 - i) % 8;

        ledOn(led);
        _delay_ms(500);

        ledOff(led);
        _delay_ms(500);
    }
}

void ledFlower(LED *led)
{
    for (uint8_t i = 0; i < 4; i++)
    {
        led->pinNumber = 3-i;
        ledOn(led);
        led->pinNumber = (i+4); // 이걸 잘 모르겠음
        ledOn(led);
        _delay_ms(500);

        led->pinNumber = 3-i;
        ledOff(led);
        led->pinNumber = (i+4);
        ledOff(led);
        _delay_ms(500);
    }

    for (uint8_t i = 0; i < 4; i++)
    {
        led->pinNumber = 7-i;
        ledOn(led);
        led->pinNumber = (i); // 이걸 잘 모르겠음
        ledOn(led);
        _delay_ms(500);

        led->pinNumber = 7-i;
        ledOff(led);
        led->pinNumber = (i);
        ledOff(led);
        _delay_ms(500);
    }    

}

void ledOdd(LED *led)
{
    for (uint8_t i = 1; i < 5; i++)
    {
        led->pinNumber = (i * 2) - 2;
        ledOn(led);
        _delay_ms(500);

        ledOff(led);
        _delay_ms(500);
    }
}

void ledEven(LED *led)
{
    for (uint8_t i = 1; i < 5; i++)
    {
        led->pinNumber = (i * 2) - 1;
        ledOn(led);
        _delay_ms(500);

        ledOff(led);
        _delay_ms(500);
    }
}

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
//    *data = (1<<i) | (1 << (7-i));
//    //*data = (0b00000001 << i) | (0b00000001 << (7 - i));
// }
#endif