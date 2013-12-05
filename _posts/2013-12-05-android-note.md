---
layout: post
title: "android note"
description: "record some errors or mistakes, as well as experiences I got when developing android apps."
category: "android"
tags: [android]
---
{% include JB/setup %}

##Custom Theme Style   
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

I've got a mistake that I copied the code from somewhere which the parent is not right. 
Wrap you head that ``parent="android.Theme.Holo"`` is not right. If you want to use the pre-defined theme, make sure that the value of `parent` should start with `@android:style/`.


