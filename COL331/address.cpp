#include <stdio.h>
int staticVar = 0;
int main(int argc, char** argv) {

	staticVar += 1;
	for (int i = 0; i<100000000; i++)
	{	int y=87;
        int z = y+321;
        y = z-34;
    }
		// printf("%s",argv[1]);

	printf ("Address: %p\n", &staticVar);
	// int t;
	// scanf("%d",&t);
}
