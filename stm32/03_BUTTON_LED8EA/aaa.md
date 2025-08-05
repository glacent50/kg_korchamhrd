# STM32 버튼 LED 제어 프로그램 분석

## 흐름도 (Flowchart)

```mermaid
flowchart TD
    A[시작] --> B[시스템 초기화\nHAL_Init]
    B --> D[GPIO 초기화\nMX_GPIO_Init]
    D --> E[USART2 초기화\nMX_USART2_UART_Init]
    E --> F{무한 루프}
    F --> G{버튼 PC8 눌림?}
    G -->|Yes| H[LED 8개 켜기\nledOn]
    G -->|No| I{버튼 PC6 눌림?}
    I -->|Yes| J[LED 8개 끄기\nledOff]
    I -->|No| K{버튼 PC5 눌림?}
    K -->|Yes| L[LED 꽃모양 패턴\nledFlower]
    K -->|No| F
    H --> F
    J --> F
    L --> F
```

## 시퀀스 다이어그램 (Sequence Diagram)

```mermaid
sequenceDiagram
    participant Main
    participant HAL
    participant GPIO
    participant LED
    
    Main->>HAL: HAL_Init()
    Main->>GPIO: MX_GPIO_Init()
    Main->>HAL: MX_USART2_UART_Init()
    
    loop Infinite Loop
        Main->>GPIO: HAL_GPIO_ReadPin(PC8)
        alt Button PC8 Pressed
            Main->>LED: ledOn(8)
        else Button PC6 Pressed
            Main->>GPIO: HAL_GPIO_ReadPin(PC6)
            Main->>LED: ledOff(8)
        else Button PC5 Pressed
            Main->>GPIO: HAL_GPIO_ReadPin(PC5)
            Main->>LED: ledFlower(8)
        end
    end
```

## 주요 기능 설명

1. **초기화 과정**
   - HAL 라이브러리 초기화
   - 시스템 클럭 설정
   - GPIO 핀 초기화
   - USART2 통신 초기화

2. **버튼 제어 기능**
   - PC8 버튼: LED 8개 모두 켜기
   - PC6 버튼: LED 8개 모두 끄기
   - PC5 버튼: LED 꽃모양 패턴 표시

3. **LED 제어 함수**
   - ledOn(): LED 켜기
   - ledOff(): LED 끄기
   - ledFlower(): 꽃모양 패턴 표시