
# Project Progress

This document is a complement to the [Project Plan](plan.md.html)
page.  That one documents what work needs to be done, while this
one documents what work has been done.

Although it is possible to see what work has been done by reading
the git commit log, that would be long and tedious; this is at a
much higher level.

## Development environment

This project has a handy building and testing environment written
in the same language as the project itself ([literate
coffeescript](http://coffeescript.org/#literate)).  This means that
all code in the entire repository is in one language!

That building and testing environment does all this:
 * builds [the app itself](../app/index.html)
   (which is currently a stub, but the compilation
   process compiles and minifies all code, with source maps)
 * builds [a test app](../testapp/index.html)
   for developers (not just a stub; see [below](#test-app))
 * builds all documentation pages
   (see `doc` folder in navigation bar on the right)
 * creates annotated web pages for all source code files
   (see `src` folder on right)
   which are actually readable because the source language is
   literate
 * runs all unit tests and formats their results for reading online
   (see `test` folder on right)
   and cross-links code pages with test result pages

For more information, see:
 * [How to start using the build tools](
   index.md.html#getting-started) (uses [node](nodejs.org))
 * [The build utilities](buildutils.litcoffee.html)
 * [The cake script that uses those utilities](cake.litcoffee.html)
   (or see [what cake is](http://coffeescript.org/#cake))

## DOM Enhancements

This project will be a math word processor that can check a
student's work.  We already have [a desktop app that does this](
lurchmath.org), but this project is a rewrite of that software for
the web.

One of the major needs is a good word processing environment in a
web page.  Content-editable DIVs will not cut it, so we will need
to build a word processor from scratch, including handling keyboard
and mouse events and simulating a cursor.  This will require adding
a lot of sophistication to the DOM API.

So far the following has been accomplished on this front:
 * [Addressing](domutils.litcoffee.html#address) and
   [indexing](domutils.litcoffee.html#index) functions have been
   added to DOM Nodes.
 * Such nodes can also be [serialized](
   domutils.litcoffee.html#serialization) (and unserialized) for
   storage; this will enable saving an entire document, as well as
   copying and pasting portions, and saving an undo/redo stack
 * Every edit of the DOM tree using normal methods of the Node
   prototype now generate [change events](
   domeditaction.litcoffee.html), which get listened to
   by a [tracker](domedittracker.litcoffee.html), which keeps a
   stack of them.  The actions have undo/redo capability, making it
   possible to undo down/redo up that stack.

## Word Processing

All of the above tools will eventually be used to build a word
processor in a webpage, then add features to it supporting
mathematical meaning and the validation thereof.  Those features
are still several steps away, but the [LurchEditor](
lurcheditor.litcoffee.html) class already exists.

So far its only features are that it ensures that each DOM node
within the DIV over which it has charge gets assigned a unique id,
for distinguishing them and allowing them to reference one another.

## Test app

All features of the word processing environment that *are* built
are available in the test app, and can (unsurprisingly) be tested
there.  Furthermore, the test app remembers the history of
commands that the user executed, and lets the user do all of the
following things.
 * add comments documenting the tests they're performing
 * mark the results of those commands as correct/incorrect
   (i.e., find and identify bugs)
 * save test histories into the repository for use in automated
   unit testing

For detailed documentation on the test app, visit
[its help page](test-app-help.md.html) or
[the test app itself](../testapp/index.html) (which, of course,
also contains a link to its help page).

## More to come

To see detailed plans for how this project will proceed from its
current state, see the [Project Plan](plan.md.html).

