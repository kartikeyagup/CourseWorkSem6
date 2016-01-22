#include <iostream>

int main(int argc, char** argv)
{
    const char* x = "hello";
    std::cout << argv[1] <<"\n";
    if (strcmp(argv[1],x)==0)
    {
        std::cout << "In the if case\n";
        return 0;
    }
    std::cout << "Didnt reach the if case\n";
    return 0;
}
