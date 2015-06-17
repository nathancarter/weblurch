
# Tests of the OpenMath module

Here we import the module we're about to test, plus a utilities module for
comparing JSON structures.  (That module is tested [in a separate
file](utils-spec.litcoffee).)

    { OMNode } = require '../src/openmath.duo'
    require '../src/utils'

## `OMNode` class

This section verifies that the OMNode class is defined, and some of its
methods are also.

    describe 'OMNode class', ->
        it 'should be defined, with its methods', ->
            expect( OMNode ).toBeTruthy()
            expect( OMNode.checkJSON ).toBeTruthy()

## `OMNode.checkJSON`

This section tests the `OMNode.checkJSON` routine, ensuring that it finds
things to have correct form when they actually do, and incorrect form when
they do not.

    describe 'OMNode.checkJSON', ->

### should find atomic nodes with the right form valid

        it 'should find atomic nodes with the right form valid', ->

Positive, negative, and 0 as integers.  Some strings, some numbers.

            expect( OMNode.checkJSON { t : 'i', v : 3 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'i', v : -335829 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'i', v : 0 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'i', v : '57238905173420' } ) \
                .toBeNull()
            expect( OMNode.checkJSON { t : 'i', v : '-1' } ).toBeNull()
            expect( OMNode.checkJSON { t : 'i', v : '0' } ).toBeNull()

Various floats, but here they must be numbers, not strings.

            expect( OMNode.checkJSON { t : 'f', v : 3 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'f', v : -335829 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'f', v : 0 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'f', v : 0.00001 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'f', v : -3284.352 } ).toBeNull()
            expect( OMNode.checkJSON { t : 'f', v : 1.203e-6 } ).toBeNull()

Various strings, some empty, some long.

            expect( OMNode.checkJSON { t : 'st', v : '' } ).toBeNull()
            expect( OMNode.checkJSON { t : 'st', v : ' 1 2 3 4 5 ' } ) \
                .toBeNull()
            expect( OMNode.checkJSON {
                t : 'st'
                v : "In the first survey question, respondents were asked to name the desired characteristics of a top predictive modeler. The top answer was 'good business knowledge,' followed closely by 'understanding of statistics.' Other popular responses were 'avid learner,' 'communicating results,' 'data expertise,' and 'good programmer.'"
            } ).toBeNull()
            expect( OMNode.checkJSON { t : 'st', v : {}.toString() } ) \
                .toBeNull()

Two byte arrays, one empty, one long.

            expect( OMNode.checkJSON { t : 'ba', v : new Uint8Array } ) \
                .toBeNull()
            expect( OMNode.checkJSON {
                t : 'ba'
                v : new Uint8Array 1000
            } ).toBeNull()

Symbols with various identifiers for their names and CDs, and any old text
for the URIs, since that is not constrained in the current implementation.

            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'exampleSymbolName'
                cd : 'my_content_dictionary'
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'arcsec'
                cd : 'transc1'
                uri : 'http://www.openmath.org/cd'
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'sy'
                n : '_'
                cd : 'dummy-not-real'
                uri : 'http://www.lurchmath.org'
            } ).toBeNull()

A few variables, all with valid identifiers for names.

            expect( OMNode.checkJSON { t : 'v', n : 'x' } ).toBeNull()
            expect( OMNode.checkJSON { t : 'v', n : 'y' } ).toBeNull()
            expect( OMNode.checkJSON { t : 'v', n : '_foo' } ).toBeNull()
            expect( OMNode.checkJSON { t : 'v', n : 'aThing' } ).toBeNull()

### should find compound nodes with the right form valid

        it 'should find compound nodes with the right form valid', ->

We can apply variables as functions to other atomics.

            # f(x)
            expect( OMNode.checkJSON {
                t : 'a'
                c : [
                    { t : 'v', n : 'f' }
                    { t : 'v', n : 'x' }
                ]
            } ).toBeNull()
            # g(3,-0.1)
            expect( OMNode.checkJSON {
                t : 'a'
                c : [
                    { t : 'v', n : 'g' }
                    { t : 'i', v : 3 }
                    { t : 'f', v : -0.1 }
                ]
            } ).toBeNull()
            # myFunc()
            expect( OMNode.checkJSON {
                t : 'a'
                c : [ { t : 'v', n : 'myFunc' } ]
            } ).toBeNull()

