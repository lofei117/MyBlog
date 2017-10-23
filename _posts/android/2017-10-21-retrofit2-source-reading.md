---
layout: post
title: "Retrofit 2.0 源码阅读解析"
description: "Retrofit 2.0 源码阅读解析"
category: "android"
tags: [android, java]
---
{% include JB/setup %}

# 前言
Retrofit是服务于Java/Android的网络请求框架，之前已经在很多项目中使用该框架来进行网络请求，然而一直没有深入去阅读它的源码，近期大致翻看了一下，在这里作一个简单的总结。

Retrofit主要实现了如下功能：
> 1. 按照`Restful`协议实现框架；
> 2. 根据注解配置访问方法、路径及参数，使代码具有更高的可读性；
> 3. 使用接口访问网络接口，完全无需关心内部实现;
> 4. 抽象和实现解耦，通过自定义接口转化器和数据格式转化器，来实现自定义配置;

# 准备工作
第一步：准备一杯咖啡或者一杯茶，然后可以适当准备纸笔用来记录（也可以直接在电脑上用文档记录）

第二步：开始从github上下载Retrofit的源码，地址如下：`https://github.com/square/retrofit`.

第三步：使用任何自己喜欢的IDE或者文本编辑器打开，我用的是Sublime Text.

# 开始分析源码
下载完源码之后，我们发现整个目录下有若干个子目录及文件：
      
>  \|- retrofit     
   &nbsp;&nbsp;&nbsp;&nbsp;\|- retrofit       
   &nbsp;&nbsp;&nbsp;&nbsp;\|- retrofit-adapters   
   &nbsp;&nbsp;&nbsp;&nbsp;\|- retrofit-converters   
   &nbsp;&nbsp;&nbsp;&nbsp;\|- retrofit-mock   
   &nbsp;&nbsp;&nbsp;&nbsp;\|- samples   
   &nbsp;&nbsp;&nbsp;&nbsp;\|- website   
   &nbsp;&nbsp;&nbsp;&nbsp;\|- other files...   

其中，`retrofit`目录下为整个框架的基础代码；`retrofit-adapters`目录下为接口适配器代码，它的作用是实现将实际网络实现接口，转化为你编写的应用接口（例如`Java8`语法、`RxJava`接口等）；`retrofit-converters`是数据格式转化器，负责将网络流数据转化为你想要的目标格式（`Protobuf`、`Gson`等）；`retrofit-mock`则是一个虚拟Web Server，用来进行虚拟网络访问测试；`samples`顾名思义，是例子代码；`websites`则是用来部署在github io上的静态网站代码；其余文件这里不过多赘述。

下面将根据retrofit官网`GitHubService`的`listRepos`例子来一步步深入解读源码：

```java
// Create Java API
public interface GitHubService {
  @GET("users/{user}/repos")
  Call<List<Repo>> listRepos(@Path("user") String user);
}

// Use Retrofit to create API instance.
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl("https://api.github.com/")
    .build();

GitHubService service = retrofit.create(GitHubService.class);

// Call the methods to accomplish http requests
Call<List<Repo>> repos = service.listRepos("octocat");
```

## Retrofit.Builder\#build
`Builder`模式是最常见的一种创建型模式，主要作用是通过链式调用完成参数配置，最后通过`build`方法返回需要创建的实例对象，关于该模式这里不过多赘述，这里我们主要看一下对应的`build`方法。
源码如下：

```java
public Retrofit build() {
  if (baseUrl == null) {
    throw new IllegalStateException("Base URL required.");
  }

  okhttp3.Call.Factory callFactory = this.callFactory;
  if (callFactory == null) {
    callFactory = new OkHttpClient();
  }

  Executor callbackExecutor = this.callbackExecutor;
  if (callbackExecutor == null) {
    callbackExecutor = platform.defaultCallbackExecutor();
  }

  // Make a defensive copy of the adapters and add the default Call adapter.
  List<CallAdapter.Factory> adapterFactories = new ArrayList<>(this.adapterFactories);
  adapterFactories.add(platform.defaultCallAdapterFactory(callbackExecutor));

  // Make a defensive copy of the converters.
  List<Converter.Factory> converterFactories =
      new ArrayList<>(1 + this.converterFactories.size());

  // Add the built-in converter factory first. This prevents overriding its behavior but also
  // ensures correct behavior when using converters that consume all types.
  converterFactories.add(new BuiltInConverters());
  converterFactories.addAll(this.converterFactories);

  return new Retrofit(callFactory, baseUrl, converterFactories, adapterFactories,
      callbackExecutor, validateEagerly);
}
```

