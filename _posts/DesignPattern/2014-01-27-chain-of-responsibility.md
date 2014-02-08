---
layout: post
title: "Chain of Responsibility"
description: "Chain of Responsibility - Design Pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Behavioral Pattern"]
---
{% include JB/setup %}

# Introduction
In object oriented design, the chain-of-responsibility pattern is a design pattern consisting of a source of command objects and a series of processing objects. Each processing object contains logic that defines the types of command objects that it can handle; the rest are passed to the next processing object in the chain. A mechanism also exists for adding new processing objects to the end of this chain.

For instance, in Android development, touch event and click event you attach to a control, the event would be dispatched top-down from ViewParent to its subviews, like ViewGroup or ImageView... Each subview may process this event or passing it to its subviews in the chain(actually it's a tree).

# Denifition
Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request. Chain the receiving objects and pass the request along the chain until an object handles it.

# UML class diagram
![Chain of Responsibility](/assets/images/designpattern/chain_of_responsibility.png "Chain of Responsibility")

# Participants

* Handler 
	* defines an interface for handling requests.
	* (optional) implements the successor link.
* ConcreteHandler
	* handles requests it is responsible for.
	* can assess its successor.
	* if the ConcreteHandler can handle the request, it does so; otherwise it forwards the request to its successor.
* Client
	* initiates the request to a ConcreteHandler object on the chain.

# Example

```java
// Handler
public abstract class Logger {
	public static int ERROR = 3;
	public static int INFO = 5;
	public static int DEBUG = 7;

	protected int mask;

	// the next element in the chain of responsibility
	protected Logger next;

	public void setNext(Logger logger) {
		next = logger;
	}

	public void message(String msg, int priority) {
		if (priority <= mask) {
			writeMessage(msg);
		}
		if (next != null) {
			next.message(msg, priority);
		}
	}

	protected abstract void writeMessage(String msg);
}

// ConcreteHandler
public class StdoutLogger extends Logger {

	public StdoutLogger(int mask) {
		this.mask = mask;
	}

	@Override
	protected void writeMessage(String msg) {
		// TODO Auto-generated method stub
		System.out.println("Writing msg to stdout:" + msg);
	}

}

public class EmailLogger extends Logger {

	public EmailLogger(int mask) {
		this.mask = mask;
	}

	@Override
	protected void writeMessage(String msg) {
		// TODO Auto-generated method stub
		System.out.println("Sending msg via email:" + msg);
	}

}

public class FileLogger extends Logger {

	public FileLogger(int mask) {
		this.mask = mask;
	}

	@Override
	protected void writeMessage(String msg) {
		// TODO Auto-generated method stub
		System.out.println("Writing msg to file:" + msg);
	}

}

// Client
class Client{
	private Logger chain;
		
	public void createChain() {
		chain = new StdoutLogger(Logger.DEBUG);
		
		Logger logger2 = new EmailLogger(Logger.INFO);
		chain.setNext(logger2);
		
		Logger logger3 = new FileLogger(Logger.ERROR);
		logger2.setNext(logger3);
		
	}
	
	public void show() {
		if (chain == null) {
			createChain();
		}
		
		chain.message("Starting emulator...", Logger.INFO);
		chain.message("Loading modules...", Logger.DEBUG);
		chain.message("Emulator started. The emulator is running...", Logger.INFO);
		chain.message("An exception has occured.", Logger.ERROR);
	}
}

public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		new Client().show();
	}

}
```

Output:

```
Writing msg to stdout:Starting emulator...
Sending msg via email:Starting emulator...
Writing msg to stdout:Loading modules...
Writing msg to stdout:Emulator started. The emulator is running...
Sending msg via email:Emulator started. The emulator is running...
Writing msg to stdout:An exception has occured.
Sending msg via email:An exception has occured.
Writing msg to file:An exception has occured.
```

# Usage

* When more than one object may handle a request, and the handler isn't known apriori. The handler should be ascertained automatically.
* When you want to issure a request to one or several objects without specifying the receiver explicitly.
* When the set of objects that can handle a request should be specified dynamically.

# See Also

* [wikipedia.org](http://en.wikipedia.org/wiki/Chain-of-responsibility_pattern "wikipedia.org")