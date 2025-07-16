#include "ap.h"

void apInit()
{
    // 초기화 루틴 - main.c에서 sei() 호출하므로 여기서는 제거
}

void apMain()
{

    stdout = &OUTPUT;
    
    UART_Init();   
    sei();

    while (1)
    {
        if(rxFlag == 1)
        {
            rxFlag = 0;             
            printf(rxBuff);
        }
    }        
}





// void apMain()
// {


// //    LCD_Init();

//     // LCD_GotoXY(0,0);
//     // LCD_WriteString((uint8_t *)"Hello LCD");

//     // LCD_GotoXY(1,0);
//     // LCD_WriteString((uint8_t *)"Hello AVR");

//     // while (1)
//     // {
//     //     /* code */
//     // }
    
//     // char buff[30];
//     // sprintf(buff, "Hello ATmega128A");
//     // LCD_WriteStringXY(0,0, buff);

//     // uint16_t count = 0;
//     // while (1)
//     // {
//     //     sprintf(buff, "Count : %d", count++);
//     //     LCD_WriteStringXY(1,2, buff);
//     //     _delay_ms(100);
//     // }
    
// }

// void apMain()
// {
//     LED_DDR = 0xff;

//     // 버튼 관련 변수 선언 (기능별 분류)
//     BUTTON btnOn;
//     BUTTON btnOff;
//     BUTTON btnToggle;

//     buttonInit(&btnOn, &BUTTON_DDR, &BUTTON_PIN, BUTTON_ON); // 변수주소, DDR주소, PIN주소, 0번핀
//     buttonInit(&btnOff, &BUTTON_DDR, &BUTTON_PIN, BUTTON_OFF);
//     buttonInit(&btnToggle, &BUTTON_DDR, &BUTTON_PIN, BUTTON_TOGGLE);

//     while (1)
//     {
//         if (buttonGetState(&btnOn) == RELEASED)
//         {
//             LED_PORT = 0xff;
//         }

//         if (buttonGetState(&btnOff) == RELEASED)
//         {
//             LED_PORT = 0x00;
//         }

//         if (buttonGetState(&btnToggle) == RELEASED)
//         {
//             LED_PORT ^= 0xff;
//         }
//     }
// }

// #if 0
// ISR(INT4_vect){
//     //PORTD = 0xFF;
//     ledOnAll();
// }

// ISR(INT5_vect){
//     PORTD = 0x00;
// }

// void apMain()
// {
//     //DDRD = 0xFF; // D port 출력
//     ledInitAll();

//     // 레지스터 세팅 방법......
//     sei(); //전역 인터럽트 인에비블

//     //EICRB = 0x0E; //INT4 항강 INT5 상승에지
//     //EIMSK = 0x30; //INT0, INT1 Interrupt Enable
//     EICRB |= (1<<ISC51) | (1<<ISC50) | (1<<ISC41);
//     EIMSK |= (1<<INT4)  | (1<<INT5);

//     while(1)
//     {
//         // main ....
//     }
// }
// #endif

// #if 0
// void apMain()
// {
//     //DDRB = 0xff; // PORTB를 출력으로 설정

//     // 16MHz / (64 * (1 + 249)) = 1000Hz, 
    


//     // 250Hz = 16MHz / (2 * N * (1 + X))
//     // 여기서 N = [1, 8, 32, 64, 256, 1024]




//     DDRB = 0xff; // 

//     // TCCR0 = 0x1C; // 레지스터 세팅 분주비 64
//     TCCR0 = 0x1D;    // 분주비 128 


//     //OCR0 = 128;
 
//     OCR0 = 255;


//     while (1)
//     {
//         while ((TIFR & 0x02) == 0)
//         {
            
//         }

//         TIFR = 0x02;
        
//         //OCR0 = 128;
//         OCR0 = 255;

//         /* code */
//     }
        
// }
// #endif

// #if 0
// void apMain()
// {
//     DDRD = 0xFF;
//     PORTD = 0;

