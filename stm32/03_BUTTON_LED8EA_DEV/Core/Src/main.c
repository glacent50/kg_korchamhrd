/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
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
#include "main.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

#include "led.h"
#include "button.h"

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

// 버튼 상태 추적을 위한 정의
#define BUTTON_COUNT           3     // 사용 버튼 수
#define DEBOUNCE_DELAY_MS      50    // 디바운싱 시간 (ms)
#define LONG_PRESS_DELAY_MS    1000  // 길게 누름 인식 시간 (1초)
#define REPEAT_INTERVAL_MS     200   // 길게 누를 때 반복 간격 (200ms)

// 버튼 이벤트 타입
typedef enum {
  BUTTON_NONE = 0,    // 이벤트 없음
  BUTTON_PRESSED,     // 버튼 눌림 상태
  BUTTON_RELEASED,    // 버튼 뗌 상태
  BUTTON_LONG_PRESS,  // 버튼 길게 누름 상태
  BUTTON_REPEAT       // 길게 누를 때 반복 이벤트
} ButtonEvent_t;

// 버튼 상태 구조체
typedef struct {
  uint8_t currentState;          // 현재 상태 (0: 안눌림, 1: 눌림)
  uint8_t lastState;             // 이전 상태
  uint32_t lastChangeTime;       // 마지막 상태 변화 시간
  uint32_t lastRepeatTime;       // 마지막 반복 이벤트 시간
  ButtonEvent_t event;           // 현재 이벤트
  uint8_t longPressDetected;     // 길게 누름 감지 플래그
} ButtonState_t;

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

volatile uint8_t rxData; // UART 수신 버퍼로 사용 (ISR에 의해 변경됨)
volatile uint8_t rxAFlag = 0; // 'a' 명령어 처리를 위한 플래그
volatile uint8_t rxBFlag = 0; // 'b' 명령어 처리를 위한 플래그
volatile uint8_t rxCFlag = 0; // 기존 플래그, volatile로 변경

// 버튼 상태 배열
ButtonState_t buttonStates[BUTTON_COUNT] = {0};

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

//void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
//{
//  if (huart->Instance == USART2)
//  {
//    // 현재 수신된 문자는 rxData에 저장되어 있습니다.
//    // 다음 문자 수신을 위해 UART 수신 인터럽트를 다시 활성화합니다.
//    // 가능한 한 빨리 인터럽트를 재활성화하는 것이 좋습니다.
//    HAL_UART_Receive_IT(&huart2, (uint8_t*)&rxData, 1); // 다음 문자를 저장할 버퍼로 volatile rxData 사용
//
//    // 방금 수신된 문자 처리
//    if (rxData == 'a'){
//      uint8_t _text[] = "LED ON\n";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//      rxAFlag = 1; // 'a' 플래그 설정
//    }
//    else if (rxData == 'b'){
//      uint8_t _text[] = "LED OFF\nd";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//      rxBFlag = 1; // 'b' 플래그 설정
//    }
//    else if (rxData == 'c'){
//      uint8_t _text[] = "LED LEFT SHIFT\n";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//      rxCFlag = 1; // 'c' 플래그 설정
//    }
//  }
//}

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/**
 * @brief 버튼 상태를 업데이트하고 이벤트를 반환
 * @param btnIndex 버튼 인덱스 (0-2)
 * @return 버튼 이벤트
 */
