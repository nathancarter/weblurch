
# Utilities useful to the testing suite

The compiled app runs in a web browser, so this module provides
utility functions for dealing with the headless browser
[PhantomJS](http://phantomjs.org/) for use in automated testing.
This is done through a bridge from [node.js](http://nodejs.org/)
to PhantomJS, called [node-phantom-simple](
https://npmjs.org/package/node-phantom-simple).

We also include
[stack-trace](https://www.npmjs.org/package/stack-trace) because
it is useful for knowing which files call `phantomDescribe`,
below, so that those files can be logged for use in documentation
generation later.

    nps = require 'node-phantom-simple'
    st = require 'stack-trace'

# The main API, `phantomDescribe`

The `phantomDescribe` function makes it easy to set up a PhantomJS
instance and load into it a page from a given URL.  If any errors
take place during the loading process, they are thrown as
exceptions, or recorded as attributes of the page object.
 * `page.reserr` will be a resource error object, if there was a
   resource error
 * `page.err` will be a generic error object, if there was a
   generic error

This can easily be used within the asynchronous test framework in
[Jasmine](http://jasmine.github.io/) by replacing a call to
Jasmine's `describe` function with a call to `phantomDescribe`.
An example appears [further below](#example).

# Private API

Here is a global variable in which I store the one PhantomJS
instance I create.  (Creating many PhantomJS instances
leads to errors about too many listeners for an `EventEmitter`, so
I use one global PhantomJS instance.)  It starts uninitialized,
and I prove a function for querying whether it has been
initialized since then.

    P = phantom: null, page: null
    phantomInitialized = -> P?.phantom and P?.page

This function loads into that global instance any given URL.
It does not check `phantomInitialized` first; that is the business
of the next function, below.
Once the URL is loaded, this function calls the given callback.

It sets `P.page` to be false before the page opening is attempted,
and sets it to true if the opening complets without error.

    loadURLInPhantom = ( url, callback ) ->
        P.page.loaded = no
        P.page.open url, ( err, status ) ->
            if err then console.log err ; throw err
            P.page.loaded = yes
            callback()
            
This function initializes the global variable `P`, loads the given
URL into the page stored in that global variable, and then calls a
callback function.  If `P` was already initialized, then this just
calls the callback.

    initializePhantom = ( url, callback ) ->
        if phantomInitialized()
            loadURLInPhantom url, callback
        else
            nps.create ( err, ph ) ->
                if err then console.log err ; throw err
                P.phantom = ph
                P.phantom.createPage ( err, pg ) ->
                    if err then console.log err ; throw err
                    P.page = pg
                    P.page.onResourceError = ( err ) ->
                        console.log 'Page resource error:', err
                        P.page.reserr = err
                    P.page.onError = ( err ) ->
                        console.log 'Page error:', err
                        P.page.err = err
                    P.page.onConsoleMessage = ( message ) ->
                        console.log message
                    loadURLInPhantom url, callback

# Public API

And now we define the one function this module exports, which will
initialize the members of `P` if and when needed.

    exports.phantomDescribe = ( text, url, tests ) ->

First, we record which unit test called this function.  See the
documentation for `logUnitTestName` below for additional details.

        logUnitTestName text
        describe text, ->

Before each test, load the given page into the headless browser and
be sure it loaded successfully.

            beforeEach ( done ) -> initializePhantom url, done

Run the tests that the user passed in as a function.
Provide the user the `phantom` and `page` objects from earlier
as attributes of the `this` object when `tests` is run.
Thus they can access them as `@phantom` and `@page`.

            tests.apply P

# Example

Example use (note the very important `=>` for preserving `this`):

    # phantomDescribe 'My page', './index.html', ->
    #     it 'must load', ( done ) =>
    #         expect( @page.loaded ).toBeTruthy()
    #         done()

# Logging unit test names and filenames

We want to keep track of the mapping from unit test names to
filenames in which they were defined, so that documentation
generation can create links from test results to files that
define those tests.  This function uses the stack trace to find
which unit test file (of the form `\*-spec.litcoffee`) made a
call to `phantomDescribe`, and logs that data in a JSON file in
the test reports directory.

    savefile = './reports/unit-test-names.json'
    logUnitTestName = ( name ) ->
        fs = require 'fs'
        try
            mapping = JSON.parse fs.readFileSync savefile
        catch error
            mapping = { }
        for frame in st.get()
            fn = frame.getFileName()
            if /-spec\.litcoffee/.test fn
                mapping[name] = ( fn.split '/' ).pop()
                fs.writeFileSync savefile,
                                 JSON.stringify mapping, null, 2
                break

