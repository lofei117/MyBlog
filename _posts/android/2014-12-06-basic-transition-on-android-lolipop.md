---
layout: post
title: "Basic Transition on Android Lolipop"
description: "Basic Transition using Scene on Android Lolitop"
category: "android"
tags: ["android", "android transition", "android lolitop"]
---
{% include JB/setup %}

# Foreword
好久没有写博客了，究其原因是好久没有好好学习，没有好好深入研究代码的实现云云。拖延症云云屁话不提。
Android Lolipop出来有一阵了，不能老啃着`targetSdkVersion=14`, `minSdkVersion=9`过一辈子吧，不然又有一股兼容IE6既视感。
本来是准备用英文写的，出于很多稀奇古怪的原因（譬如说用老外的语言把老外做的东西转述一遍，总有点做无用功并且显摆的感觉，而且可能还语病百出）不提，还是踏踏实实用中文吧。用什么语言是其次的，内容才是关键。

# Scene Animation
Android介绍一共有三种Animation，分别是：

>
> * `Property Animation`
> * `View Animation` 
> * `Drawable Animation`
>

`Property Animation` 属性动画的从HoneyComb 3.0（Api Level 11）开始支持，主要特征为实时改变对象的属性来达到动画效果，比如一个移动动画，动画的过程中物体的坐标即其当时的坐标，和现实世界的移动动画一样。

而`View Animation`则不然，`View Animation`视图动画，只是绘制出动画过程中物体所在的位置，而物体的实际坐标并没有发生改变。这一点在我们点击移动过程中的物体便可以发现差异：当物体A 从 X 点通过动画移动到 Y 点时，其物理位置仍然处于 X 点，和 **所见即所得** 相违背。

`Drawable Animation`绘图动画允许你加载组图片资源来构建一个动画，即逐帧动画。逐帧动画是最传统最古老的动画实现方式了。

Scene Animation （场景动画）其实并不是一个严格意义上的动画机制，只是一个动画表现形式。即从场景 A 变化到场景 B 时所呈现出来的动画效果。其底层实现是通过 Animator，即`Property Animation`实现的。
本文标题写的是BasicTransiton on Lilitop，事实上在4.0Kitkat的时候就已经支持该动画了。

# Animation Effect
<video id="video" controls="" preload="none" poster="" width="320" height="480">
  <source id="mp4" src="/assets/movies/BasicTransition.mp4" type="video/mp4" />
</video>

# Realization
初看这个效果，按照以前的实现方式，移动的整个部分只有一个静态布局。在点击各个 RadioButton 之后启动一个 translate 的动画，改变三个按钮的坐标或大小达到新的布局效果。使用`Property Animation`实时改变或者使用`View Animation`绘制动画完成之后重设坐标。实现起来并不难，缺点是需要针对每一个元素单独设置动画，会有一系列坐标和形状计算等繁琐操作。

视屏中从场景1切换到场景2时，三个元素发生了位置移动，我们会按照如下步骤来实现：

* 1：为各元素定义动画的xml文件，动画类型为translate
* 2：通过AnimationUtil为各元素分别加载对应的Animation实例
* 3：调用各元素的startAnimation方法

或者：

* 1：使用一个共有的ValueAnimator计算动画系数
* 2：在ValueAnimator的回调方法中动态计算并设置各元素的坐标

使用Scene Animation让这一切变得很简单。只需定义对应的1、2、3、4四个场景，在场景中设定好对应元素的坐标和大小，剩下的一切交给`TransitionManager`来完成。这一点很像Flash中的补间动画的形状渐变，定义起始点A的坐标和形状和结束点A1的坐标和形状，期间的所有操作则无需关心。

来看一下代码实现：

xml布局代码

