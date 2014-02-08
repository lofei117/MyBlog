---
layout: post
title: "Flyweight"
description: "Flyweight pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Structural Pattern"]
---
{% include JB/setup %}

# Introduction
When you want to deal with a large number of objects, most of which are common (or you can find their common parts), you may find that the storage costs too much. Flyweight pattern can help to reduce the number of objects, or reduce the storage cost by sharing their intrinsic.

For instance, if I have a lot of messages, and I want to send them to many people by SMS, I have stored the contacts in a XML file like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Contacts>
    <Contact>
        <Name>Tom</Name>
        <Mobile>+11-12345678</Mobile>
        <Email>tom@gmail.com</Email>
    </Contact>
    <Contact>
        <Name>Jack</Name>
        <Mobile>+11-12345699</Mobile>
        <Email>jack@gmail.com</Email>
    </Contact>
    <Contact>
        <Name>Christina</Name>
        <Mobile>+11-12225699</Mobile>
        <Email>christina@gmail.com</Email>
    </Contact>
    <!--
    	more contacts ...
	-->
</Contacts>
```

And the messages are like:

<!-- more -->

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Messages>
	<Message>
		<Content>hello, this is a test message</Content>
		<Receiver>Tom</Receiver>			
	</Message>
	<Message>
		<Content>Tom, I've got a beautiful cat, would you like coming to see her?</Content>
		<Receiver>Tom</Receiver>			
	</Message>
	<Message>
		<Content>hello, this is Christina, would you come to my home for dinner?</Content>
		<Receiver>Jack</Receiver>			
	</Message>
	<Message>
		<Content>hello, this is Christina, would you come to my home for dinner?</Content>
		<Receiver>Tom</Receiver>			
	</Message>
	<!-- 
		more messages
	-->
</Messages>
```

Generally, we may design it as:

```java
public class Message{
	private String content;
	private Receiver receiver;

	// getters and setters
	...
}

public class Receiver{
	private String name;
	private String mobile;
	private String email;

	// getters and setters
	...
}
```
Each `Message` object has an attribute of type `Receiver`, and most of the `Message` objects have same `Receiver`. 
So, let's have a look at Flyweight to see how it work.

# Definition
Use sharing to support large numbers of fine-grained object efficiently.

# UML class diagram
![Flyweight pattern](/assets/images/designpattern/flyweight.png "Flyweight pattern")

# Participants

* Flyweight
	* declares an interface through which flyweights can receive and act on extrinsic state.
* ConcreteFlyweight
	* implements the Flyweight interface adds storage for intrinsic state, if any. 
	* a ConcreteFlyweight must be sharable. 
	* any state it stores must be intrinsic, that is, it must be independent of ConcreteFlyweight object's content.
* UnsharedConcreteFlyweight
	* not all Flyweight subclasses need to be shared. The Flyweight interface enables *sharing*; it doesn't enforce it. It's common for UnsharedConcreteFlyweight objects to have ConcreteFlyweight objects as children at some level in the flyweight object structure.
* FlyweightFactory
	* creates and manages the Flyweight object.
	* ensures that flyweight are shared properly. When a client requests a flyweight, the FlyweightFactory object supplies an existing interface or creates it, if none exists.
* Client
	* maintains a reference to flyweight(s).
	* computes or stores the extrinsic state of flyweight(s).

# Example

