
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

