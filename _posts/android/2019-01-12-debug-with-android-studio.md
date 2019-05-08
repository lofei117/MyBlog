---
layout: post
title: "Debug with Android Studio"
description: "Debug with Android Studio"
category: "android"
tags: ['android']
---
{% include JB/setup %}

> 使用调试工具(Debug Tools)进行调试(Debug)是一个程序员必不可少的技能，但是很多程序员对于调试工具的使用，很多都仍处于初级阶段。即便是工作很多年的老鸟，可能也只会最基础的调试。前段时间根据自己所掌握的调试基础，给公司内部作了一个分享，这里再行记录一下。
其实从准备开始记录这些基础的琐碎的东西，经常要拖好久才能完成。一个是因为有些忙，一个是因为有些懒，还有一个是因为觉得，所要记录的这些东西太基础了。
技术的学习就是这样，有些东西，无论基础与否，如果不熟悉，或者好久没有使用了，便生疏了。而一旦掌握或者重新掌握，觉得不过如此而已。   
所谓不积跬步无以至千里，不积小流无以成江海。还是踏踏实实的记录下来吧，权当以后做一个回顾。


# 0x0 基础信息界面介绍
* 首先上来介绍一下最基本的信息——图形界面介绍。

![主界面一览图](https://mmbiz.qpic.cn/mmbiz_jpg/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLBC2Ltb7XLAYrbibpqZ1ZApMYlqHXUAzuiah9QINX9mibXd4GatFZAqicBQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1 "Main.png")

如图所示，我将界面分成了ABCEDF六个区块，其中A为我们最常用的代码工作区，B为断点调试的快捷按钮区（Step Out/Step into等等），C为Debug相关工具快捷按钮区（Restart/Resume/Stop等等)，D为当前断点线程和方法栈展示区，E为变量展示区，F为断点信息区。
> **注**：Intellij和Android Studio，以及不同版本的Android Studio之间界面会有些许差别。本例中版本为Android Studio 3.3.

* B-调试快捷按钮区域

![调试快捷按钮区域](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaL3Da8dWibRDOXxj5gNMYUicj3gYPJth0ibGppCOlSKRbMQMSRvE7vTmGbg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

第一个按钮的作用是快速定位到当前断点（指的是当前运行）所在位置。当我们调试到某行代码时，往往会点击某个类或者某个方法去查看它的源码（不是`Step Into`，只是查看代码)，点了好几层之后，想要快速回到最开始的位置，只需要点击这个按钮即可。
接下来的4个按钮做过研发的同学想必都很熟悉了，分别是`Step Over`/`Step Into`/`Force Step Into`/`Step Out`，`Step Into`和`Force Step Into`的区别在于，前者能够进入自己编写以及第三方库（包括Android SDK）的方法（默认跳过jdk的方法），后者可以进入jdk源码的代码。
第5个按钮是`Drop Frame`，顾名思义，是将当前帧卸载掉，意思就是讲当前执行的代码回滚。为什么这个按钮在这里是灰的，不可点击的呢？因为Android的`Dalvik`虚拟机及`ART`机制都不支持该操作，如果我们是原始的`Java`程序，`jvm`支持的情况下，就可以实现这个功能。
我们可以在`junit`中试一下这个功能。

