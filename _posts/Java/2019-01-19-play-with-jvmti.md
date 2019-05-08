---
layout: post
title: "Play with JVMTI"
description: "Play with JVMTI"
category: "java"
tags: ['java', 'jvmti']
---
{% include JB/setup %}

> 上周讲了如何使用 `Android Studio` 来进行高阶调试。今天来讲一讲关于 `Java` 调试背后的东西————`JPDA`.

# 0x0 JPDA
`Java Platform Debugger Architecture`，简称`JPDA`，是Java平台针对调试(`Debug`)一套完整的架构定义。它定义了底层后端接口`JVMTI`、中间的传输层`JDWP`，以及顶层前端的调试接口`JDI`，一共三层结构。

```text
             Components                         Debugger Interfaces

                /    |--------------|
               /     |     VM       |
 debuggee ----(      |--------------|  <------- JVM TI - Java VM Tool Interface
               \     |   back-end   |
                \    |--------------|
                /           |
 comm channel -(            |  <--------------- JDWP - Java Debug Wire Protocol
                \           |
                     |--------------|
                     | front-end    |
                     |--------------|  <------- JDI - Java Debug Interface
                     |      UI      |
                     |--------------|

```


* `JVMTI`---`Java Virtual Machine Tool Interface`
    * `JVMTI`从Java 1.5开始引进，用于代替`JVMPI（Java VM Profiling Interface)`和`JVMDI(Java VM Debug Interface)`，它定义了在 Java 虚拟机层，即被调试者(`debuggee`)的调试接口，如果一个`JVM`需要支持调试，那么它直接根据`JVMTI`接口实现是最省事的。当然，不同的`JVM`对于`JVMTI`的支持不一定相同，比如`Android`的`Dalvik VM`和`ART`环境，就略有不同。
* `JDWP`---`Java Debug Wire Protocal`
    * `JDWP`定义了`debuggee`和`debugger`的传输协议。
* `JDI`---`Java Debug Interface`
    * `JDI`是高层级的Java语言调试接口，通过实现`JDI`，我们可以自己编写一个调试工具，例如之前我们提到的`Android Studio`的调试工具。
    
    
# 0x1 JVMTI
前面介绍了`JPDA`的基础知识，以及它的三层接口。接下来开始详细介绍`JVMTI`，这也是我们本篇文章的主要内容。

`JVMTI`是虚拟机端的编程接口，通常来说，每一个虚拟机都有一个`JVMTI`实现。它可以用来获取当前虚拟机的状态信息（线程信息、内存堆栈信息），也可以用来进行调试交互（设置断点、修改内存值等），以及获得相关通知回调（断点触发等）。我们可以使用`c/c++/JNI`代码来编写一个`native`库`Agent`，用来和虚拟机交互，获得想要的信息。

# 0x2 Agent的工作过程
有两种类型的`Agent`，一个是我们前面提到的通过`c/c++`，使用`JNI`编写的`native`库，还有一种是使用`Java`编写的`Java Agent`，即我们常见的`instrument`。`Java Agent`可以理解为高层级的`Agent`，它的底层其实也是由一层`c/c++`编写的动态链接库（例如`libinstument.so`）来实现跟`JVMTI`交互的。
这里我们将针对`native`层的`agent`（我们假定它为`libagent.so`）进行分析。
我们通过`c/c++`通过`JNI`编写的动态链接库，可以有两种方式加载到`JVM`中来。

* 通过命令行参数`-agentlib:<agent-lib-name>=<options>`或者`-agentpath:<path-to-agent>=<options>`加载
* 通过Java代码，使用`VirtualMachine`进行`attach`之后，使用`loadAgentLibrary`或者`loadAgentPath`加载。

