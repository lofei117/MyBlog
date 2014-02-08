---
layout: post
title: "Dive into String"
description: "Dive into String"
category: "Java"
tags: ["Java", "String"]
---
{% include JB/setup %}

# Introduction

String is a final class inheritanced from `java.lang.Object`, it represents for character strings. All string literals we see in Java, such as "abc", are implemented as instances of this class.

According to the document, Strings are defined as constants, that means the value of them cannot be changed after they are created. If you want mutable strings, you should use `StringBuilder`(or `StringBuffer`).

As a result that String objects are immutable, the can be shared. For instance:

```java
String str = "abc";
```
is equivalent to:

```java
char data[] = {'a', 'b', 'c'};
String str = new String(data);
```

String class has two attributes, `value` and `hash`. 

<!-- more -->

>```java
>  /** The value is used for character storage. */
>   private final char value[];
>
>   /** Cache the hash code for the string */
>    private int hash; // Default to 0
>```

and one of the constructors of String class is:

```java
public String(char value[]) {
    this.value = Arrays.copyOf(value, value.length);
}
```

Since String is a final class, it cannot be inheritanced.

# Instantiation
String class has 15 constructors, in which there are two deprecated. Usually we use:

```java
String str1 = "abc";
```

or:

```java
String str2 = new String("abc");
```

to create String object. The two ways above are different. In the former one, characters are stored in **stack memory** when the latter are stored in **heap memory**. Enventually, if we use `str1==str2` to compare them, it would return `false` cause java compares objects use their address for operation: `==`.

In the former one, Java would create a reference object of String class, and then searching the stack whether there is an address storing value "abc", if yes, let the reference `str1` point to it, otherwise, create a new String type object with value "abc", and let `str1` point to it. 

So, if we create another String object with value "abc":

```java
String str3 = "abc";
```
it's obvious that `str1==str3` would return `true` cause they are point to the same address. When, to

```java
String str4 = new String("abc");
```
`str2==str4` would return `false`. 

# Equality

In this section, I will start with below example.

```java
public static void main(String[] args) {
	String a = "123";
	String b = "123";

	String c = new String("123");
	String d = new String("123");

	System.out.println(a == b);
	System.out.println(c == d);
	System.out.println(a == c);

	System.out.println(a.equals(c));
}
```
The output is:

```
true
false
false
true
```

Because java compares two objects by their address when use `==`. So if you want to check two String objects whether they have the same content, you should use `equals` method.

Let's have a look at `equals` method's code:

```java
    public boolean equals(Object anObject) {
        if (this == anObject) {
            return true;
        }
        if (anObject instanceof String) {
            String anotherString = (String) anObject;
            int n = value.length;
            if (n == anotherString.value.length) {
                char v1[] = value;
                char v2[] = anotherString.value;
                int i = 0;
                while (n-- != 0) {
                    if (v1[i] != v2[i])
                            return false;
                    i++;
                }
                return true;
            }
        }
        return false;
    }
```
Here we can see that String class compute the equal by check the characters one by one. 

# Concatenation
Sometimes you may want to use:

```java
	str1 = str1 + "def";
```
to concatenate two strings.
In this process, `str1` is not pointing to the address of `abc` anymore, according to the document, concatenation operator "+" of String is implemented through `StringBuilder`(or `StringBuffer`) class and its append method.

First, java will create a new object `StringBuilder` in heap memory, then copy the value of str1 and value "def" to the `StringBuilder` object, finally let the `str1` point to the object.

So that's why:

```java
	String a = "abc";
	String b = "abcdef";

	a = a + "def";

	System.out.println(a == b);
```
would return `false`.

Another method to concatenate two String objects is use `concat` method.
Here is the code:

```java
    public String concat(String str) {
        int otherLen = str.length();
        if (otherLen == 0) {
            return this;
        }
        int len = value.length;
        char buf[] = Arrays.copyOf(value, len + otherLen);
        str.getChars(buf, len);
        return new String(buf, true);
    }
```
When the length of the argument `str` is 0 (means it's an empty String), the original String will return, otherwise, a new String object would be created. As a result, it would take more time and cost more memory to concatenate the strings.
(Remind yourself that String is immutable object.)

`StringBuilder`(or `StringBuffer`) is recommended to use to concatenate strings, cause they can change the length through certain method calls. `StringBuilder` is added since version 1.5, regarded as a replacement of `StringBuffer`. The difference between them is that `StringBuilder` is not thread-safe but `StringBuffer` is. So it's recommended that `StringBuilder` be used in preference to `StringBuffer` when possible as it will be faster. Otherwise, if in multi-thread environment, you should use `StringBuffer`.

Here is an example to test the performance of these three classes.

```java
	public static void main(String[] args) {
		String str1 = "string";
		String str2 = "1";
		StringBuilder sbd = new StringBuilder("string");
		StringBuffer sbf = new StringBuffer("string");
		
		long start = System.currentTimeMillis();
		for (int i = 0; i < 50000; i++) {
			str1 = str1 + str2;
		}
		long end = System.currentTimeMillis();
		System.out.println("Time of operator + :" + (end - start) + " ms");
		
		start = System.currentTimeMillis();
		for (int i = 0; i < 50000; i++) {
			str1 = str1.concat(str2);
		}
		end = System.currentTimeMillis();
		System.out.println("Time of concat method :" + (end - start) + " ms");
		
		start = System.currentTimeMillis();
		for (int i = 0; i < 50000; i++) {
			sbd.append(str2);
		}
		end = System.currentTimeMillis();
		System.out.println("Time of StringBuilder :" + (end - start) + " ms");
		
		start = System.currentTimeMillis();
		for (int i = 0; i < 50000; i++) {
			sbf.append(str2);
		}
		end = System.currentTimeMillis();
		System.out.println("Time of StringBuffer :" + (end - start) + " ms");
	}
```

Output:

```
Time of operator + :3931 ms
Time of concat method :6211 ms
Time of StringBuilder :2 ms
Time of StringBuffer :4 ms
```

I've tested some cases, I found that *operator + is* most like :

```java
	StringBuilder sb = null ;
	for (int i = 0; i < 50000; i++) {
		sb = new StringBuilder(str1);
		sb.append(str2);			
	}
	str1 = sb.toString();
```

*concat method* is slower than *operator +* is because that *operator +* concatenate strings in stack when *concat* in heap.

(
If you set `str2` to an empty String(`String str2 = ""`), the output is:

```
Time of operator + :27 ms
Time of concat method :1 ms
Time of StringBuilder :1 ms
Time of StringBuffer :3 ms
```
)

I'm sure you already know why.


# See Also

* [String][String]
* [StringBuilder][StringBuilder]
* [StringBuffer][StringBuffer]

[String]: http://docs.oracle.com/javase/7/docs/api/java/lang/String.html "String"
[StringBuffer]: http://docs.oracle.com/javase/7/docs/api/java/lang/StringBuffer.html "StringBuffer"
[StringBuilder]: http://docs.oracle.com/javase/7/docs/api/java/lang/StringBuilder.html "StringBuilder"