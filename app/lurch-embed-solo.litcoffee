
# Embedding Lurch in web pages

This file makes it easy to embed Lurch document snippets in web pages or
blogs, and have those snippets each become live Lurch applications, right
there in the page.  It contains functions for converting snippets into live
applications, and also interpreting a shorthand form of Lurch documents,
described below.

## Global variables

We use the following namespace.

    window.LurchEmbed = { }

The default location of the main webLurch application is the following.

IT IS SET TO LOCALHOST ONLY WHEN TESTING.  IT SHOULD ACTUALLY BE AT
`http://nathancarter.github.io/weblurch/app/app.html` BEFORE PUSHING THIS
CODE TO GITHUB.  IF YOU SEE THIS CODE ON GITHUB, I GOOFED.  SEND ME AN
EMAIL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    window.LurchEmbed.defaultURL = 'http://localhost:8000/app/app.html'

## Making snippets live

An HTML document author (or blog author) can paste into any DIV in the page
or blog source the exact HTML copied directly from a live Lurch application,
surrounded by a DIV (or other block-level element).  Running the following
function on that element converts it into a live Lurch application.

The second parameter is an optional set of key-value pairs to attach to the
constructed `iframe` element.  Most commonly, this should include its width
and height, which default to 800 and 400.

The final parameter is the URL to the Lurch application that should be used
to embed the main application.  It defaults to the location of the app on
GitHub, but can be replaced by any URL hosting the main application.

We respect the attribute "data-embed-index" so that we can use different
filenames in Local Storage for saving each embedded document on a page, to
prevent collisions/overwriting.  That attribute is set by the function in
the [automation section](#automating-the-process), below.

    window.LurchEmbed.makeLive =
    ( element, attributes = width : 800, height : 400, applicationURL = \
      window.LurchEmbed.defaultURL ) ->
        filename = 'auto-load'
        filename += index if index = element.getAttribute 'data-embed-index'
        localStorage.setItem filename,
            JSON.stringify [ { }, element.innerHTML ]
        url = applicationURL + '?autoload=' + filename
        replacement = element.ownerDocument.createElement 'iframe'
        replacement.style.border = '1px solid black'
        for own key, value of attributes
            replacement.setAttribute key, value
        ( $ element ).replaceWith replacement
        replacement.setAttribute 'src', url

## Automating the process

For convenience, we invoke the above function on every element in the
document with the class "lurch-embed".  Thus web page and blog authors do
not need to call any script functions.  They just mark some elements with a
specific class, and all is taken care of for them.

    $ ->
        ( $ '.lurch-embed' ).each ( index, element ) ->
            element.setAttribute 'data-embed-index', index
            window.LurchEmbed.makeLive element

Authors can use Lurch shorthand in their blocks simply by wrapping the
contents of the "lurch-embed" block in a single `<shorthand>...</shorthand>`
tag pair.  The embedded Lurch application will notice, from that wrapper,
that the content needs to be translated from Lurch shorthand, and will
perform that translation, simultaneously removing the wrapper.  This is
useful for writing Lurch document content in a human-readable form.  See
[the source code for document
import/export](main-app-import-export-solo.litcoffee) for details on Lurch
shorthand.
