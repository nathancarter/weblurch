
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

Because all the actions about dealing with ids often change the
DOM starting at the given `div` and going down, they generate
change events that the superclass records.  We do not wish to have
those changes recorded here, because we do not wish to allow the
user to undo them.  Thus at this point, we clear the changes stack.

            @clearStack()

The editor keeps references to cursor position and anchor elements
in a member variable, for easy access.  These begin as null,
meaning that there is no cursor initially; the document doesn't
have focus.  For more information on these variables, see the
[section below on the cursor](#cursor-support).

            @cursor = position : null, anchor : null

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

The `cursor` member of this class contains two fields, `position`
and `anchor`.
 * These may both be null, meaning that there is no cursor in the
   document.
 * These may both be the same element, meaning that there is no
   selection; the cursor position and anchor are the same.
 * These may be different elements, meaning that there is a
   selection; it includes all leaves between the position and
   anchor.

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

This class supports placing the cursor inside some HTML elements,
but not others.  For isntance, you can place your cursor inside a
SPAN, but not inside an HR.  The following variable local to this
module stores the list of variables in which we can place the
cursor.  (These were selected from [the full list on the w3schools
website](http://www.w3schools.com/tags/).)

        elementsSupportingCursor: t.toUpperCase() for t in '''
            a abbr acronym address article aside b bdi bdo big
            blockquote caption center cite code dd details dfn div
            dl dt em fieldset figcaption figure footer form header
            h1 h2 h3 h4 h5 h6 i kbd label legend li mark nav ol p
            pre q s samp section small span strong sub summary sup
            td th time u ul var'''.trim().split /\s+/

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

