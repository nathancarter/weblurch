
# Basic tests of compiled app code

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { startPhantom } = require './phantom-utils'

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
            startPhantom toLoad, ( ph, pg ) ->
                [ loaded, phantom, page ] = [ yes, ph, pg ]
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
            expect( page.reserr ).toBeFalsy()
            done()
        it 'should load without errors', ( done ) ->
            expect( page.err ).toBeFalsy()
            done()

### Verify that `LurchEditor` is defined

        it 'should have LurchEditor defined', ( done ) ->
            page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

