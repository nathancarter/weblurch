
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
`DOMEditAction` instances to be empty.

            @stack = []

And add this newly created instance to the list of all instances.

            DOMEditTracker.instances.push this

## Getters

Although in CoffeeScript, no members are truly private, the
intent is that the fields of an object should not be directly
accessed from outside the class except through getters and
setters.

So far there is only one, for querying the element passed at
construction time, over which this object has taken "ownership."

        getElement: -> @element

## Events

When any editing takes place inside the DOM tree watched by an
instance of this class, then the instance will want to be notified
of it.  We therefore provide this method by which it can be
notified.

The one parameter should be an instance of the `DOMEditAction`
class.  If it is not, it is ignored.

        nodeEditHappened: ( action ) ->
            if action instanceof DOMEditAction
                @stack.push action

