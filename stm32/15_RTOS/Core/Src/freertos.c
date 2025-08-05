/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * File Name          : freertos.c
 * Description        : Code for freertos applications
 ******************************************************************************
 * @attention
 *
 * Copyright (c) 2025 STMicroelectronics.
 * All rights reserved.
 *
 * This software is licensed under terms that can be found in the LICENSE file
 * in the root directory of this software component.
 * If no LICENSE file comes with this software, it is provided AS-IS.
 *
 ******************************************************************************
 */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "delay_us.h"
#include "queue.h"      // 추가
#include "usart.h"      // 추가: huart2 선언 포함
#include "tim.h"        // 추가: htim3 선언 포함
#include "ultrasonic.h"
#include "motor.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */

QueueHandle_t uartRxQueue;

/* USER CODE END Variables */
/* Definitions for LED_TASK_1 */
osThreadId_t LED_TASK_1Handle;
const osThreadAttr_t LED_TASK_1_attributes = {
		.name = "LED_TASK_1",
		.stack_size = 128 * 4,
		.priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for ultrasonicTask */
osThreadId_t ultrasonicTaskHandle;
const osThreadAttr_t ultrasonicTask_attributes = {
		.name = "ultrasonicTask",
		.stack_size = 128 * 4,
		.priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for mainMoveTask */
osThreadId_t mainMoveTaskHandle;
const osThreadAttr_t mainMoveTask_attributes = {
		.name = "mainMoveTask",
		.stack_size = 128 * 4,
		.priority = (osPriority_t) osPriorityHigh,
};
/* Definitions for controlTask */
osThreadId_t controlTaskHandle;
const osThreadAttr_t controlTask_attributes = {
		.name = "controlTask",
		.stack_size = 128 * 4,
		.priority = (osPriority_t) osPriorityHigh1,
};
/* Definitions for xUltrasonicQueue */
osMessageQueueId_t xUltrasonicQueueHandle;
const osMessageQueueAttr_t xUltrasonicQueue_attributes = {
		.name = "xUltrasonicQueue"
};

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)
{
	bool isNotify = HCSR04_TIM_IC_CaptureCallback(htim); // 기존 코드 주석 처리 또는 삭제

	// 초음파 센서 타이머 캡처 인터럽트 발생 시 ultrasonicTask에 알림 전송
	BaseType_t xHigherPriorityTaskWoken = pdFALSE;
	if (ultrasonicTaskHandle != NULL && isNotify) {
		vTaskNotifyGiveFromISR(ultrasonicTaskHandle, &xHigherPriorityTaskWoken);
		portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
	}
}



/* USER CODE END FunctionPrototypes */

void LED_TASK_01(void *argument);
void UltrasonicTask(void *argument);
void MainMoveTask(void *argument);
void ControlTask(void *argument);

void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */

/**
 * @brief  FreeRTOS initialization
 * @param  None
 * @retval None
 */
void MX_FREERTOS_Init(void) {
	/* USER CODE BEGIN Init */

	uartRxQueue = xQueueCreate(32, sizeof(uint8_t)); // 32바이트 큐 생성

	/* USER CODE END Init */

	/* USER CODE BEGIN RTOS_MUTEX */
	/* add mutexes, ... */
	/* USER CODE END RTOS_MUTEX */

	/* USER CODE BEGIN RTOS_SEMAPHORES */
	/* add semaphores, ... */
	/* USER CODE END RTOS_SEMAPHORES */

	/* USER CODE BEGIN RTOS_TIMERS */
	/* start timers, add new ones, ... */
	/* USER CODE END RTOS_TIMERS */

	/* Create the queue(s) */
	/* creation of xUltrasonicQueue */
	xUltrasonicQueueHandle = osMessageQueueNew (10, sizeof(SensorData_t), &xUltrasonicQueue_attributes);

	/* USER CODE BEGIN RTOS_QUEUES */
	/* add queues, ... */
	/* USER CODE END RTOS_QUEUES */

	/* Create the thread(s) */
	/* creation of LED_TASK_1 */
	LED_TASK_1Handle = osThreadNew(LED_TASK_01, NULL, &LED_TASK_1_attributes);

	/* creation of ultrasonicTask */
	ultrasonicTaskHandle = osThreadNew(UltrasonicTask, NULL, &ultrasonicTask_attributes);

	/* creation of mainMoveTask */
	mainMoveTaskHandle = osThreadNew(MainMoveTask, NULL, &mainMoveTask_attributes);

	/* creation of controlTask */
	controlTaskHandle = osThreadNew(ControlTask, NULL, &controlTask_attributes);

	/* USER CODE BEGIN RTOS_THREADS */
	/* add threads, ... */
	/* USER CODE END RTOS_THREADS */

	/* USER CODE BEGIN RTOS_EVENTS */
	/* add events, ... */
	/* USER CODE END RTOS_EVENTS */

}

/* USER CODE BEGIN Header_LED_TASK_01 */
/**
 * @brief  Function implementing the LED_TASK_1 thread.
 * @param  argument: Not used
 * @retval None
 */
/* USER CODE END Header_LED_TASK_01 */
void LED_TASK_01(void *argument)
{
	/* USER CODE BEGIN LED_TASK_01 */
	/* Infinite loop */
	for(;;)
	{
		//    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
		//    osDelay(1000);
		//    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
		//    osDelay(1000);



		osDelay(1000);
	}
	/* USER CODE END LED_TASK_01 */
}

/* USER CODE BEGIN Header_UltrasonicTask */
/**
 * @brief Function implementing the ultrasonicTask thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_UltrasonicTask */
void UltrasonicTask(void *argument)
{
	/* USER CODE BEGIN UltrasonicTask */
	/* Infinite loop */
	for(;;)
	{
		// 초음파 트리거 신호 발생
		HCSR04_trgger_center();
		// 캡처 완료 알림 대기 (최대 100ms)
		ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));

		HCSR04_trgger_right();
		ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));

		HCSR04_trgger_left();
		ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(100));

		{// 여기서 3개 Data 일괄적으로 던짐....
			extern volatile uint8_t distance_Center;
			extern volatile uint8_t distance_Right;
			extern volatile uint8_t distance_Left;

			SensorData_t sensorData;
			sensorData.distance_Center = distance_Center;
			sensorData.distance_Right = distance_Right;
			sensorData.distance_Left = distance_Left;
			xQueueSend(xUltrasonicQueueHandle, &sensorData, portMAX_DELAY);
		}

		osDelay(10);

		//vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(50));
	}
	/* USER CODE END UltrasonicTask */
}

