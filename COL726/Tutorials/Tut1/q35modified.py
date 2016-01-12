n = 1000000
h = 111.11

sum1 = 0.0
for i in range (1,n):
    sum1 = sum1 + 0.1
print sum1,(n-1)*0.1

sum2 = 0.0
sum3 = 0.0
for j in range (1,n):
    sum2 = sum2 + (j*h)
    sum3 = sum3 + (n-j)*h
print sum2,sum3,(sum2-sum3)

sum4 = 0.0
sum5 = 0.0
for j in range (1,n):
    sum4 = h*j - h*j
    sum5 = sum5 - h*(n-j+1);
for j in range(1,n):
    sum5 = sum5 + h*j;
print sum4, sum5, (sum4-sum5)
