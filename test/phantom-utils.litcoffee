
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
[Jasmine](http://jasmine.github.io/) by placing a call to this in a
`beforeEach` call.

    exports.startPhantom = ( url, callback ) ->
        nps.create ( err, phantom ) ->
            if err then console.log err ; throw err
            phantom.createPage ( err, page ) ->
                if err then console.log err ; throw err
                page.onResourceError = ( err ) -> page.reserr = err
                page.onError = ( err ) -> page.err = err
                page.open url, ( err, status ) ->
                    if err then console.log err ; throw err
                    callback phantom, page

