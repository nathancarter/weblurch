
# Complex Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example.solo.litcoffee).  This
application is just a few steps more complex.  There is yet another example
of a more complex and robust webLurch application coming soon.

    setAppName 'ComplexApp'
    window.menuBarIcon = { }
    window.helpAboutText =
        'See the fully documented source code for this demo app at the
        following URL:\n
        \nhttps://github.com/nathancarter/weblurch/blob/master/app/complex-example.solo.litcoffee'

[See a live version of this application online here.](
http://nathancarter.github.io/weblurch/app/complex-example.html)

## Define two group types

As in the simple example, we assign to a global variable, which is noticed
by the webLurch setup process and respected.  We define two group types.

    window.groupTypes = [

### Computations

The first performs simple arithmetic computations on the contents of the
group, and replaces the contents of the group with an equation that shows
the result of the computation.  For instance, a group containing 3+2 would
be transformed into 3+2=5, with the cursor position preserved.

        name : 'computation'
        text : 'Computation group'
        image : './images/red-bracket-icon.png'
        tooltip : 'Make selection a computation'
        color : '#996666'
        imageHTML : '<font color="#996666"><b>[ ]</b></font>'
        openImageHTML : '<font color="#996666"><b>[</b></font>'
        closeImageHTML : '<font color="#996666"><b>]</b></font>'

The tag on a bubble will either classify it as an arithmetic expression or
not, just as an example use of the tag as a status indicator.  The
`isJustArithmetic` function is defined
[at the end of this file](#auxiliary-functions).

        tagContents : ( group ) ->
            leftHandSide = group.contentAsText()?.split( '=' )?[0]
            if leftHandSide? and isJustArithmetic leftHandSide
                'arithmetic expression'
            else
                'unknown'

Whenever the group's contents change, we must recompute their value, if the
contents are a valid arithmetic expression.  Although such a task is nearly
instantaneous, we run it in the background and force it to take one second,
just to show how a lengthy computation might be handled.  The background
computation called "do arithmetic" is defined
[at the end of this file](#auxiliary-functions).

The `Background.addTask` function enqueues a task to be done later.  The
parameters are (1) the name of the function to do (defined by a call to
`Background.registerFunction`, as below), (2) the array of groups to pass
as parameters, and (3) the callback to be called in this (main, UI) thread
when the computation is complete.

Note that for a variety of reasons that callback may never be called.  For
instance, if there is an error in your background processing code, the
callback will not be called.  Or if the user changes the contents of the
group again before the computation completes, then that background process
will be discarded and a new one initiated; only the callback from the
second one will be called (assuming that it completes without error or
early termination).

        contentsChanged : ( group, firstTime ) ->
            Background.addTask 'do arithmetic', [ group ], ( result ) ->

We must always check in any callback whether the group we wish to modify
still exists in our document.  (The user may delete it in the interim, and
attempting to modify its contents would then cause errors.)

                if group.deleted or not result? then return

We now rewrite the contents of the group as an equation, showing the
original content followed by an equals sign and then the result computed by
the background process.  If the contents of the group haven't changed, we
do nothing.

                text = group.contentAsText()
                if result is text then return
                leftHandSide = text.split( '=' )[0]

Store the current cursor position so that we can put it back there later.
Each group has a pointer to [the Groups plugin](groupsplugin.litcoffee),
which has a pointer to the [TinyMCE](http://www.tinymce.com/) editor
instance in which we're working.  We use some of the TinyMCE API here.
Groups also contain their open and close boundaries (each an IMG element)
as `group.open` and `group.close`.

                before = group.plugin?.editor.selection.getRng()
                textNode = group.open.nextSibling
                if before.startContainer is textNode
                    origPos = before.startOffset

Set the contents of the group to be the equation we desire.

                group.setContentAsText "#{leftHandSide}=#{result}"

Try to put the cursor back at approximately the same place that it was
before.  (This is actually often annoying to the user, because they may have
moved the cursor outside this group in the 1 second since the change that
triggered the computation, and this simple attempt to preserve cursor
location forces it back inside the group.  But in a real application, you
could use more care to prevent that annoyance.  This is just an example.)

                if not textNode = group.open.nextSibling then return
                range = textNode.ownerDocument.createRange()
                origPos ?= leftHandSide.length
                if origPos > textNode.textContent.length
                    origPos = textNode.textContent.length
                range.setStart textNode, origPos
                range.setEnd textNode, origPos
                group.plugin?.editor.selection.setRng range

### Groups with menus

We now define a group type that doesn't compute anything automatically, but
that allows you to ask questions about it and perform operations on it with
the context menu and/or the bubble tag menu.

    ,
        name : 'words'
        text : 'Group of words'
        image : './images/red-bracket-icon.png'
        tooltip : 'Make selection about words'
        color : '#669966'
        imageHTML : '<font color="#669966"><b>( )</b></font>'
        openImageHTML : '<font color="#669966"><b>(</b></font>'
        closeImageHTML : '<font color="#669966"><b>)</b></font>'

The tag on a bubble will either classify it as something that might be a
proper name, or somethign that probably isn't.  The function defining what
it means for something to be name-like appears at the end of this file.

        tagContents : ( group ) -> mightBeAName group.contentAsText()

We now provide a small popup menu that appears when the user clicks the
group's tag, and whose actions deal with that tag's content.

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
populating it with example text content that satisfies and does not satisfy
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

## Auxiliary functions

The following function determines if a text string contains only numbers and
operators appropriate for an arithmetic expression, and thus safe to pass
to `eval()`.

    isJustArithmetic = ( text ) -> /^[.0-9+*/ ()-]+$/.test text

Here we register the background function used by the testing routine above
in `contentsChanged`.  Although this could just call `eval` and be done, we
place it in a loop that forces the computation to last for one second (the
1000 in the code is in milliseconds), to simulate the kind of computations
that can take a long time, and thus would be moved into the background.

Because this routine will be run in a separate thread, it does not have
access to the same group object as in the main, UI thread.  Rather, we get a
simplified copy of the group, which is an object containing the members
`id`, `typeName`, `deleted`, `text`, `html`, `parent`, `children`, and
`data`.  These are not all documented here; see [the source code for the
Groups plugin for details, in `Group.toJSON()`](groupsplugin.litcoffee).

Note that because this will be run in a background thread, we also cannot
make use of any functions defined in the current namespace.  In particular,
we must rewrite the regular expression in `isJustArithmetic`, because it
will not be available in the web worker thread in which this function will
be run.

    Background.registerFunction 'do arithmetic', ( group ) ->
        leftHandSide = group?.text?.split( '=' )?[0]
        whenToStop = ( new Date ).getTime() + 1000
        while ( new Date ).getTime() < whenToStop
            result = if leftHandSide? and \
                        /^[.0-9+*/ ()-]+$/.test leftHandSide
                try eval leftHandSide catch e then '???'
            else
                '???'
        result

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