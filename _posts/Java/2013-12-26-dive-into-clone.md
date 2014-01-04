---
layout: post
title: "Dive into clone"
description: "Something about clone an object in Java"
category: "Java"
tags: ["Java"]
---
{% include JB/setup %}

# Cloning in Java
There must be a lot times that you want to copy an object, or sometimes it's prohibitively expensive to instantiate new instance. 
Simply, if you just assign an object to another variable, like:

```java
MyObject obj1 = new MyObject();
MyObject obj2 = obj1;
```
But absolutely it is not copy, `obj2` and `obj1` are different references of the MyObject type object in memory. If you do some change to `obj1`, it will reflect in `obj2`. Obviously, this is not what we want.

Java supplies an interface `Cloneable` that we can clone an object when we implement this interface. `Cloneable` is an empty interface so that we can name the method whatever we like. Usually, just name it as `clone` to keep high readability.

```java
// Person Object
public class Person implements Cloneable {
	private String name;

	public Person(String name) {
		this.name = name;
	}
	
	@Override
	public Object clone() throws CloneNotSupportedException {
		return super.clone();
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@Override
	public String toString() {
		return "This is person " + name + "@" + Integer.toHexString(hashCode());
	}
}

// TestCase
public class TestClone {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		Person p1 = new Person("Tom");
		Person p2 = null;
		try {
			p2 = (Person) p1.clone();
		} catch (CloneNotSupportedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		System.out.println(p1);
		System.out.println(p2);
		System.out.println(p1 != p2);
		System.out.println(p1.getClass() == p2.getClass());
		System.out.println(p1.equals(p2));
	}

}
```

In this case, we simply implement the `clone` method and call `super.clone()` to finish the copy process. `super.clone()` is defined in `java.lang.Object` class as:

```java
protected native Object clone() throws CloneNotSupportedException;
```
`Object.clone()` is a native method, I'm not going to get deep into it now. What I am going to do is reading the comments of `clone` method. 

>Creates and returns a copy of this object. The precise meaning of "copy" may depend on the class of the object. The >general intent is that, for any object x, the expression:    
>	 `x.clone() != x`   
>will be true, and that the expression:    
>	 `x.clone().getClass() == x.getClass()`   
>will be true, but these are not absolute requirements. While it is typically the case that:    
>	 `x.clone().equals(x)`   
>will be true, this is not an absolute requirement. 
>

According to the comments, the output of above testcase should be:

```
This is person Tom@3020ad
This is person Tom@1b15692
true
true
true
```
However, the output is:

```
This is person Tom@3020ad
This is person Tom@1b15692
true
true
false
```
The reason is that default `equals` method is inherenting from `java.lang.Object` class, which is declared and implemented as:

```java
public boolean equals(Object obj) {
   return (this == obj);
}
```
In this method, the objects are compared with their address in memory. Absolutely, `p1` and `p2` are stored in different area of memory, they're two actual object, which means, they have different `hashcode` as we see.

Review the comments, it's recommend that `x.clone().equals(x)` will be *true*, but this is **not** an absolute requirement. That is to say, we should decide the result according to the fact to meets our needs. 
In this case, I want to the result `p1.equals(p2)` returns *true*, so I'm gonna override the `equals` method.
Cause it is a simple case, I suppose that two person are same when they have the same name, so the code is like:

```java
	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		} else if(obj instanceof Person) {
			Person p = (Person)obj;
			if (this.name.equals(p.getName())) {
				return true;
			}
		}
		return false;
	}
```
Run the testcase again, the result is:

```
This is person Tom@c791b9
This is person Tom@3020ad
true
true
true
```
In complex software development, objects usually have lots of attributes, like that objects in real world owing lots of properties, so you'd better think about their equalization for more times.

## Deep copy
Java has two kinds of copy: ***shallow copy*** and ***deep copy***, `Object.clone` is the former one. Let's have a look at another case below:

