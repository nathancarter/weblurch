
# Tests for the `LurchEditor` class

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe } = require './phantom-utils'

## LurchEditor class

    phantomDescribe 'LurchEditor class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', ( done ) =>
            @page.evaluate ( -> LurchEditor ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

## LurchEditor instances without DIVs

    phantomDescribe 'LurchEditor instances without DIVs',
    './app/index.html', ->

### should initialize freeIds

A newly created `LurchEditor` instance should have a `freeIds`
array containing only zero.

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

### nextFreeId() should count 0,1,2,...

        it 'nextFreeId() should count 0,1,2,...', ( done ) =>
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

### addFreeId() re-inserts in order

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

## LurchEditor instances with DIVs

Nothing has been tested regarding constructing a new `LurchEditor`
instance around an existing DOM element, and verifying that it
does the correct things with the IDs.  See the documentation in
[the Lurch Editor class itself](lurcheditor.litcoffee.html) for
more information on what the constructor is expected to do in
those situations.

## To come

More to come on this unit test as more features of the
`LurchEditor` class are implemented.

