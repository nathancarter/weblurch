
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

It initializes the following member variable, discussed below in
the [undo/redo stack section](#undo-redo-stack).

            @stackPointer = 0

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

## Undo/redo stack

The [DOMEditTracker](domedittracker.litcoffee.html) class (from
which this class derives) provides an undo/redo stack, but here we
add some functionality to it.

We add a pointer into the stack, an integer that is one greater
than the last performed action.  That pointer was initialized in
[the constructor](#-code-lurcheditor-code-constructor), above.  It
satisfies the following criteria.
 * When it equals the stack length, then the last action done is
   the last action on the stack, and was *not* an "undo."  It was
   either an action done for teh first time, or was a "redo."
 * When it is less than the stack length, then the last action
   done was either an "undo" or a "redo," as the user navigated
   the undo/redo stack with buttons/keyboard shortcuts/etc.

To preserve these two properties, we implement the following
features.

We override the `nodeEditHappened` method so that, if needed, it
truncates the stack to have length equal to the stack pointer
before using the superclass's implementation to append the latest
action to that stack.  After doing so, it updates the pointer to
equal the stack length, thus preserving the invariant that the
final action on the stack was the most recently completed one.

        nodeEditHappened: ( args... ) ->
            if @stackPointer < @stack.length
                @stack = @stack[..@stackPointer]
            super args...
            @stackPointer = @stack.length

We add `canUndo` and `canRedo` methods to the class that just
report whether the index pointer isn't at the top or bottom of the
stack.

        canUndo: -> @stackPointer > 0
        canRedo: -> @stackPointer < @stack.length

We add methods that can describe teh atcions that would take place
if undo or redo were invoked, returning the empty string if one
cannot undo/redo.

        undoDescription: ->
            return 'Undo' + if @stackPointer is 0 then '' else
                @stack[@stackPointer - 1].toString()
        redoDescription: ->
            return 'Redo ' +
                if @stackPointer is @stack.length then '' else
                @stack[@stackPointer].toString()

We add `undo` and `redo` methods that move the stack pointer while
calling the `undo` and `redo` methods in the appropriate actions on
the stack.

(not yet implemented)

