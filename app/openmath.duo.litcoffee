
# OpenMath module

This module implements an encoding of OpenMath objects as JSON.  It is *not*
an official encoding endorsed by the OpenMath Society.  It is merely my own
choice of how to do the encoding, in the absence of an official standard
(that I could find).

Objects are encoded as follows.  (If these phrases are unfamiliar to you,
see [the OpenMath Standard,
v2.0](http://www.openmath.org/standard/om20-2004-06-30/).)
 * OMI - `{ t : 'i', v : 6 }` (where `t` stands for type and `v` for value),
   and integers may also be stored as strings if desired (e.g., `-6`)
 * OMF - `{ t : 'f', v : -0.521 }`
 * OMSTR - `{ t : 'st', v : 'example' }`
 * OMB - `{ t : 'ba', v : aUint8ArrayHere }`
 * OMS - `{ t : 'sy', n : 'symbolName', cd : 'cd', uri : 'http://...' }`,
   where the URI is optional
 * OMV - `{ t : 'v', n : 'name' }`
 * OMA - `{ t : 'a', c : [ child, objects, here ] }` (children are the
   required operator, followed by zero or more operands)
 * OMATTR - rather than wrap things in OMATTR nodes, simply add the
   attributes object (a mapping from string keys to objects) to the existing
   object, with 'a' as its key.  To create the string key for an OM symbol,
   just use its JSON form (fully compact, as created by `JSON.stringify`
   with one argument).
 * OMBIND - `{ t : 'bi', s : object, v : [ bound, vars ], b : object }`,
   where `s` stands for the head symbol and `b` for the body
 * OMERR - `{ t : 'e', s : object, c : [ child, nodes, here ] }`, where `s`
   stands for the head symbol, and `c` can be omitted if empty.
 * No encoding for foreign objects is specified here.

The following line ensures that this file works in Node.js, for testing.

    if global? and not window? then window = global

## OpenMath Node class

    window.OMNode = class OMNode

The following class method checks to see if an object is of any one of the
formats specified above; if so, it returns true, and if not, it returns an
error describing why not.  It is recursive, verifying that children are also
of the correct form.

It either returns a string, meaning that the object is invalid, and the
string contains the reason why, or it returns null, meaning that the object
is valid.

        @checkJSON : ( object ) ->
            if object not instanceof Object
                return "Expected an object, found #{typeof object}"

If the object has attributes, we must verify that their keys are the
stringified forms of JSON objects representing OpenMath symbols and their
values also pass this same validity test, recursively.

            if object.hasOwnProperty 'a'
                for own key, value of object.a
                    try
                        symbol = JSON.parse key
                    catch e
                        return "Key #{key} invalid JSON"
                    if symbol.t isnt 'sy'
                        return "Key #{key} is not a symbol"
                    if reason = @checkJSON symbol then return reason
                    if reason = @checkJSON value then return reason
                null

This function verifies that the object doesn't have any keys beyond those on
the list, plus 't' for type and 'a' for attributes.

            checkKeys = ( list... ) ->
                for key in Object.keys object
                    if key not in list and key isnt 't' and key isnt 'a'
                        return "Key #{key} not valid in object of type
                            #{object.t}"
                null

This is not nearly the full range of Unicode symbols permitted for
identifiers in the OpenMath specification, but is a useful subset for this
first implementation.  See page 14 of [the
standard](http://www.openmath.org/standard/om20-2004-06-30/omstd20.pdf) for
the exact regular expression.

            identRE = /^[:A-Za-z_][:A-Za-z_.0-9-]*$/

Now we consider each type of object separately.

            switch object.t

Integers must have t and v keys, and the latter must look like an integer,
whether it's actually one or a string doesn't matter.

                when 'i'
                    if reason = checkKeys 'v' then return reason
                    if not /^[+-]?[0-9]+$/.test "#{object.v}"
                        return "Not an integer: #{object.v}"

Floats must have t and v keys, and the latter must be a number.

                when 'f'
                    if reason = checkKeys 'v' then return reason
                    if typeof object.v isnt 'number'
                        return "Not a number: #{object.v} of type
                            #{typeof object.v}"
                    if isNaN object.v
                        return 'OpenMath floats cannot be NaN'
                    if not isFinite object.v
                        return 'OpenMath floats must be finite'

Strings must have t and v keys, and the latter must be a string.

                when 'st'
                    if reason = checkKeys 'v' then return reason
                    if typeof object.v isnt 'string'
                        return "Value for st type was #{typeof object.v},
                            not string"

Byte Arrays must have t and v keys, the latter of which is a `Uint8Array`.

                when 'ba'
                    if reason = checkKeys 'v' then return reason
                    if object.v not instanceof Uint8Array
                        return "Value for ba type was not an instance of
                            Uint8Array"

Symbols must have t, n, and cd keys, with an optional uri key, all of which
must be strings.  The n key (for "name") must be a valid identifier, in that
it must match the regular expression defined above.

                when 'sy'
                    if reason = checkKeys 'n','cd','uri' then return reason
                    if typeof object.n isnt 'string'
                        return "Name for sy type was #{typeof object.n},
                            not string"
                    if typeof object.cd isnt 'string'
                        return "CD for sy type was #{typeof object.cd},
                            not string"
                    if object.uri? and typeof object.uri isnt 'string'
                        return "URI for sy type was #{typeof object.uri},
                            not string"
                    if not identRE.test object.n
                        return "Invalid identifier as symbol name:
                            #{object.n}"
                    if not identRE.test object.cd
                        return "Invalid identifier as symbol CD:
                            #{object.cd}"

Variables must have t and n keys, the latter of which must be a valid
identifier, matching the same regular expression as above.

                when 'v'
                    if reason = checkKeys 'n' then return reason
                    if typeof object.n isnt 'string'
                        return "Name for v type was #{typeof object.n},
                            not string"
                    if not identRE.test object.n
                        return "Invalid identifier as symbol name:
                            #{object.n}"

Applications must have t and c keys, the latter of which must be an array of
objects that pass this same validity test, applied recursively.  It may not
be empty.

                when 'a'
                    if reason = checkKeys 'c' then return reason
                    if object.c not instanceof Array
                        return "Children of application object was not an
                            array"
                    if object.c.length is 0
                        return "Application object must have at least one
                            child"
                    for child in object.c
                        if reason = @checkJSON child then return reason

Bindings must have t, s, v, and b keys, where s is a symbol, v an array of
variables, and b any OpenMath node.

                when 'bi'
                    if reason = checkKeys 's', 'v', 'b' then return reason
                    if reason = @checkJSON object.s then return reason
                    if object.s.t isnt 'sy'
                        return "Head of a binding must be a symbol"
                    if object.v not instanceof Array
                        return "In a binding, the v key must be an array"
                    for variable in object.v
                        if reason = @checkJSON variable then return reason
                        if variable.t isnt 'v'
                            return "In a binding, all values in the v array
                                must have type v"
                    if reason = @checkJSON object.b then return reason

Errors must have t, s, and c keys, with s a symbol and c an array of child
nodes.

                when 'e'
                    if reason = checkKeys 's', 'c' then return reason
                    if reason = @checkJSON object.s then return reason
                    if object.s.t isnt 'sy'
                        return "Head of an error must be a symbol"
                    if object.c not instanceof Array
                        return "In an error, the c key must be an array"
                    for child in object.c
                        if reason = @checkJSON child then return reason

If the object's type is not on that list, it's not valid.

                else
                    return "Invalid type: #{object.t}"

If all of the above checks pass then we return null, meaning the object is
valid (no errors).

            null

## Export classes defined herein

    if exports?
        exports.OMNode = OMNode
