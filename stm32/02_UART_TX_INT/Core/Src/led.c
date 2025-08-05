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
    HAL_GPIO_TogglePin(led[i].port, led[i].pinNumber);
  }
}

void ledLeftShift(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].onState);
    HAL_Delay(100);
    HAL_GPIO_WritePin(led[i].port, led[i].pinNumber, led[i].offState);;
  }
}

void ledRightShift(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    uint8_t idx = num-i; //8, 7, 6, 5, 4, 3, 2, 1
    idx = idx -1;        //7, 6, 5, 4, 3, 2, 1, 0

    HAL_GPIO_WritePin(led[idx].port, led[idx].pinNumber, led[idx].onState);
    HAL_Delay(100);
    HAL_GPIO_WritePin(led[idx].port, led[idx].pinNumber, led[idx].offState);
  }
}

void ledFlower(uint8_t num)
{
  for(uint8_t i=0 ; i<num ; i++)
  {
    uint8_t start = i;           //0, 1, 2, 3, 4, 5, 6, 7
    uint8_t last  = (num-i) - 1; //7, 6, 5, 4, 3, 2, 1, 0

    HAL_GPIO_WritePin(led[start].port, led[start].pinNumber, led[start].onState);
    HAL_GPIO_WritePin(led[last].port, led[last].pinNumber, led[last].onState);

    HAL_Delay(100);

    HAL_GPIO_WritePin(led[start].port, led[start].pinNumber, led[start].offState);
    HAL_GPIO_WritePin(led[last].port, led[last].pinNumber, led[last].offState);
  }



}



