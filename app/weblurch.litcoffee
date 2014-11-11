
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

## Next and previous leaves

Although the DOM provides properties for the next and previous
siblings of any node, it does not provide a method for finding the
next or previous *leaf* nodes.  The following additions to the Node
prototype do just that.

One can call `N.nextLeaf()` to get the next leaf node in the
document strictly after `N` (regardless of whether `N` itself is a
leaf), or `N.nextLeaf M` to restrict the search to within the
ancestor node `M`.  `M` defaults to the entire document.  `M` must
be an ancestor of `N`, or this default is used.

    Node::nextLeaf = ( container = null ) ->

Walk up the DOM tree until we can find a previous sibling.  Do not
step outside the bounds of the document or `container`.

        walk = this
        while walk and walk isnt container and not walk.nextSibling
            walk = walk.parentNode

If no next sibling could be found, quit now, returning null.

        walk = walk?.nextSibling
        if not walk then return null

We have a next sibling, so return its first leaf node.

        while walk.childNodes.length > 0
            walk = walk.childNodes[0]
        walk

The following routine is analogous to the previous one, but in the
opposite direction (finding the previous leaf node, within the
given `container`, if such a leaf node exists).  Its code is not
documented because it is so similar to the previous routine, which
is documented.

    Node::previousLeaf = ( container = null ) ->
        walk = this
        while walk and walk isnt container and
          not walk.previousSibling
            walk = walk.parentNode
        walk = walk?.previousSibling
        if not walk then return null
        while walk.childNodes.length > 0
            walk = walk.childNodes[walk.childNodes.length - 1]
        walk

## More convenient `remove` method

Some browsers provide the `remove` method in the `Node` prototype,
but some do not.  To make things standard, I create the following
member in the `Node` prototype.  It guarantees that for any node
`N`, the call `N.remove()` has the same effect as the (more
verbose and opaque) call `N.parentNode.removeChild N`.

    Node::remove = -> @parentNode?.removeChild this

## Adding classes to and removing classes from elements

It is handy to have methods that add and remove CSS classes on
HTML element instances.

First, for checking if one is there:

    Element::hasClass = ( name ) ->
        classes = ( @getAttribute 'class' )?.split /\s+/
        classes and name in classes

Next, for adding a class to an element:

    Element::addClass = ( name ) ->
        classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
        if name not in classes then classes.push name
        @setAttribute 'class', classes.join ' '

Last, for removing one:

    Element::removeClass = ( name ) ->
        classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
        classes = ( c for c in classes when c isnt name )
        if classes.length > 0
            @setAttribute 'class', classes.join ' '
        else
            @removeAttribute 'class'



# Generic Utilities

This file provides functions useful across a wide variety of
situations.  Utilities specific to the DOM appear in
[the DOM utilities package](domutilities.litcoffee.html).  More
generic ones appear here.

## Equal JSON objects

By a "JSON object" I mean an object where the only information we
care about is that which would be preserved by `JSON.stringify`
(i.e., an object that can be serialized and deserialized with
JSON's `stringify` and `parse` without bringing any harm to our
data).

We wish to be able to compare such objects for semantic equality
(not actual equality of objects in memory, as `==` would do).  We
cannot simply do this by comparing the `JSON.stringify` of each,
because [documentation on JSON.stringify](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify)
says that we cannot rely on a consistent ordering of the object
keys.  Thus we implement the following comparison routine.

Note that this only works for objects that fit the requirements
above; if equality (in your situation) is affected by the prototype
chain, or if your object contains functions, or any other similar
difficulty, then this routine is not guaranteed to work for you.

It yields the same result as 
`JSON.stringify(x) is JSON.stringify(y)` would if `stringify`
always gave the same ordering of object keys.

    JSON.equals = ( x, y ) ->

If only one is an object, or only one is an array,
then they're not equal.
If neither is an object, you can use plain simple `is` to compare.

        if ( x instanceof Object ) isnt ( y instanceof Object )
            return no
        if ( x instanceof Array ) isnt ( y instanceof Array )
            return no
        if x not instanceof Object then return x is y

So now we know that both inputs are objects.

Get their keys in a consistent order.  If they aren't the same for
both objects, then the objects aren't equal.

        xkeys = ( Object.keys x ).sort()
        ykeys = ( Object.keys y ).sort()
        if ( JSON.stringify xkeys ) isnt ( JSON.stringify ykeys )
            return no

If there's any key on which the objects don't match, then they
aren't equal.  Otherwise, they are.

        for key in xkeys
            if not JSON.equals x[key], y[key] then return no
        yes