其中`-agentlib`对应`loadAgentLibrary`，它需要我们将动态链接库`libagent.so`的路径添加到系统的相关路径中（`Windows`的`Path`，`Linux`的`LD_LIBRARY_PATH`等）；而`-agentpath`和`loadAgentPath`则需要指定一个完整的可访问路径（`-agentpath`可以是相对路径，`loadAgentPath`必须是完整的路径）。

## 通过命令行参数加载
通过命令行参数加载，即在启动`Java`程序时将参数传入，启动的时候会调用`libagent.so`的以下这个方法：

```c++
JNIEXPORT jint JNICALL 
Agent_OnLoad(JavaVM *vm, char *options, void *reserved)
```

虚拟机会在初始化之前调用该函数，这意味着什么呢？这意味着：

* 没有任何类被加载；
* 没有对象被创建；
* 没有任何字节码被执行；

但是呢，还是有些事情可以做的：

* 系统级参数`system properties`已被设置好；
* `Capability`相关功能是完整可用的

什么是`Capability`呢？单词翻译过来是能力的意思，顾名思义，它代表了当前`JVM`环境下`JVMTI`所支持的能力。

在初始化的时候，我们就可以对`Capability`进行操作，通过`addCapability`函数，来让`JVM`支持我们想要的能力。例如我们想要有中断线程的能力，就需要将`Capability`结构体的`can_signal_thread`设置为`TRUE(1)`，如果我们需要得到方法进入时的通知事件，就需要设置`can_generate_method_entry_events`.

如下代码所示：
```c++
JNIEXPORT jint JNICALL Agent_OnLoad(JavaVM *jvm, char *options, void *reserved){
    jvmtiEnv *jvmti = 0;
    jint ret = (vm)->GetEnv(reinterpret_cast<void**>(&jvmti),JVMTI_VERSION_1_1);
    if (ret != JNI_OK || jvmti == 0) {
		throw AgentException(JVMTI_ERROR_INTERNAL);
	}
    // 创建一个新的环境
    jvmtiCapabilities caps;
    memset(&caps, 0, sizeof(caps));
    caps.can_generate_method_entry_events = 1;

    // 设置当前环境
    jvmtiError error = jvmti->AddCapabilities(&caps);
    CheckException(error);
    return JNI_OK;
}
```

有些`Capability`可以在`Agent_OnAttach`的时候修改，而绝大多数必须在`Agent_OnLoad`的时候才能设置。
每个`JVMTI`环境都拥有独立的`Capability`设置，即使是同一个`library`库，在`Agent_OnLoad`之后，再次使用`loadAgentPath`加载，也属于不同的`JVMTI`环境，拥有不同的`Capability`.

## `Attach`之后加载
说到`Attach`，熟悉`Android Studio`调试的同学都知道。当程序的`debuggable`为`true`时，我们就可以通过`Android Studio`来`Attach`到对应的进程中，而不需要重新使用`Debug As`来启动程序。这极大的减少了我们调试过程中不必要的等待时间。
它的这个功能，和我们这里要将的，基本原理是一样的。
我们这里要讲的是启用一个`Java`进程，然后通过`Virtual Machine`的`attach`方法附着到对应进程上去，然后再通过`loadAgentLibrary`或者`loadAgentPath`加载对应的动态链接库，从而建立起通道来实现相关的功能。
而`Android Studio`的`Attach Debugger to Android Process`是使用`LLDB`来当前端。具体我还未深入进行分析，猜想其实是在`Java`的`Attach`上进行了封装，或者是直接使用`LLDB`来当`JDI`，通过`socket`实现`JDWP`. 后者的可能性更大一点。

回到正题。
和上一节不同，`Attach`成功之后，会调用`libagent.so`的`Agent_OnAttach`方法：
```c++
JNIEXPORT jint JNICALL Agent_OnAttach(JavaVM *vm, char *options,
    void *reserved) 
```
和`Agent_OnLoad`方法不同，`Agent_OnAttach`时`JVM`已经在正常运行，因此，有一些`Capability`可能无法使用，而且我们也无法对其进行修改。