通过源码我们可以发现，Retrofit默认使用`OkHttpClient`来完成网络访问，同时也配置了默认的接口适配器和数据格式转换器，但是`baseUrl`必须由外部提供，否则直接抛出`IllegalStateException`异常。
这里需要关注的一个点是`Platform`, 默认情况下，构造函数通过`Platform.get()`来获取当前的平台。
通过阅读`Platform`源码我们发现，`Platform`包含了`Java8`、`Android`和一个默认的`Platform`，而通过Retrofit的官方介绍我们可以知道，Retrofit目前仅支持`Java`和`Android`两种平台，其中`Java`支持`Java7`和`Java8`，Android支持`Android 2.3`及以上。

在`Android`类型的`Platform`中，`defaultCallbackExecutor`是一个`MainThreadExecutor`，顾名思义，默认的回调方法是在`MainThread`，即UI线程中执行的。同时，根据`callbackExecutor`也配置了一个默认的`defaultCallAdapterFactory`，实现类是`ExecutorCallAdapterFactory`，关于它们的具体作用，后文将进行详细介绍。

## Retrofit\#create
通过`Builder`构建出`Retrofit`实例之后，就可以调用`Retrofit#create()`创建出我们定义的接口实例，在上述例子中，即`GitHubService`实例，那么，它是怎么实现的呢？

```java
public <T> T create(final Class<T> service) {
  Utils.validateServiceInterface(service);
  if (validateEagerly) {
    eagerlyValidateMethods(service);
  }
  return (T) Proxy.newProxyInstance(service.getClassLoader(), new Class<?>[] { service },
      new InvocationHandler() {
        private final Platform platform = Platform.get();

        @Override public Object invoke(Object proxy, Method method, @Nullable Object[] args)
            throws Throwable {
          // If the method is a method from Object then defer to normal invocation.
          if (method.getDeclaringClass() == Object.class) {
            return method.invoke(this, args);
          }
          if (platform.isDefaultMethod(method)) {
            return platform.invokeDefaultMethod(method, service, proxy, args);
          }
          ServiceMethod<Object, Object> serviceMethod =
              (ServiceMethod<Object, Object>) loadServiceMethod(method);
          OkHttpCall<Object> okHttpCall = new OkHttpCall<>(serviceMethod, args);
          return serviceMethod.callAdapter.adapt(okHttpCall);
        }
      });
}
```

我们可以一目了然地看出，`create`方法使用了泛型，通过泛型来返回指定的实例，在`return`方法之前，都是针对接口做的一些验证，真正的Magic发生在`return`后面的代码中。我们定义的`GitHubService`是一个接口类，而接口类要实现操作，就必须实现里面的接口方法，否则就无法正常使用。

Retrofit使用了代理模式（Proxy Pattern），利用Java的`Proxy#newProxyInstance`动态代理来实现接口方法逻辑。代理模式被广泛应用于AOP设计，关于代理模式，这里不展开详细赘述，大家可以自行查看相关资料。
如果你并不想马上了解代理模式，可以这么理解，通过代理模式，所有你定义的接口方法，比如`GitHubService`里的所有方法，当你调用它们时，都会触发上面的`invoke`方法，`invoke`方法有三个参数：`Object proxy`, `Method method`, `Object[] args`. 第一个参数`proxy`即代理的实例，一般情况下我们不需要使用，第二个参数`method`是方法的实例，熟悉Java反射调用的同学应该非常熟悉，第三个参数`args`顾名思义是参数数组，可以为空。

比如我们例子中的

```java
Call<List<Repo>> repos = service.listRepos("octocat");
```

在调用`listRepos`方法时，实际是触发`invoke`方法，传入的参数`method`即`listRepos`的`Method`方法对象，`args`即包含了`octocat`字符串对象的对象数组。

在`invoke`方法中，第一个`if`判断是针对仅在`Object`类声明的基础方法进行调用，比如并没有自定义实现的`toString`、`hashCode`等方法（在Java8之前，接口不允许自己实现方法），而在Java8之中，允许接口声明自己的`default`类型方法，因而有了第二个`if`判断。除此之外就是我们真正定义的接口方法了。

```java
ServiceMethod<Object, Object> serviceMethod =
                (ServiceMethod<Object, Object>) loadServiceMethod(method);
```

