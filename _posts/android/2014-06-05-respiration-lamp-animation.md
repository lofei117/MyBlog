---
layout: post
title: "Respiration lamp animation"
description: "To implement a view animation looks like a respiration lamp."
category: "android"
tags: ["android"]
---
{% include JB/setup %}

# Foreword
I am developing an android application, in which I want to show a circle which flashes like a respiration lamp. Here I am going to use view animation to realize it.

# Implementation

To accomplish this, we have five steps:

* 1: create an android application. 
* 2: create a layout xml file for view inflation, and a anim xml file with animation details. (Also you could hard code the animation info, but it's not recommended cause it is difficult to refactoring.)
* 3: add an ImageView to the layout xml
* 4: create an activity to show the view
* 5: load the animation from xml and bind it to the view. (Or create an `Animation` instance when you do not have a animation xml).


I'm not going to waste time on how to create the application project, I'm going to start with the layout xml file.

The layout xml file is simple, with only an `ImageView` inside. The `ImageView` is used to display a circle as the lamp. 

```xml

<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="info.lofei.respirationlamp.MainActivity$PlaceholderFragment" >

    <ImageView
        android:id="@+id/iv_lamp"
        android:layout_width="200dp"
        android:layout_height="200dp"
        android:layout_centerInParent="true"
        android:src="@drawable/shp_lamp_bg" />

</RelativeLayout>
```

And then, as you see, I assign the value `@drawable/shp_lamp_bg` as the image source to the ImageView. The drawable `shp_lamp_bg` is a ![`shape`](http://developer.android.com/guide/topics/resources/drawable-resource.html shape)resource defined in folder *drawable* :

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="oval" >

    <gradient
        android:angle="45"
        android:type="radial"
        android:gradientRadius="200"
        android:endColor="#22FF00B2"
        android:centerColor="#99FF00B2"
        android:startColor="#FFFF00B2" />

    <corners android:radius="360dp" />

</shape>
```

To let `lamp` start to flash as if it were respiration, we need an animation, here I define the animation in the xml file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<alpha  xmlns:android="http://schemas.android.com/apk/res/android"
 	android:interpolator="@android:anim/accelerate_interpolator" 
 	android:duration="1000" 
 	android:fromAlpha="1.0"
 	android:toAlpha="0.0"
 	android:repeatCount="infinite"
 	android:repeatMode="reverse"/>
```

This is just a simple `alpha` animation, set the interpolator as `accelerat_interpolator`, repeatCout as `infinite` and repeatMode as `reverse` making the animation more like a real respiration. I set the duration as `1000` which is equals to **1** second, due to the repeatMode-reverse, the total duration of a respiration cycle is **2** seconds, closer to the earthborn's breath cycle.


To start breathing, we should load the animation in the java source file, using `AnimationUtils` to load the animation, and call the method `startAnimation(animation)` of `ImageView`.

```java
	mImageView = (ImageView) rootView.findViewById(R.id.iv_lamp);
	Animation animation = AnimationUtils.loadAnimation(getActivity(), R.anim.respiration_lamp);
	mImageView.startAnimation(animation);
```

Now we can run the application to get the result.

# Effect
![Effect](/assets/images/android/respiration_lamp.gif "The effect")

# Source code
[Respiration Lamp](https://github.com/lofei117/AndroidWorks/tree/master/RespirationLamp "Respiration Lamp source code.")