```xml
// 主场景
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="com.example.android.basictransition.BasicTransitionFragment">

    <RadioGroup
        android:id="@+id/select_scene"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:orientation="horizontal">

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/scene"/>

        <RadioButton
            android:id="@+id/select_scene_1"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:checked="true"
            android:text="@string/scene_1"/>

        <RadioButton
            android:id="@+id/select_scene_2"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/scene_2"/>

        <RadioButton
            android:id="@+id/select_scene_3"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/scene_3"/>

        <RadioButton
            android:id="@+id/select_scene_4"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/scene_4"/>

    </RadioGroup>

    <FrameLayout
        android:id="@+id/scene_root"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1">

        <include layout="@layout/scene1"/>

    </FrameLayout>

</LinearLayout>

// Scene1
<RelativeLayout
    android:id="@+id/container"
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <View
        android:id="@+id/transition_square"
        android:layout_width="@dimen/square_size_normal"
        android:layout_height="@dimen/square_size_normal"
        android:background="#990000"
        android:gravity="center"/>

    <ImageView
        android:id="@+id/transition_image"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@id/transition_square"
        android:src="@drawable/ic_launcher"/>

    <ImageView
        android:id="@+id/transition_oval"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:layout_below="@id/transition_image"
        android:src="@drawable/oval"/>
</RelativeLayout>

// Scene2
<RelativeLayout
    android:id="@+id/container"
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <View
        android:id="@+id/transition_square"
        android:layout_width="@dimen/square_size_normal"
        android:layout_height="@dimen/square_size_normal"
        android:layout_alignParentBottom="true"
        android:background="#990000"
        android:gravity="center"/>

    <ImageView
        android:id="@+id/transition_image"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:layout_alignParentRight="true"
        android:src="@drawable/ic_launcher"/>

    <ImageView
        android:id="@+id/transition_oval"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:layout_centerHorizontal="true"
        android:src="@drawable/oval"/>

</RelativeLayout>

...其他Scene...

```

Java 代码

```java

public class BasicTransitionFragment extends Fragment
        implements RadioGroup.OnCheckedChangeListener {

    // We transition between these Scenes
    private Scene mScene1;
    private Scene mScene2;
    private Scene mScene3;

    /** A custom TransitionManager */
    private TransitionManager mTransitionManagerForScene3;

    /** Transitions take place in this ViewGroup. We retain this for the dynamic transition on scene 4. */
    private ViewGroup mSceneRoot;

    public static BasicTransitionFragment newInstance() {
        return new BasicTransitionFragment();
    }

    public BasicTransitionFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_basic_transition, container, false);
        assert view != null;
        RadioGroup radioGroup = (RadioGroup) view.findViewById(R.id.select_scene);
        radioGroup.setOnCheckedChangeListener(this);
        mSceneRoot = (ViewGroup) view.findViewById(R.id.scene_root);


        // A Scene can be instantiated from a live view hierarchy.
//        mScene1 = new Scene(mSceneRoot, (ViewGroup) mSceneRoot.findViewById(R.id.container));
        mScene1 = Scene.getSceneForLayout(mSceneRoot, R.layout.scene1, getActivity());

        // You can also inflate a generate a Scene from a layout resource file.
        mScene2 = Scene.getSceneForLayout(mSceneRoot, R.layout.scene2, getActivity());


        // Another scene from a layout resource file.
        mScene3 = Scene.getSceneForLayout(mSceneRoot, R.layout.scene3, getActivity());


        // We create a custom TransitionManager for Scene 3, in which ChangeBounds and Fade
        // take place at the same time.
        mTransitionManagerForScene3 = TransitionInflater.from(getActivity())
                .inflateTransitionManager(R.transition.scene3_transition_manager, mSceneRoot);


        return view;
    }

    @Override
    public void onCheckedChanged(RadioGroup group, int checkedId) {
        switch (checkedId) {
            case R.id.select_scene_1: {

                // You can start an automatic transition with TransitionManager.go().
                TransitionManager.go(mScene1);

                break;
            }
            case R.id.select_scene_2: {
                TransitionManager.go(mScene2);
                break;
            }
            case R.id.select_scene_3: {

                // You can also start a transition with a custom TransitionManager.
                mTransitionManagerForScene3.transitionTo(mScene3);

                break;
            }
            case R.id.select_scene_4: {

                // Alternatively, transition can be invoked dynamically without a Scene.
                // For this, we first call TransitionManager.beginDelayedTransition().
                TransitionManager.beginDelayedTransition(mSceneRoot);
                // Then, we can just change view properties as usual.
                View square = mSceneRoot.findViewById(R.id.transition_square);
                ViewGroup.LayoutParams params = square.getLayoutParams();
                int newSize = getResources().getDimensionPixelSize(R.dimen.square_size_expanded);
                params.width = newSize;
                params.height = newSize;
                square.setLayoutParams(params);

                break;
            }
        }
    }

}

```





