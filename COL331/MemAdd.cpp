#include <iostream>

int main()
{
    int *x = new int[5000];
    for (int j=0; j<100000000; j++)
    {
        int y=87;
        int z = y+321;
        y = z-34;
    }
    //for (int j=0; j<1000; j++)
    //{
        //std::cout << x <<"\n";
    //}

        std::cout << x <<"\n";
    return 0;
}
