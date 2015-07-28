---
layout: post
title: "android note"
description: "record some errors or mistakes, as well as experiences I got when developing android apps."
category: "android"
tags: [android]
---
{% include JB/setup %}

## Custom Theme Style   
It's quite easy for developers to define their own theme by declaring styles in `styles.xml` file.   
like:

```xml
<style name="AppBaseTheme" parent="@android:style/Theme.Holo.Light">
	<!--
        Theme customizations available in newer API levels can go in
        res/values-vXX/styles.xml, while customizations related to
        backward-compatibility can go here.
 
    -->
</style>
```

~~~I've got a mistake that I copied the code from somewhere which the parent is not right. 
Wrap you head that ``parent="android.Theme.Holo"`` is not right. If you want to use the pre-defined theme, make sure that the value of `parent` should start with `@android:style/`.~~~

Well, it seems that I was wrong, but I forget why I got this mistake. 

## startActivityForResult

DO NOT SET THE `REQUEST_CODE` as a negative value.

## Gradle Flavors
In my project by using Android Studio, I have several flavors, in which one flavor(`flavorA`) has different code from the others. Most of the common code are put in `src/main` folder, but there is a class(calling it `A`) , varies from `flavorA` and `flavorB`, `flavorC`, `flavorD`..., and there are also some resouces for each flavor.    
Since class `A` cannot put both in `src/main/java` and `src/flavorA/java`(if you do, duplicated error would occur), we have to put `A.java` in `src/flavorA/java`, `src/flavorB/java`, `src/flavorC/java`... Actually, only the class in `flavorA` is different from the others, class `A` in `src/flavorB/java` and `src/flavorC/java`(...) are same with each other. I am not going to put the same class in each flavor's folder because that's not easy to maintain.    

OK, shortly speaking:

* 1.There are two(or more) versions of a Java class.
* 2.Owning to Gradle struction, we cannot put the default version in directory `src/main/java` 
* 3.There are lots of flavors use the same version of the Java class
* 4.We don't like to put the same class in each flavor's source folder

So, here comes the code I write in `build.gradle`:

* 1.Add the flavors in `productFlavors`

```
	productFlavors {
        flavorA {}
        flavorB {}
        flavorC {}
        flavorD {}
		...
    }
```

* 2.Change the sourceSets for each flavor:

```
android {
	productFlavors.all { flavor ->
        if (name.equals("flavorA")) {
            // do something for flavorA
            // Note: we do not set the sourceSets for flavorA here, you should put the source code in `src/flavorA/java`, gradle would do the work for us.
        } else {
            // set the sourceSets for other flavors
            initSourceSets(flavor.name)
        }
    }
    
}
    

def initSourceSets(flavorName) {
    android.sourceSets.findAll { source ->
        source.name.equals(flavorName)
    }.each { source ->
    	// set the sourceSets as flavorB
        source.setRoot('src/flavorB')
    }
}
```

All right, that are all works. If you have more versions, you need do more works, and it's not difficult, agree?


