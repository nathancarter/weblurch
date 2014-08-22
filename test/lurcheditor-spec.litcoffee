
# Tests for the `LurchEditor` class

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe, pageDo, pageExpects,
      pageExpectsError, inPage } = require './phantom-utils'

## LurchEditor class

    phantomDescribe 'LurchEditor class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', inPage ->
            pageExpects -> LurchEditor

## LurchEditor instances without DIVs

    phantomDescribe 'LurchEditor instances without DIVs',
    './app/index.html', ->

### should initialize freeIds

A newly created `LurchEditor` instance should have a `freeIds`
array containing only zero.

        it 'should initialize freeIds', inPage ->
            pageExpects ( ->
                L = new LurchEditor()
                L.freeIds
            ), 'toEqual', [ 0 ]

Calling `nextFreeId()` on a newly created instance should keep
yielding nonnegative integers starting with zero and counting
upwards.  The resulting `freeIds` array should have in it just
the next integer.

### nextFreeId() should count 0,1,2,...

        it 'nextFreeId() should count 0,1,2,...', inPage ->
            pageDo -> window.L = new LurchEditor()
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 0
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 1
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 2
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 3
            pageExpects ( -> L.freeIds ), 'toEqual', [ 4 ]

### addFreeId() re-inserts in order

        it 'addfreeId() re-inserts in order', inPage ->

Create a new instance and put it through the same sequence of
`nextFreeId()` calls as above.  We should get the same result.

            pageDo ->
                window.L = new LurchEditor()
                L.nextFreeId() for i in [1..4]
            pageExpects ( -> L.freeIds ), 'toEqual', [ 4 ]

Then restoring the id 2 should put it back on the `freeIds` list in
the correct spot.

            pageDo -> L.addFreeId 2
            pageExpects ( -> L.freeIds ), 'toEqual', [ 2, 4 ]

But restoring any id 4 or higher should do nothing.

            pageDo ->
                L.addFreeId 4
                L.addFreeId 10
                L.addFreeId 100
            pageExpects ( -> L.freeIds ), 'toEqual', [ 2, 4 ]

Then calls to `nextFreeId` should yield 2, 4, 5, 6, ...

            pageExpects ( -> L.nextFreeId() ), 'toEqual', 2
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 4
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 5
            pageExpects ( -> L.nextFreeId() ), 'toEqual', 6

## LurchEditor instances with DIVs

We now test constructing a new `LurchEditor` instance around an
existing DOM element, and verify that it does the correct things
with ids.  See the documentation in
[the Lurch Editor class itself](lurcheditor.litcoffee.html) for
details on what the constructor is expected to do in these
situations, or read each test description below.

    phantomDescribe 'LurchEditor instances with DIVs',
    './app/index.html', ->

### should give an empty DIV id 0

        it 'should give an empty DIV id 0', inPage ->

When constructed in an empty DIV, it should give that DIV the id 0,
and thus have a free ids list of `[ 1 ]` aftewards.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.L = new LurchEditor div
            pageExpects ( -> parseInt( div.id ) ), 'toEqual', 0
            pageExpects ( -> L.freeIds ), 'toEqual', [ 1 ]

### should remove all invalid ids

        it 'should remove all invalid ids', inPage ->

When constructed in a DIV containing a hierarchy of nested spans,
some of which have ids, all of which are invalid, it should remove
all of their old ids, and assign them each a new, unique,
nonnegative integer id.  In this test, we verify only that it
removed all of their old ids.

            pageDo ->
                window.div = document.createElement 'div'
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

For each id we expect to be in the document (because it's mentioned
in the HTML code given above), verify that it is actually present
in the document by looking up the id and verifying that the result
is not null.

            pageExpects ->
                document.getElementById( 'yo' ) isnt null
            pageExpects ->
                document.getElementById( 'inner' ) isnt null
            pageExpects ->
                document.getElementById( '-1' ) isnt null
            pageExpects ->
                document.getElementById( '-0' ) isnt null
            pageExpects ->
                document.getElementById( '1.0' ) isnt null
            pageExpects ->
                document.getElementById( 'hank' ) isnt null

Install the Lurch Editor in the DIV in question.

            pageDo -> new LurchEditor div

