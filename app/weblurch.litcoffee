
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

    Node.prototype.address = ( ancestor = null ) ->

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
        recur.concat [ Array.prototype.slice.apply(
            @parentNode.childNodes ).indexOf this ]

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

    Node.prototype.index = ( address ) ->

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

    Node.prototype.toJSON = ( verbose = yes ) ->

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




# `LurchEditor` class

A Lurch Editor is an HTML DIV (that has *not* been marked as
`content-editable` in the browser) but that will be made editable
by the user through the functionality of this class.

    window.LurchEditor = class LurchEditor

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

        constructor: ( div ) ->
            @element = null
            if div and div?.tagName isnt 'DIV'
                throw new Error '''LurchEditor can only be
                    constructed in a DIV node'''

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

Now that all of that has succeeded, store the div we just processed
in a member variable so it can be queried later, in
`editorElement`.

            @element = div

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

## Getters

So far there is only one, for querying the element passed at
construction time, over which this object has taken "ownership."
(Although in JavaScript/CoffeeScript, no members are truly private,
the intent is that the fields of an object should not be directly
accessed from outside the class except through getters and
setters.)

        getElement: -> @element

With that getter, however, I classify two convenience methods it
enables.  DOM Nodes have the methods `address` and `index`
implemented in them; see [the documentation on those functions](
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
inherited from the address and index
functions defined in the Node prototype.

