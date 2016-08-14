
# Embedding Lurch in a website or blog

## Overview

When writing a web page or blog about introductory proofs, or about Lurch
itself, authors will want to show examples of small documents in a live
Lurch application.  Validation will be functioning and showing its results,
and users can explore the example interactively as well, possibly even
experimenting and/or making changes. We call this *embedding* Lurch in a web
page or blog.

## How To

The author must do two things to embed Lurch in a blog/website:

 * Include this code at the top of your webpage, or in the scripts list for
   your blog:
```html
<script src='http://nathancarter.github.io/weblurch/app/lurch-embed-solo.min.js'></script>
```
 * Create DIVs (or other blocks) with the class "lurch-embed" and place into
   them your content.  You can directly paste content copied directly from
   the Lurch web app, or you can write in
   [Lurch shorthand](https://github.com/nathancarter/weblurch/app/main-app-import-export-solo.litcoffee#lurch-shorthand).
```html
<div class='lurch-embed'>
    <p>Here is a Lurch document with two paragraphs, but no expressions.</p>
    <p>To see how to embed expressions, check out the examples below.</p>
</div>
```

## Examples

 1. Embedding a very tiny Lurch document into a webpage by pasting raw Lurch
    HTML directly into the page source (not very human-readable).
     * [Live view](http://nathancarter.github.io/weblurch/test/embedding/embed-test.html)
     * [Source code](https://github.com/nathancarter/weblurch/test/embedding/embed-test.html)
 1. Embedding two different (small) documents into the same webpage, and
    writing each in Lurch shorthand (more human-readable).
    See link above for instructions on writing in Lurch shorthand.
     * [Live view](http://nathancarter.github.io/weblurch/test/embedding/shorthand-test.html)
     * [Source code](https://github.com/nathancarter/weblurch/test/embedding/shorthand-test.html)
 1. The example HTML code above produces the embedded Lurch document shown
    below.

<div class='lurch-embed'>
    <p>Here is a Lurch document with two paragraphs, but no expressions.</p>
    <p>To see how to embed expressions, check out the examples below.</p>
</div>
