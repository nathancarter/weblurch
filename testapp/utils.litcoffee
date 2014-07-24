
# Test app utilities

## Setup routine

The following routine is run after
[the test app page](../testapp/index.html) has finished loading.

    window.testAppSetup = ->

Create a `LurchEditor` instance in the page itself.

        window.LE =
            new LurchEditor document.getElementById 'editor'

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
        ( $ undoButton ).on 'click', undoButtonClicked

Make the code input respond to the Enter key by auto-clicking the
run button.

        ( $ codeInput ).on 'keyup', ( event ) ->
            if event.keyCode is 13 then runButtonClicked()

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

        compare = window.comparisonHistory?.data
        if compare and index < compare.length

Use the same auxiliary function as
[the main code runner](#main-code-runner) uses, then update the
view.

            runCodeInModel compare[index].code
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

### Download button

    window.downloadButtonClicked = ( event ) ->
        data = JSON.stringify testHistory
        blob = new Blob [ data ], type : 'application/json'
        link = document.createElement 'a'
        link.setAttribute 'href', URL.createObjectURL blob
        link.setAttribute 'download',
            "#{testNameInput.value or 'test-history'}.json"
        link.click()

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
        state = """
            <pre class='gap-below-2'>#{escaped}</pre>
            #{code}
            """

Label the state as either as the initial state or the result of
executing some JavaScript code.

        if index is 0
            title = "Initial state:"
            type += ' gap-before-2'
        else
            title = "State after command #{index}:"

Wrap it in titles and boxes to make it pretty, and insert any
details the caller provided, such as buttons or markers, in the
panel title.

        """
        <div class='panel panel-#{type}'>
          <div class='panel-heading'>
            #{details}
            <h3 class='panel-title'>#{title}</h3>
          </div>
          <div class='panel-body'>#{state}</div>
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
                makeThumbButtons( index ), type
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

        if compare
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
container excluding the tab bodies, which we're about to resize.

        theRest = 75 # padding
        for child in Array::slice.apply mainContainer.childNodes
            if child instanceof HTMLElement and not
               ( $ child ).hasClass 'tab-content'
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

