
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## address function

    phantomDescribe 'address function', './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>
            @page.evaluate ( -> address ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should give null on corner cases

        it 'should give null on corner cases', ( done ) =>

The corner cases to be tested here are these:
 * The address of a DOM node within one of its children.
 * The address of a DOM node within one of its siblings.
Although there are others we could test, these are enough for now.

            @page.evaluate ->
                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
                [
                    address( pardiv, chidiv1 ) is null
                    address( pardiv, chidiv2 ) is null
                    address( chidiv1, chidiv2 ) is null
                    address( chidiv2, chidiv1 ) is null
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeTruthy()
                done()

### should be empty for N,N

        it 'should be empty for N,N', ( done ) =>

We will test a few cases of `N,N` for various `N`.

            @page.evaluate ->
                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
                [
                    address( pardiv, pardiv )
                    address( chidiv1, chidiv1 )
                    address( chidiv2, chidiv2 )
                    address( document, document )
                    address( document.body, document.body )
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ ]
                expect( result[1] ).toEqual [ ]
                expect( result[2] ).toEqual [ ]
                expect( result[3] ).toEqual [ ]
                expect( result[4] ).toEqual [ ]
                done()

### should be empty for top-level,null

        it 'should be empty for top-level,null', ( done ) =>

The simplest way to test this is to compute the address of the
document, and expect it to be the empty array.  But we also have
the document create an empty div and not put it inside any other
node, and we expect that its address will also be the empty array.

            @page.evaluate ->
                [
                    address document
                    address document.createElement 'div'
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ ]
                expect( result[1] ).toEqual [ ]
                done()

### should be length-1 for a child

        it 'should be length-1 for a child', ( done ) =>
            @page.evaluate ->

First, add some structure to the document.

                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2

Next, create some structure outside the document.

                outer = document.createElement 'div'
                inner = document.createElement 'span'
                outer.appendChild inner

We call the `address` function in several different ways, but each
time we call it on an immediate child of the second argument
(or an immediate child of the document, with no second argument).
Sometimes we compute the same result in both of those ways to
verify that they are equal.

                [
                    address document.childNodes[0], document
                    address document.childNodes[0]
                    address chidiv1, pardiv
                    address chidiv2, pardiv
                    address pardiv, document.body
                    document.body.childNodes.length
                    address inner, outer
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ 0 ]
                expect( result[1] ).toEqual [ 0 ]
                expect( result[2] ).toEqual [ 0 ]
                expect( result[3] ).toEqual [ 1 ]

The next line verifies that `pardiv` was the last element in the
list of child nodes of the document body.

                expect( result[4] ).toEqual [ result[5]-1 ]
                expect( result[6] ).toEqual [ 0 ]
                done()


### should work for grandchildren, etc.

        it 'should work for grandchildren, etc.', ( done ) =>
            @page.evaluate ->

First, we construct a hierarchy with several levels so that we can
ask questions across those various levels.  This also ensures that
we know exactly what the child indices are, because we designed
the hierarchy in the first place.  I am careful to allow no
whitespace between 

                hierarchy = '''
                    <span id="test-0">foo</span>
                    <span id="test-1">bar</span>
                    <div id="test-2">
                        <span id="test-3">baz</span>
                        <div id="test-4">
                            <div id="test-5">
                                <span id="test-6">
                                    f(<i>x</i>)
                                </span>
                                <span id="test-7">
                                    f(<i>x</i>)
                                </span>
                            </div>
                            <div id="test-8">
                            </div>
                        </div>
                    </div>
                    '''

In order to ensure that we do not insert any text nodes that would
ruin our index counts, we first process that string to remove
unwanted whitespace.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy
                elts = ( document.getElementById "test-#{i}" \
                    for i in [0..8] )

We check the address of each test element inside the div we just
created, as well as inside the div called `test-2`.

                [
                    address elts[0], div
                    address elts[1], div
                    address elts[2], div
                    address elts[3], div
                    address elts[4], div
                    address elts[5], div
                    address elts[6], div
                    address elts[7], div
                    address elts[8], div
                    address elts[2], elts[2]
                    address elts[3], elts[2]
                    address elts[4], elts[2]
                    address elts[5], elts[2]
                    address elts[6], elts[2]
                    address elts[7], elts[2]
                    address elts[8], elts[2]
                ]

When checking addresses, note that `result[i]` corresopnds to the
node with id "test-i", for any $i\in\{0,1,\ldots,7,8\}$.

            , ( err, result ) ->

First, check the descendants of the main div.

                expect( result[0] ).toEqual [ 0 ]
                expect( result[1] ).toEqual [ 1 ]
                expect( result[2] ).toEqual [ 2 ]
                expect( result[3] ).toEqual [ 2, 0 ]
                expect( result[4] ).toEqual [ 2, 1 ]
                expect( result[5] ).toEqual [ 2, 1, 0 ]
                expect( result[6] ).toEqual [ 2, 1, 0, 0 ]
                expect( result[7] ).toEqual [ 2, 1, 0, 1 ]
                expect( result[8] ).toEqual [ 2, 1, 1 ]

Next, check the descendants of the element with id `test-2`.

                expect( result[9] ).toEqual [ ]
                expect( result[10] ).toEqual [ 0 ]
                expect( result[11] ).toEqual [ 1 ]
                expect( result[12] ).toEqual [ 1, 0 ]
                expect( result[13] ).toEqual [ 1, 0, 0 ]
                expect( result[14] ).toEqual [ 1, 0, 1 ]
                expect( result[15] ).toEqual [ 1, 1 ]
                done()

### should throw errors on non-nodes

Each of the various silly things tried below should all throw an
exception.  Thus we put each in a `try`-`catch` block that returns
the computed value if no error occurred, or the error message if
one did occur.  We verify that an error occurs in every case.

        it 'should throw errors on non-nodes', ( done ) =>

Computing the address of a numeric literal should throw an error.
We verify that the message returned contains some of the error
text we expect.

            @page.evaluate ->
                try address 3 catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()

Computing the address of an empty object should throw an error.
Same test as above.

            @page.evaluate ->
                try address { } catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()

Computing the address of an array of nodes should throw an error.
Same test as above.

            @page.evaluate ->
                node1 = document.body
                node2 = document.createElement 'div'
                node1.appendChild node2
                try address [ node1, node2 ] catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()

Now repeat the same three tests, but this time also pass in valid
nodes as second parameters.  The errors should still be thrown.

            @page.evaluate ->
                try address 3, document catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()
            @page.evaluate ->
                try address { }, document catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()
            @page.evaluate ->
                node1 = document.body
                node2 = document.createElement 'div'
                node1.appendChild node2
                try address [ node1, node2 ], document
                catch e then e.message
            , ( err, result ) ->
                expect( /requires.*Node/.test result ).toBeTruthy()
                done()

