
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

The above factory function uses the following constructor.  The constructor
also defines several properties for the object, by installing getters for
the common attributes type, value, name, cd, uri, symbol, body, children,
and variables.  These all return undefined if they do not apply to the
current structure, except children and variables, which return empty arrays
in that case.

        constructor : ( @tree ) ->
            Object.defineProperty this, 'parent',
                get : -> if @tree.p then new OMNode @tree.p else undefined
            Object.defineProperty this, 'type', get : -> @tree.t
            Object.defineProperty this, 'value',
                get : -> if @tree.t isnt 'bi' then @tree.v else undefined
            Object.defineProperty this, 'name', get : -> @tree.n
            Object.defineProperty this, 'cd', get : -> @tree.cd
            Object.defineProperty this, 'uri', get : -> @tree.uri
            Object.defineProperty this, 'symbol',
                get : -> if @tree.s then new OMNode @tree.s else undefined
            Object.defineProperty this, 'body',
                get : -> if @tree.b then new OMNode @tree.b else undefined
            Object.defineProperty this, 'children',
                get : -> new OMNode child for child in @tree.c ? [ ]
            Object.defineProperty this, 'variables',
                get : -> if @tree.t is 'bi'
                    new OMNode variable for variable in @tree.v
                else
                    [ ]

### Serialization

Unserializing an `OMNode` object from a string is done by the `decode`
method, above.  Serializing is done by its inverse, here, which simply uses
`JSON.stringify`, but filters out parent pointers.

        encode : =>
            JSON.stringify @tree, ( k, v ) ->
                if k is 'p' then undefined else v

### Copies and equality

Two instances will often want to be compared for equality, structurally.
This is essentially the same activity as comparing equality of two JSON
structures, except parent pointers should be ignored so that the recursion
remains acyclic.

You can pass a second parameter indicating whether to pay attention to
attributes in the comparison.  By default it is true, meaning consider all
attributes.  If it is false, no attributes will be considered.  Other values
may be supported in the future.

        equals : ( other, attributes = yes ) =>
            recur = ( a, b ) ->

If they are atomically equal, we're done.

                if a is b then return yes

If they're arrays, ensure they have the same length, type, and contents.

                if a instanceof Array or a instanceof Uint8Array
                    if ( a instanceof Array ) and ( b not instanceof Array )
                        return no
                    if ( a instanceof Uint8Array ) and \
                       ( b not instanceof Uint8Array )
                        return no
                    if a.length isnt b.length then return no
                    for element, index in a
                        if not recur element, b[index] then return no
                    return yes

Otherwise, they must be objects, with all the same key-value pairs.

                if a not instanceof Object then return no
                if b not instanceof Object then return no
                for own key, value of a
                    if key is 'p' or not attributes and key is 'a'
                        continue
                    if not b.hasOwnProperty key then return no
                    if not recur value, b[key] then return no
                for own key, value of b
                    if key is 'p' or not attributes and key is 'a'
                        continue
                    if not a.hasOwnProperty key then return no
                yes
            recur @tree, other.tree

There is also a much stricter notion of equality:  Do the two OMNode objects
actually wrap the same object underneath?  That is, are they pointing to the
same tree in memory?  This function can detect that.

        sameObjectAs : ( other ) => @tree is other?.tree

On a similar note, you may want to create a distinct copy of any given
OMNode instance.  Here is a method for doing so.

        copy : =>
            recur = ( tree ) ->
                result = switch tree.t

Integers, floats, and strings are easy to copy; just duplicate type and
value.  Variables and symbols are easy for the same reason, but different
atomic members.

                    when 'i', 'f', 'st' then { t : tree.t, v : tree.v }
                    when 'v' then { t : 'v', n : tree.n }
                    when 'sy'
                        result = { t : 'sy', n : tree.n, cd : tree.cd }
                        if tree.hasOwnProperty 'uri'
                            result.uri = tree.uri
                        result

