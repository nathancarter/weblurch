
# Embedding Lurch in a website or blog

## Overview

When writing a web page or blog about introductory proofs, or about
mathematics itself, authors will want to show examples of small documents
in a live Lurch application.  It should be live so that validation is
functioning and showing its results, and so that users can explore the
example interactively as well, possibly even experimenting with changes.
We call this *embedding* Lurch in a web page or blog.

## How To

The author must do two things in order to embed Lurch in a blor or website.
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
    [Lurch shorthand](../src/main-app-import-export-solo.litcoffee#lurch-shorthand).

## Examples

[Here is an example](../test/embedding/embed-test.html) of embedding a very
tiny Lurch document into a webpage.  That page uses the method in which raw
Lurch HTML is pasted directly into the page source, which is not very
human-readable.

[Here is an example](../test/embedding/shorthand-test.html) of embedding two
different smallish documents into the same webpage using Lurch shorthand,
which is much more human readable.  (Follow the link in the previous section
for instructions on how to write Lurch shorthand.)
