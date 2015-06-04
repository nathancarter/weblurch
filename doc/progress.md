
# Project Progress

This document is a complement to the [Project Plan](plan.md.html) page.
That one documents what work needs to be done, while this one documents what
work has been done.

Although it is possible to see what work has been done by reading the git
commit log, that would be long and tedious; this is at a much higher level.

## Development environment

This project has a handy building and testing environment written in [the
same language as the project itself](http://coffeescript.org/#literate).

It does this:
 * builds [the app itself](../app/)
   (which is currently a stub, but the compilation process compiles and
   minifies all code, with source maps)
 * runs all unit tests and formats their results for reading online (see
   [test](test) folder)

## DOM Enhancements

So far the following has been accomplished on this front:
 * [Addressing](../src/domutils.litcoffee#address) and [indexing](
   ../src/domutils.litcoffee#index) functions have been added to DOM Nodes.
 * DOM nodes can also be [serialized](
   ../src/domutils.litcoffee#serialization) (and unserialized) for storage

## External work

I have implemented [jsfs](http://github.com/nathancarter/jsfs), a tool for
storing files in the browser's LocalStorage as if it were a filesystem.
This will be useful to import into Lurch.

## Groups/Bubbles

Groups are sections of the document that have been marked by the user as
needing special treatment (e.g., a set of symbols that should be seen as an
equation, or a paragraph that expresses a change in the application's
settings).  In [the desktop version of Lurch](http://lurchmath.org), these
were displayed as red, green, and blue bubbles in the user interface.

This project contains
[a TinyMCE plugin for Groups](../app/groupsplugin.litcoffee) that allows a
programmer to customize what types of groups the user can add to his or her
document, and how those groups behave.

## More to come

To see detailed plans for how this project will proceed from its
current state, see the [Project Plan](plan.md).