Byte arrays require making a copy of the byte array object, which can be
accomplished with the constructor.

                    when 'ba' then { t : 'ba', v : new Uint8Array tree.v }

For errors and applications, we copy the children array; for errors we also
include the symbol.

                    when 'e', 'a'
                        result =
                            t : tree.t
                            c : ( recur child for child in tree.c )
                        if tree.t is 'e' then result.s = recur tree.s
                        result

Lastly, for bindings, we copy each sub-part: symbol, body, variable list.

                    when 'bi'
                        t : 'bi'
                        s : recur tree.s
                        v : ( recur variable for variable in tree.v )
                        b : recur tree.b

Then no matter what we created, we copy the attributes over as well.

                for own key, value of tree.a ? { }
                    ( result.a ?= { } )[key] = recur value
                result

Apply the recursive function.

            OMNode.decode recur @tree

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

### Simple encoding and decoding

The above functions can be used to create OpenMath data structures of
arbitrary complexity and type.  But most use cases can be handled with only
a subset of that full complexity, and we provide the following toosl for
doing so.

`OMNode.simpleDecode()` takes a string as input (like `OMNode.decode()`
does), but this string is in a much simple form.  Here are the formats it
supports.
 * `anyIdentifier` will be treated as a variable.  Examples:
   * `x`
   * `thing_7`
 * `ident1.ident2` will be treated as a symbol (CD and name, respectively).
   Examples:
   * `arith1.plus`
   * `transc1.arcsin`
 * any integer will be treated as an integer.  Examples:
   * -6
   * 57328074078459027340 (value will be a string, due to size)
 * any float will be treated as a float.  Examples:
   * 582.53280
   * -0.00001
 * a string literal enclosed in quotation marks (`"`) will be treated as a
   string, but with no support for escape codes, other than `\"`.  Examples:
   * "this is a string"
   * ""
 * a string literal enclosed in single quotes (`'`) behaves the same way,
   escaping only `\'`
   * 'this is also a string, ain\'t it?'
   * '""'
 * `F(A1,...,An)`, where `F` is any valid form and each `Ai` is as well,
   is interpreted as the application of `F` to the `Ai` in the order given.
   Here `n` may be zero.  Examples:
   * `f(x)`
   * `transc1.arcsin(arith1.divide(1,2))`
 * `F[A1,...,An]` behaves the same as the previous case, except that the
   `Ai` entries before `An` must all be variables, and they will be bound;
   i.e., this yields an OpenMath binding object, not an application object.
   Examples:
   * `logic.forall(x,P(x))`
   * `foo.lambda(x,f(x,7,"bar"))`
This syntax does not allow for the expression of OpenMath error objects,
attributions, symbol URIs, byte arrays, or very large integers.

We declare the following structure for use in the routine below.

        tokenTypes = [
            name : 'symbol'
            pattern : /[:A-Za-z_][:A-Za-z_0-9-]*\.[:A-Za-z_][:A-Za-z_0-9-]*/
        ,
            name : 'variable'
            pattern : /[:A-Za-z_][:A-Za-z_0-9-]*/
        ,
            name : 'float'
            pattern : /[+-]?(?:[0-9]+\.[0-9]*|[0-9]*\.[0-9]+)/
        ,
            name : 'integer'
            pattern : /[+-]?[0-9]+/
        ,
            name : 'string'
            pattern : /"(?:[^"\\]|\\"|\\\\)*"|'(?:[^'\\]|\\'|\\\\)*'/
        ,
            name : 'comma'
            pattern : /,/
        ,
            name : 'openParen'
            pattern : /\(/
        ,
            name : 'closeParen'
            pattern : /\)/
        ,
            name : 'openBracket'
            pattern : /\[/
        ,
            name : 'closeBracket'
            pattern : /\]/
        ]

Now the routine itself.

        @simpleDecode = ( input ) ->

Ensure the input is a string.

            if typeof input isnt 'string'
                return 'Input was not a string'

