
# `LurchEditor` class

A Lurch Editor is an HTML DIV (that has *not* been marked as
`content-editable` in the browser) but that will be made editable
by the user through the functionality of this class.

    class LurchEditor

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
it back into the list of free ids.

        addFreeId: ( id ) ->
            if id < @freeIds[@freeIds.length-1]
                @freeIds.push id
                @freeIds.sort()

The constructor takes any DIV from the browser's HTML DOM.
It does not yet implement the following features, but it will:
 * Collect a list of all used ids in the given div, removing any
   ids that aren't of the correct form.
 * Create a list of the complement of the set of used ids, as a
   set of free ids.
 * For every un-id'ed element, give it the next available id.


        constructor: ( div ) ->
            @freeIds = [ 0 ]

