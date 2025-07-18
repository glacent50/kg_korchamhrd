#include <stdio.h>

int main(int argc, char const *argv[])
{
    /*
     * 이 코드는 별표(*)로 다이아몬드 모양과 비슷한 패턴을 출력합니다.
     * 두 개의 중첩된 반복문을 사용합니다:
     * - 바깥쪽 반복문(i 변수)은 0부터 8까지 반복하며, 행의 개수를 제어합니다.
     * - 처음 5행(i < 5)에서는 안쪽 반복문이 별의 개수를 1개에서 5개까지 증가시키며 출력합니다.
     * - 나머지 행에서는 별의 개수를 4개에서 1개까지 감소시키며 출력합니다.
     * 각 행의 끝에는 줄바꿈 문자를 출력합니다.
     */
    int i = 0, j = 0;
    for (i = 0; i < 9; i++)
    {
        // 12345 4321
        if (i < 5)
        {
            for (j = 0; j <= i; j++)
            {
                printf("*");
            }
        }
        else
        {
            for (j = 0; j <= (8 - i); j++)
            {
                printf("*");
            }
        }
        printf("\n");
    }
}


int sum(int x, int y) {
    return x + y;
}