---
layout: post
title: "Abstract Factory"
description: "Abstract Factory pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Abstract Factory"]
---
{% include JB/setup %}

# Introduction
Well, before we start to talk about the intent of Abstract Factory, think about that:

* 1. I want to send some message to my customers, but I don't know (or I don't care) what kind of ConcreteSender to use.
* 2. If I have a new kind of ConcreteSender (e.g. WechatSender), I can add it to my program without modify the exists Factory class.
* 3. ....

If we want to use [Factory Method][factory-method], we'll find that we should do the steps:

* 1. Implement the interface `Sender` (WechatSender);
* 2. Add the code to `SingleSenderFactory#createSender` method.

So the code may like:

```java
// WechatSender
public class WechatSender implements Sender{
	public void send(String message){
		// ToDo do some logic here...
	}
}
// SingleSenderFactory
public class SingleSenderFactory extends SenderFactory {
	public SingleSenderFactory() {

	}

	public Sender createSender(String type) {
		if (type.equalsIgnoreCase("mail")) {
			return new MailSender();
		} else if (type.equalsIgnoreCase("sms")) {
			return new SmsSender();
		} else if(type.equalsIgnoreCase("wechat"){
			return new WechatSender();
		} else {
			System.out.println("Cannot find type:" + type);
			return null;
		}
	}	
}
```

If we finally have a lot of ConcreteSender, you will find that too much code in the SingleSenderFactory, and a lot of `if-else`.  The coulping is too high. 

All right, so here comes Abstract Factory pattern.

# Definition
Provides an interface for creating families of related or dependent objects without specifying their concrete classes.

# UML class diagram
![Abstract Factory](/assets/images/designpattern/abstract-factory.png "Abstract Factory")

# Participants

* Abstract Factory
	* declares an interface for operations that creat abstract products objects.
* Concrete Factory
	* implememts the operations to create concrete products objects.
* Abstract Product
	* delcares an interface for a type of product objects.
* Concrete Product
	* defines a product object to be created by the corresponding concrete factory implements the AbstractProduct interface.
* Client
	* use interfaces declared by AbstractFactory and AbstractProduct classes.

# Example
An example written in Java.

```java
// Abstract Factory
public interface SenderFactory {
	public Sender createSender();
}

// Concrete Factory
public class MailSenderFactory implements SenderFactory {

	@Override
	public Sender createSender() {
		// TODO Auto-generated method stub
		return new MailSender();
	}

}
public class SmsSenderFacotry implements SenderFactory {

	@Override
	public Sender createSender() {
		// TODO Auto-generated method stub
		return new SmsSender();
	}

}
public class WechatSenderFactory implements SenderFactory {

	@Override
	public Sender createSender() {
		// TODO Auto-generated method stub
		return new WechatSender();
	}

}

// Abstract Product
public interface Sender {
	public void send(String message);
}

// Concrete Product
public class MailSender implements Sender {

	@Override
	public void send(String message) {
		// TODO Auto-generated method stub
		System.out.println("send by mail...");
		System.out.println("sending message:"+message);
	}

}
public class SmsSender implements Sender {

	@Override
	public void send(String message) {
		// TODO Auto-generated method stub
		System.out.println("send by sms...");
		System.out.println("sending message:"+message);
	}

}
public class WechatSender implements Sender {

	@Override
	public void send(String message) {
		// TODO Auto-generated method stub
		System.out.println("send by wechat...");
		System.out.println("sending message:"+message);
	}

}

// Client
public class MessageProcessor {
	private Sender sender;
	
	public MessageProcessor(SenderFactory senderFactory) {
		sender = senderFactory.createSender();
	}
	
	public void processMessage(String message) {
		sender.send(message);
	}
}

// Application
public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		String senderName = "wechat";
		String message = "hello, world";
		
		SenderFactory factory = null;
		MessageProcessor processor = null;
		
		if (senderName.equalsIgnoreCase("wechat")) {
			factory = new WechatSenderFactory();
		} else if (senderName.equalsIgnoreCase("sms")) {
			factory = new SmsSenderFacotry();
		} else if (senderName.equalsIgnoreCase("mail")) {
			factory = new MailSenderFactory();
		}
		
		processor = new MessageProcessor(factory);
		processor.processMessage(message);
	}
}
```

As we see, the Client (MessageProcessor) doesn't know what the concrete factory actually is, if we want to add a product family, it's quite easy. We only need to implement an Abstract Product interface, and implement an Abstract Factory. And it's easy to change the family without modify the exists families.

# Usage

* When the system needs to be independent of how its products are created composed and represented.
* when the system needs to be configured with one of mutilple families of products.
* When a family of products needs to be used together and this constraint needs to be enforced.
* When you need to provide a library of products, expose their interfaces not the implementations.

# Summary
Well, I am still not quite clear with the design patterns, but I'm trying to make clearer. 
Before we start to write code to realize some functions, think for more time and times. 
Here are some tips mentioned in \<\<Design Patterns Explained\>\> 

* Design to interfaces.
* Favor composition over inheritance.
* Find what varies and encapsulate it.

# See Also
* [wikipedia.org](http://en.wikipedia.org/wiki/Abstract_factory_pattern	 "wikipedia.org")
* [apwebco.com](http://www.apwebco.com/gofpatterns/creational/AbstractFactory.html "apwebco.com")
* [Factory Method][factory-method]


[factory-method]: /2013/12/18/factory-method/ "Factory Method"