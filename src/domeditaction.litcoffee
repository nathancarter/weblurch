
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

            @node = node.address @tracker?.getElement()

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
                { @name } = data[0]
                @value = node.getAttribute @name

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

## Non-actions

It is possible to create edit actions that do not actually change
the document in any way.  For instance, a normalize action might
be called when there are not any adjacent text nodes, so it does
nothing.  Or a replaceChild action might be performed, replacing
an existing child with one that is indistinguishable from it.

We wish to be able to detect when an edit action is really a
non-action, for a few reasons.
 * Let's not push onto the undo/redo stack actions that will do
   nothing if the user undoes/redoes them.  This would be confusing
   to the user.
 * Let's not notify listeners of null changes, because whatever
   processing the listeners would do upon changes would then be
   wasted effort, since the document has not really changed.

Thus the following member function of the `DOMEditAction` class
returns whether or not the action is null.

        isNullAction: ->

Appending, inserting, or remvoing a child always changes the
document.  (If the attempt had been to append or insert something
invalid, or remove something invalid, this object would not have
completed its constructor.  The fact that it did means that the
addition or removal is a valid action.)

            if @type is 'appendChild' or @type is 'insertBefore' or
               @type is 'removeChild'
                return no

Removing an attribute is null if and only if the node did not have
the attribute, in which case `@value` will be null.

            if @type is 'removeAttribute' or
               @type is 'removeAttributeNode'
                console.log 'old attribute is', @name, @value
                return @value is null

Normalize is a null action iff the constructor did not find any
sequences of adjacent text nodes anywhere in the node to be
normalized.

            else if @type is 'normalize'
                return JSON.equals @sequences, {}

Replacing a child with another is an actual modification iff the
"before" child is distinguishable from the "after" child.

            else if @type is 'replaceChild'
                return JSON.equals @oldChild, @newChild

Setting an attribute is an actual modification iff the new value
is a different string than the old value.

            else if @type is 'setAttribute' or
                    @type is 'setAttributeNode'
                return @oldValue is @newValue

A compound action is a null action iff all its elements are.
Although we could make it null iff the combined sequence of actions
is guaranteed to yield the same document as before, but that is
both less useful and harder to compute.

            else if @type is 'compound'
                for subaction in @subactions
                    if not subaction.isNullAction() then return no
                return yes

And those are all the types we know.

            else throw Error 'Invalid DOMEditAction type: ' + @type

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
way.  If there is no tracker, this will fail.

            if not @tracker
                throw Error \
                    'Cannot redo action with no DOMEditTracker'
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

As above, compute the original "`this`" node.  If there is no
tracker, this will fail.

            if not @tracker
                throw Error \
                    'Cannot undo action with no DOMEditTracker'
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

