
#ifndef INC_DELAY_US_H_
#define INC_DELAY_US_H_

#include "main.h"
#include "tim.h"


extern volatile uint8_t delay_done;


void delay_us(uint16_t us);


// Non-Blocking 방식
void delay_us_non_blocking(uint16_t us);
uint8_t is_delay_done(void);




#endif /* INC_DELAY_US_H_ */
