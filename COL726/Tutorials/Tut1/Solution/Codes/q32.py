from math import *
import random

def NormalMethod(a,b,c):
    # print b**2 - 4*a*c
    t1 = sqrt(b**2 - 4*a*c)
    return ((t1-b)/(2*a), (-t1-b)/(2*a))

def InverseMethod(a,b,c):
    t1 = sqrt(b**2 - 4*a*c)
    return (-2*c/(b+t1),-2*c/(b-t1))


def Compare(a,b,c):
    a*=1.0
    b*=1.0
    c*=1.0
    return (NormalMethod(a,b,c),InverseMethod(a,b,c))

print Compare(1.0,-2.0,1.0)

sumval = 0.0
maxval = 0.0
NUMCASES = 10

for i in xrange(10):
    l2= random.randint(1000000,100000000)
    l1= random.randint(0,100)
    l3= random.randint(0,100)
    res = Compare(l1,l2,l3)
    absdiff = abs(res[0][0]-res[1][0])+ abs(res[0][1]-res[1][1])
    # print absdiff
    sumval += absdiff
    maxval = max(maxval,absdiff)
    # if absdiff>0.1:
        # print absdiff, l1,l2,l3
    # print Compare(l1,l2,l3)

sumval /= NUMCASES
print "Mean Difference: ", sumval
print "Max difference ", maxval
