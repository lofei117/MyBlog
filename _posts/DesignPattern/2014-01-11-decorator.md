---
layout: post
title: "Decorator"
description: "Decorator pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Structural Pattern"]
---
{% include JB/setup %}

# Introduction
Sometimes you may want to add some responsibilities to your object dynamically and transparently as decorations, and they can be withdrawn at anytime. One solution is to implement subclasses to support each combination, but that's not a good idea, cause you would produce an explosion of subclasses, Or the class definition maybe hidden or otherwise unavaliable for subclassing.
Decorator pattern is designed to solve this problem.

# Definition
Attach additional responsibilities to an object dynamically. Decorators provide a flexible alternative to subclassing for extending functionality.

# UML class diagram
![Decorator pattern](/assets/images/designpattern/decorator.png "Decorator pattern")

# Participants

* Component
	* defines the interface for objects can have responsibilities added to them dynamically.
* ConcreteComponent
	* defines an object to which additional responsibilities can be attached.
* Decorator
	* maintains a reference to a Component object and defines an interface that confirms to Component's interface.
* ConcreteDecorator
	* adds the resonsibilities to the Component.

# Example

```java
// Component
public interface Messageable {
	public void buildMessage();
}

// ConcreteComponent
public class TextMessage implements Messageable {

	@Override
	public void buildMessage() {
		// TODO Auto-generated method stub
		System.out.println("This is message built in TextMessage.");
	}

}

// Decorator
public class MessageDecorator implements Messageable {

	private Messageable message;
	
	public MessageDecorator(Messageable msg) {
		this.message = msg;
	}
	@Override
	public void buildMessage() {
		// TODO Auto-generated method stub
		message.buildMessage();
	}

}

// ConcreteDecorator
public class PrefixMessageDecorator extends MessageDecorator {

	public PrefixMessageDecorator(Messageable msg) {
		super(msg);
		// TODO Auto-generated constructor stub
	}

	@Override
	public void buildMessage() {
		// TODO Auto-generated method stub
		addPrefix();
		super.buildMessage();
	}
	
	public void addPrefix() {
		System.out.println("This is prefix message...");
	}

}

public class SuffixMessageDecorator extends MessageDecorator {
	
	public SuffixMessageDecorator(Messageable msg) {
		super(msg);
	}

	@Override
	public void buildMessage() {
		// TODO Auto-generated method stub
		super.buildMessage();
		addSuffix();
	}
	
	public void addSuffix() {
		System.out.println("This is suffix message...");
	}
}

// Client
public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub

		Messageable textMessage = new PrefixMessageDecorator(
				new SuffixMessageDecorator(new TextMessage()));
		textMessage.buildMessage();
	}

}
```

Output:

```
This is prefix message...
This is message built in TextMessage.
This is suffix message...
```

# Usage

* When you want to add responsibilities to individual objects dynamically and transpanrently without affect other objects.
* When you want to add responsibilities to the object that you might want to change in the future.
* When extension by static subclassing is impratical.

# See Also

* [apwebco.com](http://www.apwebco.com/gofpatterns/structural/Decorator.html "apwebco.com")
* [Adapter pattern](/2014/01/02/adapter/ "Adapter pattern")
* [Composite pattern](/2014/01/05/composite/ "Composite pattern")
* [Strategy pattern](# "Strategy pattern")
