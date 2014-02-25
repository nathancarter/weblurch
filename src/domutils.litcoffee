
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

The following function compute the address of any one DOM node
within any other.  If the second parameter (the ancestor, called
`M` above) is not supplied, then it is taken to be the top-level
Node (i.e., the furthest-up ancestor, with no `.parentNode`).

    window.address = ( node, ancestor = null ) ->

First, be safe by ensuring that `node` is actually a DOM Node.

        if node not instanceof Node
            throw Error 'address() requires a Node as argument 0'

The base case comes in two flavors.
First, if the two parameters match, then they must be the same
node, so return the empty array.

        if node is ancestor then return []

Second, if we've reached the top level then we must consider the
second parameter.  Were we looking inside a specific ancestor?  If
so, we didn't find it, so return null.  If not, return the empty
array, because we are the top level.

        if not node.parentNode
            return if ancestor then null else []

Otherwise, recur up the ancestor tree, and concatenate our own
index in our parent with the array we compute there, if there is
one.

        recur = address node.parentNode, ancestor
        if recur is null then return null
        recur.concat [ Array.prototype.slice.apply(
            node.parentNode.childNodes ).indexOf node ]

