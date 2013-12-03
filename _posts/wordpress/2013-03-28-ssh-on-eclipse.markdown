---
author: lofei117
comments: true
date: 2013-03-28 14:30:56+00:00
layout: post
slug: ssh-on-eclipse
title: eclipse中ssh搭建
wordpress_id: 508
categories:
- java
- 网站设计
tags:
- hibernate
- java
- spring
- ssh
- struts
- website
---

惭愧，大学都快毕业了连个SSH框架都不会搭，于是又折腾了几天。

不求甚解不是好事，不善于总结也不是好事。

还是简单的说一下吧。


# # why




## ##why eclipse.


1：我实在是不想为了一个网站就去用900多m的myeclipse。虽然myeclipse的确很方便的帮我们搭建好ssh环境。

2：myeclipse能够帮我们做很多事而不用管，但是如果不去了解其中的架构，不去了解struts如何拦截消息作出相应，不去了解spring如何管理struts和hibernate，不去了解hibernate持久化数据操作等消息，之后的编码也还是会一头雾水。




## ##why ssh.


1：才疏学浅是个坎。 或者可以用ssi。到以后hibernate的轻量级和全自动化估计估计满足不了需求，但是短期内快速开发……




# # how




## ## build a project


此过程的介绍纯属凑字数，不喜者请直接往下跳~~~~

打开eclipse以后新建一个dynamic web project就ok了。记得不要直接finish，在最后一步勾选Generate web.xml delopment descriptor.


