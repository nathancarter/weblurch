
# Utilities useful to the testing suite

The compiled app runs in a web browser, so this module provides
utility functions for dealing with the headless browser
[PhantomJS](http://phantomjs.org/) for use in automated testing.
This is done through a bridge from [node.js](http://nodejs.org/)
to PhantomJS, called [node-phantom-simple](
https://npmjs.org/package/node-phantom-simple).

    nps = require 'node-phantom-simple'

The following function makes it easy to set up a Phantom instance
and load into it a page from a given URL.  If any errors take place
during the loading process, they are thrown as exceptions, or
recorded as attributes of the page object.
 * `page.reserr` will be a resource error object, if there was a
   resource error
 * `page.err` will be a generic error object, if there was a
   generic error

This can easily be used within the asynchronous test framework in
[Jasmine](http://jasmine.github.io/) by replacing a call to
Jasmine's `describe` function with a call to this one.  An example
appears after the following code.

    exports.phantomDescribe = ( text, url, tests ) ->
        describe text, ->

An object in which to store the `phantom` and `page` objects
we'll create.

            P = phantom: null, page: null

Before each test, load the given page into the headless browser and
be sure it loaded successfully.

            beforeEach ( done ) ->
                nps.create ( err, ph ) ->
                    if err then console.log err ; throw err
                    P.phantom = ph
                    P.phantom.createPage ( err, pg ) ->
                        if err then console.log err ; throw err
                        P.page = pg
                        P.page.loaded = no
                        P.page.onResourceError = ( err ) ->
                            P.page.reserr = err
                        P.page.onError = ( err ) ->
                            P.page.err = err
                        P.page.open url, ( err, status ) ->
                            if err then console.log err ; throw err
                            P.page.loaded = yes
                            done()

After each test, tear down the headless browser so that the test
process will exit.

            afterEach ( done ) ->
                P.phantom.exit()
                done()

Run the tests that the user passed in as a function.
Provide the user the `phantom` and `page` objects from earlier
as attributes of the `this` object when `tests` is run.
Thus they can access them as `@phantom` and `@page`.

            tests.apply P

Example use (note the very important `=>` for preserving `this`):

    # phantomDescribe 'My page', './my.html', ( phantom, page ) ->
    #     it 'must load', ( done ) =>
    #         expect( page.loaded ).toBeTruthy()
    #         done()