/* USER CODE BEGIN Header_MainMoveTask */
/**
 * @brief Function implementing the mainMoveTask thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_MainMoveTask */
void MainMoveTask(void *argument)
{
	/* USER CODE BEGIN MainMoveTask */
	uint8_t rxChar;

	/* Infinite loop */
	for(;;)
	{
		if (xQueueReceive(uartRxQueue, &rxChar, portMAX_DELAY) == pdPASS) {
			// rxChar에 수신된 문자 있음
			// 원하는 처리 수행
			MotorControl(rxChar);
		}

		osDelay(10);
	}
	/* USER CODE END MainMoveTask */
}


static ControlCommand_t DecideDirection(uint8_t dist_left, uint8_t dist_center, uint8_t dist_right) {
    ControlCommand_t cmd = {STEER_NONE, SPEED_NORMAL, BRAKE_NONE};

    if (dist_center < SAFE_DISTANCE) {
        // 전방 장애물: 정지 및 비상 브레이크
        cmd.speed = SPEED_STOP;
        cmd.brake = BRAKE_EMERGENCY;
    } else if (dist_left < SAFE_LEFT_DISTANCE && dist_right >= SAFE_RIGHT_DISTANCE) {
        // 좌측 장애물: 우회전
        cmd.steering = STEER_RIGHT;
        cmd.speed = SPEED_SLOW;
    } else if (dist_right < SAFE_RIGHT_DISTANCE && dist_left >= SAFE_LEFT_DISTANCE) {
        // 우측 장애물: 좌회전
        cmd.steering = STEER_LEFT;
        cmd.speed = SPEED_SLOW;
    } else if (dist_center < WARNING_DISTANCE) {
        // 전방 경고 거리 이내: 감속
        cmd.speed = SPEED_SLOW;
    } else {
        // 모든 방향 안전: 직진
        cmd.steering = STEER_NONE;
        cmd.speed = SPEED_NORMAL;
    }

    return cmd;
}


