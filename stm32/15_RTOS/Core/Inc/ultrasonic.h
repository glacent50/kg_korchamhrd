/*
 * ultrasonic.h
 *
 *  Created on: Jul 8, 2025
 *      Author: user22
 */

#ifndef INC_ULTRASONIC_H_
#define INC_ULTRASONIC_H_

#include "main.h"
#include "stdbool.h"

#define SAFE_DISTANCE      20   // cm, 안전 거리

#define WARNING_DISTANCE   40   // cm, 경고 거리

#define SAFE_LEFT_DISTANCE      30   // cm, 안전 거리
#define SAFE_RIGHT_DISTANCE     30


// 제어 명령 상수
#define STEER_NONE     0
#define STEER_LEFT     1
#define STEER_RIGHT    2

#define SPEED_STOP     0
#define SPEED_SLOW     1
#define SPEED_NORMAL   2

#define BRAKE_NONE     0
#define BRAKE_EMERGENCY 1


// 센서 데이터 구조체
typedef struct {
    uint8_t distance_Center;
    uint8_t distance_Right;
    uint8_t distance_Left;
} SensorData_t;

// 제어 명령 구조체
typedef struct {
    uint8_t steering;
    uint8_t speed;
    uint8_t brake;
} ControlCommand_t;


void HCSR04_trgger_center(void);
void HCSR04_trgger_right(void);
void HCSR04_trgger_left(void);

bool HCSR04_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim);

#endif /* INC_ULTRASONIC_H_ */
