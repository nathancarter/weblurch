
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
   * joins adjacent text nodes
   * event contains `N`'s address together with a map from indices
     to text content of all current child text nodes of `N`
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
   * e.g.:
     `var atr=document.createAttribute("class");
     atr.nodeValue="democlass";
     myDiv.setAttributeNode(atr);`
   * event contains `N`'s address, the name and value of the
     attribute after setting, as well as the original value of the
     attribute beforehand
 * Note that `element.dataset.foo` is not supported.

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


        constructor: ( type, node, data... ) ->

The `node` parameter must actually be a DOM Node, or this
constructor cannot function.

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

For type "normalize", we store a map from indices to text content
for all current child text nodes of `node`, in `@textChildren`,
thus making this edit action invertible later if necessary.

            else if type is 'normalize'
                if data.length isnt 0
                    throw Error 'Wrong # of parameters: ' + data
                @textChildren = {}
                for child, i in node.childNodes
                    if child instanceof Text
                        @textChildren[i] = child.textContent

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
                "Change #{@name} from #{@oldValue} to #{@newValue}"

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
then stringifies it.

This function is indirectly tested in that many other unit tests
depend upon it to test other functionality.

        toJSON: ->
            JSON.stringify { @type, @node, @toAppend, @toInsert,
                @insertBefore, @textChildren, @name, @value,
                @child, @childIndex, @oldChild, @newChild,
                @oldValue, @newValue }

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

            original = @tracker.index @node

Now we consider each possible action type separately, in a big
`if`-`else` clause, as in the `toString` method, above.

In the case of "appendChild", we simply unserialize the stored
child and append it.

            if @type is 'appendChild'
                original.appendChild Node.fromJSON @toAppend

In the case of "insertBefore", we simply unserialize the stored
child and either insert or append it, depending on the index.

            else if @type is 'insertBefore'
                newnode = Node.fromJSON @toAppend
                if @insertBefore is original.childNodes.length
                    original.appendChild newnode
                else
                    original.insertBefore \
                        original.childNodes[@insertBefore], newnode

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

Next, we consider the backward case.  I provide fewer comments in
the code below, because it is simply the inverse of the routine
just built above, which is liberally commented.  Refer to the
routine above for more detailed explanations of each part below.

        undo: ->

As above, compute the original "`this`" node.

            original = @tracker.index @node

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

We walk through the list of child nodes, and upon encountering any
text node, we check to see if there were two or more adjacent text
nodes corresponding to it originally.  If so, we break it up.

This requires keeping two separate counters, one to walk through
each set of child indices--those before and those after the
normalization--and keeping them in sync.

            else if @type is 'normalize'
                normIdx = otherIdx = 0
                while normIdx < original.childNodes.length
                    child = original.childNodes[normIdx]

If this is not a text node, we need not process it here; just move
on, incrementing both indices in concert.

                    if child not instanceof Text
                        normIdx++
                        otherIdx++
                        continue

So it is a text node.  But if it was not collapsed by the
normalization process, we need to make no changes.  So do the same
increment-and-skip process.

                    if otherIdx + 1 not of @textChildren
                        normIdx++
                        otherIdx++
                        continue

So now we know:  There was a sequence of two or more text nodes
that got collapsed into just one.  We must expand back to the old
form.  We begin by replacing the normalized text chunk with just
the first piece of its broken-up version.

                    text = @textChildren[otherIdx++]
                    text = document.createTextNode text
                    original.replaceChild text,
                        original.childNodes[normIdx++]

Then we prepare to insert all the other pieces after the first,  by
finding a place to do the insertion, or null if we'll be appending.

                    insertBefore = original.childNodes[normIdx] or
                        null

Then as long as there are more text nodes in the sequence, we keep
inserting them.

                    while otherIdx of @textChildren
                        text = @textChildren[otherIdx++]
                        text = document.createTextNode text
                        if insertBefore
                            original.insertBefore text,
                                insertBefore
                        else
                            original.appendChild text

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
                    original.appendChild addback
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

