
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## address member function of Node class

The tests in this section test the `address` member function in
the `Node` prototype.
[See its definition here.](domutils.litcoffee.html#address).

    phantomDescribe 'address member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>

First, just verify that it's present.

            @page.evaluate ( -> Node::address ),
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
            @page.evaluate ( -> Node::index ),
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

Here we re-use the same hierarchy from
[a test above](#should-work-for-grandchildren-etc-),
for the same reasons.

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

First we re-create the same hierarchy from
[a test above](#should-work-for-grandchildren-etc-),
for the same reasons.

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
[See its definition here.](domutils.litcoffee.html#serialization)

    phantomDescribe 'Node toJSON conversion',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>

First, just verify that the function itself is present.

            @page.evaluate ( -> Node::toJSON ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should convert text nodes to strings

        it 'should convert text nodes to strings', ( done ) =>

HTML text nodes should serialize as ordinary strings.
We test a variety of ways they might occur.

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

HTML comment nodes should serialize as objects with the comment
flag and the comment's text content as well.

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

### should handle other no-children elements

        it 'should handle other no-children elements', ( done ) =>

Other no-children elements include images, horizontal rules, and
line breaks.  We verify that in each case the object is encoded
with the correct tag name and attributes, but no children.

            @page.evaluate ->
                div = document.createElement 'div'
                div.innerHTML = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC" width="31" height="24">' +
                                '<hr><br>'
                div.childNodes[i].toJSON() for i in [0..2]
            , ( err, result ) ->
                expect( result[0] ).toEqual {
                    tagName : 'IMG'
                    attributes : {
                        width : '31'
                        height : '24'
                        src : 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC'
                    }
                }
                expect( result[1] ).toEqual tagName : 'HR'
                expect( result[2] ).toEqual tagName : 'BR'
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
                    children : [ 'hello' ]
                }
                expect( result[1] ).toEqual {
                    tagName : 'SPAN'
                    children : [ 'world' ]
                }
                expect( result[2] ).toEqual {
                    tagName : 'I'
                    children : [ 'The Great Gatsby' ]
                }
                expect( result[3] ).toEqual {
                    tagName : 'I'
                    attributes : class : 'X', id : 'Y'
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
                    children : [
                        {
                            tagName : 'P'
                            children : [ 'Some paragraph.' ]
                        }
                        {
                            tagName : 'P'
                            children : [
                                'Another paragraph, ' +
                                'this one with some '
                                {
                                    tagName : 'B'
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
                                    children : [
                                        {
                                            tagName : 'TR'
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
                    children : [
                        'start with a text node'
                        {
                            comment : yes
                            content : ' then a comment '
                        }
                        {
                            tagName : 'P'
                            children : [
                                'then '
                                {
                                    tagName : 'I'
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

### should respect verbosity setting

        it 'should respect verbosity setting', ( done ) =>

The verbosity setting of the serializer defaults to true, and gives
results like those shown in the tests above, whose object keys are
human-readable.  If verbosity is disabled, as in the tests below,
then each key is shrunk to a unique one-letter abbreviation, as
documented [in the module where the serialization is implemented](
domutils.litcoffee.html#serialization).

Here we do only one, brief test of each of the types tested above.

            @page.evaluate ->
                node1 = document.createTextNode 'text node'
                node2 = document.createComment 'swish'
                node3 = document.createElement 'hr'
                div = document.createElement 'div'
                div.innerHTML = '<p align="left">paragraph</p>' +
                                '<p><span id="foo">bar</span>' +
                                ' <i class="baz">quux</i></p>'
                node4 = div.childNodes[0]
                node5 = div.childNodes[1]
                [
                    node1.toJSON no
                    node2.toJSON no
                    node3.toJSON no
                    node4.toJSON no
                    node5.toJSON no
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual 'text node'
                expect( result[1] ).toEqual m : yes, n : 'swish'
                expect( result[2] ).toEqual t : 'HR'
                expect( result[3] ).toEqual {
                    t : 'P'
                    a : align : 'left'
                    c : [ 'paragraph' ]
                }
                expect( result[4] ).toEqual {
                    t : 'P'
                    c : [
                        {
                            t : 'SPAN'
                            a : id : 'foo'
                            c : [ 'bar' ]
                        }
                        ' '
                        {
                            t : 'I'
                            a : class : 'baz'
                            c : [ 'quux' ]
                        }
                    ]
                }
                done()

## Node fromJSON conversion

The tests in this section test the `fromJSON` member function in
the `Node` object.
[See its definition here.](
domutils.litcoffee.html#from-objects-to-dom-nodes)

    phantomDescribe 'Node fromJSON conversion',
    './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>

First, just verify that the function itself is present.

            @page.evaluate ( -> Node.fromJSON ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should convert strings to text nodes

        it 'should convert strings to text nodes', ( done ) =>

This test is simply the inverse of the analogous test earlier.
It verifies that two strings, one empty and one nonempty, both get
converted correctly into `Text` instances with the appropriate
content.

            @page.evaluate ->
                node1 = Node.fromJSON 'just a string'
                node2 = Node.fromJSON ''
                [
                    node1 instanceof Node
                    node1 instanceof Text
                    node1 instanceof Comment
                    node1 instanceof Element
                    node1.textContent
                    node2 instanceof Node
                    node2 instanceof Text
                    node2 instanceof Comment
                    node2 instanceof Element
                    node2.textContent
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeFalsy()
                expect( result[3] ).toBeFalsy()
                expect( result[4] ).toEqual 'just a string'
                expect( result[5] ).toBeTruthy()
                expect( result[6] ).toBeTruthy()
                expect( result[7] ).toBeFalsy()
                expect( result[8] ).toBeFalsy()
                expect( result[9] ).toEqual ''
                done()

### should handle comment objects

        it 'should handle comment objects', ( done ) =>

This test is simply the inverse of the analogous test earlier.
It verifies that two objects, one in verbose and one in
non-verbose notation, one empty and one nonempty, both get
converted correctly into `Comment` instances with the appropriate
content.

            @page.evaluate ->
                node1 = Node.fromJSON m : yes, n : 'some comment'
                node2 = Node.fromJSON comment : yes, content : ''
                [
                    node1 instanceof Node
                    node1 instanceof Text
                    node1 instanceof Comment
                    node1 instanceof Element
                    node1.textContent
                    node2 instanceof Node
                    node2 instanceof Text
                    node2 instanceof Comment
                    node2 instanceof Element
                    node2.textContent
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeFalsy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeFalsy()
                expect( result[4] ).toEqual 'some comment'
                expect( result[5] ).toBeTruthy()
                expect( result[6] ).toBeFalsy()
                expect( result[7] ).toBeTruthy()
                expect( result[8] ).toBeFalsy()
                expect( result[9] ).toEqual ''
                done()

### should be able to create empty elements

        it 'should be able to create empty elements', ( done ) =>

This test is simply the inverse of the analogous test earlier.
It verifies that two objects, one in verbose and one in
non-verbose notation, both get converted correctly into `Element`
instances with no children but the appropriate tags and
attributes.

            @page.evaluate ->
                node1 = Node.fromJSON \
                    tagName : 'hr',
                    attributes : class : 'y', whatever : 'dude'
                node2 = Node.fromJSON t : 'br', a : id : '24601'
                [
                    node1 instanceof Node
                    node1 instanceof Text
                    node1 instanceof Comment
                    node1 instanceof Element
                    node1.tagName
                    node1.childNodes.length
                    node1.attributes.length
                    node1.attributes[0].name
                    node1.attributes[0].value
                    node1.attributes[1].name
                    node1.attributes[1].value
                    node2 instanceof Node
                    node2 instanceof Text
                    node2 instanceof Comment
                    node2 instanceof Element
                    node2.tagName
                    node2.childNodes.length
                    node2.attributes.length
                    node2.attributes[0].name
                    node2.attributes[0].value
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeFalsy()
                expect( result[2] ).toBeFalsy()
                expect( result[3] ).toBeTruthy()
                expect( result[4] ).toEqual 'HR'
                expect( result[5] ).toEqual 0
                expect( result[6] ).toEqual 2
                expect( result[7] ).toEqual 'class'
                expect( result[8] ).toEqual 'y'
                expect( result[9] ).toEqual 'whatever'
                expect( result[10] ).toEqual 'dude'
                expect( result[11] ).toBeTruthy()
                expect( result[12] ).toBeFalsy()
                expect( result[13] ).toBeFalsy()
                expect( result[14] ).toBeTruthy()
                expect( result[15] ).toEqual 'BR'
                expect( result[16] ).toEqual 0
                expect( result[17] ).toEqual 1
                expect( result[18] ).toEqual 'id'
                expect( result[19] ).toEqual '24601'
                done()

### should build depth-one DOM trees

        it 'should build depth-one DOM trees', ( done ) =>

This test is simply the inverse of the analogous test earlier.
Depth-one trees are those that are objects with a children array,
no child of which has any children itself.  We test with one that
uses verbose notation and one using non-verbose.  In each case,
some of the parts have attributes and some don't.

            @page.evaluate ->
                node1 = Node.fromJSON {
                    t : 'I'
                    c : [
                        'non-bold stuff, followed by '
                        {
                            t : 'B'
                            a : class : 'C', id : '123'
                            c : 'bold stuff'
                        }
                    ]
                }
                node2 = Node.fromJSON {
                    tagName : 'p'
                    attributes : {
                        style : 'border: 1px solid gray;'
                        width : '100%'
                    }
                    children : [
                        {
                            tagName : 'span'
                            children : [ 'some text' ]
                        }
                        {
                            tagName : 'span'
                            children : [ 'yup, more text' ]
                        }
                    ]
                }
                [
                    node1.outerHTML
                    node2.outerHTML
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual \
                    '<i>non-bold stuff, followed by ' +
                    '<b class="C" id="123">bold stuff</b></i>'
                expect( result[1] ).toEqual \
                    '<p style="border: 1px solid gray;" ' +
                    'width="100%"><span>some text</span>' +
                    '<span>yup, more text</span></p>'
                done()

### should build deep DOM trees

        it 'should build depth-one DOM trees', ( done ) =>

This test is simply the inverse of the analogous test earlier.
The routines for building DOM trees from JSON objects should be
able to create many-level, nested structures.  Here I mix
verbose and non-verbose notation in one, large test, to be sure
that this works.

            @page.evaluate ->
                node = Node.fromJSON {
                    t : 'div'
                    a : class : 'navigation', width : '600'
                    c : [
                        {
                            t : 'div'
                            a : id : 'paragraph1'
                            c : [
                                {
                                    t : 'span'
                                    c : [ 'Start paragraph 1.' ]
                                }
                                {
                                    t : 'span'
                                    c : [ 'Middle paragraph 1.' ]
                                }
                                {
                                    t : 'span'
                                    c : [ 'End paragraph 1.' ]
                                }
                            ]
                        }
                        {
                            tagName : 'div'
                            attributes : {
                                id : 'paragraph2'
                                style : 'padding : 5px;'
                            }
                            children : [
                                {
                                    tagName : 'span'
                                    children : [
                                        {
                                            t : 'span'
                                            c : [ 'way inside' ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
                node.outerHTML
            , ( err, result ) ->
                expect( result ).toEqual \
                    '<div class="navigation" width="600">' +
                    '<div id="paragraph1">' +
                    '<span>Start paragraph 1.</span>' +
                    '<span>Middle paragraph 1.</span>' +
                    '<span>End paragraph 1.</span></div>' +
                    '<div id="paragraph2" ' +
                    'style="padding : 5px;"><span><span>' +
                    'way inside</span></span></div></div>'
                done()

## Using Node prototype methods

The tests in this section test the modifications made to the Node
prototype that emit events when methods defined in that prototype
are used for editing.

    phantomDescribe 'using Node prototype methods',
    './app/index.html', ->

### should send alerts on `appendChild` calls

We append an empty span to a div containing only whitespace, and
expect to hear a `DOMEditAction` in response, indicating that the
span was appended to the root of the tracked tree.

We then append an empty span inside that span, and expect a
similar event notification, but this time with an address further
inside the root.

        it 'should send alerts on appendChild calls', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                onemore = document.createElement 'span'

Append the span to the div, then an element to the span.  Since
the div has a whitespace text node in it, the span will be its
second child, but the thing added inside the span will be its
first.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = div.appendChild span
                result2 = span.appendChild onemore

Return the serialized versions of the recorded edit actions,
along with all return values from calls to `appendChild`.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1.address tracker.getElement()
                result.push result2.address tracker.getElement()
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

Validate the serialized versions of the `appendChild` events.

                expect( result[0] ).toEqual
                    type : 'appendChild', node : [],
                    toAppend : { tagName : 'SPAN' }
                expect( result[1] ).toEqual
                    type : 'appendChild', node : [ 1 ],
                    toAppend : { tagName : 'SPAN' }

Validate the return values, which must be the addresses of the
appended children within the original div.

                expect( result[2] ).toEqual [ 1 ]
                expect( result[3] ).toEqual [ 1, 0 ]
                done()

### should send alerts on `insertBefore` calls

We insert an empty span in a div containing only whitespace,
before that whitespace node, and expect to hear a `DOMEditAction`
in response, indicating that the span was inserted under the root
of the tracked tree, at index 0.

We then insert an empty span at index 2, which is equivalent to an
append call, and expect another event, with index 2.

We then insert a final empty span, inside the first one, and
expect a similar event notification, but this time with an
address further inside the root.

        it 'should send alerts on appendChild calls', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                text = div.childNodes[0]
                span = document.createElement 'span'
                onemore = document.createElement 'span'
                twomore = document.createElement 'span'

Insert the span into the div, at index 0.  Then insert another 
at index 2.  Then insert the final span into the first span.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = div.insertBefore span, text
                result2 = div.insertBefore onemore # == append
                result3 = span.insertBefore twomore # == append

Return the serialized versions of the recorded edit actions,
along with all return values from calls to `appendChild`.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1.address tracker.getElement()
                result.push result2.address tracker.getElement()
                result.push result3.address tracker.getElement()
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 6

Validate the serialized versions of the `insertBefore` events.

                expect( result[0] ).toEqual
                    type : 'insertBefore', node : [],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 0
                expect( result[1] ).toEqual
                    type : 'insertBefore', node : [],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 2
                expect( result[2] ).toEqual
                    type : 'insertBefore', node : [ 0 ],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 0

Validate the return values, which must be the addresses of the
appended children within the original div.

                expect( result[3] ).toEqual [ 0 ]
                expect( result[4] ).toEqual [ 2 ]
                expect( result[5] ).toEqual [ 0, 0 ]
                done()

### should send alerts on `normalize` calls

We insert a text node after the existing whitespace in the div,
and normalize.  We test that the normalize event is emitted.

We then insert an empty span after the text, append two text node
children inside it, with an empty span between.  We then normalize
that node and repeat the test.

        it 'should send alerts on normalize calls', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.appendChild document.createTextNode 'example'
                span = document.createElement 'span'
                span.innerHTML = 'foo<span></span>bar'

Normalize the div, append the span, and normalize the span.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = div.normalize()
                div.appendChild span
                result2 = span.normalize()

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`normalize` were undefined, as they should be.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push typeof result1
                result.push typeof result2
                result
            , ( err, result ) ->

We'll be looking for the two `normalize` events, plus the one
`appendChild` event that isn't what we're testing here (but
certainly did occur during the test, and thus got recorded), plus
the two return values added to the end of the results array, for
a total of 5 items.

                expect( result.length ).toEqual 5

Validate the serialized versions of the various events.
First, the first of two normalize events that we're testing, this
one done on a div with two text children and no other children.

                expect( result[0] ).toEqual
                    type : 'normalize', node : [],
                    textChildren : {
                        0 : '\n        '
                        1 : 'example'
                    }

Next, an `appendChild` event that isn't part of this test, but is
included for completeness.

                expect( result[1] ).toEqual
                    type : 'appendChild', node : [],
                    toAppend : {
                        tagName : 'SPAN'
                        children : [
                            'foo'
                            { tagName : 'SPAN' }
                            'bar'
                        ]
                    }

Finally, the second normalize event, called on the span inside the
div, with two text node children, not adjacent.

                expect( result[2] ).toEqual
                    type : 'normalize', node : [ 1 ],
                    textChildren : {
                        0 : 'foo'
                        2 : 'bar'
                    }

Ensure that the return values were both undefined.

                expect( result[3] ).toEqual 'undefined'
                expect( result[4] ).toEqual 'undefined'
                done()

### should send alerts on `removeAttribute` calls

We place two spans inside the root div, with attributes on each.
We then remove some of those attributes and ensure that the
correct events are propagated for each.

        it 'should send alerts on removeAttribute calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span align="center" class="thing">hi</span>
                <span style="color:blue;">blue</span>
                '''
                span1 = div.childNodes[0]
                span2 = div.childNodes[2]

Remove an attribute from each span node.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = span1.removeAttribute 'align'
                result2 = span2.removeAttribute 'style'

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`removeAttribute` were undefined, as they should be.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push typeof result1
                result.push typeof result2
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

Validate the serialized versions of the two `removeAttribute`
events.

                expect( result[0] ).toEqual
                    type : 'removeAttribute', node : [ 0 ],
                    name : 'align', value : 'center'
                expect( result[1] ).toEqual
                    type : 'removeAttribute', node : [ 2 ],
                    name : 'style', value : 'color:blue;'

Ensure that the return values were both undefined.

                expect( result[2] ).toEqual 'undefined'
                expect( result[3] ).toEqual 'undefined'
                done()

### should send alerts on `removeAttributeNode` calls

This test imitates the previous one, but uses
`removeAttributeNode` rather than `removeAttribute`.  This adds
just one new step, of fetching the attribute node to be removed.

        it 'should send alerts on removeAttributeNode calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span align="center" class="thing">hi</span>
                <span style="color:blue;">blue</span>
                '''
                span1 = div.childNodes[0]
                span2 = div.childNodes[2]

Remove an attribute from each span node.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                togo = span1.getAttributeNode 'align'
                result1 = span1.removeAttributeNode togo
                togo = span2.getAttributeNode 'style'
                result2 = span2.removeAttributeNode togo

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`removeAttributeNode` were attribute nodes with the correct data.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1
                result.push result2
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

Validation of events is exactly as it was in the previous test,
except for the name of the action.

                expect( result[0] ).toEqual
                    type : 'removeAttributeNode', node : [ 0 ],
                    name : 'align', value : 'center'
                expect( result[1] ).toEqual
                    type : 'removeAttributeNode', node : [ 2 ],
                    name : 'style', value : 'color:blue;'

Validation of return types is different; we expect that the return
types were attribute nodes, and we inspect their defining
properties.

                expect( result[2].name ).toEqual 'align'
                expect( result[2].value ).toEqual 'center'
                expect( result[3].name ).toEqual 'style'
                expect( result[3].value ).toEqual 'color:blue;'
                done()

### should send alerts on `removeChild` calls

This test creates a hierarchical structure of spans under the root
div node, then calls `removeChild` twice in different portions of
that tree, verifying that the appropriate events are emitted each
time.

        it 'should send alerts on removeChild calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span><span>INNER SPAN!</span>hi</span>
                <span>there</span>
                '''
                span1 = div.childNodes[0]
                span2 = div.childNodes[2]
                spanI = span1.childNodes[0]

Remove the inner span, then the second span.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = span1.removeChild spanI
                result2 = div.removeChild span2

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`removeChild` were the child nodes that were removed.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1.toJSON()
                result.push result2.toJSON()
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

First we expect the two child removal events.

                expect( result[0] ).toEqual
                    type : 'removeChild',
                    node : [ 0 ], childIndex : 0,
                    child : {
                        tagName : 'SPAN'
                        children : [ 'INNER SPAN!' ]
                    }
                expect( result[1] ).toEqual
                    type : 'removeChild',
                    node : [], childIndex : 2,
                    child : {
                        tagName : 'SPAN'
                        children : [ 'there' ]
                    }

Then we expect two child nodes to have been returned by those
`removeChild` calls, which we serialized for returning here.

                expect( result[2] ).toEqual {
                    tagName : 'SPAN'
                    children : [ 'INNER SPAN!' ]
                }
                expect( result[3] ).toEqual {
                    tagName : 'SPAN'
                    children : [ 'there' ]
                }
                done()

### should send alerts on `replaceChild` calls

This test operates exactly like the previous, except rather than
deleting two children, they are simply replaced with new children
that are measurably different, for the purposes of testing.

        it 'should send alerts on replaceChild calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span><span>INNER SPAN!</span>hi</span>
                <span>there</span>
                '''
                span1 = div.childNodes[0]
                span2 = div.childNodes[2]
                spanI = span1.childNodes[0]
                repl1 = document.createElement 'h1'
                repl1.innerHTML = 'heading'
                repl2 = document.createElement 'span'
                repl2.innerHTML = 'some words'

Replace the inner span, then the second span, with `repl1` and
`repl2`, respectively.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = span1.replaceChild repl1, spanI
                result2 = div.replaceChild repl2, span2

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`replaceChild` were the original child nodes that were replaced,
and are thus no longer in the DOM.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1.toJSON()
                result.push result2.toJSON()
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

First we expect the two child replacement events.

                expect( result[0] ).toEqual
                    type : 'replaceChild',
                    node : [ 0 ], childIndex : 0,
                    oldChild : {
                        tagName : 'SPAN'
                        children : [ 'INNER SPAN!' ]
                    },
                    newChild : {
                        tagName : 'H1'
                        children : [ 'heading' ]
                    }
                expect( result[1] ).toEqual
                    type : 'replaceChild',
                    node : [], childIndex : 2,
                    oldChild : {
                        tagName : 'SPAN'
                        children : [ 'there' ]
                    },
                    newChild : {
                        tagName : 'SPAN'
                        children : [ 'some words' ]
                    }

Then we expect the replaced nodes to have been returned by those
`replaceChild` calls, which we serialized for returning here.

                expect( result[2] ).toEqual {
                    tagName : 'SPAN'
                    children : [ 'INNER SPAN!' ]
                }
                expect( result[3] ).toEqual {
                    tagName : 'SPAN'
                    children : [ 'there' ]
                }
                done()

### should send alerts on `setAttribute` calls

We create one span inside the root div, set an attribute on that
span and then do the same on the root div, and ensure that both
events are correctly emitted.  In one case, we will be creating a
new attribute, and in the other case, replacing an existing one.

        it 'should send alerts on setAttribute calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span example="yes">content</span>
                '''
                span = div.childNodes[0]

Set an attribute on the div, then change the attribute on the
span.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                result1 = div.setAttribute 'align', 'center'
                result2 = span.setAttribute 'example', 'no'

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`setAttribute` were undefined, as they should be.

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push typeof result1
                result.push typeof result2
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

First we expect the two attribute-setting events.

                expect( result[0] ).toEqual
                    type : 'setAttribute',
                    node : [], name : 'align',
                    oldValue : '', newValue : 'center'
                expect( result[1] ).toEqual
                    type : 'setAttribute',
                    node : [ 0 ], name : 'example',
                    oldValue : 'yes', newValue : 'no'

Then we expect the calls to have given no return values.

                expect( result[2] ).toEqual 'undefined'
                expect( result[3] ).toEqual 'undefined'
                done()

### should send alerts on `setAttributeNode` calls

We create one span inside the root div, set an attribute on that
span and then do the same on the root div, and ensure that both
events are correctly emitted.  In one case, we will be creating a
new attribute, and in the other case, replacing an existing one.

        it 'should send alerts on setAttributeNode calls',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span example="yes">content</span>
                '''
                span = div.childNodes[0]

Set an attribute on the div, then change the attribute on the
span.

                tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                edit = document.createAttribute 'align'
                edit.value = 'center'
                result1 = div.setAttributeNode edit
                edit = document.createAttribute 'example'
                edit.value = 'no'
                result2 = span.setAttributeNode edit

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`setAttribute` were what they should be.  In the first case, the
result should be undefined, because no node was replaced.  In the
second case, it should be the replaced attribute node (i.e., the
old one).

                result = tracker.getEditActions().map \
                    ( x ) -> x.toJSON()
                result.push result1 is null
                result.push result2
                result
            , ( err, result ) ->
                expect( result.length ).toEqual 4

First we expect the two attribute-setting events.

                expect( result[0] ).toEqual
                    type : 'setAttributeNode',
                    node : [], name : 'align',
                    oldValue : '', newValue : 'center'
                expect( result[1] ).toEqual
                    type : 'setAttributeNode',
                    node : [ 0 ], name : 'example',
                    oldValue : 'yes', newValue : 'no'

Then we expect the first call to have given null as the return
value.

                expect( result[2] ).toBeTruthy()

But the second call should have returned the original attribute
node (before the replacement).

                expect( result[3].name ).toEqual 'example'
                expect( result[3].value ).toEqual 'yes'
                done()