Tokenize it using the above token data.

            tokens = [ ]
            while input.length > 0
                originally = input.length
                for tokenType in tokenTypes
                    match = tokenType.pattern.exec input
                    if match? and match.index is 0
                        tokens.push
                            type : tokenType.name
                            text : match[0]
                        input = input[match[0].length..]
                if input.length is originally
                    return "Could not understand from here: #{input[..10]}"

Parse tokens using two states: one for when an expression is about to start,
and one for when an expression just ended.  Maintain a stack of expressions
already parsed, for forming application and binding expressions.

            state = 'expression about to start'
            stack = [ ]
            while tokens.length > 0
                next = tokens.shift()
                switch state
                    when 'expression about to start'
                        switch next.type
                            when 'symbol'
                                halves = next.text.split '.'
                                stack.unshift
                                    node :
                                        OMNode.symbol halves[1], halves[0]
                            when 'variable'
                                stack.unshift
                                    node : OMNode.variable next.text
                            when 'integer'
                                int = parseInt next.text
                                if /\./.test int then int = next.text
                                stack.unshift node : OMNode.integer int
                            when 'float'
                                stack.unshift
                                    node : OMNode.float parseFloat next.text
                            when 'string'
                                type = next.text[0]
                                next = next.text[1...-1].replace \
                                    RegExp( "\\\\#{type}", 'g' ), type
                                stack.unshift node : OMNode.string next
                            else return "Unexpected #{next.text}"
                        state = 'expression ended'
                    when 'expression ended'
                        switch next.type
                            when 'comma'
                                state = 'expression about to start'
                            when 'openParen'
                                stack[0].head = 'application'
                                if tokens?[0]?.type is 'closeParen'
                                    tokens.shift()
                                    stack.unshift
                                        node : OMNode.application \
                                            stack.shift().node
                                    state = 'expression ended'
                                else
                                    state = 'expression about to start'
                            when 'openBracket'
                                stack[0].head = 'binding'
                                state = 'expression about to start'
                            when 'closeParen'
                                for expr, index in stack
                                    if expr.head is 'application' then break
                                    if expr.head is 'binding'
                                        return "Mismatch: [ closed by )"
                                if index is stack.length
                                    return "Unexpected )"
                                children = [ ]
                                for i in [0..index]
                                    children.unshift stack.shift().node
                                stack.unshift
                                    node : OMNode.application.apply \
                                        null, children
                            when 'closeBracket'
                                for expr, index in stack
                                    if expr.head is 'binding' then break
                                    if expr.head is 'application'
                                        return "Mismatch: ( closed by ]"
                                if index is stack.length
                                    return "Unexpected ]"
                                children = [ ]
                                for i in [0..index]
                                    children.unshift stack.shift().node
                                stack.unshift
                                    node : OMNode.binding.apply \
                                        null, children
                            else return "Unexpected #{next.text}"
                if typeof stack?[0].node is 'string'
                    return stack[0].node # error in building OMNode

Parsing complete so there should be just one node on the stack, the result.
If there is more than one, we have an error.

            if stack.length > 1
                "Unexpected end of input"
            else
                stack[0].node

The inverse to the above function is a simple encoding function.  It can
operate on only a subset of the full complexity of OMNode trees, and thus in
some cases it gives results that are not representative of the input.  Here
are the details:
 * integers, floats, and strings will all be correctly encoded
 * variables without dots in their names will be correctly encoded; those
   with dots in their names conflict with the naming of symbols in the
   simple encoding, but will be encoded as their names
 * symbols will be correctly encoded with the exception that any URI will be
   dropped, and the same issue with dots applies to symbol and CD names
 * byte arrays and errors have no simple encoding, and will thus all be
   converted to a string containing the words "byte array" or "error,"
   respectively
 * all attributions are dropped

        simpleEncode : =>
            recur = ( tree ) ->
                switch tree?.t
                    when 'i', 'f' then "#{tree.v}"
                    when 'v' then tree.n
                    when 'st' then "'#{tree.v.replace /'/g, '\\\''}'"
                    when 'sy' then "#{tree.cd}.#{tree.n}"
                    when 'ba' then "'byte array'"
                    when 'e' then "'error'"
                    when 'a'
                        children = ( recur c for c in tree.c )
                        head = children.shift()
                        "#{head}(#{children.join ','})"
                    when 'bi'
                        variables = ( recur v for v in tree.v )
                        head = recur tree.s
                        body = recur tree.b
                        "#{head}[#{variables.join ','},#{body}]"
                    else "Error: Invalid OpenMath type #{tree?.t}"
            recur @tree

