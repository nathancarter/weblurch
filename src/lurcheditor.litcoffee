
# `LurchEditor` class

A Lurch Editor is an HTML DIV (that has *not* been marked as
`content-editable` in the browser) but that will be made editable
by the user through the functionality of this class.

    window.LurchEditor = class LurchEditor extends DOMEditTracker

## Functions related to ids

The object maintains a list of unique integer ids for assigning to
elements in the HTML DOM, from that DIV on downwards in the tree.
The list `@freeIds` is a list $[a\_1,\ldots,a\_n]$ such that an id
is available if and only if it's one of the $a\_i$ or is greater
than $a\_n$.  For this reason, the list begins as `[ 0 ]`, in the
constructor, below.

When a free id is needed, we need a function that will give the
next such free id and then mark that id as consumed from the list.

        nextFreeId: ->
            if @freeIds.length > 1
                @freeIds.shift()
            else
                @freeIds[0]++

When an id in use becomes free, we need a function that will put
it back into the list of free ids.  The sort in the code below is
by numerical order, not dictionary (string) order.

        addFreeId: ( id ) ->
            if id < @freeIds[@freeIds.length-1]
                @freeIds.push id
                @freeIds.sort ( a, b ) -> a - b

## `LurchEditor` constructor

The constructor takes any DIV from the browser's HTML DOM, or no
argument if the instance is not to be made visible in a webpage.
See the constructor of [the ancestor `DOMEditTracker` class](
domedittracker.litcoffee.html) for more information on the call to
`super`.

The constructor also starts a timer that's used to flash the cursor
in the document, when the cursor is visible.  Only one timer is
created, which governs all instances of this class, so we use the
following class variable to store the timer id.

        cursorTimerId: null

Now, the constructor itself.

        constructor: ( div ) ->
            super div

It calls `cleanIds` on that DIV to remove from it any ids that
aren't nonnegative integers.

            usedIds = @cleanIds div

Then it computes the list of `freeIds` as the complement of the set
of nonnegative integer ids found by `cleanIds`.

            @freeIds = if usedIds.length is 0 then [ 0 ] else
                ( i for i in [0..(Math.max usedIds...)+1] \
                    when i not in usedIds )

Last, for every HTMLElement under the DIV without an id, the
constructor gives it the next available id.

            @assignIds div

Because all of those changes may have been recorded by this object
(as a `DOMEditTracker`) we now clear its undo/redo stack, so that
they are not later undoable by a user.

            @clearStack()

