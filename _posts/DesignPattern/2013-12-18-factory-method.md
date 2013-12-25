---
layout: post
title: "Factory Method"
description: "Factory Method pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Factory Method"]
---
{% include JB/setup %}


# Introduction

The Factory Method is a pattern intented to help assign responsibility for creation. It's an object-oriented creational design pattern to implement the concept of factories and deals with the problem of creating objects(products) without specifying the extract class of object that will be created.

The Factory Method may be used when:

* The creation of an object makes reuse impossible without significant duplication of code.
* The creation of an object requires access of imformation or resources that should not be contained within the composing class.
* The lifetime management of the generated objects must be centralized to ensure the consistent behavior within the application.

Factory Methods are common in **toolkits** and **frameworks**, where library code needs to create objects of types that maybe subclassed by applications using the framework.

# <a name="definition"></a>Definition

Define an interface for creating an object, but let subclasses decide which class to be instantiate. Factory Method lets a class defer instantiation to subclasses.

# Problem 
A class needs to instantiate a derivation of another class, but doesn't know which one. Factory Method allows a derived class to make the decision.

# UML class diagram
![uml-diagram][uml-diagram]

Factory Method pattern is a simplified version of [Abstract Factory][abstract-factory] pattern. Factory Method pattern is responsible of creating products that belong to one family. While Abstract Method deals with multiple families of products.

# Participants
* Product
	* defines the interface that objects the factory method creates.

* ConcreteProduct
	* implements the Product interface.

* Creator
	* declares the factory method which returns an object of type Product. Creator also defines a default implementation of the factory method that returns a default ConcreteProduct object.
	* may call the factory method to create a Product object.

* ConcreteCreator
	* overrides the factory method to return an instance of a ConcreteProduct.

# Example 
Here is an example written in Java. 	

```java
// Sender.java
public interface Sender {
	public void send(String message);
}

// MailSender.java
public class MailSender implements Sender {

	@Override
	public void send(String message) {
		// TODO Auto-generated method stub
		System.out.println("send by mail...");
		System.out.println(message);
	}

}

// SenderFactory.java
public abstract class SenderFactory {
	public void sendMessage(String senderType, String message) {
		Sender sender = createSender(senderType);
		sender.send(message);
	}
	public abstract Sender createSender(String senderType);
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
		} else {
			System.out.println("Cannot find type:" + type);
			return null;
		}
	}	
}

// Test.java
public class Test {
	public static void main(String[] args) {
		SenderFactory senderFactory = new SingleSenderFactory();
		senderFactory.sendMessage("mail", "hello, world");
	}
}
```

# Summary
I read lots of pages about Factory Method pattern, also the book \<\<Design Patterns\>\> and \<\<Design Patterns Explained\>\>, to make clear that how does it work. Those pages I read give me different examples most of which are not correct or accurate.
Factory Method is similar to Abstract Method, and actually when we want to use the patterns, it's difficult to say what's the pattern exactly is. 

Review the [Definition](#definition), there're two points:

* The subclass(e.g. SingleSenderFactory) decides which class to be instantiated. 
* Defer the instantiation to subclass(e.g. SingleSenderFactory).

These work will also be done in [Abstract Factory][abstract-factory]. But Factory Method is simpler.

# See Also

* [wikipedia.org](http://en.wikipedia.org/wiki/Factory_method_pattern "wikipedia.org")
* [apwebco.com](http://www.apwebco.com/gofpatterns/creational/FactoryMethod.html "apwebco.com")
* [abstract-factory][abstract-factory]

[uml-diagram]: /assets/images/designpattern/factory-method.png "Factory Method"
[abstract-factory]: /2013/12/20/abstract-factory/ "Abstract Factory"