这句代码中，根据传入的`method`对象，去查找对应的`serviceMethod`对象，在`loadServiceMethod`方法中，代码逻辑也很简单，查找缓存是否已经存在对应的`serviceMethod`，有的话直接返回，没有则创建一个新的`ServiceMethod`对象，并加入缓存。
查找到对应的`serviceMethod`实例后，将根据该对象以及参数`args`创建一个`OkHttpCall`对象。`OkHttpCall`类是实现了`retrofit2.Call<T>`的类，在Retrofit中，它是一个`final`类，无法继承。
这里其实使用了一个简单的`Bridge`模式，将抽象和实现的独立变化分离，抽象即`OkHttpCall`，实现是我们之前通过`Builder`对象创建的`callFactory`，默认的`OkHttpClient`即其中一个实现。为什么说是一个简单的`Bridge`模式呢？因为它只有一个`OkHttpCall`本身，并没有其他的抽象化实现。在`OkHttpClient`中持有一个`okhttp3.Call rawCall`对象，通过`rawCall`对象来完成真正的网络请求。具体将在后文分析`OkHttpCall`源码时深入讲解。

```java
return serviceMethod.callAdapter.adapt(okHttpCall);
```

这是`invoke`方法的最后一句，真正的接口转换，其实是在这里的`adapt`方法调用之后触发的。`serviceMethod`的`callAdapter`成员变量，即我们通过`Builder`配置的`AdapterFactory`创建的`CallAdapter`对象。在本例中没有进行特殊配置，因此它即是我们上面提到的`ExecutorCallAdapterFactory`创建的`CallAdapter`. 通过`callAdapter`的`adapt`方法，实现了将`retrofit.Call<R>`到自定义的返回类型`T`的转换。很明显的`Adapter`适配器模式。

我们在之前提过，我们可以在`Builder`中自定义`AdapterFactory`，而`retrofit-adapters`目录下，即是`retrofit`已经为我们封装实现好的常用的接口适配器。

上面讲了这么多，其实只是分析了一个问题：retrofit是如何实现**仅通过接口**即可完成网络请求调用的。
答案是通过Proxy代理模式，动态代理实现，具体的实现包括以下步骤：

> 1. 通过`loadServiceMethod`来找到对应的`ServiceMethod`；
> 2. 通过桥接模式，使用`OkHttpCall`将真正的请求转发到自定义或者默认的`OkHttpClient`中;
> 3. 通过适配器模式，使用配置的`CallAdapter.Factory`生成的`CallAdapter`对象的`adapt`方法，将`retrofit.Call`对象转化成我们需要的返回类型；

到这里之后，我们就有了三个问题：

> 1. `ServiceMethod`是什么？它里面完成了什么逻辑？
> 2. `OkHttpCall`是如何实现请求转发的？
> 3. `CallAdapter#adapt`实现了接口返回类型转换，那么数据类型转换（`retrofit-converters`）是在什么时候完成的？

带着这三个问题，我们开始分析`ServiceMethod`和`OkHttpCall`的源码。

## ServiceMethod
在`loadServiceMethod`中，`ServiceMethod`对象实例一样是通过`Builder`完成的，那么我们同样去查看其对应的`build`方法。
`build`方法代码较长，在刨除错误异常处理代码之后，主要如下：

```java
public ServiceMethod build() {
  callAdapter = createCallAdapter();
      
  responseConverter = createResponseConverter();

  for (Annotation annotation : methodAnnotations) {
    parseMethodAnnotation(annotation);
  }

  int parameterCount = parameterAnnotationsArray.length;
  parameterHandlers = new ParameterHandler<?>[parameterCount];
  for (int p = 0; p < parameterCount; p++) {
    Type parameterType = parameterTypes[p];

    Annotation[] parameterAnnotations = parameterAnnotationsArray[p];

    parameterHandlers[p] = parseParameter(p, parameterType, parameterAnnotations);
  }

  return new ServiceMethod<>(this);
}
```

通过阅读上述代码，我们可以很快梳理出如下流程，即`ServiceMethod`中做了些什么：

> 1. 创建接口适配器
> 2. 创建数据类型转化器
> 3. 方法注解处理
> 4. 参数注解处理

在第1步`createCallAdapter`方法的源码中，找出`method`的泛型返回值类型和方法注解，然后再次调用`Retrofit#calldapter`方法来找到对应的`CallAdapter`。回到`Retrofit`的源码，我们可以发现最终实现如下：

