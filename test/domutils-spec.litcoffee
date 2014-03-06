
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## address member function of Node class

The tests in this section test the `address` member function in the
`Node` prototype.
[See its definition here.](domutils.litcoffee.html#address).

    phantomDescribe 'address member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>

First, just verify that it's present.

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

The tests in this section test the `index` member function in the
`Node` prototype.  This function is like the inverse of `address`.
[See its definition here.](domutils.litcoffee.html#index).

    phantomDescribe 'index member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>
            @page.evaluate ( -> Node.prototype.index ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should give errors for non-arrays

        it 'should give errors for non-arrays', ( done ) =>

Verify that calls to the function throw errors if anything but an
array is passed as the argument.

            @page.evaluate ->
                result = []
                result.push try document.index 0 \
                            catch e then e.message
                result.push try document.index { 0: 0 } \
                            catch e then e.message
                result.push try document.index document \
                            catch e then e.message
                result.push try document.index ( -> ) \
                            catch e then e.message
                result.push try document.index '[0,0]' \
                            catch e then e.message
                result
            , ( err, result ) ->

Now verify that each of the items in the resulting array contains
the relevant portion of the expected error message.

                expect( /requires an array/.test result[0] )
                    .toBeTruthy()
                expect( /requires an array/.test result[1] )
                    .toBeTruthy()
                expect( /requires an array/.test result[2] )
                    .toBeTruthy()
                expect( /requires an array/.test result[3] )
                    .toBeTruthy()
                expect( /requires an array/.test result[4] )
                    .toBeTruthy()
                done()

### should yield itself for []

        it 'should yield itself for []', ( done ) =>

Verify that `N.index []` yields `N`, for any node `N`.
We test a variety of type of nodes, including the document, the
body, some DIVs and SPANs inside, as well as some DIVs and SPANs
that are not part of the document.

            @page.evaluate ->
                divInPage = document.createElement 'div'
                document.body.appendChild divInPage
                spanInPage = document.createElement 'span'
                document.body.appendChild spanInPage
                divOutside = document.createElement 'div'
                spanOutside = document.createElement 'span'
                [
                    divInPage is divInPage.index []
                    spanInPage is spanInPage.index []
                    divOutside is divOutside.index []
                    spanOutside is spanOutside.index []
                    document is document.index []
                    document.body is document.body.index []
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeTruthy()
                expect( result[4] ).toBeTruthy()
                expect( result[5] ).toBeTruthy()
                done()

### should work for descendant indices

        it 'should work for descendant indices', ( done ) =>
            @page.evaluate ->

Here we re-use the same hierarchy from [a test above](
#should-work-for-grandchildren-etc-), for the same reasons.

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

For the same reasons as above, we remove whitespace between tags
before creating a DOM structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Look up a lot of addresses, and store their ids (if they are
elements with ids) or their text content (if they are text nodes).

                [
                    div.index( [ 0 ] ).id
                    div.index( [ 1 ] ).id
                    div.index( [ 2 ] ).id
                    div.index( [ 0, 0 ] ).textContent
                    div.index( [ 1, 0 ] ).textContent
                    div.index( [ 2, 0 ] ).id
                    div.index( [ 2, 0, 0 ] ).textContent
                    div.index( [ 2, 1 ] ).id
                    div.index( [ 2, 1, 0 ] ).id
                    div.index( [ 2, 1, 0, 0 ] ).id
                    div.index( [ 2, 1, 0, 0, 1 ] ).textContent
                    div.index( [ 2, 1, 0, 1 ] ).id
                    div.index( [ 2, 1, 1 ] ).id
                ]

Verify the ids and text contents computed above match the
hierarchy and indices given.

            , ( err, result ) ->
                expect( result[0] ).toEqual 'test-0'
                expect( result[1] ).toEqual 'test-1'
                expect( result[2] ).toEqual 'test-2'
                expect( result[3] ).toEqual 'foo'
                expect( result[4] ).toEqual 'bar'
                expect( result[5] ).toEqual 'test-3'
                expect( result[6] ).toEqual 'baz'
                expect( result[7] ).toEqual 'test-4'
                expect( result[8] ).toEqual 'test-5'
                expect( result[9] ).toEqual 'test-6'
                expect( result[10] ).toEqual 'x'
                expect( result[11] ).toEqual 'test-7'
                expect( result[12] ).toEqual 'test-8'
                done()

### should give undefined for bad indices

        it 'should give undefined for bad indices', ( done ) =>

Verify that calls to the function return undefined if any step in
the address array is invalid.  There are many ways for this to
happen (entry less than zero, entry larger than number of children
at that level, entry not an integer, entry not a number at all).
We test each of these cases below.

            @page.evaluate ->

First we re-create the same hierarchy from [a test above](
#should-work-for-grandchildren-etc-), for the same reasons.

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

For the same reasons as above, we remove whitespace between tags
before creating a DOM structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Now call `div.index` with addresses that contain each of the
erroneous steps mentioned above.  Here we call `typeof` on each
of the return values, because we expect that they will be
undefined in each case, and we wish to populate our array with
that information in string form, so that it can be returned from
the page as valid JSON.

                [
                    typeof div.index [ -1 ]
                    typeof div.index [ 3 ]
                    typeof div.index [ 300000 ]
                    typeof div.index [ 0.2 ]
                    typeof div.index [ 'something' ]
                    typeof div.index [ 'childNodes' ]
                    typeof div.index [ [ 0 ] ]
                    typeof div.index [ [ ] ]
                    typeof div.index [ { } ]
                    typeof div.index [ div ]
                    typeof div.index [ 0, -1 ]
                    typeof div.index [ 0, 1 ]
                    typeof div.index [ 0, 'ponies' ]
                ]
            , ( err, result ) ->

Now verify that each of the items in the resulting array contains
the relevant portion of the expected error message.

                expect( result[0] ).toEqual 'undefined'
                expect( result[1] ).toEqual 'undefined'
                expect( result[2] ).toEqual 'undefined'
                expect( result[3] ).toEqual 'undefined'
                expect( result[4] ).toEqual 'undefined'
                expect( result[5] ).toEqual 'undefined'
                expect( result[6] ).toEqual 'undefined'
                expect( result[7] ).toEqual 'undefined'
                expect( result[8] ).toEqual 'undefined'
                expect( result[9] ).toEqual 'undefined'
                expect( result[10] ).toEqual 'undefined'
                expect( result[11] ).toEqual 'undefined'
                expect( result[12] ).toEqual 'undefined'
                done()

## Node toJSON conversion

The tests in this section test the `toJSON` member function in the
`Node` prototype.
[See its definition here.](domutils.litcoffee.html#serialization).

    phantomDescribe 'Node toJSON conversion',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>

First, just verify that the function itself is present.

            @page.evaluate ( -> Node.prototype.toJSON ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should convert text nodes to strings

        it 'should convert text nodes to strings', ( done ) =>
            @page.evaluate ->
                textNode = document.createTextNode 'foo'
                div = document.createElement 'div'
                div.innerHTML = '<i>italic</i> not italic'
                [
                    textNode.toJSON()
                    div.childNodes[0].childNodes[0].toJSON()
                    div.childNodes[1].toJSON()
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual 'foo'
                expect( result[1] ).toEqual 'italic'
                expect( result[2] ).toEqual ' not italic'
                done()

### should convert comment nodes to objects

        it 'should convert comment nodes to objects', ( done ) =>
            @page.evaluate ->
                comment1 = document.createComment 'comment content'
                comment2 = document.createComment ''
                [
                    comment1.toJSON()
                    comment2.toJSON()
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual \
                    comment : yes, content : 'comment content'
                expect( result[1] ).toEqual \
                    comment : yes, content : ''
                done()

### should handle spans correctly

        it 'should handle spans correctly', ( done ) =>

Must correctly convert things of the form `<span>text</span>` or
`<i>text</i>` or any other simple, non-nested tag.  Three simple
tests are done, plus one with two different attributes.

            @page.evaluate ->
                # <span>hello</span>, created this way:
                span1 = document.createElement 'span'
                span1.appendChild document.createTextNode 'hello'
                # <span>world</span>, created this way:
                span2 = document.createElement 'span'
                span2.innerHTML = 'world'
                # <i>The Great Gatsby</i>, lifted out of a div:
                div1 = document.createElement 'div'
                div1.innerHTML = '<i>The Great Gatsby</i>'
                # one with attributes, also lifted out of a div:
                div2 = document.createElement 'div'
                div2.innerHTML = '<i class="X" id="Y">Z</i>'
                [
                    span1.toJSON()
                    span2.toJSON()
                    div1.childNodes[0].toJSON()
                    div2.childNodes[0].toJSON()
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual {
                    tagName : 'SPAN'
                    attributes : { }
                    children : [ 'hello' ]
                }
                expect( result[1] ).toEqual {
                    tagName : 'SPAN'
                    attributes : { }
                    children : [ 'world' ]
                }
                expect( result[2] ).toEqual {
                    tagName : 'I'
                    attributes : { }
                    children : [ 'The Great Gatsby' ]
                }
                expect( result[3] ).toEqual {
                    tagName : 'I'
                    attributes : { class : 'X', id : 'Y' }
                    children : [ 'Z' ]
                }
                done()

### should handle hierarchies correctly

        it 'should handle hierarchies correctly', ( done ) =>

The above tests cover simple situations, either DOM trees of
height 1 or 2.  Now we consider situations in which there are
many levels to the Node tree.  I choose three examples, and mix in
a diversity of depths, attributes, tag names, comments, etc.

            @page.evaluate ->
                div1 = document.createElement 'div'
                div1.innerHTML = '<span class="outermost" id=0>' +
                                 '<span class="middleman" id=1>' +
                                 '<span class="innermost" id=2>' +
                                 'finally, the text' +
                                 '</span></span></span>'
                document.body.appendChild div1
                div2 = document.createElement 'div'
                div2.innerHTML = '<p>Some paragraph.</p>' +
                                 '<p>Another paragraph, this ' +
                                 'one with some ' +
                                 '<b>force!</b></p>' +
                                 '<table border=1>' +
                                 '<tr><td width=50%>Name</td>' +
                                 '<!--random comment-->' +
                                 '</td><td width=50%>Age</td>' +
                                 '</tr></table>'
                document.body.appendChild div2
                div3 = document.createElement 'div'
                div3.innerHTML = 'start with a text node' +
                                 '<!-- then a comment -->' +
                                 '<p>then <i>MORE</i></p>'
                document.body.appendChild div3
                [
                    div1.toJSON()
                    div2.toJSON()
                    div3.toJSON()
                ]
            , ( err, result ) ->
                expectedAnswer1 = {
                    tagName : 'DIV'
                    attributes : { }
                    children : [
                        {
                            tagName : 'SPAN'
                            attributes : {
                                class : 'outermost'
                                id : '0'
                            }
                            children : [
                                {
                                    tagName : 'SPAN'
                                    attributes : {
                                        class : 'middleman'
                                        id : '1'
                                    }
                                    children : [
                                        {
                                            tagName : 'SPAN'
                                            attributes : {
                                                class : 'innermost'
                                                id : '2'
                                            }
                                            children : [
                                                'finally, the text'
                                                
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
                expectedAnswer2 = {
                    tagName : 'DIV'
                    attributes : { }
                    children : [
                        {
                            tagName : 'P'
                            attributes : { }
                            children : [ 'Some paragraph.' ]
                        }
                        {
                            tagName : 'P'
                            attributes : { }
                            children : [
                                'Another paragraph, ' +
                                'this one with some '
                                {
                                    tagName : 'B'
                                    attributes : { }
                                    children : [ 'force!' ]
                                }
                            ]
                        }
                        {
                            tagName : 'TABLE'
                            attributes : { border : '1' }
                            children : [
                                {
                                    tagName : 'TBODY'
                                    attributes : { }
                                    children : [
                                        {
                                            tagName : 'TR'
                                            attributes : { }
                                            children : [
                                                {
                                                    tagName : 'TD'
                                                    attributes : {
                                                        width :
                                                            '50%'
                                                    }
                                                    children :
                                                        [ 'Name' ]
                                                }
                                                {
                                                    comment : yes
                                                    content :
                                                        'random ' +
                                                        'comment'
                                                }
                                                {
                                                    tagName : 'TD'
                                                    attributes : {
                                                        width :
                                                            '50%'
                                                    }
                                                    children :
                                                        [ 'Age' ]
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
                expectedAnswer3 = {
                    tagName : 'DIV'
                    attributes : { }
                    children : [
                        'start with a text node'
                        {
                            comment : yes
                            content : ' then a comment '
                        }
                        {
                            tagName : 'P'
                            attributes : { }
                            children : [
                                'then '
                                {
                                    tagName : 'I'
                                    attributes : { }
                                    children : [ 'MORE' ]
                                }
                            ]
                        }
                    ]
                }
                expect( result[0] ).toEqual expectedAnswer1
                expect( result[1] ).toEqual expectedAnswer2
                expect( result[2] ).toEqual expectedAnswer3
                done()

