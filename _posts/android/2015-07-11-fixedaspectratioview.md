---
layout: post
title: "FixedAspectRatioView"
description: "Fixed Aspect Ratio View"
category: "android"
tags: ["android"]
---
{% include JB/setup %}

# Foreword
在Android开发过程中，我们可能有需求需要将一个View对象固定为指定比例，比如4:3， 1:1之类的。一般的做法有两种，一个是预先知道宽高的值，直接在xml中给出指定的dp值，这种做法有个缺点，就是每个单独的视图都必须给定值，而对于我们并不知道宽或者高的具体值时，便很难做到。

例如一般情况下，我们希望宽等于（或者接近，因为可能会有padding）屏幕宽度，而高度根据给定的比例缩放。

所以第二种做法便是根据当前的宽/高值，根据给定的比例值动态计算另一个值。

# Realization
在Android中，我们可以重写`onMeasure`方法来重新计算宽高值，系统在布局的时候会根据相应的计算结果来重新计算，然后给视图分配出指定的宽高。

一般情况下，我们希望在xml中指定宽高比例，以及基准的边（即宽不变，高对应重新计算；或者高不变，宽重新计算）。因此，我们需要在style中声明指定的style，在xml中设置对应的值，在View的构造函数中获取指定的值，然后在`onMeasure`方法中计算。

下面我们按照这个步骤来写出一个自定义的`FrameLayout` （你可以实现自定义的各种`View`，比如`RelativeLayout`，或者`ImageView`，我个人的建议是自定义`ViewGroup`类型，推荐`FrameLayout`或者`RelativeLayout`, 这样该控件之内的其他控件都会固定在这个范围之内，同时在其他地方使用时也可直接使用）

* 1.声明自定义style
	新建一个`style_ratio_view.xml`文件，或者其他名字，也可以直接放在`style.xml`中，内容如下。

	```xml
	<declare-styleable name="FixedAspectRatioView">
        <attr name="aspectRatioWidth" format="integer" />
        <attr name="aspectRatioHeight" format="integer" />
        <attr name="fixedAspect" format="enum">
            <enum name="width" value="0"/>
            <enum name="height" value="1"/>
        </attr>
    </declare-styleable>
	```
	其中`fixedAspect`是一个枚举类型，标识需要固定的边。而其余两个是整型类型值，标识宽高比。

* 2.编写FixedAspectRatioView
	新建一个类，继承自`FrameLayout`，代码如下：

	```java 
	public class FixedAspectRatioView extends FrameLayout {

	    private static final int FIXED_WIDTH = 0;
	    private static final int FIXED_HEIGHT = 1;

	    private int mAspectRatioWidth = 0;

	    private int mAspectRatioHeight = 0;

	    private int mFixedAspect;

	    public FixedAspectRatioView(Context context) {
	        super(context);
	    }

	    public FixedAspectRatioView(Context context, AttributeSet attrs) {
	        super(context, attrs);
	        init(context, attrs);
	    }

	    public FixedAspectRatioView(Context context, AttributeSet attrs, int defStyleAttr) {
	        super(context, attrs, defStyleAttr);
	        init(context, attrs);
	    }

	    private void init(Context context, AttributeSet attrs) {
	        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.FixedAspectRatioView);

	        mAspectRatioWidth = a.getInt(R.styleable.FixedAspectRatioView_aspectRatioWidth, 0);
	        mAspectRatioHeight = a.getInt(R.styleable.FixedAspectRatioView_aspectRatioHeight, 0);

	        mFixedAspect = a.getInt(R.styleable.FixedAspectRatioView_fixedAspect, FIXED_WIDTH);

	        a.recycle();
	    }

	    @Override
	    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
	        if(mAspectRatioHeight == 0 || mAspectRatioWidth == 0) {
	            super.onMeasure(widthMeasureSpec, heightMeasureSpec);
	        } else {
	            int originalWidth = MeasureSpec.getSize(widthMeasureSpec);

	            int originalHeight = MeasureSpec.getSize(heightMeasureSpec);

	            int calculatedHeight = originalWidth * mAspectRatioHeight / mAspectRatioWidth;

	            int finalWidth, finalHeight;

	            if (mFixedAspect == FIXED_WIDTH) {
	                finalWidth = originalWidth;
	                finalHeight = calculatedHeight;
	            } else {
	                finalWidth = originalHeight * mAspectRatioWidth / mAspectRatioHeight;
	                finalHeight = originalHeight;
	            }
	            super.onMeasure(
	                    MeasureSpec.makeMeasureSpec(finalWidth, MeasureSpec.EXACTLY),
	                    MeasureSpec.makeMeasureSpec(finalHeight, MeasureSpec.EXACTLY));
	        }
	    }
	}
	```

	我们声明了对应的成员变量，并在构造方法中从xml中读取对应的值，最后在`onMeasure`方法中，根据对应的值重新计算，最后调用super方法。具体的计算可以看代码实现，比较简单，不具体赘述。

* 3.在xml中设置对应的值。
	使用也极其简单，代码如下：

	```xml
	<info.lofei.app.tuchong.widget.FixedAspectRatioView
			xmlns:app="http://schemas.android.com/apk/res-auto"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            app:aspectRatioHeight="9"
            app:aspectRatioWidth="16"
            app:fixedAspect="width">

            <ImageView
                android:id="@+id/iv_photo"
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:scaleType="centerCrop"
                android:src="@drawable/ic_dashboard"/>

    </info.lofei.app.tuchong.widget.FixedAspectRatioView>
    ```
    在这个例子中，控件的宽为填充父控件，以宽为固定边，以16:9的宽高比重新计算高度。最后我们便得到了一个宽高比为16:9的图片。

# Conclusion
这是自定义Android控件中极其简单的一个，代码也不复杂，写这边博客主要是记录，希望这些琐碎的小细节可以成为小工具，以后便可以直接调用，将时间放到构思程序的整体设计上去。