```java
int start = adapterFactories.indexOf(skipPast) + 1;
for (int i = start, count = adapterFactories.size(); i < count; i++) {
  CallAdapter<?, ?> adapter = adapterFactories.get(i).get(returnType, annotations, this);
  if (adapter != null) {
    return adapter;
  }
}
```

到这里，Retrofit配置`AdapterFactory`来实现返回类型转换的过程就一目了然了，剩下的，就是各个`AdapterFactory`如何生成合适的`CallAdapter`来进行`adapt`的细节实现了。阅读`retrofit-adapters`目录下的源码，可以帮助你更好的理解转换过程。

第2步的`createResponseConverter`的处理过程与第1部完全一致，不作赘述。不过需要留意一点的是，`callAdapter`我们之前已经提到，在`invoke`方法中调用了它的`adapt`方法来实现接口转换。而`responseConverter`到目前还未被使用，即我们上面提到的第3个问题。

在`ServiceMethod`源码中查找`responseConverter`的调用，我们找到下面这个方法：

```java
R toResponse(ResponseBody body) throws IOException {
  return responseConverter.convert(body);
}
```

那么流程就更加清晰了，当`ServiceMethod#toResponse`方法被调用时，实际就是调用了`responseConverter#convert`方法，将`ResponseBody`数据对象，转化成了我们需要的数据类型对象，比如`Gson`、`Protobuf`等等。

`ServiceMethod#toResponse`方法是在`OkHttpCall`中调用的，这个我们后续分析`OkHttpCall`源码的时候再进行讲解。

在第3步和第4步中，就是ServiceMethod中占篇幅最多的代码了。我们自定义接口使用了注解（具体包含的注解，在`retrofit2/http`包名下）来简化代码结构，这些注解，都是在`ServiceMethod`中处理的，具体细节这里不展开讲解。

## 开始分析OkHttpCall之前
那么现在，我们就带着最后一个问题，来到了本文最后分析的一个（然而并不是最后一个）类源码。
回想一下问题：**`OkHttpCall`是如何实现请求转发的？**

在开始分析`OkHttpCall`源码之前，我们来回顾一下之前得到的信息。

> 1. 在`invoke`方法中，创建了一个持有`ServiceMethod`实例的`OkHttpCall`对象;
> 2. 在`invoke`方法中，通过`serviceMethod.callAdapter#adapt`方法传入`okHttpCall`实例来触发的接口转换。

所以，别着急，让我们回到`CallAdapter#adapt`方法，这里我们选择默认的`ExecutorCallAdapterFactory`来进行讲解。

`ExecutorCallAdapterFactory`的`get`方法，创建了一个`CallAdapter`对象，这个`CallAdapter`类`adapt`方法的源码如下：

```java
@Override public Call<Object> adapt(Call<Object> call) {
  return new ExecutorCallbackCall<>(callbackExecutor, call);
}
```

这里通过`ExecutorCallbackCall`创建了一个`Call<Object>`对象并返回，传入的参数`Call<Object> call`即我们的`okHttpCall`实例，而通过`CallAdapter`源码我们知道，`adapt`方法是泛型方法，可以返回任何类型，例如`RxJavaCallAdapter`返回的就是一个`Object`对象，Java8的`BodyCallAdapter`中返回的是`CompletableFuture<R>`对象。

因为本文中以`ExecutorCallAdapterFactory`举例，请务必将参数的`Call<Object>`和返回值`Call<Object>`区分开。

在构造`ExecutorCallbackCall`对象时，传入了两个参数，`callbackExecutor`和`call`对象，前者是`Android`类型`Platform`中的`MainThreadExecutor`，后者即`okHttpCall`实例。`ExecutorCallBackCall`使用了聚合委托来实现请求转发，将实际请求转发到`okHttpCall`中。

在我们的例子中，请再次看如下代码：

```java
Call<List<Repo>> repos = service.listRepos("octocat");
```

这里的`repos`就是`ExecutorCallbackCall`类的对象实例，我们可以通过`repos`调用`Call`接口的任何方法，比如`enqueue`方法来执行异步请求，`execute`方法来执行同步请求。而这些方法的实现，即是我们之前提到的，通过内置的`Call`委托对象实现，这个委托对象的实例即`okHttpCall`对象实例。

在其他的`CallAdapter`中，比如`RxJavaCallAdapter`，则是将`okHttpCall`封装成`OnSubscribe`对象，然后再通过`Observable#create`创建出`Observable`对象实例，当`Observable`对象实例调用`subscribe`对象时就触发了实际的网络请求调用。具体可自行查看源码。