The editor keeps references to cursor position and anchor elements
in a member variable, for easy access.  These begin as null,
meaning that there is no cursor initially; the document doesn't
have focus.  For more information on these variables, see the
[section below on the cursor](#cursor-support).

            @cursor = position : null, anchor : null

Start the timer for blinking the cursor.

            if LurchEditor::cursorTimerId is null
                LurchEditor::cursorTimerId = setInterval \
                    LurchEditor::blinkCursors, 500

## Functions used by the constructor

Collect a list of all used ids in the given node, removing any
ids that aren't just nonnegative integers.  This routine is used
by the class's constructor as part of the procedure for
initializing the node in the DOM in which the LurchEditor will
reside.

        cleanIds: ( node ) ->
            result = []
            if node not instanceof Node then return result
            if node.id
                if /^\d+$/.test node.id
                    result.push parseInt node.id
                else
                    node.removeAttribute 'id'
            for child in node.childNodes
                result = result.concat ( id for id in \
                    @cleanIds child when id not in result )
            result

Assign ids to every HTMLElement under the given node, using this
object's `nextFreeId` function to do so.  Non-HTMLElement nodes are
not given ids.

        assignIds: ( node ) ->
            if node not instanceof Node then return
            if node instanceof HTMLElement and not node.id
                node.id = @nextFreeId()
            @assignIds child for child in node.childNodes

## Convenience methods

DOM Nodes have the methods `address` and `index` implemented in
them; see [the documentation on those functions](
domutils.litcoffee.html#address) for more information.

It will be convenient to be able to call such methods in a
`LurchEditor`, thereby having its main element provided as the
default arguments.  We therefore define the following two shortcut
functions.

Let `LE.address N` be shorthand for `N.address LE.getElement()`.
But if we have no main HTML element, return null.

        address: ( node ) ->
            if @element then node?.address @element else null

Let `LE.index A` be shorthand for `LE.getElement().index A`.
But if we have no main HTML element, return null.

        index: ( address ) ->
            if @element then @element.index address else null

We therefore have the guarantee `N == LE.index LE.address N`
inherited from the address and index functions defined in the Node
prototype.

## Cursor support

The following two element ids will be used for the elements that
represent the cursor position and anchor in the document.

        positionId: 'lurch-cursor-position'
        anchorId: 'lurch-cursor-anchor'

The following class will be used for the elements that sit within
the selection, i.e., those between the cursor position and anchor.

        selectionClass: 'lurch-cursor-selection'

The `cursor` member of this class contains two fields, `position`
and `anchor`.
 * These may both be null, meaning that there is no cursor in the
   document.
 * These may both be the same element, meaning that there is no
   selection; the cursor position and anchor are the same.
 * These may be different elements, meaning that there is a
   selection; it includes all leaves between the position and
   anchor.

### Keeping member variables up to date with DOM

Because it is possible for the document state to become out-of-sync
with these variables, we provide the following routine to update
them.  Although in many cases it's possible to simply keep those
member variables up-to-date, we have this routine in case a
document is restored from a serialized state with a cursor at a
specific position, so that the member variables can get caught up
to the document state.

        updateCursor: ->
            @cursor = position : null, anchor : null
            walk = start = document.getElementById \
                LurchEditor::positionId
            while walk and not @cursor.position
                if walk is @element then @cursor.position = start
                walk = walk.parentNode
            walk = start = document.getElementById \
                LurchEditor::anchorId
            while walk and not @cursor.anchor
                if walk is @element then @cursor.anchor = start
                walk = walk.parentNode

### Which HTML element types can contain the cursor?

This class supports placing the cursor inside some HTML elements,
but not others.  For isntance, you can place your cursor inside a
SPAN, but not inside an HR.  The following variable local to this
module stores the list of variables in which we can place the
cursor.  (These were selected from [the full list on the w3schools
website](http://www.w3schools.com/tags/).)

        elementsSupportingCursor: t.toUpperCase() for t in '
            a abbr acronym address article aside b bdi bdo big
            blockquote caption center cite code dd details dfn div
            dl dt em fieldset figcaption figure footer form header
            h1 h2 h3 h4 h5 h6 i kbd label legend li mark nav ol p
            pre q s samp section small span strong sub summary sup
            td th time u ul var'.trim().split /\s+/

### Number of cursor positions within a given node

For placing the cursor within a node, we need to be able to compute
how many cursor positions are available within that node.  The
following routine does so, recursively.

Note that it computes only the number of cursor positions *inside*
the node, so a node such as &lt;span&gt;hi&lt;/span&gt; would have
three locations (before the h, after the h, and after the i).  The
two locations outside the node (before and after it) are *not*
counted by this routine; they will be counted if this were called
on the span's parent node.

This is even true for text nodes!  For example, the text node child
inside the span in the previous paragraph has one inner location,
because the positions before the h and after the i do not count as
"inside."

        cursorPositionsIn: ( node ) ->

Text nodes can have the cursor before any character but the first,
because, as described above, we are counting only the cursor
positions *inside* the node.  For text nodes with no content, this
has the funny consequence of giving -1 cursor positions, but that
is acceptable.

            if node instanceof Text
                node.length - 1

Next we handle the two subcases of nodes without children.

Some nodes with no children are only temporarily childless; e.g.,
an empty span can contain the cursor and permit typing within it.
For such nodes, we say there is one cursor location, which is
immediately inside the node.

Other nodes with no children are not permitted to contain the
cursor (e.g., a horizontal rule, an image, etc.).  Such nodes have
no cursor positions inside them.

            else if node.childNodes.length is 0
                if node.tagName in \
                LurchEditor::elementsSupportingCursor then 1 \
                else 0

Nodes with children have a character count that depends on the
character counts of the children.  We sum the character counts of
the children, which accounts for all cursor positions strictly
inside the children, but then we need to add the cursor positions
immediately inside the parent node, but between children, or before
or after all children.  There are $n+1$ of them, if $n$ is the
number of children, because every child has a valid position before
it, and the last child also has one additional valid position after
it.

            else
                result = node.childNodes.length + 1
                for child, index in node.childNodes
                    result += @cursorPositionsIn child
                result

### Removing the cursor from the document

There are times when the cursor (and its anchor, and any selection)
needs to be removed from the document.  For example, one such time
is when the document loses focus.  This function accomplishes that.

        removeCursor: ->

First, let's be sure our member variables about the cursor are
up-to-date.

            @updateCursor()
            
Remove the cursor and its anchor from the document, setting the
variables that track them to null.

            @cursor.position?.remove()
            @cursor.anchor?.remove()
            @cursor.position = @cursor.anchor = null

Now remove the selection class from anything that had it.

            selection = Array::slice.apply \
                @element.getElementsByClassName \
                LurchEditor::selectionClass
            for element in selection
                selection.removeClass? LurchEditor::selectionClass

Because this may have placed two text nodes next to one another,
normalize to unit them.

            @element.normalize()

### Inserting the cursor into the document

If we are to insert a cursor into the document, we need a way to
create a new cursor element.  It will simply be a span with the
id declared [earlier](#cursor-support).

        makeNewCursor = ->
            result = document.createElement 'span'
            result.setAttribute 'id', LurchEditor::positionId
            result

To insert the cursor into the document, we first remove it from
wherever it currently is, if anywhere, then we insert it at the
given cursor position.  If no cursor position is given, we default
to using the very beginning of the document.

        placeCursor: ( position = 0 ) ->

Remove the old cursor, if any, and create a new one.

            @removeCursor()
            newCursor = makeNewCursor()

Now we need to recur, so we create an inner, auxiliary routine for
recurring from the root div of the editor on downward.

            recur = ( node, pos ) =>

As we start to recur down the DOM hierarchy, we first consider HTML
elements that can have children.  For such nodes, We look at their
children.

The interstices between them fall at various indices.  If any such
index matches `pos`, then we insert the new cursor at that
interstice.  If not, then we recur on the child which contains the
cursor position.

                if node.tagName in \
                LurchEditor::elementsSupportingCursor
                    count = 0
                    for child in Array::slice.apply node.childNodes

Is it the interstice before the current child?

                        if count is pos
                            node.insertBefore newCursor, child
                            return

No, so add 1 to count, to record that interstice.  Then see if the
child itself contains the cursor.  If so, recur on the child.

                        count++
                        size = @cursorPositionsIn child
                        if pos < count + size
                            recur child, pos - count
                            return
                        count += size

If none of that succeeded, place the cursor at the end of the list
of children.  This assumes that the routine was not called with too
large a cursor position; if it was, this caps it at the maximum.

This includes the case where the element has no children, and *any*
position was given, valid or otherwise.

                    node.appendChild newCursor

The only kind of node we support that has cursor positions in it
but that cannot contain child nodes is a Text node.  For it, we
split the text node if necessary.

Recall that position 0 inside a text node is actually after the
first character, because that is the first position *inside*.  Even
so, we include boundary cases just to be safe.

                else if node instanceof Text
                    if pos + 1 <= 0
                        node.parentNode.insertBefore newCursor,
                            node
                    else if pos + 1 >= node.textContent.length
                        node.parentNode.appendChild newCursor
                    else
                        split = node.splitText pos + 1
                        node.parentNode.insertBefore newCursor,
                            split

If we attempted to insert the cursor inside a non-text node that
cannot support children, the routine does nothing.

Now call that auxiliary routine on the root div.

            recur @element, position
            @cursor.position = @cursor.anchor = newCursor

### Blinking the cursor

The following callback is a "class method," because it is a timer's
callback, and therefore won't have a `this` object defined.  We
therefore apply it to every existing `LurchEditor` instance.  We
find a list of them by utilizing the fact that the parent class,
`DOMEditTracker`, keeps a list of all its instances, which we can
filter to just those that are also `LurchEditor`s.

The following CSS class will be used for the element that
represents the cursor position in the document.

        cursorVisible: 'lurch-cursor-visible'

This routine adds/removes a CSS class that makes the cursor
visible, and it does so in all of the child nodes of the root div
for each `LurchEditor` instance.  Because this happens regularly,
as set up by a repeating timer in the constructor, all cursors end
up flashing, as desired, so long as the CSS class given above
appears in the page stylesheet with an appropriate definition.

        blinkCursors: ( onOff = 'toggle' ) ->
            cssClass = LurchEditor::cursorVisible
            for LE in DOMEditTracker.instances
                if LE instanceof LurchEditor
                    LE.updateCursor()
                    continue unless LE.cursor.position
                    if onOff is 'toggle'
                        onOff = not LE.cursor.position.hasClass \
                            cssClass
                    if onOff
                        LE.cursor.position.addClass cssClass
                    else
                        LE.cursor.position.removeClass cssClass

