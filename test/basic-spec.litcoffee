
# Basic tests of compiled app code

Because the compiled app runs in a web browser, we load up the
headless browser [PhantomJS](http://phantomjs.org/) for these
tests.  This is done through a bridge from
[node.js](http://nodejs.org/) to PhantomJS called
[node-phantom-simple](https://npmjs.org/package/node-phantom-simple).

    nps = require 'node-phantom-simple'

## `app/index.html` page

    describe 'app index.html', ->
        toLoad = './app/index.html'

### Verify that the page loads

In the [Jasmine](http://jasmine.github.io/) testing framework,
asynchronous tests are handled using `beforeEach` functions that
take `done` functions as arguments.  You call `done()` when the
setup is complete, and all tests will wait for that call to
happen.  Each test must then also call `done()` before flow will
proceed on to any other tests thereafter.

        loaded = no
        beforeEach ( done ) ->
            nps.create ( err, phantom ) ->
                if err then console.log err ; throw err
                phantom.createPage ( err, page ) ->
                    if err then console.log err ; throw err
                    page.open toLoad, ( err, status ) ->
                        if err then console.log err ; throw err
                        loaded = yes
                        phantom.exit()
                        done()
        it 'should load', ( done ) ->
            expect( loaded ).toBeTruthy()
            done()

### Verify that it loaded without errors

This test not yet implemented.

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

