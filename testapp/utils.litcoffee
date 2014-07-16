
# Test app utilities

## Setup routine

The following routine is run after
[the test app page](../testapp/index.html) has finished loading.

    window.testAppSetup = ->

Create a `LurchEditor` instance in the page itself.

        window.LE =
            new LurchEditor document.getElementById 'editor'

Store in global variables the important UI elements on the page.

        'source codeInput runButton'.split( ' ' ).map ( id ) ->
            window[id] = document.getElementById id
        window.maindiv = LE.getElement()

Install the event handler for the run button, and make it happen
whenever the user presses the enter key in the code input.

        ( $ runButton ).on 'click', runButtonClicked
        ( $ codeInput ).on 'keyup', ( event ) ->
            if event.keyCode is 13 then runButtonClicked()

Run [the routine](#source-synchronizer) that updates the source div
with the HTML source of the `LurchEditor`'s element.

        updateSourceTab()

Place the user's keyboard focus into the code input box.

        codeInput.focus()

## Event handlers

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
        updateSourceTab()
        codeInput.value = ''
        codeInput.focus()

