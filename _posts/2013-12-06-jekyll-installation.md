---
layout: post
title: "jekyll-installation"
description: "Introduce my experience of move my blog from wordpress to github-pages run through jekyll"
category: "tech"
tags: [redcarpet,jekyll]
---
{% include JB/setup %}

#Foreword

Well, I'm just moving my blog from wordpress to github these days. Jekyll is recommended as the static page generator which is also github-pages' generator.
My home page was cloned from [Jekyll-Bootstrap](https://github.com/plusjade/jekyll-bootstrap/), to be honest, it's a well-designed template to build jekyll site.

#Installation
* My operation system:
Microsoft Windows 7, 32bit.

## Install Ruby
Well, I really like Linux or Mac(I still do not have enough money to buy one.) which support commad-line installation.
To install ruby you should download two file from [Click here](http://rubyinstaller.org/downloads).

- Ruby 
- Ruby development kit.

Get more information on the site, make sure that you have download the right ruby dev-kit for you ruby.
*What I wanna tell you* is that *at first time* I downloaded **Ruby 2.0.0-p353** and **DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe**, but when I try to install jekyll with the command ```gem install jekyll```
I cannot download it, something seems error but I don't what it is. (Using bundle to install may work *sometimes*.)
As you see above I italic *at first time* and *sometimes*, the reason is that I've install and uninstall it for several times since ruby 2.0 does not work well on my tablet.
So the result is that I finally choose **Ruby 1.9.3** and **DevKit-tdm**.

## Install jekyll
You may easily use 

```
gem install github-pages
```

which would install jekyll at the same time, see [Github-Pages](https://help.github.com/articles/using-jekyll-with-pages).

Normally, just use 

```
gem install jekyll
```

I've tried both the two way, it seems no difference.

BTW. if you wanna use **bundle** to install them, GIYF, you'll get lots of information.

## Install redcarpet
If you install jekyll with github-pages, redcarpet is also installed. Otherwise, use

```
gem install redcarpet -v "2.3.0"
```

**Do not just use `gem install redcarpet` cause the latest version of redcarpet is 3.0, but the latest jekyll version is 1.3.1 which has its dependency on redcarpet 2.3.0 but not 3.0.**

**If you are reading this blog several month later, please check it yourself**

# Run the website on localhost
Till now, the introduction of installation was finished. For more information about installation and website initlization, just google it and read the github-pages documents and [Quick Start](http://www.jekyllbootstrap.com/usage/jekyll-quick-start.html). if you are using jekyll-bootstrap like me.
You can just use

```
jekyll new testBlog
```

to generate a empty website.
Then, ``cd testBlog`` into the website root directory and type

```
jekyll serve
```

Congratulations, if you doesn't get any error or warning you may see the words like

```
Configuration file: G:/Blog/lofei117.github.com/_config.yml
            Source: G:/Blog/lofei117.github.com
       Destination: G:/Blog/lofei117.github.com/_site
      Generating... done.
    Server address: http://0.0.0.0:4000
  Server running... press ctrl-c to stop.
```

you're able to see the result in your browser with the url http://localhost:4000/

If you get some error like GBK(or other coding), or some other errors, same words **GIYF**.

# Troubleshooting
It's very awesome that you've got none errors when you finish these steps at first time, even the second, the third time you also may get troubles.
Here I will write some mistake or errors that I've met.

## Wordpress to Jekyll exporters
If you have your own blog which was host on wordpress before, you may want to export those blogs and convert them to markdown file. Jekyll has its own importer.
When I was about to use the importer, I googled this, there were a lot pages telling me that there's a folder in jekyll-lib folder named *migration*, I didn't find it because Jekyll 1.3.1 removed it and make the importer as another gem fill named *jekyll-import*.
I tried to use jekyll-import to transfer the wordpress blog to markdown file by following the step on [jekyll-import](http://import.jekyllrb.com/docs/home/), but failed. I forgot the error and I'm not going to re-do this step, if you also get errors, use third-part program or scripts to do this. To recommend, I use the python script [exitwp](https://github.com/thomasf/exitwp).

## Pygments(Or Markdown converters)
Well, this is the most confused problem that I met. 
You may choose the markdown renderer by setting 

```yaml
markdown : redcarpet 
# valid choice is maruku|rdiscount|kramdown|redcarpet
```

default renderer is *marku*. If you're familiar with *github flavored markdown*, you must be like use `fenced_code_blocks` to wrap your code and highlight it. *redcarpet* does meet your needs, but there is a little difference between native GFM on github.

I've tried a lot of methods to let my jekyll environment support `fenced_code_blocks`.
like:
- install & re-install different version of `ruby`, `jekyll`, `pygments.rb`....
- try to hack the plugin code to support this function.
and as a result, I write the code 

```ruby
require 'pygments'
require 'redcarpet'

module Jekyll
  module Converters
    class Markdown < Converter
      alias old_convert convert

      def extensions
        Hash[ *@config['redcarpet']['extensions'].map {|e| [e.to_sym, true] }.flatten ]
      end

      def markdown
        @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions)
      end
  
      def convert(content)
        if @config['markdown'] == 'redcarpet2' then        
          
          content.gsub!(/(?:^|\n)```(\w*)\s*(.*?\n)```\n/m) do |text|
                cls = $1.empty? ? "text" : "#{$1}"
                #  "<div class=\"highlight\"><pre><code class=\"#{cls}\">#{$2}</code></pre></div>"                
                result = Pygments.highlight($2, :lexer => cls)   
                File.open("G:/Blog/lofei117.github.com/_cache/123.txt", 'a') {|f| f.print(result) }
                result             
              end          
          markdown.render(content) 
        else
          old_convert(content)     
        end    
      end 
    end
  end
end
```

which can mostly support the function but still has some bugs.
Here are some figures:

***The expect result with xml code:***

![correct_result1][correct_result1]

***The actual result:***

![actual_result1][actual_result1]

***The expect result with java code:***

![correct_result2][correct_result2]

***The actual result:***

![actual_result2][actual_result2]

***The actual result with plugin hooked:***

![actual_result2_plugin_hooked][actual_result2_plugin_hooked]

Well, with lots of picture and gosip, 
Below is the tips to use **fenced_code_blocks** correctly:

1: Use triple backtick \`\`\` (Normal input method of English-UK Keybord, mostly at the left side of key **1**, above **Tab**)

2: Wrap your head that to input an empty line before the start of \`\`\`, like:

```
    some words

    ``` java	
      int a=5;
    ```
```

rather than

```
    somewords
    ```java
    int a=5;
    ```
```

3: Remember to set the `markdown` as `redcarpet` in `_config.yml`

4: Add the `redcarpet` options to `_config.yml` like:

```yaml
redcarpet:
  extensions: ["no_intra_emphasis", "fenced_code_blocks", "autolink", "strikethrough", "superscript"]
```

# Conclusion
Thank you for reading this blog, wish to help you.


[correct_result1]: /assets/images/correct_result1.png "xml correct result"
[actual_result1]: /assets/images/actual_result1.png "xml actual result"
[correct_result2]: /assets/images/correct_result2.png "java correct result"
[actual_result2]: /assets/images/actual_result2.png "java actual result"
[actual_result2_plugin_hooked]: /assets/images/actual_result2_plugin_hooked.png "java plugin hooked result"
