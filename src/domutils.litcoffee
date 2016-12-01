
# Utility functions for working with the DOM

This file defines all of its functions inside one enormous `installIn`
function, which installs those methods into a particular `window` instance.
This is so that it can be used in an iframe in addition to the main window.
This file itself calls `installIn` on the main `window` instance, so you do
not need to.  But if you also wish to use these functions within an iframe,
you can call `installIn` on the `window` instance for that iframe.

    window.installDOMUtilitiesIn = ( window ) ->

## Address

The address of a node `N` in an ancestor node `M` is an array `a` of
non-negative integer indices such that
`M.childNodes[a[0]].childNodes[a[1]]. ... .childNodes[a[a.length-1]] == N`.
Think of it as the path one must walk through children to get from `M` down
to `N`.  Special cases:
 * If the array is of length 1, then `M == N.parentNode`.
 * If the array is empty, `[]`, then `M == N`.
 * If `M` is not an ancestor of `N`, then we say the address of `N`
   within `M` is null (not an array at all).

The following member function of the `Node` class adds the address function
to that class.  Using the `M` and `N` from above, one would call it like
`N.address M`.  [See below](#index) for its inverse function, `index`.

It computes the address of any one DOM node within any other. If the
parameter (the ancestor, called `M` above) is not supplied, then it defaults
to the top-level Node above `N` (i.e., the furthest-up ancestor, with no
`.parentNode`, which usually means it's the global variable `document`).

        window.Node::address = ( ancestor = null ) ->

The base case comes in two flavors. First, if the parameter is this node,
then the correct result is the empty array.

            if this is ancestor then return []

Second, if we've reached the top level then we must consider the second
parameter.  Were we restricted to a specific ancestor?  If so, we didn't
find it, so return null.  If not, return the empty array, because we have
reached the top level.

            if not @parentNode
                return if ancestor then null else []

Otherwise, recur up the ancestor tree, and concatenate our own index in our
parent with the array we compute there, if there is one.

            recur = @parentNode.address ancestor
            if recur is null then return null
            recur.concat [ @indexInParent() ]

You'll notice that the final line of code above depends on the
as-yet-undefined helper function `indexInParent()`.  We therefore create
that simple helper function now, which is also a useful member of the `Node`
prototype.

        window.Node::indexInParent = ->
            if @parentNode
                Array::slice.apply( @parentNode.childNodes ).indexOf this
            else
                -1

## Index

This function is an inverse for `address`, [defined above](#address).

The node at index `I` in node `N` is the descendant `M` of `N` in the node
hierarchy such that `M.address N` is `I`. In short, if `N` is any ancestor
of `M`, then `N.index(M.address(N)) == M`.

Keeping in mind that an address is simply an array of nonnegative integers,
the implementation is simply repeated lookups in some `childNodes` arrays.
It is therefore quite short, with most of the code going to type safety.

        window.Node::index = ( address ) ->

Require that the parameter be an array.

            if address not instanceof Array
                throw Error 'Node address function requires an array'

If the array is empty, we've hit the base case of this recursion.

            if address.length is 0 then return this

Othwerise, recur on the child whose index is the first element of the given
address.  There are two safety checks here.  First, we verify that the index
we're about to look up is a number (otherwise things like `[0]` will be
treated as zero, which is probably erroneous).  Second, the `?.` syntax
below ensures that that index is valid, so that we do not attempt to call
this function recursively on something other than a node.

            if typeof address[0] isnt 'number' then return undefined
            @childNodes[address[0]]?.index address[1..]

## Serialization

### From DOM Nodes to objects

These methods are for serializing and unserializing DOM nodes to objects
that are amenable to JSON processing.

First, the function for converting a DOM Node to an object that can be
serialized with `JSON.stringify`.  After this function is defined, one can
take any node `N` and call `N.toJSON()`.

        window.Node::toJSON = ( verbose = yes ) ->

The `verbose` parameter uses human-readable object keys, and is the default.
A more compact version can be obtained by setting that value to false.  The
inverse function below can handle either format.  The shrinking of keys
follows the following convention.
 * tagName becomes t
 * attributes becomes a
 * children becomes c
 * comment becomes m
 * content becomes n

Text nodes are simply returned as strings.

            if this instanceof window.Text then return @textContent

Comment nodes are returned as objects with a comment flag and a text content
attribute.

            if this instanceof window.Comment
                return if verbose
                    comment : yes, content : @textContent
                else
                    m : yes, n : @textContent

All other types of nodes must be elements in order to be serialized by this
routine.

            if this not instanceof window.Element
                throw Error "Cannot serialize this node: #{this}"

A serialized Element is an object with up to three properties, tag name,
attribute dictionary, and child nodes array.  We create that object, then
add the attributes dictionary and children array if and only if they are
nonempty.

            result = tagName : @tagName
            if @attributes.length
                result.attributes = { }
                for attribute in @attributes
                    result.attributes[attribute.name] = attribute.value
            if @childNodes.length
                result.children =
                    ( chi.toJSON verbose for chi in @childNodes )

If verbosity is disabled, change all the object keys to one-letter
abbreviations.

            if not verbose
                result.t = result.tagName ; delete result.tagName
                result.a = result.attributes ; delete result.attributes
                result.c = result.children ; delete result.children
            result

### From objects to DOM Nodes

Next, the function for converting an object produced with `N.toJSON()` back
into an actual DOM Node.  This function requires its one parameter to be one
of two types, either a string (meaning that a text node should be returned)
or an object with the three properties given above (tagName, attributes,
children, meaning that an Element should be returned).  One calls it by
writing `Node.toJSON object`.

        window.Node.fromJSON = ( json ) ->

Handle the easy case first:  strings yield text nodes.

            if typeof json is 'string'
                return window.document.createTextNode json

Next, if we can find a comment flag in the object, then we create and return
a comment.

            if 'comment' of json and json.comment
                return window.document.createComment json.content
            if 'm' of json and json.m
                return window.document.createComment json.n

The only other possibility is that the object encodes an Element. So if we
can't get a tag name from the object, we cannot proceed, and thus the input
was invalid.

            if not 'tagName' of json and not 't' of json
                throw Error "Object has no t[agName]: #{this}"

Create an element using the tag name, add any attributes from the given
object, and recur on the child array if there is one.

            result = window.document.createElement json.tagName or json.t
            if attributes = json.attributes or json.a
                for own key, value of attributes
                    result.setAttribute key, value
            if children = json.children or json.c
                for child in children
                    result.appendChild Node.fromJSON child
            result

## Next and previous leaves

Although the DOM provides properties for the next and previous siblings of
any node, it does not provide a method for finding the next or previous
*leaf* nodes.  The following additions to the Node prototype do just that.

One can call `N.nextLeaf()` to get the next leaf node in the document
strictly after `N` (regardless of whether `N` itself is a leaf), or
`N.nextLeaf M` to restrict the search to within the ancestor node `M`.  `M`
defaults to the entire document.  `M` must be an ancestor of `N`, or this
default is used.

        window.Node::nextLeaf = ( container = null ) ->

Walk up the DOM tree until we can find a previous sibling.  Do not step
outside the bounds of the document or `container`.

            walk = this
            while walk and walk isnt container and not walk.nextSibling
                walk = walk.parentNode

If no next sibling could be found, quit now, returning null.

            if walk is container then return null
            walk = walk?.nextSibling
            if not walk then return null

We have a next sibling, so return its first leaf node.

            while walk.childNodes.length > 0 then walk = walk.childNodes[0]
            walk

The following routine is analogous to the previous one, but in the opposite
direction (finding the previous leaf node, within the given `container`, if
such a leaf node exists).  Its code is not documented because it is so
similar to the previous routine, which is documented.

        window.Node::previousLeaf = ( container = null ) ->
            walk = this
            while walk and walk isnt container and not walk.previousSibling
                walk = walk.parentNode
            if walk is container then return null
            walk = walk?.previousSibling
            if not walk then return null
            while walk.childNodes.length > 0
                walk = walk.childNodes[walk.childNodes.length - 1]
            walk

Related to the previous two methods are two for finding the next and
previous nodes of type `Text`.

        window.Node::nextTextNode = ( container = null ) ->
            if ( walk = @nextLeaf container ) instanceof window.Text
                walk
            else
                walk?.nextTextNode container
        window.Node::previousTextNode = ( container = null ) ->
            if ( walk = @previousLeaf container ) instanceof window.Text
                walk
            else
                walk?.previousTextNode container

Related to the other methods above, we have the following two, which compute
the first or last leaf inside a given ancestor.

        window.Node::firstLeafInside = ->
            @childNodes?[0]?.firstLeafInside() or this
        window.Node::lastLeafInside = ->
            @childNodes?[@childNodes.length-1]?.lastLeafInside() or this

## More convenient `remove` method

Some browsers provide the `remove` method in the `Node` prototype, but some
do not.  To make things standard, I create the following member in the
`Node` prototype.  It guarantees that for any node `N`, the call
`N.remove()` has the same effect as the (more verbose and opaque) call
`N.parentNode.removeChild N`.

        window.Node::remove = -> @parentNode?.removeChild this

## Adding classes to and removing classes from elements

It is handy to have methods that add and remove CSS classes on HTML element
instances.

First, for checking if one is there:

        window.Element::hasClass = ( name ) ->
            classes = ( @getAttribute 'class' )?.split /\s+/
            classes and name in classes

Next, for adding a class to an element:

        window.Element::addClass = ( name ) ->
            classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
            if name not in classes then classes.push name
            @setAttribute 'class', classes.join ' '

Last, for removing one:

        window.Element::removeClass = ( name ) ->
            classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
            classes = ( c for c in classes when c isnt name )
            if classes.length > 0
                @setAttribute 'class', classes.join ' '
            else
                @removeAttribute 'class'

## Converting (x,y) coordinates to nodes

The browser will convert an (x,y) coordinate to an element, but not to a
text node within the element.  The following routine fills that gap.  Thanks
to [this StackOverflow answer](http://stackoverflow.com/a/13789789/670492).

        window.document.nodeFromPoint = ( x, y ) ->
            elt = window.document.elementFromPoint x, y
            for node in elt.childNodes
                if node instanceof window.Text
                    range = window.document.createRange()
                    range.selectNode node
                    for rect in range.getClientRects()
                        if rect.left < x < rect.right and \
                           rect.top < y < rect.bottom then return node
            return elt

## Order of DOM nodes

To check whether DOM node A appears strictly before DOM node B in the
document, use the following function.  Note that if node B is contained in
node A, this returns false.

        window.strictNodeOrder = ( A, B ) ->
            cmp = A.compareDocumentPosition B
            ( Node.DOCUMENT_POSITION_FOLLOWING & cmp ) and \
                not ( Node.DOCUMENT_POSITION_CONTAINED_BY & cmp )

To sort an array of document nodes, using a comparator that will return -1,
0, or 1, indicating whether nodes are in order, the same, or out of order
(respectively), use the following comparator function.

        window.strictNodeComparator = ( groupA, groupB ) ->
            if groupA is groupB then return 0
            if strictNodeOrder groupA, groupB then -1 else 1

## Extending ranges

An HTML `Range` object indicates a certain section of a document.  We add to
that class here the capability of extending a range to the left or to the
right by a given number of characters (when possible).  Here, `howMany` is
the number of characters, and if positive, it will extend the right end of
the range to the right; if negative, it will extend the left end of the
range to the left.

If the requested extension is not possible, a false value is returned, and
the object may or may not have been modified, and may or may not be useful.
If the requested extension is possible, a true value is returned, and the
object is guaranteed to have been correctly modified as requested.

        window.Range::extendByCharacters = ( howMany ) ->
            if howMany is 0
                return yes
            else if howMany > 0
                if @endContainer not instanceof window.Text
                    if @endOffset > 0
                        next = @endContainer.childNodes[@endOffset - 1]
                                .nextTextNode window.document.body
                    else
                        next = @endContainer.firstLeafInside()
                        if next not instanceof window.Text
                            next = next.nextTextNode window.document.body
                    if next then @setEnd next, 0 else return no
                distanceToEnd = @endContainer.length - @endOffset
                if howMany <= distanceToEnd
                    @setEnd @endContainer, @endOffset + howMany
                    return yes
                if next = @endContainer.nextTextNode window.document.body
                    @setEnd next, 0
                    return @extendByCharacters howMany - distanceToEnd
            else if howMany < 0
                if @startContainer not instanceof window.Text
                    if @startOffset > 0
                        prev = @startContainer.childNodes[@startOffset - 1]
                                .previousTextNode window.document.body
                    else
                        prev = @startContainer.lastLeafInside()
                        if prev not instanceof window.Text
                            prev =
                                prev.previousTextNode window.document.body
                    if prev then @setStart prev, 0 else return no
                if -howMany <= @startOffset
                    @setStart @startContainer, @startOffset + howMany
                    return yes
                if prev = @startContainer
                           .previousTextNode window.document.body
                    remaining = howMany + @startOffset
                    @setStart prev, prev.length
                    return @extendByCharacters remaining
            no

The `extendByWords` function is analogous, but extends by a given number of
words rather than a given number of characters.

A word counts as any sequence of consecutive letters, and a letter counts as
anything that can be modified with the `toUpperCase()` and `toLowerCase()`
function of JavaScript strings. (This is not perfect, in that it does not
pay attention to most non-alphabetic languages, but it is an easy shortcut,
for now.)

        isALetter = ( char ) -> char.toUpperCase() isnt char.toLowerCase()

We will use that on these two simple Range utilities.

        window.Range::firstCharacter = -> @toString().charAt 0
        window.Range::lastCharacter = ->
            @toString().charAt @toString().length - 1

Return values for `extendByWords` are the same as for `extendByCharacters`.

        window.Range::extendByWords = ( howMany ) ->
            original = @cloneRange()
            @includeWholeWords()
            if howMany is 0
                return yes
            else if howMany > 0
                if not @equals original
                    return @extendByWords howMany - 1
                seenALetter = no
                while @toString().length is 0 or not seenALetter or \
                      isALetter @lastCharacter()
                    lastRange = @cloneRange()
                    if not @extendByCharacters 1
                        return seenALetter and howMany is 1
                    if isALetter @lastCharacter() then seenALetter = yes
                @setStart lastRange.startContainer, lastRange.startOffset
                @setEnd lastRange.endContainer, lastRange.endOffset
                return @extendByWords howMany - 1
            else if howMany < 0
                if not @equals original
                    return @extendByWords howMany + 1
                seenALetter = no
                while @toString().length is 0 or not seenALetter or \
                      isALetter @firstCharacter()
                    lastRange = @cloneRange()
                    if not @extendByCharacters -1
                        return seenALetter and howMany is -1
                    if isALetter @firstCharacter() then seenALetter = yes
                @setStart lastRange.startContainer, lastRange.startOffset
                @setEnd lastRange.endContainer, lastRange.endOffset
                return @extendByWords howMany + 1
            no

Two ranges are the same if and only if they have the same start and end
containers and same start and end offsets.

        window.Range::equals = ( otherRange ) ->
            @startContainer is otherRange.startContainer and \
            @endContainer is otherRange.endContainer and \
            @startOffset is otherRange.startOffset and \
            @endOffset is otherRange.endOffset

The following utility function is used by the previous.  It expands the
Range object as little as possible to ensure that it contains an integer
number of words (no word partially included).

A range in the middle of a word will expand to include the word. A range
next to a word will expand to include the word.  A range touching no letter
on either side will not change.

        window.Range::includeWholeWords = ->
            while @toString().length is 0 or isALetter @firstCharacter()
                lastRange = @cloneRange()
                if not @extendByCharacters -1 then break
            @setStart lastRange.startContainer, lastRange.startOffset
            @setEnd lastRange.endContainer, lastRange.endOffset
            while @toString().length is 0 or isALetter @lastCharacter()
                lastRange = @cloneRange()
                if not @extendByCharacters 1 then break
            @setStart lastRange.startContainer, lastRange.startOffset
            @setEnd lastRange.endContainer, lastRange.endOffset

## Installation into main window global namespace

As mentioned above, we defined all of the functions in one big `installIn`
function so that we can install them in an iframe in addition to the main
window.  We now call `installIn` on the main `window` instance, so clients
do not need to do so.

    installDOMUtilitiesIn window
