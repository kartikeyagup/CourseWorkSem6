from decimal import *

def sqrt(c,x):
    return (x+c/x)/2

sqrtnum = Decimal(2.0)
guess = Decimal(1.0)
for i in xrange(10):
    print i,guess
    guess = sqrt(sqrtnum, guess)
