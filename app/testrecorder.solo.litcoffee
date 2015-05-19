
# Test Recording UI

webLurch supports a mode in which it can record various keystrokes and
command invocations, and store them in the form of code that can be copied
and pasted into the source code for the app's unit testing suite.  This is
very handy for constructing new test cases without writing a ton of code.
It is also less prone to typographical and other small errors, since the
code is generated for you automatically.

That mode is implemented in two script files:
 * The file [testrecorder.litcoffee](#testrecorder.litcoffee), which pops up
   a separate browser window that presents the test-recording UI.
 * This file, which implements all the UI interactivity in that popup
   window.

## Initializing global variables

The following variable stores the test state.

    testState = steps : [ ]

## Update function

The update function fills the code output area with the in-code
representation of the `testState` global variable.

    update = ->
        code = ''
        if not testState.title? and not testState.steps?
            code = '(no steps recorded yet)'
        else
            code = '\nTest built with webLurch test-recording mode.\n\n'
            title = testState.title or 'untitled test'
            code += "    it '#{title}', inPage ->\n"
            writeStep = ( explanation, codeString ) ->
                code += "\n#{explanation}\n"
                if codeString?
                    for line in codeString.split '\n'
                        code += "\n        #{line}\n"
            for step in testState.steps
                if step.type is 'comment'
                    writeStep step.content
                # more cases to come
                else
                    writeStep 'Unknown step type:', "'#{step.type}'"
        document.getElementById( 'testCode' ).textContent = code

The update function should be called as soon as the page has loaded.

    $ update

## Button click handlers

    $ ->

When the user clicks the "Set Test Title" button, we prompt them for a
title, then update the code in the output area to reflect the change.

        ( $ '#setTitle' ).on 'click', ->
            newTitle = prompt 'Enter new test title', testState.title ? ''
            if newTitle isnt null
                testState.title = newTitle
                update()

When the user clicks the "Add a Comment" button, we prompt them for its
contents, then add it to the steps array as a comment.

        ( $ '#addComment' ).on 'click', ->
            content = prompt 'Enter your comment here', ''
            if content isnt null
                testState.steps.push { type : 'comment', content : content }
                update()
