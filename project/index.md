---
layout: page
title: "Projects page"
description: "Projects"
---
{% include JB/setup %}

<div class="posts">
    <div class="posts-item main-index">
        {% for post in site.posts %}
        {% if post.category == "Project" %}
        <article class="post">
            <div class="meta">
                <div class="date">
                    <time datetime='{{ post.date | date_to_utc | date: "%Y-%m-%d" }}' data-updated="true" itemprop="datePublished">{{ post.date | date_to_utc | date: "%Y-%m-%d" }}</time>
                </div>
                {% unless post.tags == empty %}
                <div class="tags">
                    {% assign tags_list = post.tags %}
                    {% include JB/tags_list %}
                </div>
                {% endunless %}
            </div>
            <h1 class="title"><a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></h1>
            <div class="markdown-body">
                {% if post.content contains "<!-- more -->" %}               
                    {{ post.content | split:"<!-- more -->" | first % }}              
                {% else %}                
                    {{ post.content | truncatewords:100 }}               
                {% endif %}     
                <a href="{{post.url}}" class="more-link">Continue Reading &rarr;</a>       
            </div>    
        </article>
        {% endif %}
        {% endfor %}
    </div>
</div>