```java
// Person Object
public class Person implements Cloneable {
	private String name;
	private Car car;		// Add car attribute

	public Person(String name, Car car) {
		this.name = name;
		this.setCar(car);
	}

	@Override
	public Object clone() throws CloneNotSupportedException {
		return super.clone();
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Car getCar() {
		return car;
	}

	public void setCar(Car car) {
		this.car = car;
	}

	@Override
	public String toString() {
		return "This is person " + name + " has car " + car.getName() + "@" + Integer.toHexString(hashCode());
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		} else if(obj instanceof Person) {
			Person p = (Person)obj;
			if (this.name.equals(p.getName())) {
				return true;
			}
		}
		return false;
	}
}

// Car Object
public class Car {
	private String name;
	
	public Car(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@Override
	public String toString() {
		return "@" + Integer.toHexString(hashCode());
	}
}

// TestCase
public class TestClone {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		Person p1 = new Person("Tom", new Car("Benz"));
		Person p2 = null;
		try {
			p2 = (Person) p1.clone();
		} catch (CloneNotSupportedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		String name = p2.getName();
		name = "Jack";
		p2.setName(name);
		
		Car car2 = p2.getCar();
		car2.setName("Ford");		

		System.out.println(p1);
		System.out.println(p2);
		System.out.println(p1 != p2);
		System.out.println(p1.getClass() == p2.getClass());
		System.out.println(p1.equals(p2));
	}
}
```
The expected output is:

```
This is person Tom has car Benz@76fba0
This is person Jack has car Ford@181ed9e
true
true
false
```
But actually, it is:

```
This is person Tom has car Ford@76fba0
This is person Jack has car Ford@181ed9e
true
true
false
```
**You may ask why the name `Tom` was not changed, well, I would talk about it in my new post [Dive into String][dive-into-string]**

This is because that ***shallow copy*** copies the object fields as references, `car` in `p1` has the same hashcode as `car` in `p2`.

```java
// Test code
System.out.println(p1.getCar().equals(p2.getCar()));
// Output
true
```

To get deep copy of an object, we should also clone the object fields(e.g. Car).
So we may modify the code in `Person.clone` like:

```java
	@Override
	public Object clone() throws CloneNotSupportedException {
		Person clonePerson = (Person) super.clone();
		if (clonePerson != null) {
			clonePerson.car = (Car)this.car.clone();
		}
		return clonePerson;
	}
```
And we should also implement `clone` method for `Car` class.

```java
	@Override
	public Object clone() throws CloneNotSupportedException {
		return super.clone();
	}
```
**Remember to implememt the interface `Cloneable` in `Car` class.**

Run the testcase again, we finally get our expected output:

```
This is person Tom has car Benz@181ed9e
This is person Jack has car Ford@1175422
true
true
false
```

However, if we have lots of object fields in `Person` class such as `House`, `Job` and ..., even worse when they(`Car`, `House`,...) have other object fields.... You may get crazy in these steps. I don't want to implement `clone` method for all the aggregative objects in `Person` class, is there any uncomplicated method?

The answer is *Yes*. We can use **serialization** to realize this.

To use **serialization** in Java, we should implement **Serialiable** interface for the classes(Both `Person` and its aggregative class), and then add an attribute *serialVersionUID* to it. Here I use an default serial version ID.

```java
private static final long serialVersionUID = 1L;
```
Then, declare and implement a method named `deepClone` in `Person` class.

```java
	public Object deepClone() throws IOException, ClassNotFoundException {
		// Serialize the object
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		ObjectOutputStream oos = new ObjectOutputStream(bos);
		oos.writeObject(this);
		
		// Deserialize the object
		ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());
		ObjectInputStream ois = new ObjectInputStream(bis);
		return ois.readObject();
	}
```

**Differ from hierarchy clone, it seems we only need to implement deepClone for `Person` class.**

According to [wikipedia][wikipedia], serialization is used to clone final fields cauze clone is incompatible with final fields. But serialization is significantly slower. I didn't check this yet.

# Summary
Well, I had tried my best to understand `clone` in java, but I think there are still lots of work to do, I shall *dive into clone* deeper.

# See Also

* [Cloning in Java](http://www.jusfortechies.com/java/core-java/cloning.php "Cloning in Java")
* [wikipedia][wikipedia]
* [Prototype pattern][prototype]

[wikipedia]: http://en.wikipedia.org/wiki/Clone_(Java_method) "wikipedia.org"
[prototype]: /2013/12/25/prototype/ "Prototype pattern"
[dive-into-string]: /2014/01/04/dive-into-string/ "Dive into String"