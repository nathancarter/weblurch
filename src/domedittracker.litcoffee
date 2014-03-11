
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

## Getters

Although in CoffeeScript, no members are truly private, the
intent is that the fields of an object should not be directly
accessed from outside the class except through getters and
setters.

So far there is only one, for querying the element passed at
construction time, over which this object has taken "ownership."

        getElement: -> @element