> 有个小插曲，当我在Mac Os里直接打开先前编译好的Java程序，通过`attach`之后，再使用`loadAgentPath`加载lib库，始终无法成功。会报如下错误：
> ```java
>Exception in thread "main" java.io.IOException: Non-numeric value found - int expected
>at sun.tools.attach.HotSpotVirtualMachine.readInt(HotSpotVirtualMachine.java:255)
>	at sun.tools.attach.HotSpotVirtualMachine.loadAgentLibrary(HotSpotVirtualMachine.java:63)
>	at sun.tools.attach.HotSpotVirtualMachine.loadAgentPath(HotSpotVirtualMachine.java:88)
>	at info.lofei.test.VMAttacher.main(VMAttacher.java:16)
>
>Process finished with exit code 1
>
> ```
>调试跟进，发现`HotSpotVirtualMachine#readInt`相关代码，获取的`var2(slot2)`值是`return code:0`, 分析源码，我认为这个`0`其实是正确的响应结果，是我们期望的值，然而一整句的`return code:0`却不是。将`return code:0`转化成`int`值的时候就报错了。分析了`socket`流，分析了`lib`库的底层代码，始终不得其解。后来通过`Intellij`把目标进程启动，发现返回值变成了正确的`0`，可以正常运行了！后来反复对比，才发现是因为我本机装了不同版本的`JDK`, 包括`Java 10`和`Java 8`，出错的原因是，通过`Java Default Launcher`直接启动，使用的是`Java 10`, 而使用`Java 8`版本通过命令行`java -jar`启动是可以正确运行的。
>好坑😂。

## 卸载
无论是通过`Agent_OnLoad`还是`Agent_OnAttach`方式加载，最终都要等到目标进程结束之后，才会卸载。卸载回调的是`Agent_OnUnload`方法：
```c++
JNIEXPORT void JNICALL Agent_OnUnload(JavaVM *vm)
```
这意味着，当一个类库已经被加载过之后，即便是在磁盘上重新替换类库，重新通过`loadAgentPath`加载，生效的仍然是之前的代码。

# 0x3 玩一玩JVMTI
前面我们已经讲了`JPDA`和`JVMTI`的基本知识。下面我们要来动手玩一玩如何使用`JVMTI`。
在IBM学习论坛里，有前辈已经写了一个DEMO，本文的学习也是参考了他们写的教程《深入 Java 调试体系》。地址详见最后的参考文章。

该DEMO已经实现了`JVMTI`初始化加载`Agent`相关逻辑，编写了回调，当目标`Java`程序方法调用时，将其打印出来。并通过传入参数，可以实现仅过滤打印感兴趣的方法。

我的想法是，通过`attach`来添加一个方法断点，当断点击中后，将对应的传入参数打印出来。

关于`JVMTI`初始化等相关代码这里不展开详细讲，只讲和设置断点有关的逻辑。详细原理可以参考上面提到的IBM的《深入 Java 调试体系》以及Oracle的官方教程。

思路是这样的：
* 初始化的时候将`can_generate_breakpoint_events`以及`can_generate_method_entry_events`这两个`capability`设置为`TRUE(1)`;
* 初始化的时候通过`SetEventNotificationMode`添加通知，监听方法进入通知以及断点击中通知；
* 在方法进入通知中，通过`SetBreakpoint`方法添加一个断点；
* 断点击中后，打印信息，并将该断点移除；
> **注**：这里仅提供最基础的断点添加回调。而实际的开发过程中，应该是通过`JDI/JDWP`来和`JVMTI`打交道来实现断点增删改调试。

有了思路之后，就让我们动手写代码吧！

## 添加`Capability`
```c++
    // 创建一个新的环境
    jvmtiCapabilities caps;
    memset(&caps, 0, sizeof(caps));
    caps.can_generate_breakpoint_events = 1;
    caps.can_generate_method_entry_events = 1;

    // 设置当前环境
    jvmtiError error = m_jvmti->AddCapabilities(&caps);
	CheckException(error);
```

