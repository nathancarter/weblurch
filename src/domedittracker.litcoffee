
# DOM Edit Tracker class

    window.DOMEditTracker = class DOMEditTracker

A `DOMEditTracker` is responsible for watching the edits to the
DOM within a single HTML DIV element, and thus it takes such a DIV
at construction time.

## Tracking instances

The class itself also tracks all instances thereof currently in
memory, so that it can find the one whose DIV contains any given
DOM Node.  This way when changes take place in a DOM Node, the
corresponding edit tracker, if any, can be notified.

        @instances = []

Here is the class method taht finds the edit tracker instance in
charge of an ancestor of any given DOM Node.  It returns the
`DOMEditTracker` instance if there is one, and null otherwise.

        @instanceOver = ( node ) ->
            if node not instanceof Node then return null
            for tracker in @instances
                if tracker.getElement() is node
                    return tracker
            @instanceOver node.parentNode

## Constructor

        constructor: ( div ) ->

If they did not pass a valid DIV, then store null in the member
variable reserved for that purpose.  If they passed *something*
but it wasn't a DIV, then throw an Error.

            @element = null
            if div and div?.tagName isnt 'DIV'
                throw new Error 'DOMEditTracker can only be ' +
                                'constructed in a DIV node'

Otherwise, store the DIV they passed for later reference.

            @element = div

In either case, initialize the internal undo/redo stack of
`DOMEditAction` instances to be empty, with a stack pointer of
zero.  (Documentation on how this stack pointer behaves appears in
the [undo/redo stack section](#undo-redo-stack), below.)

            @stack = []
            @stackPointer = 0

And add this newly created instance to the list of all instances.

            DOMEditTracker.instances.push this

## Getters

Although in CoffeeScript, no members are truly private, the
intent is that the fields of an object should not be directly
accessed from outside the class except through getters and
setters.

The first is for querying the element passed at construction time,
over which this object has taken "ownership."

        getElement: -> @element

Then we provide one for querying the stack of edit actions.  A copy
of the stack is returned, so that the caller may modify it as they
see fit without harming this object.

        getEditActions: -> @stack[..]

## Setters

The user can ask to clear out the edit actions stack with the
following method.

        clearStack: -> @stack = []

## Undo/redo stack

The stack pointer initialized in the [constructor](#constructor) is
an integer that is one greater than the index of the last performed
action.  It satisfies the following criteria.
 * When it equals the stack length, then the last action done is
   the last action on the stack, and was *not* an "undo."  It was
   either an action done for the first time, or was a "redo."
 * When it is less than the stack length, then the last action
   done was either an "undo" or a "redo," as the user navigated
   the undo/redo stack with buttons/keyboard shortcuts/etc.

To preserve these two properties, we implement the following
features.

When any editing takes place inside the DOM tree watched by an
instance of this class, the instance needs to be notified of it.
We therefore provide this method by which it can be notified.

It not only pushes the action onto the undo/redo stack, but,
if needed, it also truncates the stack to have length equal to the
stack pointer before using the superclass's implementation to
append the latest action to that stack.  After doing so, it updates
the pointer to equal the stack length, thus preserving the
invariant that the final action on the stack was the most recently
completed one.

The one parameter should be an instance of the `DOMEditAction`
class.  If it is not, it is ignored.

        nodeEditHappened: ( action ) ->
            if action not instanceof DOMEditAction then return
            if @stackPointer < @stack.length
                @stack = @stack[...@stackPointer]
            @stack.push action
            @stackPointer = @stack.length

We add `canUndo` and `canRedo` methods to the class that just
report whether the stack pointer isn't at the top or bottom of the
stack.

        canUndo: -> @stackPointer > 0
        canRedo: -> @stackPointer < @stack.length

We add methods that can describe the atcions that would take place
if undo or redo were invoked, returning the empty string if one
cannot undo/redo.

        undoDescription: ->
            return if @stackPointer is 0 then '' else
                "Undo #{@stack[@stackPointer - 1].toString()}"
        redoDescription: ->
            return if @stackPointer is @stack.length then '' else
                "Redo #{@stack[@stackPointer].toString()}"

We add `undo` and `redo` methods that move the stack pointer after
calling the `undo` and `redo` methods in the appropriate actions on
the stack.

        undo: ->
            if @stackPointer > 0
                @stack[@stackPointer - 1].undo()
                @stackPointer--
        redo: ->
            if @stackPointer < @stack.length
                @stack[@stackPointer].redo()
                @stackPointer++

