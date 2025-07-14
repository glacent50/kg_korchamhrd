#include <stdio.h>
#include <string.h>

typedef struct human
{
    int age;
    int height;
    int weight;
    char name[20];
} HUMAN;

char *tttt = "ddddddddd";
int g_Aaaa = 10; 

void testHuman(HUMAN *pinfo, HUMAN valinfo){
    printf("AAAAAAAAAAAAA");
}

void testVar(){
    g_Aaaa = 1000;
}

int main()
{
    char *very = "very";
    char much[10] = "hello";

    //HUMAN info = {10, 100, 100, "dkdkdkdkdk"};
    HUMAN info;
    HUMAN *pInfo;
    pInfo = &info;

    info.age = 10;
    info.height = 100;
    info.weight = 1000;
    strcpy(info.name, "jjjjjjj");

    printf("ddd : %s \n", very);

    testVar();

    int aaa = strlen(very);


    testHuman(&info, info);

    return 0;
}
