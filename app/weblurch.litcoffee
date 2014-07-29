
# DOM Edit Action

This class will embody a single, atomic edit to a DOM tree.  This
includes all the kinds of edit performable with the usual Node
API, including inserting, removing, and replacing children,
setting and removing attributes, and normalizing nodes.

An instance will store all the data needed to undo or redo the
action it represents, so that a stack of such instances can form
the undo/redo stack for an application.

The protocol for what data to store in each case is described here.
 * `N.appendChild(node)`
   * returns `node`
   * event contains `N`'s address and the serialized node
 * `N.insertBefore(node,beforeThisChild)`
   * returns `node`
   * if `beforeThisChild` is omitted, it's the same as append
   * event contains `N`'s address, the serialized node, and the
     index of `beforeThisChild` (or child node length if absent)
 * `N.normalize()`
   * no return value
   * removes empty text nodes
   * joins adjacent text nodes, recursively
   * event contains `N`'s address together with a map from
     addresses within a normalized `N` to the sequences of text
     nodes that went together to form the normalized ones, i.e.,
     address `A` is mapped to the array of 2 or more strings that
     combined to form the text node at the new `N.index A`.
     `A` is stored as a JSON string, so `[0,1]` becomes `"[0,1]"`.
 * `N.removeAttribute(name)`
   * no return value
   * event contains `N`'s address, `name`, and original attribute
     `value`
 * `N.removeAttributeNode(attrNode)`
   * returns `attrNode`
   * e.g.: `N.removeAttributeNode(N.getAttributeNode('style'))`
   * event contains `N`'s address and original attribute `name` and
     `value`
 * `N.removeChild(childNode)`
   * returns `childNode`
   * event contains `N`'s address, the child's original index
     within `N`, and a serialization of the child
 * `N.replaceChild(newnode,oldnode)`
   * returns `oldnode`, I think
   * event contains `N`'s address, the child's original index
     within `N`, and serializations of both `oldnode` and `newnode`
 * `N.setAttribute(name,value)`
   * no return value
   * both strings
   * event contains `N`'s address, `name`, and `value`, as well as
     the original value of the attribute beforehand
 * `N.setAttributeNode(attrNode)`
   * returns replaced node if any, otherwise null
   * E.g.: <br>
     `atr = document.createAttribute 'class'` <br>
     `atr.nodeValue = 'democlass'` <br>
     `myDiv.setAttributeNode atr`
   * event contains `N`'s address, the name and value of the
     attribute after setting, as well as the original value of the
     attribute beforehand
 * Note that `element.dataset.foo` is not supported.
 * There is also a compound action that does not correspond to any
   of the `Node` member functions listed above, but rather that
   serves to aggregate a sequence of such editing actions into one.
   It stores only the array of atomic edit actions that comprise
   it.

Now begins the code for the class.

    window.DOMEditAction = class DOMEditAction

## Constructor

The constructor requires that the data given be of the appropriate
form for one of the nine acceptable ways to instantiate this class.
They are these:
 * type "appendChild", with data the parent node and child to
   append
 * type "insertBefore", with data the parent node, the child to
   insert, and the child before which to insert it, which may be
   omitted to mean the same thing as append
 * type "normalize", with data the parent node
 * type "removeAttribute", with data the node from which to remove
   the attribute, and name of the attribute to remove
 * type "removeAttributeNode", with data the node from which to
   remove the attribute, and the attribute node to remove
 * type "removeChild", with data the parent node and the child to
   remove
 * type "replaceChild", with data the parent node, the new node to
   replace the child with, and then the child to replace
 * type "setAttribute", with data the node whose attribute should
   be set, the name of the attribute to set, and the value to which
   it should be set
 * type "setAttributeNode", with data the node whose attribute
   should be set and the new attribute node to set on it
 * type "compound", with data the array of atomic actions that
   comprise the compound action; the `node` member for a compound
   action is the common ancestor of the atomic actions inside it