## 添加通知回调
```c++
    // 创建一个新的回调函数
    jvmtiEventCallbacks callbacks;
    memset(&callbacks, 0, sizeof(callbacks));
    callbacks.Breakpoint = &DebugAgent::HandleDebugMethodEntry;
    callbacks.MethodEntry = &DebugAgent::HandleMethodEntry;

    // 设置回调函数
    jvmtiError error;
    error = m_jvmti->SetEventCallbacks(&callbacks, static_cast<jint>(sizeof(callbacks)));
    CheckException(error);

    // 开启事件监听
    error = m_jvmti->SetEventNotificationMode(JVMTI_ENABLE, JVMTI_EVENT_BREAKPOINT, 0);
    CheckException(error);

    error = m_jvmti->SetEventNotificationMode(JVMTI_ENABLE, JVMTI_EVENT_METHOD_ENTRY, 0);
    CheckException(error);
```
## 实现回调函数（添加断点）
```c++

void JNICALL DebugAgent::HandleMethodEntry(jvmtiEnv* jvmti, JNIEnv* jni, jthread thread, jmethodID method)
{
	try {
        // 省略其他逻辑
        
        // 检测是否有对应的capability
        jvmtiCapabilities caps;
        memset(&caps, 0, sizeof(caps));
        jvmtiError error = jvmti->GetCapabilities(&caps);
        CheckException(error);
        cout << "Can debug:" << caps.can_generate_breakpoint_events << endl;
        if (caps.can_generate_breakpoint_events) {
            // 设置断点
            error = m_jvmti->SetBreakpoint(method, NULL);
            if (error == JVMTI_ERROR_NONE) {
                cout << "SetBreakpoint for " << signature<< " -> " << name << "(..) succeed."<< endl;
            }
        }

        // 其他逻辑...

	} catch (AgentException& e) {
		cout << "Error when enter HandleMethodEntry: " << e.what() << " [" << e.ErrCode() << "]" << endl;
    }
}

void JNICALL DebugAgent::HandleDebugMethodEntry(jvmtiEnv* jvmti, JNIEnv* jni, jthread thread, jmethodID method, jlocation location)
{
	// 处理回调逻辑、打印断点信息、移除断点等
}
```

## 编写测试的Java程序
代码略，详见Demo源码。
启动该程序时通过`-agentpath`启动：
```bash
-agentpath:${path}/PlayJVMTI/out/lib/libagent.so
```

## 运行结果
```java
Agent_OnLoad(0x108874788)
 Parse options:setBreakpoint
Can debug:1
SetBreakpoint for Linfo/lofei/demo/jvmti/Controller; -> setBreakpoint(..) succeed.
Linfo/lofei/demo/jvmti/Controller; -> setBreakpoint(..)
Breakpoint hit Linfo/lofei/demo/jvmti/Controller; -> setBreakpoint(..)
Set breakpoint call.
```

# 0x4 参考文章
* [https://www.ibm.com/developerworks/cn/java/j-lo-jpda2/index.html?ca=drs-](https://www.ibm.com/developerworks/cn/java/j-lo-jpda2/index.html?ca=drs- "JVMTI 和 Agent 实现")
* [https://docs.oracle.com/javase/8/docs/platform/jvmti/jvmti.html](https://docs.oracle.com/javase/8/docs/platform/jvmti/jvmti.html "JVMTM Tool Interface")
* [https://www.oracle.com/technetwork/articles/java/jvmti-136367.html](https://www.oracle.com/technetwork/articles/java/jvmti-136367.html "Creating a Debugging and Profiling Agent with JVMTI")

# 0x5 本文源码
* [https://github.com/lofei117/PlayJVMTI](https://github.com/lofei117/PlayJVMTI "PlayJVMTI")