We can quantify over variables, even zero variables.

            # forall x, P(x)
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'example' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        { t : 'v', n : 'x' }
                    ]
                }
            } ).toBeNull()
            # forall x, exists z, x > z
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'example' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'bi'
                    s : { t : 'sy', n : 'exists', cd : 'example' }
                    v : [ { t : 'v', n : 'z' } ]
                    b : {
                        t : 'a'
                        c : [
                            { t : 'sy', n : 'greaterThan', cd : 'example' }
                            { t : 'v', n : 'x' }
                            { t : 'v', n : 'z' }
                        ]
                    }
                }
            } ).toBeNull()
            # sum(i), not a good example, just a test
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'summation', cd : 'foo' }
                v : [ ]
                b : { t : 'v', n : 'i' }
            } ).toBeNull()

We can build error objects out of anything, as long as we start with a
symbol.

            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'Bad_Gadget_Arm', cd : 'Meh' }
                c : [
                    { t : 'st', v : 'Some explanation could go here.' }
                    { t : 'i', v : 404 }
                ]
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'ErrorWithoutChildren', cd : 'XYZ' }
                c : [ ]
            } ).toBeNull()

We can add valid attributes to any of the above forms.  Here we just sample
a few.

            expect( OMNode.checkJSON {
                t : 'i'
                v : 0
                a : { }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'f'
                v : -3284.352
                a : { '{"t":"sy","n":"A","cd":"B"}' : { t : 'i', v : '5' } }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'st'
                v : ' 1 2 3 4 5 '
                a : {
                    '{"t":"sy","n":"A","cd":"X"}' : { t : 'i', v : '5' }
                    '{"t":"sy","n":"B","cd":"X"}' : { t : 'st', v : 'foo' }
                    '{"t":"sy","n":"C","cd":"X"}' : { t : 'v', n : 'count' }
                }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'ba'
                v : new Uint8Array 1000
                a : { }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'arcsec'
                cd : 'transc1'
                uri : 'http://www.openmath.org/cd'
                a : { '{"t":"sy","n":"A","cd":"B"}' : { t : 'i', v : '5' } }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'v'
                n : 'x'
                a : {
                    '{"t":"sy","n":"A","cd":"X"}' : { t : 'i', v : '5' }
                    '{"t":"sy","n":"B","cd":"X"}' : { t : 'st', v : 'foo' }
                    '{"t":"sy","n":"C","cd":"X"}' : { t : 'v', n : 'count' }
                }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'a'
                c : [
                    { t : 'v', n : 'g' }
                    { t : 'i', v : 3 }
                    { t : 'f', v : -0.1 }
                ]
                a : { }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'ErrorWithoutChildren', cd : 'XYZ' }
                c : [ ]
                a : { '{"t":"sy","n":"A","cd":"B"}' : { t : 'i', v : '5' } }
            } ).toBeNull()
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'summation', cd : 'foo' }
                v : [ ]
                b : { t : 'v', n : 'i' }
                a : {
                    '{"t":"sy","n":"A","cd":"X"}' : { t : 'i', v : '5' }
                    '{"t":"sy","n":"B","cd":"X"}' : { t : 'st', v : 'foo' }
                    '{"t":"sy","n":"C","cd":"X"}' : { t : 'v', n : 'count' }
                }
            } ).toBeNull()

### should find atomic nodes with the wrong form invalid

        it 'should find atomic nodes with the wrong form invalid', ->

Integers can't have keys other than t and v, and their values must look like
numbers.

            expect( OMNode.checkJSON { t : 'i', v : 5, x : 9 } ) \
                .toMatch /Key x not valid in object of type i/
            expect( OMNode.checkJSON { t : 'i', v : 'seven' } ) \
                .toMatch /Not an integer: seven/
            expect( OMNode.checkJSON { t : 'i', v : new Uint8Array } ) \
                .toMatch /Not an integer: \[object Uint8Array\]/