所以本小节的小结是：

* 1. 接口转换后的实例对象，如默认的`Call`对象调用`enqueue`方法，或者`Observable`对象调用`subscribe`方法，最终会触发`OkHttpCall`中对应的方法，将请求转发到`OkHttpCall`中。

讲到这里，我们终于来到了最后一步：`OkHttpCall`的源码。

## 真正的OkHttpCall分析
回顾一下之前分析的结论，所有的请求都被转发到了`OkHttpCall`中，而主要的方法即`retrofit2.Call<T>`中的方法。
`OkHttpCall`的源码有将近300行，根据我们之前的分析，那么我们只需要关注其中核心代码即可。

`OkHttpCall`的主要几个核心方法如下：

> 1. `createRawCall`
> 2. `parseResponse`

`OkHttpCall`中的实际代码实现，是通过`okhttp3.Call`接口实现的，而该接口是通过`createRawCall`方法创建的。
查看`createRawCall`方法源码如下：

```java
private okhttp3.Call createRawCall() throws IOException {
  Request request = serviceMethod.toRequest(args);
  okhttp3.Call call = serviceMethod.callFactory.newCall(request);
  if (call == null) {
    throw new NullPointerException("Call.Factory returned null.");
  }
  return call;
}
```

可以看到，它是调用了`serviceMethod.callFactory.newCall(request)`生成的，这个`callFactory`就是最开始`Retrofit.Builder#build`方法中默认的`OkHttpClient`，或者其他你自定义的CallFactory。

而`parseResponse`顾名思义就是对返回的数据流进行解析转换。在这个方法中，我们看到了之前我们提到的熟悉的`serviceMethod.toResponse(catchingBody)`，在这里完成了数据格式转换。

在这个方法中，我们也可以看到其他一些异常处理的代码：

```java
if (code < 200 || code >= 300) {
  try {
    // Buffer the entire body to avoid future I/O.
    ResponseBody bufferedBody = Utils.buffer(rawBody);
    return Response.error(bufferedBody, rawResponse);
  } finally {
    rawBody.close();
  }
}

if (code == 204 || code == 205) {
  rawBody.close();
  return Response.success(null, rawResponse);
}
```

如果你了解Http状态码，那么理解起来会很轻松，如果你不了解，不妨查查资料。从这里我们也可以看出`Retrofit`的一些不足，例如不支持重定向，不支持重试机制等等，其实这也正是`Retrofit`的设计意图，`Retrofit`是一个完全按照`Restful`协议指定的网络请求框架，若是将上述功能引入，会和设计意图不符。

# 总结
写了一下午，又在晚上补充了一些，终于是写完了，也许会有很多不足之处，先发出来然后再慢慢修改吧。😂

读完`Retrofit`的源码后，对整个框架设计确实是惊叹的，想想自己开发多年，虽然也对功能模块进行拆分封装框架，但真正做到精简和解耦，还是差很多，仍需努力。

在Retrofit中，涉及到很多设计模式，而设计模式是为了真正的设计服务的，不是一味地为了使用模式而使用模式。
在面向对象程序设计中，有如下两个概念：

> 1. 针对接口编程
> 2. 找出变化，并把它们封装起来

针对接口编程，更方便我们去把变化的东西封装起来。在Retrofit中，变化的东西主要如下：

> 1. Http请求的真正实现方，即`CallFactory`；
> 2. 接口返回对象，即`CallAdapter`，这个功能是我认为`Retrofit`最棒的设计了；
> 3. 数据类型，即`Converter`；

将这三个变化的东西封装起来，大大简化了代码中的各种转化，以往我们使用其他库，遇到接口不统一，就需要写一大堆适配器来进行转化，遇到数据类型不统一，也要写一大堆转化逻辑来转化，尤其繁琐。

很多人对面向对象程序设计理解的封装，都是共同代码的提取或者功能模块的封装，这些其实在面向过程程序设计也可以做，概念理解的偏差，就决定了框架设计的**高度**。

给自己的一些寄语：多看优秀的开源代码、多思考多总结、多尝试写一些优秀的代码。

你也可以参考其他人的Retrofit源码解读来获取更多内容，也可以阅读源码来加深自己的认知。点击原文可以看到我同事Johnny关于Retrofit的一篇解读文章。

如有不正确之处，欢迎指出交流~