### Parent-child relationships

The functions in this category make, break, or report the relationship of an
OMNode instance to its parents or children.

This first function reports where the node is in its parent.  The return
value will be one of five types:
 * a string containing "c" followed by a number, as in 'c7' - this means
   that the node is in it's parent's `children` array, and is at index 7
 * a string containing "v" followed by a number, as in 'v0' - this is the
   same as the previous, but for the parent's `variables` array
 * the string "b" - this means that the node is the body and its parent is
   a binding
 * the string "s" - this means that the node is a symbol for its parent,
   which is either an error or a binding
 * a lengthier string beginning with "{" - this is the JSON encoded version
   of the attribute key for which the node is the corresponding value
 * undefined if none of the above apply (e.g., no parent, or invalid tree
   structure)

        findInParent : =>
            if not @parent then return undefined
            for child, index in @parent.children
                if @sameObjectAs child then return "c#{index}"
            if @type is 'v'
                for variable, index in @parent.variables
                    if @sameObjectAs variable then return "v#{index}"
            if @sameObjectAs @parent.symbol then return 's'
            if @sameObjectAs @parent.body then return 'b'
            for own key, value of @parent.tree.a ? { }
                if @tree is value then return key
            undefined # should not happen

The inverse of the previous function takes a string output by that function
and returns the corresponding child/variables/symbol/body immediately inside
this node.  That is, `x.parent.findChild x.findInParent()` will give us back
the same tree as `x` itself.  An invalid input will return undefined.

        findChild : ( indexInParent ) =>
            switch indexInParent[0]
                when 'c' then @children[parseInt indexInParent[1..]]
                when 'v' then @variables[parseInt indexInParent[1..]]
                when 's' then @symbol
                when 'b' then @body
                when '{' then @getAttribute OMNode.decode indexInParent

The `findInParent()` function can be generalized to find a node in any of
its ancestors, the result being an array of `findInParent()` results as you
walk downward from the ancestor to the descendant.  For instance, the first
bound variable within the second child of an application would have the
address `[ 'c1', 'v0' ]` (since indices are zero-based).  The following
function computes the array in question, the node's "address" within the
given ancestor.

If no ancestor is specified, the highest-level one is used.  If a value is
passed that is not an ancestor of this node, then it is treated as if no
value had been passed.  If this node has no parent, or if this node itself
is passed as the parameter, then the empty array is returned.

        address : ( inThis ) =>
            if not @parent or @sameObjectAs inThis then return [ ]
            @parent.address( inThis ).concat [ @findInParent() ]

The `address` function has the following inverse, which looks up in an
ancestor node a descendant that has the given address within that ancestor.
So, in particular, `x.index y.address( x )` should equal `y`.  Furthermore,
`x.index [ ]` will always yield `x`.  An invalid input will return
undefined.

        index : ( address ) =>
            if address not instanceof Array then return undefined
            if address.length is 0 then return this
            @findChild( address[0] )?.index address[1..]

The following function breaks the relationship of the object with its
parent.  In some cases, this can invalidate the parent (e.g., by giving a
binding or error object no head symbol, or a binding no body, or no bound
variables).  If the object has no parent or its position in that parent is
undefined (as determined by `@findInParent()`) then this does nothing.

        remove : =>
            if not index = @findInParent() then return
            switch index[0]
                when 'c'
                    @parent.tree.c.splice parseInt( index[1..] ), 1
                when 'v'
                    @parent.tree.v.splice parseInt( index[1..] ), 1
                when 'b' then delete @parent.tree.b
                when 's' then delete @parent.tree.s
                when '{' then delete @parent.tree.a[index]
            delete @tree.p