Floats can't have keys other than t and v, and their values must be numbers
passing `isFinite` and failing `isNaN`.

            expect( OMNode.checkJSON { t : 'f', v : -15.9, x : 'thing' } ) \
                .toMatch /Key x not valid in object of type f/
            expect( OMNode.checkJSON { t : 'f', v : '-15.9' } ) \
                .toMatch /Not a number: -15\.9 of type string/
            expect( OMNode.checkJSON { t : 'f', v : Infinity } ) \
                .toMatch /OpenMath floats must be finite/
            expect( OMNode.checkJSON { t : 'f', v : -Infinity } ) \
                .toMatch /OpenMath floats must be finite/
            expect( OMNode.checkJSON { t : 'f', v : NaN } ) \
                .toMatch /OpenMath floats cannot be NaN/

Strings can't have keys other than t and v, and their values must be
strings.

            expect( OMNode.checkJSON { t : 'st', v : 'hi', x : 'bye' } ) \
                .toMatch /Key x not valid in object of type st/
            expect( OMNode.checkJSON { t : 'st', v : 7 } ) \
                .toMatch /Value for st type was number, not string/
            expect( OMNode.checkJSON { t : 'st', v : { } } ) \
                .toMatch /Value for st type was object, not string/

Byte arrays can't have keys other than t and v, and their values must be
Uint8Array instances.

            expect( OMNode.checkJSON {
                t : 'ba'
                v : new Uint8Array
                x : 'bye'
            } ).toMatch /Key x not valid in object of type ba/
            expect( OMNode.checkJSON { t : 'ba', v : 7 } ).toMatch \
                /Value for ba type was not an instance of Uint8Array/
            expect( OMNode.checkJSON { t : 'ba', v : { } } ).toMatch \
                /Value for ba type was not an instance of Uint8Array/

Symbols can't have keys other than t, n, cd, and uri, and they must satisfy
two criteria.
 * all of those keys must have OpenMath strings as their values (although
   the uri key may be omitted)
 * the n and cd keys must have values that are valid OpenMath identifiers

            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'this_is_a'
                cd : 'valid_symbol'
                uri : 'except for the next key'
                aaa : 'aaa'
            } ).toMatch /Key aaa not valid in object of type sy/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'justLikeThePrevious'
                cd : 'butWithoutAnURI'
                aaa : 'aaa'
            } ).toMatch /Key aaa not valid in object of type sy/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : [ 'name', 'invalid', 'type' ]
                cd : 'cd_valid'
                uri : 'uri valid'
            } ).toMatch /Name for sy type was object, not string/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'name_valid'
                cd : [ 'cd', 'invalid', 'type' ]
                uri : 'uri valid'
            } ).toMatch /CD for sy type was object, not string/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'name_valid'
                cd : 'cd_valid'
                uri : [ 'uri', 'invalid', 'type' ]
            } ).toMatch /URI for sy type was object, not string/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'name invalid'
                cd : 'cd_valid'
                uri : 'valid uri'
            } ).toMatch /Invalid identifier as symbol name: name invalid/
            expect( OMNode.checkJSON {
                t : 'sy'
                n : 'name_valid'
                cd : 'cd invalid'
                uri : 'valid uri'
            } ).toMatch /Invalid identifier as symbol CD: cd invalid/

Variables can't have keys other than t and n, and the value for the n key
must have an OpenMath strings as its value that is a valid OpenMath
identifier.

            expect( OMNode.checkJSON {
                t : 'v'
                n : 'validName'
                v : 'this key is not acceptable'
            } ).toMatch /Key v not valid in object of type v/
            expect( OMNode.checkJSON {
                t : 'v'
                n : [ 'name', 'invalid', 'type' ]
            } ).toMatch /Name for v type was object, not string/
            expect( OMNode.checkJSON {
                t : 'v'
                n : 'name invalid'
            } ).toMatch /Invalid identifier as variable name: name invalid/

### should find compound nodes with the wrong form invalid

