#include "led.h"

//// PC9, PB8, PB9, PA5, PA6, PA7, PB8, PC7,PA9

  /*Configure GPIO pins : PA5 PA6 PA7 PA14 */
  //GPIO_InitStruct.Pin = GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7|GPIO_PIN_14;

  /*Configure GPIO pins : PC7 PC9 */
  //GPIO_InitStruct.Pin = GPIO_PIN_7|GPIO_PIN_9;

  /*Configure GPIO pins : PB6 PB8 PB9 */
  //GPIO_InitStruct.Pin = GPIO_PIN_6|GPIO_PIN_8|GPIO_PIN_9;

LED_CONTROL led[8] =
    {
        {GPIOC, GPIO_PIN_9, 1 , 0}, //
        {GPIOB, GPIO_PIN_8, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOB, GPIO_PIN_9, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOB, GPIO_PIN_6, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOA, GPIO_PIN_5, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOA, GPIO_PIN_6, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOA, GPIO_PIN_7, GPIO_PIN_SET , GPIO_PIN_RESET},
        {GPIOC, GPIO_PIN_7, GPIO_PIN_SET , GPIO_PIN_RESET}, //
    };

void ledOn(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].onState);
  }

}
void ledOff(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].offState);
  }

}
void ledToggle(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].onState);
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].offState);

  }

}


void ledLeftShift(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    HAL_GPIO_TogglePin(led[i].port, led[i].pinNumber);
  }
}

void ledRightShift(uint8_t num)
{

}

void ledFlower(uint8_t num)
{

}