For each id that used to be in the document, verify that it is no
longer present in the document.

            pageExpects -> document.getElementById( 'yo' ) is null
            pageExpects ->
                document.getElementById( 'inner' ) is null
            pageExpects -> document.getElementById( '-1' ) is null
            pageExpects -> document.getElementById( '-0' ) is null
            pageExpects -> document.getElementById( '1.0' ) is null
            pageExpects ->
                document.getElementById( 'hank' ) is null

### should assign unique integer ids

        it 'should assign unique integer ids', inPage ->

If we re-run the same test as the previous (creating a
`LurchEditor` class around the same DIV) we should find that it
has also assigned unique non-negative integer ids to each element
in the DOM tree beneath that DIV, starting with 0 and proceeding
upwards sequentially.

            pageDo ->
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

                window.LE = new LurchEditor div

Now find all ids of all nodes under that div, and sort numerically.

                allNodesUnder = ( node ) ->
                    result = [ node ]
                    for child in node.childNodes
                        result = result.concat allNodesUnder child
                    result
                window.ids = ( parseInt node.id for node in \
                    allNodesUnder div when node.id )
                ids.sort ( a, b ) -> a - b

Verify that the list is `[ 0, 1, ..., 10 ]`.

            pageExpects ( -> ids ), 'toEqual', [0..10]

Verify that the list of free ids is "everything 11 and above."

            pageExpects ( -> LE.freeIds ), 'toEqual', [ 11 ]

### should work with existing integer ids

If we run a similar test to the previous two, but with the DIV
slightly altered to include a few valid integer ids, we should
find that it has also assigned unique non-negative integer ids to
each element in the DOM tree beneath that DIV, starting with 0 and
proceeding upwards sequentially, but keeping the existing valid
integer ids unchanged.

        it 'should work with existing integer ids', inPage ->
            pageDo ->
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

                window.LE = new LurchEditor div

Now find all ids of all nodes under that div, and sort them.

                allNodesUnder = ( node ) ->
                    result = [ node ]
                    for child in node.childNodes
                        result = result.concat allNodesUnder child
                    result
                window.ids = ( parseInt node.id for node in \
                    allNodesUnder div when node.id )
                ids.sort ( a, b ) -> a - b

Verify that the list is `[ 0, 1, ..., 9, 20 ]`.

            pageExpects ( -> ids ), 'toEqual', [0..9].concat [ 20 ]

Verify that the list of free ids is "everything 10 and above,
except 20."

            pageExpects ( -> LE.freeIds ),
                'toEqual', [10..19].concat [ 21 ]

Verify that the ids for the nodes that already had valid integer
ids were left unchanged.

            pageExpects ( ->
                document.getElementById( 1 ).textContent \
                    .replace /^\s+|\s+$/g, '' ),
                'toEqual', 'pos number'
            pageExpects ( ->
                document.getElementById( 4 ).textContent \
                    .replace /^\s+|\s+$/g, '' ),
                'toEqual', 'italic'
            pageExpects ( ->
                document.getElementById( 20 ).textContent \
                    .replace /^\s+|\s+$/g, '' ),
                'toEqual', 'big-ish number'

### should have working address and index

        it 'should have working address and index', inPage ->

The `LurchEditor` class defines shortuct address and index
functions that just make the calls relative to their main HTML
elements.  We verify here briefly that those functions work, but
do not test them extensively, since that is already done in
[the unit test for DOM utilities](domutils-spec.litcoffee.html).

            pageDo ->
                window.div = document.createElement 'div'
                div.id = '0'
                document.body.appendChild div
                window.span1 = document.createElement 'span'
                span1.id = '1'
                div.appendChild span1
                window.span2 = document.createElement 'span'
                span2.id = '2'
                div.appendChild span2
                window.LE = new LurchEditor div

Four address queries.

            pageExpects ( -> LE.address div ), 'toEqual', []
            pageExpects ( -> LE.address span1 ), 'toEqual', [ 0 ]
            pageExpects ( -> LE.address span2 ), 'toEqual', [ 1 ]
            pageExpects -> null is LE.address document

