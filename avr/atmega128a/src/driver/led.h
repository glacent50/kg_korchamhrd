#ifndef __LED_H__
#define __LED_H__

#include "../common/def.h"


// 포트에 대한 설정 (방향-출력)
#define LED_DDR     DDRD
#define LED_PORT    PORTD

typedef struct test
{
    volatile uint8_t    *port;
    uint8_t             pinNumber;
}LED;

void ledInit(LED *led);
void ledOn(LED *led);
void ledOff(LED *led);

void ledInitAll();

void ledOnAll();

void ledLeftShift();
void ledRightShift();
void ledFlower();
void ledOdd();
void ledEven();


#endif /* __LED_H__ */


#if 0
#ifndef __LED_H__
#define __LED_H__

#include "../common/def.h"

// #define LED_DDR DDRD
// #define LED_PORT PORTD

typedef struct 
{
    volatile uint8_t *port;
    uint8_t          pinNumber;
} LED;

void ledInit(LED *led);
void ledOn(LED *led);
void ledOff(LED *led);


void ledLeftShift(LED *led);
void ledRightShift(LED *led);
void ledOdd(LED *led);
void ledEven(LED *led);

void ledFlower(LED *led);


#endif /* __LED_H__ */







// //LED 출력함수
// void GPIO_Output(uint8_t data);

// void ledInit();

// void ledShift(uint8_t i, uint8_t *data); // 포인터 선언
#endif