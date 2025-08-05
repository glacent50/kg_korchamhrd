#include "ultrasonic.h"
#include "delay_us.h"
#include "tim.h"        // 추가: htim3 선언 포함
#include "stdbool.h"
#include "cmsis_os.h"   // FreeRTOS 관련 헤더 추가
#include "queue.h"

extern QueueHandle_t xUltrasonicQueueHandle; // 큐 핸들 extern 선언

#define TRIG_PORT_CENTER GPIOC
#define TRIG_PIN_CENTER  GPIO_PIN_1

volatile uint8_t distance_Center = 0;

void HCSR04_trgger_center(void)
{
	HAL_GPIO_WritePin(TRIG_PORT_CENTER, TRIG_PIN_CENTER, GPIO_PIN_SET);
	delay_us(10);
	HAL_GPIO_WritePin(TRIG_PORT_CENTER, TRIG_PIN_CENTER, GPIO_PIN_RESET);

	__HAL_TIM_ENABLE_IT(&htim2, TIM_IT_CC1);
}


static bool HCSR04_TIM_IC_CaptureCallback_Center(TIM_HandleTypeDef *htim)
{
	static uint16_t IC_Value1_Center = 0;
	static uint16_t IC_Value2_Center = 0;
	static uint16_t echoTime_Center = 0;
	static uint8_t captureFlag_Center = 0;

	if(captureFlag_Center == 0) // 아직 캡처 안했다면
	{
		IC_Value1_Center = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_1);
		captureFlag_Center = 1;

		// 캡처에 대한 극성을 폴링으로 바꿈
		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_FALLING);
		return false;
	}
	else if(captureFlag_Center == 1) //캡처를 했다면
	{
		IC_Value2_Center = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_1);

		__HAL_TIM_SET_COUNTER(&htim2, 0);

		if (IC_Value2_Center > IC_Value1_Center)
		{
			echoTime_Center = IC_Value2_Center - IC_Value1_Center;
		}
		else if(IC_Value1_Center > IC_Value2_Center)
		{
			echoTime_Center = (0xFFFF - IC_Value1_Center) +IC_Value2_Center;
		}

		distance_Center = echoTime_Center / 58;
		captureFlag_Center = 0;

		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_RISING);
		__HAL_TIM_DISABLE_IT(&htim2, TIM_IT_CC1);

		return true;
	}
	return false;
}

#define TRIG_PORT_RIGHT GPIOC
#define TRIG_PIN_RIGHT  GPIO_PIN_2

volatile uint8_t distance_Right = 0;

void HCSR04_trgger_right(void)
{
	HAL_GPIO_WritePin(TRIG_PORT_RIGHT, TRIG_PIN_RIGHT, GPIO_PIN_SET);
	delay_us(10);
	HAL_GPIO_WritePin(TRIG_PORT_RIGHT, TRIG_PIN_RIGHT, GPIO_PIN_RESET);

	__HAL_TIM_ENABLE_IT(&htim2, TIM_IT_CC2);
}

static bool HCSR04_TIM_IC_CaptureCallback_Right(TIM_HandleTypeDef *htim)
{
	static uint16_t IC_Value1_Right = 0;
	static uint16_t IC_Value2_Right = 0;
	static uint16_t echoTime_Right = 0;
	static uint8_t captureFlag_Right = 0;

	if(captureFlag_Right == 0) // 아직 캡처 안했다면
	{
		IC_Value1_Right = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_2);
		captureFlag_Right = 1;

		// 캡처에 대한 극성을 폴링으로 바꿈
		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_2, TIM_INPUTCHANNELPOLARITY_FALLING);
		return false;
	}
	else if(captureFlag_Right == 1) //캡처를 했다면
	{
		IC_Value2_Right = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_2);

		__HAL_TIM_SET_COUNTER(&htim2, 0);

		if (IC_Value2_Right > IC_Value1_Right)
		{
			echoTime_Right = IC_Value2_Right - IC_Value1_Right;
		}
		else if(IC_Value1_Right > IC_Value2_Right)
		{
			echoTime_Right = (0xFFFF - IC_Value1_Right) +IC_Value2_Right;
		}

		distance_Right = echoTime_Right / 58;
		captureFlag_Right = 0;

		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_2, TIM_INPUTCHANNELPOLARITY_RISING);
		__HAL_TIM_DISABLE_IT(&htim2, TIM_IT_CC2);

		return true;
	}
	return false;
}


#define TRIG_PORT_LEFT GPIOC
#define TRIG_PIN_LEFT  GPIO_PIN_3

volatile uint8_t distance_Left = 0;

void HCSR04_trgger_left(void)
{
	HAL_GPIO_WritePin(TRIG_PORT_LEFT, TRIG_PIN_LEFT, GPIO_PIN_SET);
	delay_us(10);
	HAL_GPIO_WritePin(TRIG_PORT_LEFT, TRIG_PIN_LEFT, GPIO_PIN_RESET);

	__HAL_TIM_ENABLE_IT(&htim2, TIM_IT_CC3);
}

static bool HCSR04_TIM_IC_CaptureCallback_Left(TIM_HandleTypeDef *htim)
{
	static uint16_t IC_Value1_Left = 0;
	static uint16_t IC_Value2_Left = 0;
	static uint16_t echoTime_Left = 0;
	static uint8_t captureFlag_Left = 0;

	if(captureFlag_Left == 0) // 아직 캡처 안했다면
	{
		IC_Value1_Left = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_3);
		captureFlag_Left = 1;

		// 캡처에 대한 극성을 폴링으로 바꿈
		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_3, TIM_INPUTCHANNELPOLARITY_FALLING);
		return false;
	}
	else if(captureFlag_Left == 1) //캡처를 했다면
	{
		IC_Value2_Left = HAL_TIM_ReadCapturedValue(&htim2, TIM_CHANNEL_3);

		__HAL_TIM_SET_COUNTER(&htim2, 0);

		if (IC_Value2_Left > IC_Value1_Left)
		{
			echoTime_Left = IC_Value2_Left - IC_Value1_Left;
		}
		else if(IC_Value1_Left > IC_Value2_Left)
		{
			echoTime_Left = (0xFFFF - IC_Value1_Left) +IC_Value2_Left;
		}

		distance_Left = echoTime_Left / 58;
		captureFlag_Left = 0;

		__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_3, TIM_INPUTCHANNELPOLARITY_RISING);
		__HAL_TIM_DISABLE_IT(&htim2, TIM_IT_CC3);

		return true;
	}
	return false;
}


bool HCSR04_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)
{
	if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1)
	{
		return HCSR04_TIM_IC_CaptureCallback_Center(htim);
	}

	if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_2)
	{
		return HCSR04_TIM_IC_CaptureCallback_Right(htim);
	}

	if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_3)
	{
		return HCSR04_TIM_IC_CaptureCallback_Left(htim);
	}

	return false;
}