Four index queries, the last of which we expect to be undefined.

            pageExpects ( -> LE.index( [] ).id ), 'toEqual', '0'
            pageExpects ( -> LE.index( [ 0 ] ).id ), 'toEqual', '1'
            pageExpects ( -> LE.index( [ 1 ] ).id ), 'toEqual', '2'
            pageExpects ( -> LE.index [ 0, 0 ] ),
                'toBeUndefined'

### should give no address and index if empty

        it 'should give no address and index if empty', inPage ->

The shortuct address and index functions in the `LurchEditor` class
should function correctly (returning null) if the main HTML element
of the instance is empty.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.LE = new LurchEditor()
            pageExpects ( -> LE.address div ), 'toBeNull'
            pageExpects ( -> LE.index div ), 'toBeNull'

## LurchEditor cursor support

We now test the routines that support placement and movement of
cursor position and anchor elements in the document.

    phantomDescribe 'LurchEditor cursor support',
    './app/index.html', ->

### should locate position and anchor elements

        it 'should locate position and anchor elements', inPage ->

In this test we construct a `LurchEditor` over a div that's got
some elements inside that can function like cursor position and
anchor markers.  We assign those elements the appropriate ids to
indicate that they are cursor position and anchor markers, and
verify that the editor can identify them as such.

            pageDo ->

Create a div and put inside five spans, only two of which are
marked as cursor position and anchor elements.

                window.div = document.createElement 'div'
                document.body.appendChild div
                window.LE = new LurchEditor div
                temp = document.createElement 'span'
                temp.textContent = 'not important'
                div.appendChild temp
                window.P = document.createElement 'span'
                P.id = LurchEditor::positionId
                P.textContent = 'foo'
                div.appendChild P
                temp = document.createElement 'span'
                temp.textContent = 'also not important'
                div.appendChild temp
                window.A = document.createElement 'span'
                A.id = LurchEditor::anchorId
                A.textContent = 'bar'
                div.appendChild A
                temp = document.createElement 'span'
                temp.textContent = 'yes, still not important'
                div.appendChild temp

Verify that, at first, the `LurchEditor` instance has no known
cursor position or anchor elements.

            pageExpects ( -> LE.cursor.position ), 'toBeNull'
            pageExpects ( -> LE.cursor.anchor ), 'toBeNull'

Now have the editor find its cursor position and anchor elements.

            pageDo -> LE.updateCursor()

Verify that it found the correct items.

            pageExpects -> LE.cursor.position is P
            pageExpects -> LE.cursor.anchor is A

Next, remove those elements from the document.  We will then
recompute the cursor position and anchor, and verify that they
have become null once again.

            pageDo ->
                div.removeChild P
                div.removeChild A
                LE.updateCursor()
            pageExpects ( -> LE.cursor.position ), 'toBeNull'
            pageExpects ( -> LE.cursor.anchor ), 'toBeNull'

### should provide the cursorPositionsIn member

