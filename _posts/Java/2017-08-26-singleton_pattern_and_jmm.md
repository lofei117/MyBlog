---
layout: post
title: "Singleton Pattern and Java memory model"
description: "Singleton Pattern and Java memory model"
category: "Java"
tags: ["Java", "Singleton Pattern"]
---
{% include JB/setup %}

# 前言

单例模式可以说是设计模式里最常用、也是最容易手写的案例了，然而要真正把单例模式写好，并明白为何那么写，还是蛮有文章的。最近在温习Java内存模型相关知识，准备就单例模式的一些特殊写法，来谈一谈Java Memory Model.

# 单例模式的常见写法

* Case 0.

静态常量对象、静态内部类、枚举类型写法。
这三种写法都是线程安全的，在本文中并不展开讲解。这三种写法不能使用动态参数创建实例，使用场景也相对有限。

* Case 1.

```java
public class SingletonTest {

    private static SingletonTest sInstance;

    public static SingletonTest getInstance() {
        if (sInstance == null) {
            sInstance = new SingletonTest();
        }
        return sInstance;
    }

    public static void main(String[] args) {
        SingletonTest.getInstance();
    }
}
```
这种写法，是最低级最常见的错误写法，没有任何锁机制。在线程并发过程中，会出现“重复创建相同对象”、“使用未完全初始化完成对象”两种问题。

* Case 2.

```java
public class SingletonTest {

    private static SingletonTest sInstance;

    public synchronized static SingletonTest getInstance() {
        if (sInstance == null) {
            sInstance = new SingletonTest();
        }
        return sInstance;
    }

    public static void main(String[] args) {
        SingletonTest.getInstance();
    }
}
```
这种写法也是很常见的写法，从正确性上来说，这个写法是正确的，但是从性能上来考虑，synchronized锁耗性能，这种写法每次调用`getInstance`时都会锁定，只有一个线程能够使用。而我们只需要在实例对象为空需要实例化时才锁定，因此这种写法也是不推荐的。


* Case 3.

```java
public class SingletonTest {

    private static SingletonTest sInstance;

    public static SingletonTest getInstance() {
        if (sInstance == null) {
            synchronized (SingletonTest.class) {
                if (sInstance == null) {
                    sInstance = new SingletonTest();
                }
            }
        }
        return sInstance;
    }

    public static void main(String[] args) {
        SingletonTest.getInstance();
    }
}
```

这种写法应该是更常见的写法了，很多教科书的示例都是这个，但是这个方法，在Java中并不正确。问题主要在`sInstance = new SingletonTest();`这一句，正常程序思维下，一定是这一句执行完之后，才返回`sInstance`值。在单线程模型中，这也是没有任何问题的。
我们通过`javap -verbose SingletonTest`查看生成的字节码，结果如下：

```java
public static info.lofei.java.SingletonTest getInstance();
    descriptor: ()Linfo/lofei/java/SingletonTest;
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=0
         0: getstatic     #2                  // Field sInstance:Linfo/lofei/java/SingletonTest;
         3: ifnonnull     37
         6: ldc           #3                  // class info/lofei/java/SingletonTest
         8: dup           
         9: astore_0      
        10: monitorenter  
        11: getstatic     #2                  // Field sInstance:Linfo/lofei/java/SingletonTest;
        14: ifnonnull     27
        17: new           #3                  // class info/lofei/java/SingletonTest
        20: dup           
        21: invokespecial #4                  // Method "<init>":()V
        24: putstatic     #2                  // Field sInstance:Linfo/lofei/java/SingletonTest;
        27: aload_0       
        28: monitorexit   
        29: goto          37
        32: astore_1      
        33: aload_0       
        34: monitorexit   
        35: aload_1       
        36: athrow        
        37: getstatic     #2                  // Field sInstance:Linfo/lofei/java/SingletonTest;
        40: areturn       

```   

`sInstance = new SingletonTest();` 这一句，对应于上述中17-24。17的`new`步骤，会在java堆中创建一个`SingletonTest`的对象，为其分配内存空间，同时在操作栈中压入对象的引用。20的`dup`操作则是复制了一份这个引用，因为接下来的21中，`invokespecial`操作是执行构造器里真正的对象初始化，需要传入`this`引用，会消耗掉一个栈顶引用值。最后才是24的`putstatic`，将对象的引用值设置给`sInstance`。

在处理器执行代码过程中，会尽可能的优化程序代码和重排代码执行顺序，来达到并发的优化。而代码重排序，包括了编译器重排序和处理器重排序。在本示例中，拥有因果关系的语句不会被重排，`putstatic`一定是在`new`之后执行的，因为只有`new`之后，才会有对象引用值可以供`putstatic`使用，而因为`invokespecial`也需要使用一个隐藏的引用值`this`，所以，`putstatic`和`invokespecial`也必须都在`dup`之后执行，但是，基于处理器重排的原因，`putstatic`不一定会在`invokespecial`之后执行.但是有一点，有数据依赖性的地方，顺序一定是同步的，也就是`return`语句，一定会是在它之前的所有语句执行完才会去执行。这也是为什么在单线程模型中，上述的代码不会有问题的原因。
但是呢，单例的大部分使用场景，都是要为多线程服务的，在多线程并发过程中，就会涉及到数据竞争问题。

