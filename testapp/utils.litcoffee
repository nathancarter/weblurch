
# Test app utilities

## Setup routine

The following routine is run after
[the test app page](../testapp/index.html) has finished loading.

    window.testAppSetup = ->

Create a `LurchEditor` instance in the page itself.

        window.LE =
            new LurchEditor document.getElementById 'editor'

Create global arrays in which we will store the history of all the
states of the model (i.e., `LE`'s element), as well as all lines of
code executed to cause changes of state.

        window.testHistory = [
            {
                code : ''
                state : LE.getElement().toJSON()
            }
        ]

Store in global variables the important UI elements on the page.

        '''
        source history historyBody historyTab codeInput
        runButton yesButton noButton
        ''' \
        .split( ' ' ).map ( id ) ->
            window[id] = document.getElementById id
        window.maindiv = LE.getElement()

Install event handlers for the buttons.

        ( $ runButton ).on 'click', runButtonClicked
        ( $ yesButton ).on 'click', yesButtonClicked
        ( $ noButton ).on 'click', noButtonClicked

Make the code input respond to the Enter key by auto-clicking the
run button.

        ( $ codeInput ).on 'keyup', ( event ) ->
            if event.keyCode is 13 then runButtonClicked()

Fill the source and/or history tabs only when they become visible,
so we're not always recomputing their contents.

        ( $ sourceTab ).on 'click', updateSourceTab
        ( $ historyTab ).on 'click', updateHistoryTab

Run [the routine](#source-synchronizer) that updates the source div
with the HTML source of the `LurchEditor`'s element.

        updateSourceTab()

Place the user's keyboard focus into the code input box.

        codeInput.focus()

## Event handlers

### Dispatcher

This function dispatches to either the source tab updater or the
history tab updater, depending on which one is visible, if either.

    window.updateDispatcher = ->
        if ( $ source ).hasClass 'active' then updateSourceTab()
        if ( $ history ).hasClass 'active' then updateHistoryTab()

### Source synchronizer

The following routine fills the source div with the HTML source of
the `LurchEditor`'s element.

    window.updateSourceTab = ->
        code = LE.getElement().outerHTML.replace( /&/g, '&amp;' )
                                        .replace( />/g, '&gt;' )
                                        .replace( /</g, '&lt;' )
                                        .replace( /'/g, '&apos;' )
                                        .replace( /"/g, '&quot;' )
        source.innerHTML = "<pre>#{code}</pre>"

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

        updateDispatcher()
        codeInput.value = ''
        codeInput.focus()

### Yes and no buttons

The event handlers for the "Mark right" and "Mark wrong" buttons
edit the last item pushed onto the `testHistory` stack.

    window.yesButtonClicked = ( event ) ->
        testHistory[testHistory.length - 1].correct = yes
        updateDispatcher()

    window.noButtonClicked = ( event ) ->
        testHistory[testHistory.length - 1].correct = no
        updateDispatcher()

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

