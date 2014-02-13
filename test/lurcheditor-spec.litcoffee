
# Tests for the `LurchEditor` class

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe } = require './phantom-utils'

### Verify that `LurchEditor` class exists

    phantomDescribe 'LurchEditor class', './app/index.html', ->
        it 'should exist', ( done ) =>
            @page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### Test `freeIds` API

A newly created `LurchEditor` instance should have a `freeIds`
array containing only zero.

    phantomDescribe 'LurchEditor instances', './app/index.html', ->
        it 'should initialize freeIds', ( done ) =>
            @page.evaluate ( ->
                L = new LurchEditor()
                L.freeIds
            ), ( err, result ) ->
                expect( result ).toEqual( [ 0 ] )
                done()

Calling `nextFreeId()` on a newly created instance should keep
yielding nonnegative integers starting with zero and counting
upwards.  The resulting `freeIds` array should have in it just
the next integer.

        it 'nextfreeId() should count 0,1,2,...', ( done ) =>
            @page.evaluate ( ->
                L = new LurchEditor()
                result = []
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.freeIds
                result
            ), ( err, result ) ->
                expect( result ).toEqual( [ 0, 1, 2, 3, [ 4 ] ] )
                done()

After a newly created instance has undergone the same sequence of
`nextFreeId()` calls as above, then restoring the id 2 should put
it back on the `freeIds` list in the correct spot, but restoring
any id 4 or higher should do nothing.  Then calls to `nextFreeId`
should yield 2, 4, 5, 6, ...

        it 'addfreeId() re-inserts in order', ( done ) =>
            @page.evaluate ( ->
                L = new LurchEditor()
                result = []
                L.nextFreeId() # four calls to nextFreeId()
                L.nextFreeId()
                L.nextFreeId()
                L.nextFreeId()
                result.push L.freeIds[..] # save current array
                L.addFreeId 2 # one call to addFreeId()
                result.push L.freeIds[..] # save current array
                result.push L.nextFreeId() # four more
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result
            ), ( err, result ) ->
                expect( result ).toEqual [
                    [ 4 ] # first saved freeIds array
                    [ 2, 4 ] # second saved freeIds array
                    2, 4, 5, 6 # last four generated ids
                ]
                done()

More to come on this unit test as more features of the
`LurchEditor` class are implemented.

