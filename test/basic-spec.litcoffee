
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

First, a few variables that will be set up before each test and
then used during the tests, so they are declared at this scope.

        loaded = no
        phantom = null
        page = null

In the [Jasmine](http://jasmine.github.io/) testing framework,
asynchronous tests are handled using `beforeEach` functions that
take `done` functions as arguments.  You call `done()` when the
setup is complete, and all tests will wait for that call to
happen.  Each test must then also call `done()` before flow will
proceed on to any other tests thereafter.

        beforeEach ( done ) ->
            nps.create ( err, ph) ->
                if err then console.log err ; throw err
                phantom = ph
                phantom.createPage ( err, pg ) ->
                    if err then console.log err ; throw err
                    page = pg
                    page.onResourceError = ( err ) ->
                        nps.reserr = err
                    page.onError = ( err ) -> nps.err = err
                    page.open toLoad, ( err, status ) ->
                        if err then console.log err ; throw err
                        loaded = yes
                        done()

After each test, we must clean up with a corresponding `afterEach`
call, which simply ends the Phantom process.

        afterEach ( done ) ->
            phantom.exit()
            done()

### Verify that the page loads

        it 'should load', ( done ) ->
            expect( loaded ).toBeTruthy()
            done()

### Verify that it loaded without errors

        it 'should find the page', ( done ) ->
            expect( nps.reserr ).toBeFalsy()
            done()
        it 'should load without errors', ( done ) ->
            expect( nps.err ).toBeFalsy()
            done()

### Verify that `LurchEditor` is defined

        it 'should have LurchEditor defined', ( done ) ->
            page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

