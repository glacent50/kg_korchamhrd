/*
 * dhc11.h
 *
 *  Created on: Jul 1, 2025
 *      Author: user22
 */

#ifndef INC_DHC11_H_
#define INC_DHC11_H_

//#include "main.h"
#include "stm32f4xx.h"
#include "stdint.h"
#include "stdio.h"
#include "stdbool.h"
#include "delay_us.h"


enum
{
  INPUT,
  OUTPUT
};

typedef struct
{
  GPIO_TypeDef *port;
  uint16_t pin;
  uint8_t temperature;
  uint8_t humidity;
} DHT11;


void dht11Init(DHT11 *dht, GPIO_TypeDef *port, uint16_t pin);

void dht11GpioMode(DHT11 *dht, uint8_t mode);

bool dht11Read(DHT11 *dht);





#endif /* INC_DHC11_H_ */
