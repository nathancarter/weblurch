
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe, pageSetup, pageExpects, inPage,
      pageExpectsError } = require './phantom-utils'

## address member function of Node class

The tests in this section test the `address` member function in
the `Node` prototype.
[See its definition here.](domutils.litcoffee.html#address).

    phantomDescribe 'address member function of Node class',
    './app/index.html', ->

### should be defined

First, just verify that it's present.

        it 'should be defined', inPage ->
            pageExpects ( -> Node::address ), 'toBeTruthy'

### should give null on corner cases

        it 'should give null on corner cases', inPage ->

The corner cases to be tested here are these:
 * The address of a DOM node within one of its children.
 * The address of a DOM node within one of its siblings.

Although there are others we could test, these are enough for now.

            pageSetup ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
            pageExpects ( -> pardiv.address( chidiv1 ) ),
                'toBeNull'
            pageExpects ( -> pardiv.address( chidiv2 ) ),
                'toBeNull'
            pageExpects ( -> chidiv1.address( chidiv2 ) ),
                'toBeNull'
            pageExpects ( -> chidiv2.address( chidiv1 ) ),
                'toBeNull'

### should be empty when argument is this

        it 'should be empty when argument is this', inPage ->

We will test a few cases where the argument is the node it's being
called on, for various nodes.

            pageSetup ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
            pageExpects ( -> pardiv.address( pardiv ) ),
                'toEqual', [ ]
            pageExpects ( -> chidiv1.address( chidiv1 ) ),
                'toEqual', [ ]
            pageExpects ( -> chidiv2.address( chidiv2 ) ),
                'toEqual', [ ]
            pageExpects ( -> document.address( document ) ),
                'toEqual', [ ]
            pageExpects ( ->
                document.body.address document.body ),
                'toEqual', [ ]

### should be empty for top-level,null

        it 'should be empty for top-level,null', inPage ->

The simplest way to test this is to compute the address of the
document, and expect it to be the empty array.  But we also make
the document create an empty div and not put it inside any other
node, and we expect that its address will also be the empty array.

            pageExpects ( -> document.address() ), 'toEqual', [ ]
            pageExpects ( ->
                document.createElement( 'div' ).address() ),
                'toEqual', [ ]

### should be length-1 for a child

        it 'should be length-1 for a child', inPage ->

First, add some structure to the document.
We will need to run tests on a variety of parent-child pairs of
nodes, so we need to create such pairs as structures in the
document first.

            pageSetup ->
                window.pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                window.chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                window.chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2

Next, create some structure *outside* the document.
We want to verify that our routines work outside the page's
document as well.

                window.outer = document.createElement 'div'
                window.inner = document.createElement 'span'
                outer.appendChild inner

We call the `address` function in several different ways, but each
time we call it on an immediate child of the argument (or an
immediate child of the document, with no argument).  Sometimes we
compute the same result in both of those ways to verify that they
are equal.

            pageExpects ( ->
                document.childNodes[0].address document ),
                'toEqual', [ 0 ]
            pageExpects ( -> document.childNodes[0].address() ),
                'toEqual', [ 0 ]
            pageExpects ( -> chidiv1.address pardiv ),
                'toEqual', [ 0 ]
            pageExpects ( -> chidiv2.address pardiv ),
                'toEqual', [ 1 ]
            pageExpects ( -> document.body.childNodes.length ),
                'toEqual', 8
            pageExpects ( -> pardiv.address document.body ),
                'toEqual', [ 7 ]
            pageExpects ( -> inner.address outer ),
                'toEqual', [ 0 ]

### should work for grandchildren, etc.

        it 'should work for grandchildren, etc.', inPage ->

First, we construct a hierarchy with several levels so that we can
ask questions across those various levels.  This also ensures that
we know exactly what the child indices are, because we designed
the hierarchy in the first place.

            pageSetup ->
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
change the expected indices of the elements in the HTML code
above, we remove whitespace between tags before creating a DOM
structure from that code.

                hierarchy = hierarchy.replace( /^\s*|\s*$/g, '' )
                                     .replace( />\s*</g, '><' )

Now create that hierarchy inside our page, for testing.

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy
                window.elts = ( document.getElementById \
                    "test-#{i}" for i in [0..8] )

We check the address of each test element inside the div we just
created, as well as its address relative to the div with id
`test-2`.

First, check all descendants of the main div.

            pageExpects ( -> elts[0].address div ),
                'toEqual', [ 0 ]
            pageExpects ( -> elts[1].address div ),
                'toEqual', [ 1 ]
            pageExpects ( -> elts[2].address div ),
                'toEqual', [ 2 ]
            pageExpects ( -> elts[3].address div ),
                'toEqual', [ 2, 0 ]
            pageExpects ( -> elts[4].address div ),
                'toEqual', [ 2, 1 ]
            pageExpects ( -> elts[5].address div ),
                'toEqual', [ 2, 1, 0 ]
            pageExpects ( -> elts[6].address div ),
                'toEqual', [ 2, 1, 0, 0 ]
            pageExpects ( -> elts[7].address div ),
                'toEqual', [ 2, 1, 0, 1 ]
            pageExpects ( -> elts[8].address div ),
                'toEqual', [ 2, 1, 1 ]

Next, check the descendants of the element with id `test-2` for
their addresses relative to that element.

            pageExpects ( -> elts[2].address elts[2] ),
                'toEqual', [ ]
            pageExpects ( -> elts[3].address elts[2] ),
                'toEqual', [ 0 ]
            pageExpects ( -> elts[4].address elts[2] ),
                'toEqual', [ 1 ]
            pageExpects ( -> elts[5].address elts[2] ),
                'toEqual', [ 1, 0 ]
            pageExpects ( -> elts[6].address elts[2] ),
                'toEqual', [ 1, 0, 0 ]
            pageExpects ( -> elts[7].address elts[2] ),
                'toEqual', [ 1, 0, 1 ]
            pageExpects ( -> elts[8].address elts[2] ),
                'toEqual', [ 1, 1 ]

## index member function of Node class

The tests in this section test the `index` member function in the
`Node` prototype.  This function is like the inverse of `address`.
[See its definition here.](domutils.litcoffee.html#index).

    phantomDescribe 'index member function of Node class',
    './app/index.html', ->

### should be defined

        it 'should be defined', inPage ->
            pageExpects ( -> Node::index ), 'toBeTruthy'

### should give errors for non-arrays

        it 'should give errors for non-arrays', inPage ->

Verify that calls to the function throw errors if anything but an
array is passed as the argument, and that the error messages
contain the relevant portion of the expected error message.

            pageExpectsError ( -> document.index 0 ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index 0: 0 ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index document ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index -> ),
                'toMatch', /requires an array/
            pageExpectsError ( -> document.index '[0,0]' ),
                'toMatch', /requires an array/

### should yield itself for []

        it 'should yield itself for []', inPage ->

Verify that `N.index []` yields `N`, for any node `N`.
We test a variety of type of nodes, including the document, the
body, some DIVs and SPANs inside, as well as some DIVs and SPANs
that are not part of the document.

            pageSetup ->
                window.divInPage = document.createElement 'div'
                document.body.appendChild divInPage
                window.spanInPage = document.createElement 'span'
                document.body.appendChild spanInPage
                window.divOutside = document.createElement 'div'
                window.spanOutside = document.createElement 'span'
            pageExpects ( -> divInPage is divInPage.index [] ),
                'toBeTruthy'
            pageExpects ( -> spanInPage is spanInPage.index [] ),
                'toBeTruthy'
            pageExpects ( -> divOutside is divOutside.index [] ),
                'toBeTruthy'
            pageExpects ( ->
                spanOutside is spanOutside.index [] ),
                'toBeTruthy'
            pageExpects ( -> document is document.index [] ),
                'toBeTruthy'
            pageExpects ( ->
                document.body is document.body.index [] ),
                'toBeTruthy'

### should work for descendant indices

        it 'should work for descendant indices', inPage ->

Here we re-use the same hierarchy from
[a test above](#should-work-for-grandchildren-etc-),
for the same reasons.

            pageSetup ->
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

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Look up a lot of addresses, and verify their ids (if they are
elements with ids) or their text content (if they are text nodes).

            pageExpects ( -> div.index( [ 0 ] ).id ),
                'toEqual', 'test-0'
            pageExpects ( -> div.index( [ 1 ] ).id ),
                'toEqual', 'test-1'
            pageExpects ( -> div.index( [ 2 ] ).id ),
                'toEqual', 'test-2'
            pageExpects ( -> div.index( [ 0, 0 ] ).textContent ),
                'toEqual', 'foo'
            pageExpects ( -> div.index( [ 1, 0 ] ).textContent ),
                'toEqual', 'bar'
            pageExpects ( -> div.index( [ 2, 0 ] ).id ),
                'toEqual', 'test-3'
            pageExpects ( ->
                div.index( [ 2, 0, 0 ] ).textContent ),
                'toEqual', 'baz'
            pageExpects ( -> div.index( [ 2, 1 ] ).id ),
                'toEqual', 'test-4'
            pageExpects ( -> div.index( [ 2, 1, 0 ] ).id ),
                'toEqual', 'test-5'
            pageExpects ( -> div.index( [ 2, 1, 0, 0 ] ).id ),
                'toEqual', 'test-6'
            pageExpects ( ->
                div.index( [ 2, 1, 0, 0, 1 ] ).textContent ),
                'toEqual', 'x'
            pageExpects ( -> div.index( [ 2, 1, 0, 1 ] ).id ),
                'toEqual', 'test-7'
            pageExpects ( -> div.index( [ 2, 1, 1 ] ).id ),
                'toEqual', 'test-8'

### should give undefined for bad indices

        it 'should give undefined for bad indices', inPage ->

Verify that calls to the function return undefined if any step in
the address array is invalid.  There are many ways for this to
happen (entry less than zero, entry larger than number of children
at that level, entry not an integer, entry not a number at all).
We test each of these cases below.

First we re-create the same hierarchy from
[a test above](#should-work-for-grandchildren-etc-),
for the same reasons.

            pageSetup ->
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

                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = hierarchy

Now call `div.index` with addresses that contain each of the
erroneous steps mentioned above.  Here we call `typeof` on each
of the return values, because we expect that they will be
undefined in each case, and we wish to populate our array with
that information in string form, so that it can be returned from
the page as valid JSON.

            pageExpects ( -> typeof div.index [ -1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 3 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 300000 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0.2 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 'something' ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 'childNodes' ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ [ 0 ] ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ [ ] ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ { } ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ div ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, -1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, 1 ] ),
                'toEqual', 'undefined'
            pageExpects ( -> typeof div.index [ 0, 'ponies' ] ),
                'toEqual', 'undefined'

## Node toJSON conversion

The tests in this section test the `toJSON` member function in the
`Node` prototype.
[See its definition here.](domutils.litcoffee.html#serialization)

    phantomDescribe 'Node toJSON conversion',
    './app/index.html', ->

### should be defined

        it 'should be defined', inPage ->

First, just verify that the function itself is present.

            pageExpects ( -> Node::toJSON ), 'toBeTruthy'

### should convert text nodes to strings

        it 'should convert text nodes to strings', inPage ->

HTML text nodes should serialize as ordinary strings.
We test a variety of ways they might occur.

            pageSetup ->
                window.textNode = document.createTextNode 'foo'
                window.div = document.createElement 'div'
                div.innerHTML = '<i>italic</i> not italic'
            pageExpects ( -> textNode.toJSON() ), 'toEqual', 'foo'
            pageExpects ( ->
                div.childNodes[0].childNodes[0].toJSON() ),
                'toEqual', 'italic'
            pageExpects ( -> div.childNodes[1].toJSON() ),
                'toEqual', ' not italic'

### should convert comment nodes to objects

        it 'should convert comment nodes to objects', inPage ->

HTML comment nodes should serialize as objects with the comment
flag and the comment's text content as well.

            pageExpects ( ->
                comment = document.createComment 'comment content'
                comment.toJSON() ), 'toEqual',
                comment : yes, content : 'comment content'
            pageExpects ( ->
                comment = document.createComment ''
                comment.toJSON() ), 'toEqual',
                comment : yes, content : ''

### should handle other no-children elements

        it 'should handle other no-children elements', inPage ->

Other no-children elements include images, horizontal rules, and
line breaks.  We verify that in each case the object is encoded
with the correct tag name and attributes, but no children.

            pageSetup ->
                window.div = document.createElement 'div'
                div.innerHTML = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC" width="31" height="24"><hr><br>'
            pageExpects ( -> div.childNodes[0].toJSON() ),
                'toEqual', {
                    tagName : 'IMG'
                    attributes : {
                        width : '31'
                        height : '24'
                        src : 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB8AAAAYCAIAAACNybHWAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA63pUWHRYTUw6Y29tLmFkb2JlLnhtcAAAGJVtULsOwiAU3fsVBOdy+9ChhHaxcTNpnHSsikoUaAqm+PcWWx9Rmbj3vOAwR51sJLc1cvKiDHU5rvd6y2l/92vA6EGx5xyvlxWa65ajGZmSCBcBQoi1+wNdlYtR3k85PlnbUICu60iXEt0eIc6yDKIEkiTsGaG5KVu7UJnJYPL0KbnZtaKxQivk53qrrzbHeOQMZwjiTryTlCGPR5OdluARiEkEL29v77e0Eo5f1qWQXJk+o0hjBn+Bv8LNG0+mn8LNj5DB13eGrmAsqwgYvIovgjseJHia4Qg7sAAAAV5JREFUSIntlL9rwkAUx18uPQttvICSmqjn5pDi4BJHwdm/VzI6xFEHsWSyBWtOUxSbqks8yHVwsWdRA7WT3/H9+PB9946nzGYzuJruhBD/Tf+az8eet2Jst9mc7s9ks7lSqdpsEtM8zirT6VQKvQ8GvusmaWZSEKq127Rel70fu/ZdFyFUo9QkJIPxae6O8zCK/CB46XR0yyKFwmEWiZ967fUSIZ4preTzZ9EAkMG4Yhg2pSJJxp4n0WT6ijEAMAk5/xwHMnUdAD4Zk2jyVvdrvMT1oe4xBoB4vZZof/wjb/Qb/Ua/El2+M1jTAGDHeSpozDkAYE2Tr5hUtz+hYRSlou/r9WJRisveaaOhIOQHwWS5jC+YIOZ8slj4jIGqlh1Hoimj0Uhq+PD9t25XJEkK86pabbUM25bCv2z1ybYfDYP1++sw5NvtaSzWNGJZZcd5yOWOUcpwOEzhMaW+AXrrPiceQvueAAAAAElFTkSuQmCC'
                    }
                }
            pageExpects ( -> div.childNodes[1].toJSON() ),
                'toEqual', tagName : 'HR'
            pageExpects ( -> div.childNodes[2].toJSON() ),
                'toEqual', tagName : 'BR'

### should handle spans correctly

        it 'should handle spans correctly', inPage ->

Must correctly convert things of the form `<span>text</span>` or
`<i>text</i>` or any other simple, non-nested tag.  Three simple
tests are done, plus one with two different attributes.

First, a span created by appendign a text node child to a new
span element.

            pageExpects ( ->
                span1 = document.createElement 'span'
                span1.appendChild document.createTextNode 'hello'
                span1.toJSON() ), 'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'hello' ]
                }

Next, a span created by assigning to the innerHTML property of a
new span element.

            pageExpects ( ->
                span2 = document.createElement 'span'
                span2.innerHTML = 'world'
                span2.toJSON() ), 'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'world' ]
                }

Next, an italic element lifted out of a div, where it was created
using the innerHTML property of the div.

            pageExpects ( ->
                div1 = document.createElement 'div'
                div1.innerHTML = '<i>The Great Gatsby</i>'
                div1.childNodes[0].toJSON() ), 'toEqual', {
                    tagName : 'I'
                    children : [ 'The Great Gatsby' ]
                }

Same as the previous, but this time with some attributes on the
element.

            pageExpects ( ->
                div2 = document.createElement 'div'
                div2.innerHTML = '<i class="X" id="Y">Z</i>'
                div2.childNodes[0].toJSON() ), 'toEqual', {
                    tagName : 'I'
                    attributes : class : 'X', id : 'Y'
                    children : [ 'Z' ]
                }

### should handle hierarchies correctly

        it 'should handle hierarchies correctly', inPage ->

The above tests cover simple situations, either DOM trees of
height 1 or 2.  Now we consider situations in which there are
many levels to the Node tree.  I choose three examples, and mix in
a diversity of depths, attributes, tag names, comments, etc.

            pageSetup ->
                window.div1 = document.createElement 'div'
                div1.innerHTML = '<span class="outermost" id=0>' +
                                 '<span class="middleman" id=1>' +
                                 '<span class="innermost" id=2>' +
                                 'finally, the text' +
                                 '</span></span></span>'
                document.body.appendChild div1
                window.div2 = document.createElement 'div'
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
                window.div3 = document.createElement 'div'
                div3.innerHTML = 'start with a text node' +
                                 '<!-- then a comment -->' +
                                 '<p>then <i>MORE</i></p>'
                document.body.appendChild div3
            pageExpects ( -> div1.toJSON() ), 'toEqual', {
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
            pageExpects ( -> div2.toJSON() ), 'toEqual', {
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
                                                    width : '50%'
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
                                                    width : '50%'
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
            pageExpects ( -> div3.toJSON() ), 'toEqual', {
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

### should respect verbosity setting

        it 'should respect verbosity setting', inPage ->

The verbosity setting of the serializer defaults to true, and
gives results like those shown in the tests above, whose object
keys are human-readable.  If verbosity is disabled, as in the
tests below, then each key is shrunk to a unique one-letter
abbreviation, as documented
[in the module where the serialization is implemented](
domutils.litcoffee.html#serialization).

Here we do only one, brief test of each of the types tested above.

            pageExpects ( ->
                node = document.createTextNode 'text node'
                node.toJSON no ), 'toEqual', 'text node'
            pageExpects ( ->
                node = document.createComment 'swish'
                node.toJSON no ), 'toEqual', {
                    m : yes
                    n : 'swish'
                }
            pageExpects ( ->
                node = document.createElement 'hr'
                node.toJSON no ), 'toEqual', t : 'HR'
            pageSetup ->
                window.div = document.createElement 'div'
                div.innerHTML = '<p align="left">paragraph</p>' +
                                '<p><span id="foo">bar</span>' +
                                ' <i class="baz">quux</i></p>'
            pageExpects ( ->
                node = div.childNodes[0]
                node.toJSON no ), 'toEqual', {
                    t : 'P'
                    a : align : 'left'
                    c : [ 'paragraph' ]
                }
            pageExpects ( ->
                node = div.childNodes[1]
                node.toJSON no ), 'toEqual', {
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

## Node fromJSON conversion

The tests in this section test the `fromJSON` member function in
the `Node` object.
[See its definition here.](
domutils.litcoffee.html#from-objects-to-dom-nodes)

    phantomDescribe 'Node fromJSON conversion',
    './app/index.html', ->

### should be defined

        it 'should be defined', inPage ->

First, just verify that the function itself is present.

            pageExpects ( -> Node.fromJSON ), 'toBeTruthy'

### should convert strings to text nodes

        it 'should convert strings to text nodes', inPage ->

This test is simply the inverse of the analogous test earlier.
It verifies that two strings, one empty and one nonempty, both get
converted correctly into `Text` instances with the appropriate
content.

            pageSetup ->
                window.node1 = Node.fromJSON 'just a string'
                window.node2 = Node.fromJSON ''
            pageExpects ( -> node1 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node1 instanceof Text ), 'toBeTruthy'
            pageExpects ( -> node1 instanceof Comment ),
                'toBeFalsy'
            pageExpects ( -> node1 instanceof Element ),
                'toBeFalsy'
            pageExpects ( -> node1.textContent ),
                'toEqual', 'just a string'
            pageExpects ( -> node2 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node2 instanceof Text ), 'toBeTruthy'
            pageExpects ( -> node2 instanceof Comment ),
                'toBeFalsy'
            pageExpects ( -> node2 instanceof Element ),
                'toBeFalsy'
            pageExpects ( -> node2.textContent ), 'toEqual', ''

### should handle comment objects

        it 'should handle comment objects', inPage ->

This test is simply the inverse of the analogous test earlier.
It verifies that two objects, one in verbose and one in
non-verbose notation, one empty and one nonempty, both get
converted correctly into `Comment` instances with the appropriate
content.

            pageSetup ->
                window.node1 = Node.fromJSON \
                    m : yes, n : 'some comment'
                window.node2 = Node.fromJSON \
                    comment : yes, content : ''
            pageExpects ( -> node1 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node1 instanceof Text ), 'toBeFalsy'
            pageExpects ( -> node1 instanceof Comment ),
                'toBeTruthy'
            pageExpects ( -> node1 instanceof Element ),
                'toBeFalsy'
            pageExpects ( -> node1.textContent ),
                'toEqual', 'some comment'
            pageExpects ( -> node2 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node2 instanceof Text ), 'toBeFalsy'
            pageExpects ( -> node2 instanceof Comment ),
                'toBeTruthy'
            pageExpects ( -> node2 instanceof Element ),
                'toBeFalsy'
            pageExpects ( -> node2.textContent ), 'toEqual', ''

### should be able to create empty elements

        it 'should be able to create empty elements', inPage ->

This test is simply the inverse of the analogous test earlier.
It verifies that two objects, one in verbose and one in
non-verbose notation, both get converted correctly into `Element`
instances with no children but the appropriate tags and
attributes.

            pageSetup ->
                window.node1 = Node.fromJSON \
                    tagName : 'hr',
                    attributes : class : 'y', whatever : 'dude'
                window.node2 = Node.fromJSON \
                    t : 'br', a : id : '24601'
            pageExpects ( -> node1 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node1 instanceof Text ), 'toBeFalsy'
            pageExpects ( -> node1 instanceof Comment ),
                'toBeFalsy'
            pageExpects ( -> node1 instanceof Element ),
                'toBeTruthy'
            pageExpects ( -> node1.tagName ), 'toEqual', 'HR'
            pageExpects ( -> node1.childNodes.length ),
                'toEqual', 0
            pageExpects ( -> node1.attributes.length ),
                'toEqual', 2
            pageExpects ( -> node1.attributes[0].name ),
                'toEqual', 'class'
            pageExpects ( -> node1.attributes[0].value ),
                'toEqual', 'y'
            pageExpects ( -> node1.attributes[1].name ),
                'toEqual', 'whatever'
            pageExpects ( -> node1.attributes[1].value ),
                'toEqual', 'dude'
            pageExpects ( -> node2 instanceof Node ), 'toBeTruthy'
            pageExpects ( -> node2 instanceof Text ), 'toBeFalsy'
            pageExpects ( -> node2 instanceof Comment ),
                'toBeFalsy'
            pageExpects ( -> node2 instanceof Element ),
                'toBeTruthy'
            pageExpects ( -> node2.tagName ), 'toEqual', 'BR'
            pageExpects ( -> node2.childNodes.length ),
                'toEqual', 0
            pageExpects ( -> node2.attributes.length ),
                'toEqual', 1
            pageExpects ( -> node2.attributes[0].name ),
                'toEqual', 'id'
            pageExpects ( -> node2.attributes[0].value ),
                'toEqual', '24601'

### should build depth-one DOM trees

        it 'should build depth-one DOM trees', inPage ->

This test is simply the inverse of the analogous test earlier.
Depth-one trees are those that are objects with a children array,
no child of which has any children itself.  We test with one that
uses verbose notation and one using non-verbose.  In each case,
some of the parts have attributes and some don't.

            pageExpects ( ->
                node = Node.fromJSON {
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
                node.outerHTML
            ), 'toEqual',
                '<i>non-bold stuff, followed by ' +
                '<b class="C" id="123">bold stuff</b></i>'
            pageExpects ( ->
                node = Node.fromJSON {
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
                node.outerHTML
            ), 'toEqual',
                '<p style="border: 1px solid gray;" ' +
                'width="100%"><span>some text</span>' +
                '<span>yup, more text</span></p>'

### should build deep DOM trees

        it 'should build depth-one DOM trees', inPage ->

This test is simply the inverse of the analogous test earlier.
The routines for building DOM trees from JSON objects should be
able to create many-level, nested structures.  Here I mix
verbose and non-verbose notation in one, large test, to be sure
that this works.

            pageExpects ( ->
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
            ), 'toEqual',
                '<div class="navigation" width="600">' +
                '<div id="paragraph1">' +
                '<span>Start paragraph 1.</span>' +
                '<span>Middle paragraph 1.</span>' +
                '<span>End paragraph 1.</span></div>' +
                '<div id="paragraph2" ' +
                'style="padding : 5px;"><span><span>' +
                'way inside</span></span></div></div>'

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

        it 'should send alerts on appendChild calls', inPage ->
            pageSetup ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                onemore = document.createElement 'span'

Append the span to the div, then an element to the span.  Since
the div has a whitespace text node in it, the span will be its
second child, but the thing added inside the span will be its
first.

                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                window.result1 = div.appendChild span
                window.result2 = span.appendChild onemore

Validate the serialized versions of the recorded edit actions,
along with all return values from calls to `appendChild`.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'appendChild', node : [],
                    toAppend : { tagName : 'SPAN' }
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'appendChild', node : [ 1 ],
                    toAppend : { tagName : 'SPAN' }
                }

Validate the addresses of the appended children within the
original div.

            pageExpects ( ->
                result1.address tracker.getElement() ),
                'toEqual', [ 1 ]
            pageExpects ( ->
                result2.address tracker.getElement() ),
                'toEqual', [ 1, 0 ]

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

        it 'should send alerts on appendChild calls', inPage ->
            pageSetup ->
                div = document.getElementById '0'
                text = div.childNodes[0]
                span = document.createElement 'span'
                onemore = document.createElement 'span'
                twomore = document.createElement 'span'

Insert the span into the div, at index 0.  Then insert another 
at index 2.  Then insert the final span into the first span.

                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()
                window.result1 = div.insertBefore span, text
                # the next two are actually appends
                window.result2 = div.insertBefore onemore
                window.result3 = span.insertBefore twomore

Validate the serialized versions of the recorded edit actions,
along with all return values from calls to `appendChild`.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 3
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'insertBefore', node : [],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 0
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'insertBefore', node : [],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 2
                }
            pageExpects ( ->
                tracker.getEditActions()[2].toJSON() ),
                'toEqual', {
                    type : 'insertBefore', node : [ 0 ],
                    toInsert : { tagName : 'SPAN' },
                    insertBefore : 0
                }

Validate the addresses of the appended children within the
original div.

            pageExpects ( ->
                result1.address tracker.getElement() ),
                'toEqual', [ 0 ]
            pageExpects ( ->
                result2.address tracker.getElement() ),
                'toEqual', [ 2 ]
            pageExpects ( ->
                result3.address tracker.getElement() ),
                'toEqual', [ 0, 0 ]

### should send alerts on `normalize` calls

We insert a text node after the existing whitespace in the div,
and normalize.  We test that the normalize event is emitted.

We then insert an empty span after the text, append two text node
children inside it, with an empty span between.  We then normalize
that node and repeat the test.

        it 'should send alerts on normalize calls', inPage ->
            pageSetup ->
                window.div = document.getElementById '0'
                div.appendChild document.createTextNode 'example'
                window.span = document.createElement 'span'
                span.innerHTML = 'foo<span></span>bar'
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Normalize the div, append the span, and normalize the span.  As
we do so, we verify that each of the normalize calls returns
undefined.

            pageExpects ( -> div.normalize() ), 'toBeUndefined'
            pageSetup -> div.appendChild span
            pageExpects ( -> span.normalize() ), 'toBeUndefined'

Now we validate the serialized versions of the edit actions that
got recorded by the edit tracker.

We'll be looking for the two `normalize` events, plus the one
`appendChild` event that isn't what we're testing here (but
certainly did occur during the test, and thus got recorded).

First, the first of two normalize events that we're testing, this
one done on a div with two text children and no other children.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 3
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'normalize', node : [],
                    sequences : {
                        '[0]' : [ '\n        ', 'example' ]
                    }
                }

Next, an `appendChild` event that isn't part of this test, but is
included for completeness.

            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'appendChild', node : [],
                    toAppend : {
                        tagName : 'SPAN'
                        children : [
                            'foo'
                            { tagName : 'SPAN' }
                            'bar'
                        ]
                    }
                }

Finally, the second normalize event, called on the span inside the
div, with two text node children, not adjacent.

            pageExpects ( ->
                tracker.getEditActions()[2].toJSON() ),
                'toEqual', {
                    type : 'normalize', node : [ 1 ],
                    sequences : { }
                }

### should send alerts on `removeAttribute` calls

We place two spans inside the root div, with attributes on each.
We then remove some of those attributes and ensure that the
correct events are propagated for each.

        it 'should send alerts on removeAttribute calls',
        inPage ->
            pageSetup ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span align="center" class="thing">hi</span>
                <span style="color:blue;">blue</span>
                '''
                window.span1 = div.childNodes[0]
                window.span2 = div.childNodes[2]
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Remove an attribute from each span node, and verify that the
return value of `removeAttribute` in each case is undefined.

            pageExpects ( -> span1.removeAttribute 'align' ),
                'toBeUndefined'
            pageExpects ( -> span2.removeAttribute 'style' ),
                'toBeUndefined'

Validate the recorded edit actions.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                    'toEqual', {
                        type : 'removeAttribute', node : [ 0 ],
                        name : 'align', value : 'center'
                    }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                    'toEqual', {
                        type : 'removeAttribute', node : [ 2 ],
                        name : 'style', value : 'color:blue;'
                    }

### should send alerts on `removeAttributeNode` calls

This test imitates the previous one, but uses
`removeAttributeNode` rather than `removeAttribute`.  This adds
just one new step, of fetching the attribute node to be removed.

        it 'should send alerts on removeAttributeNode calls',
        inPage ->
            pageSetup ->
                div = document.getElementById '0'
                div.innerHTML = '''
                <span align="center" class="thing">hi</span>
                <span style="color:blue;">blue</span>
                '''
                window.span1 = div.childNodes[0]
                window.span2 = div.childNodes[2]
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Remove an attribute from each span node, and verify that the
return value of `removeAttributeNode` in each case is an attribute
node, the one removed.

            pageSetup ->
                togo = span1.getAttributeNode 'align'
                window.result1 = span1.removeAttributeNode togo
                togo = span2.getAttributeNode 'style'
                window.result2 = span2.removeAttributeNode togo
            pageExpects ( -> result1.name ), 'toEqual', 'align'
            pageExpects ( -> result1.value ), 'toEqual', 'center'
            pageExpects ( -> result2.name ), 'toEqual', 'style'
            pageExpects ( -> result2.value ),
                'toEqual', 'color:blue;'

Validate the recorded edit actions.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'removeAttributeNode', node : [ 0 ],
                    name : 'align', value : 'center'
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'removeAttributeNode', node : [ 2 ],
                    name : 'style', value : 'color:blue;'
                }

### should send alerts on `removeChild` calls

This test creates a hierarchical structure of spans under the root
div node, then calls `removeChild` twice in different portions of
that tree, verifying that the appropriate events are emitted each
time.

        it 'should send alerts on removeChild calls', inPage ->
            pageSetup ->
                window.div = document.getElementById '0'
                div.innerHTML = '''
                <span><span>INNER SPAN!</span>hi</span>
                <span>there</span>
                '''
                window.span1 = div.childNodes[0]
                window.span2 = div.childNodes[2]
                window.spanI = span1.childNodes[0]
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Remove the inner span, then the second span.  In each case,
verify that the result of the remove operation is the child node
removed.  We use serialization in order to transport the nodes
from the test page to this environment safely, via JSON.

            pageExpects ( ->
                span1.removeChild( spanI ).toJSON() ),
                'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'INNER SPAN!' ]
                }
            pageExpects ( ->
                div.removeChild( span2 ).toJSON() ),
                'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'there' ]
                }

Return the serialized versions of the recorded edit actions, plus
checks about whether the return values from the calls to
`removeChild` were the child nodes that were removed.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'removeChild',
                    node : [ 0 ], childIndex : 0,
                    child : {
                        tagName : 'SPAN'
                        children : [ 'INNER SPAN!' ]
                    }
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'removeChild',
                    node : [], childIndex : 2,
                    child : {
                        tagName : 'SPAN'
                        children : [ 'there' ]
                    }
                }

### should send alerts on `replaceChild` calls

This test operates exactly like the previous, except rather than
deleting two children, they are simply replaced with new children
that are measurably different, for the purposes of testing.

        it 'should send alerts on replaceChild calls', inPage ->
            pageSetup ->
                window.div = document.getElementById '0'
                div.innerHTML = '''
                <span><span>INNER SPAN!</span>hi</span>
                <span>there</span>
                '''
                window.span1 = div.childNodes[0]
                window.span2 = div.childNodes[2]
                window.spanI = span1.childNodes[0]
                window.repl1 = document.createElement 'h1'
                repl1.innerHTML = 'heading'
                window.repl2 = document.createElement 'span'
                repl2.innerHTML = 'some words'
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Replace the inner span, then the second span, with `repl1` and
`repl2`, respectively.  In each case, verify that the return value
is what it ought to be, the replaced node.  We serialize that
return value here, for transport between the test page and this
environment.

            pageExpects ( ->
                span1.replaceChild( repl1, spanI ).toJSON() ),
                'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'INNER SPAN!' ]
                }
            pageExpects ( ->
                div.replaceChild( repl2, span2 ).toJSON() ),
                'toEqual', {
                    tagName : 'SPAN'
                    children : [ 'there' ]
                }

Validate the recorded edit actions.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
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
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
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
                }

### should send alerts on `setAttribute` calls

We create one span inside the root div, set an attribute on that
span and then do the same on the root div, and ensure that both
events are correctly emitted.  In one case, we will be creating a
new attribute, and in the other case, replacing an existing one.

        it 'should send alerts on setAttribute calls', inPage ->
            pageSetup ->
                window.div = document.getElementById '0'
                div.innerHTML = '''
                <span example="yes">content</span>
                '''
                window.span = div.childNodes[0]
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Set an attribute on the div, then change the attribute on the
span.  As we do so, validate that the return values from the
`setAttribute` calls are undefined, as they should be.

            pageExpects ( -> div.setAttribute 'align', 'center' ),
                'toBeUndefined'
            pageExpects ( ->  span.setAttribute 'example', 'no' ),
                'toBeUndefined'

Validate the recorded edit actions.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'setAttribute',
                    node : [], name : 'align',
                    oldValue : '', newValue : 'center'
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'setAttribute',
                    node : [ 0 ], name : 'example',
                    oldValue : 'yes', newValue : 'no'
                }

### should send alerts on `setAttributeNode` calls

We create one span inside the root div, set an attribute on that
span and then do the same on the root div, and ensure that both
events are correctly emitted.  In one case, we will be creating a
new attribute, and in the other case, replacing an existing one.

        it 'should send alerts on setAttributeNode calls',
        inPage ->
            pageSetup ->
                window.div = document.getElementById '0'
                window.div.innerHTML = '''
                <span example="yes">content</span>
                '''
                window.span = div.childNodes[0]
                window.tracker = DOMEditTracker.instanceOver div
                tracker.clearStack()

Set an attribute on the div, then change the attribute on the
span.  As we do so, validate that the return values of the calls
to `setAttributeNode` are as they should be, the attribute node
being replaced, or null if there was none.

            pageSetup ->
                edit = document.createAttribute 'align'
                edit.value = 'center'
                window.result1 = div.setAttributeNode edit
            pageExpects ( -> result1 ), 'toBeNull'
            pageSetup ->
                edit = document.createAttribute 'example'
                edit.value = 'no'
                window.result2 = span.setAttributeNode edit
            pageExpects ( -> result2.name ), 'toEqual', 'example'
            pageExpects ( -> result2.value ), 'toEqual', 'yes'

Validate the recorded edit actions.

            pageExpects ( -> tracker.getEditActions().length ),
                'toEqual', 2
            pageExpects ( ->
                tracker.getEditActions()[0].toJSON() ),
                'toEqual', {
                    type : 'setAttributeNode',
                    node : [], name : 'align',
                    oldValue : '', newValue : 'center'
                }
            pageExpects ( ->
                tracker.getEditActions()[1].toJSON() ),
                'toEqual', {
                    type : 'setAttributeNode',
                    node : [ 0 ], name : 'example',
                    oldValue : 'yes', newValue : 'no'
                }

