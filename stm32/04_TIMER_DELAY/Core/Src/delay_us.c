
#include "delay_us.h"


volatile uint8_t delay_done = 1;


void delay_us(uint16_t us)
{
  __HAL_TIM_SET_COUNTER(&htim11, 0);
  while((__HAL_TIM_GET_COUNTER(&htim11)) < us);
}

void delay_us_non_blocking(uint16_t us)
{
  if(delay_done)
  {
    delay_done = 0;
    HAL_TIM_Base_Stop_IT(&htim11);                      // 안전하게 멈춤
    __HAL_TIM_SET_COUNTER(&htim11, 0);                   // 카운터 초기화
    __HAL_TIM_SET_AUTORELOAD(&htim11, us - 1);           // 원하는 us만큼 설정
    __HAL_TIM_CLEAR_FLAG(&htim11, TIM_FLAG_UPDATE);      // 플래그 클리어
    HAL_TIM_Base_Start_IT(&htim11);                      // 타이머 + 인터럽트 시작
  }
}

uint8_t is_delay_done(void)
{
  return delay_done;
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  if(htim->Instance == TIM11)
  {
    delay_done = 1;
    __HAL_TIM_DISABLE_IT(&htim11, TIM_IT_UPDATE);
  }
}
