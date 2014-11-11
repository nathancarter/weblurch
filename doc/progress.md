
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

## More to come

To see detailed plans for how this project will proceed from its
current state, see the [Project Plan](plan.md).
