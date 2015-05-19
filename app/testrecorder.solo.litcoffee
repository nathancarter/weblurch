
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
            writeStep = ( explanation, codeString ) ->
                code += "\n#{explanation}\n"
                if codeString?
                    code += '\n'
                    for line in codeString.split '\n'
                        code += "        #{line}\n"
            escapeApos = ( text ) -> text.replace /'/g, '\\\''
            indent = ( text ) ->
                '    ' + text.replace ( RegExp '\n', 'g' ), '\n    '
            code = '\nTest built with webLurch test-recording mode.\n\n'
            title = testState.title or 'untitled test'
            code += "    it '#{escapeApos title}', inPage ->\n"
            for step in testState.steps
                if step.type is 'comment'
                    writeStep step.content
                else if step.type is 'check contents'
                    string = "'#{escapeApos step.content}'"
                    writeStep 'Check to be sure the editor contains the
                        correct content.', "pageExpects allContent, 'toBeSimilarHTML',\n#{indent string}"
                # more cases to come
                else
                    writeStep 'Unknown step type:',
                        "'#{escapeApos step.type}'"
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

When the user clicks the "Call Editor Contents Correct" button, we add a
step to the list of test steps, containing within it the full contents of
the editor as they stand.

        ( $ '#contentsCorrect' ).on 'click', ->
            testState.steps.push
                type : 'check contents'
                content : window.opener.tinymce.activeEditor.getContent()
            update()
