
# Complex Example webLurch Application

## Overview

This documentation assumes that you have read [the simple example
application](simple-example-solo.litcoffee).  This app is just a few steps
more complex than that one.  Other example applications built with the LWP
are [listed here](http://nathancarter.github.io/weblurch/app/index.html).

[A live version of this app is online here.](
http://nathancarter.github.io/weblurch/app/complex-example.html)

Set the app name with the same function we used in the simple example app.

    setAppName 'ComplexApp'

Add a source code link to the help menu, as in the simple example app.

    addHelpMenuSourceCodeLink 'app/complex-example-solo.litcoffee'

We also change the Help/About menu item to be specific to this demo app.

    window.helpAboutText =
        '<p>See the fully documented <a target="top"
        href="https://github.com/nathancarter/weblurch/blob/master/app/complex-example-solo.litcoffee"
        >source code for this demo app</a>.</p>'

## Define two group types

As in the simple example, we assign to a global variable, which is noticed
by the LWP setup process and respected.  This time, we define two group
types.

    window.groupTypes = [

### Computations

The first type is groups that perform simple arithmetic computations on
their contents, decorating the ending grouper with the result.  For
instance, a group containing 3+2 would have its ending grouper contain the
text "=5."

        name : 'computation'
        text : 'Computation group'
        tooltip : 'Make selection a computation'
        color : '#996666'
        imageHTML : '<font color="#996666"><b>[ ]</b></font>'
        openImageHTML : '<font color="#996666"><b>[</b></font>'
        closeImageHTML : '<font color="#996666"><b>]</b></font>'

The tag on a bubble will either classify it as an arithmetic expression or
not.  This shows one example use of the bubble tag, as a status indicator.
The `isJustArithmetic` function is defined [at the end of this
file](#auxiliary-functions).

        tagContents : ( group ) ->
            content = group.contentAsText()
            if content? and isJustArithmetic content
                'arithmetic expression'
            else
                'unknown'

Whenever the group's contents change, we must recompute their value, if the
contents are a valid arithmetic expression.  Although such a task is nearly
instantaneous, this example app runs it in the background *and forces it to
take one second, as an example* of how a lengthy computation could be sent
to a background thread.  The background computation called "do arithmetic"
is defined [at the end of this file](#auxiliary-functions).

The `Background.addTask` function enqueues a task to be done later.  The
parameters are
 1. the name of the function to do (defined by a call to
    `Background.registerFunction`, as [below](#auxiliary-functions)),
 1. the array of groups to pass as parameters, and
 1. the callback to be called in this (main, UI) thread when the computation
    is complete.

There are situations in which that callback may never be called.  If there
is an error in your background processing code, the callback will not be
called.  If the user changes the contents of the group before the
computation completes, the background process will be discarded and a new
one initiated because the old one has become irrelevant.  In such a case,
only the callback from the second one will be called (assuming that it
completes without error or early termination).

        contentsChanged : ( group, firstTime ) ->

First, it may be that the contents changed merely because the computation
ended and we placed its result in the close grouper (as at the end of this
function).  That counts as a change to this group, but we would not want to
respond to that.  As you can see at the end of this function, we mark such
moments with a flag `doNotEvaluateAgain`, and we check that flag here.

            if group.doNotEvaluateAgain then return

We begin by placing an ellipsis as the decoration at the end of the group,
to show that computation is in progress.  Again, the computations in this
app do not *actually* take very long, but we have artificially extended them
to take one second, just as a demonstration of what might happen in more
computationally intensive contexts.

            group.set 'closeDecoration', '<font color="#999999">...</font>'

Now we enqueue the background task.

            Background.addTask 'do arithmetic', [ group ], ( result ) ->

We must always check in any callback whether the group we wish to modify
still exists in our document.  (The user may delete it in the interim, and
attempting to modify its contents would then cause errors.)

                if group.deleted or not result? then return

We can now change the decoration at the end of the group to indicate that we
have computed a value for the group, using an equals sign, and green text to
indicate success.

                safeResult = "#{result}".replace /&/g, '&amp;'
                .replace /</g, '&lt;'
                .replace />/g, '&gt;'
                .replace /"/g, '&quot;'
                .replace /'/g, '&apos;'
                safeResult = "<font color=\"#009900\">=#{safeResult}</font>"
                group.doNotEvaluateAgain = yes
                group.set 'closeDecoration', safeResult
                group.doNotEvaluateAgain = no

### Groups with menus

We now define a second group type, one that doesn't compute anything
automatically, but that allows you to ask questions about it and perform
operations on it with the context menu and/or the bubble tag menu.  This is
to demonstrate that multiple group types can exist within the same app.

    ,
        name : 'words'
        text : 'Group of words'
        tooltip : 'Make selection about words'
        color : '#669966'
        imageHTML : '<font color="#669966"><b>( )</b></font>'
        openImageHTML : '<font color="#669966"><b>(</b></font>'
        closeImageHTML : '<font color="#669966"><b>)</b></font>'

The tag on a bubble will either classify the group as something that might
be a proper name, or something that probably isn't.  The function
`mightBeAName` is defined at the end of this file.

        tagContents : ( group ) -> mightBeAName group.contentAsText()

We now provide a small popup menu that appears when the user clicks the
group's tag, and whose actions deal with that tag's content.  It returns an
array of menu items, each with text and an `onclick` handler.

        tagMenuItems : ( group ) ->
            [

The first menu item explains why the group was classified as it was on its
tag.

                text : 'Why this tag?'
                onclick : ->
                    alert "This group was classified as
                        '#{mightBeAName group.contentAsText()}' for the
                        following reason:\nText 'might be a name' if it has
                        one to three words, all capitalized.  Otherwise,
                        it is 'probably not a name.'"

The second and third items give the user the ability to change the group,
populating it with example text content that satisfies or does not satisfy
(respectively, for the two menu items) the criteria for namehood.

            ,
                text : 'Change this into a name'
                onclick : -> group.setContentAsText 'Rufus Dimble'
            ,
                text : 'Change this into a non-name'
                onclick : -> group.setContentAsText 'corn on the cob'
            ]

We also provide a context menu that the user can bring up by right-clicking
anywhere inside the group.

The two items on it count the numbers of letters or words in the group's
interior, reporting it in a popup dialog that the user must then dismiss.

        contextMenuItems : ( group ) ->
            [
                text : 'Count number of letters'
                onclick : ->
                    alert "Number of letters:
                        #{group.contentAsText().length}\n(includes spaces
                        and punctuation)"
            ,
                text : 'Count number of words'
                onclick : ->
                    alert "Number of words:
                        #{group.contentAsText().split( ' ' ).length}
                        \n(counts any sequence of non-spaces as a word)"
            ]
    ]

That completes the main part of the app.  The remainder of this file is a
few auxiliary functions mentioned above, but not yet defined.

## Auxiliary functions

The following function determines if a text string contains only numbers and
operators appropriate for an arithmetic expression, and thus safe to pass
to `eval()`.

    isJustArithmetic = ( text ) -> /^[.0-9+*/ ()-]+$/.test text

Here we register the background function used by the testing routine above
in `contentsChanged`.  Although this could just call `eval` and be done, we
place it in a loop that forces the computation to last for one second (the
1000 in the code is in milliseconds), to simulate a computation that takes a
long time, and thus needed to be moved into the background.

Because this routine will be run in a separate thread, it does not have
access to the same group object as in the main, UI thread.  Rather, we get a
simplified copy of the group, which is an object containing the members
`id`, `typeName`, `deleted`, `text`, `html`, `parent`, `children`, and
`data`.  These are not all documented here; see [the source code for the
Groups plugin for details](groupsplugin.litcoffee), in `Group.toJSON()`.

Note that because this will be run in a background thread, we cannot make
use of any functions defined in the current namespace.  In particular, we
must copy in the regular expression in `isJustArithmetic`, because it will
not be available in the thread in which this function will be run.  This is
done in the second argument, which is a list of objects to be (deep) copied
into the background thread.

    Background.registerFunction 'do arithmetic', ( group ) ->
        whenToStop = ( new Date ).getTime() + 1000
        while ( new Date ).getTime() < whenToStop
            result = if group.text? and isJustArithmetic group.text
                try eval group.text catch e then '???'
            else
                '???'
        result
    , isJustArithmetic : isJustArithmetic

What does it mean for something to be a name, or probably a name?  Proper
names are three or fewer words, each of which is capitalized.

    mightBeAName = ( text ) ->
        words = text.split ' '
        if not words? or words.length > 3 or words.length is 0
            return 'probably not a name'
        for word in words
            if not word[0]? or word[0].toUpperCase() isnt word[0]
                return 'probably not a name'
        'might be a name'
