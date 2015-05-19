
# Test Recording Loader

webLurch supports a mode in which it can record various keystrokes and
command invocations, and store them in the form of code that can be copied
and pasted into the source code for the app's unit testing suite.  This is
very handy for constructing new test cases without writing a ton of code.
It is also less prone to typographical and other small errors, since the
code is generated for you automatically.

That mode is implemented in two script files:
 * This file pops up a separate browser window that presents the
   test-recording UI.
 * That popup window uses the script
   [testrecorder.solo.litcoffee](#testrecorder.solo.litcoffee), which
   implements all that window's UI interactivity.

First, we have a function that switches the app into test-recording mode, if
and only if the query string equals "?test".  Test-recording mode uses a
popup window so that the main app window stays pristine and undisturbed, and
tests are recorded in the normal app environment.

    maybeSetupTestRecorder = ->
        if location.search is '?test'

Launch popup window.

            testwin = open './testrecorder.html', 'recording',
                "status=no, location=no, toolbar=no, menubar=no,
                left=#{window.screenX+($ window).width()},
                top=#{window.screenY}, width=400, height=600"

If the browser blocked it, notify the user.

            if not testwin
                alert 'You have asked to run webLurch in test-recording
                    mode, which requires a popup window.  Your browser has
                    blocked the popup window.  Change its settings or allow
                    this popup to use test-recording mode.'

If the browser did not block it, then it is loaded.  It loads its own
scripts for handling UI events for controls in the popup window.

Now we setup timers that (in 0.1 seconds) will install in the editor
listeners for various events that we want to record.

            do installListeners = ->
                notSupported = ( whatYouDid ) ->
                    alert "You #{whatYouDid}, which the test recorder does
                        not yet support.  The current test has therefore
                        become corrupted, and you should reload this page
                        and start your test again.  You will need to limit
                        yourself to using only supported keys, menu items,
                        and mouse operations."
                try

If a keypress occurs for a key that can be typed (letter, number, space),
tell the test recorder window about it.  For any other type of key, tell the
user that we can't yet record it, so the test is corrupted.

                    tinymce.activeEditor.on 'keypress', ( event ) ->
                        letter = String.fromCharCode event.keyCode
                        if /[A-Za-z0-9 ]/.test letter
                            testwin.editorKeyPress event.keyCode,
                                event.shiftKey, event.ctrlKey, event.altKey
                        else
                            notSupported "pressed the key with code
                                #{event.keyCode}"

If a keyup occurs for any key, do one of three things.  First, if it's a
letter, ignore it, because the previous case handles that better.  Second,
if it's shift/ctrl/alt/meta, ignore it.  Finally, if it's one of the special
keys we can handle (arrows, backspace, etc.), notify the test recorder about
it.  For any other type of key, tell the user that we can't yet record it,
so the test is corrupted.

                    tinymce.activeEditor.on 'keyup', ( event ) ->
                        letter = String.fromCharCode event.keyCode
                        if /[A-Za-z0-9 ]/.test letter then return
                        ignore = [ 16, 17, 18, 91 ] # shift, ctrl, alt, meta
                        if event.keyCode in ignore then return
                        conversion =
                            8 : 'backspace'
                            13 : 'enter'
                            35 : 'end'
                            36 : 'home'
                            37 : 'left'
                            38 : 'up'
                            39 : 'right'
                            40 : 'down'
                            46 : 'delete'
                        if conversion.hasOwnProperty event.keyCode
                            testwin.editorKeyPress \
                                conversion[event.keyCode],
                                event.shiftKey, event.ctrlKey, event.altKey
                        else
                            notSupported "pressed the key with code
                                #{event.keyCode}"

Tell the test recorder about any mouse clicks in the editor.  If the user
is holding a ctrl, alt, or shift key while clicking, we cannot currently
support that, so we warn the user if they try to record such an action.

                    tinymce.activeEditor.on 'click', ( event ) ->
                        if event.shiftKey
                            notSupported "shift-clicked"
                        else if event.ctrlKey
                            notSupported "ctrl-clicked"
                        else if event.altKey
                            notSupported "alt-clicked"
                        else
                            testwin.editorMouseClick event.clientX,
                                event.clientY

If any of the above handler installations fail, the reason is probably that
the editor hasn't been initialized yet.  So just wait 0.1sec and retry.

                catch e
                    setTimeout installListeners, 100
