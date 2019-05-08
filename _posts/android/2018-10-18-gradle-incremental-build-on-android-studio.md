---
layout: post
title: "Gradle incremental build on Android Studio"
description: "浅谈gradle增量构建"
category: "android"
tags: ['android', 'gradle']
---
{% include JB/setup %}


> 最近在折腾Android Studio打包优化，其中有些地方使用了gradle的incremental build增量构建。不是特别顺利，因此想把相关心得记录下来，当做一个笔记。

# 0x0 前言
谈起增量编译，Android开发者一定都不陌生。自从谷歌官方开始停止eclipse插件ADT开发和维护之后，相信大家都已经转战到Android Studio上来了。当我们自己使用Android Studio编译运行apk的时候，经常可以看到gradle console里打印的`:xxxxx:build UP-TO-DATE`，这个便是增量构建。增量构建可以跳过很多不必要的重复编译构建，为我们节省下大量的时间。   
而在开发Android程序的时候，我们经常会遇到，需要使用gradle task手动编写一些gradle脚本，来辅助打包，或者做一些资源处理。 当然，也有很多task是继承gradle原生的task来实现的。gradle的大部分task，已经默认支持增量构建，无需我们作任何处理。这里讲介绍如何编写一个自定义的task，使其能够支持增量构建。

# 0x1 需求
这里我们举一个简单的例子，我们有若干个资源文件：`a.txt, b.txt, c.txt....`，存放在`app/data/`下面，这些文件中都有一个`version=@@VERSION_CODE@@`的内容。我们希望每次构建的时候，能够自动将版本号统一修改，放到`assets`目录下去。

# 0x2 实现
首先我们创建一个自定义任务，让打包任务依赖于其执行：

```java
task processAssets {
    ...
}
tasks.assemble.dependensOn processAssets
```
这个例子，其实可以用继承`Copy`来实现。我们可以如下实现
```java
def version = "1000"

task processAssets(type: Copy) {
    group "custom"

    println("processAssets")

    from("data") {
        include "*.txt"
        filter { it.replaceAll('@@VERSION_CODE@@', version) }
    }
    into("src/main/assets")
}
tasks.assemble.dependsOn(processAssets)
```
连着运行的时候，结果是这样的：
```ruby
➜  DebugDemo ./gradlew processAssets
Parallel execution is an incubating feature.

> Configure project :app 
processAssets

> Configure project :plugin 
publishNonDefault is deprecated and has no effect anymore. All variants are now published.


BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
➜  DebugDemo 
➜  DebugDemo 
➜  DebugDemo ./gradlew processAssets
Parallel execution is an incubating feature.

> Configure project :app 
processAssets

> Configure project :plugin 
publishNonDefault is deprecated and has no effect anymore. All variants are now published.


BUILD SUCCESSFUL in 1s
1 actionable task: 1 up-to-date
```
可以看到，第二次运行之后，结果后面多了一个`up-to-date`字样，意味着第二次执行，gradle判断输入输出没有改变，因此不需要执行任务。

