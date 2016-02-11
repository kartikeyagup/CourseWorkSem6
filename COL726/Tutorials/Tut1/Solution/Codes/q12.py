import math 
import matplotlib.pyplot as plt 

h=0.1

def correct(x):
    return math.e**(x**2)+ x

y=[]
x=[]
z = [1.0]

x.append(0.0)
y.append(1.0)

for i in xrange(1,20):
    y.append(y[-1]+h*(2*x[-1]*y[-1] -2*x[-1]**2 +1))
    x.append(0.1*i)
    z.append(correct(x[-1]))


print x
print y
print z
plt.plot(x,y,color='red')
plt.plot(x,z,color='blue')
plt.grid(True)
plt.show()
    


