---
layout: post
title: "Maven Publishing"
description: "Maven Publishing"
category: "android"
tags: ['android', 'gradle', 'maven']
---
{% include JB/setup %}


# Upgrade gradle to 4.6 （1）

> 下载了最新版的Android Studio之后，gradle插件版本可以升级到3.2.0，对应gradle-wrapper版本升级到4.6，与此同时，项目中一些自定义任务需要进行相关的修改，记录一下。

# 0x0 Legacy publishing
我们编写的自定义库，很多时候需要发布到maven仓库去供自己的其他工程通过maven依赖，或者供第三方直接依赖使用。通过仓库管理，可以节省掉很多文件备份、拷贝过程，也减少了之间错误发生的可能性。以及，如我上一篇文章提到的混淆，可以通过自身工程配置`consumerProguardFile`来配置混淆，不需要其他地方再单独配置。

在以前的gradle版本（我们以前用的是2.3.3），可以用`maven`插件的`uploadArchives`来发布依赖包。

```
afterEvaluate { project ->

    signing {
        required { isReleaseBuild() && gradle.taskGraph.hasTask("uploadArchives") }
        sign configurations.archives
    }

    uploadArchives {
        configuration = configurations.archives
        repositories.mavenDeployer {
            beforeDeployment {
                MavenDeployment deployment -> signing.signPom(deployment)
            }

            repository(url: getRepositoryUrl()) {
                authentication(
                        userName: getRepositoryUsername(),
                        password: getRepositoryPassword())

            }

            pom.project {
                name POM_NAME
                artifactId POM_ARTIFACT_ID
                packaging POM_PACKAGING
                description POM_DESCRIPTION
                url getRepositoryUrl()
            }

        }
    }
}

```

在升级到新版本之后，`uploadArchives`任务失效了。
在之前的版本时，通过`uploadArchives`上传仓库时，gradle的输出是这样的：
```
> Task :lib:uploadArchives 
Uploading: com/xxx/2.0.1-SNAPSHOT/maven-metadata.xml to repository remote at https://------.com/repository/maven-snapshots/
Transferring 0K from remote
Uploaded 0K
Uploading: com/xxx/maven-metadata.xml to repository remote at https://------.com/repository/maven-snapshots/
Transferring 0K from remote
Uploaded 0K

:lib:uploadArchives (Thread[Task worker for ':',5,main]) completed. Took 5.469 secs.

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.6/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 21s
189 actionable tasks: 59 executed, 130 up-to-date

```

在新版本，输出是这样的：

```
> Task :lib:uploadArchives 
Task ':lib:uploadArchives' is not up-to-date because:
  Task has not declared any outputs.
Publishing configuration: configuration ':lib:archives'

:lib:uploadArchives (Thread[Task worker for ':',5,main]) completed. Took 0.021 secs.

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.6/userguide/command_line_interface.html#sec:command_line_warnings
BUILD SUCCESSFUL in 7s
1 actionable task: 1 executed

```
看到输出里有一句`Task has not declared any outputs`，显然，升级之后，gradle认为我们没有配置任何输出，所以没有上传任何数据。
有一个解决方案是添加对应的`artifacts`，如下：
```
 uploadArchives {
        // configuration = configurations.archives
        repositories.mavenDeployer {
            beforeDeployment {
                MavenDeployment deployment -> signing.signPom(deployment)
            }

            repository(url: getRepositoryUrl()) {
                authentication(
                        userName: getRepositoryUsername(),
                        password: getRepositoryPassword())

            }

            artifacts {
                archives(file("${project.buildDir}/outputs/aar/filename.aar")) {
                    name 'artifact name'
                    type 'aar'
                }
            }


            pom.project {
                name POM_NAME
                artifactId POM_ARTIFACT_ID
                packaging POM_PACKAGING
                description POM_DESCRIPTION
                url getRepositoryUrl()
            }

        }
    }
```
前提是需要先执行`assemble`任务来生成对应的`filename.aar`文件。`archives`任务里可以使用`builtBy`来进行任务关联，表示生成对应文件的前置任务，我试了使用`assemble`任务，发现会出现循环依赖。所以只能外部调用`assemble`任务之后，再执行`uploadArchive`任务。
你一定发现`// configuration = configurations.archives`这一行被注释了的代码。我们看到等号的语句大致可以猜到，这也是配置`artifacts`的代码。
当然这其实并不是我们要讨论的重点。

