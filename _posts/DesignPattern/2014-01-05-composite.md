---
layout: post
title: "Composite"
description: "Composite pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Structural Pattern"]
---
{% include JB/setup %}

# Introduction
There must be some times you want deal with tree-structed data, and you always have to discriminate between a leaf-node and a branch. This makes code more complex, and therefore, error prone.In OOP, a composite is an object designed as a composition of one-or-more similar objects, all exhibiting similar functionality. Composite pattern is know as a "has-a" relationship between objects. By grouping them as a group, you only need call one method, operations will perform on all composite objects. 

# Definition
Composite objects into tree structures to represent part-whole hierarchies. Composite lets client treat individual objects and composition of objects uniformly. 

# UML class diagram
![Composite pattern](/assets/images/designpattern/composite.png "Composite pattern")

# Participants

* Component
	* declares the interface for the objects in the composition.
	* implements default behavior for the interface common to all classes, as appropriate.
	* declares an interface for accessing and managing its child components.
* Leaf
	* represents leaf objects in the composition, a leaf has no child.
	* defines behavior for primitive objects in the composition.
* Composite
	* defines behavior for components having children.
	* stores child components.
	* implements child-related operations in Components interface.
* Client
	* manipulate objects in the composition through the Component interfaces.

# Example

```java
// Component
public interface Node {
	public void print();
}

// Composite
public class Tree implements Node {
	
	private List<Node> childNodes = new ArrayList<>();
	
	@Override
	public void print() {
		// TODO Auto-generated method stub
		for (Node child : childNodes) {
			child.print();
		}
	}
	
	public void addChild(Node child) {
		childNodes.add(child);
	}
	
	public void removeChild(Node child) {
		childNodes.remove(child);
	}

}

// Leaf
public class Leaf implements Node {
	
	private String color;
	
	public Leaf(String col) {
		this.color = col;
	}

	@Override
	public void print() {
		// TODO Auto-generated method stub
		System.out.println("This is leaf of which color is " + color);
	}

}

// Client
public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		Tree tree = new Tree();
		
		Tree branch1 = new Tree();
		Tree branch2 = new Tree();
		
		Leaf leaf1 = new Leaf("Red");
		Leaf leaf2 = new Leaf("Red");
		Leaf leaf3 = new Leaf("Red");
		Leaf leaf4 = new Leaf("Green");
		
		branch1.addChild(leaf1);
		branch1.addChild(leaf2);
		branch1.addChild(leaf3);
		branch2.addChild(leaf4);
		
		tree.addChild(branch1);
		tree.addChild(branch2);
		
		tree.print();
	}

}
```

# Usage

* When you want to represent the whole hierarchy or a part of hierarchy of objects.
* When you want clients to be able to ignore the differences between compositions of objects and individual objects.
* When the structure can have any level of complexity andis dynamic.

# See Also

* [wikipedia.org](http://en.wikipedia.org/wiki/Composite_pattern "wikipedia.org")
* [apwebco.com](http://www.apwebco.com/gofpatterns/structural/Composite.html "apwebco.com")