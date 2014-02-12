
# Tests for the `LurchEditor` class

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { startPhantom } = require './phantom-utils'
    describe 'LurchEditor class', ->
        loaded = no
        phantom = null
        page = null
        beforeEach ( done ) ->
            startPhantom './app/index.html', ( ph, pg ) ->
                [ loaded, phantom, page ] = [ yes, ph, pg ]
                done()
        afterEach ( done ) ->
            phantom.exit()
            done()

### Verify that `LurchEditor` class exists

        it 'should exist', ( done ) ->
            page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### Test `freeIds` API

        it 'instances should initialize freeIds', ( done ) ->
            page.evaluate ( ->
                L = new LurchEditor()
                L.freeIds
            ), ( err, result ) ->
                expect( result ).toEqual( [ 0 ] )
                done()

Much more to come on this unit test...

