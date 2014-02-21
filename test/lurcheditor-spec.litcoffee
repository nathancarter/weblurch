
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
            @page.evaluate ->
                L = new LurchEditor()
                L.freeIds
            , ( err, result ) ->
                expect( result ).toEqual [ 0 ]
                done()

Calling `nextFreeId()` on a newly created instance should keep
yielding nonnegative integers starting with zero and counting
upwards.  The resulting `freeIds` array should have in it just
the next integer.

### nextFreeId() should count 0,1,2,...

        it 'nextFreeId() should count 0,1,2,...', ( done ) =>
            @page.evaluate ->
                L = new LurchEditor()
                result = []
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.nextFreeId()
                result.push L.freeIds
                result
            , ( err, result ) ->
                expect( result ).toEqual [ 0, 1, 2, 3, [ 4 ] ]
                done()

### addFreeId() re-inserts in order

After a newly created instance has undergone the same sequence of
`nextFreeId()` calls as above, then restoring the id 2 should put
it back on the `freeIds` list in the correct spot, but restoring
any id 4 or higher should do nothing.  Then calls to `nextFreeId`
should yield 2, 4, 5, 6, ...

        it 'addfreeId() re-inserts in order', ( done ) =>
            @page.evaluate ->
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
            , ( err, result ) ->
                expect( result ).toEqual [
                    [ 4 ] # first saved freeIds array
                    [ 2, 4 ] # second saved freeIds array
                    2, 4, 5, 6 # last four generated ids
                ]
                done()

### should return a null element

An instance of the `LurchEditor` class created without a div should
return null from its `getElement` method.

        it 'should return a null element', ( done ) =>
            @page.evaluate ->
                L = new LurchEditor()
                L.getElement()
            , ( err, result ) ->
                expect( result ).toBeNull()
                done()

## LurchEditor instances with DIVs

We now test constructing a new `LurchEditor` instance around an
existing DOM element, and verify that it does the correct things
with ids.  See the documentation in
[the Lurch Editor class itself](lurcheditor.litcoffee.html) for
details on what the constructor is expected to do in these
situations, or read each test description below.

    phantomDescribe 'LurchEditor instances with DIVs',
    './app/index.html', ->

When constructed in an empty DIV, it should give that DIV the id 0,
and thus have a free ids list of `[ 1 ]` aftewards.

### should give an empty DIV id 0

        it 'should give an empty DIV id 0', ( done ) =>
            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div
                L = new LurchEditor div
                [ parseInt( div.id ), L.freeIds ]
            , ( err, result ) ->
                expect( result ).toEqual [ 0, [ 1 ] ]
                done()

When constructed in a DIV containing a hierarchy of nested spans,
some of which have ids, all of which are invalid, it should remove
all of their old ids, and assign them each a new, unique,
nonnegative integer id.  In this test, we verify only that it
removed all of their old ids.

### should remove all invalid ids

        it 'should remove all invalid ids', ( done ) =>
            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML =
                    '''
                    <span id="yo">some span
                        <span id="inner">inner span</span>
                    </span>
                    <b id="-1">neg number</b>
                    <br>
                    <a href="foo" id="-0">weird</a>
                    <span id="1.0">int-ish float</span>
                    <span>
                        <span>
                            <span id="hank">way inside</span>
                        </span>
                        <i>italic</i>
                    </span>
                    '''
                oldids = 'yo inner -1 -0 1.0 hank'.split ' '

For each id we expect to be in the document (because it's mentioned
in the HTML code given above), record whether it was actually
present in the document.  (We record "is null" for each, and expect
all false results.)

                result = before: { }, after: { }
                for key in oldids
                    result.before[key] =
                        document.getElementById( key ) is null

Install the Lurch Editor in the DIV in question.

                L = new LurchEditor div

For each id that used to be in the document, record whether it is
still present in the document.  (We expect it to *not* be; we
record "is null" for each, and expect all true results.)

                for key in oldids
                    result.after[key] =
                        document.getElementById( key ) is null
                result
            , ( err, result ) ->

Verify that all the "before"s were not null.

                expect( result.before['yo'] ).toBeFalsy()
                expect( result.before['inner'] ).toBeFalsy()
                expect( result.before['-1'] ).toBeFalsy()
                expect( result.before['-0'] ).toBeFalsy()
                expect( result.before['1.0'] ).toBeFalsy()
                expect( result.before['hank'] ).toBeFalsy()

Verify that all the "after"s were null.

                expect( result.after['yo'] ).toBeTruthy()
                expect( result.after['inner'] ).toBeTruthy()
                expect( result.after['-1'] ).toBeTruthy()
                expect( result.after['-0'] ).toBeTruthy()
                expect( result.after['1.0'] ).toBeTruthy()
                expect( result.after['hank'] ).toBeTruthy()
                done()

### should assign unique integer ids