# 0x3 原理
我们把生成的文件移除，然后使用`./gradlew processAssets --info`来查看详情，可以看到如下内容：
```ruby
All projects evaluated.
Selected primary task 'processAssets' from project :
Tasks to be executed: [task ':app:processAssets']
Creating new cache for resourceHashesCache, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/fileHashes/resourceHashesCache.bin, access org.gradle.cache.internal.DefaultCacheAccess@28410804
Creating new cache for taskHistory, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/taskHistory/taskHistory.bin, access org.gradle.cache.internal.DefaultCacheAccess@5493c334
Creating new cache for outputFiles, path /Users/lofei/Downloads/DebugDemo/.gradle/buildOutputCleanup/outputFiles.bin, access org.gradle.cache.internal.DefaultCacheAccess@4ed167b4
:app:processAssets (Thread[Task worker for ':',5,main]) started.

> Task :app:processAssets 
Putting task artifact state for task ':app:processAssets' into context took 0.001 secs.
Up-to-date check for task ':app:processAssets' took 0.001 secs. It is not up-to-date because:
  Output property 'destinationDir' file /Users/lofei/Downloads/DebugDemo/app/src/main/assets/c.txt has been removed.
  Output property 'destinationDir' file /Users/lofei/Downloads/DebugDemo/app/src/main/assets/b.txt has been removed.
  Output property 'destinationDir' file /Users/lofei/Downloads/DebugDemo/app/src/main/assets/a.txt has been removed.

:app:processAssets (Thread[Task worker for ':',5,main]) completed. Took 0.018 secs.

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
➜  DebugDemo 
```
可以知道其实gradle是通过文件快照缓存来实现相关检查的。快照保存在项目目录的`.gradle`目录下的相关文件里。我们可以注意到，相关路径带有gradle版本号信息，这意味着，不同版本的gradle的快照缓存不通用，及无法跨gradle版本实现增量构建。
另外我们可以注意到，`Up-to-date check`里，检测的输出属性是`destinationDir`发生了改变，导致此次构建需要重新执行。
那如果我修改了文件内容呢？
```ruby
All projects evaluated.
Selected primary task 'processAssets' from project :
Tasks to be executed: [task ':app:processAssets']
Creating new cache for resourceHashesCache, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/fileHashes/resourceHashesCache.bin, access org.gradle.cache.internal.DefaultCacheAccess@104e1166
Creating new cache for taskHistory, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/taskHistory/taskHistory.bin, access org.gradle.cache.internal.DefaultCacheAccess@5a17beb7
Creating new cache for outputFiles, path /Users/lofei/Downloads/DebugDemo/.gradle/buildOutputCleanup/outputFiles.bin, access org.gradle.cache.internal.DefaultCacheAccess@5de7bb1
:app:processAssets (Thread[Task worker for ':',5,main]) started.

> Task :app:processAssets 
Putting task artifact state for task ':app:processAssets' into context took 0.0 secs.
Up-to-date check for task ':app:processAssets' took 0.005 secs. It is not up-to-date because:
  Input property 'rootSpec$1$1' file /Users/lofei/Downloads/DebugDemo/app/data/b.txt has changed.

:app:processAssets (Thread[Task worker for ':',5,main]) completed. Took 0.016 secs.

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
➜  DebugDemo 
```
可以看到，本次的`Up-to-date check`里，引起增量构建的原因是我修改了`b.txt`里的内容。对应的修改属性是`rootSpec$1$1`.
上面提到的`destinationDir`和`rootSpec`都是`Copy`这个任务所拥有的属性。如果是其他的原生任务，相关属性也不尽相同。
但是只要是继承了`Task`任务下来的任何任务，有一个输入属性`inputs`和一个输出属性`outputs`，是一定存在的。也就是说，如果我们只是普普通通的一个task，只要设置好了`inputs`属性和`outputs`属性，我们就可以迅速实现增量构建功能。

# 0x4 运用
我们现在不使用`Copy`任务来实现需求，我们改成使用`shell`脚本来辅助完成**修改内容拷贝**任务。那么就变成了这个样子：
* shell代码
```shell
#!/bin/sh

echo "sed 's/@@VERSION_CODE@@/$1/g' $2 > $3"
sed s/@@VERSION_CODE@@/$1/g $2 > $3
```

