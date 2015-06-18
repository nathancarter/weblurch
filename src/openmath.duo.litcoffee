
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

    if not exports? then exports = module?.exports ? window

## OpenMath Node class

    exports.OMNode = exports.OM = OM = class OMNode

### Class ("static") methods

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
                        return "Invalid identifier as variable name:
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
                        return "In a binding, the v value must be an array"
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

The following function converts a string encoding of an OpenMath structure
and creates an instance of `OMNode` for the corresponding structure.
 * If the string contains invalid JSON, this routine will return an
   error message string rather than an OMNode object.
 * If it contains JSON for a structure that doesn't pass `checkJSON`, above,
   again, an error message string is returned.
 * Otherwise it adds appropriate parent pointers to the nodes in the
   resulting tree, then wraps it in an instance of OMNode and returns it.
The function can also take an object that has been parsed from such JSON
text.

        @decode : ( json ) ->
            if typeof json is 'string'
                try json = JSON.parse json catch e then return e.message
            if reason = @checkJSON json then return reason
            setParents = ( node ) ->
                for c in node.c ? [ ] # children, if any
                    c.p = node
                    setParents c
                for v in node.v ? [ ] # bound variables, if any
                    v.p = node
                    setParents v
                for own k, v of node.a ? { } # attribute values, if any
                    v.p = node
                    setParents v
                # head symbol and body object, if any
                if node.s? then node.s.p = node ; setParents node.s
                if node.b? then node.b.p = node ; setParents node.b
            setParents json
            json.p = null
            new OMNode json

### Constructor

The above factory function uses the following constructor.

        constructor : ( @tree ) ->

### Serialization

Unserializing an `OMNode` object from a string is done by the `decode`
method, above.  Serializing is done by its inverse, here, which simply uses
`JSON.stringify`, but filters out parent pointers.

        encode : =>
            JSON.stringify @tree, ( k, v ) ->
                if k is 'p' then undefined else v

### Factory functions

We provide here functions for creating each type of OMNode, from integer to
error.  Each is a "static" (class) method, documented separately.  It
returns an error message as a string if there was an error, instead of the
desired OMNode instance.

The integer factory function creates an OpenMath integer node, and must be
passed a single parameter containing either an integer or a string
representation of an integer, e.g., `OM.integer 100`.

        @integer : ( value ) ->
            OMNode.decode { t : 'i', v : value }

The float factory function creates an OpenMath float node, and must be
passed a single parameter containing a number, e.g., `OM.integer 1.234`,
and that number cannot be infinite or NaN.

        @float : ( value ) ->
            OMNode.decode { t : 'f', v : value }

The string factory function creates an OpenMath string node, and must be
passed a single parameter containing a string, e.g., `OM.integer 'hi'`.

        @string : ( value ) ->
            OMNode.decode { t : 'st', v : value }

The byte array factory function creates an OpenMath byte array node, and
must be passed a single parameter that is an instance of `Uint8Array`.

        @bytearray : ( value ) ->
            OMNode.decode { t : 'ba', v : value }

The symbol factory function creates an OpenMath symbol node, and must be
passed two or three parameters, in this order: symbol name (a string),
content dictionary name (a string), and optionally the CD's base URI (a
string).

        @symbol : ( name, cd, uri ) ->
            OMNode.decode if uri?
                { t : 'sy', n : name, cd : cd, uri : uri }
            else
                { t : 'sy', n : name, cd : cd }

The variable factory function creates an OpenMath variable node, and must be
passed one parameter, the variable name (a string).

        @variable : ( name ) ->
            OMNode.decode { t : 'v', n : name }

The application factory creates an OpenMath application node, and accepts a
variable number of arguments, each of which must be either an `OMNode`
instance or the JSON object that could function as the tree within such an
instance.  `OMNode` instances are copied, objects are used as-is.

        @application : ( args... ) ->
            result = { t : 'a', c : [ ] }
            for arg in args
                result.c.push if arg instanceof OMNode
                    JSON.parse arg.encode() # copy without parent pointers
                else
                    arg
            OMNode.decode result

The attribution factory creates an OpenMath node from its first argument,
and attaches to it the attributes specified by the remaining arguments.
Those remaining arguments must come in pairs k1, v1, through kn, vn, and
each ki,vi pair must be an OpenMath symbol node followed by any OpenMath
node.  As in the case of applications, such nodes may be JSON objects or
`OMNode` instances; the former are used as-is and the latter copied.  The
first parameter can also be either a JSON object or an `OMNode` instance,
and in the latter case it, too, is copied.

        @attribution : ( node, attrs... ) ->
            if node not instanceof Object
                return 'Invalid first parameter to attribution'
            if attrs.length % 2 isnt 0
                return 'Incomplete key-value pair in attribution'
            if node instanceof OMNode then node = JSON.parse node.encode()
            while attrs.length > 0
                node.a ?= { }
                key = attrs.shift()
                key = if key instanceof OMNode
                    key.encode()
                else
                    JSON.stringify key
                value = attrs.shift()
                node.a[key] = if value instanceof OMNode
                    JSON.parse value.encode() # copy without parent pointers
                else
                    value
            OMNode.decode node

The binding factory functions exactly like the application factory, except
that it has restrictions on the types of its arguments.  The first must be a
symbol (used as the head of the binding), the last can be any OpenMath node,
and all those in between must be variables.  Furthermore, there must be at
least two arguments, so that there is a head and a body.  Just as in the
case of applications, `OMNode` instances are copied, but straight JSON
objects are used as-is.

        @binding : ( head, vars..., body ) ->
            if head not instanceof Object
                return 'Invalid first parameter to binding'
            if body not instanceof Object
                return 'Invalid last parameter to binding'
            result =
                t : 'bi'
                s : if head instanceof OMNode
                    JSON.parse head.encode()
                else
                    head
                v : [ ]
                b : if body instanceof OMNode
                    JSON.parse body.encode()
                else
                    body
            for variable in vars
                result.v.push if variable instanceof OMNode
                    JSON.parse variable.encode() # copy w/o parent pointers
                else
                    variable
            OMNode.decode result

The error factory functions exactly like the application factory, except
that it has one restriction on the types of its arguments:  The first must
be a symbol.  Just as in the case of applications, `OMNode` instances are
copied, but straight JSON objects are used as-is.

        @error : ( head, others... ) ->
            if head not instanceof Object
                return 'Invalid first parameter to binding'
            result =
                t : 'e'
                s : if head instanceof OMNode
                    JSON.parse head.encode()
                else
                    head
                c : [ ]
            for other in others
                result.c.push if other instanceof OMNode
                    JSON.parse other.encode() # copy without parent pointers
                else
                    other
            OMNode.decode result

## Nicknames

Here we copy each of the factory functions to a short version if its own
name, so that they can be combined in more compact form when creating
expressions.  Each short version is simply the first 3 letters of its long
version, to make them easy to remember.

    OM.int = OM.integer
    OM.flo = OM.float
    OM.str = OM.string
    OM.byt = OM.bytearray
    OM.sym = OM.symbol
    OM.var = OM.variable
    OM.app = OM.application
    OM.att = OM.attribution
    OM.bin = OM.binding
    OM.err = OM.error