Applications can't have keys other than t and c, and the value for the c key
must be a nonempty array of valid OpenMath JSON structures.

            expect( OMNode.checkJSON {
                t : 'a'
                c : [ { t : 'i', v : 6 } ]
                v : 'bad'
            } ).toMatch /Key v not valid in object of type a/
            expect( OMNode.checkJSON {
                t : 'a'
                c : 7
            } ).toMatch /Children of application object was not an array/
            expect( OMNode.checkJSON {
                t : 'a'
                c : [ ]
            } ).toMatch /Application object must have at least one child/
            expect( OMNode.checkJSON {
                t : 'a'
                c : [
                    { # valid
                        t : 'i'
                        v : 0
                        a : { }
                    }
                    { # valid
                        t : 'a'
                        c : [
                            { t : 'v', n : 'f' }
                            { t : 'v', n : 'x' }
                        ]
                    }
                    { #invalid
                        t : 'v'
                        n : 'name invalid'
                    }
                ]
            } ).toMatch /Invalid identifier as variable name: name invalid/
            expect( OMNode.checkJSON {
                t : 'a'
                c : [
                    { # valid
                        t : 'i'
                        v : 0
                        a : { }
                    }
                    { # valid at this level, but...
                        t : 'a'
                        c : [
                            { t : 'v', n : 'f' } # valid
                            { t : 'v', n : 'x' } # valid
                            { t : 'i', v : 5, x : 9 } # invalid
                        ]
                    }
                ]
            } ).toMatch /Key x not valid in object of type i/

Bindings can't have keys other than t, s, v, and b.  The s value must be a
symbol, the v value an array of variables, and the b value any OpenMath JSON
structure.

            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        { t : 'v', n : 'x' }
                    ]
                }
                r : 'bad'
            } ).toMatch /Key r not valid in object of type bi/
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'v', n : 'forall' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        { t : 'v', n : 'x' }
                    ]
                }
            } ).toMatch /Head of a binding must be a symbol/
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : 'this is not technically an array'
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        { t : 'v', n : 'x' }
                    ]
                }
            } ).toMatch /In a binding, the v value must be an array/
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : 'this is not an OpenMath JSON structure'
            } ).toMatch /Expected an object, found string/
            expect( OMNode.checkJSON {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : [ { t : 'i', v : 10000 } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        { t : 'v', n : 'x' }
                    ]
                }
            } ).toMatch \
                /In a binding, all values in the v array must have type v/

Errors must have only t, s, and c keys.  The value for s must be a symbol,
the value for c must be an array of OpenMath JSON structures.

            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'peaceOnEarthNotFound', cd : 'foo' }
                c : [
                    { t : 'v', n : 'x' }
                    { t : 'v', n : 'y' }
                ]
                b : 'bad'
            } ).toMatch /Key b not valid in object of type e/
            expect( OMNode.checkJSON {
                t : 'e'
                s : [ ]
                c : [
                    { t : 'v', n : 'x' }
                    { t : 'v', n : 'y' }
                ]
            } ).toMatch /Invalid type: undefined/
            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'v', n : 'w' }
                c : [
                    { t : 'v', n : 'x' }
                    { t : 'v', n : 'y' }
                ]
            } ).toMatch /Head of an error must be a symbol/
            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'peaceOnEarthNotFound', cd : 'foo' }
                c : { t : 'v', n : 'x' }
            } ).toMatch /In an error, the c key must be an array/
            expect( OMNode.checkJSON {
                t : 'e'
                s : { t : 'sy', n : 'peaceOnEarthNotFound', cd : 'foo' }
                c : [
                    { t : 'v', n : 'x', c : [ ] }
                    { t : 'v', n : 'y' }
                ]
            } ).toMatch /Key c not valid in object of type v/

## `OMNode.decode`

This section tests the `OMNode.decode` routine, ensuring that it correctly
constructs `OMNode` instances from their serialized versions, or returns
error messages when that is appropriate.

    describe 'OMNode.decode', ->

### should return errors from invalid JSON

