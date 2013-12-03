---
layout: post
title: "Something about jaskson"
description: ""
category: ""
tags: []
---
{% include JB/setup %}

There are a lot of blogs telling you how to use `jackson` in your java project, so I am not going to repeat it, just google it yourself.    

What I'm going to introduce here is that I've got an error when user jackson with `boolean` value.   

When I was using jaskson to parse a Json string value in which there is a boolean value to a java POJO, I've got an error like:   
```java  
org.codehaus.jackson.map.exc.UnrecognizedPropertyException: Unrecognized field "isBoy" (Class info.lofei.bean.User), not marked as ignorable   
at [Source: java.io.StringReader@16e9494; line: 1, column: 46] (through reference chain: info.lofei.bean.User["isBoy"])
	at org.codehaus.jackson.map.exc.UnrecognizedPropertyException.from(UnrecognizedPropertyException.java:53)
	at org.codehaus.jackson.map.deser.StdDeserializationContext.unknownFieldException(StdDeserializationContext.java:267)
	at org.codehaus.jackson.map.deser.std.StdDeserializer.reportUnknownProperty(StdDeserializer.java:649)
	at org.codehaus.jackson.map.deser.std.StdDeserializer.handleUnknownProperty(StdDeserializer.java:635)
	at org.codehaus.jackson.map.deser.BeanDeserializer.handleUnknownProperty(BeanDeserializer.java:1355)
	at org.codehaus.jackson.map.deser.BeanDeserializer.deserializeFromObject(BeanDeserializer.java:717)
	at org.codehaus.jackson.map.deser.BeanDeserializer.deserialize(BeanDeserializer.java:580)
	at org.codehaus.jackson.map.ObjectMapper._readMapAndClose(ObjectMapper.java:2723)
	at org.codehaus.jackson.map.ObjectMapper.readValue(ObjectMapper.java:1854)
	at info.lofei.Main.main(Main.java:22)
```

The input Json string is:```String json = "{\"userid\":300,\"username\":\"lofei\",\"isBoy\":true}";```
and below is the code of User class:   
```java
public class User {   
   
	private int 		userid;   
	private String 		username;   
	private boolean 	isBoy;  
 
	public User() {   
		// TODO Auto-generated constructor stub   
	}   
   
	public int getUserid() {   
		return userid;   
	}   
   
	public void setUserid(int userid) {   
		this.userid = userid;   
	}   
   
	public String getUsername() {   
		return username;   
	}   
   
	public void setUsername(String username) {   
		this.username = username;   
	}   
   
	public boolean isBoy() {   
		return isBoy;   
	}   
   
	public void setBoy(boolean isBoy) {   
		this.isBoy = isBoy;   
	}   
   
	public String toString() {   
		return "userid:"+userid+"#username:"+username+"#isBoy:"+isBoy;   
	}   
}   
```

##Analysis##
The error occurs because that the key-value pair in Json string is `"isBoy":true`, which means a boolean key-value pair, to get the correct value in POJO, you should declare the field as `boy` rather than `isBoy`, it's different from the String/Integer or other object(not guaranteed). For more, if you're using eclipse as your IDE you can generate the getters&setters by check `Source>Generate Getters and Setters` when right clicking in the code area.
