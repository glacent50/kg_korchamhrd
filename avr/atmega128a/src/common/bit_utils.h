#ifndef BIT_UTILS_H
#define BIT_UTILS_H

// 특정 비트를 1로 설정 (SET)
#define SET_BIT(REG, BIT)     ((REG) |= (1 << (BIT)))

// 특정 비트를 0으로 설정 (CLEAR)
#define CLR_BIT(REG, BIT)     ((REG) &= ~(1 << (BIT)))

// 특정 비트를 토글 (반전)
#define TOG_BIT(REG, BIT)     ((REG) ^= (1 << (BIT)))

// 특정 비트의 상태 읽기
#define READ_BIT(REG, BIT)    (((REG) >> (BIT)) & 0x01)

// 특정 비트가 1로 설정되었는지 확인
#define IS_BIT_SET(REG, BIT)  (((REG) >> (BIT)) & 0x01)

// 특정 비트가 0으로 설정되었는지 확인
#define IS_BIT_CLR(REG, BIT)  (!IS_BIT_SET(REG, BIT))

// 값의 특정 비트들을 설정
#define SET_BITS(REG, MASK)   ((REG) |= (MASK))

// 값의 특정 비트들을 클리어
#define CLR_BITS(REG, MASK)   ((REG) &= ~(MASK))

#endif // BIT_UTILS_H