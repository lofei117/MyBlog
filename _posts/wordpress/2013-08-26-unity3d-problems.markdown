---
author: lofei117
comments: true
date: 2013-08-26 04:07:33+00:00
layout: post
slug: unity3d-problems
title: unity3d学习问题总结
wordpress_id: 549
categories:
- Unity3D
- 错误总结
tags:
- unity3d
- 错误总结
---

# 前言：


学习的时候总会碰到各种问题，经常就是各种搜索、看文档甚至问别人什么的来解决。运气好的时候马上就能搞定，运气不好的时候一个问题得纠结两三天。还有时候甚至是同样的问题第二次还得纠结两三天，细想想来自己没有好好做总结没有记录是导致这种情况发生的罪魁祸首。

那么，是该写一篇博客来总结了。每次碰到问题就在这里加上，解决了就在问题后面附上解决方案，这样子之后如果在遇到找起来就方便多了。





* * *






## Problem：


1：The animation state *** could not be played because it couldn't be found!

这个问题困扰我两天了，官方文档以及教程看了半天没找到答案，然后自己瞎琢磨也没整明白。一直以为是代码或者某个地方设置的问题。好吧承认自己愚昧，居然没有去用搜索引擎搜索。今天才百度了一下，在某君的百度空间里找到解决方案。


## Solution：


原因是在导入模型动画的时候没有设置导入选项，在Rig选项中应该将Animation Type设置为Legacy（事实上Unity3d的warning中就提到动画片段不是Legacy，我却一直无视这warning……），然后下面的Generation选择合适的，我选的是Store In Root(New)这个。

改完之后Apply一下。重新运行，OK.

原文链接：[http://hi.baidu.com/next2_me/item/af74cf873eeab0c098255fc8](http://hi.baidu.com/next2_me/item/af74cf873eeab0c098255fc8)





* * *






## Problem：


2：Unity3D生成Android程序安装完后再安卓环境中渲染不完全、闪烁以及有重影问题

这个问题当时也困扰了我几天，一直以为是代码的问题，但是只有几行代码，是不会涉及到渲染优化等问题的。而u3d自带的angrybots以及网上下的一些demo却没有问题。我自己开始写的两个小应用，一个在同学的三星手机上运行没有问题，一个渲染不完全，而在我自己的小米手机1S青春版（我一直管它叫小米手机1s屌丝版）上运行，不仅渲染不完全，还有重影闪烁，体验相当糟糕。


## Solution：


在File-Build Settings-PlayerSettings-Resolution and Presentation里取消Use-32-bit-Display-Buffer的勾，选上Use-24-bit-Depth-Buffer，然后在Other Settings里将Graphics Level选用OpenGL ES 1.x

现在市面上安卓手机鱼龙混杂，设备良莠不齐（也不得不吐槽小米自己所谓的牛逼其实隐藏了很多未知的弊端，毕竟一分钱一分货了），真是个很蛋疼的问题。

找到的百度文库原文链接：[http://wenku.baidu.com/view/8140d30a59eef8c75fbfb33f.html](http://wenku.baidu.com/view/8140d30a59eef8c75fbfb33f.html)





* * *





## 




## Problem:


3:Unity3D在Android平台下无阴影效果

这个问题是Unity3D本身的原因，在standalone里可以正常显示阴影，但是在android平台下不行。也不算问题，不过当时不知道困扰了一会。


## Solution：


尚未解决，应该是有其他方案来实现实时阴影特效的，如果是静止的就用lightmapping烘焙（虽然我还不知道这个怎么用）。





* * *





## 




## Problem：


4：Unity3D自带的character controller针对碰撞检测OnCollisionEnter的问题

在Unity3D中人物与普通物理引擎不同，不接受普通物理引擎反应，不能跟普通的物理一视同仁。

好吧其实这个问题很水。


## Solution：


使用OnControllerColliderHit来检测碰撞，不过这个函数不是碰撞的时候才调用一次，而是只要跟人物发生接触就会一直触发。





* * *





## 




## Problem：


5：Unity3D中相机清楚标志Clear Flags选择Depth Only或者Don't Clear时Game View显示问题

具体原因未知，效果如图所示。


## [![Unit3d图像缓存](/assets/images/2013/08/QQ截图20130907223259.png)](/assets/images/2013/08/QQ截图20130907223259.png)




## Solution:


改成Solid Color或者Skybox就好，但是这样的话如果多重相机，该相机如果用来显示仪表盘，要是静态的图片还好，如果仪表盘需要更新估计会有问题。





* * *





##




## Problem:


6:在使用Unity3D自带的NavMeshAgent的时候遇到的问题，人物无法在高度差的对象网格之中自动寻路。


## Solution：


如果在烘焙对象时使用了OffMeshLink，绑定了NavMeshAgent组件的对象的walkable层需要包括jump层。



关于如何使用Unity3D的NavMeshAgent，可以参考[http://liweizhaolili.blog.163.com/blog/static/16230744201271161310135/](http://liweizhaolili.blog.163.com/blog/static/16230744201271161310135/)

以及Unity3D官方的例子。[http://pan.baidu.com/s/1ceyzO ](http://pan.baidu.com/s/1ceyzO)

在阿赵的博文之中，并没有提到我这里遇到的问题。 阿赵大概是选择了Everything的Layer选项，而我则只是有选择的选择了烘焙的Layer，并没有勾选jump层，所以遇到些问题。

下面是官方的说明：


_    The NavMeshLayer assigned to auto-generated off-mesh links, is the built-in layer Jump. This allows for global control of the auto-generated off-mesh links costs (see [Navmesh layers](http://docs.unity3d.com/Documentation/Components/class-NavMeshLayers.html))._


以及NavMeshAgent组件的Auto Traverse Off Mesh Link选项，如果不勾选的话仍然无法进行高度寻路。 看了官方的Demo是的确把这个选项去掉的，但是勾选也不影响它的运行（正常爬楼梯），但是如果不勾选的话，默认是无法进行寻路的。 看了下官方的动画是位移动画，猜想可能这个会影响。还有待考证。
