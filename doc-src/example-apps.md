
# Example Lurch Applications

The webLurch project is attempting to rewrite [the desktop application
Lurch](http://www.lurchmath.org/) for the web.  It is not yet complete, but
the foundational technology is progressing, and can be used in other
projects as well.  This page lists several example applications built using
the webLurch foundation.
[(See here for full developer info.)](developer.md)

## Main App

### webLurch

*(Still incomplete)*

The ongoing implementation of Lurch for the web is kept here.  It does not
check proofs yet!  It is still in the beginning phases of development.  For
software that will check the steps of students' work, [see the desktop
version](http://www.lurchmath.org).

 * [Launch the app](http://nathancarter.github.io/weblurch/app/app.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/main-app-basics-solo.litcoffee)

## Intro apps

### Simple example

Developers who want to build their own apps on the webLurch platform should
start here, because it's highly documented and extremely simple.

 * [Launch the app](http://nathancarter.github.io/weblurch/app/simple-example.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/simple-example-solo.litcoffee)

### Complex Example

Developers who want to build their own apps on the webLurch platform should
start with the Simple Example, then move to this one.

It defines two group types rather than one, and shows how to
add context menus and do lengthy background computations,
among other things.

 * [Launch the app](http://nathancarter.github.io/weblurch/app/complex-example.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/complex-example-solo.litcoffee)

## Demo apps

### Math Evaluator

Developers learning the Lurch web platform should start with [the Intro
apps](#intro-apps) above, then try "Demo" apps.

This one lets users wrap any typeset mathematical expression in a bubble and
ask the app to evaluate it or show its internal structure.

 * [Launch the app](http://nathancarter.github.io/weblurch/app/math-example.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/math-example-solo.litcoffee)

### OMCD Editor

Developers learning the Lurch web platform should start with [the Intro
apps](#intro-apps) above, then try "Demo" apps.

This app that lets you write an [OpenMath Content
Dictionary](http://www.openmath.org/cd/) in a user-friendly word processor,
then export its raw XML for use elsewhere. This is a specific example of an
entire category of apps for editing hierarchically structured meanings.

 * [Launch the app](http://nathancarter.github.io/weblurch/app/openmath-example.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/openmath-example-solo.litcoffee)

### Code Editor

Developers learning the Lurch web platform should start with [the Intro
apps](#intro-apps) above, then try "Demo" apps.

This app lets users insert boilerplate code from a simple programming
language (with only one kind of if and one kind of loop, and a few other
statements) using groups and text within them as comments.  Thus the user
"codes" in their own native language, and the app translates it into one of
a few sample languages in a sidebar.  JavaScript code can then be executed
if the user desires.

 * [Launch the app](http://nathancarter.github.io/weblurch/app/sidebar-example.html)
 * [View source code file 1](https://github.com/nathancarter/weblurch/blob/master/app/sidebar-example-solo.litcoffee) and [file 2](https://github.com/nathancarter/weblurch/blob/master/app/sidebar-example-defs-solo.litcoffee)

### Lean UI

Developers learning the Lurch web platform should start with [the Intro
apps](#intro-apps) above, then try "Demo" apps.

This is the most complex demo; try one of the others to start.

It lets users interact with the theorem prover
[Lean](https://leanprover.github.io) in a word-processing environment with
nice visual feedback.

 * [Read the tutorial](lean-example/tutorial-1.md)
 * [Launch the app](http://nathancarter.github.io/weblurch/app/lean-example.html)
 * [View source code](https://github.com/nathancarter/weblurch/blob/master/app/lean-example-solo.litcoffee)
