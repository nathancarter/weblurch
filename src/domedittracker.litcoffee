
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

If they passed *something* as the `div` parameter, but it wasn't a
DIV, then throw an Error.

            if div and div?.tagName isnt 'DIV'
                throw new Error 'DOMEditTracker can only be ' +
                                'constructed in a DIV node'

Since the div was not an error, store it, or if they omitted it,
store null.

            @element = div or null

In either case, initialize the internal undo/redo stack of
`DOMEditAction` instances to be empty, with a stack pointer of
zero.  (Documentation on how this stack pointer behaves appears in
the [undo/redo stack section](#undo-redo-stack), below.)

            @stack = []
            @stackPointer = 0

Furthermore, we keep a boolean about whether we're supposed to add
actions to that stack or not as they occur.  By default it is
always on, but is disabled briefly when undo/redo actions take
place.

            @stackRecording = true

Sometimes actions recorded on the stack happen in a block, and
should form a compound action for placement on the stack.  As such
action sequences are coming in, they are stored in the following
temporary variable.  When it is null, no compound action is being
constructed, and the tracker should just push each individual edit
action onto the stack separately.  The "actions" variable will be
an array and the "name" variable a string naming it, during
recording of a compound action.

            @compoundActions = null
            @compoundName = null

Each instance will also have a list of listeners that should be
notified whenever changes take place in this instance's element.
We store those listeners as an array of callbacks, in this member.

            @listeners = []

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

        nodeEditHappened: ( action ) ->

The one parameter should be an instance of the `DOMEditAction`
class.  If it is not, it is ignored.

            if action not instanceof DOMEditAction then return

Even if we're not recording the actions on our internal undo/redo
stack, we must still notify any listeners of any changes that
happen.

            listener action for listener in @listeners

The only further actions this routine takes are recording the
action on the undo/redo stack, so now is when we should quit if
stack recording is turned off.

            if not @stackRecording then return

If this object is building a compound action, then append the
current action to that pending compound action, but do nothing
else.

            if @compoundActions isnt null
                @compoundActions.push action
                return

Truncate the stack if necessary, then push the value onto it.

            if @stackPointer < @stack.length
                @stack = @stack[...@stackPointer]
            @stack.push action

The stack pointer must always be after the last-performed action,
so we must update it here, having just recorded a newly-performed
action.

            @stackPointer = @stack.length

When actions are being recorded, the user can stipulate that a
sequence of successive actions form a logical unit, and thus should
be recorded as a compound action.  We provide the following two
methods for indicating the start and end of a compound action.

The user can flag the beginning of a sequence of actions using the
following routine.  It does nothing if another sequence is already
underway.

        startCompoundAction: ( name ) ->
            if @compoundActions isnt null then return
            @compoundActions = []
            @compoundName = name

The user later flags the end of the sequence of actions using the
following routine.  It does nothing if no sequence is underway.

        endCompoundAction: ->
            if @compoundActions is null then return

Create the new action and clear out the temporary variables.

            action = new DOMEditAction 'compound', @compoundActions
            if @compoundName then action.name = @compoundName
            @compoundActions = null
            @compoundName = null

Inform this object that the comound edit happened, so that it can
be recorded on the stack.

            @nodeEditHappened action

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
the stack.  Stack recording is disabled while they act, so that
they do not get doubly recorded.

Calling `undo` implicitly terminates any ongoing compound action
that may be being recorded.  If one *was* being recorded, then it
will be *that* new, compound action that gets undone.

        undo: ->
            @endCompoundAction()
            if @stackPointer > 0
                @stackRecording = false
                @stack[@stackPointer - 1].undo()
                @stackRecording = true
                @stackPointer--

If a compound action is being recorded, redo does nothing.

        redo: ->
            return if @compoundActions isnt null
            if @stackPointer < @stack.length
                @stackRecording = false
                @stack[@stackPointer].redo()
                @stackRecording = true
                @stackPointer++

## Listeners

Anyone interested in changes that take place in the document
monitored by this `DOMEditTracker` instance can add a callback
function to the instance's list, using the following method.

        listen: ( callback ) -> @listeners.push callback

Those callbacks are called every time a change takes place in the
DOM tree beneath the element tracked by this instance.  They are
passed one parameter, the
[`DOMEditAction`](domeditaction.litcoffee.html) instance
representing the change.  Its `.node` member will contain the
address where the change took place.

