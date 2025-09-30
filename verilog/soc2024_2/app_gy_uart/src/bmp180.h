#ifndef __BMP180_H
#define __BMP180_H

#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"

// BMP180 츨력 결과 값
typedef struct {
    int32_t temperature;
    int32_t temperatureMod;
    int32_t pressure;
    int32_t pressureMod;
    int32_t altitude;
} BMP180_ResultData;

// 함수 프로토타입
int bmp180_init(void);
int bmp180_GetResultData(BMP180_ResultData *resultData);

#endif