---
layout: post
title: "build variants on android studio"
description: "build types and flavors on android studio"
category: "android"
tags: ["android"]
---
{% include JB/setup %}

# Foreword
Android studio作为google官方推荐的Android开发IDE，的确是一个很棒的开发工具，虽然它曾经那么难用不堪，不过成长下来，已然能够完全取代eclipse成为Android程序员们最应该使用的开发工具。Gradle工程对于打包环境配置能够让你从冗余的xml配置中解放出来，在这里我讲介绍一下Android Studio的gradle中的build variant相关的一些小知识。

Android的build variant主要由build types和product flavors做笛卡尔乘积得到的集合(**主要**的意思是还会有其他一些比如针对cpu架构的，在此不做详细介绍）. 

# Build types	
Android Studio默认有两个build type类型，`release`和`debug`，以下是他们之间的一些区别：

* 1: 在`debug`类型中，`debuggable`被默认置为`true`, 而在`release`中默认是`false`, 该值在生成项目（build project）时，会和`BuildConfig.DEBUG`字段对应，通过它我们可以做一些逻辑处理。
* 2: `debug`类型默认使用debug签名，而在`release`中，你必须手动指定一个签名。更多关于签名的信息，请点击[这里](http://developer.android.com/tools/publishing/app-signing.html "Android signing")

我们还可以添加自定义的build type，需要注意的是其名字不能和渠道名（product flavor)相同。在自定义的build type中，我们需要根据自己的需求设置对应的属性。例如

```
manifestPlaceholders = [INSTALLED_CHANNEL: "default_channel"]
debuggable true
versionNameSuffix  ".alpha"
// 开启混淆
minifyEnabled true
zipAlignEnabled true
// 移除无用的资源文件
shrinkResources true
proguardFiles 'proguard-rules.pro'
// 签名设置
signingConfig signingConfigs.release
```

等等，以及其他一些属性。

在第一点我们提到可以通过`BuildConfig.DEBUG`来在java代码中写一些逻辑，比如我们要在开发过程中输出程序调试日志，而在正式发布的包里面把这些日志去掉。我们可以这么做：

```java
if(BuildConfig.DEBUG) {
	Log.d("Test", "hello, this is a debug log");
}
```
因为`BuildConfig.DEBUG`为Android Studio编译项目时生成的自动生成的java类，查看其声明我们发现其是一个`static final`字段。编译器在编译时，会帮助我们把`if`语句中条件永远为`false`的语句去掉，不编译为二进制文件，因此在最终的发布包中，我们就看不到这些调试日志了。

这是一个最简单的使用`BuildConfig.DEBUG`的示例，关于更深入的使用`BuildConfig.DEBUG`来编写程序逻辑，在下面介绍完渠道（Product Flavors）后详细介绍。0

# Product Flavors
通过Product Flavors可以配置多渠道信息，针对不同的渠道，我们可以给程序添加不同的版本标识以及逻辑代码。

添加渠道很简单，只要在对应的module下面的`build.gradle`的`android`块中添加`productFlavors`代码块即可，如下所示：

```
android {
	
	...

	productFlavors {
		free{}
		pro{}
		...
	}

	...
}
```

如上所示，一共添加了三个渠道，`free`, `pro`, 添加完后，点击菜单栏的*Build*->*Make Project*（或者*Rebuild Project*）重新生成项目即可。如果在此之前，我们的项目是一个正确的Gradle工程，在修改了`build.gradle`文件之后，Android Studio会提醒我们同步项目（Sync Project）， 点击*Sync Now*，则相当于重新生成了项目。

在项目构建完成之后，我们可以点击Android Studio左侧的*Build Variants*标签页，我们可以看到我们项目中的Module信息，每个Module后面都显示了其当前选中的`Build Variant`，我们在直接运行代码时，编译的正是该`variant`.

在这里我们也可以看到如上述所说的，每个`Build Variant`都是`Build Types`和`Product Flavors`的笛卡尔乘积的其中一个元素。

# 更复杂的逻辑配置
我们可以给每个不同的`Product Flavors`指定不同的包名、版本号和版本名, `Build Type`可以指定不同的或者版本名后缀名，这些都只是简单的表层配置，更复杂的配置则是为他们分配不同的代码，上面提到的`BuildConfig.DEBUG`便是其中一种。

一般情况下，我们设置根据不同场景调用不同的逻辑时，会在代码中根据动态的结果来调用不同的逻辑，即`if`语句中的代码是动态的，与`BuildConfig.DEBUG`不同的是，`BuildConfig.DEBUG`（以及所有`if`等语句中逻辑永远为`false`）判断的代码在编译时会直接移除。除此之外，如果要根据不同的渠道实现不同的逻辑，我们还可以在`src`目录下创建与渠道名同名的文件夹，该文件夹与`src/main`处于同级目录，`src/main`的代码为程序主要代码，该文件夹下主要由`java`, `res`, `assets`等文件夹以及`AndroidManifest.xml`文件，区别是渠道文件夹下的这些文件，可以覆盖或补充`src/main`文件夹下的代码，组成一套完整的代码。

这部分代码比较复杂，在此不详细介绍了，可以点击文章最后的demo链接下载代码查看。

# 更多的小技巧

* 1：除了`debuggale`生成的`DEBUG`变量之外，`BuildConfig`类中还会有`VERSION_CODE`, `VERSION_NAME`, `APPLICATION_ID`等一系列常量，除此之外，我们还可以自定义一些变量来区分各个渠道，只需要在具体的渠道或者编译类型子块中加入如下代码：

```
buildConfigField "boolean", "IS_FREE", "true"
```
其中第一个字段是java数据基础类型，第二个是字段名，第三个是值。当值与基础类型不对应时，生成的BuildConfig会有错误，便无法生成项目。

我们可以配置多个类似的预编译值（如果确实有需要），然后在`src/main`中使用。

* 2：当我们有多个渠道，而其中两个或者多个渠道要使用不同的java代码，其余几个渠道代码与某个渠道代码相同时，我们无法在`src/main`中放置这些Java类，因为会有类重复冲突（duplicated error），如果在每个渠道的文件夹下都放置同样的java代码，难以维护，而且会造成困惑。
我们可以通过如下方法来达到我们的目的：

```

android {

	productFlavors {
        flavorA {}
        flavorB {}
        flavorC {}
        flavorD {}
		...
    }

	productFlavors.all { flavor ->
        if (name.equals("flavorA")) {
            // do something for flavorA
            // Note: we do not set the sourceSets for flavorA here, you should put the source code in `src/flavorA/java`, gradle would do the work for us.
        } else {
            // set the sourceSets for other flavors
            initSourceSets(flavor.name)
        }
    }
    
}
    

def initSourceSets(flavorName) {
    android.sourceSets.findAll { source ->
        source.name.equals(flavorName)
    }.each { source ->
    	// set the sourceSets as flavorB
        source.setRoot('src/flavorB')
    }
}
```

# 最后的最后
关于gradle配置还有很多具体的细节，我也在不断的探索中，常总结常思考，才能常进步，加油~~~










