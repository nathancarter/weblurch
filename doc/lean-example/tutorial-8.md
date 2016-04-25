
# Lean App Tutorial, Part 8

This page assumes you've read Parts [1](tutorial-1.md), [2](tutorial-2.md),
[3](tutorial-3.md), [4](tutorial-4.md), [5](tutorial-5.md),
[6](tutorial-6.md), and [7](tutorial-7.md).

The end of [Part 7](tutorial-7.md) promised a tutorial on inserting special
symbols into the document, which Lean understands.

## Symbols

Lean code can contain many Unicode characters that resemble mathematical
notation, and thus make documents more attractive.  This appliction supports
those characters, as shown in the image below.

<p align=center><img src='tut-8-ss-characters.png' width=50%/></p>

The blackboard bold N stands for the natural numbers (formerly written nat)
and the greek letter lambda stands for "fun" or "assume" in Lean.

You can enter these symbols by typing a backslash, followed by the symbol's
name, followed by the spacebar (or alternately followed by another
backslash, if you're starting another symbol immediately afterwards).  For
example, to type the first line of the document shown above, you would
proceed as follows.

 1. Click the button to start a term group.
 1. Type `check (3:\nat`.
 1. Press the spacebar, and `\nat` will be replaced by the blackboard bold
    N.
 1. Type `)`.

## Catalog

What symbols are available?  Lots!  Nearly 2,000, in fact!  But most of them
are not useful in Lean itself.  Here are three ways to get started with
keyboard shortcuts:

 1. The most important ones to know are `\and`, `\or`, `\to`, `\neg`,
    `\forall`, `\exists`, `\pi`, `\sigma`, `\lambda`, `\int`, and `\nat`.
 1. Take [the Lean tutorial](https://leanprover.github.io/tutorial/), which
    covers the keyboard shortcuts that work in Lean.  I imported the same
    data file into this web app that they use in Lean, so all shortcuts that
    work in Lean work here.
 1. If you really want to know the full list of 1,959 shortcuts, you can
    inspect [the (minified JSON) data file](https://raw.githubusercontent.com/leanprover/tutorial/master/js/input-method.js) just mentioned.

## So what?

### Benefits

Your Lean documents will now look much less computer-ish, and much more
mathematical and readable.

### Missing pieces

This is the last page of the tutorial, but surely you can think of ways that
this app could be improved.  Feel free to visit [the webLurch project GitHub
site](https://github.com/nathancarter/weblurch) and see how to fork the
project and contribute your own code.  Feel free also to contact one of the
members of the development team, through GitHub, or just open an issue.
