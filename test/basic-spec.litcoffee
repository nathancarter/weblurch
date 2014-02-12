
# Basic tests of compiled app code

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## Test `app/index.html` page

    phantomDescribe 'app index.html', './app/index.html', ->

### Verify that the page loads

        it 'should load', ( done ) =>
            expect( @page.loaded ).toBeTruthy()
            done()

### Verify that it loaded without errors

        it 'should find the page', ( done ) =>
            expect( @page.reserr ).toBeFalsy()
            done()
        it 'should load without errors', ( done ) =>
            expect( @page.err ).toBeFalsy()
            done()

### Verify that `LurchEditor` is defined

        it 'should have LurchEditor defined', ( done ) =>
            @page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

