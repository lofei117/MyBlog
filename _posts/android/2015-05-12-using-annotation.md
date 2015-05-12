---
layout: post
title: "Using Annotation"
description: "Using Annotation in Android"
category: "android"
tags: ["Android"]
---
{% include JB/setup %}

# Foreword
`Annotation`(注解)是从Java 1.5开始新加的特性，距今已经好多年的历史了。不得不说注解是一个很好用的东西。不过本文不打算深入解释`Annotation`，而是准备从Android提供的`Annotation`来讲述其使用技巧。

# Why Annotation
在开发过程中，我们会遇到各种设计接口、方法时，需要对方法的参数进行限制，来避免或者尽量避免由于开发人员的错误调用而导致程序运行不正常乃至崩溃。
例如：我们常用的`TextView`的`setText`方法有多个重载实现，而我们常用的为:

```java
public final void setText(CharSequence text) {
    setText(text, mBufferType);
}

public final void setText(int resid) {
    setText(getContext().getResources().getText(resid));
}
```
这两个方法。当我们从网络流（或者其他一些场景下）获取到数据，直接调用`setText`方法，经常会出现传入错误的int类型值，这个int类型值并不是正确的`R.string.*`值，在程序运行的时候就会报错，导致程序崩溃（Force close)。

在没有注解的情况下，我们是很难做出判断，这些操作只能凭开发人员的细心判断达到。但是人往往是会犯错的，尤其是多人协作的时候，这种问题尤其容易出现。而在Annotation的帮助下，我们可以很好的实现控制，让编译器去协助我们完成检查，在编译时便检查出错误。

**注意：这个错误只能在视觉上呈现，实际编译仍能通过。**

# How to use Annotation
针对上述场景，Android的support-annotation包里提供了`StringRes`这个Annotation，在设置了`@StringRes`注解的参数`PARAMETER`, 使用非`R.string.*`类型的int值是，便会报错：
![Error](/assets/images/android/annotation_error.png "Annotation Error")

**注：本文的IDE为Android Studio, 并未测试Eclipse上的显示和提示.**

查看`StringRes`的源码实现如下：

```java
/**
 * Denotes that an integer parameter, field or method return value is expected
 * to be a String resource reference (e.g. {@link android.R.string#ok}).
 */
@Documented
@Retention(SOURCE)
@Target({METHOD, PARAMETER, FIELD})
public @interface StringRes {
}

```

我们查看TextView的对应方法代码看到如下情况：
![Hint](/assets/images/android/annotation_hint.png "Annotation Hint")

我们注意到并没有在方法的参数里标记`@StringRes`，只是在左边有一个@标识，鼠标悬停后有上图的显示其使用了外部的Annotation，具体的情况目前并未深入分析，此处挖个坑。

**注意：** Android提供了`android.support.annotation.StringRes`和`android.annotation.StringRes`, 后者是`@hide`的，也就是说只能在系统app中使用。

# How to use Annotation
说了这么多，是时候该操刀上了。使用起来很简单：

```java
private void testStringRes(@StringRes int id) {
    ...
}
```

然后在使用的时候直接调用该方法，如果有不符合的参数传入，编译器便会给出错误提示。
![Use](/assets/images/android/annotation_use.png "Annotation Use")

# More Annotations
除了上述提到的`StringRes`这个Annotation外，`android.support.annotation`包下还有其余24个annotation，主要分为一下几类：

* 1：和`StringRes`一样的`*Res`注解；
* 2：`NonNull`和`Nullable`;
* 3：`IntDef`和`StringDef`;

`NonNull`和`Nullable`相对比较简单，也是和上述的`StringRes`一样使用，不过区别是这两者在IDE中是以Warning(警告)形式出现，而`StringRes`是以Error(错误)形式出现。

**注意： 上述的Error并不是真正意义上的Error，只是在IDE中会显示红色标记，而Warning只会显示一个不显眼的背景高亮。 而且在编译的时候都能通过编译并运行。**

![Warning](/assets/images/android/annotation_warning.png "Annotation Warning")

`IntDef`和`StringDef`允许我们自定义新的注解类型，从而达到实现参数类型控制的目的，其达到的效果和枚举`Enum`类似。
具体可参考`android.app.ActionBar`类的相关实现：

```java
@Retention(RetentionPolicy.SOURCE)
@IntDef({NAVIGATION_MODE_STANDARD, NAVIGATION_MODE_LIST, NAVIGATION_MODE_TABS})
public @interface NavigationMode {}


/**
 * Set the current navigation mode.
 *
 * @param mode The new mode to set.
 * @see #NAVIGATION_MODE_STANDARD
 * @see #NAVIGATION_MODE_LIST
 * @see #NAVIGATION_MODE_TABS
 *
 * @deprecated Action bar navigation modes are deprecated and not supported by inline
 * toolbar action bars. Consider using other
 * <a href="http://developer.android.com/design/patterns/navigation.html">common
 * navigation patterns</a> instead.
 */
public abstract void setNavigationMode(@NavigationMode int mode);
```

# 其他
关于Annotation的实现原理以及自定义Annotation，留待下次讲解吧。

