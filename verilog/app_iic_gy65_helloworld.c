/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiic.h"


// I2C 설정
#define IIC_ADDR    XPAR_XIIC_0_BASEADDR
XIic iic_instance;


// BMP180 I2C 주소 및 레지스터 정의
#define BMP180_I2C_ADDR         0x77
#define BMP180_REG_CONTROL      0xF4
#define BMP180_REG_RESULT       0xF6
#define BMP180_REG_CAL_AC1      0xAA

// 측정 명령
#define BMP180_CMD_TEMPERATURE  0x2E
#define BMP180_CMD_PRESSURE_0   0x34  // OSS = 0
#define BMP180_CMD_PRESSURE_1   0x74  // OSS = 1
#define BMP180_CMD_PRESSURE_2   0xB4  // OSS = 2
#define BMP180_CMD_PRESSURE_3   0xF4  // OSS = 3


// BMP180 캘리브레이션 데이터 구조체
typedef struct {
    short AC1, AC2, AC3;
    unsigned short AC4, AC5, AC6;
    short B1, B2;
    short MB, MC, MD;
} BMP180_CalData;

BMP180_CalData cal_data;
int oss = 0;  // Oversampling setting (0-3)

// 함수 프로토타입
int bmp180_init(void);
int bmp180_read_calibration(void);
int bmp180_read_raw_temperature(void);
long bmp180_read_raw_pressure(void);

void delay_ms(int ms);

// I2C 읽기 함수
int i2c_read_bytes(u8 device_addr, u8 reg_addr, u8 *data, int count) {
    u8 write_data = reg_addr;
    unsigned bytes_sent, bytes_received;
    
    // 레지스터 주소 전송
    bytes_sent = XIic_Send(iic_instance.BaseAddress, device_addr, 
                          &write_data, 1, XIIC_REPEATED_START);
    if (bytes_sent != 1) {
        return -1;
    }
    
    // 데이터 수신
    bytes_received = XIic_Recv(iic_instance.BaseAddress, device_addr, 
                              data, count, XIIC_STOP);
    if (bytes_received != count) {
        return -1;
    }
    
    return 0;
}

// I2C 쓰기 함수
int i2c_write_byte(u8 device_addr, u8 reg_addr, u8 data) {
    u8 write_data[2] = {reg_addr, data};
    unsigned bytes_sent;
    
    bytes_sent = XIic_Send(iic_instance.BaseAddress, device_addr, 
                          write_data, 2, XIIC_STOP);
    if (bytes_sent != 2) {
        return -1;
    }
    
    return 0;
}

// BMP180 초기화
int bmp180_init(void) {
    xil_printf("BMP180 initializing...\r\n");
    
    // I2C 초기화
    if (XIic_Initialize(&iic_instance, IIC_ADDR) != XST_SUCCESS) {
        xil_printf("I2C initialization failed!\r\n");
        return -1;
    }
    
    // 캘리브레이션 데이터 읽기
    if (bmp180_read_calibration() != 0) {
        xil_printf("Failed to read calibration data!\r\n");
        return -1;
    }
    
    xil_printf("BMP180 initialized successfully!\r\n");
    return 0;
}

// 캘리브레이션 데이터 읽기
int bmp180_read_calibration(void) {
    u8 cal_bytes[22];
    
    if (i2c_read_bytes(BMP180_I2C_ADDR, BMP180_REG_CAL_AC1, cal_bytes, 22) != 0) {
        return -1;
    }
    
    // 캘리브레이션 데이터 파싱 (빅엔디안)
    cal_data.AC1 = (cal_bytes[0] << 8) | cal_bytes[1];
    cal_data.AC2 = (cal_bytes[2] << 8) | cal_bytes[3];
    cal_data.AC3 = (cal_bytes[4] << 8) | cal_bytes[5];
    cal_data.AC4 = (cal_bytes[6] << 8) | cal_bytes[7];
    cal_data.AC5 = (cal_bytes[8] << 8) | cal_bytes[9];
    cal_data.AC6 = (cal_bytes[10] << 8) | cal_bytes[11];
    cal_data.B1  = (cal_bytes[12] << 8) | cal_bytes[13];
    cal_data.B2  = (cal_bytes[14] << 8) | cal_bytes[15];
    cal_data.MB  = (cal_bytes[16] << 8) | cal_bytes[17];
    cal_data.MC  = (cal_bytes[18] << 8) | cal_bytes[19];
    cal_data.MD  = (cal_bytes[20] << 8) | cal_bytes[21];
    
    xil_printf("Calibration data loaded:\r\n");
    xil_printf("AC1=%d, AC2=%d, AC3=%d\r\n", cal_data.AC1, cal_data.AC2, cal_data.AC3);
    xil_printf("AC4=%u, AC5=%u, AC6=%u\r\n", cal_data.AC4, cal_data.AC5, cal_data.AC6);
    
    return 0;
}

