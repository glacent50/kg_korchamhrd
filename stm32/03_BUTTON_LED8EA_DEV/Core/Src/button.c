
#include "button.h"


BUTTON_CONTROL button[3] =
{
    {GPIOC, GPIO_PIN_8, 0},
    {GPIOC, GPIO_PIN_6, 0},
    {GPIOC, GPIO_PIN_5, 0},
};

// HAL_Delay 사용
//bool buttonGetPressed(uint8_t num)
//{
//  bool ret = false;
//
//  if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//  {
//    HAL_Delay(30);  // 디바운스 타임.
//
//    if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//    {
//      ret = true;
//    }
//
//  }
//
//  return ret;
//}

/* HAL_GetTick() 사용 */
//bool buttonGetPressed(uint8_t num)
//{
//  static uint32_t prevTime = 0;
//
//  bool ret = false;
//
//  if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//  {
//    const uint32_t currTime = HAL_GetTick();
//    if (currTime - prevTime > 30)
//    {
//      if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//      {
//        ret = true;
//      }
//
//      prevTime = currTime;
//    }
//  }
//
//  return ret;
//}

/* 최초 처음부터 디바운스 */
//bool buttonGetPressed(uint8_t num)
//{
//  static uint32_t prevTime = 0xFFFFFFFF;
//
//  if (prevTime == 0xFFFFFFFF) {
//    prevTime = HAL_GetTick();
//  }
//
//  bool ret = false;
//
//  if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//  {
//    const uint32_t currTime = HAL_GetTick();
//    if (currTime - prevTime > 30)
//    {
//      if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
//      {
//        ret = true;
//      }
//
//      prevTime = currTime;
//    }
//  }
//
//  return ret;
//}


/* 각 배열로 디바운스 코드 입력 */
bool buttonGetPressed(uint8_t num)
{
  static uint32_t prevTime[3] = {0xFFFFFFFF};

  if (prevTime[num] == 0xFFFFFFFF) {
    prevTime[num] = HAL_GetTick();
  }

  bool ret = false;

  if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
  {
    const uint32_t currTime = HAL_GetTick();
    if (currTime - prevTime[num] > (30 * 10))
    {
      if (HAL_GPIO_ReadPin(button[num].port, button[num].pinNumber) == button[num].onState)
      {
        ret = true;
      }

      prevTime[num] = currTime;
    }
  }

  return ret;
}







