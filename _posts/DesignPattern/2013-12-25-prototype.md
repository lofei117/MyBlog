---
layout: post
title: "Prototype"
description: "Prototype pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Creational Pattern"]
---
{% include JB/setup %}


# Introduction
Sometimes we would want to clone a object rather than instantiate a new instance, we would use Prototype pattern.
Prototype is used to:

* avoid subclasses of an object creator in the client application, like the [Abstract Factory pattern][abstract-factory] does.
* avoid the inherent cost of creating a new object in the standard way(e.g., using the 'new' keyword) when it is prohibitively expensive for a given application.

To implement the pattern in Java, we need to implement the interface `Cloneable`. `Cloneable` is an empty interface, so you could implement an method with any name as you like, usually, we declare it as `clone()`.

# Definition
Specify the kinds of objects to create using a prototypical instance, and create new object by copying the prototype.

# UML class diagram
![Prototype](/assets/images/designpattern/prototype.png "Prototype pattern")

# Participants

* Prototype
	* declares an interface for cloning itself.
* ConcretePrototype
	* implements an operation for cloning itself.
* Client
	* creates a new object by asking a prototype to clone itself.

# Example

```java
// Prototype
public abstract class Human implements Cloneable {
	protected String name;
	protected String gender;
	protected int age;

	public Object clone() {
		Object clone = null;
		try {
			clone = super.clone();
		} catch (Exception e) {
			// TODO: handle exception
			e.printStackTrace();
		}
		return clone;
	}
	
	public abstract String getGender();
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}
	
	public void setAge(int age) {
		this.age = age;
	}
	
	public int getAge() {
		return age;
	}
}

// ConcretePrototype
public class Female extends Human {

	@Override
	public String getGender() {
		// TODO Auto-generated method stub
		return "Female";
	}

}

public class Male extends Human {

	@Override
	public String getGender() {
		// TODO Auto-generated method stub
		return "Male";
	}

}

// Client
public class HumanCache {
	private static Hashtable<String, Human> humanMap = new Hashtable<String, Human>();
	
	public static Human getHuman(String gender) {
		Human cachedHuman = (Human)humanMap.get(gender.toLowerCase());
		return (Human)cachedHuman.clone();
	}
	
	public static void loadCache() {
		Male m = new Male();
		m.setAge(20);
		m.setName("Cloneable man");
		humanMap.put("male", m);
		
		Female fm = new Female();
		fm.setAge(18);
		fm.setName("Cloneable woman");
		humanMap.put("female", fm);
	}
}

// Test
public class Test {
	
	public static void main(String[] args) {
		HumanCache.loadCache();
		
		Male cloneMale = (Male) HumanCache.getHuman("male");
		System.out.println("gender:" + cloneMale.getGender());
		System.out.println("name:" + cloneMale.getName());
		System.out.println("age:" + cloneMale.getAge());
		
		Female cloneFemale = (Female) HumanCache.getHuman("female");
		System.out.println("gender:" + cloneFemale.getGender());
		System.out.println("name:" + cloneFemale.getName());
		System.out.println("age:" + cloneFemale.getAge());		
	}
}
```

In this example we simply call `super.clone()` which is defined in `java.lang.Object` class to finish the clone process. `clone` method in class `Object` is a native method. 
`Object.clone()` is a ***shallow copy***, if we desire a ***deep copy***, we should override the `clone` method using serialization and unserialization.

Here is the code of ***deep copy***:

```java
/**
 * deep Clone
 * @return cloned object
 */
public Object deepClone() {
	try {
		 /* Write the object to binary stream */  
        ByteArrayOutputStream bos = new ByteArrayOutputStream();  
        ObjectOutputStream oos = new ObjectOutputStream(bos);  
        oos.writeObject(this);  
  
        /* Read in the binary stream as an object */  
        ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());  
        ObjectInputStream ois = new ObjectInputStream(bis);  
        return ois.readObject(); 
	} catch (Exception e) {
		// TODO: handle exception
		e.printStackTrace();
		return null;
	}
}
```

To use binary read-write serialization, you should implement `Serializable` interface in class `Product` (e.g. Human).

For more information about `clone` method, please see another blog [Dive into clone][dive-into-clone].

# Usage

* When the classes to instantiate are specified at run time.
* When you want to avoid building a class hierarchy of factories that parrallels the class hierarchy of products.
* When instances of a class can hava one of only a few combinations of state.

# See Also

* [wikipedia.org](http://en.wikipedia.org/wiki/Prototype_pattern "wikipedia.org")
* [apwebco.com](http://www.apwebco.com/gofpatterns/creational/Prototype.html "apwebco.com")


[abstract-factory]: /2013/12/20/abstract-factory/ "Abstract Factory"
[dive-into-clone]: /2013/12/26/dive-into-clone/ "Dive into clone"