We write the signature for the constructor with parameter names
that expect the construction of an atomic action type, since that
will be the most common occurrence.  But we handle the special case
of the compound type immediately.

        constructor: ( type, node, data... ) ->

If this is the compound case, then the user will call `new
DOMEditAction 'compound', arrayOfActions` or `new DOMEditAction
'compound', action1, ..., actionN`.  We handle either of those
cases here, because they do not involve passing a node parameter.

            if type is 'compound'
                @type = type

First, unite the array case and the many-parameters case into one
by forming an `actionList` array.

                if not node?
                    @subactions = []
                else if node instanceof Array
                    @subactions = node
                else
                    @subactions = [ node ].concat data

Now verify that its elements are all actions.

                for action in @subactions
                    if action not instanceof DOMEditAction
                        throw Error """Compound action array
                            containd a non-action: #{action}"""

Find the common ancestor for all their addresses.

                if @subactions.length is 0
                    @node = []
                    @tracker = null
                else
                    @node = @subactions[0].node
                    @tracker = @subactions[0].tracker
                    for action in @subactions[1..]
                        end = action.length
                        end = @node.length if end > @node.length
                        for i in [1...end]
                            if @node[i] isnt action[i]
                                @node = @node[...i]
                                break

Return this instance, so that the constructor terminates now; this
is the end of the compound case.

                @description = 'Document edit'
                return this

Now that the compound case is taken care of, we can return to all
the other atomic cases, in which the `node` parameter must actually
be a DOM Node; otherwise, this constructor cannot function.

            if node not instanceof Node
                throw Error 'This is not a node: ' + node

The `DOMEditTracker` instance in which all of this will operate is
stored in the member `@tracker`.  If there is no such tracker, that
member will be null.

            @tracker = DOMEditTracker.instanceOver node

Also remember the type of action.

            @type = type

The node itself is stored in `@node` as the address within the
given edit tracker, or within its topmost ancestor if there is no
tracker.  (But this class is not very useful if there is no edit
tracker; we avoid throwing an error mainly for the convenience of
the caller.)

            @node = node.address @tracker.getElement()

For type "appendChild", the node to append is stored serialized,
in `@toAppend`.

            if type is 'appendChild'
                if data.length isnt 1
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Node
                    throw Error 'Invalid parameter: ' + data
                @toAppend = data[0].toJSON()

For type "insertBefore", the node to insert is stored serialized,
in `@toInsert`, and the node before which to insert it is stored as
its index, or the previous number of children if this parameter was
omitted, in `@insertBefore`.

            else if type is 'insertBefore'
                if data.length isnt 1 and data.length isnt 2
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Node
                    throw Error 'Invalid parameter: ' + data[0]
                @toInsert = data[0].toJSON()
                if data.length is 2
                    if data[1] not instanceof Node
                        throw Error 'Invalid parameter: ' + data[0]
                    if data[1].parentNode isnt node
                        throw Error 'Invalid child: ' + data[0]
                    @insertBefore = data[1].indexInParent()
                else
                    @insertBefore = node.childNodes.length