* task代码
```java
task processAssetsByShell {
    group "custom"

    inputs.dir "${project.projectDir.toString()}/data"
    outputs.dir "${project.projectDir.toString()}/src/main/assets"

    doLast {
        FileTree tree = fileTree("${project.projectDir.toString()}/data").include('*.txt')
        tree.each { file ->
            println(file.path)
            exec {
                workingDir "${project.projectDir.toString()}"
                commandLine 'sh', 'shell/processSingle.sh', version, file.absolutePath, "src/main/assets/${file.name}"
            }
        }
    }
}
```
我们运行试一下：
```ruby
➜  DebugDemo ./gradlew processAssetsByShell        
Parallel execution is an incubating feature.

> Configure project :app 
processAssets

> Configure project :plugin 
publishNonDefault is deprecated and has no effect anymore. All variants are now published.

> Task :app:processAssetsByShell 
/Users/lofei/Downloads/DebugDemo/app/data/c.txt
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/c.txt > src/main/assets/c.txt
/Users/lofei/Downloads/DebugDemo/app/data/b.txt
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/b.txt > src/main/assets/b.txt
/Users/lofei/Downloads/DebugDemo/app/data/a.txt
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/a.txt > src/main/assets/a.txt


BUILD SUCCESSFUL in 2s
1 actionable task: 1 executed
➜  DebugDemo echo "new content" >> app/data/a.txt 
➜  DebugDemo ./gradlew processAssetsByShell --info
...

> Task :app:processAssetsByShell 
Putting task artifact state for task ':app:processAssetsByShell' into context took 0.0 secs.
Up-to-date check for task ':app:processAssetsByShell' took 0.003 secs. It is not up-to-date because:
  Input property '$1' file /Users/lofei/Downloads/DebugDemo/app/data/a.txt has changed.
/Users/lofei/Downloads/DebugDemo/app/data/c.txt
Starting process 'command 'sh''. Working directory: /Users/lofei/Downloads/DebugDemo/app Command: sh shell/processSingle.sh 1000 /Users/lofei/Downloads/DebugDemo/app/data/c.txt src/main/assets/c.txt
Successfully started process 'command 'sh''
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/c.txt > src/main/assets/c.txt
/Users/lofei/Downloads/DebugDemo/app/data/b.txt
Starting process 'command 'sh''. Working directory: /Users/lofei/Downloads/DebugDemo/app Command: sh shell/processSingle.sh 1000 /Users/lofei/Downloads/DebugDemo/app/data/b.txt src/main/assets/b.txt
Successfully started process 'command 'sh''
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/b.txt > src/main/assets/b.txt
/Users/lofei/Downloads/DebugDemo/app/data/a.txt
Starting process 'command 'sh''. Working directory: /Users/lofei/Downloads/DebugDemo/app Command: sh shell/processSingle.sh 1000 /Users/lofei/Downloads/DebugDemo/app/data/a.txt src/main/assets/a.txt
Successfully started process 'command 'sh''
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/a.txt > src/main/assets/a.txt

:app:processAssetsByShell (Thread[Task worker for ':',5,main]) completed. Took 0.069 secs.

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
➜  DebugDemo 
```
我们可以发现，`up-to-date`功能已经生效。但是我们还发现，我只是修改了`a.txt`这个文件，所有的文件都重新生成了一遍，这显然不符合我们增量构建需求的。那么问题出在了哪里呢？
答案很简单，因为任务`up-to-date`检测认为需要重新构建，所以需要执行任务，触发了`doLast`里的逻辑（本例的实现机制，如果直接放在`task`里，即使不需要增量构建，也会执行任务）。
而`doLast`里的内容，是遍历所有文件去调用`shell`完成操作，即只要触发了增量构建，就会遍历一遍。
找到了问题之后，我们再次修改，我们需要知道***哪个文件***发生了改变，来针对其做重新构建。
那么，怎么才能知道***哪个文件***发生了改变呢？

