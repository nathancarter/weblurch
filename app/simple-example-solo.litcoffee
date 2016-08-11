
# Simple Example webLurch Application

## Overview

This explanation assumes that you  want to build an application in the Lurch
Web Platform (LWP).  [(What's the LWP?)](../README.md)

This file shows how to build an extremely simple application (like a "hello
world") in the LWP.  [See a live version of the result
here.](http://nathancarter.github.io/weblurch/app/simple-example.html)

Two files make up this example.  This one is more important.  The other is
[simple-example.html](simple-example.html), which is almost entirely
boilerplate code (as commented in its source), plus one line that imports
the compiled version of *this* file.

To make your own app, you will also need two files.
 * Make a copy of this file and modify its code to suit your needs.  Run
   the [CoffeeScript](http://www.coffeescript.org) compiler on it to
   generate JavaScript.
 * Make a copy of `simple-example.html`, and change one (clearly marked)
   line to import your generated JavaScript.

Now begins the code that defines this simple application. After this file,
you can [examine other examples](
http://nathancarter.github.io/weblurch/app/index.html).

## Set the app name

The LWP provides a single function to set the app name.  Call it like so.
The app name appears in the browser's/tab's title bar.

    setAppName 'ExampleApp'

## Add a help menu item

We want the app itself to link to this documented source code file, so that
users who stumble upon the app can easily find its documentation.

    addHelpMenuSourceCodeLink 'app/simple-example-solo.litcoffee'

We also change the Help/About menu item to be specific to this demo app.

    window.helpAboutText =
        '<p>See the fully documented <a target="top"
        href="https://github.com/nathancarter/weblurch/blob/master/app/simple-example-solo.litcoffee"
        >source code for this demo app</a>.</p>'

## Define one group type

We assign to a global variable the array of group types we'd like to have in
our word processor.  The LWP setup process looks for this global variable,
and, if it exists, respects its settings.  If it does not exist, a very
simple default setup is used instead.

In this case, we will make the array have length one, as we are adding just
one type.  You will see it show up as a button on the app's toolbar with an
icon that looks like two brackets, `[ ]`, because such an icon will be
generated from the `imageHTML` attribute provided below.  The open and close
variants are used in the document to delimit group boundaries.

    window.groupTypes = [
        name : 'reporter'
        text : 'Simple Event Reporter'
        imageHTML : '[ ]'
        openImageHTML : '['
        closeImageHTML : ']'

The `tagContents` function is called on a group whenever that group is about
to have its bubble drawn, and the result is placed in the bubble tag.  This
function should be fast to compute, since it will be run often.  Usually it
just reports the (stored) results of previously-executed computations.

In this app, bubble tags are very simple:  They report how many characters
are in the group.

        tagContents : ( group ) ->
            "#{group.contentAsText()?.length} characters"

The `contentsChanged` function is called on a group whenever that group just
had its contents changed.  The `firstTime` parameter is true when the group
was just constructed, and false every time thereafter; if an app needs to do
any particular initialization of newly constructed groups, it can check the
`firstTime` parameter and respond accordingly.

In this simple app, we just write to the browser console a notification that
the group's contents have changed.  Open your browser console to see
notifications stream by as you type inside a "reporter" group.

        contentsChanged : ( group, firstTime ) ->
            console.log 'This group just changed:', group.contentAsText()

The `deleted` function is called on a group immediately after it has been
removed from the document (for example, by the user deleting one or both of
its endpoints).  The group does not exist in the document at the time of
this function call.  Any finalization that may need to be done could be
placed in this function.  Because it is run in the UI thread, it should be
relatively fast.

In this simple app, we just write to the browser console a notification that
the group was deleted.  Open your browser console to see notifications
appear whenever you delete a "reporter" group.

        deleted : ( group ) ->
            console.log 'You deleted this group:', group
    ]

Functions that need to do lengthy computations can run them in the
background.  webLurch has a built-in mechanism to make this easy.  To see
how to use it, see
[the more complex example application](complex-example-solo.litcoffee),
one of the [many examples](
http://nathancarter.github.io/weblurch/app/index.html) available.
