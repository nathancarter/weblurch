
# Project Overview

## Current state of *Lurch*

Lurch is a math-enabled word processor that can check the reasoning in a
user's document, including mathematical proofs.  The current version is [a
desktop app](http://lurchmath.org).  The purpose of this project is to move
it to the web.

## Future plans

Moving to the web requires implementing a meaning-enabled word processor in
the browser.  This will be done by choosing a well-established foundation
(probably [TinyMCE](http://www.tinymce.com/), or possibly [CKEditor](
http://ckeditor.com/)) and building meaningful mathematical content on top
of it.  This is very similar to how the desktop version of *Lurch* took a
word-processor widget from [the Qt Project](http://qt-project.org/) and
added a layer of meaning on top.

The project comes in roughly the following *five phases,* although you can
read much more details about these on the [Progress Page](progress.md) (what
has been done so far) and the [Plan Page](plan.md) (what still must be
done).
 1. Foundation - Add to a TinyMCE or CKEditor interface the ability to load
    and save files to the browser's local storage.  *This is complete.
    It can be used in many other projects, not just Lurch.*
 1. Basement - Add a layer of meaning on top of the plain editor.  In the
    desktop version of the software, this shows up as "bubbles," a UI
    familiar to anyone who has used Word's Equation Editor
    or [LyX](http://wiki.lyx.org/) or [the current version of *Lurch*](http://lurchmath.org/wordpress-temp/wp-content/uploads/2012/03/mathfest-2013-gcps.pdf).
    *This is complete.  It can be used in many other projects, not just
    Lurch.  Watch this space for links to a tutorial, coming soon.*
 1. Lobby - Add tools for mathematical typesetting.  These might be done
    with [MathQuill](http://mathquill.com/) or
    [MathJax](http://www.mathjax.org/), [as in the desktop
    version](https://www.youtube.com/watch?v=xvVz0xdqi-8).
    *This is not yet built, but others ([1](
    https://github.com/foraker/tinymce_equation_editor), [2](
    http://ckeditor.com/addon/mathjax), [3](
    https://github.com/rikuhaa/mathedit), [4](
    https://github.com/efloti/plugin-mathjax-pour-tinymce)) have built
    similar plugins already.  This item could be done at this point, or
    earlier or later; it is somewhat orthogonal to the rest.*
 1. Guest rooms - Add a facility for easy background processing of document
    content.  This allows developers to extend the version with useless
    bubbles to a version in which the bubbles can be used for any of a wide
    variety of results.  *This is in process.  Note that when it is
    complete, it can be used in many projects, not just Lurch.*
 1. Penthouse suite - Apply the previous layer to the specific needs of
    *Lurch*, adding dependencies, meaning, rules, etc.
    *This is not yet fully designed, but when it has been both designed and
    built, Lurch will have migrated from the desktop to the web.*

## What's built so far?

See the [Progress Page](progress.md) for the answer to this question.
