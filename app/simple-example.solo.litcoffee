
# Simple Example webLurch Application

## Overview

webLurch is first a word processor whose UI lets users group/bubble sections
of their document, with the intent that those sections can be handled
semantically.  Second, it is also a particular use of that foundation, for
checking students' proofs (not yet implemented as of this writing on the
web, only in [the desktop version](http://lurchmath.org)).  But other
applications could be built on the same foundation, not just proof-checking.

This file shows how to make an extremely simple application of that type.
Consider it the "hello world" of webLurch application development.

This file is the more important of two files that make up the example
application.  The other is [simple-example.html](simple-example.html), which
is almost entirely boilerplate code (as commented in its source), plus one
line that imports the compiled version of this file.

You can [see a live version of the resulting application online now](
http://nathancarter.github.io/weblurch/app/simple-example.html).

## Specify the app name

We make one global function call to change the app name, which appears in
the browser's/tab's title bar.

    setAppName 'ExampleApp'

## Define one group type

We assign to a global variable the array of group types we'd like to have in
our word processor.  The setup routine for the webLurch application will
look for this global variable, and if it exists, respect its settings.  If
it does not exist, a very simple default setup is used instead.

In this case, we will make the array have length one,
as we are adding just one type.

    window.groupTypes = [
        name : 'reporter'
        text : 'Simple Event Reporter'
        image : './images/red-bracket-icon.png'

The `tagContents` function is called on a group whenever that group is about
to have its bubble drawn.  Thus this function should be extremely fast to
compute, possibly even just reporting the results of previously executed
(and stored) computations.

In this case, we do a very simple example:  Just report how many characters
are in the group.

        tagContents : ( group ) ->
            "#{group.contentAsText()?.length} characters"

The `contentsChanged` function is called on a group whenever that group just
had its contents changed.  The `firstTime` parameter is true when the group
was just constructed, and false every time thereafter; if any particular
initialization of a newly constructed group of this type needed to happen,
it could check the `firstTime` parameter and behave accordingly.

        contentsChanged : ( group, firstTime ) ->
            console.log 'This group just changed:', group.contentAsText()

The `deleted` function is called on a group immediately after it has been
removed from the document (for example, by the user deleting one or both of
its endpoints).  The group does not exist in the document at the time of
this function call.  Any finalization that may need to be done could be
placed in this function.  Because it is run in the UI thread, it, too, must
be very short.

        deleted : ( group ) ->
            console.log 'You deleted this group:', group
    ]

Functions that need to do lengthy computations can run them in the
background.  webLurch has a built-in mechanism to make this easy.  To see
how to use it, see
[the more complex example application](complex-example.solo.litcoffee).
