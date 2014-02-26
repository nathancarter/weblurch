
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
would call it like `N.address M`.

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

