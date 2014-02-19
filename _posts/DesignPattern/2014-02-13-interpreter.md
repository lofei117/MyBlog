---
layout: post
title: "Interpreter"
description: "Interpreter pattern - Design Pattern"
category: "Design Pattern"
tags: ["Design Pattern", "Behavioral Pattern"]
---
{% include JB/setup %}

# Introduction
The interpreter pattern is a design pattern that specifies how to evaluate sentences in a language. If a particular kind of problems occurs often enough, it might be worthwhile to express instances of the problem as sentences in a simple language. We can build an interpreter that solves the problem by interpreting these sentences.

# Definition
Given a language, define a representation for its grammer along with an interpreter that uses the representation to interpret sentences in the language.

# UML class diagram
![Interpreter Pattern](/assets/images/designpattern/interpreter.png "Interpreter Pattern")

# Participants

* AbstractExpression
	* declares an abstract Interpret operation that is common to all nodes in the abstract syntax tree.
* TerminalExpression
	* implements an Interpret operation associated with terminal symbols in the grammer.
	* an interface is required for every terminal symbol in a sentence.
* NonterminalExpression
	* on such class is required for every rule R ::= R1 R2 R3 ... Rn in the grammer.
	* maintains instance variables of type AbstractExpression for each of the symbols R1 through Rn.
	* implements an Interpret operation for nonternimal symbols in the grammer. Interpret typically calls itself recursively on the variables representing R1 through Rn.
* Context
	* contains information that's global to the interpreter.
* Client
	* builds (or is given) an abstract syntax tree representing a particular sentence in the language that the grammer defines. The abstract syntax tree is assembled from instance of the NonterminalExpression and TerminalExpression classes.
	* invokes the Interpret operation.

# Example
## Example1

```java
// AbstractExpression
public interface Expression {
	public boolean interpret(String str);
}

// NonterminalExpression
public class AndExpression implements Expression {
	
	private Expression expression1 = null;
	private Expression expression2 = null;
	
	public AndExpression(Expression exp1, Expression exp2) {
		expression1 = exp1;
		expression2 = exp2;
	}

	@Override
	public boolean interpret(String str) {
		// TODO Auto-generated method stub
		return expression1.interpret(str) && expression2.interpret(str);
	}

}

public class OrExpression implements Expression {

	private Expression expression1 = null;
	private Expression expression2 = null;
	
	public OrExpression(Expression exp1, Expression exp2) {
		expression1 = exp1;
		expression2 = exp2;
	}

	@Override
	public boolean interpret(String str) {
		// TODO Auto-generated method stub
		return expression1.interpret(str) || expression2.interpret(str);
	}

}

// TerminalExpression
public class TerminalExpression implements Expression {
	
	private String literal = null;
	
	public TerminalExpression(String str) {
		literal = str;
	}

	@Override
	public boolean interpret(String str) {
		StringTokenizer st = new StringTokenizer(str);
		while (st.hasMoreTokens()) {
			String test = st.nextToken();
			if(test.equals(literal)) {
				return true;
			}
		}
		return false;
	}

}

// Client
class Client {

	public Expression buildInterpreterTree() {
		// Terminals
		Expression terminal1 = new TerminalExpression("John");
		Expression terminal2 = new TerminalExpression("Jack");
		Expression terminal3 = new TerminalExpression("Henry");
		Expression terminal4 = new TerminalExpression("Mary");

		// John or Jack
		Expression alternation1 = new OrExpression(terminal1, terminal2);
		// (John or Jack) and Henry
		Expression alternation2 = new AndExpression(alternation1, terminal3);
		// Mary or ((John or Jack) and Henry)
		Expression alternation3 = new OrExpression(terminal4, alternation2);

		return alternation3;
	}

	public void show() {
		String context = "Mary Tom";
		Expression define = buildInterpreterTree();
		System.out.println(context + " is " + define.interpret(context));
	}
}

public class Test {

	public static void main(String[] args) {
		new Client().show();
	}
}

// Context 
String class
```

Output:

```
Mary Tom is true
```

```java
// AbstactExpression
public interface Expression {
	public int interpret(Map<String, Expression> variables);
}

// NonternimalExpression
public class PlusExpression implements Expression {
	
	private Expression leftOperand;
	private Expression rightOperand;
	
	public PlusExpression(Expression exp1, Expression exp2) {
		this.leftOperand = exp1;
		this.rightOperand = exp2;
	}

	@Override
	public int interpret(Map<String, Expression> variables) {
		// TODO Auto-generated method stub
		return leftOperand.interpret(variables)
				+ rightOperand.interpret(variables);
	}

}

// NonternimalExpression
public class MinusExpression implements Expression {

	private Expression leftOperand;
	private Expression rightOperand;
	
	public MinusExpression(Expression exp1, Expression exp2) {
		this.leftOperand = exp1;
		this.rightOperand = exp2;
	}

	@Override
	public int interpret(Map<String, Expression> variables) {
		// TODO Auto-generated method stub
		return leftOperand.interpret(variables)
				- rightOperand.interpret(variables);
	}

}

// TernimalExpression
public class Number implements Expression {
	
	private int number;
	
	public Number(int number) {
		this.number = number;
	}

	@Override
	public int interpret(Map<String, Expression> variables) {
		// TODO Auto-generated method stub
		return number;
	}

}

// TerminalExpression
public class Variable implements Expression {

	private String name;

	public Variable(String name) {
		this.name = name;
	}

	@Override
	public int interpret(Map<String, Expression> variables) {
		if (variables.get(name) == null)
			return 0;
		return variables.get(name).interpret(variables);
	}

}

// Interpreter
public class Envaluator implements Expression {

	private Expression syntaxTree;
	
	public Envaluator(String expStr) {
		Stack<Expression> expStack = new Stack<>();
		
		for (String token : expStr.split(" ")) {
			if(token.equals("+")) {
				Expression subExp = new PlusExpression(expStack.pop(), expStack.pop());
				expStack.push(subExp);
			}else if(token.equals("-")) {
				Expression right = expStack.pop();
				Expression left = expStack.pop();
				
				Expression subExp = new MinusExpression(left, right);
				expStack.push(subExp);
			}else {
				expStack.push(new Variable(token));
			}
		}
		syntaxTree = expStack.pop();
	}

	@Override
	public int interpret(Map<String, Expression> context) {
		// TODO Auto-generated method stub
		return syntaxTree.interpret(context);
	}

}

// Client
public class Test {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		String expression = "a b - c a + -";
		
		Map<String, Expression> context = new HashMap<String, Expression>();
		context.put("a", new Number(10));
		context.put("b", new Number(5));
		context.put("c", new Number(7));
		
		Envaluator envaluator = new Envaluator(expression);
		int result = envaluator.interpret(context);
		
		System.out.println(result);
	}

}

// Context
Map interface
```

Output

```
-12
```


# Usage
Use the Interpreter pattern when there is a language to interpret, and you can represent the statements in the language as abstract syntax trees. The Interpreter pattern works best when:

* When the grammer is simple.
* efficiency is not a critical concern.

# See Also

* [wikipedia.org](http://en.wikipedia.org/wiki/Interpreter_pattern "wikipedia.org")
* [oodesign.com](http://www.oodesign.com/interpreter-pattern.html "oodesign.com")
