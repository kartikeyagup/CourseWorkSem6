#include <iostream>

int main()
{
    int *x = new int[5000];
    for (int j=0; j<1000000; j++)
    {
        int y=87;
    }
    for (int j=0; j<1000; j++)
    {
        std::cout << x <<"\n";
    }

    return 0;
}
