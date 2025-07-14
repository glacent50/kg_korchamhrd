/*
 *
 * 이 파일은 C 함수에서 지역 변수, static 변수, 전역 변수의 사용을 보여줍니다.
 * 세 가지 덧셈 함수가 포함되어 있습니다:
 *   - add: 두 정수의 합을 지역 변수로 누적합니다.
 *   - staticAdd: static 지역 변수를 사용하여 여러 번 호출 시 합을 누적합니다.
 *   - globalAdd: 전역 변수를 사용하여 여러 번 호출 시 합을 누적합니다.
 *
 * main 함수는 비트 연산을 시연하고 각 덧셈 함수를 두 번씩 호출하여
 * 결과를 콘솔에 출력합니다.
 *
 * 함수:
 *   int add(int a, int b)
 *     - 두 정수를 지역 변수로 더합니다.
 *     - 결과를 출력하고 반환합니다.
 *
 *   int staticAdd(int a, int b)
 *     - static 지역 변수를 사용하여 두 정수를 더합니다.
 *     - 함수 호출 간에 합을 누적합니다.
 *     - 누적 결과를 출력하고 반환합니다.
 *
 *   int globalAdd(int a, int b)
 *     - 전역 변수를 사용하여 두 정수를 더합니다.
 *     - 함수 호출 간에 합을 누적합니다.
 *     - 누적 결과를 출력하고 반환합니다.
 *
 * 전역 변수:
 *   int g_hab
 *     - globalAdd에서 합을 전역적으로 누적하는 데 사용됩니다.
 */

#include <stdio.h>

// 함수 프로토타입 선언
int add(int a, int b);
int staticAdd(int a, int b);
int globalAdd(int a, int b);

int g_hab;

int main(void)
{
    unsigned short data = 0x5678;
    unsigned short msk1 = 0xf000;

    int arr[5];

    printf("결과값 1 = %#.4x \n", data & msk1);

    add(1, 1);
    add(1, 1);

    staticAdd(1,1);
    staticAdd(1,1);

    globalAdd(1,1);
    globalAdd(1,1);

    printf("결과값 1 = %#.4x \n", data & msk1);

    return 0;
}

int add(int a, int b)
{
    int hab = 0;

    hab = hab + a + b;

    printf("--- llll %d \n", hab);

    return hab;
}

int staticAdd(int a, int b)
{
    static int s_hab = 0;

    s_hab = s_hab + a + b;

    printf("@@@@ ssss %d \n", s_hab);

    return s_hab;
}

int globalAdd(int a, int b)
{
    g_hab = g_hab + a + b;

    printf("@@@@ gggg %d \n", g_hab);

    return g_hab;
}

typedef int (*T_fun)(int, int);
T_fun fFunc = globalAdd;