//     TCCR0 |= (1<<CS02) | (1<<CS00);
//     //0b0111

//     TCNT0 = 131;

//     while (1)
//     {
//         while ((TIFR & 0x01) == 0)
//         {        
//         }

//         PORTD = ~PORTD;
//         TIFR = 0x01;
//         TCNT0 = 131;
//     }

// }
// #endif

// #if 0
// void apMain()
// {
//     //DDRB = 0xff;
//     DDRB |= (1<<PB4);

//     //TCCR0 |= (1<<WGM00) | (1<<COM00) | (1<<WGM01) |(1<<CS02);
//     TCCR0 = 0x6C;

//     OCR0 = 255;

//     while (1)
//     {
//         for (uint8_t i=0 ; i<255 ; i++){
//             OCR0 = i;
//             _delay_ms(10);
//         }

//     }
    
// }
// #endif

// #if 0
// void apMain()
// {
//     DDRB |= (1<<PB5);


//     TCCR1A |= (1<<COM1A1) | (1<<WGM11);
//     TCCR1B |= (1<<WGM13) | (1<<WGM12) | (1<<CS11) | (1<<CS10);

//     ICR1 = 4999;  //TOP 

//     while (1)
//     {

//         OCR1A = 250;  // -90 drgree

//         _delay_ms(1000);

//         OCR1A = 500; // 

//         _delay_ms(1000);

//     }
    
// }
// #endif

#if 0
// 버튼 핀 정의
#define BUTTON_PIN_STOP 0    // 팬 정지 버튼 핀 번호
#define BUTTON_PIN_SLOW 1    // 팬 저속 버튼 핀 번호
#define BUTTON_PIN_FAST 2    // 팬 고속 버튼 핀 번호
#define BUTTON_PIN_SERVON 3  // 서보모터 켜기 버튼 핀 번호
#define BUTTON_PIN_SERVOFF 4 // 서보모터 끄기 버튼 핀 번호

