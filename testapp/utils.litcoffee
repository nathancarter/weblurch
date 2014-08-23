
# Test app utilities

## Setup routine

The following routine is run after
[the test app page](../testapp/index.html) has finished loading.

    window.testAppSetup = ->

Create a `LurchEditor` instance in the page itself.

        window.LE = new LurchEditor editor

Create global datum in which we will store the history of all the
states of the model (i.e., `LE`'s element), as well as all lines of
code executed to cause changes of state.

        initializeHistory()

Store in global variables the important UI elements on the page.

        window.maindiv = LE.getElement()

Install event handlers for the buttons.

        ( $ runButton ).on 'click', runButtonClicked
        ( $ resetButton ).on 'click', resetButtonClicked
        ( $ downloadButton ).on 'click', downloadButtonClicked
        ( $ copyButton ).on 'click', copyButtonClicked
        ( $ pasteButton ).on 'click', pasteButtonClicked
        ( $ undoButton ).on 'click', undoButtonClicked
        ( $ runFullHistoryButton ).on 'click',
            runFullHistoryButtonClicked
        ( $ saveStateCommentsButton ).on 'click',
            saveStateCommentsButtonClicked

Make the code input respond to the Enter key by auto-clicking the
run button, and the comments input respond to Shift+Enter by
auto-clicking the Save button.

        ( $ codeInput ).on 'keydown', ( event ) ->
            if event.keyCode is 13 then runButtonClicked()
        ( $ commentEditInput ).on 'keydown', ( event ) ->
            if event.keyCode is 13 and event.shiftKey
                saveStateCommentsButtonClicked()
                no # prevent event propagation

Fill the source and/or history tabs only when they become visible,
so we're not always recomputing their contents.

        ( $ sourceTab ).on 'click', updateSourceTab
        ( $ historyTab ).on 'click', updateHistoryTab

Fill the saved histories drop-down with items from the global
variable `allTestHistories`.  Then install the event handler for
that drop-down list.

        filenames = Object.keys allTestHistories
        filenames.sort()
        filenames.unshift 'Compare to a saved history...'
        for filename in filenames
            item = document.createElement 'option'
            item.textContent = filename
            savedHistoriesList.appendChild item
        ( $ savedHistoriesList ).change chosenHistoryChanged

Make the history body the right size for scrolling independently,
and have this update every time the page is resized.

        resizeHistoryHeight()
        ( $ window ).resize resizeHistoryHeight

Set up the common commands panel.

        setupCommonCommands()

Run [the routine](#source-synchronizer) that updates the currently
active view.

        updateView()

Place the user's keyboard focus into the code input box.

        codeInput.focus()

## Event handlers

### Dispatcher

This function dispatches to either the source tab updater or the
history tab updater, depending on which one is visible, if either.

    window.updateView = ->
        updateSourceTab() if ( $ sourceView ).hasClass 'active'
        updateHistoryTab() if ( $ historyView ).hasClass 'active'

### Source synchronizer

The following routine fills the source div with the HTML source of
the `LurchEditor`'s element.

    window.updateSourceTab = ->
        code = LE.getElement().outerHTML.replace( /&/g, '&amp;' )
                                        .replace( />/g, '&gt;' )
                                        .replace( /</g, '&lt;' )
                                        .replace( /'/g, '&apos;' )
                                        .replace( /"/g, '&quot;' )
        sourceView.innerHTML = "<pre>#{code}</pre>"

### Main code runner

The event handler on the "Run" button that evaluates the code the
user enters in the code input box.  The following function is the
auxiliary function it uses to do so.

    window.runCodeInModel = ( code ) ->

First, just evaluate the code.

        eval code

This auxiliary function also appends that action and its result to
the test history array.

        testHistory.push {
            code : code
            state : LE.getElement().toJSON()
        }

The event handler just calls the auxiliary function, then updates
any visible views, clears the code input, and gives it focus.

    window.runButtonClicked = ( event ) ->
        runCodeInModel codeInput.value
        updateView()
        codeInput.value = ''
        codeInput.focus()

### Code runner for test history

Similar to the previous method, but this event handler is for the
individual run buttons that appear in code steps in a saved test
history, if one is displayed.

    window.runSavedStep = ( index ) ->

Guard against having this run at an incorrect time, or with an
incorrect parameter.

        savedHistory = window.comparisonHistory?.data
        if savedHistory and index < savedHistory.length

Use the same auxiliary function as
[the main code runner](#main-code-runner) uses, then update the
view.

            runCodeInModel savedHistory[index].code
            updateView()

### Code runner for full test history

It can be convenient to run the full test history all at once, all
commands in sequence.  There is a button for doing so, and this is
its event handler.

It is very similar to
[the previous handler](#code-runner-for-test-history), except in
a loop, so I don't feel the need to describe it in detail.  The
one interesting note is that we don't replay the initial command,
because it is blank (corresponding to the initial state).

    window.runFullHistoryButtonClicked = ( event ) ->
        savedHistory = window.comparisonHistory?.data
        if savedHistory
            testHistory[testHistory.length-1].comments =
                savedHistory[0].comments
            for step in savedHistory[1..]
                runCodeInModel step.code
                testHistory[testHistory.length-1].comments =
                    step.comments
            updateView()

### Yes and no buttons

The event handlers for the "Mark right" and "Mark wrong" buttons
edit the last item pushed onto the `testHistory` stack.

    window.yesButtonClicked = ( index ) ->
        if testHistory[index].correct is yes
            delete testHistory[index].correct
        else
            testHistory[index].correct = yes
        updateView()

    window.noButtonClicked = ( index ) ->
        if testHistory[index].correct is no
            delete testHistory[index].correct
        else
            testHistory[index].correct = no
        updateView()

### Edit comments buttons

The following event handler responds to the user's clicking the
edit button in a state in the current history.

    window.editStateComments = ( index ) ->

Fill the hidden modal dialog with the comments to be edited.

        ( $ commentEditInput ).val testHistory[index].comments

Store the index of the state we're editing, so we know later where
to save any edits.

        commentEditInput.comesFromIndex = index

Show the modal dialog and ensure that focus goes to the right
control after it appears.

        ( $ commentEditDialog ).modal {
            show : true
            backdrop : true
            keyboard : true
        }
        ( $ commentEditDialog ).on 'shown.bs.modal', ( event ) ->
            ( $ commentEditInput ).focus()

The following event handler responds to the user's clicking Save in
the modal dialog for editing state comments.

    window.saveStateCommentsButtonClicked = ( event ) ->

Fetch the stored index of which state it is whose comments we're
editing.

        index = commentEditInput.comesFromIndex

Save the comments, having trimmed whitespace from start and end.

        testHistory[index].comments =
            ( $ commentEditInput ).val().trim()

Hide the modal dialog and update any necessary views.

        ( $ commentEditDialog ).modal 'hide'
        updateView()
    
### Download button

    window.downloadButtonClicked = ( event ) ->

I use pretty printing in the following JSON, because these files
will be checked into our repository, and developers may end up
browsing them at some point on disk.  The preferred way to browse
them is to load them into
[this very test app](../testapp/index.html), but it doesn't hurt to
make reading the source files easier.

        data = JSON.stringify testHistory, null, 2

The following uses the HTML `createObjectURL` method to store blob
data in the browser, which provides us a unique URL containing a
hash that references that blob, for the user to download.

        blob = new Blob [ data ], type : 'application/json'
        link = document.createElement 'a'
        link.setAttribute 'href', URL.createObjectURL blob
        link.setAttribute 'download',
            "#{testNameInput.value or 'test-history'}.json"
        link.click()

Technically, once the blob has been used (i.e., the file
downloaded), we should then delete the URL, to save resources.
However, the amount of data being stored here is very small, and
the test app will be used infrequently enough that I'm not
concerned about that leak right now.  But it could be fixed in the
future.

### Copy and paste buttons

The copy button just throws up a prompt that lets the user use
Ctrl+C to copy the contents of the window.  This is less than
perfectly convenient, but there are security reasons why copying
to the clipboard in JavaScript is tricky.

    window.copyButtonClicked = ( event ) ->
        window.prompt 'Press Ctrl+C, then Enter',
            JSON.stringify ( step.code for step in testHistory \
                when step.code isnt '' )

The paste button does the same thing, requiring the user to
manually paste the clipboard contents into a prompt box.  Again,
this is due to JavaScript security constraints.

    window.pasteButtonClicked = ( event ) ->
        got = window.prompt 'Press Ctrl+V, then Enter', ''
        try
            for command in JSON.parse got
                runCodeInModel command
            updateView()
        catch
            alert 'That was not a valid command history.'

### Reset button

This method resets the document (and the editor over it) to their
initial states, by replacing them with fresh ones.  The process is
described in the comments interleaved in the code below.

    window.resetButtonClicked = ( event ) ->

Then recreate a new div that's exactly like the document was when
it was initialized.

        freshDocument = Node.fromJSON testHistory[0].state

Replace the existing document in the DOM hierarchy with this new
one.

        current = window.LE.getElement()
        current.parentNode.replaceChild freshDocument, current

Throw away the old `LurchEditor` and replace it with a new one,
whose element is this newly created document.

        window.LE = new LurchEditor freshDocument
        window.maindiv = freshDocument

Clear out the test history, reload any saved history, and refresh
all views.

        initializeHistory()
        chosenHistoryChanged()
        updateView()

### Undo button

This method performs an undo *not* by calling the `undo` method of
the editor, for two reasons.
 * The test history may be testing (and thus using) that very undo
   method, and thus it should not be relied upon in the test app.
 * Calling that method changes the state of the editor, by
   manipulating its undo/redo stack.  But the state of that stack
   must be reverted by this very undo/redo operation.

Thus this method proceeds as follows.

    window.undoButtonClicked = ( event ) ->

First, retain the current test history in a temporary variable for
use below.

        oldHistory = testHistory

Now reset the entire page to its initial state (which clears out
the test history, and that's why we saved it, above.)

        resetButtonClicked()

Now replay all the commands in the test history, in order, *except
for* the final one.  This will put the document *and* the editor in
the state they were in before that last command took place.  Note
that the first entry in the test history is not a command, so we
must skip it.

        for step in oldHistory[1...-1]
            runCodeInModel step.code

Last, update any views to show that the undo took place.

        updateView()

### Handling a choice of a saved history

    window.chosenHistoryChanged = ( event ) ->

Look up the data for the chosen history in the global variable in
which it's stored.

        filename = ( $ savedHistoriesList ).val()

Update the global variable used for history comparison to contain
that data, or to be null if there was no such data (e.g., the user
chose the drop-down's title, rather than an item on it).

        if filename of allTestHistories
            window.comparisonHistory = {
                filename : filename
                data : allTestHistories[filename]
            }
        else
            window.comparisonHistory = null

Update the view, in case they're viewing the history.

        updateView()

### Representation of the test history

This routine is the event handler for the display of the History
tab; it populates that tab with an HTML representation of the
current test history.

First, we need some auxiliary functions.  The first computes the
representation of a command in the history.  The parameters are
as follows.
 * `step` is an entry in the test history
 * `index` is an integer, that step's index in the history
 * `details` is any HTML that should be inserted in the panel
   header, before the title (such as floating buttons/indicators)


    window.historyCommandRepresentation = ( step, index,
        details = '' ) ->

Escape the code for insertion into an HTML document.

        code = step.code.replace( /&/g, '&amp;' )
                        .replace( />/g, '&gt;' )
                        .replace( /</g, '&lt;' )
                        .replace( /'/g, '&apos;' )
                        .replace( /"/g, '&quot;' )

Wrap it in some titles and boxes to make it pretty.

        """
        <div class='panel panel-info'>
          <div class='panel-heading'>
            #{details}
            <h3 class='panel-title'>Command #{index}:</h3>
          </div>
          <div class='panel-body'>
            <pre>#{code}</pre>
          </div>
        </div>
        """

The second auxiliary function computes the representation of a
state in the command history.  The parameters are the same as in
the previous auxiliary function, plus this one:
 * `type` is the panel type, either 'default', 'success', or
   'danger'


    window.historyStateRepresentation = ( step, index,
        details = '', type = 'default' ) ->

De-serialize the model state, do not put it into the page's DOM,
but convert it to a string of HTML code.  Remove all ids from this
code so that we can use it to represent the document state without
conflicting with the document that's already in the page.

        code = Node.fromJSON( step.state ).outerHTML
        escaped = code.replace( /&/g, '&amp;' )
                      .replace( />/g, '&gt;' )
                      .replace( /</g, '&lt;' )
                      .replace( /'/g, '&apos;' )
                      .replace( /"/g, '&quot;' )
        code = code.replace /\s+id=['"][^'"]+['"]/g, ''
        state = """<pre class='gap-below-2'>#{escaped}</pre>
                   #{code}"""

Label the state as either as the initial state or the result of
executing some JavaScript code.

        if index is 0
            title = "Initial state:"
            type += ' gap-before-2'
        else
            title = "State after command #{index}:"

Wrap the comments in a well if they actually exist, or keep them
blank if this step does not have any comments.

        if step.comments
            comments = """
                <div class='well well-sm'>
                    <span class='glyphicon glyphicon-info-sign'>
                    </span>
                    #{step.comments}
                </div>
                """
        else
            comments = ''

Wrap it in titles and boxes to make it pretty, and insert any
details the caller provided, such as buttons or markers, in the
panel title.

        """
        <div class='panel panel-#{type}'>
            <div class='panel-heading'>
                #{details}
                <h3 class='panel-title'>#{title}</h3>
            </div>
            <div class='panel-body'>
                #{comments}
                #{state}
            </div>
        </div>
        """

Now, the main event handler.

    window.updateHistoryTab = ->

We also need several tiny auxiliary functions that aren't worth
declaring at the global scope, so I declare them here.  They're
for creating HTML button code.

A run button for use in saved history commands:

        makeRunButton = ( index ) -> """
            <button type='button'
                    class='btn btn-xs btn-default pull-right'
                    data-toggle='tooltip' title='Run'
                    onclick='runSavedStep(#{index});'
             ><span class='glyphicon glyphicon-play'>
                    </span></button>"""

An edit button for use in current history states:

        makeEditButton = ( index ) -> """
            <button type='button'
                    class='btn btn-xs btn-default pull-right'
                    data-toggle='tooltip' title='Edit comments'
                    onclick='editStateComments(#{index});'
             ><span class='glyphicon glyphicon-pencil'>
                    </span></button>"""

A pair of thumbs up/down buttons for use in test history states:

        makeThumbButtons = ( index ) -> """
            <button type='button'
                    class='btn btn-xs btn-danger pull-right'
                    data-toggle='tooltip' title='Mark incorrect'
                    onclick='noButtonClicked(#{index});'
             ><span class='glyphicon glyphicon-thumbs-down'>
                    </span></button>
            <button type='button'
                    class='btn btn-xs btn-success pull-right'
                    data-toggle='tooltip' title='Mark correct'
                    onclick='yesButtonClicked(#{index});'
             ><span class='glyphicon glyphicon-thumbs-up'>
                    </span></button>"""

"Same" and "different" indicators for saved history states:

        sameIndicator = '''
            <div class='pull-right'>SAME
                <span class='glyphicon glyphicon-ok'></span>
            </div>'''
        diffIndicator = '''
            <div class='pull-right'>DIFFERENT
                <span class='glyphicon glyphicon-remove'></span>
            </div>'''

Tool for building rows of two columns:

        makeRowOfTwo = ( left, right ) -> """
            <div class='row'>
                <div class='col-md-6'>#{left}</div>
                <div class='col-md-6'>#{right}</div>
            </div>"""

And now we truly begin!  Initialize the representation to empty,
and we'll build it as we loop through the histories.

        representation = ''

Find out if we're comparing the current test history to another.

        compare = window.comparisonHistory?.data or null

Loop through the history's steps.

        for step, index in testHistory

If this is not the initial state, then show the command that got us
to this state.

            if index > 0
                current = historyCommandRepresentation step, index
                if compare
                    if index < compare.length
                        saved = historyCommandRepresentation \
                            compare[index], index,
                            makeRunButton index
                    else
                        saved = ''
                    current = makeRowOfTwo current, saved
                representation += current

No matter what state it is, show the state.  We must first
compute the type of panel we will use to show the state, based
on its correctness marking.

            if not step.hasOwnProperty 'correct'
                type = 'default'
            else
                type = if step.correct then 'success' else 'danger'
            current = historyStateRepresentation step, index,
                makeThumbButtons( index ) +
                makeEditButton( index ), type
            if compare
                if index < compare.length
                    left = JSON.stringify step.state
                    right = JSON.stringify compare[index].state
                    if left is right
                        details = sameIndicator
                        type = 'success'
                    else
                        details = diffIndicator
                        type = 'danger'
                    saved = historyStateRepresentation \
                        compare[index], index, details, type
                else
                    saved = ''
                current = makeRowOfTwo current, saved
            representation += current

If there were more steps remaining in the saved history to which
we're comparing the current one, show those at the end.

        if compare and testHistory.length < compare.length
            for index in [testHistory.length...compare.length]
                step = compare[index]
                code = historyCommandRepresentation step, index,
                    makeRunButton index
                state = historyStateRepresentation \
                    compare[index], index, '', 'default'
                representation += makeRowOfTwo '', code
                representation += makeRowOfTwo '', state

Populate the history tab.

        historyBody.innerHTML = representation

### Resizing the test history div

Because the test history div should be scrollable without the rest
of the page being scrollable, it must have a fixed height.  This is
unfortunate, especially since it requires estimating how tall the
rest of the page will be, and subtracting.  Furthermore, it must be
updated every time the window resizes.  Hence the following
function, which I wish I could do in CSS, but I don't think I can.

    resizeHistoryHeight = ->

First figure out the total height of all children of the main
container, stopping before the tab bodies, which we're about to
resize.  (After the tab bodies sit modal dialogs, which we do not
wish to include in the height computation.)

        theRest = 75 # padding
        for child in Array::slice.apply mainContainer.childNodes
            if ( $ child ).hasClass 'tab-content' then break
            if child instanceof HTMLElement
                theRest += ( $ child ).outerHeight true

Then subtract to determine the appropriate resize height.

        ( $ historyBody ).height ( $ window ).height() - theRest

## Utility functions

    window.initializeHistory = ->

Set up the initial test history by reading it from the current
document state.

        window.testHistory = [
            {
                code : ''
                state : LE.getElement().toJSON()
            }
        ]

Clear the history to which the user wishes to compare that one,
because at the outset, no such history has been chosen.

        window.comparisonHistory = null

    window.setupCommonCommands = ->
        glyphIcon = ( name ) ->
            "<span class='glyphicon glyphicon-#{name}'></span>"
        commonCommands = [
            [
                glyphIcon 'align-justify'
                'Set the document to a few paragraphs of text'
                'maindiv.innerHTML = "<p>Lorem ipsum dolor sit
                    amet, consectetur adipiscing elit,
                    sed do eiusmod tempor incididunt ut
                    labore et dolore magna aliqua.</p>
                    <p>Ut enim ad minim veniam,
                    quis nostrud exercitation ullamco laboris
                    nisi ut aliquip ex ea commodo consequat.</p>"'
            ]
            [
                glyphIcon 'plus'
                'Add one paragraph to the end of the document'
                'maindiv.innerHTML += "<p>Appended paragraph</p>"'
            ]
            [
                glyphIcon 'trash'
                'Remove all content from the document'
                'maindiv.innerHTML = ""'
            ]
            [
                glyphIcon 'backward'
                'Places the cursor at the beginning'
                'LE.placeCursor(0)'
            ]
            [
                glyphIcon 'forward'
                'Places the cursor at the end'
                'LE.placeCursor(LE.cursorPositionsIn(LE.getElement()))'
            ]
            [
                glyphIcon 'arrow-left'
                'Move the cursor to the left'
                'LE.moveCursor(-1)'
            ]
            [
                glyphIcon 'arrow-right'
                'Move the cursor to the right'
                'LE.moveCursor(1)'
            ]
            [
                glyphIcon 'chevron-left'
                'Shift+move the cursor to the left'
                'LE.moveCursor(-1,false)'
            ]
            [
                glyphIcon 'chevron-right'
                'Shift+move the cursor to the right'
                'LE.moveCursor(1,false)'
            ]
            [
                glyphIcon 'resize-horizontal'
                'Select all'
                'LE.placeCursor(0); LE.placeCursor(LE.cursorPositionsIn(LE.getElement()),false);'
            ]
        ]
        for triple in commonCommands
            [ title, desc, code ] = triple
            button = document.createElement 'button'
            button.innerHTML = title
            button.setAttribute 'type', 'button'
            button.setAttribute 'class', 'btn btn-default'
            button.setAttribute 'title', "#{desc}\n#{code}"
            window.commonCommands.appendChild button
            do ( code ) ->
                ( $ button ).click ( event ) -> runCodeInModel code
            window.commonCommands.appendChild \
                document.createTextNode ' '

