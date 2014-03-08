
# Setup routine for the test app

The following routine is run after
[the test app page](../testapp/index.html) has finished loading, to
create a `LurchEditor` instance in the page itself.

    window.testAppSetup = ->
        window.LE =
            new LurchEditor document.getElementById 'editor'

