#include <stdio.h>
#include <unistd.h>

int main()
{
    printf("starting \n");

    int counter = 0;
    pid_t pid = fork();

    if (pid ==0)
    {
        int i=0;
        int *x = new int[500];
        printf("pid 0: %d \n",x);
        for(; i<5000; i++)
        {
            /*printf("child process: counter=%d\n",++counter);*/
        }
    }
    else if (pid>0)
    {
        int j=0;
        int *x = new int[500];
        printf("pid 1: %d \n",x);
        for (; j<5000; j++)
        {
            /*printf("parent process: counter=%d\n",++counter);*/
        }
    }
    else
    {
        printf("Fork failed\n");
    }
    printf("Program exiting\n");
    return 0;
}
