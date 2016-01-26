/*#include "types.h"*/
/*#include "user.h"*/
/*[>#include "date.h"<]*/


/*int*/
/*main(int argc, char *argv[])*/
/*{*/
  /*[>struct rtcdate r;<]*/

  /*[>if (date(&r)) {<]*/
    /*[>printf(2, "date failed\n");<]*/
    /*[>exit();<]*/
  /*[>}<]*/

    /*int old_std= dup(1);*/
	/*int file = open("test1.txt",0777);*/
	/*[>std::cout << "Before dup2 line\n";<]*/
	/*printf(1, "Before dup2 line\n");*/
    /*dup2(file,1);*/
	/*printf(1, "After dup2 line\n");*/
	/*[>std::cout << "Just after dup2\n";<]*/
	/*//fflush(stdout);*/
	/*close(file);*/
	/*dup2(1,1);*/
	/*//fflush(stdout);*/
	/*dup2(old_std,1);*/
	/*close(old_std);*/
	/*printf(1, "After closing\n");*/
	/*[>std::cout <<  "After closing\n";<]*/
	/*return 0;*/
    /*[>printf(1,"\t  Year: %d\n  Month:%d\n  Date: %d\n  Hour: %d\n  Minute: %d\n  Second: %d\n",r.year,r.month,r.day, r.hour,r.minute,r.second);<]*/
  /*// your code to print the time in any format you like...*/

  /*exit();*/
/*}*/
// #include "types.h"
// #include "user.h"
// #include "date.h"
#include "param.h"
#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "fcntl.h"
#include "syscall.h"
#include "traps.h"
#include "memlayout.h"

int
main(int argc, char **argv)
{
     /*int pid, status;*/
     int newfd;	/* new file descriptor */

     if (argc != 2) {
         printf(2, "usage: %s output_file\n", argv[0]);
         exit();
     }
     if((newfd = open(argv[1], O_CREATE|O_RDWR)) < 0)
     {
         printf(2,"Error opening file\n");
         exit();
     }
     printf(1,"%d\n",newfd);
     printf(1,"This goes to the standard output.\n");
     printf(1,"Now the standard output will go to \"%s\".\n", argv[1]);

    int a = dup2(newfd,1);
	printf(1,"%d\n",a);

	printf(1,"This goes to the standard output too.\n");

	exit();
	// return 0;
}