# 0x1 Maven Publishing
其实早在2013年6月28号发布的gradle 1.4版本开始，就已经加了了全新的`maven-publish`插件，来支持发布maven依赖库。截止到当前最新版（5.0），已经经历了很多次修改和完善。
`publish`插件和之前的`uploadArchives`相比，支持添加不同的`publication`，此外也支持将库直接通过`publishToMavenLocal`仅发布到本地的仓库，这项功能非常有用，以往我们修改一个依赖库之后，需要上传到线上（测试网）仓库，然后在`app`工程里刷新依赖，效率及其低下，特别是还涉及到代码审核等过程，简直痛不欲生。
而有了`publishToMavenLocal`功能之后，自己调试的时候就可以先发布到本地测试，在自测通过之后，再提交审核发布到测试网仓库测试，之后再发布现网仓库。
（注：本地调试需要在`app`工程的`build.gradle`的仓库地址中添加`mavenLocal`）

话说回来，参考官方文档，我们新的发布任务是这样创建的：
```
publishing {
    publications {
        mavenPublish(MavenPublication) {
            groupId GROUP
            version VERSION_NAME
            artifactId POM_ARTIFACT_ID

            pom {
                packaging = POM_PACKAGING
                withXml {
                    asNode().appendNode('description', POM_DESCRIPTION)
                    asNode().appendNode('name', POM_NAME)
                    asNode().appendNode('url', getMavenRepositoryUrl())
                }
            }

            project.android.libraryVariants.all { variant ->
                def fileName = "${project.buildDir}/outputs/aar/${project.name}-${variant.flavorName}-${variant.buildType.name}.aar"
                if (variant.flavorName == null || variant.flavorName.isEmpty()) {
                    fileName = "${project.buildDir}/outputs/aar/${project.name}-${variant.buildType.name}.aar"
                }
                artifact(fileName) {
                    classifier variant.name
                    extension "aar"
                }
            }
        }

    }
    repositories {
        maven {
            // change URLs to point to your repos, e.g. http://my.org/repo
            url = getMavenRepositoryUrl()

            credentials {
                username getMavenRepositoryUsername()
                password getMavenRepositoryPassword()
            }
        }

    }
}

project.afterEvaluate { project ->
    publish.dependsOn("assemble")
    publishToMavenLocal.dependsOn("assemble")
}
```
和上面提到的新版`uploadArchives`一样，在发布动作之前，需要我们先执行`assemble`完成打包动作，然后也需要配置`artifact`来上传。
如果你的任务只是上传普通的`java library`的话，其实只要配置`from components.java`就行。本例中因为是上传`Android`的`aar`库，又因为我们的库里面，配置了不同的渠道和编译类型，需要将这些一并上传到同一个版本仓库中，所以使用了`project.android.libraryVariants.all`遍历指定对应的`artifact`。
此外，`packging`属性需要放到`pom`属性中配置，而其他的例如`name`, `url`等属性，需要通过`withXml.addNode`来添加。而`groupId`, `version`等属性，则是在`mavenPublish`（可指定为其他名字）的`publication`中配置。
在`app`中依赖对应的库，便可以通过如下方式来依赖：
```
debugImplementation "${GROUP}:${libraryName}:${VERSION}:debug@aar"
releaseImplementation "${GROUP}:${libraryName}:${VERSION}:release@aar"
freeReleaseImplementation "${GROUP}:${libraryName}:${VERSION}:freeRelease@aar"   // free 为渠道号
```
其实配置总体而言并无难度，主要是不熟悉就会走很多弯路，另外不同的gradle版本之间会有差异，如果版本不一样，对应的配置也是不同的。
我们项目集成时，主要遇到的几个坑就是：
* 1. `publish`插件一样不支持自动上传包，需要手动指定artifact，而且需要等`assemble`任务执行后添加；
* 2. `pom`属性添加时，`name`, `url`等属性不再支持直接通过属性设置，需要通过`asNode().appendNode`来添加；


`mavne-publish`插件支持创建不同的`publication`来上传不同的仓库，本例中并未体现，无非就是针对不同需求，再在`publications`中添加一个类似`mavenPublish`的配置。

此外，`maven-publish`插件有个缺点是，暂时不支持对`pom`文件进行签名。
> Note: Signing the generated POM file generated by this plugin is currently not supported. Future versions of Gradle might add this functionality. Please use the Maven plugin for the purpose of publishing your artifacts to Maven Central.

等后续看官方更新吧。😄

# 0x2 See Also
* [https://docs.gradle.org/4.6/userguide/artifact_management.html](https://docs.gradle.org/4.6/userguide/artifact_management.html "Legacy publishing")
* [https://docs.gradle.org/4.6/userguide/publishing_maven.html](https://docs.gradle.org/4.6/userguide/publishing_maven.html "Maven publishing")