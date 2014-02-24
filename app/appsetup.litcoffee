
# Setup routine for the main app

The following routine is run after
[the main app page](../app/index.html) has finished loading, to
create a `LurchEditor` instance in the page itself.

    window.appSetup = ->
        window.LE =
            new LurchEditor document.getElementById 'editor'

