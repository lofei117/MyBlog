---
layout: post
title: "Advanced Person and Group Appraising System of HIT"
description: "A website built with Jsp & Servlet"
category: "Project"
tags: ["Project"]
---
{% include JB/setup %}

# Introduction

* Name : Advanced Person and Group Appraising System of HIT (Harbin Institute of Technology)
* Time : 2011.04 - 2011.06
* Role : Developer
* Teammate: Aibao Li, Qizhen Zhang.

This is the first project I had been involved in. It's a dynamic websites developed with Jsp and original Servlet, and use MySQL as database.

As a normal website, most of the pages are built with native HTML and Javascript, [Ext-Js][Ext-Js] was used to build front-end UI for role **Teacher** and **Administrator**. 

<!-- more -->

# Structure

* Model : Javabean, `ClassInfoBean.java`, `StudentInfoBean.java`, `TeacherInfoBean.java`, `DBTools.java` ...
* View : Jsp, `index.jsp`, `studentIndex.jsp`, `superManager.jsp`, `error.jsp`, ...
* Controller : Servlet, `StuLogin.java`, `ModPassword.java`, `SubmitStuForm.java`, ...

# Screenshots

![index.png][index.png]

![loginpage.png][loginpage.png]

![studentForm.png][studentForm.png]

![studentIndex.png][studentIndex.png]

![superManager.png][superManager.png]






[index.png]: /assets/images/Project/Pingyou/index.png "index page"
[loginpage.png]: /assets/images/Project/Pingyou/loginpage.png "login page"
[studentForm.png]: /assets/images/Project/Pingyou/studentForm.png "student form"
[studentIndex.png]: /assets/images/Project/Pingyou/studentIndex.png "student index page"
[superManager.png]: /assets/images/Project/Pingyou/superManager.png "superManager index page"

[Ext-Js]: http://www.sencha.com/products/extjs/ "Ext-Js"