
# DOM Edit Tracker class

A `DOMEditTracker` is responsible for watching the edits to the
DOM within a single HTML DIV element, and thus it takes one at
construction time.

## Constructor

    window.DOMEditTracker = class DOMEditTracker
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

