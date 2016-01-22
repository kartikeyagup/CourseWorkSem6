#include <iostream>
#include <unistd.h>
#include <fcntl.h>

int main()
{
	int old_std= dup(1);
	int file = open("test1.txt",O_RDWR);
	std::cout << "Before dup2 line\n";
	dup2(file,1);
	std::cout << "Just after dup2\n";
	//fflush(stdout);
	close(file);
	dup2(1,1);
	//fflush(stdout);
	dup2(old_std,1);
	close(old_std);
	std::cout <<  "After closing\n";
	return 0;
}