```java
// Flyweight
public interface Contactable {
	public void SendTo(Message msg);
}

// ConcreteFlyweight
public class Contact implements Contactable {
	private String name;
	private String mobile;
	private String email;

	public Contact(String name, String mobile, String email) {
		this.name = name;
		this.mobile = mobile;
		this.email = email;
	}
	
	public Contact(Contact c) {
		this.name = c.name;
		this.mobile = c.mobile;
		this.email = c.email;
	}

	public String getName() {
		return name;
	}

	public String getMobile() {
		return mobile;
	}

	public String getEmail() {
		return email;
	}

	@Override
	public void SendTo(Message msg) {
		// TODO Auto-generated method stub
		System.out.println("sending message...");
		System.out.println("content:" + msg.getContent());
		System.out.println("receiver:" + name);
		System.out.println("mobile:" + mobile);
		System.out.println("-----------------");
	}
}

// FlyweightFactory
public class ContactFactory {
	private Map<String, Contactable> contacts = new HashMap<String, Contactable>();

	public Contactable getContact(String name) {
		Contact contact;
		if (contacts.containsKey(name)) {
			contact = (Contact) contacts.get(name);
		} else {
			contact = initContact(name);
			contacts.put(name, contact);
		}
		return contact;
	}

	public Contact initContact(String name) {
		// contacts... these are test data, actually I should read them in from the contacts.xml
		
		Contact c = null;
		if (name.equalsIgnoreCase("tom")) {
			c = new Contact("Tom", "+11-12345678", "tom@gmail.com");
		} else if (name.equalsIgnoreCase("jack")) {
			c = new Contact("Jack", "+11-12345699", "jack@gmail.com");
		} else if (name.equalsIgnoreCase("christina")) {
			c = new Contact("Christina", "+11-12225699", "christina@gmail.com");
		}
		return c;
	}

	public int getContactSize() {
		return contacts.size();
	}
}

// Extrinsic data
public class Message {
	private final String content;
	private final String receiver;
	
	public Message(String content, String receiver) {
		this.content = content;
		this.receiver = receiver;
	}
	
	public String getContent() {
		return content;
	}

	public String getReceiver() {
		return receiver;
	}
}

// Client
class Client{
	private List<Message> messages;
	private ContactFactory contactFactory = new ContactFactory();
	public Client() {
		// TODO Auto-generated constructor stub
		messages = new ArrayList<>();
				
		// read in messages from messages.xml file.
		messages.add(new Message("hello, this is a test message", "Tom"));
		messages.add(new Message("Tom, I've got a beautiful cat, would you like coming to see her?", "Tom"));
		messages.add(new Message("hello, this is Christina, would you come to my home for dinner?", "Tom"));
		messages.add(new Message("hello, this is Christina, would you come to my home for dinner?", "Jack"));
	}
	
	public void sendMessages() {
		for(Message m : messages) {
			Contactable c = contactFactory.getContact(m.getReceiver());
			c.SendTo(m);
		}
		System.out.println("total contact count:"+contactFactory.getContactSize());
	}
}

public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		new Client().sendMessages();
	}

}
```

Output:

```
sending message...
content:hello, this is a test message
receiver:Tom
mobile:+11-12345678
-----------------
sending message...
content:Tom, I've got a beautiful cat, would you like coming to see her?
receiver:Tom
mobile:+11-12345678
-----------------
sending message...
content:hello, this is Christina, would you come to my home for dinner?
receiver:Tom
mobile:+11-12345678
-----------------
sending message...
content:hello, this is Christina, would you come to my home for dinner?
receiver:Jack
mobile:+11-12345699
-----------------
total contact count:2
```
# Summary
Honestly speaking, this example is not a good one, but I hope it would help, I've thought about this pattern for more than two days, read lots of blog to understand it, but I am still a little confused, I need to do more work.

And I don't know when to use the `UnsharedConcreteFlyweight`, those source code I read gave me sences that they had ignored it.

# Usage
The Flyweight pattern's effctviveness depends heavily on how and where it's used. Apply the Flyweight pattern when all of the following are true:

* An application uses a large number of objects.
* Storage costs are high because of the sheer quantity of objects.
* Most object state can be made extrinsic.
* Many groups of objects may be replaced by relatively few shared objects once extrinsic state is removed.
* The application doesn's depend on object identity. Since flyweight objects may be shared, identity tests will return true for conceptually district objects.

# See Also

* [apwebco.com](http://www.apwebco.com/gofpatterns/structural/Flyweight.html "apwebco.com")