If we re-run the same test as the previous (creating a
`LurchEditor` class around the same DIV) we should find that it
has also assigned unique non-negative integer ids to each element
in the DOM tree beneath that DIV, starting with 0 and proceeding
upwards sequentially.

        it 'should assign unique integer ids', ( done ) =>
            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML =
                    '''
                    <span id="yo">some span
                        <span id="inner">inner span</span>
                    </span>
                    <b id="-1">neg number</b>
                    <br>
                    <a href="foo" id="-0">weird</a>
                    <span id="1.0">int-ish float</span>
                    <span>
                        <span>
                            <span id="hank">way inside</span>
                        </span>
                        <i>italic</i>
                    </span>
                    '''

Construct the `LurchEditor` instance around the div, as before.

                LE = new LurchEditor div

Now find all ids of all nodes under that div.

                allNodesUnder = ( node ) ->
                    result = [ node ]
                    for child in node.childNodes
                        result = result.concat allNodesUnder child
                    result
                {
                    ids: ( parseInt node.id for node in \
                            allNodesUnder div when node.id )
                    freeIds: LE.freeIds[..]
                }
            , ( err, result ) ->

Sort the ids and verify that the list is `[ 0, 1, ..., 10 ]`.
(There are nine tags in the HTML code above, plus the DIV
containing them.)

                result.ids.sort ( a, b ) -> a - b
                expect( result.ids[0] ).toEqual 0
                expect( result.ids[1] ).toEqual 1
                expect( result.ids[2] ).toEqual 2
                expect( result.ids[3] ).toEqual 3
                expect( result.ids[4] ).toEqual 4
                expect( result.ids[5] ).toEqual 5
                expect( result.ids[6] ).toEqual 6
                expect( result.ids[7] ).toEqual 7
                expect( result.ids[8] ).toEqual 8
                expect( result.ids[9] ).toEqual 9
                expect( result.ids[10] ).toEqual 10
                expect( result.ids.length ).toEqual 11

Verify that the list of free ids is "everything 11 and above."

                expect( result.freeIds ).toEqual [ 11 ]
                done()

### should work with existing integer ids

If we run a similar test to the previous two, but with the DIV
slightly altered to include a few valid integer ids, we should
find that it has also assigned unique non-negative integer ids to
each element in the DOM tree beneath that DIV, starting with 0 and
proceeding upwards sequentially, but keeping the existing valid
integer ids unchanged.

        it 'should work with existing integer ids', ( done ) =>
            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML =
                    '''
                    <span id="yo">some span
                        <span id="inner">inner span</span>
                    </span>
                    <b id="1">pos number</b>
                    <br>
                    <a href="foo" id="-0">weird</a>
                    <span id="20">big-ish number</span>
                    <span>
                        <span>
                            <span id="hank">way inside</span>
                        </span>
                        <i id=4>italic</i>
                    </span>
                    '''

Construct the `LurchEditor` instance around the div, as before.

                LE = new LurchEditor div

Now find all ids of all nodes under that div.

                allNodesUnder = ( node ) ->
                    result = [ node ]
                    for child in node.childNodes
                        result = result.concat allNodesUnder child
                    result
                result =
                    ids: ( parseInt node.id for node in \
                            allNodesUnder div when node.id )
                    freeIds: LE.freeIds[..]
                    texts: { }
                for i in [0..9].concat [ 20 ]
                    result.texts[i] =
                        document.getElementById( "#{i}" ) \
                            .textContent.replace /^\s+|\s+$/g, ''
                result
            , ( err, result ) ->

Sort the ids and verify that the list is `[ 0, 1, ..., 9, 20 ]`.
(There are nine tags in the HTML code above, plus the DIV
containing them.)

                result.ids.sort ( a, b ) -> a - b
                expect( result.ids[0] ).toEqual 0
                expect( result.ids[1] ).toEqual 1
                expect( result.ids[2] ).toEqual 2
                expect( result.ids[3] ).toEqual 3
                expect( result.ids[4] ).toEqual 4
                expect( result.ids[5] ).toEqual 5
                expect( result.ids[6] ).toEqual 6
                expect( result.ids[7] ).toEqual 7
                expect( result.ids[8] ).toEqual 8
                expect( result.ids[9] ).toEqual 9
                expect( result.ids[10] ).toEqual 20
                expect( result.ids.length ).toEqual 11

Verify that the list of free ids is "everything 10 and above,
except 20."

                expect( result.freeIds ).toEqual \
                    [ 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21 ]

Verify that the ids for the nodes that already had valid integer
ids were left unchanged.

                expect( result.texts[4] ).toEqual 'italic'
                expect( result.texts[1] ).toEqual 'pos number'
                expect( result.texts[20] ).toEqual 'big-ish number'
                done()

### should return the correct div

An instance of the `LurchEditor` class created without a div should
return null from its `getElement` method.

        it 'should return a null element', ( done ) =>
            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div

Construct the `LurchEditor` instance around the div, as before.

                LE = new LurchEditor div
                div is LE.getElement()
            , ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