# 0x5 IncrementalTaskInputs
`IncrementalTaskInputs`里面包含了更详细丰富的信息，主要如下：
```java
IncrementalTaskInputs.outOfDate(org.gradle.api.Action)
IncrementalTaskInputs.removed(org.gradle.api.Action)
```
顾名思义，我们可以知道`outOfDate`即文件发生了改变（包括新增），`removed`即原有的文件被删除。
参考 [https://docs.gradle.org/current/userguide/custom_tasks.html#incremental_tasks](https://docs.gradle.org/current/userguide/custom_tasks.html#incremental_tasks "Incremental tasks") 我们可以很快写出符合我们需求的自定义`task`。

```java

task processAssetsByShell2(type: ProcessAssetsTask) {
    inputDir file("${project.projectDir.toString()}/data")
    outputDir file("${project.projectDir.toString()}/src/main/assets")
    inputVersion version
}

class ProcessAssetsTask extends DefaultTask {
    @InputDirectory
    File inputDir

    @OutputDirectory
    File outputDir

    @Input
    String inputVersion

    @TaskAction
    void execute(IncrementalTaskInputs inputs) {
        if (!inputs.incremental)
            project.delete(outputDir.listFiles())

        inputs.outOfDate { change ->
            project.exec {
                workingDir "${project.projectDir.toString()}"
                commandLine 'sh', 'shell/processSingle.sh', inputVersion, change.file.absolutePath, "src/main/assets/${change.file.name}"
            }
        }

        inputs.removed { change ->
            def targetFile = project.file("$outputDir/${change.file.name}")
            if (targetFile.exists()) {
                targetFile.delete()
            }
        }
    }
}
```
运行结果如下：
```ruby
➜  DebugDemo ./gradlew processAssetsByShell2
Parallel execution is an incubating feature.

> Configure project :app 
processAssets

> Configure project :plugin 
publishNonDefault is deprecated and has no effect anymore. All variants are now published.

> Task :app:processAssetsByShell2 
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/c.txt > src/main/assets/c.txt
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/b.txt > src/main/assets/b.txt
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/a.txt > src/main/assets/a.txt


BUILD SUCCESSFUL in 2s
1 actionable task: 1 executed
➜  DebugDemo ./gradlew processAssetsByShell2
Parallel execution is an incubating feature.

> Configure project :app 
processAssets

> Configure project :plugin 
publishNonDefault is deprecated and has no effect anymore. All variants are now published.


BUILD SUCCESSFUL in 1s
1 actionable task: 1 up-to-date
➜  DebugDemo 
➜  DebugDemo echo "add some string" >> app/data/a.txt
➜  DebugDemo ./gradlew processAssetsByShell2 --info  
...
All projects evaluated.
Selected primary task 'processAssetsByShell2' from project :
Tasks to be executed: [task ':app:processAssetsByShell2']
Creating new cache for resourceHashesCache, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/fileHashes/resourceHashesCache.bin, access org.gradle.cache.internal.DefaultCacheAccess@64fe529a
Creating new cache for taskHistory, path /Users/lofei/Downloads/DebugDemo/.gradle/4.4/taskHistory/taskHistory.bin, access org.gradle.cache.internal.DefaultCacheAccess@3b585e47
Creating new cache for outputFiles, path /Users/lofei/Downloads/DebugDemo/.gradle/buildOutputCleanup/outputFiles.bin, access org.gradle.cache.internal.DefaultCacheAccess@4ac18438
:app:processAssetsByShell2 (Thread[Task worker for ':',5,main]) started.

> Task :app:processAssetsByShell2 
Putting task artifact state for task ':app:processAssetsByShell2' into context took 0.0 secs.
Up-to-date check for task ':app:processAssetsByShell2' took 0.001 secs. It is not up-to-date because:
  Input property 'inputDir' file /Users/lofei/Downloads/DebugDemo/app/data/a.txt has changed.
Starting process 'command 'sh''. Working directory: /Users/lofei/Downloads/DebugDemo/app Command: sh shell/processSingle.sh 1000 /Users/lofei/Downloads/DebugDemo/app/data/a.txt src/main/assets/a.txt
Successfully started process 'command 'sh''
sed 's/@@VERSION_CODE@@/1000/g' /Users/lofei/Downloads/DebugDemo/app/data/a.txt > src/main/assets/a.txt

:app:processAssetsByShell2 (Thread[Task worker for ':',5,main]) completed. Took 0.031 secs.

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
➜  DebugDemo 
```
搞定！撒花！我们发现终于满足了我们的需求。

# 0x6 总结
通过修改默认任务的`inputs`和`outputs`属性，或者自定义`task`的相关输入输出属性，我们就可以像原生的`task`一样支持增量编译构建了。比如你的输入输出包含了其他信息，例如构建时间、版本参数等。可以使用其他的注解来辅助。
怎么样，快来试试吧~

* 注1：其实上面的版本并没有达到我们真正的目的，因为我们监听的是`outputDir`，比如当`outputDir`目录的`a.txt`有修改时，会认为所有的文件都发生改变。阅读了gradle官方文档之后，发现设计并不支持此功能，有些遗憾。
> However, there are many cases where Gradle is unable to determine which input files need to be reprocessed. Examples include:

> * There is no history available from a previous execution.
* You are building with a different version of Gradle. Currently, Gradle does not use task history from a different version.
* An upToDateWhen criteria added to the task returns false.
* An input property has changed since the previous execution.
* One or more output files have changed since the previous execution.

> In any of these cases, Gradle will consider all of the input files to be outOfDate. 

* 注2：建议阅读以下参考资料，获取更全面的介绍。（虽然有时候官方文档也有点说不清道不明。）

# 0x7 参考资料
* [https://docs.gradle.org/current/userguide/custom_tasks.html#incremental_tasks](https://docs.gradle.org/current/userguide/custom_tasks.html#incremental_tasks "Incremental tasks") 
* [https://docs.gradle.org/current/userguide/more_about_tasks.html#sec:up_to_date_checks](https://docs.gradle.org/current/userguide/more_about_tasks.html#sec:up_to_date_checks "Up-to-date checks (AKA Incremental Build)") 