ButtonEvent_t updateButtonState(uint8_t btnIndex)
{
  if (btnIndex >= BUTTON_COUNT) return BUTTON_NONE;
  
  uint8_t currentRead = buttonGetPressed(btnIndex);
  ButtonState_t *btn = &buttonStates[btnIndex];
  
  // 현재 시간 읽기
  uint32_t currentTime = HAL_GetTick();
  
  // 디바운싱 - 마지막 변경 후 일정 시간이 지나야 상태 변경 허용
  if (currentTime - btn->lastChangeTime < DEBOUNCE_DELAY_MS) {
    return btn->event;
  }
  
  // 상태 변화 감지
  if (currentRead != btn->lastState) {
    btn->lastState = currentRead;
    btn->lastChangeTime = currentTime;
    
    if (currentRead) {
      // 상승 엣지(Rising edge): 버튼 눌림
      btn->event = BUTTON_PRESSED;
      btn->longPressDetected = 0; // 길게 누름 상태 초기화
      return BUTTON_PRESSED;
    } else {
      // 하강 엣지(Falling edge): 버튼 뗌
      btn->event = BUTTON_RELEASED;
      btn->longPressDetected = 0; // 길게 누름 상태 초기화
      return BUTTON_RELEASED;
    }
  }
  
  // 버튼이 계속 눌려있는 상태
  if (currentRead) {
    // 길게 누름 감지 (처음 한 번만)
    if (!btn->longPressDetected && 
        (currentTime - btn->lastChangeTime >= LONG_PRESS_DELAY_MS)) {
      btn->longPressDetected = 1;
      btn->lastRepeatTime = currentTime;
      btn->event = BUTTON_LONG_PRESS;
      return BUTTON_LONG_PRESS;
    }
    
    // 길게 누른 후 반복 이벤트 생성
    if (btn->longPressDetected && 
        (currentTime - btn->lastRepeatTime >= REPEAT_INTERVAL_MS)) {
      btn->lastRepeatTime = currentTime;
      btn->event = BUTTON_REPEAT;
      return BUTTON_REPEAT;
    }
    
    return btn->event;
  }
  
  // 상태 변화가 없고 버튼이 눌려있지 않으면 이벤트 없음
  btn->event = BUTTON_NONE;
  return BUTTON_NONE;
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  HAL_UART_Receive_IT(&huart2, (uint8_t*)&rxData, 1);

  // 버튼 상태 배열 추가
  ButtonState_t buttonStates[BUTTON_COUNT] = {0};

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
  // 버튼 0 (LED ON) 처리
  switch (updateButtonState(0)) {
    case BUTTON_PRESSED:
      ledOn(8);
      {
        uint8_t _text[] = "LED ON\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
      }
      break;
      
    case BUTTON_LONG_PRESS:
      {
        uint8_t _text[] = "Button 0 LONG PRESS - All LEDs Blink\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
        // 예: 모든 LED 깜빡이기 시작
        ledBlink(8);
      }
      break;
      
    case BUTTON_RELEASED:
      // 필요시 버튼 뗄 때 동작 구현
      break;
      
    case BUTTON_REPEAT:
      // 길게 누를 때 반복 동작 (예: LED 밝기 증가 등)
      break;
      
    default:
      break;
  }

  // 버튼 1 (LED OFF) 처리
  switch (updateButtonState(1)) {
    case BUTTON_PRESSED:
      ledOff(8);
      {
        uint8_t _text[] = "LED OFF\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
      }
      break;
      
    case BUTTON_LONG_PRESS:
      {
        uint8_t _text[] = "Button 1 LONG PRESS - Right Shift Pattern\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
        // 예: LED 오른쪽 시프트 패턴
        // ledRightShift(8); // 함수가 구현되어 있다면
      }
      break;
      
    default:
      break;
  }

  // 버튼 2 (LED FLOWER PATTERN) 처리
  switch (updateButtonState(2)) {
    case BUTTON_PRESSED:
      ledFlower(8);
      {
        uint8_t _text[] = "LED FLOWER PATTERN\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
      }
      break;
      
    case BUTTON_LONG_PRESS:
      {
        uint8_t _text[] = "Button 2 LONG PRESS - Special Pattern\n";
        HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
        // 예: 특별한 LED 패턴
        ledLeftShift(8);
      }
      break;
      
    case BUTTON_REPEAT:
      // 반복 누르면 패턴 속도 증가와 같은 기능 구현 가능
      break;
      
    default:
      break;
  }

//    if(buttonGetPressed(0))
//    {
//      ledOn(8);
//      uint8_t _text[] = "LED ON\n";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//    }
//
//    if(buttonGetPressed(1))
//    {
//      uint8_t _text[] = "LED OFF\n";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//      ledOff(8);
//    }
//
//    if(buttonGetPressed(2))
//    {
//      uint8_t _text[] = "LED FLOWER PATTERN\n";
//      HAL_UART_Transmit(&huart2, _text, sizeof(_text), 100);
//      ledFlower(8);
//    }

//    if (rxAFlag == 1){
//      ledOn(8);
//      rxAFlag = 0; // 플래그 클리어
//    }
//    else if (rxBFlag == 1){
//      ledOff(8);
//      rxBFlag = 0; // 플래그 클리어
//    }
//    else if (rxCFlag == 1){
//      ledLeftShift(8);
//      rxCFlag = 0; // 플래그 클리어
//    }

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 4;
  RCC_OscInitStruct.PLL.PLLN = 100;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_3) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
