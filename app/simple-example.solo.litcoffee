
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

## Define one group type

After the initialization function above has been run, each plugin will be
initialized.  The Groups plugin will look for the following data, so that it
knows which group types to create.

    window.groupTypes = [
        name : 'me'
        text : 'Meaningful expression'
        image : './images/red-bracket-icon.png'
        tooltip : 'Make text a meaningful expression'
        color : '#996666'

All of the following code is here only for testing the features it
leverages.  Later we will actually make bubbles that have sensible
behaviors, but for now we're just doing very simple things for testing
purposes.

        tagContents : ( group ) ->
            "#{group.contentAsText()?.length} characters"
        # contentsChanged : ( group, firstTime ) ->
        #     Background.addTask 'arith', [ group ], ( result ) ->
        #         if group.deleted or not result? then return
        #         text = group.contentAsText()
        #         if result isnt text
        #             lhs = text.split( '=' )[0]
        #             before = group.plugin?.editor.selection.getRng()
        #             textNode = group.open.nextSibling
        #             if before.startContainer is textNode
        #                 origPos = before.startOffset
        #             group.setContentAsText result
        #             if not textNode = group.open.nextSibling
        #                 return
        #             range = textNode.ownerDocument.createRange()
        #             origPos ?= lhs.length
        #             if origPos > textNode.textContent.length
        #                 origPos = textNode.textContent.length
        #             range.setStart textNode, origPos
        #             range.setEnd textNode, origPos
        #             group.plugin?.editor.selection.setRng range
        contentsChanged : ( group, firstTime ) ->
            Background.addTask 'notify', [ group ], ( result ) ->
                console.log result
        deleted : ( group ) ->
            console.log 'You deleted this group:', group
        contextMenuItems : ( group ) ->
            [
                text : group.contentAsText()
                onclick : -> alert 'Example code for testing'
            ]
        tagMenuItems : ( group ) ->
            [
                text : 'Compute'
                onclick : ->
                    text = group.contentAsText()
                    if not /^[0-9+*/ -]+$/.test text
                        alert 'Not a mathematical expression'
                        return
                    try
                        alert "#{text} evaluates to:\n#{eval text}"
                    catch e
                        alert "Error in #{text}:\n#{e}"
            ]
    ]

Here we register the background function used by the testing routine above
in `contentsChanged`.  Again, this is just very simple and not very useful
code, except for its value in testing the underlying structure of the app.

    Background.registerFunction 'arith', ( group ) ->
        if lhs = group?.text?.split( '=' )?[0]
            "#{lhs}=" + if /^[0-9+*/ ()-]+$/.test lhs
                try eval lhs catch e then '???'
            else
                '???'
        else
            null
    Background.registerFunction 'notify', ( group ) -> group?.text
    Background.registerFunction 'count', ( group ) ->
        counter = 0
        endAt = ( new Date ).getTime() + 1000
        while ( new Date ).getTime() < endAt then counter++
        "from #{endAt-1000} to #{endAt}, counted #{counter}"
