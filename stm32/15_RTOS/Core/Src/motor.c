#include "motor.h"


// 제어 명령 상수
#define STEER_NONE     0
#define STEER_LEFT     1
#define STEER_RIGHT    2

#define SPEED_STOP     0
#define SPEED_SLOW     1
#define SPEED_NORMAL   2

#define BRAKE_NONE     0
#define BRAKE_EMERGENCY 1


static const uint32_t TIM3_CCR_MIN = 300;

static const uint32_t SPEED_STEP_0 = TIM3_CCR_MIN + (70 * 0);
static const uint32_t SPEED_STEP_1 = TIM3_CCR_MIN + (70 * 1);
static const uint32_t SPEED_STEP_2 = TIM3_CCR_MIN + (70 * 2);
static const uint32_t SPEED_STEP_3 = TIM3_CCR_MIN + (70 * 3);
static const uint32_t SPEED_STEP_4 = TIM3_CCR_MIN + (70 * 4);
static const uint32_t SPEED_STEP_5 = TIM3_CCR_MIN + (70 * 5);
static const uint32_t SPEED_STEP_6 = TIM3_CCR_MIN + (70 * 6);
static const uint32_t SPEED_STEP_7 = TIM3_CCR_MIN + (70 * 7);
static const uint32_t SPEED_STEP_8 = TIM3_CCR_MIN + (70 * 8);
static const uint32_t SPEED_STEP_9 = TIM3_CCR_MIN + (70 * 9);

static const uint32_t TIM3_CCR_MAX = 1000;

static uint32_t sCurrentSpeed = TIM3_CCR_MIN;

static void SetSpeedLeft(const uint32_t Speed)
{
	{// TIM3_CCR1
		if (Speed < TIM3_CCR_MIN) TIM3->CCR1 = TIM3_CCR_MIN;
		else if(Speed > TIM3_CCR_MAX) TIM3->CCR1 = TIM3_CCR_MAX;
		else TIM3->CCR1 = Speed;
	}
}

static void SetSpeedRight(const uint32_t Speed)
{
	{// TIM3_CCR2
		if (Speed < TIM3_CCR_MIN) TIM3->CCR2 = TIM3_CCR_MIN;
		else if (Speed > TIM3_CCR_MAX) TIM3->CCR2 = TIM3_CCR_MAX;
		else TIM3->CCR2 = Speed;
	}
}

static void SetSpeed(const uint32_t Speed)
{
	sCurrentSpeed = Speed;
	SetSpeedLeft(Speed);
	SetSpeedRight(Speed);
}

void AutoLeftBackControl()
{
	SetSpeed(SPEED_STEP_5);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET);

	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
}

void AutoRightBackControl()
{
	SetSpeed(SPEED_STEP_5);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
}



bool AutoSpeedControl(const uint8_t speed)
{
	bool ret = false;

	switch(speed)
	{
	case SPEED_NORMAL:
		SetSpeed(SPEED_STEP_9);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		ret = true;
		break;
	case SPEED_SLOW: // 회전시 적용
//		SetSpeed(SPEED_STEP_6);
//		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
//		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);
//
//		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
//		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		break;
	case SPEED_STOP:
//		SetSpeed(SPEED_STEP_6);
//		ret = true;
		break;
	}

	return ret;
}


bool AutoSteeringControl(const uint8_t steering)
{
	bool ret = false;

	switch(steering)
	{
	case STEER_NONE:
		//SetSpeed(SPEED_STEP_9);
		break;
	case STEER_LEFT:
		SetSpeed(SPEED_STEP_7);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);

		ret = true;
		break;
	case STEER_RIGHT:
		SetSpeed(SPEED_STEP_7);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);

		ret = true;
		break;
	}

	return ret;
}

bool AutoMoveSlowBack()
{
	SetSpeed(SPEED_STEP_3);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET);

	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
}



bool AutoBrakeControl(const uint8_t brake)
{
	bool ret = false;

	switch(brake)
	{
	case BRAKE_NONE:
		//SetSpeed(SPEED_STEP_9);
		break;
	case BRAKE_EMERGENCY:
		SetSpeed(SPEED_STEP_0);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5|GPIO_PIN_6, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8|GPIO_PIN_9, GPIO_PIN_RESET);
		ret = true;
		break;
	}

	return ret;
}

void MotorControl(const uint8_t rxChar)
{
	switch(rxChar)
	{
	case 'F': // move forward
		SetSpeed(sCurrentSpeed);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		break;

	case 'B': // move backward
		SetSpeed(sCurrentSpeed);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
		break;

	case 'R': // Turn Right
		SetSpeed(sCurrentSpeed);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		break;

	case 'L': // Turn Left
		SetSpeed(sCurrentSpeed);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		break;


	case 'G': // forward left
		SetSpeedLeft(sCurrentSpeed/6);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);

		break;

	case 'H': // forward right
		SetSpeedRight(sCurrentSpeed/6);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);

		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		break;

	case 'I': // backward left
		break;

	case 'J': // backward right
		break;

	case 'S': // Stop All motor
		HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5|GPIO_PIN_6, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8|GPIO_PIN_9, GPIO_PIN_RESET);
		break;

	case 'Y': break;
	case 'X': break;
	case 'x': break;
	// speed set
	case '0': SetSpeed(SPEED_STEP_0); break;
	case '1': SetSpeed(SPEED_STEP_1); break;
	case '2': SetSpeed(SPEED_STEP_2); break;
	case '3': SetSpeed(SPEED_STEP_3); break;
	case '4': SetSpeed(SPEED_STEP_4); break;
	case '5': SetSpeed(SPEED_STEP_5); break;
	case '6': SetSpeed(SPEED_STEP_6); break;
	case '7': SetSpeed(SPEED_STEP_7); break;
	case '8': SetSpeed(SPEED_STEP_8); break;
	case '9': SetSpeed(SPEED_STEP_9); break;

	default:
		break;
	}

}

