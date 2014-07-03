
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
            if @type is 'appendChild'
                text = Node.fromJSON( @toAppend ).textContent
                if text.length > 50 then text = text[..50] + '...'
                if text.length is 0 then text = 'a node'
                "Add #{text}"
            else if @type is 'insertBefore'
                text = Node.fromJSON( @toInsert ).textContent
                if text.length > 50 then text = text[..50] + '...'
                if text.length is 0 then text = 'a node'
                "Insert #{text}"
            else if @type is 'normalize'
                "Normalize text"
            else if @type is 'removeAttribute' or
                    @type is 'removeAttributeNode'
                "Remove #{@name} attribute"
            else if @type is 'removeChild'
                text = Node.fromJSON( @child ).textContent
                if text.length > 50 then text = text[..50] + '...'
                if text.length is 0 then text = 'a node'
                "Remove #{text}"
            else if @type is 'replaceChild'
                orig = Node.fromJSON( @oldChild ).textContent
                if orig.length > 50 then orig = orig[..50] + '...'
                if orig.length is 0 then orig = 'a node'
                repl = Node.fromJSON( @newChild ).textContent
                if repl.length > 50 then repl = repl[..50] + '...'
                if repl.length is 0 then repl = 'a node'
                "Replace #{orig} with #{repl}"
            else if @type is 'setAttribute' or
                    @type is 'setAttributeNode'
                "Change #{@name} from #{@oldValue} to #{@newValue}"
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