That is, if the input to `decode` is not even valid JSON, then the JSON
parsing error should be returned as a string

        it 'should return errors from invalid JSON', ->
            expect( OMNode.decode 'something' ).toEqual 'Unexpected token s'
            expect( OMNode.decode '{a:"b"}' ).toEqual 'Unexpected token a'
            expect( OMNode.decode '{"a":7 7}' ).toEqual 'Unexpected number'

### should return errors from invalid OpenMath JSON

That is, if the input to `decode` is valid JSON, but the parsed version of
that input does not pass `checkJSON`, then the error from `checkJSON` is
returned.  Here we just a small selection of the tests from earlier in this
file, now compressing the objects into JSON strings.

        it 'should return errors from invalid OpenMath JSON', ->
            expect( OMNode.decode '{"t":"sy","n":"name_valid",' + \
                '"cd":["cd","invalid","type"],"uri":"uri valid"}'
            ).toMatch /CD for sy type was object, not string/
            expect( OMNode.decode '{"t":"i","v":5,"x":9}' ) \
                .toMatch /Key x not valid in object of type i/
            expect( OMNode.decode JSON.stringify {
                t : 'e'
                s : { t : 'sy', n : 'peaceOnEarthNotFound', cd : 'foo' }
                c : [
                    { t : 'v', n : 'x', c : [ ] }
                    { t : 'v', n : 'y' }
                ]
            } ).toMatch /Key c not valid in object of type v/

### should return OMNodes from valid OpenMath JSON

When the input to `decode` is valid JSON that, when parsed, passes the
`checkJSON` test, `decode` should return an OMNode instance.  Here we just
run a few of the valid OpenMath JSON structures from earlier through
`decode` and verify that the result is an instance of `OMNode`.

        it 'should return OMNodes from valid OpenMath JSON', ->
            expect( OMNode.decode( '{"t":"i","v":-335829}' ) \
                instanceof OMNode ).toBeTruthy()
            expect( OMNode.decode( '{
                "t" : "sy",
                "n" : "_",
                "cd" : "dummy-not-real",
                "uri" : "http://www.lurchmath.org"
            }' ) instanceof OMNode ).toBeTruthy()
            expect( OMNode.decode( JSON.stringify( {
                t : 'st'
                v : ' 1 2 3 4 5 '
                a : {
                    '{"t":"sy","n":"A","cd":"X"}' : { t : 'i', v : '5' }
                    '{"t":"sy","n":"B","cd":"X"}' : { t : 'st', v : 'foo' }
                    '{"t":"sy","n":"C","cd":"X"}' : { t : 'v', n : 'count' }
                }
            } ) ) instanceof OMNode ).toBeTruthy()

### should set up parent pointers correctly

Whenever `decode` produces an `OMNode` instance, all nodes in the OpenMath
tree should have `p` (parent) pointers to their container (parent) objects.
The topmost node will a null parent.  This test verifies that.

        it 'should set up parent pointers correctly', ->
            decoded = OMNode.decode '{"t":"i","v":-335829}'
            expect( decoded ).toBeTruthy()
            tree = decoded.tree
            expect( tree ).toBeTruthy()
            expect( tree.p ).toBeNull()
            decoded = OMNode.decode '{
                "t" : "sy",
                "n" : "_",
                "cd" : "dummy-not-real",
                "uri" : "http://www.lurchmath.org"
            }'
            expect( decoded ).toBeTruthy()
            tree = decoded.tree
            expect( tree ).toBeTruthy()
            expect( tree.p ).toBeNull()
            decoded = OMNode.decode JSON.stringify {
                t : 'st'
                v : ' 1 2 3 4 5 '
                a : {
                    '{"t":"sy","n":"A","cd":"X"}' : { t : 'i', v : '5' }
                    '{"t":"sy","n":"B","cd":"X"}' : { t : 'st', v : 'foo' }
                    '{"t":"sy","n":"C","cd":"X"}' : { t : 'v', n : 'count' }
                }
            }
            expect( decoded ).toBeTruthy()
            tree = decoded.tree
            expect( tree ).toBeTruthy()
            expect( tree.p ).toBeNull()
            expect( tree.a['{"t":"sy","n":"A","cd":"X"}'].p ).toBe tree
            expect( tree.a['{"t":"sy","n":"B","cd":"X"}'].p ).toBe tree
            expect( tree.a['{"t":"sy","n":"C","cd":"X"}'].p ).toBe tree
            decoded = OMNode.decode JSON.stringify {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'example' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'P' }
                        {
                            t : 'a'
                            c : [
                                { t : 'v', n : 'f' }
                                { t : 'v', n : 'x' }
                            ]
                        }
                        { t : 'v', n : 'y' }
                    ]
                }
            }
            expect( decoded ).toBeTruthy()
            tree = decoded.tree
            expect( tree ).toBeTruthy()
            expect( tree.p ).toBeNull()
            expect( tree.s.p ).toBe tree
            expect( tree.v[0].p ).toBe tree
            expect( tree.b.p ).toBe tree
            expect( tree.b.c[0].p ).toBe tree.b
            expect( tree.b.c[1].p ).toBe tree.b
            expect( tree.b.c[2].p ).toBe tree.b
            expect( tree.b.c[1].c[0].p ).toBe tree.b.c[1]
            expect( tree.b.c[1].c[1].p ).toBe tree.b.c[1]