// 원시 온도 데이터 읽기
int bmp180_read_raw_temperature(void) {
    u8 data[2];
    
    // 온도 측정 시작
    if (i2c_write_byte(BMP180_I2C_ADDR, BMP180_REG_CONTROL, BMP180_CMD_TEMPERATURE) != 0) {
        return -1;
    }
    
    // 측정 완료 대기 (4.5ms)
    usleep(5000);
    
    // 결과 읽기
    if (i2c_read_bytes(BMP180_I2C_ADDR, BMP180_REG_RESULT, data, 2) != 0) {
        return -1;
    }
    
    return (data[0] << 8) | data[1];
}

// 원시 압력 데이터 읽기
long bmp180_read_raw_pressure(void) {
    u8 data[3];
    u8 pressure_cmd = BMP180_CMD_PRESSURE_0 + (oss << 6);
    
    // 압력 측정 시작
    if (i2c_write_byte(BMP180_I2C_ADDR, BMP180_REG_CONTROL, pressure_cmd) != 0) {
        return -1;
    }
    
    // 측정 완료 대기 (OSS에 따라 다름)
    int delay_time = 5000 + (3 << oss) * 1000;  // 5ms + (3*2^oss)ms
    usleep(delay_time);
    
    // 결과 읽기 (3바이트)
    if (i2c_read_bytes(BMP180_I2C_ADDR, BMP180_REG_RESULT, data, 3) != 0) {
        return -1;
    }
    
    long pressure = ((data[0] << 16) | (data[1] << 8) | data[2]) >> (8 - oss);
    return pressure;
}


// 기압고도 공식: h = 44330 * (1 - (P/P0)^(1/5.255))
// float altitude = 44330.0f * (1.0f - powf(pressure / 1013.25f, 1.0f / 5.255f));
// 101325,  // 해수면 (0m)
// 100129,  // 약 100m
// 98961,   // 약 200m
// 89876,   // 약 1000m

// 기준 기압 hPa 단위
#define P0 1013

// 압력 범위 (0~1000 m 범위만)
#define P_MIN 900
#define P_MAX 1013

// 테이블 크기
#define TABLE_SIZE (P_MAX - P_MIN + 1)

static const uint16_t altitude_table[] = {
        2,    10,    19,    27,    35,    44,    52,    61,    69,    77, 
       86,    94,   102,   111,   119,   128,   136,   145,   153,   162, 
      170,   178,   187,   195,   204,   212,   221,   229,   238,   246, 
      255,   263,   272,   281,   289,   298,   306,   315,   323,   332, 
      341,   349,   358,   366,   375,   384,   392,   401,   410,   418, 
      427,   436,   444,   453,   462,   470,   479,   488,   497,   505, 
      514,   523,   532,   540,   549,   558,   567,   576,   584,   593, 
      602,   611,   620,   629,   637,   646,   655,   664,   673,   682, 
      691,   700,   708,   717,   726,   735,   744,   753,   762,   771, 
      780,   789,   798,   807,   816,   825,   834,   843,   852,   861, 
      870,   879,   888,   897,   907,   916,   925,   934,   943,   952, 
      961,   970,   979,   989, 
};


