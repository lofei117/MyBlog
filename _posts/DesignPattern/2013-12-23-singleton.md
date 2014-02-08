---
layout: post
title: "Singleton"
description: "Singleton"
category: "Design Pattern"
tags: ["Design Pattern", "Creational Pattern"]
---
{% include JB/setup %}

# Introduction
In software engineering, when develop a software, sometimes you may want to instantiate an object just one time, and keep it all the time with only one instance. To ensure that there is only one instance and that the instance is easily accesible, you should use Singleton pattern.

# Definition
Ensure a class only has one instance, and provide a global point of access to it.

# UML class diagram
![Singleton pattern](/assets/images/designpattern/singleton.png "Singleton pattern")

# Participants

* Singleton
	* defines an instance operation that lets clients access its unique instance.
	* responsible for creating and maintaining its own unique instance.

# Example

```java
public class Singleton{
	private static Singleton instance;
	private Singleton(){};

	public static Singleton getInstance(){
		if(instance == null){
			instance = new Singleton();
		}
		return instance;
	}
}
```
It's not difficult for you to write an Singleton class, but you should pay your attention to multi-threads project to ensure that:

* DO NOT instantiate the object two(or more) times when different threads may do without locking the code.
* DO NOT use empty object before it'd been instantiated.

# Usage
* When there must be only one instance of a class.

# See Also

* [wikepedia.org](http://en.wikipedia.org/wiki/Singleton_pattern "wikipedia.org")
* [apwebco.com](http://www.apwebco.com/gofpatterns/creational/Singleton.html "apwebco.com")