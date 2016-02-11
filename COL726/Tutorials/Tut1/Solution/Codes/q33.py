import math
import matplotlib.pyplot as plt
# import numpy as np

arr=[[0 for i in xrange(2)] for j in xrange(21)]
arr[0][0]= 1.0 - (1/math.e)
arr[0][1]= 1.0 - (1/math.e)

for i in xrange(1,21):
    arr[i][0]=1.0-i*arr[i-1][0]

for j in xrange(2,21,2):
    arr[j][1]=1 - j + j*(j-1)*arr[j-2][1]

yvals=[]
xvals=[i for i in xrange(21)]
for elem in arr:
    print elem
    yvals.append(elem[0])

plt.plot(xvals,yvals)
plt.grid(True)
plt.show()
    