## `OMNode.encode`

    describe 'OMNode.encode', ->

This function should be the inverse to `decode`, tested above.  Because
`decode` adds parent pointers, which make it harder to check equality of two
structures, we test as follows:
 * Take a valid OpenMath JSON object
 * Apply JSON.stringify to it
 * Apply OMNode.decode to the resulting JSON string
 * Apply OMNode.encode to the resulting OMNode
 * Apply JSON.parse to the resulting string
 * Compare this last JSON object to the first for structural equality

### should correctly invert `OMNode.decode`

This test just does the above procedure on several valid input structures,
all taken from the first tests in this file.

        it 'should correctly invert OMNode.decode', ->

The integer -1:

            structure1 = { t : 'i', v : '-1' }
            string1 = JSON.stringify structure1
            node = OMNode.decode string1
            string2 = node.encode()
            structure2 = JSON.parse string2
            expect( structure1 ).toEqual structure2

A long string:

            structure1 = {
                t : 'st'
                v : "In the first survey question, respondents were asked to name the desired characteristics of a top predictive modeler. The top answer was 'good business knowledge,' followed closely by 'understanding of statistics.' Other popular responses were 'avid learner,' 'communicating results,' 'data expertise,' and 'good programmer.'"
            }
            string1 = JSON.stringify structure1
            node = OMNode.decode string1
            string2 = node.encode()
            structure2 = JSON.parse string2
            expect( structure1 ).toEqual structure2

An application:

            structure1 = {
                t : 'a'
                c : [
                    { t : 'v', n : 'g' }
                    { t : 'i', v : 3 }
                    { t : 'f', v : -0.1 }
                ]
            }
            string1 = JSON.stringify structure1
            node = OMNode.decode string1
            string2 = node.encode()
            structure2 = JSON.parse string2
            expect( structure1 ).toEqual structure2

A nested binding:

            structure1 = {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'example' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'bi'
                    s : { t : 'sy', n : 'exists', cd : 'example' }
                    v : [ { t : 'v', n : 'z' } ]
                    b : {
                        t : 'a'
                        c : [
                            { t : 'sy', n : 'greaterThan', cd : 'example' }
                            { t : 'v', n : 'x' }
                            { t : 'v', n : 'z' }
                        ]
                    }
                }
            }
            string1 = JSON.stringify structure1
            node = OMNode.decode string1
            string2 = node.encode()
            structure2 = JSON.parse string2
            expect( structure1 ).toEqual structure2

A symbol with an attribute:

            structure1 = {
                t : 'sy'
                n : 'arcsec'
                cd : 'transc1'
                uri : 'http://www.openmath.org/cd'
                a : { '{"t":"sy","n":"A","cd":"B"}' : { t : 'i', v : '5' } }
            }
            string1 = JSON.stringify structure1
            node = OMNode.decode string1
            string2 = node.encode()
            structure2 = JSON.parse string2
            expect( structure1 ).toEqual structure2
