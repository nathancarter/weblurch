
# Project Overview

## What is Lurch now?

Lurch is a math-enabled word processor that can check the reasoning
in a user's document, including mathematical proofs.  The current
version is [a desktop app](http://lurchmath.org).  The purpose of
this project is to move it to the web.

## What's the plan?

Doing so requires implementing a meaning-enabled word processor in
the browser.  For a variety of reasons I won't go into here, just
setting a div as content-editable causes great problems.  Therefore
it is necessary to implement the word processor from the ground up,
writing our own display, editing events, keyboard and mouse
handling, and so on.  This is slow, but gives great power and
control in the long run.

Thus the project comes in roughly the following *four phases,*
although you can read much more details about these on the
[Progress Page](progress.md.html) (what has been done so far) and
the [Plan Page](plan.md.html) (what still must be done).
 1. Basement - Build ways to monitor and respond to edits in the
    DOM, undo/redo them, combine them, etc.
    *This has been built and unit tested.*
 1. Lobby - Build keyboard and mouse handlers that perform DOM
    edits, including cursor movements, selection, typing,
    formatting, copy, paste, etc.
    *This is not yet built, but when it is, there will be a
    full word processor in the browser.  It will not be
    Lurch-specific, in that it could easily be re-used for another
    project.*
 1. Guest rooms - Add "smart characters" to the word processor,
    that is, custom objects that sit in a paragraph like a single
    (perhaps very large) character, but have a different purpose
    (e.g., images, equations, invisible groupers).  Add background
    processing threads that can deal with the semantics of these
    custom objects.
    *This is not yet built, but when it is, the Lurch word
    processor will become powerful enough to handle a wide variety
    of non-Lurch tasks, including many kinds of meaningful
    documents, like various computational tools.*
 1. Penthouse suite - Apply the previous layer to the specific
    needs of Lurch, building validation, rules, properties, etc.
    *This is not yet built, but when it is, Lurch will have
    migrated from the desktop to the web.*

## What's built so far?

Always check with the [Progress Page](progress.md.html) to see the
answer to this question.

Also, [the test app](../testapp/index.html) is the most advanced
product in this repository at the moment, and the help link on its
page can tell you how to use it, if you're a developer or tester.

