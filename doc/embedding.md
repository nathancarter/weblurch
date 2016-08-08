
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
 1. Include in the page or blog the script at
    [this URL](http://nathancarter.github.io/weblurch/app/lurch-embed-solo.min.js).
    Just paste this line at the top of your webpage, or in the scripts
    list for your blog:
```html
<script src='http://nathancarter.github.io/weblurch/app/lurch-embed-solo.min.js'></script>
```
 2. Create blocks (such as DIVs) with the class "lurch-embed" and place into
    them the content you care about.  You can do this by simply pasting HTML
    content copied directly from the Lurch app itself, or by writing
    [Lurch shorthand](../app/main-app-import-export-solo.litcoffee#lurch-shorthand).
```html
<div class='lurch-embed'>
    <p>Here is a Lurch document with two paragraphs, but no expressions.</p>
    <p>To see how to embed expressions, check out the examples below.</p>
</div>
```

## Examples

Here is an example ([view
live](http://nathancarter.github.io/weblurch/test/embedding/embed-test.html),
[view source](../test/embedding/embed-test.html)) of embedding a very tiny
Lurch document into a webpage.  That page uses the method in which raw Lurch
HTML is pasted directly into the page source, which is not very
human-readable.

Here is an example ([view
live](http://nathancarter.github.io/weblurch/test/embedding/shorthand-test.html),
[view source](../test/embedding/shorthand-test.html)) of embedding two
different smallish documents into the same webpage using Lurch shorthand,
which is much more human readable.  (Follow the link in the previous section
for instructions on how to write Lurch shorthand.)
