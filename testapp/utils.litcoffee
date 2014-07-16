
# Test app utilities

## Setup routine

The following routine is run after
[the test app page](../testapp/index.html) has finished loading.

    window.testAppSetup = ->

Create a `LurchEditor` instance in the page itself.

        window.LE =
            new LurchEditor document.getElementById 'editor'

Store in a global variable the div that will show the source code
for the `LurchEditor`'s element.

        window.srcdiv = document.getElementById 'source'

Run [the routine](#source-synchronizer) that updates the source div
with the HTML source of the `LurchEditor`'s element.

        updateSourceTab()

## Source synchronizer

The following routine fills the sourve div with the HTML source of
the `LurchEditor`'s element.

    window.updateSourceTab = ->
        code = LE.getElement().outerHTML.replace( /&/g, '&amp;' )
                                        .replace( />/g, '&gt;' )
                                        .replace( /</g, '&lt;' )
                                        .replace( /'/g, '&apos;' )
                                        .replace( /"/g, '&quot;' )
        srcdiv.innerHTML = "<pre>#{code}</pre>"