![Drop Frame](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLcNSplEeNAHNszCUeWicpSpdUrCPTXvfJzWfMuCcicEaJibe2OUFHeSibPg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

在`Drop Frame`后面是`Evaluate Expression`按钮，这个也是非常有用的一个功能。点击这个按钮，我们可以编写代码做一些计算工作。

![Evaluate Expression](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLo6eKakjGMXEL0pMUhfAzqEH7JcP3gibddv6A90vI9IVvicLLZ3Y5yrYQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

最后一个置灰的按钮是`Trace Current Stream Chain`，是用来跟踪`java8`的`lambda`语法流状态的。这里不展开讲解。

* C-调试相关工具快捷按钮区
这一块蛮简单的，主要是上面提到的中断调试、恢复运行、查看设置断点，以及一些调试设置等。大家可以自行试用一下。
主要提一点就是照相机📷那个按钮，`Get the thread dump`，可以将线程信息导出来查看。

![线程信息](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLlCibopAE8Y8yZzUAlAHlJuicibYDsvc92ycRcKvssMBlwbXnkbaf6DJCQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)


* D-调用帧区域
在调用栈区域，可以点击某个方法，查看调用该方法时，相关变量的值。

![调用帧](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaL7Rib3ECVMWVnnnOhnlgDsvVAWYGjb17uLR9RJokQElia2qujY8Hzz9DA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

> **注**：`Frames`旁边的`Threads`顾名思义就是线程相关信息。

* E-变量区域
如上节所述，E区域为IDE的变量展示区域。我们可以看到当前状态下各个变量的值（我们也可以在A区域实时预览变量的值）。在E区域，我们可以看到左边有一写快捷按钮，可以快速的添加我们关心的变量值。这些按钮是`Watch View`的操作按钮，当前版本Android Studio默认将`Watch View`和`Variables View`放在一起展示。这样能够节省展示空间，也更加方便。

![变量区域](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLmlTMtewqdsMUFZfaiaToZ9WLwLkMTy1VGF7QZHNunywFvDZkQ1JRe2Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![变量值快捷预览](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLQeic4qL4qkJBNXB4ky8mzibgqXDtUGR04ia6Hz5e9gIVfPZnRfbNXtp1A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

# 0x1 断点类型介绍

![断点类型](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLKe7Pzr3U5N3J4XCpR22KVShFKpL1pkibywB93hIDFH2sYicuu7obVyjw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

如上图所示，在Android Studio中可以添加以下几种断点：
* Java Line Breakpoints
* Java Field Watchpoints
* Java Method Breakpoints
* Java Exception Breakpoints
* Kotlin Field Watchpoints
* Exception Breakpoints
* Symbolic Breakpoints

第一个`Java Line Breakpoints`是我们最常用，也是最基础的断点。相信使用过调试工具的开发者一定都会用这个，而实际情况是，很多好多年开发经验的老鸟，也仅停留在这一种类型断点的调试。
第二个`Java Field Watchpoints`，可以对某个类当中的某个变量值进行监听，监听它的读取或者修改，这个功能在多线程开发中特别有用。通过添加这个类型的断点，我们就可以知道，变量的值究竟是什么时候被改变成了什么。
第三个`Java Method Breakpoints`，可以指定监听某个方法的调用。当任何地方调用到匹配的方法时，就会停在方法最开始的位置。
第四个`Java Exception Breakpoints`，可以指定某种异常类型，当该异常发生时，虚拟机就停留在发生异常的地方，保留现场。这个功能对于我们来说也非常有用。
第五个`Kotlin Field Watchpoints`和第二个类似，只不过语言是`Kotlin`。
第六个`Exception Breakpoints`顾名思义是所有异常断点，它包括`Java Exception`和其他的一些异常。
第七个`Symbolic Breakpoints`符号表断点，查阅了一些资料，目前只找到跟iOS有关的资料。

本文主要针对前四个跟Java相关的断点进行讲解。

# 0x2 添加一个断点
`Java Line Breakpoints`最简单，只要在对应代码行最前面点一下就可以添加一个断点，这里不展开讲。

![添加断点](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLnic0LIoWialNzj5mdNCgc4TicwNUKEutUoLIkwpsS8Q2ZHibuLia2HCpH1A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)
其余的断点都可以在如上界面添加。

![Add Java Exception Breakpoint](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaL7Yy6fzphXqJpsYzLc2CuN1JewnbGZCEbib0dE8miauDwaeJ6E1CT32nA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![Add Java Field Watchpoint](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaL5u6fzLWoMVqPxGH93eP0QXX3CiaX6y2sXyuUXRemY8S1HoWxweW64lA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![Add Java Method Breakpoint](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaLNQ2JnQKr3vABGIK0IdYMDk8tg2TtXProDIBfY39KtvCALE74hkgxGA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

如上三张图所示，分别是添加其对应断点的界面。不同的是`Exception Breakpoint`和`Field Watchpoint`都需要准确的包名类名索引，而`Method Breakpoint`却能够支持通过正则来匹配对应的类名或者方法名。
此外，`Field Watchpoint`必须是处于自己工程中的代码才有效，如果是`Android SDK`中类的变量，也无法添加。
而不论是何种断点，添加成功后，我们都可以修改断点的配置，来使调试过程更符合我们的需求。

# 0x3 断点精细配置

![Breakpoint options](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwShiawBiaIvF9yALRZykGDl6iaL9D3SHdceFTvqIialYKVL0oTiaNvRtoBY7WAN8a8JBwKSlMZqSMeU7ciaA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

我们可以在之前添加断点的界面，或者在击中断点之后，右击断点来弹出如上界面，来配置断点详情。
* `Suspend`，是否暂停。如果选择了暂停，则击中断点之后，则会暂停等待我们进行下一步操作。暂停可以选择`All`所有线程，或者`Thread`当前线程。如果选择不暂停，则可以结合下面的`Evaluate and log`来输出日志。这个对于我们用于持续观察很有用。例如滑动界面时，将坐标持续打印在logcat中，而不需要修改代码重新运行。
* `Condition`，设置断点击中的条件，当且仅当条件满足时，断点才会起作用。
* `Log`，根据后面勾选的可选项，可以将断点击中的信息或者调用栈打印到`Debug`的`Console`中。
* `Evaluate and log`，可以根据自己的需求编写代码，然后计算出想要的值并将其打印到`Debug`的`Console`中，当然，也可以在代码中使用`android.util.Log`来打印到`logcat`中。

右下角的`Instance filters`/`Class filter`/`Pass Count`/`Caller filters`和`Condition`一样，都属于为该断点设置条件，当且仅当条件满足时，才算命中断点。

其中`Pass Count`最简单，勾选此选项，并输入一个大于0的整形数字n，则当第n次命中断点时才算真正命中。前面n-1次都跳过去了。不勾选即默认为`1`。

如`Breakpoint options`图所示，`Instance filters`对应的ID，为代码对应的`this`的值`MainActivity@5127`的`5127`这个数字。这个有什么用处呢？我目前还没找到特别合适且非它不可的场景。思考了下，可能是当`Method Breakpoints`通过正则模糊匹配断点时，结合起来用。
`Class filters`也一样，不过需要注意的是，如果监听的是匿名类中的断点，类名需要加上对应的引用。如`MainActivity$3`。如果是内部类也一样。（当然，可以用正则*来匹配任意类）。
`Caller filters`是调用者的过滤器。如图所示，指的仅是调用当前方法的前一个`Caller`，而不是任何在调用栈上的`Caller`。例如调用步骤是`a()->b()->c()->d()->f()`和`a()->a2()->c()->d()`，对于`c()`的调用者有`b()`和`a2()`两种可能，我们配了`b()`后，则第一种情况能命中断点，第二种情况不能命中。而如果我们把`Caller filters`配成`a()`，则两种情况都不会命中断点。
这里同样支持正则来匹配。
   
其余的一些设置选项都比较简单，大家可以自己尝试一下，这里不详细展开讲。
> **注**：不同的断点类型也会有一些不同的设置选项，比如`Field Watchpoint`可以设置`Field access`和`Field modification`检测。而`Method Breakpoints`拥有`Method entry`/`Method exit`选项。

# 0x4 小结
粗粗略略算是写完了。然而其实省略了很多细节，如果深究每一个细节写完，感觉显得太啰嗦太基础。
更多细节的地方，还是留给大家自己去摸索使用吧。毕竟本来这就是一篇很基础的水文。😄