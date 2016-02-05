import math

def Integrate(f, start,stop, step):
    ans = 0.0
    elem = start
    while (elem<stop):
        ans += 0.5*step*(f(elem)+f(elem+step))
        elem += step
    # for elem in xrange(start,stop,step):
        # ans += 0.5*(f(elem)+f(elem+step))
    return ans

print "test"

def fact(n):
    return n*2.0
print math.sin(math.pi/2)
# print Integrate(fact,1,2,0.5)
print Integrate(math.sin,0,math.pi,0.1)
print Integrate(math.sin,0,math.pi,0.01)
print Integrate(math.sin,0,math.pi,0.001)