For type "normalize", we store a map from addresses in the
normalized version (which isn't even yet computed) to sequences of
strings that will be amalgamated to appear at those addresses.
We store it in `@sequences`, thus making this edit action
invertible later if necessary.

            else if type is 'normalize'
                if data.length isnt 0
                    throw Error 'Wrong # of parameters: ' + data
                @sequences = {}

We create a function that recursively processes the DOM tree from
any node `N` downward, then call it on our `node`.  The variable
`index` in the following code walks one step at a time, even when
`child` jumps many sequential text nodes at once, so that we build
addresses that the text nodes will have after normalization.

                that = this
                process = ( N, address = [] ) =>
                    child = N.childNodes[0]
                    index = 0
                    while child

If we've found a sequence of two or more adjacent text nodes, build
an array of them and record it in the `sequences` field.

                        nextAddr = address.concat [ index ]
                        if child instanceof Text and
                           child.nextSibling instanceof Text
                            strings = []
                            while child instanceof Text
                                strings.push child.textContent
                                child = child.nextSibling
                            key = JSON.stringify nextAddr
                            @sequences[key] = strings

Otherwise, just move on to the next child.

                        else
                            process child, nextAddr
                            child = child.nextSibling

In either case, advance `index` by just one step.

                        index++
                process node

For type "removeAttribute", we store the name of the attribute
in `@name`, together with its original value in `@value`.

            else if type is 'removeAttribute'
                if data.length isnt 1
                    throw Error 'Wrong # of parameters: ' + data
                @name = data[0] + ''
                @value = node.getAttribute @name

For type "removeAttributeNode", we store the same data as in the
previous type, under the same names.

            else if type is 'removeAttributeNode'
                if data.length isnt 1
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Attr
                    throw Error 'Invalid attribute node: ' +
                                data[0]
                { @name, @value } = data[0]

For type "removeChild", we store the child's original index within
`@node` as `@childIndex`, and a serialization of the child, as
`@child`.

            else if type is 'removeChild'
                if data.length isnt 1
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Node
                    throw Error 'Invalid parameter: ' + data[0]
                if data[0].parentNode isnt node
                    throw Error 'Invalid child: ' + data[0]
                @childIndex = data[0].indexInParent()
                @child = data[0].toJSON()

For type "replaceChild", we store the child's original index within
`@node` as `@childIndex`, a serialization of the child, as
`@oldChild`, and a serialization of the replacement, as
`@newChild`.

            else if type is 'replaceChild'
                if data.length isnt 2
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Node
                    throw Error 'Invalid parameter: ' + data[0]
                if data[1] not instanceof Node
                    throw Error 'Invalid parameter: ' + data[1]
                if data[1].parentNode isnt node
                    throw Error 'Invalid child: ' + data[1]
                @childIndex = data[1].indexInParent()
                @oldChild = data[1].toJSON()
                @newChild = data[0].toJSON()

For type "setAttribute", we store the name and value to which the
attribute will be set, in `@name` and `@newValue`, respectively, as
well as the attribute's original value, in `@oldValue`.  If the
old value is null, we store the empty string instead, so that
JSON serialization is possible.

            else if type is 'setAttribute'
                if data.length isnt 2
                    throw Error 'Wrong # of parameters: ' + data
                @name = data[0] + ''
                @newValue = data[1] + ''
                @oldValue = ( node.getAttribute @name ) or ''

For type "setAttributeNode", we store the same data as in the
previous case, and under the same names.

            else if type is 'setAttributeNode'
                if data.length isnt 1
                    throw Error 'Wrong # of parameters: ' + data
                if data[0] not instanceof Attr
                    throw Error 'Invalid parameter: ' + data[0]
                @name = data[0].name
                @newValue = data[0].value
                @oldValue = ( node.getAttribute @name ) or ''

If none of the above types were what the caller was trying to
construct, throw an error, because they're the only types
supported.

            else throw Error 'Invalid DOMEditAction type: ' + type

## Description

Instance of the class need to be able to provide descriptions of
themselves, for use on undo/redo stacks.  We provide this
functionality with a `toString` method.

        toString: ->

We simply check each of the nine valid action types, and create a
sensible string representation for each.  Sections of quoted text
are capped at 50 characters, but that can easily be changed here:

            max = 50

I do not document each of the individual parts of the following
simple `if`-`else` code, but suffice it to say that the forms of
the output are on the following list.
 * Add [text appended]
 * Insert [text inserted]
 * Normalize text
 * Remove [name] attribute
 * Remove [text removed]
 * Replace [text] with [text]
 * Change [attribute name] from [old value] to [new value]
For compound actions, the output will be the vague phrase
"Document edit" unless it has been changed by calling
`action.description = 'Other content here'`.

            if @type is 'appendChild'
                text = Node.fromJSON( @toAppend ).textContent
                if text.length > max then text = text[..max]+'...'
                if text.length is 0 then text = 'a node'
                "Add #{text}"
            else if @type is 'insertBefore'
                text = Node.fromJSON( @toInsert ).textContent
                if text.length > max then text = text[..max]+'...'
                if text.length is 0 then text = 'a node'
                "Insert #{text}"
            else if @type is 'normalize'
                "Normalize text"
            else if @type is 'removeAttribute' or
                    @type is 'removeAttributeNode'
                "Remove #{@name} attribute"
            else if @type is 'removeChild'
                text = Node.fromJSON( @child ).textContent
                if text.length > max then text = text[..max]+'...'
                if text.length is 0 then text = 'a node'
                "Remove #{text}"
            else if @type is 'replaceChild'
                orig = Node.fromJSON( @oldChild ).textContent
                if orig.length > max then orig = orig[..max]+'...'
                if orig.length is 0 then orig = 'a node'
                repl = Node.fromJSON( @newChild ).textContent
                if repl.length > max then repl = repl[..max]+'...'
                if repl.length is 0 then repl = 'a node'
                "Replace #{orig} with #{repl}"
            else if @type is 'setAttribute' or
                    @type is 'setAttributeNode'
                oldv = @oldValue or 'empty'
                newv = @newValue or 'empty'
                "Change #{@name} from #{oldv} to #{newv}"
            else if @type is 'compound'
                @description

An error message is returned as a string if none of the nine valid
action types is stored in this object (i.e., the object is
corrupt).

            else
                "Error, unknown edit action type: #{@type}"

## Serialization

The class also provides a serialization method, mostly for use in
unit testing, because instances of the object can then be sent in
and out of a headless browser as JSON.  This implementation just
copies into an object all possibly-relevant fields of the object,
ready for later JSON stringification, should that be useful.

This function is indirectly tested in that many other unit tests
depend upon it to test other functionality.

        toJSON: -> {
            @type, @node, @toAppend, @toInsert, @insertBefore,
            @sequences, @name, @value, @child, @childIndex,
            @oldChild, @newChild, @oldValue, @newValue,
            @description, @subactions
        }

## Undo/redo

Edit actions, because they are actions, will sit on an undo/redo
stack, and thus must be able to be applied, either forwards or
backwards.  The following two methods support this need.

Each method assumes that it is being called at a time that makes
sense.  E.g., an undo is being performed right after the action
was performed, or with the `DOMEditTracker` element in a state
equivalent to such a time.  And a redo should only be performed if
the action was just undone, or an equivalent state (such as doing
one further undo, then redoing that action).

Furthermore, these methods make changes to the DOM, and thus will
generate more `DOMEditAction` events, which will propagate to the
`DOMEditTracker` stored in this object's `tracker` field.  Thus it
is the business of the tracker, before asking one of the actions on
its undo/redo stack to perform an undo/redo, to temporarily pause
its own recording of such actions.  This will prevent corruption of
the undo/redo stack in question.

First, we consider the forward case.  It could be named simply
`do` but the action is almost never created in order to be applied;
rather, it is created as an event that records an action that was
done via the ordinary DOM API, and can thus be undone/redone later.
Hence, we call this `redo` since it is almost always called for
that purpose.  Also, it gives a nice symmetry with `undo`.

        redo: ->

In every case, we need to know what object was "`this`" when the
event was created.  Its address within the containing
`DOMEditTracker` is stored in our `node` field, so we find it that
way.

            original = @tracker.getElement().index @node

Now we consider each possible action type separately, in a big
`if`-`else` clause, as in the `toString` method, above.

In the case of "appendChild", we simply unserialize the stored
child and append it.

            if @type is 'appendChild'
                original.appendChild Node.fromJSON @toAppend

In the case of "insertBefore", we simply unserialize the stored
child and either insert or append it, depending on the index.

            else if @type is 'insertBefore'
                newnode = Node.fromJSON @toInsert
                if @insertBefore is original.childNodes.length
                    original.appendChild newnode
                else
                    original.insertBefore newnode,
                        original.childNodes[@insertBefore]

Normalization is simple because it takes no parameters.

            else if @type is 'normalize'
                original.normalize()

Removing an attribute is also straightforward, because the only
parameter we need is the attribute name, stored in our `name`
field.

I handle both the attribute and attribute-node cases in the same
manner, because we are only concerned here with final results, not
with the specific events generated along the way.

            else if @type is 'removeAttribute' or
                    @type is 'removeAttributeNode'
                original.removeAttribute @name

Removing a child is straightforward because we have the only
parameter we need, its index, stored in our `childIndex` field.

            else if @type is 'removeChild'
                original.removeChild \
                    original.childNodes[@childIndex]

Replacing a child requires first unserializing the replacement from
our `newChild` field, then calling doing the replacement using the
usual DOM API.

            else if @type is 'replaceChild'
                replacement = Node.fromJSON @newChild
                original.replaceChild replacement,
                    original.childNodes[@childIndex]

Changing an attribute is easy, because the key-value pair is stored
in this object under the `name` and `newValue` fields.

I handle both the attribute and attribute-node cases in the same
manner, because we are only concerned here with final results, not
with the specific events generated along the way.

            else if @type is 'setAttribute' or
                    @type is 'setAttributeNode'
                original.setAttribute @name, @newValue

If it's a compound action, just run all the subactions in order.

            else if @type is 'compound'
                action.redo() for action in @subactions

Next, we consider the backward case.  I provide fewer comments in
the code below, because it is simply the inverse of the routine
just built above, which is liberally commented.  Refer to the
routine above for more detailed explanations of each part below.

        undo: ->

As above, compute the original "`this`" node.

            original = @tracker.getElement().index @node

The inverse of "appendChild" is to remove the last child.

            if @type is 'appendChild'
                original.removeChild original.childNodes[ \
                    original.childNodes.length - 1]

The inverse of "insertBefore" is to remove the inserted child node.
The insertion index stored in `insertBefore` is the index of the
child to remove.

            else if @type is 'insertBefore'
                original.removeChild \
                    original.childNodes[@insertBefore]

The inverse of normalization is to break up any text fragments that
were adjacent before the normalization, but which got united
because of it.

For each key in the sequences object, we use it as an address to
look up the descendant of `original` that resulted from
amalgamating the sequence into one text node.  After all these
lookups, we then take each and break them up using the `splitText`
method of the `Text` prototype.

            else if @type is 'normalize'

First look up all the descendants in advance, before expanding any,
so that all addresses are valid throughout this process.

                descendants = {}
                for own key of @sequences
                    descendants[key] = \
                        original.index JSON.parse key

Next split each such descendant into pieces, based on the lengths
of the strings stored in the `sequences` object.

                for own key of @sequences
                    d = descendants[key]
                    for string in @sequences[key]
                        if string.length < d.textContent.length
                            d.splitText string.length
                            d = d.nextSibling

The inverse of removing an attribute to put it back in, with both
the key and value we recorded for this purpose, before its removal.

I handle both the attribute and attribute-node cases in the same
manner, because we are only concerned here with final results, not
with the specific events generated along the way.

            else if @type is 'removeAttribute' or
                    @type is 'removeAttributeNode'
                original.setAttribute @name, @value

The inverse of removing a child is to add the child back in, which
we can do because we stored a serialized version of the child in
this object.  We take care to differentiate the cases of insertion
vs. appending.

            else if @type is 'removeChild'
                addBack = Node.fromJSON @child
                if @childIndex is original.childNodes.length
                    original.appendChild addBack
                else
                    original.insertBefore addBack,
                        original.childNodes[@childIndex]

The inverse of replacing a child is actually still replacing a
child, just with the old and new reversed.

            else if @type is 'replaceChild'
                replacement = Node.fromJSON @oldChild
                original.replaceChild replacement,
                    original.childNodes[@childIndex]

The inverse of changing an attribute is to change it back to its
former value, if it had one, but if it did not, then remove the
attribute entirely.

I handle both the attribute and attribute-node cases in the same
manner, because we are only concerned here with final results, not
with the specific events generated along the way.

            else if @type is 'setAttribute' or
                    @type is 'setAttributeNode'
                if @oldValue isnt ''
                    original.setAttribute @name, @oldValue
                else
                    original.removeAttribute @name

If it's a compound action, undo all the subactions, in reverse
order from how they were originally performed.  (Note that the code
below copies the array before reversing it, because the reverse
happens in-place, impacting the array itself.)

            else if @type is 'compound'
                for action in @subactions[..].reverse()
                    action.undo()




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




# Utility functions for working with the DOM

## Address

The address of a node `N` in an ancestor node `M` is an array `a`
of non-negative integer indices such that
`M.childNodes[a[0]].childNodes[a[1]]. ...
.childNodes[a[a.length-1]] == N`.  Think of it as the path one must
walk through children to get from `M` down to `N`.  Special cases:
 * If the array is of length 1, then `M == N.parentNode`.
 * If the array is empty, `[]`, then `M == N`.
 * If `M` is not an ancestor of `N`, then we say the address of `N`
   within `M` is null (not an array at all).

The following member function of the `Node` class adds the address
function to that class.  Using the `M` and `N` from above, one
would call it like `N.address M`.  [See below](#index) for its
inverse function, `index`.

It computes the address of any one DOM node within any other.
If the parameter (the ancestor, called `M` above) is not supplied,
then it defaults to the top-level Node above `N`
(i.e., the furthest-up ancestor, with no `.parentNode`,
which usually means it's the global variable `document`).

    Node::address = ( ancestor = null ) ->

The base case comes in two flavors.
First, if the parameter is this node, then the correct result is
the empty array.

        if this is ancestor then return []

Second, if we've reached the top level then we must consider the
second parameter.  Were we restricted to a specific ancestor?  If
so, we didn't find it, so return null.  If not, return the empty
array, because we have reached the top level.

        if not @parentNode
            return if ancestor then null else []

Otherwise, recur up the ancestor tree, and concatenate our own
index in our parent with the array we compute there, if there is
one.

        recur = @parentNode.address ancestor
        if recur is null then return null
        recur.concat [ @indexInParent() ]

You'll notice that the final line of code above depends on the
as-yet-undefined helper function `indexInParent()`.  We therefore
create that simple helper function now, which is also a useful
member of the `Node` prototype.

    Node::indexInParent = ->
        if @parentNode
            Array::slice.apply(
                @parentNode.childNodes ).indexOf this
        else
            -1

## Index

This function is an inverse for `address`,
[defined above](#address).

The node at index `I` in node `N` is the descendant `M` of `N` in
the node hierarchy such that `M.address N` is `I`.
In short, if `N` is any ancestor of `M`, then
`N.index(M.address(N)) == M`.

Keeping in mind that an address is simply an array of nonnegative
integers, the implementation is simply repeated lookups in some
`childNodes` arrays.  It is therefore quite short, with most of
the code going to type safety.

    Node::index = ( address ) ->

Require that the parameter be an array.

        if address not instanceof Array
            throw Error 'Node address function requires an array'

If the array is empty, we've hit the base case of this recursion.

        if address.length is 0 then return this

Othwerise, recur on the child whose index is the first element of
the given address.  There are two safety checks here.  First, we
verify that the index we're about to look up is a number (otherwise
things like `[0]` will be treated as zero, which is probably
erroneous).  Second, the `?.` syntax below ensures that that index
is valid, so that we do not attempt to call this function
recursively on something other than a node.

        if typeof address[0] isnt 'number' then return undefined
        @childNodes[address[0]]?.index address[1..]

## Serialization

### From DOM Nodes to objects

These methods are for serializing and unserializing DOM nodes to
objects that are amenable to JSON processing.

First, the function for converting a DOM Node to an object that
can be serialized with `JSON.stringify`.  After this function is
defined, one can take any node `N` and call `N.toJSON()`.

    Node::toJSON = ( verbose = yes ) ->

The `verbose` parameter uses human-readable object keys, and is the
default.  A more compact version can be obtained by setting that
value to false.  The inverse function below can handle either
format.  The shrinking of keys follows the following convention.
 * tagName becomes t
 * attributes becomes a
 * children becomes c
 * comment becomes m
 * content becomes n

Text nodes are simply returned as strings.

        if this instanceof Text then return @textContent

Comment nodes are returned as objects with a comment flag and a
text content attribute.

        if this instanceof Comment
            return if verbose
                comment : yes, content : @textContent
            else
                m : yes, n : @textContent

All other types of nodes must be elements in order to be serialized
by this routine.

        if this not instanceof Element
            throw Error "Cannot serialize this node: #{this}"

A serialized Element is an object with up to three properties, tag
name, attribute dictionary, and child nodes array.  We create that
object, then add the attributes dictionary and children array if
and only if they are nonempty.

        result = tagName : @tagName
        if @attributes.length
            result.attributes = { }
            for attribute in @attributes
                result.attributes[attribute.name] = attribute.value
        if @childNodes.length
            result.children =
                chi.toJSON verbose for chi in @childNodes

If verbosity is disabled, change all the object keys to one-letter
abbreviations.

        if not verbose
            result.t = result.tagName ; delete result.tagName
            result.a = result.attributes ; delete result.attributes
            result.c = result.children ; delete result.children
        result

### From objects to DOM Nodes

Next, the function for converting an object produced with
`N.toJSON()` back into an actual DOM Node.  This function requires
its one parameter to be one of two types, either a string (meaning
that a text node should be returned) or an object with the three
properties given above (tagName, attributes, children, meaning that
an Element should be returned).  One calls it by writing
`Node.toJSON object`.

    Node.fromJSON = ( json ) ->

Handle the easy case first:  strings yield text nodes.

        if typeof json is 'string'
            return document.createTextNode json

Next, if we can find a comment flag in the object, then we create
and return a comment.

        if 'comment' of json and json.comment
            return document.createComment json.content
        if 'm' of json and json.m
            return document.createComment json.n

The only other possibility is that the object encodes an Element.
So if we can't get a tag name from the object, we cannot proceed,
and thus the input was invalid.

        if not 'tagName' of json and not 't' of json
            throw Error "Object has no t[agName]: #{this}"

Create an element using the tag name, add any attributes from the
given object, and recur on the child array if there is one.

        result = document.createElement json.tagName or json.t
        if attributes = json.attributes or json.a
            for own key, value of attributes
                result.setAttribute key, value
        if children = json.children or json.c
            for child in children
                result.appendChild Node.fromJSON child
        result

## Change events

Whenever a change is made to a DOM Node using one of the built-in
methods of the Node prototype, notifications of that change event
must be sent to any `DOMEditTracker` instance containing the
modified node.  To facilitate this, we modify those Node prototype
methods so that they not only do their original work, but also
send the notification events in question.  (Some of the methods in
question are in the Element prototype rather than the Node
prototype, so changes happen in both, actually.)

Each modified version has the same signature and return value as
before, but with the changes explained below.  The following code
just performs the modification to each of the methods listed in
the following string.

    '''
    appendChild insertBefore normalize removeAttribute
    removeAttributeNode removeChild replaceChild
    setAttribute setAttributeNode
    '''.split( /\s+/ ).map ( methodName ) ->

Compute whether the modificatio needs to take place in the Node
prototype or the Element prototype, and then store the original
value of the method for use from within our modified one.

        which = if Node::[methodName] then Node else Element
        original = which::[methodName]

Next, replace the original with our modified version.

        which::[methodName] = ( args... ) ->

If and only if a tracker exists over this node, we create an event
that we will later propagate to it.  We must create the event now,
so that if the creation of the event needs to record any data from
the unmodified state of this node (which is a common occurrence)
then it has the opportunity to do so.

            tracker = DOMEditTracker.instanceOver this
            if tracker
                event = new DOMEditAction methodName, this, args...

Then call the original version of this method.

            result = original.call this, args...

Now if a tracker was found earlier, and thus a method created to
send to that tracker, go ahead and send it now.

            if tracker
                tracker.nodeEditHappened event

Return the same return value that would have been returned from the
original method.

            result




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