在多线程并发过程中，线程A的`putstatic`执行完之后，`sInstance`值不再为null，此时线程B调用`getInstance`方法，判定`sInstance`不为null，直接返回使用，那么就可能出现调用`SingletonTest`内部的对象值不正确，甚至报`NullPointerException`异常。

# 线程并发与内存模型

## 线程通信机制
线程并发通信有两种实现机制。`共享内存`和`消息传递`。

在`共享内存`的并发模型里，线程之间共享程序的公共状态，线程之间通过写-读内存中的公共状态来隐式进行通信。在`消息传递`的并发模型里，线程之间没有公共状态，线程之间必须通过明确的发送消息来显式进行通信。<sup>[1][JMM1]</sup>

Java采用的是`共享内存`模型来实现线程通信。因此，Java中的线程同步是*显示*同步、*隐式*通信。

## 共享内存与“本地内存”
在Java中，所有的*实例(instance fields)*、*静态域(static fields)*以及*数组元素(array elements)*存储在堆内存中，堆内存在线程之间共享。每个线程，都有自己的一个专属“本地内存”，这是一个虚拟的概念，涉及到缓存、写缓冲区、寄存器及其他硬件和编译器优化。我们把线程共享的数据叫做“主内存”，下图便是线程共享的概念图。

![Java thread memory sharing](/assets/java/java_thread_memory_sharing.png "Java thread memory sharing")

*局部变量(Local variable)*、*方法定义参数(formal method parameters)*、*异常处理器参数(exception handler parameters)*不会在线程之间共享，他们不会有*内存可见性*问题。

如上图所示，由于每个线程都有自己的本地内存，当线程执行过程中，结果都是先保存到本地内存，然后再从本地内存刷新到堆内存之中。而另一个线程则把共享内存的数据同步到它的本地内存之中，再进行它的运行计算。

## 可见性问题和**Happens-before**原则

上面我们提到，线程拥有自己的本地内存，处理器计算的结果，会先保存到线程的本地内存，比如说写缓冲区，然后才刷新同步到共享内存中。而另外一个线程，则会从共享线程中同步数据到本地内存进行自己的运算处理。而问题，就出在本地内存同步到共享内存的过程，如果没有经过特殊处理，缓冲区的刷新操作是不保证同步的。

**可见性**，指的是当一个线程对变量发生修改时，这些改变可以被其他线程看到。`final`变量，`volatile`变量，以及`synchronized`变量都具有**可见性**。

在JSR-133模型中，提出了**Happens-before**原则，这一章比较繁琐，而且有些看得还不是特别明白，网上的介绍也比较模糊，我准备在仔细阅读之后再详细展开叙述。

## `volatile`关键字	

`volatile`是java保留关键字，通过该关键字声明的变量，在JVM执行的时候，会生成内存屏障(memory barriers)，禁止处理器对其的重排。通俗的说法，我们把它称为轻量级的`synchronized`。`synchronized`锁具有两种特性，`互斥性`和`可见性`。`volatile`具有`可见性`特性，但却不具备`互斥性`特性。因此，它拥有更高的读写效率，在某些场合，我们可以用来替代`synchronized`的变量。
在JVM执行过程中，线程对`volatile`的写，保证其之前的操作一定会先于`volatile`的写发生，并强行刷新写缓冲区到共享内存。对于`volatile`的读，一定会从共享内存中同步最新的值（包括之前读取的其他变量值）。

因此，Case 3的代码可以改成如下：


```java
public class SingletonTest {

    private static volatile SingletonTest sInstance;

    public static SingletonTest getInstance() {
        if (sInstance == null) {
            synchronized (SingletonTest.class) {
                if (sInstance == null) {
                    sInstance = new SingletonTest();
                }
            }
        }
        return sInstance;
    }

    public static void main(String[] args) {
        SingletonTest.getInstance();
    }
}
```

对`sInstance`变量进行写操作时，一定会保证`invokespecial`在`putstatic`之前完成，并从线程缓冲区刷新到共享内存。而另一个线程读取`sInstance`时，一定会从共享内存读取到最新的值，则完美的避免了重复创建对象，以及避免对象未完全正确初始化就使用的问题。

## 总结
其实上面的分析，很多还是很片面，还有很多内容需要深入分析和补充。不过怕琐事太多，坑越拖越填不上，所以先简单分析总结一下，后续再补充和纠正吧。也希望大家看到后能够给出意见和见解~

# See Also

* [JMM1][JMM1]
* [volatile fields][volatile fields]
* [Oracle docs][Oracle docs]

[JMM1]: http://www.infoq.com/cn/articles/java-memory-model-1 "深入理解Java内存模型（一）——基础"
[volatile fields]: http://docs.oracle.com/javase/specs/jls/se7/html/jls-8.html#jls-8.3.1.4 "volatile vields"
[Oracle docs]: http://docs.oracle.com/javase/specs/jls/se7/html/jls-17.html#jls-17.4 "Oracle docs"