[![eclipse_new_project](http://blog.lofei.info/wp-content/uploads/2013/03/eclipse_new_project.png)](http://blog.lofei.info/wp-content/uploads/2013/03/eclipse_new_project.png)



然后finish就ok了。然后可以新建一个页面来测试一下，记得部署好服务器。这里用的是tomcat 7.


## ## how to use struts


要想使用struts，自然得有相关的包了。可以上apache.org上下载。[http://struts.apache.org/](http://struts.apache.org/)   博主用的是struts2.

1：下载完解压以后，将struts的必要包放到WEB-INF/lib目录下。

一般的教程上说是6个必须包：



	
  * struts2-core-*.jar

	
  * xwork-core-*.jar

	
  * ognl-*.jar

	
  * freemarker-*.jar

	
  * commons-io-*.jar

	
  * commons-fileupload-*.jar


我这里运行的时候还需要以下两个包，不然会出错，不知道是不是tomcat的原因:

	
  * commons-lang*.jar

	
  * commons-logging-*.jar


2：添加完包以后，需要在web.xml中添加struts过滤器，这个一般的教程里都有，就不繁琐的介绍了。如下:



    
    <!-- Struts Filter -->
    	<filter>
    		<filter-name>struts2</filter-name>
    		<filter-class>
                          org.apache.struts2.dispatcher.ng.filter.StrutsPrepareAndExecuteFilter
                    </filter-class>
    	</filter>
    	<filter-mapping>
    		<filter-name>struts2</filter-name>
    		<url-pattern>/*</url-pattern>
    	</filter-mapping>




 需要注意的是：网上有的教程（一般都是比较老的了）上说的filter-class是org.apache.struts2.dispatcher.FilterDispatcher，这个在这里会出错，新版的struts2应该用我上面说的那个。

3：在web.xml中添加好以后，需要在classpath里添加struts.xml. 这里放在java resources的src目录下就好，eclipse在编译部署的时候会自动拷贝过去。 至于这个命名，如果你命名成struts2.xml，基本出错了。

struts.xml的内容主要是添加action映射和处理结果。

    
    <?xml version="1.0" encoding="UTF-8" ?>
    <!DOCTYPE struts PUBLIC
            "-//Apache Software Foundation//DTD Struts Configuration 2.0//EN"
            "http://struts.apache.org/dtds/struts-2.0.dtd">
    
    <struts>
    	<package name="default" namespace="/" extends="struts-default">
    
    		<!-- Add actions here -->
    		<action name="loginAction" class="lofei.action.LoginAction">
    			<result name="success">/index.jsp</result>
    			<result name="input">/index.jsp</result>
    			<result name="error">/error.jsp</result>
    		</action>
    
    	</package>
    </struts>
    


这里的package和namespace的话，可以自己详细查阅一下文档。 可以参考struts下载来的文件里struts-blank.war的例子。

4：编写action。这个我就不多说了，需要注意的是getter和setter不要忘了、漏了或者错了。错了的话主要是针对命名， 比如username的setter应该是setUsername，不是setUserName.其余同理。这里的username和action来源表单域里的值对应。




## ## intergrate spring with struts


同样这里也是分四步。当然是先需要下载spring包，在[http://www.springsource.org/download/community](http://www.springsource.org/download/community) （这里不得不说一句说不定若干年以后网址就变了，到时候搜索一下就好。spring里东西很多，自己根据下载就好，这里下载的是spring framework.(顺带说一句如果有钱donate一下springsource也好的，我以后有钱了我也会捐助，可惜现在穷学生一个). 下载完以后就开始下面的工作。

1：添加spring必须的包。

根据网站的具体需求不用，需要使用的功能不同当然需要的包肯定只能多不能少。要想集成struts，可以用struts里的struts-spring-plugin.jar或者spring的spring-struts-*.jar. 事实上你会发现其实你需要集成spring用到的基本包在struts里面都会有（至少现在是这样，不排除以后去掉的可能性）。我这里添加了下面的这些包，可以说基本都添加进来了，除了webmvc……目前还没用到的是aop aspects instrument和jdbc这四个。



	
  * spring-aop-3.2.1.RELEASE.jar

	
  * spring-aspects-3.2.1.RELEASE.jar

	
  * spring-beans-3.2.1.RELEASE.jar

	
  * spring-context-3.2.1.RELEASE.jar

	
  * spring-core-3.2.1.RELEASE.jar

	
  * spring-expression-3.2.1.RELEASE.jar

	
  * spring-instrument-3.2.1.RELEASE.jar

	
  * spring-jdbc-3.2.1.RELEASE.jar

	
  * spring-orm-3.2.1.RELEASE.jar

	
  * spring-tx-3.2.1.RELEASE.jar

	
  * spring-web-3.2.1.RELEASE.jar


*** 这里的spring-tx-*.jar是spring的transaction包，后面把hibernate加进来通过spring对其进行事务管理的时候需要用到，不得不吐槽一下本来以为aop orm这些已经够省字了，没想到还有tx这货。

2：修改web.xml

添加spring framework的支持，貌似没什么好说的，上代码吧。

    
    <!-- Spring Framework -->
    	<!-- Path of configuraion of spring -->
    	<context-param>
    		<param-name>contextConfigLocation</param-name>
    		<param-value>classpath:applicationContext.xml</param-value>
    	</context-param>
    
    	<!-- Start the container of Spring -->
    	<listener>
    		<listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    	</listener>


classpath对应的是WEB-INF/classes目录，这里可以放在java resources的src目录下（和struts.xml）一样，编译部署之后会自动发布过去。
如果后期网站比较复杂，应该考虑把这些xml分成几个文件，到时候可以用通配符*来匹配。如application*.xml.

3：添加applicationContext.xml
spring作为容器，主要完成的是对bean的管理，这些bean可以是用户自己编写的bean，也可以是DAO，hibernate的sessionFactory就是通过这一原理进行aop的。

    
    <?xml version="1.0" encoding="UTF-8"?>
    <beans xmlns="http://www.springframework.org/schema/beans"
    	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    	xsi:schemaLocation="http://www.springframework.org/schema/beans 
     http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">
     	<!-- Hibernate SessionFactory -->
    	<bean id="sessionFactory"
    		class="org.springframework.orm.hibernate4.LocalSessionFactoryBean">
    		<property name="configLocation">
    			<value>classpath:hibernate.cfg.xml</value>
    		</property>
    	</bean>
    
    	<bean id="userDAO" class="lofei.DAO.impl.UserDAOImpl">		
    	</bean>
    	<bean id="loginService" class="lofei.service.impl.LoginServiceImpl">
    		<property name="userDAO">
    			<ref bean="userDAO" />
    		</property>
    	</bean>
    	<bean id="loginAction" class="lofei.action.LoginAction">
    		<property name="loginService">
    			<ref bean="loginService" />
    		</property>
    	</bean>
    </beans>


这里我已经把hibernate的代码添加进去了，将就着看吧。~~

4：编写对应的Service

这个也不多废话了，注意接口和实现的设计。





* * *



喝口水，好累。



* * *






## ## using hibernate


好吧这里我们得分5步。 当然也是需要先下载啦。 [http://hibernate.org/downloads](http://hibernate.org/downloads) 还真是有点复杂，下载release bundles就好。

1：添加必要的包，在hibernate里会有几个文件夹，其中一个是required文件夹，把这个文件夹里的东西都拷贝过去就好。

** 记得spring的transaction包要考过去，不然~~~

** 记得根据自己的数据库类型添加数据库驱动，我这里用的是mysql. 在[http://dev.mysql.com/downloads/connector/j/5.1.html](http://dev.mysql.com/downloads/connector/j/5.1.html) 这里下载mysql 5.1的驱动。

2：在spring的applicationContext.xml之中添加hibernate支持，上面的代码已经有了，这里不赘述了。

3：编写hibernate.cfg.xml文件。

这个文件里包含了连接数据库的基本信息。

    
    <?xml version='1.0' encoding='UTF-8'?>
    <!DOCTYPE hibernate-configuration PUBLIC
              "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
              "http://hibernate.sourceforge.net/hibernate-configuration-3.0.dtd">
    
    <hibernate-configuration>
    	<session-factory>
    		<property name="connection.url">
    			jdbc:mysql://localhost:3306/test
    		</property>
    		<property name="connection.username">root</property>
    		<property name="connection.password">123456</property>
    		<property name="dialect">
    			org.hibernate.dialect.MySQLDialect
    		</property>
    		<property name="connection.driver_class">
    			com.mysql.jdbc.Driver
    		</property>
    		<property name="hibernate.show_sql">true</property>
    		<mapping resource="lofei/DAO/User.hbm.xml" />
    
    	</session-factory>
    </hibernate-configuration>


这里貌似没有详细可以说的，看对应的name就能明白了。这里的话我用的是mysql，所以~~~。

4：编写User.hbm.xml文件

    
    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE hibernate-mapping PUBLIC "-//Hibernate/Hibernate Mapping DTD 3.0//EN"
    "http://hibernate.sourceforge.net/hibernate-mapping-3.0.dtd">
    <!-- 
        Mapping file autogenerated by MyEclipse Persistence Tools
    -->
    <hibernate-mapping>
        <class name="lofei.bean.User" table="user" catalog="test">
            <id name="id" type="java.lang.Integer">
                <column name="userid" />
                <generator class="native" />
            </id>
            <property name="username" type="java.lang.String">
                <column name="username" length="20" not-null="true" />
            </property>
            <property name="password" type="java.lang.String">
                <column name="password" length="20" not-null="true" />
            </property>
        </class>
    </hibernate-mapping>


这里主要是数据表，跟数据库里对应的信息对应，column对应数据表里的项，property对应持久化对象的对应属性。
5：编写DAO和bean以及对应的SessionFactory的Singleton类。

SessionFactory只需要初始化一次，所以可以编写一个类来获取session，当然也可以用static初始化。

编写持久化对象，来跟User.hbm.xml对应。




## ## All is well


到这里算是搭建完毕了，这里没有介绍具体的action bean等，这些看代码应该就能明白了。just test it.




# # Conclusion





	
  * ***** 细节很重要，这些配置文件里稍不留神有时候一个字母打错了就可能纠结半天， 给出的错误提示不一定能很快让你发现错误。

	
  * ***** 搜索引擎固然方便了很多，但是网上很多杂七杂八的东西真的很坑爹。

	
  * ***** mysql未启动的时候~~~ 这种问题还是细节问题，不要以为死脑筋的钻在代码里

	
  * ***** hibernate的DAO里写sql语句的时候，对应的表名不再是数据库里的表名，而是你写的bean的类名。

	
  * ***** 切忌心浮气躁，心急吃不了热豆腐，也不要好高骛远，慢慢来，冷静的时候工作效率会高不少。

	
  * ***** 前面的路还很长，慢慢来吧。




最后在这里放上我搭的ssh的例子。

[http://pan.baidu.com/share/link?shareid=424702&uk=3439330748](http://pan.baidu.com/share/link?shareid=424702&uk=3439330748)


