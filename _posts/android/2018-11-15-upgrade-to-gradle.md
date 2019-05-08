---
layout: post
title: "Upgrade to gradle"
description: "Upgrade to gradle"
category: "android"
tags: ['android','gradle']
---
{% include JB/setup %}

# Upgrade gradle to 4.6 （0）

> 下载了最新版的Android Studio之后，gradle插件版本可以升级到3.2.0，对应gradle-wrapper版本升级到4.6，与此同时，项目中一些自定义任务需要进行相关的修改，记录一下。

# 0x0 自定义混淆

在Android Studio里开发apk定义混淆很简单，只要在相应地方里配置`proguardFile`或者`proguardFiles`即可。如果是`library`模块供`application`依赖（`project`依赖或者`aar`依赖），可以在`library`里配置`consumerProguardFile`就可以自己控制混淆配置，无需在`application`层配置。而如果是`library`模块，输出`jar`包供第三方使用，则需要自己进行混淆。混淆可以直接使用`proguard`工具进行混淆，当然更方便的是使用Gradle自带的`ProguardTask`来进行混淆。

在之前版本的gradle环境（gradle 3.0.1）中，我们的配置如下：

```java
 1 task("proguard${nameCap}Jar", type: ProGuardTask, dependsOn: ["make${nameCap}Jar"]) {
 2    group = 'jar'
 3    description = 'make proguard jar'
 4
 5    injars originalJarPath
 6    outjars proguardJarPath
 7    configuration 'proguard-rules.pro'
 8    printmapping "${mappingFilePath}/mapping.txt"
 9
10    Plugin plugin = getPlugins().hasPlugin(AppPlugin) ?
11            getPlugins().findPlugin(AppPlugin) :
12            getPlugins().findPlugin(LibraryPlugin)
13    if (plugin != null) {
14        List<String> runtimeJarList
15        if (plugin.getMetaClass().getMetaMethod("getRuntimeJarList")) {
16            runtimeJarList = plugin.getRuntimeJarList()
17        } else if (android.getMetaClass().getMetaMethod("getBootClasspath")) {
18            runtimeJarList = android.getBootClasspath()
19        } else {
20            runtimeJarList = plugin.getBootClasspath()
21        }
22        for (String runtimeJar : runtimeJarList) {
23            //给 proguard 添加 runtime
24            libraryjars(runtimeJar)
25        }
26    }
27    libraryjars files(configurations.compile.collect())
28}
29
```

升级为3.2.0之后，`runtimeJarList = plugin.getBootClasspath()`行报错，gradle显示如下：

```shell
1* What went wrong:
2A problem occurred configuring project ':projectXXX'.
3> No signature of method: com.android.build.gradle.LibraryPlugin.getBootClasspath() is applicable for argument types: () values: []
```

错误提示很明显，也很简单，就是找不到这个方法，然而google到类似的问题很多，原因却各不相同。
经过多次尝试之后，发现旧版本的gradle运行时，`else if (android.getMetaClass().getMetaMethod("getBootClasspath"))`这块代码的返回值是`true`，执行的代码是`runtimeJarList = android.getBootClasspath()`，并不会知道`else`语句块里，所以不会报错。
那么问题很明确了，出问题的地方就在于`android.getMetaClass().getMetaMethod("getBootClasspath")`这块代码，在升级之后，返回值变了。

这一块找了好久，一直没找到准确的问题，也无从寻找解决方案。后来偶然使用如下代码自定义plugin调试时，发现代码无法编译通过。

```java
 1class DebuggerPlugin implements Plugin<Project> {
 2    void apply(Project project) {
 3        project.task("debugTask") {
 4            def hasApp = project.plugins.withType(AppPlugin)
 5            def hasLib = project.plugins.withType(LibraryPlugin)
 6
 7            Plugin plugin = null
 8            if (hasApp) {
 9                plugin = project.plugins.findPlugin(AppPlugin)
10            } else if (hasLib) {
11                plugin = project.plugins.findPlugin(LibraryPlugin)
12            }
13            println(plugin)
14            if (plugin != null) {
15                List<String> runtimeJarList
16                if (plugin.getMetaClass().getMetaMethod("getRuntimeJarList")) {
17                    runtimeJarList = plugin.getRuntimeJarList()
18                } else if (android.getMetaClass().getMetaMethod("getBootClasspath")) {
19                    runtimeJarList = project.android.getBootClasspath()
20                } else {
21                    runtimeJarList = plugin.getBootClasspath()
22                }
23                println("runtimeJar:"+runtimeJarList)
24
25            }
26        }
27    }
28}
```

报如下错误：

```shell
1* What went wrong:
2A problem occurred evaluating project ':scene-provider-android'.
3> Failed to apply plugin [class 'DebuggerPlugin']
4   > Could not get unknown property 'android' for task ':scene-provider-android:debugTask' of type org.gradle.api.DefaultTask.
```

多年的代码敏感一下子就让我找到了问题所在，在我的`build.gradle`明明是声明了`android.library`工程，有`android`对象存在的。而在Plugin类中，自定插件类是跟外在载体无直接关联，因此无法直接访问到`android`，或者说无法感知到`android`的存在。解决方案很简单，就是在`android`前面加上`project`对象访问。
即`android.getMetaClass().getMetaMethod("getBootClasspath")`修改为`project.android.getMetaClass().getMetaMethod("getBootClasspath")`，再次尝试，即编译通过。