void apMain()
{
    // 버튼 객체 선언
    BUTTON btnFanStop;       // 팬 정지 버튼
    BUTTON btnFanSlow;       // 팬 저속 버튼
    BUTTON btnFanFast;       // 팬 고속 버튼
    BUTTON btnServOn;        // 서보모터 켜기 버튼
    BUTTON btnServOff;       // 서보모터 끄기 버튼

    // FND 표시를 위한 세그먼트 패턴 배열(0~9 숫자)
    uint8_t fndNumber[] = {
        0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x27, 0x7F, 0x67};

    // 버튼 초기화
    buttonInit(&btnFanStop, &BUTTON_DDR, &BUTTON_PIN, BUTTON_PIN_STOP);  // 팬 정지 버튼 초기화
    buttonInit(&btnFanSlow, &BUTTON_DDR, &BUTTON_PIN, BUTTON_PIN_SLOW);  // 팬 저속 버튼 초기화
    buttonInit(&btnFanFast, &BUTTON_DDR, &BUTTON_PIN, BUTTON_PIN_FAST);  // 팬 고속 버튼 초기화
    buttonInit(&btnServOn, &BUTTON_DDR, &BUTTON_PIN, BUTTON_PIN_SERVON); // 서보모터 켜기 버튼 초기화
    buttonInit(&btnServOff, &BUTTON_DDR, &BUTTON_PIN, BUTTON_PIN_SERVOFF); // 서보모터 끄기 버튼 초기화

    // 포트 설정
    DDRD = 0xFF;  // D 포트 전체를 출력으로 설정 (LED 표시용)
    DDRA = 0xFF;  // A 포트 전체를 출력으로 설정 (FND 표시용)

    // 팬 모터 PWM 설정
    DDRB |= (1 << PB4);  // PB4 핀을 출력으로 설정 (팬 PWM 출력)
    // TCCR0 |= (1 << WGM00) | (1 << COM01) | (1 << WGM01) | (1 << CS02);
    TCCR0 = 0x6C;  // 타이머0 설정 - 고속 PWM 모드, 비반전 출력, 256 분주

    // 서보모터 설정
    DDRB |= (1 << PB5);  // PB5 핀을 출력으로 설정 (서보모터 PWM 출력)

    // 16비트 타이머1 설정 - 서보모터 구동용 PWM (50Hz)
    TCCR1A |= (1 << COM1A1) | (1 << WGM11);  // 비반전 출력, 고속 PWM 모드
    TCCR1B |= (1 << WGM13) | (1 << WGM12) | (1 << CS11) | (1 << CS10);  // 고속 PWM 모드, 64분주

    ICR1 = 4999;  // TOP 값 설정 (PWM 주기 결정) - 50Hz 주파수 생성

    // 서보모터 제어 변수 초기화
    uint8_t sevo_state = 0;  // 서보모터 동작 상태 (0: 정지, 1: 동작)
    int sevo_count = OCR1A;      // 서보모터 위치 카운터

    while (1)
    {
        // 서보모터 동작 상태일 때 위치 제어
        if (sevo_state == 1)
        {
            if (sevo_count == 500)  // 최대 위치에 도달하면 카운터 초기화
            {
                sevo_count = 0;
            }
            OCR1A = sevo_count;  // 서보모터 위치 설정
            sevo_count++;        // 위치 카운터 증가 (회전)
            _delay_ms(8);        // 서보모터 이동 대기 시간
        }

        // 팬 정지 버튼 처리
        if (buttonGetState(&btnFanStop) == ACT_PUSH)
        {
            PORTD = 0b00000000;  // LED 모두 끄기
            _delay_ms(50);       // 디바운싱 딜레이

            PORTA = fndNumber[0];  // FND에 0 표시
            _delay_ms(50);         // 디바운싱 딜레이

            OCR1A = 0;  // 서보모터 정지
            OCR0 = 0;   // 팬 정지
            _delay_ms(30);  // 안정화 딜레이
        }

        // 팬 저속 버튼 처리
        if (buttonGetState(&btnFanSlow) == ACT_PUSH)
        {
            OCR0 = 128;         // 팬 속도 중간값 설정
            _delay_ms(50);      // 디바운싱 딜레이
            PORTD = 0b11000000; // LED 표시 패턴
            _delay_ms(50);      // 디바운싱 딜레이
            PORTA = fndNumber[2]; // FND에 2 표시
            _delay_ms(50);      // 디바운싱 딜레이
        }

        // 팬 고속 버튼 처리
        if (buttonGetState(&btnFanFast) == ACT_PUSH)
        {
            PORTD = 0b11100000;  // LED 표시 패턴
            _delay_ms(50);       // 디바운싱 딜레이
            PORTA = fndNumber[3]; // FND에 3 표시
            _delay_ms(50);       // 디바운싱 딜레이
            OCR0 = 200;          // 팬 고속 설정
            _delay_ms(50);       // 디바운싱 딜레이
        }

        // 서보모터 켜기 버튼 처리
        if (buttonGetState(&btnServOn) == ACT_PUSH)
        {
            PORTD = 0b11110000;  // LED 표시 패턴
            _delay_ms(50);       // 디바운싱 딜레이
            PORTA = fndNumber[4]; // FND에 4 표시
            _delay_ms(50);       // 디바운싱 딜레이

            sevo_state = 1;      // 서보모터 동작 상태 활성화
        }

        // 서보모터 끄기 버튼 처리
        if (buttonGetState(&btnServOff) == ACT_PUSH)
        {
            PORTD = 0b11111000;  // LED 표시 패턴
            _delay_ms(50);       // 디바운싱 딜레이
            PORTA = fndNumber[5]; // FND에 5 표시
            _delay_ms(50);       // 디바운싱 딜레이

            sevo_state = 0;      // 서보모터 동작 상태 비활성화

            OCR1A = 0;           // 서보모터 정지
            _delay_ms(10);       // 안정화 딜레이
        }
    }
}

#endif

