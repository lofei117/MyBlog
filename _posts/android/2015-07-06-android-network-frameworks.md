---
layout: post
title: "Android Network Frameworks"
description: ""
category: ""
tags: []
---
{% include JB/setup %}

# TODO 
android网络库调研   
1、基础功能特点   
2、并发数，并发时效率（不同并发数效率，响应时间）   
3、内存使用；   
4、不同场景使用情况（图片请求为主，数据请求为主等）   
5、基础参数（包大小，更新情况，版本兼容情况）     

# HttpClient, HttpUrlConnection and OkHttp

Before Android Gingerbread(2.3) HttpUrlConnection is not stable cause it has some un-fixed bugs. So HttpClient is recommended as default. Since Gingerbread, the bugs are fixed, and HttpUrlConnection is more lightweight and more easy to maintain.

Both HttpClient and HttpUrlConnection are developed based on HTTP, when OkHttp based on HTTP and SPDY. That is said, OkHttp would be quicker and more efficiently.

# AsyncTask

* Cancelable **false**
* Support network change **false**
* Parallel work support: not simple
* May lead to memory leak (Activity has been recycled)
* different behavior varies on platform-version


# Volley, Retrofit and android-async-http

## Features

### Volley

* High level API to make asynchronous RESTful HTTP request.
* Elegant and robust Request queue.
* Extension architecture allows developers to implement custom request and response handling mechanism
* Able to use external HTTP client library (like OkHttp)
* Robust request caching policy.
* Support image loading, and custom view for loading image easily.
* Max waiting queue size: 11, cannot be changed
* Max parallel capacity: default 4, can be changed.
* `StringRequest`, `JsonRequest` supported.

### Retrofit

* Easy to use RESTful API ( by annotation)
* Use OkHttp default. (which is faster than HttpClient or HttpUrlConnection)
* NIO support.
* Faster than Volley.
* Auto parse Json by Gson (default). And `jackson`, `simplexml`, `protobuf` also supported.
* Can custom thread pool size
* Simply for Web Service. Image load not support,


### android-async-http

* Asynchronous Http Request, handle responses in anonymous callbacks.
* HTTP requests happen outside the UI thread.
* Thread Pool for capping concurrent resource usage.
* GET/POST params builder
* Multipart file uploads without using third part libraries.
* Automatic smart request retries.
* Automatic gzip decode.
* Built-in response parsing in to JSON(JsonHttpResponseHandler)
* Max connections default: 10, can be changed.



## Convenience

* Json parse

	Retrofit has auto json parser.

* Cookie Handler

* Retry mechanism
	
	Retrofit has no retry mechanism.

* Headers

* Error handling

## Performance

* Memory use
* Speed

## Other
* OkHttp的body只可取一次，第二次再取则为空。