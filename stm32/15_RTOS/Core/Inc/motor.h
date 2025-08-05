/*
 * motor.h
 *
 *  Created on: Jul 8, 2025
 *      Author: user22
 */

#ifndef INC_MOTOR_H_
#define INC_MOTOR_H_


#include "main.h"
#include "stdbool.h"

void MotorControl(const uint8_t rxChar);


bool AutoSpeedControl(const uint8_t speed);
bool AutoSteeringControl(const uint8_t steering);
bool AutoBrakeControl(const uint8_t brake);

void AutoLeftBackControl();
void AutoRightBackControl();

bool AutoMoveSlowBack();

#endif /* INC_MOTOR_H_ */