SensorData_t g_sensor_data;
ControlCommand_t g_control_cmd;


/* USER CODE BEGIN Header_ControlTask */
/**
 * @brief Function implementing the controlTask thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_ControlTask */
void ControlTask(void *argument)
{
	/* USER CODE BEGIN ControlTask */
	SensorData_t sensor_data;
	ControlCommand_t control_cmd;

	const uint8_t max_cnt = 6;
	SensorData_t save_sensor_data[max_cnt];
	uint8_t cur_cnt = 0;


	SensorData_t mdify_sensor_data;

	/* Infinite loop */
	for(;;)
	{
		// xUltrasonicQueueHandle에서 초음파 값 수신 (최대 10ms 대기)
		if (osMessageQueueGet(xUltrasonicQueueHandle, &sensor_data, NULL, 10) == osOK) {

			// debuging
			g_sensor_data = sensor_data;
			save_sensor_data[cur_cnt].distance_Center = sensor_data.distance_Center;
			save_sensor_data[cur_cnt].distance_Left = sensor_data.distance_Left;
			save_sensor_data[cur_cnt].distance_Right = sensor_data.distance_Right;
			cur_cnt++; // next

			const bool isMotorMove = (cur_cnt >= max_cnt)? true:false;
			if (cur_cnt >= max_cnt){
				cur_cnt = 0;
			}

			if (isMotorMove){
				// 각 센서 데이터를 개별적으로 정렬하여 중간값 추출
				uint8_t center_values[max_cnt];
				uint8_t left_values[max_cnt];
				uint8_t right_values[max_cnt];
				
				// 센서 데이터를 개별 배열로 복사
				for (uint8_t idx = 0; idx < max_cnt; idx++) {
					center_values[idx] = save_sensor_data[idx].distance_Center;
					left_values[idx] = save_sensor_data[idx].distance_Left;
					right_values[idx] = save_sensor_data[idx].distance_Right;
				}
				
				// 각 센서 데이터 배열을 버블 정렬
				for (uint8_t i = 0; i < max_cnt - 1; i++) {
					for (uint8_t j = 0; j < max_cnt - i - 1; j++) {
						// Center 값 정렬
						if (center_values[j] > center_values[j + 1]) {
							uint8_t temp = center_values[j];
							center_values[j] = center_values[j + 1];
							center_values[j + 1] = temp;
						}
						
						// Left 값 정렬
						if (left_values[j] > left_values[j + 1]) {
							uint8_t temp = left_values[j];
							left_values[j] = left_values[j + 1];
							left_values[j + 1] = temp;
						}
						
						// Right 값 정렬
						if (right_values[j] > right_values[j + 1]) {
							uint8_t temp = right_values[j];
							right_values[j] = right_values[j + 1];
							right_values[j + 1] = temp;
						}
					}
				}
				
				// 정렬된 값들의 중간값(median) 사용
				mdify_sensor_data.distance_Center = center_values[max_cnt / 2];
				mdify_sensor_data.distance_Left = left_values[max_cnt / 2];
				mdify_sensor_data.distance_Right = right_values[max_cnt / 2];
				
				// 정렬된 중간값으로 제어 명령 결정
				control_cmd = DecideDirection(mdify_sensor_data.distance_Left, 
											mdify_sensor_data.distance_Center, 
											mdify_sensor_data.distance_Right);
			}

			g_control_cmd = control_cmd;


#if 1
			if(!AutoSteeringControl(control_cmd.steering)){
				if (!AutoBrakeControl(control_cmd.brake)){

					if (control_cmd.speed == SPEED_SLOW){
						if (sensor_data.distance_Left > sensor_data.distance_Right){
							AutoSteeringControl(STEER_LEFT);
						}else{
							AutoSteeringControl(STEER_RIGHT);
						}
					}else{
						AutoSpeedControl(control_cmd.speed);
					}

				}else{
					AutoMoveSlowBack();
					// 브레이크 상태에서 재자리 회전 실행

//					if (sensor_data.distance_Left > sensor_data.distance_Right){
//						AutoLeftBackControl();
//					}else{
//						AutoRightBackControl();
//					}


				}
			}
#endif
		}

		osDelay(10);
	}
	/* USER CODE END ControlTask */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */

/* USER CODE END Application */