It will also be useful in later functions in this class to be able to
replace a subtree in-place with a new one.  The following method
accomplishes this, replacing this object in its context with the parameter.
This works whether this tree is a child, variable, head symbol, body, or
attribute value of its parent.  If this object has no parent, then we make
no modifications to that parent, since it does not exist.

In all cases, the parameter is `remove()`d from its context, and this node,
if it has a parent, is `remove()`d from it as well.  Furthermore, this
OMNode instance becomes a wrapper to the given node instead of its current
contents.  The removed node is returned.

        replaceWith : ( other ) =>
            other.remove()
            original = new OMNode @tree
            @tree = other.tree
            if not index = original.findInParent() then return
            switch index[0]
                when 'c'
                    original.parent.tree.c[parseInt index[1..]] = @tree
                when 'v'
                    original.parent.tree.v[parseInt index[1..]] = @tree
                when 'b' then original.parent.tree.b = @tree
                when 's' then original.parent.tree.s = @tree
                when '{' then original.parent.tree.a[index] = @tree
                else throw 'Invalid index in parent' # should never happen
            @tree.p = original.tree.p
            delete original.tree.p
            original

### Attributes

Here we have three functions that let us manipulate attributes without
worrying about the unpredictable ordering of keys in a JSON stringification
of an object.

The first takes an OMNode instance as input and looks up the corresponding
key-value pair in this object's attributes, if there is one.  If so, it
returns the corresponding value as an OMNode instance.  Otherwise, it
returns undefined.

For efficiency, this considers only the names and CDs of the key when
searching.  If that becomes a problem later, it could be changed here in
this function, as well as in the two that follow.

        getAttribute : ( keySymbol ) =>
            if keySymbol not instanceof OMNode then return undefined
            if keySymbol.type isnt 'sy' then return undefined
            nameRE = RegExp "\"n\":\"#{keySymbol.name}\""
            cdRE = RegExp "\"cd\":\"#{keySymbol.cd}\""
            for own key, value of @tree.a ? { }
                if nameRE.test( key ) and cdRE.test( key )
                    return new OMNode value

The second takes an OMNode instance as input and looks up the corresponding
key-value pair in this object's attributes, if there is one.  If so, it
deletes that key-value pair, which includes calling `remove()` on the value.
Otherwise, it does nothing.

The same efficiency comments apply to this function as to the previous.

        removeAttribute : ( keySymbol ) =>
            if keySymbol not instanceof OMNode then return
            if keySymbol.type isnt 'sy' then return
            nameRE = RegExp "\"n\":\"#{keySymbol.name}\""
            cdRE = RegExp "\"cd\":\"#{keySymbol.cd}\""
            for own key, value of @tree.a ? { }
                if nameRE.test( key ) and cdRE.test( key )
                    ( new OMNode value ).remove()
                    delete @tree.a[key]
                    return

The third and final function of the set takes two OMNode instances as input,
a key and a new value.  It looks up the corresponding key-value pair in this
object's attributes, if there is one.  If so, it replaces the original value
with the new value, including calling `remove()` on the old value.
Otherwise, it inserts a new key-value pair corresponding to the two
parameters.  In either case, `remove()` is called on the new value before it
is inserted into this tree, in case it is already in another tree.

The same efficiency comments apply to this function as to the previous.

        setAttribute : ( keySymbol, newValue ) =>
            if keySymbol not instanceof OMNode or \
               newValue not instanceof OMNode then return
            if keySymbol.type isnt 'sy' then return
            @removeAttribute keySymbol
            newValue.remove()
            ( @tree.a ?= { } )[keySymbol.encode()] = newValue.tree
            newValue.tree.p = @tree

### Free and bound variables and expressions

