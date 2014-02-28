
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## address member function of Node class

    phantomDescribe 'address member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>
            @page.evaluate ( -> Node.prototype.address ),
            ( err, result ) ->
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
                    pardiv.address( chidiv1 ) is null
                    pardiv.address( chidiv2 ) is null
                    chidiv1.address( chidiv2 ) is null
                    chidiv2.address( chidiv1 ) is null
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeTruthy()
                done()

### should be empty when argument is this

        it 'should be empty when argument is this', ( done ) =>

We will test a few cases where the argument is the node it's being
called on, for various nodes.

            @page.evaluate ->
                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
                [
                    pardiv.address( pardiv )
                    chidiv1.address( chidiv1 )
                    chidiv2.address( chidiv2 )
                    document.address( document )
                    document.body.address( document.body )
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
document, and expect it to be the empty array.  But we also make
the document create an empty div and not put it inside any other
node, and we expect that its address will also be the empty array.

            @page.evaluate ->
                [
                    document.address()
                    document.createElement( 'div' ).address()
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ ]
                expect( result[1] ).toEqual [ ]
                done()

### should be length-1 for a child

        it 'should be length-1 for a child', ( done ) =>
            @page.evaluate ->

First, add some structure to the document.
We will need to run tests on a variety of parent-child pairs of
nodes, so we need to create such pairs as structures in the
document first.

                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2

Next, create some structure *outside* the document.
We want to verify that our routines work outside the page's
document as well.

                outer = document.createElement 'div'
                inner = document.createElement 'span'
                outer.appendChild inner

We call the `address` function in several different ways, but each
time we call it on an immediate child of the argument (or an
immediate child of the document, with no argument).  Sometimes we
compute the same result in both of those ways to verify that they
are equal.

                [
                    document.childNodes[0].address document
                    document.childNodes[0].address()
                    chidiv1.address pardiv
                    chidiv2.address pardiv
                    pardiv.address document.body
                    document.body.childNodes.length
                    inner.address outer
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
the hierarchy in the first place.

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
change the expected indices of the elements in the HTML code above,
we remove whitespace between tags before creating a DOM structure
from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy
                elts = ( document.getElementById "test-#{i}" \
                    for i in [0..8] )

We check the address of each test element inside the div we just
created, as well as its address relative to the div with id
`test-2`.

                [
                    elts[0].address div
                    elts[1].address div
                    elts[2].address div
                    elts[3].address div
                    elts[4].address div
                    elts[5].address div
                    elts[6].address div
                    elts[7].address div
                    elts[8].address div
                    elts[2].address elts[2]
                    elts[3].address elts[2]
                    elts[4].address elts[2]
                    elts[5].address elts[2]
                    elts[6].address elts[2]
                    elts[7].address elts[2]
                    elts[8].address elts[2]
                ]

When checking addresses, note that `result[i]` corresponds to the
node with id "test-i", for any $i\in\{0,1,\ldots,7,8\}$.

            , ( err, result ) ->

First, check all descendants of the main div.

                expect( result[0] ).toEqual [ 0 ]
                expect( result[1] ).toEqual [ 1 ]
                expect( result[2] ).toEqual [ 2 ]
                expect( result[3] ).toEqual [ 2, 0 ]
                expect( result[4] ).toEqual [ 2, 1 ]
                expect( result[5] ).toEqual [ 2, 1, 0 ]
                expect( result[6] ).toEqual [ 2, 1, 0, 0 ]
                expect( result[7] ).toEqual [ 2, 1, 0, 1 ]
                expect( result[8] ).toEqual [ 2, 1, 1 ]

Next, check the descendants of the element with id `test-2` for
their addresses relative to that element.

                expect( result[9] ).toEqual [ ]
                expect( result[10] ).toEqual [ 0 ]
                expect( result[11] ).toEqual [ 1 ]
                expect( result[12] ).toEqual [ 1, 0 ]
                expect( result[13] ).toEqual [ 1, 0, 0 ]
                expect( result[14] ).toEqual [ 1, 0, 1 ]
                expect( result[15] ).toEqual [ 1, 1 ]
                done()

## index member function of Node class

    phantomDescribe 'index member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>
            @page.evaluate ( -> Node.prototype.index ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

