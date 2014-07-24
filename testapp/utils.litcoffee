
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
        ( $ yesButton ).on 'click', yesButtonClicked
        ( $ noButton ).on 'click', noButtonClicked
        ( $ downloadButton ).on 'click', downloadButtonClicked

Make the code input respond to the Enter key by auto-clicking the
run button.

        ( $ codeInput ).on 'keyup', ( event ) ->
            if event.keyCode is 13 then runButtonClicked()

Fill the source and/or history tabs only when they become visible,
so we're not always recomputing their contents.

        ( $ sourceTab ).on 'click', updateSourceTab
        ( $ historyTab ).on 'click', updateHistoryTab

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

### Code runner

The event handler on the "Run" button that evaluates the code the
user enters in the code input box.

    window.runButtonClicked = ( event ) ->
        eval codeInput.value

It also appends that action and its result to the test history
array.

        testHistory.push {
            code : codeInput.value
            state : LE.getElement().toJSON()
        }

Update any visible views, clear the code input, and give it focus.

        updateView()
        codeInput.value = ''
        codeInput.focus()

### Yes and no buttons

The event handlers for the "Mark right" and "Mark wrong" buttons
edit the last item pushed onto the `testHistory` stack.

    window.yesButtonClicked = ( event ) ->
        testHistory[testHistory.length - 1].correct = yes
        updateView()

    window.noButtonClicked = ( event ) ->
        testHistory[testHistory.length - 1].correct = no
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

Clear out the test history and refresh all views.

        initializeHistory()
        updateView()

### Representation of the test history

This routine is the event handler for the display of the History
tab; it populates that tab with an HTML representation of the
current test history.

    window.updateHistoryTab = ->
        representation = ''
        for step, index in testHistory

If this is not the initial state, then show the command that got us
to this state.

            if index > 0
                code = step.code.replace( /&/g, '&amp;' )
                                .replace( />/g, '&gt;' )
                                .replace( /</g, '&lt;' )
                                .replace( /'/g, '&apos;' )
                                .replace( /"/g, '&quot;' )
                representation += """
                    <div class='panel panel-info'>
                      <div class='panel-heading'>
                        <h3 class='panel-title'
                        >Command #{index}:</h3>
                      </div>
                      <div class='panel-body'>
                        <pre>#{code}</pre>
                      </div>
                    </div>
                    """

Compute the type of panel we will use to show the next state, based
on its correctness marking.

            if not step.hasOwnProperty 'correct'
                type = 'default'
            else
                type = if step.correct then 'success' else 'danger'

De-serialize the model state, do not put it into the page's DOM,
but convert it to a string of HTML code.  Remove all ids from this
code so that we can use it to represent the document state.

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

Show the state in the history step, either as the initial state or
the result of executing some JavaScript code.

            title = if index is 0
                "Initial state:"
            else
                "State after command #{index}:"
            if index is 0 then type += ' gap-before-2'
            representation += """
                <div class='panel panel-#{type}'>
                  <div class='panel-heading'>
                    <h3 class='panel-title'>#{title}</h3>
                  </div>
                  <div class='panel-body'>#{state}</div>
                </div>
                """

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

Set up the initial test history by reading it from the current
document state.

    window.initializeHistory = ->
        window.testHistory = [
            {
                code : ''
                state : LE.getElement().toJSON()
            }
        ]

