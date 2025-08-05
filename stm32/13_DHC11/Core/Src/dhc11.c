/*
 * dhc11.c
 *
 *  Created on: Jul 1, 2025
 *      Author: user22
 */

#include "dhc11.h"

void dht11Init(DHT11 *dht, GPIO_TypeDef *port, uint16_t pin)
{
  dht->port = port;
  dht->pin = pin;
}


void dht11GpioMode(DHT11 *dht, uint8_t mode)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  // 출려모드 설정
  if (mode == OUTPUT)
  {
    /*Configure GPIO pin : PC4 */
    GPIO_InitStruct.Pin = dht->pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(dht->port, &GPIO_InitStruct);
  }
  else if (mode == INPUT)
  {
    /*Configure GPIO pin : PC4 */
    GPIO_InitStruct.Pin = dht->pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(dht->port, &GPIO_InitStruct);
  }
}

bool dht11Read(DHT11 *dht)
{
  bool ret = true;

  uint16_t timeTick = 0; //시간 측정

  uint8_t pulse[40] = {0,};

  uint8_t humValue1 = 0, humValue2 = 0;
  uint8_t tempValue1 = 0, tempValue2 = 0;
  uint8_t parityValue = 0;

  HAL_TIM_Base_Start(&htim11);

  // 통시신호 전송
  dht11GpioMode(dht, OUTPUT);

  HAL_GPIO_WritePin(dht->port, dht->pin, GPIO_PIN_RESET); // low
  HAL_Delay(20); // at least 18ms

  HAL_GPIO_WritePin(dht->port, dht->pin, GPIO_PIN_SET);  // high
  delay_us(30);

  //
  dht11GpioMode(dht, INPUT); // input mode 변경

  // 응답신호 대기
  __HAL_TIM_SET_COUNTER(&htim11, 0);
  while(HAL_GPIO_ReadPin(dht->port, dht->pin) == GPIO_PIN_RESET)
  {
    if(__HAL_TIM_GET_COUNTER(&htim11) > 100)
    {
      printf("Time out !! \r\n");
      break;
    }
  }

  __HAL_TIM_SET_COUNTER(&htim11, 0);
  while(HAL_GPIO_ReadPin(dht->port, dht->pin) == GPIO_PIN_RESET)
  {
    if(__HAL_TIM_GET_COUNTER(&htim11) > 100)
    {
      printf("Time out HIGH !! \r\n");
      break;
    }
  }

  for (uint8_t i =0 ; i<40 ; i++)
  {
    while(HAL_GPIO_ReadPin(dht->port, dht->pin) == GPIO_PIN_RESET); // low 50us 대기

    __HAL_TIM_SET_COUNTER(&htim11, 0);
    while(HAL_GPIO_ReadPin(dht->port, dht->pin) == GPIO_PIN_SET)
    {
      timeTick = __HAL_TIM_GET_COUNTER(&htim11); //  high 신호 시간 측정

      // 신호 길이에 따른 0, 1 구분
      if(timeTick > 20 && timeTick < 30){
        pulse[i] = 0;
      }
      else if(timeTick > 65 && timeTick < 85)
      {
        pulse[i] = 1;
      }
    }
  }

  HAL_TIM_Base_Stop(&htim11);


  // 온 습도 데이터 처리
  for (uint8_t i =0 ; i<8 ; i++)  {  humValue1 = (humValue1 << 1) + pulse[i];  }
  for (uint8_t i =8 ; i<16 ; i++)  {  humValue2 = (humValue2 << 1) + pulse[i];  }
  for (uint8_t i =16 ; i<24 ; i++)  {  tempValue1 = (tempValue1 << 1) + pulse[i];  }
  for (uint8_t i =24 ; i<32 ; i++)  {  tempValue2 = (tempValue2 << 1) + pulse[i];  }
  for (uint8_t i =32 ; i<40 ; i++)  {  parityValue = (parityValue << 1) + pulse[i];  }

  // 구조체에 입력
  dht->temperature = tempValue1;  // 온도데이터 저장
  dht->humidity = humValue1;      // 습도데이터 저장

  // 데이터 무결성
  uint8_t checkSum = humValue1 + humValue2 + tempValue1 + tempValue2;
  if(checkSum != parityValue)
  {
    printf("Check Sum Error \r\n");
    ret = false;
  }

  return ret;
}













