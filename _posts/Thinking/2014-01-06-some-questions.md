---
layout: post
title: "Some Questions"
description: "This is an archive of some questions, generally interview questions."
category: "Thinking"
tags: ["Thinking"]
---
{% include JB/setup %}

# Foreword
I cannot remember everything I met, so I am gonna write this blog to record them.

## Question
When you have three buckets, one is full of **apples**, one is full of **oranges**, and the third is full of **oranges + apples**, each bucket has a label on them, but the the labels are not in their correct position. If you have only one chance to choose one bucket and get a fruit from it, how can you figure them out.

## Answer
This is a logic question, and the key of this question is that **Both the three labels are attached to wrong buckets**.
Let's define **apples** as `A`, **oranges** as `O`, and **oranges + apples** as `O+A`, label of **apple** as `AL`, label of **oranges** as `OL`, and `(O+A)L`. Then, enum the possible combinations of them.

* 1. `A`:`OL`, `O`:`(O+A)L`, `O+A`:`AL`
* 2. `A`:`(O+A)L`, `O`:`AL`, `O+A`:`OL`

As we can see, we only have two groups. Owing to that labels are in wrong position, bucket with label `(O+A)L` contain only one kind of fruit(apple or orange), so just check this bucket, if we get **apple**, this must be **apple** bucket(group 2), otherwise if we get **orange** it must be **orange** bucket(group 1), and then we will know another two buckets according to the combination.

## Question
If you have a 5 gallons bucket, and a 3 gallons bucket, how to get 4 gallons bucket water? (There is enough water you can use.)

## Answer
Well, this is a simple question, I remember that I could calculate it when I was a primary student. 

* 1. Fill the 5 gallons bucket with water, and then pour them to the 3 gallons one, now we get 2 gallons of water in 5 gallons bucket and 3 gallons of water in 3 gallons bucket.
* 2. Pour the water in 3 gallos bucket out, make it empty.
* 3. Pour the 2 gallons water in 5 gallons bucket to 3 gallons bucket, now we get an empty 5 gallons bucket and 2 gallons water in 3 gallons bucket.
* 4. Fill the 5 gallons bucket with water, and then pour portion of it to 3 gallons bucket to make it full, cause 3 gallons bucket already has 2 gallons of water, so we could only pour 1 gallon of water to it. Eventually, we get 4 gallons of water in 5 gallons bucket.

## Question
In the above question, what if we have a `x` gallons bucket and a `y` gallons bucket when we want to get `z` gallons of water?

## Answer
Analyse the quesion and think about it, we will find that, no matter how many steps we do and what we do, the `z` gallons is depend on `x` and `y`, and what ever the `x` and `y` were as long as they are positive integers, we can get `z` gallons of water(also `z` is positive integer). That means, there must be two integers `k1` and `k2`, to make the equation ``k1*x + k2*y = z`` established. Well, that's it.

## Question
If you have 21 coins, including a heavier one, by using a balance, how many times will you use the balance to find the heavier coin out?

## Answer
3 times is enough. 
* 1. Divide the coins to three groups 7-7-7
* 2. Choose two groups and put them on the balance, as a result you will get which group is heavier. (If they are balanced, the third group not on the balance is heavier)
* 3. Divide the 7 coins to three groups again by 2-2-3
* 4. Put the two groups with two coins on the balance. If they are not balanced, you will get the heaview group, jump to step 5. otherwise, the heavier coin is in the 3-coins group, jump to step 6.
* 5. Seperate the two coins and put them on the balance, finally, you will get the heavier coin.
* 6. Choose two coins from the 3-coins group, put them on the balance, if they are not balanced, you have already get the heavier one, otherwise, the left one is the heavier one.

## Question
If you have 12 coins, including a special one, you don't know whether it's heavier or lighter, use the balance for three times, how to find the special one out? And how to judge it's heavier or lighter?

## Answer
This question is a little complex, the problem is that we don't know whether it's heavier or lighter.

* 1. First, let's mark the coins with 1-12.
* 2. Put 1,2,3,4 coins on the left dish of the balance, 5,6,7,8 on the right of the balance. If they are balanced, jump to step 3.1, otherwise jump to step 3.2. (Weigh the 1st time)
* 3.
	* 3.1 Since 1234 is equivalent to 5678, we can conclude that the special one is in 9,10,11,12. Put 1,2 and 9 on the left dish of the balance, and 3,10,11 on the right dish. If they are balanced, jump to step 4.1, else jump to 4.2. (Weight the 2nd time.)
	* 3.2 In this section, there are two possible cases, 1,2,3,4 is heavier, or lighter. Whatever, the 9,10,11,12 coins are normal. Put 1,6,7,8 on the left dish, 5,9,10,11 on the right. If they are balanced, jump to step 5.1, else jump to 5.2. (Weigh the 2nd time.)
* 4.
	* 4.1 If you jump to this step, it means that the 12 coin which have not been weigh is the special coin, to judge it is heavier or lighter, just use an normal coin like coin 1 to weigh with it, then you will know the 12 coin is heavier or lighter. (Weigh the 3rd time.)
	* 4.2 Now we know the special ball is in 9,10 and 11. In step 3.1, cause the balance is unbalanced, you will get some possible result. If 1,2,9 is heavier than 3,10,11, it means the special coin may be 9(heavier) or 10/11 (lighter), otherwise if 1,2,9 is lighter, it means the special coin may be 9(lighter), or 10/11(heavier). Put 1,10 on the left dish, 2,11 on the right dish, if they are balanced, it means 9 is the special(heavier or lighter is known already), if they are unbalanced, for instance 1,10 is heavier than 2,11, according to the **9 heavier,10/11 lighter** and **9 lighter, 10/11 heavier** combination, the result is 11 lighter or 10 heavier. (Weigh the 3rd time.)
* 5.
	* 5.1 The special coin must be in 2,3,4, in step 2(the 1st weigh), if 1,2,3,4 is heavier than 5,6,7,8, it means the special is a heavier one, otherwise, it is lighter. To find out the special, just put 2 on the left and 3 on the right. If they are balanced, the special is 4, if unbalanced, you will get the special according to the conclusion whether the special is heavier or lighter. (Weight the 3rd time.)
	* 5.2 In this case, the special must be in 1,5,6,7,8. Based on the result in step 2(the 1st weigh), if the result is same as step 2(i.e. 1,2,3,4 is heavier and 1,6,7,8 is heavier, or both the group is lighter), it means the special is 1 or 5, just compare 1 and 9 for the last time, you will find out which is special, and heavier or lighter would be inferred from step 2. if the result is not same as step 2, it means the special is in 6,7,8. For instance, if 1,2,3,4 is heavier and 1,6,7,8 is lighter, it meas the special one is lighter in 6,7,8, put 6 and 7 on balance then we will know which one is the special. 

Well, it's a little complex, and I've tried to describe clearer. Maybe I should divide the steps to more. Here is a web page of the 12 coin question, a 12 ball game, you can play it several times, I'm sure you will comprehense it.
[12-ball-quesion](http://fun.lofei.info/12ball/ "12-ball-game")