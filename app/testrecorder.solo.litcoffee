
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
                if explanation?
                    code += "\n#{explanation}\n"
                if codeString?
                    if explanation? then code += '\n'
                    for line in codeString.split '\n'
                        code += "        #{line}\n"
            escapeApos = ( text ) -> text.replace /'/g, '\\\''
            indent = ( text ) ->
                '    ' + text.replace ( RegExp '\n', 'g' ), '\n    '
            code = '\nTest built with webLurch test-recording mode.\n\n'
            title = testState.title or 'untitled test'
            code += "    it '#{escapeApos title}', inPage ->\n"
            ary = testState.steps
            for step, index in ary
                if index > 0 and ary[index].type is ary[index-1].type
                    count = 0
                else
                    count = 1
                    while ( index+count < ary.length ) and \
                          ( ary[index].type is ary[index+count].type )
                        count++
                if step.type is 'comment'
                    writeStep step.content
                else if step.type is 'check contents'
                    string = "'#{escapeApos step.content}'"
                    writeStep 'Check to be sure the editor contains the
                        correct content.', "pageExpects allContent, 'toBeSimilarHTML',\n#{indent string}"
                else if step.type is 'wrong contents'
                    string = "'TO BE EDITED: #{escapeApos step.content}'"
                    writeStep "At this point the editor contains incorrect
                        contents.  (The code below will need to be edited
                        later to replace the incorrect expectation with a
                        correct one.)\n
                        \nExplanation of how the expectation below is
                        incorrect:  #{step.explanation}",
                        "pageExpects allContent,
                        'toBeSimilarHTML',\n#{indent string}"
                else if step.type is 'key press'
                    explanation = switch count
                        when 0 then null
                        when 1 then 'Simulate pressing a key in the editor.'
                        else 'Simulate pressing keys in the editor.'
                    args = "'#{step.content}'"
                    if step.shift then args += ", 'shift'"
                    if step.ctrl then args += ", 'ctrl'"
                    if step.alt then args += ", 'alt'"
                    writeStep explanation, "pageKey #{args}"
                else if step.type is 'typing'
                    writeStep 'Simulate typing in the editor.',
                        "pageType '#{escapeApos step.content}'"
                else if step.type is 'click'
                    writeStep 'Simulate a mouse click in the editor.',
                        "pageClick #{step.x}, #{step.y}"
                else if step.type is 'button'
                    explanation = switch count
                        when 0 then null
                        when 1 then 'Simulate clicking a command button
                            in the editor.'
                        else 'Simulate clicking command buttons
                            in the editor.'
                    writeStep explanation,
                        "pageCommand '#{escapeApos step.content}'"
                else
                    writeStep 'ERROR: Unknown step type:',
                        "'#{escapeApos step.type}'\n# #{step.content}"
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

When the user clicks the "Call Editor Contents Incorrect" button, we add a
step to the list of test steps, containing within it the full contents of
the editor as they stand, plus an explanation the user provides about why
the editor has incorrect contents.

        ( $ '#contentsIncorrect' ).on 'click', ->
            explanation = prompt 'Please provide an explanation of why the
                editor\'s contents are incorrect.  Include a suggestion of
                what they ought to be, if possible.', ''
            if explanation isnt null
                testState.steps.push
                    type : 'wrong contents'
                    content :
                        window.opener.tinymce.activeEditor.getContent()
                    explanation : explanation
                update()

When the user clicks the "See Editor Contents" button, we pop up an alert
dialog containing the editor contents for the user to view.

        ( $ '#seeContents' ).on 'click', ->
            result = window.opener.tinymce.activeEditor.getContent()
            if result is '' then alert 'Editor is empty.'
            else alert 'The editor contents are represented in HTML format
                below.\n\n' + result

When the user clicks the "Email Generated Test to Developers" button, we
create an email-sending link and navigate to it.  However, if the current
test doesn't actually contain any calls to `pageExpects`, then we inform the
user that they haven't actually tested anything yet.

        ( $ '#emailTest' ).on 'click', ->
            somethingIsTested = no
            for step in testState.steps
                if step.type[-9..] is ' contents'
                    somethingIsTested = yes
                    break
            if not somethingIsTested
                alert 'You have not made any assertions yet in the test.
                    You must at some point mark the editor contents as
                    correct or incorrect in order for the generated code to
                    actually contain an assertion to be tested.'
                return
            recipient = 'ncarter@bentley.edu'
            subject = 'webLurch: recorded unit test'
            body = encodeURIComponent "\n
                \nThe following unit test was recorded on #{new Date}.\n
                \n(Before sending this email, feel free to add any extra
                    information you have here.)\n
                \n-----------begin test code------------\n
                #{document.getElementById( 'testCode' ).textContent}"
            window.location.href =
                "mailto:#{recipient}?subject=#{subject}&body=#{body}"

## Events from the main page

The page with the editor in it will send us various events, such as key
presses and menu clicks.  We will record them as part of the test using the
handlers provided below, which the main page calls.

    window.editorKeyPress = ( keyCode, shift, ctrl, alt ) ->
        letter = String.fromCharCode keyCode
        if /[a-zA-Z0-9 ]/.test letter
            if testState.steps.length > 0 and \
               testState.steps[testState.steps.length-1].type is 'typing'
                testState.steps[testState.steps.length-1].content += letter
            else
                testState.steps.push
                    type : 'typing'
                    content : letter
        else
            testState.steps.push
                type : 'key press'
                content : keyCode
                shift : shift
                ctrl : ctrl
                alt : alt
        update()
    window.editorMouseClick = ( x, y ) ->
        testState.steps.push
            type : 'click'
            x : x
            y : y
        update()
    window.buttonClicked = ( name ) ->
        testState.steps.push
            type : 'button'
            content : name
        update()