The methods in this section are about variable binding and which expressions
are free to replace others.  There are also methods that do such
replacements.

This method lists the free variables in an expression.  It returns an array
of strings, just containing the variables' names.  Variables appearing in
attributes do not count; only variables appearing as children of
applications or error nodes, or in the body of a binding expression can
appear on this list.

        freeVariables : =>
            switch @type
                when 'v' then return [ @name ]
                when 'a', 'c'
                    result = [ ]
                    for child in @children
                        for free in child.freeVariables()
                            result.push free unless free in result
                    result
                when 'bi'
                    boundByThis = ( v.name for v in @variables )
                    ( varname for varname in @body.freeVariables() \
                        when varname not in boundByThis )
                else [ ]

This method computes whether an expression is free by walking up its
ancestor chain and determining whether any of the variables free in the
expression are bound further up the ancestor chain.  If you pass an
ancestor as the parameter, then the computation will not look upward beyond
that ancestor; the default is to leave the parameter unspecified, meaning
that the algorithm should look all the way up the parent chain.

        isFree : ( inThis ) =>
            freeVariables = @freeVariables()
            walk = this
            while walk
                if walk.type is 'bi'
                    boundHere = ( v.name for v in walk.variables )
                    for variable in freeVariables
                        if variable in boundHere then return no
                if walk.sameObjectAs inThis then break
                walk = walk.parent
            yes

This method returns true if there is a descendant of this structure that is
structurally equivalent to the parameter and, at that point in the tree,
passes the `isFree` test defined immediately above.  This algorithm only
looks downward through children, head symbols, and bodies of binding nodes,
not attribute keys or values.

Later it would be easy to add an optional second parameter, `inThis`, which
would function like the parameter of the same name to `isFree()`, and would
be passed directly along to `isFree()`.  This change would require testing.

        occursFree : ( findThis ) =>
            if @equals( findThis ) and @isFree() then return yes
            if @symbol?.equals findThis then return yes
            if @body?.occursFree findThis then return yes
            for child in @children
                if child.occursFree findThis then return yes
            no

This method replaces every free occurrence of one expression (original) with
a copy of the another expression (replacement).  The search-and-replace
recursion only proceeds through children, head symbols, and bodies of
binding nodes, not attribute keys or values.

The optional third parameter, `inThis`, functions like the parameter of the
same name to `isFree()`, is passed directly along to `isFree()`.

        replaceFree : ( original, replacement, inThis ) =>
            inThis ?= this
            if @isFree( inThis ) and @equals original
                save = new OMNode @tree
                @replaceWith replacement.copy()
                if not @isFree inThis then @replaceWith save
                return
            @symbol?.replaceFree original, replacement, inThis
            @body?.replaceFree original, replacement, inThis
            for variable in @variables
                variable.replaceFree original, replacement, inThis
            for child in @children
                child.replaceFree original, replacement, inThis

### Filtering children and descendants

The following function returns an array of all children (immediate
subexpressions, actually, including head symbols, bound variables, etc.)
that pass the given criterion.  If no criterion is given, then all immediate
subexpressions are returned.  Order is preserved.

Note that the actual subtrees are returned, not copies thereof.  Any
manipulation done to the elements of the result array will therefore impact
the original expression.

        childrenSatisfying : ( filter = -> yes ) =>
            children = @children
            if @symbol? then children.push @symbol
            children = children.concat @variables
            if @body? then children.push @body
            ( child for child in children when filter child )

The following function returns an array of all subexpressions (not just
immediate ones) that pass the given criterion, in tree order.  If no
criterion is given, then all subexpressions are returned.

As with the previous function, the actual subtrees are returned, not copies
thereof.  Any manipulation done to the elements of the result array will
therefore impact the original expression.

        descendantsSatisfying : ( filter = -> yes ) =>
            results = [ ]
            if filter this then results.push this
            for child in @childrenSatisfying()
                results = results.concat child.descendantsSatisfying filter
            results

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
    OM.simple = OM.simpleDecode
