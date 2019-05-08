---
layout: post
title: "Android remote debug"
description: ""
category: "Android remote debug"
tags: ['android']
---
{% include JB/setup %}


> 上周学习了`JPDA`里关于`JVMTI`的基本知识，然后动手写了一个简单的`Agent`实现。刚好最近看到美团技术博客里，关于`Android`远程调试的一篇文章。[https://tech.meituan.com/2017/07/20/android-remote-debug.html](https://tech.meituan.com/2017/07/20/android-remote-debug.html "Android远程调试") 于是动手写了一下。
> **注：** 本文大部分内容，和美团的这篇技术博客相似，可以理解为根据美团的文章进行实践，然后记录笔记，以及附加一些我在实践过程中遇到的一些问题。

# 0x0 背景
身为一个`Android`开发者，肯定遇到过很多线上问题无法复现，难以排查的情况。有时候因为没有线上问题对应的机型，另外有些时候，即便是机型一样，也很难模拟用户使用时的具体情景，导致问题迟迟无法解决。
而我们开发过程中，遇到绝大部分问题，除了尝试复现，还可以结合`Debug`等手段，获取当前程序运行的状态，包括变量信息、堆栈信息、线程信息等等。这个时候我们就在想，如果可以远程调试就好了。
而我们知道，`Java`程序时支持远程调试的，那`Android`是不是也一样呢？答案是肯定的。

`Android`虽然采用了`Dalvik`以及`ART`模式来适配手机，但本质还是一种特殊的`JVM`, 之前介绍`JPDA`的时候已经介绍了`JVM`调试框架。要想让`JVM`支持调试，那么必须在`JVM`启动的时候加载支持`JVMTI`的`Agent`，通过这个`Agent`和`JVMTI`通信，设置断点、获取堆栈信息等。`Hotspot VM`以及`Dalvik VM`都自带了`JVMTI`和`JDWP`实现。即我们可以用任意我们喜欢的`JDI`去进行调试，例如`IDE`自带的调试工具，或者`jdb`, 甚至自己动手写一个`JDI`工具来调试。

# 0x1 Android调试原理
在一般的`Java`程序中，要支持调试，必须（排除自己实现`JDWP`的情况）使用如下命令来启动`Java`程序:

```java
java -jar ${jarName} -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8888
```

启动之后，就可以用各种调试工具通过`ip:port`连接到该程序上去进行调试(根据`transport`不同，连接方式会有区别）。
而开发`Android`程序的时候，要想让`Android`程序支持调试，通常来讲，会有如下两种方式：
* 1. 需要将`AndroidManifest.xml`中(或者`build.gradle`中对应的`buildType`)的`debuggable`设置成`true`；
* 2. 将系统设置的`ro.debuggable`设置成`1`；

其中第二个对于绝大部分`Android`开发者来说几乎不会用到，因为它需要在编译源码的时候就将该值设置好，或者是拥有`root`权限之后，去修改这个值。

美团技术博客介绍的方法，就是第三种 ***不通常*** 的方法。即`debuggable`为`false`，也没有`root`权限去将`ro.debuggable`修改为`1`. 
扯了这么多，其实原理都是一样，只有一个，只有当目标程序的虚拟机环境支持`jdwp`，才能支持调试。那么，怎么样绕过以上两种方法，来将`jdwp`开启呢？

# 0x3 JDWP源码分析
`Android`的`jdwp`涉及的源码很多，我也并没有全部去分析。参考美团的文章，我们最关心的功能**开启**调试功能，代码主要在`runtime/debugger.cc`的`StartJdwp()`方法。以`Android 5.0`的源码[https://android.googlesource.com/platform/art/+/android-cts-5.0_r9/runtime/debugger.cc#641](https://android.googlesource.com/platform/art/+/android-cts-5.0_r9/runtime/debugger.cc#641 "StartJdwp")为例：

```c++
void Dbg::StartJdwp() {
  if (!gJdwpAllowed || !IsJdwpConfigured()) {
    // No JDWP for you!
    return;
  }
  CHECK(gRegistry == nullptr);
  gRegistry = new ObjectRegistry;
  // Init JDWP if the debugger is enabled. This may connect out to a
  // debugger, passively listen for a debugger, or block waiting for a
  // debugger.
  gJdwpState = JDWP::JdwpState::Create(&gJdwpOptions);
  if (gJdwpState == NULL) {
    // We probably failed because some other process has the port already, which means that
    // if we don't abort the user is likely to think they're talking to us when they're actually
    // talking to that other process.
    LOG(FATAL) << "Debugger thread failed to initialize";
  }
  // If a debugger has already attached, send the "welcome" message.
  // This may cause us to suspend all threads.
  if (gJdwpState->IsActive()) {
    ScopedObjectAccess soa(Thread::Current());
    if (!gJdwpState->PostVMStart()) {
      LOG(WARNING) << "Failed to post 'start' message to debugger";
    }
  }
}
```

我们看到，决定`jdwp`能否开启有两个因素，一个是`gJdwpAllowed`，另外一个是`IsJdwpConfigured()`. 

```c++
bool Dbg::IsJdwpConfigured() {
  return gJdwpConfigured;
}

// JDWP is allowed unless the Zygote forbids it.
static bool gJdwpAllowed = true;
// Was there a -Xrunjdwp or -agentlib:jdwp= argument on the command line?
static bool gJdwpConfigured = false;
```
   
我们看到`gJdwpAllowed`默认是`true`的，但是`gJdwpConfigured`默认是`false`. 如注释所说，如果启动程序的时候，命令行参数带有`-Xrunjdwp`或者`-agentlib:Jdwp=`时，这个值就应该变成`true`. 

然后我们接着找，很快就找到了对应的代码：

```c++
/*
 * Parse the latter half of a -Xrunjdwp/-agentlib:jdwp= string, e.g.:
 * "transport=dt_socket,address=8000,server=y,suspend=n"
 */
bool Dbg::ParseJdwpOptions(const std::string& options) {
  VLOG(jdwp) << "ParseJdwpOptions: " << options;
  std::vector<std::string> pairs;
  Split(options, ',', pairs);
  for (size_t i = 0; i < pairs.size(); ++i) {
    std::string::size_type equals = pairs[i].find('=');
    if (equals == std::string::npos) {
      LOG(ERROR) << "Can't parse JDWP option '" << pairs[i] << "' in '" << options << "'";
      return false;
    }
    ParseJdwpOption(pairs[i].substr(0, equals), pairs[i].substr(equals + 1));
  }
  if (gJdwpOptions.transport == JDWP::kJdwpTransportUnknown) {
    LOG(ERROR) << "Must specify JDWP transport: " << options;
  }
  if (!gJdwpOptions.server && (gJdwpOptions.host.empty() || gJdwpOptions.port == 0)) {
    LOG(ERROR) << "Must specify JDWP host and port when server=n: " << options;
    return false;
  }
  gJdwpConfigured = true;
  return true;
}

```
到这里已经很明了了，只需要将`ParseJdwpOptions`的参数，用我们想要的参数传进去，然后重新调用`StartJdwp`就可以了。

那么不禁要问，这些都是系统的源码啊，我怎么才能去调用系统源码里的方法呢？
这个时候需要介绍一下，上面的这些代码，最终打包后生成了`libart.so`这个动态链接库，`libart.so`顾名思义是`Android Runtime`的动态链接库，它包含了很多功能，我们本文讲的`jdwp`只是其中的一小块。`Android`系统在启动程序的时候一定会将`libart.so`动态加载进来。
动态链接库有一个特点，就是它只能被加载一次，后续如果你替换了动态链接库重新加载，使用的仍然是之前加载的那一个。这个特性有时候很烦，特别是在做热更新方案的时候，`so`库就只能等程序重启才能更新。但是在这个时候，这个~~恶心~~牛逼的特性，就帮上了大忙。

# 0x4 dlopen/dlsym
`Java`加载动态链接库有两种办法，一个是`Java`层的`System.loadLibrary`，另一个是`JNI`层的`dlopen`. `Android`开发者对于前者应该不陌生，而后者则需要有一定`JNI`开发经验或者熟悉`Linux`开发的同学才了解了。
`dlopen`用来加载动态链接库，加载成功后，返回其在内存中的句柄。而`dlsym`则是用来获取某个方法（符号后的函数名）的地址。而因为动态链接库只能被加载一次，所以无论后续调用多少次`dlopen`(不考虑异常情况)，其对应的内存块地址都是一样的。
什么是符号化的函数名呢？因为写代码的时候，常常会有名字一样的函数（方法），即我们常说的重载。而C语言是不允许函数同名的，因此编译器就将整个方法，包括它的类型信息编码符号化。类似如下的代码：
```c++
// 符号化之前
int  f (void) { return 1; }
int  f (int)  { return 0; }
void g (void) { int i = f(), j = f(0); }
// 符号化之后
int  __f_v (void) { return 1; }
int  __f_i (int)  { return 0; }
void __g_v (void) { int i = __f_v(), j = __f_i(0); }
```
我们可以通过`nm`命令来查看一个动态链接库里所有的符号化名称。而当我们的程序动态链接库发生崩溃时，我们也可以通过`nm`结合`addr2line`来将崩溃信息和源码关联上。

我们通过`nm`命令查找`StartJdwp`, `StopJdwp`, `ParseJdwpOptions`等函数的符号化函数名，得到如下结果：

> **注：** 以下libart.so为Android 5.0版本，不同版本的符号化函数名可能不同：

```shell
➜  nm libart.so | grep StartJdwp
0015f070 T _ZN3art3Dbg9StartJdwpEv
00291880 t _ZN3art4JDWPL15StartJdwpThreadEPv
➜  nm libart.so | grep StopJdwp
00180880 T _ZN3art3Dbg8StopJdwpEv
➜  nm libart.so | grep ParseJdwpOptions
0017ef40 T _ZN3art3Dbg16ParseJdwpOptionsERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE
➜  nm libart.so | grep SetJdwpAllowed
00153180 T _ZN3art3Dbg14SetJdwpAllowedEb
➜  
```

得到这些符号化函数名之后，我们就可以使用`dlopen`, `dlsym`, 还有`dlclose`来开启`jdwp`啦。
代码如下：
```c++
void reloadJdwpPreNougat(jboolean open) {
    void *handler = dlopen("/system/lib/libart.so", RTLD_NOW);
    if(handler == NULL){
        const char* err = dlerror();
        LOGD("dlerror: %s", err);
    }
    LOGD("handler address: %p", &handler);
    //对于debuggable false的配置，重新设置为可调试
    void (*allowJdwp)(bool);
    allowJdwp = (void (*)(bool)) dlsym(handler, "_ZN3art3Dbg14SetJdwpAllowedEb");
    allowJdwp(true);

    void (*pfun)();
    //关闭之前启动的jdwp-thread
    pfun = (void (*)()) dlsym(handler, "_ZN3art3Dbg8StopJdwpEv");
    pfun();

    if (open == JNI_TRUE) {
        //重新配置gJdwpOptions
        bool (*parseJdwpOptions)(const std::string&);
        parseJdwpOptions = (bool (*)(const std::string&)) dlsym(handler,
                                                                "_ZN3art3Dbg16ParseJdwpOptionsERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
        std::string options = "transport=dt_socket,address=8000,server=y,suspend=n";
        parseJdwpOptions(options);

        //重新startJdwp
        pfun = (void (*)()) dlsym(handler, "_ZN3art3Dbg9StartJdwpEv");
        pfun();
    }
    dlclose(handler);
}
```
我们来看一看`logcat`的日志输出：
```java
01-26 19:50:06.660 7621-7621/? D/test: Java click reloadJdwp
01-26 19:50:06.660 7621-7621/? D/native-lib: reload jdwp called to 1.
01-26 19:50:06.660 7621-7621/? D/native-lib: os version: 22
01-26 19:50:06.660 7621-7621/? D/native-lib: handler address: 0xbf8096f4
01-26 19:50:06.661 7621-7629/? I/art: Debugger is no longer active
01-26 19:50:06.666 7621-7621/? I/art: JDWP will listen on port 8000
```
这个时候，我们就已经把`jdwp`成功以`socket`的方式启动了，监听端口是`8000`. 我们就可以用任何我们喜欢的`JDI`工具去进行调试，比如在`Android Studio`里新建一个`Remote Debug`配置。或者是使用`jdb`来`attach`上去。
我这里使用的是模拟器，模拟器的ip地址是`10.0.2.15`，难以直接连上去，所以在连接之前，使用`adb forward tcp:8000 tcp:8000`绑定端口，将请求转发过去。

![jdb调试](https://mmbiz.qpic.cn/mmbiz_png/UCv8n8eUwSgib6QBianqGgaicV4yq8IGvNor1YkoiaicbVRmQVDV5ibRZWfjiajqN9ETBgddkDltuXGsMBU4QjibM5iaAng/0?wx_fmt=png "jdb")

# 0x5 剩下的工作
到目前，我们实现了在`Release`编译的程序里打开`jdwp`调试，但仅仅只是打开了这个功能，如果需要支持远端调试，仍然还有很多工作要做。我暂时列了如下几点：
* 1. 适配不同版本的`Android`系统，特别是`Android 7.0`之后，对于系统动态链接库的`dlopen`做了限制，美团的技术文章也有提到，也提供了解决方案，我这里参考了一个开源库[https://github.com/avs333/Nougat_dlfunctions](https://github.com/avs333/Nougat_dlfunctions "Nougat_dlfunctions") 
* 2. 编写我们自己的`JDI`和`JDWP`，能够下发调试命令；
* 3. 通过`Push`通道下发命令，需要在手机端启动一个新的进程（或者线程），将请求通过`socket`转发到虚拟机的`JDWP`去执行，并得到相应的结果信息；
* 4. 回传信息；

> **注：** Android 7.0 `dlopen`适配时，不同的编译方式可能需要修改下代码，比如用`clang++`编译，针对`void *`指针使用`+`来进行地址偏移会报错。
> ```c++
> error: arithmetic on a pointer to void
> ```
> 可以将其转化为`char *`之后再进行操作。


# 0x6 参考文章
* [https://tech.meituan.com/2017/07/20/android-remote-debug.html](https://tech.meituan.com/2017/07/20/android-remote-debug.html "Android远程调试") 
* [https://github.com/avs333/Nougat_dlfunctions](https://github.com/avs333/Nougat_dlfunctions "Nougat_dlfunctions")

# 0x7 本文源码
* [https://github.com/lofei117/AndroidRemoteDebug](https://github.com/lofei117/AndroidRemoteDebug "AndroidRemoteDebug")