import random

# print random.random()

mins =10000
nums = [0]*10
while True:
    for i in xrange(10):
        nums[i]=10000000+random.random()
    mean = sum(nums)/10.0
    s=0.0
    for i in xrange(10):
        s+= nums[i]**2 - mean**2
    s/=10.0
    # print s
    if s<mins:
        mins = s
        print mins
    if s<0:
        print "List of numbers to be taken: ", nums
        break
    