This section and the next test the routine defined [here](
lurcheditor.litcoffee#number-of-cursor-positions-with-a-given-node).

First, just verify that it's present.

        it 'should provide the cursorPositionsIn member', inPage ->
            pageExpects -> LurchEditor::cursorPositionsIn

### should compute correct cursor position counts

        it 'should compute correct cursor position counts',
        inPage ->

The title for this test is vague, but the reason is so that we
may pack several tests into one `it` call.  (There is no need to
reload the page after each of these.)

First, the character count of a text node should be the number of
characters in it minus one.

            pageDo ->
                window.L = new LurchEditor()
                window.T = document.createTextNode ''
            pageExpects ( -> L.cursorPositionsIn T ), 'toEqual', -1
            pageDo -> T.textContent = 'A'
            pageExpects ( -> L.cursorPositionsIn T ), 'toEqual', 0
            pageDo -> T.textContent = 'hi'
            pageExpects ( -> L.cursorPositionsIn T ), 'toEqual', 1
            pageDo -> T.textContent = 'hello, friends'
            pageExpects ( -> L.cursorPositionsIn T ), 'toEqual', 13

Second, a non-text node with no children and no permission to
contain the cursor should have no cursor positions.  Here I test
just a few example such elements.

            pageDo -> window.S = document.createElement 'img'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 0
            pageDo -> window.S = document.createElement 'hr'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 0
            pageDo -> window.S = document.createElement 'br'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 0

Third, a non-text node with no children but with position to
contain the cursor should have one cursor position.  Here I test
just a few example such elements.

            pageDo -> window.S = document.createElement 'a'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 1
            pageDo -> window.S = document.createElement 'td'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 1
            pageDo -> window.S = document.createElement 'span'
            pageExpects ( -> L.cursorPositionsIn S ), 'toEqual', 1

Finally, elements with children should return the total count of
all characters in all children, plus the number of children,
plus 1.

            pageDo ->
                window.D = document.createElement 'div'
                D.innerHTML = 'some text <span>more text</span><br
                    ><span>nest<i>ed</i></span>'
            pageExpects ( -> L.cursorPositionsIn D ), 'toEqual', 33
            pageDo -> D.innerHTML = '<b><i><u>1</u></i></b>'
            pageExpects ( -> L.cursorPositionsIn D ), 'toEqual', 8

### should provide the placeCursor member

This section and the next test the routine defined [here](
lurcheditor.litcoffee#inserting-the-cursor-into-the-document).
Note that testing `placeCursor` implicitly tests `removeCursor`
because `removeCursor` is called at the beginning of every run of
`placeCursor`, and if it didn't work, then there would be two
cursors in the document thereafter, and the `placeCursor` tests
would therefore fail.

First, just verify that it's present.

        it 'should provide the placeCursor member', inPage ->
            pageExpects -> LurchEditor::placeCursor

### should place the cursor correctly

In this routine, not only do we test the `placeCursor` routine,
verifying that it puts the cursor where we expect, but we also
verify that, after the cursor has been placed, it reports its
position correctly.  That is, if we put the cursor at position $k$,
then after verifying that it appeared where we expect, we also
query its position (using `cursorPositionOf`) and ensure that it is
$k$.

        it 'should place the cursor correctly', inPage ->

Initialize the contents of the main div to have some text, some
no-children nodes, and some nested items.

            pageDo ->
                window.div = LE.getElement()
                div.innerHTML =
                    'text<br><span><i>more</i></span><b></b>'

Verify that the desired structure was produced.

            initialConfiguration = {
                tagName : 'DIV'
                attributes : { id : '0' }
                children : [
                    'text'
                    tagName : 'BR'
                    {
                        tagName : 'SPAN'
                        children : [
                            {
                                tagName : 'I'
                                children : [ 'more' ]
                            }
                        ]
                    }
                    tagName : 'B'
                ]
            }
            pageExpects ( -> div.toJSON() ), 'toEqual',
                initialConfiguration

Place the cursor at the beginning of the document.  Then remove any
indication of whether the cursor is blinking on or off, and clone
that state of the document for later comparison.

            pageDo ->
                LE.placeCursor()
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 0.

            cursor = {
                tagName : 'SPAN'
                attributes : { id : 'lurch-cursor-position' }
            }
            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children.unshift cursor
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 0

Place the cursor way past the end of the document, which will be
treated as placing it at the end of the document.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 1000
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 15, which is the last
one in the document.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children.push cursor
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 15

Place the cursor between the first two nodes (text and BR).
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 4
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 4.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                copy.children[0]
                cursor
                copy.children[1]
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 4

Place the cursor between the second and third nodes (BR and span).
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 5
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 5.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                copy.children[0]
                copy.children[1]
                cursor
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 5

Place the cursor inside the initial text node, and ensure it
splits.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 2
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 2.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                'te'
                cursor
                'xt'
                copy.children[1]
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 2

Place the cursor inside the final span, but not yet inside its
inner italic element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 6
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 6.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children = [
                cursor
                copy.children[2].children[0]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 6

Place the cursor one step further, not only inside the final span,
but also inside its inner italic element, just before the text
inside that italic element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 7
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 7.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children[0].children = [
                cursor
                'more'
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 7

Place the cursor one step further, thus splitting the text "more"
into two pieces.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 8
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 8.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children[0].children = [
                'm'
                cursor
                'ore'
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 8

Place the cursor two steps further, thus splitting the text "more"
at a different location.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 10
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 10.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children[0].children = [
                'mor'
                cursor
                'e'
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 10

Place the cursor one step further, after the text "more" but still
inside the italic element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 11
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 11.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children[0].children = [
                'more'
                cursor
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 11

Place the cursor one step further, after the italic element but
still inside the span.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 12
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 12.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children = [
                copy.children[2].children[0]
                cursor
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 12

Place the cursor one step further, and verify that that is right
before the empty bold element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 13
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 13.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                copy.children[0]
                copy.children[1]
                copy.children[2]
                cursor
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 13

Place the cursor one step further, and verify that that is inside
the empty bold element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 14
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 14.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[3].children = [ cursor ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 14

Place the cursor one step further, and verify that that is at the
end of the document.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 15
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 15.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children.push cursor
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 15

### should preserve the anchor correctly

The `placeCursor` routine takes an optional parameter that can
make the cursor's anchor stay still while the cursor moves.
We thus take variations on the previous section's tests, now
keeping the anchor still, and verifying that the results remain
correct.

        it 'should preserve the anchor correctly', inPage ->

Initialize the contents of the main div as in the previous test.

            pageDo ->
                window.div = LE.getElement()
                div.innerHTML =
                    'text<br><span><i>more</i></span><b></b>'

Verify that the desired structure was produced.

            initialConfiguration = {
                tagName : 'DIV'
                attributes : { id : '0' }
                children : [
                    'text'
                    tagName : 'BR'
                    {
                        tagName : 'SPAN'
                        children : [
                            {
                                tagName : 'I'
                                children : [ 'more' ]
                            }
                        ]
                    }
                    tagName : 'B'
                ]
            }
            pageExpects ( -> div.toJSON() ), 'toEqual',
                initialConfiguration

Place the cursor at the beginning of the document.  Then remove
any indication of whether the cursor is blinking on or off, and
clone that state of the document for later comparison.

            pageDo ->
                LE.placeCursor()
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 0.

            cursor = {
                tagName : 'SPAN'
                attributes : { id : 'lurch-cursor-position' }
            }
            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children.unshift cursor
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 0
            pageExpects ( -> LE.anchorPosition() ), 'toEqual', 0

Place the cursor way past the end of the document, which will be
treated as placing it at the end of the document.  Do not let
the anchor move.
Again, we make a clone to remove the possibility of cursor
blinking.

            anchor = {
                tagName : 'SPAN'
                attributes : { id : 'lurch-cursor-anchor' }
            }
            pageDo ->
                LE.placeCursor 1000, no
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 15, which is the last
one in the document.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children.unshift anchor
            copy.children.push cursor
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 15
            pageExpects ( -> LE.anchorPosition() ), 'toEqual', 0

Place the cursor between the first two nodes (text and BR).
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 4
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 4.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                copy.children[0]
                cursor
                copy.children[1]
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 4
            pageExpects ( -> LE.anchorPosition() ), 'toEqual', 4

Place the cursor between the second and third nodes (BR and span).
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 5, no
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 5.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                copy.children[0]
                anchor
                copy.children[1]
                cursor
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 5
            pageExpects ( -> LE.anchorPosition() ), 'toEqual', 4

Place the cursor inside the initial text node, and ensure it
splits.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 2, no
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 2.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children = [
                'te'
                cursor
                'xt'
                anchor
                copy.children[1]
                copy.children[2]
                copy.children[3]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 2
            pageExpects ( -> LE.anchorPosition() ), 'toEqual', 4

Place the cursor inside the final span, but not yet inside its
inner italic element.
Again, we make a clone to remove the possibility of cursor
blinking.

            pageDo ->
                LE.placeCursor 6
                LurchEditor::blinkCursors off
                window.LEcopy = LE.getElement().cloneNode true

Verify that it got there, and is at position 6.

            copy = JSON.parse JSON.stringify initialConfiguration
            copy.children[2].children = [
                cursor
                copy.children[2].children[0]
            ]
            pageExpects ( -> LEcopy.toJSON() ), 'toEqual', copy
            pageExpects ( -> LE.cursorPosition() ), 'toEqual', 6