* 注：该`project`对象为`apply(Project project)`的参数对象。
那我在混淆任务里，是不是也是这样呢？实践是检验真理的唯一标准。事实告诉我，是的。
那么问题来了，为什么混淆任务可以直接访问到`android`对象，但是返回值却跟以前不一样了呢？
我试了自定义一个任务，即`debugTask`里的代码，不放在plugin插件体里，而是直接放在`build.gradle`中，发现是可以找到`getBootClasspath`方法的，也能顺利拿到结果。我再回过头去看之前的代码，对比了下，区别在于，因为需要支持多渠道混淆任务，`task("proguard${nameCap}Jar")`是放在`android.libraryVariants.all { ...}`方法体里的。这意味着，在升级gradle之后，`libraryVariants`遍历的方法体里`android`和以前不一样了，即和`project.android`不一样了。通过打印`project.android`和`android`对象，得到了如下结果：

```java
1project android: com.android.build.gradle.LibraryExtension_Decorated@244296a5
2android: null
```

`android`对象居然为`null`了！！
说明在`android.libraryVaiants.all`遍历时，将不再能够直接访问`project.android`对象。那么为什么`android.getMetaClass()`调用的时候，不会报`java.lang.NullPointerException`呢？Groovy也是jvm系语言呀。

我感觉我打开了一个新世界的大门。

跟着好奇心，我打印了`android.getMetaClass()`和`null.getMetaClass()`，发现结果都是`org.codehaus.groovy.runtime.HandleMetaClass@1e11ea06[groovy.lang.MetaClassImpl@1e11ea06[class org.codehaus.groovy.runtime.NullObject]]`

你跟我一样都没有看错，并不会报`NPE`，也会有结果输出。
`Java`语言的`null`是一个关键字，在jvm中，`null`不是一个对象，不会有任何内存。而`Groovy`的`null`，其实是`org.codehaus.groovy.runtime.NullObject`的实例。

```java
1java.lang.Object
2    groovy.lang.GroovyObjectSupport
3        org.codehaus.groovy.runtime.NullObject
```

那么这一切也不奇怪了，`Groovy`的`null`，其实就是一个对象。它也有相对应的方法。具体可参考[](http://docs.groovy-lang.org/docs/groovy-2.3.2/html/api/org/codehaus/groovy/runtime/NullObject.html "")

扯得稍微有点远，回过头来。混淆任务的`libraryjars`是为了将外部引用的jar包路径引入，才能对类混淆时keep住对应的类。而本例的task任务是将`android.jar`引入，保证`Android SDK`相关类能够正确保留。通过对plugin对象的分析，这个值除了可以通过`project.android.getBootClasspath`拿到，还可以通过`project.extension.getBootClasspath`拿到，因为本例的`plugin.extension`即`LibraryExtension`对象，也能取到该值。
最终的结果如下：

```java
 1task("proguard${nameCap}Jar", type: ProGuardTask, dependsOn: ["make${nameCap}Jar"]) {
 2    group = 'jar'
 3    description = 'make proguard jar'
 4
 5    injars originalJarPath
 6    outjars proguardJarPath
 7    configuration 'proguard-rules.pro'
 8    configuration 'proguard-rules-remove-debug-log.pro'
 9    printmapping "${mappingFilePath}/mapping.txt"
10
11    println("called:" + nameCap)
12
13    Plugin plugin = getPlugins().hasPlugin(AppPlugin) ?
14            getPlugins().findPlugin(AppPlugin) :
15            getPlugins().findPlugin(LibraryPlugin)
16    if (plugin != null) {
17        List<String> runtimeJarList
18        if (project.android.getMetaClass().getMetaMethod("getBootClasspath")) {
19            runtimeJarList = project.android.getBootClasspath()
20        } else if (plugin.extension.getMetaClass().getMetaMethod("getBootClasspath")) {
21            runtimeJarList = plugin.extension.getBootClasspath()
22        } else if (plugin.getMetaClass().getMetaMethod("getRuntimeJarList")) {
23            runtimeJarList = plugin.getRuntimeJarList()
24        } else if (plugin.getMetaClass().getMetaMethod("getBootClasspath")) {
25            runtimeJarList = plugin.getBootClasspath()
26        }
27        if (runtimeJarList != null) {
28            for (String runtimeJar : runtimeJarList) {
29                //给 proguard 添加 runtime
30                libraryjars(runtimeJar)
31            }
32        }
33
34    }
35
36    libraryjars files(configurations.myImplementation.collect())
37}
38
```

不知道细心的你有没有发现，任务的最后一句也变了。
因为新版的Android Studio启用了新的gradle依赖机制，废弃了`compile`、`provided`等依赖机制，引入了`api`、`implementation`、`compileOnly`等。
具体此文不进行赘述。这个改变会影响我们混淆任务对于我们自有依赖库的引入。其实你依然可以通过`compile`取得使用了`compile`依赖的类库jar路径，但是如果是通过其他几种依赖的，就无法顺利找到了。当我们的依赖是使用`implementation`或者`api`依赖时，使用`configurations.implementation.collect()`会报错.

```java
1* What went wrong:
2A problem occurred evaluating project ':scene-provider-android'.
3> Resolving configuration 'implementation' directly is not allowed
```

解决办法是使用自定义编译配置。

```java
1configurations {
2    myImplementation.extendsFrom implementation
3}
```

* 注：因为配置采用的是继承关系，所以`myImplementation`可以找到所有使用`implementation`依赖的库，而`implementation`是通过继承`api`得来，所以我们只需要引用`configurations.myImplementation.collect`即可得到我们要的类库jar包路径。

# More

还有其他的一些tip没讲完，感觉这一篇篇幅已经很大了。看来要分好几章了，希望能够加快进度~