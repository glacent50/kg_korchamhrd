#include <stdint.h>


#define RCC_CR_HSEON    (1<<16)   //HSE 오실레이터  ON 비트
#define RCC_CR_HSERDY   (1<<17)   //HSE Ready 플래그
#define RCC_CR_PLLON    (1<<24)   //PLL 오실레이터 ON 비트
#define RCC_CR_PLLRDY   (1<<25)   //PLL Ready 플래그

#define RCC_PLLCFGR_PLLM_Pos    0   // PLLM 위치
#define RCC_PLLCFGR_PLLN_Pos    6   // PLLN 위치
#define RCC_PLLCFGR_PLLP_Pos    16  // PLLP 위치
#define RCC_PLLCFGR_PLLSRC_Pos  22  // PLLSRC 위치

#define FLASH_ACR_LATENCY_Pos   0
#define FLASH_ACR_LATENCY_3WS   (3<<FLASH_ACR_LATENCY_Pos)  //3 wait state

#define RCC_CFGR_SW_Pos     0   // 시스템 클럭 소스 선택 스위치
#define RCC_CFGR_SW_PLL     (2<<RCC_CFGR_SW_Pos)  // PLL 선택
#define RCC_CFGR_HPRE_Pos   4   // AHB 프리스케일러
#define RCC_CFGR_PPRE1_Pos  10  // APB1 프리스케일러
#define RCC_CFGR_PPRE2_Pos  13  // APB2 프리스케일러

#define RCC_AHB1ENR_GPIOAEN (1<<0)      // GPIOA 클럭 활성화 비트


#define GPIOA_MODER_MODER5  (1<<(5*2))  // GPIOA 출력모드로 설정
#define GPIOA_ODR_ODR5      (1<<5)      // PA5출력 데이터 세트

#define RCC_BASE    0x40023800  // RCC 의 기본주소
#define FLASH_BASE  0x40023C00  // FLASH 기본주소
#define GPIOA_BASE  0x40020000  // GPIOA 의 기본주소

#define RCC_CR        (*(volatile uint32_t *)(RCC_BASE + 0x00))
#define RCC_PLLCFGR   (*(volatile uint32_t *)(RCC_BASE + 0x04))
#define RCC_CFGR      (*(volatile uint32_t *)(RCC_BASE + 0x08))
#define FLASH_ACR     (*(volatile uint32_t *)(FLASH_BASE + 0x00))
#define GPIOA_MODER   (*(volatile uint32_t *)(GPIOA_BASE + 0x00))
#define GPIOA_ODR     (*(volatile uint32_t *)(GPIOA_BASE + 0x14))

#define RCC_AHB1ENR   (*(volatile uint32_t *)(RCC_BASE + 0x30))


void Systemclock_Config(void)
{
  // HSE 클럭 활성화
  RCC_CR |= RCC_CR_HSEON;           // HSE ON
  while(!(RCC_CR & RCC_CR_HSERDY)); // HSE 안정화 대기

  // PLL 설정
  RCC_PLLCFGR = (4 << RCC_PLLCFGR_PLLM_Pos) |   // PLLM = 4
                (200 << RCC_PLLCFGR_PLLN_Pos)|  // PLLN = 200
                (0x1 << RCC_PLLCFGR_PLLP_Pos)|  // PLLP = 4
                (1 << RCC_PLLCFGR_PLLSRC_Pos);  // PLL 소스 = HSE

  // PLL 활성화
  RCC_CR |= RCC_CR_PLLON;           // PLL ON
  while(!(RCC_CR & RCC_CR_PLLRDY)); // PLL Ready 대기

  // AHB, APB1, APB2 분주 설정
  RCC_CFGR |= (0 << RCC_CFGR_HPRE_Pos);   // AHB Prescaler = 1 (SYSCLK 그대로 적용)
  RCC_CFGR |= (5 << RCC_CFGR_PPRE1_Pos);  // APB1 Prescaler = 4
  RCC_CFGR |= (4 << RCC_CFGR_PPRE2_Pos);  // APB2 Prescaler = 2

  // 플래시 메모리 설정
  FLASH_ACR |= FLASH_ACR_LATENCY_3WS;

  // 시스템 클럭소스로 PLL 선택
  RCC_CFGR |= RCC_CFGR_SW_PLL;
  while((RCC_CFGR & RCC_CFGR_SW_PLL) != RCC_CFGR_SW_PLL);
}


int main()
{
  Systemclock_Config();

  // 테스트용 GPIO 설정
  RCC_AHB1ENR |= RCC_AHB1ENR_GPIOAEN; //GPIOA 클럭 활성화
  GPIOA_MODER |= GPIOA_MODER_MODER5;  // PA5를 출력 모드로 설정

  while(1)
  {
    GPIOA_ODR ^= GPIOA_ODR_ODR5;
    for(volatile int i = 0; i < 10000000; i++);
  }
}