// pressure [hPa] 입력, altitude [m] 반환
uint16_t calc_altitude(uint16_t pressure_hPa)
{
    if (pressure_hPa >= P_MAX) return 0;                   // 해수면 이하
    if (pressure_hPa <= P_MIN) return altitude_table[0];   // 1000m 이상

    // 테이블 인덱스
    int idx = P_MAX - pressure_hPa;

    return altitude_table[idx];
}

// 지연 함수
void delay_ms(int ms) {
    usleep(ms * 1000);
}

int main() {
    init_platform();
    
    xil_printf("========================================\r\n");
    xil_printf("BMP180 (GY-65) Sensor Test\r\n");
    xil_printf("========================================\r\n");
    
    // BMP180 초기화
    if (bmp180_init() != 0) {
        xil_printf("BMP180 initialization failed!\r\n");
        cleanup_platform();
        return -1;
    }
    
    // 메인 루프
    int count = 0;
    while (1) {
        xil_printf("Reading #%d\r\n", ++count);
        
        xil_printf("====================================\r\n");
        xil_printf("BMP180 Sensor Readings:\r\n");
        xil_printf("====================================\r\n");

        // 원시 온도 데이터 읽기
        int ut = bmp180_read_raw_temperature();
        if (ut < 0) {
            xil_printf("Temperature: ERROR\r\n");
        }else{
            // BMP180 데이터시트의 알고리즘
            long x1 = ((ut - cal_data.AC6) * cal_data.AC5) >> 15;
            long x2 = (cal_data.MC << 11) / (x1 + cal_data.MD);
            long b5 = x1 + x2;
            long t = (b5 + 8) >> 4;

            //return t / 10.0f;
            int temperature = t / 10;
            int temperatureMod = t % 10;

            xil_printf("Temperature: %d.%d°C\r\n", temperature, temperatureMod);
        }

        long up = bmp180_read_raw_pressure();
        if (up < 0) {
            xil_printf("Pressure:    ERROR\r\n");
        } else if (ut >= 0 && up >= 0) {
            // 온도 보상을 위한 값 계산            
            long x1 = ((ut - cal_data.AC6) * cal_data.AC5) >> 15;
            long x2 = (cal_data.MC << 11) / (x1 + cal_data.MD);
            long b5 = x1 + x2;
            
            // 압력 측정
            // 압력 계산 (BMP180 데이터시트 알고리즘)
            long b6 = b5 - 4000;
            x1 = (cal_data.B2 * (b6 * b6 >> 12)) >> 11;
            x2 = cal_data.AC2 * b6 >> 11;
            long x3 = x1 + x2;
            long b3 = (((cal_data.AC1 * 4 + x3) << oss) + 2) >> 2;
            
            x1 = cal_data.AC3 * b6 >> 13;
            x2 = (cal_data.B1 * (b6 * b6 >> 12)) >> 16;
            x3 = ((x1 + x2) + 2) >> 2;
            unsigned long b4 = (cal_data.AC4 * (unsigned long)(x3 + 32768)) >> 15;
            unsigned long b7 = ((unsigned long)up - b3) * (50000 >> oss);
            
            long p;
            if (b7 < 0x80000000) {
                p = (b7 * 2) / b4;
            } else {
                p = (b7 / b4) * 2;
            }
            
            x1 = (p >> 8) * (p >> 8);
            x1 = (x1 * 3038) >> 16;
            x2 = (-7357 * p) >> 16;
            p = p + ((x1 + x2 + 3791) >> 4);
            
        
            //return p / 100.0f;  // Pa를 hPa로 변환
            int pressure = p / 100;
            int pressureMod = p % 100;
            xil_printf("Pressure:    %d.%d hPa\r\n", pressure, pressureMod);
            int altitude = calc_altitude(pressure);
            if (altitude > 0) {
                xil_printf("Altitude:    %d m\r\n", altitude);
            } else {
                xil_printf("Altitude:    ERROR\r\n");
            }
        }

        // 1초 대기
        delay_ms(1000);
    }
    
    cleanup_platform();
    return 0;
}