
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
            pageExpects ( -> LurchEditor ), 'toBeTruthy'

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

            pageExpects ( ->
                document.getElementById( 'yo' ) isnt null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( 'inner' ) isnt null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '-1' ) isnt null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '-0' ) isnt null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '1.0' ) isnt null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( 'hank' ) isnt null ),
                'toBeTruthy'

Install the Lurch Editor in the DIV in question.

            pageDo -> new LurchEditor div

For each id that used to be in the document, verify that it is no
longer present in the document.

            pageExpects ( ->
                document.getElementById( 'yo' ) is null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( 'inner' ) is null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '-1' ) is null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '-0' ) is null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( '1.0' ) is null ),
                'toBeTruthy'
            pageExpects ( ->
                document.getElementById( 'hank' ) is null ),
                'toBeTruthy'

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
            pageExpects ( -> null is LE.address document ),
                'toBeTruthy'

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

            pageExpects ( -> LE.cursor.position is P ),
                'toBeTruthy'
            pageExpects ( -> LE.cursor.anchor is A ),
                'toBeTruthy'

Next, remove those elements from the document.  We will then
recompute the cursor position and anchor, and verify that they
have become null once again.

            pageDo ->
                div.removeChild P
                div.removeChild A
                LE.updateCursor()
            pageExpects ( -> LE.cursor.position ), 'toBeNull'
            pageExpects ( -> LE.cursor.anchor ), 'toBeNull'

