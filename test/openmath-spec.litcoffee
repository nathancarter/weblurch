
# Tests of the OpenMath module

Here we import the module we're about to test, plus a utilities module for
comparing JSON structures.  (That module is tested [in a separate
file](utils-spec.litcoffee).)

    { OM, OMNode } = require '../src/openmath.duo'
    require '../src/utils'

## `OMNode` class

This section verifies that the OMNode class is defined, and some of its
methods are also.

    describe 'OMNode class', ->
        it 'should be defined, with its methods', ->
            expect( OMNode ).toBeTruthy()
            expect( OMNode.checkJSON ).toBeTruthy()
            expect( OMNode.decode ).toBeTruthy()
            expect( OM ).toBeTruthy()
            expect( OM.checkJSON ).toBeTruthy()
            expect( OM.decode ).toBeTruthy()

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

## Factory functions

    describe 'Factory functions', ->

We verify here that there are factory functions that work for each OpenMath
type, having both long-form names (e.g., "symbol" and "application") as well
as short-form names (e.g., "sym" and "app").

### should support long-form names

This test ensures that a few calls to each of the following functions
produce OMNode instances with the expected JSON objects.
 * integer
 * float
 * string
 * bytearray
 * symbol
 * variable
 * application
 * attribution
 * binding
 * error

        it 'should support long-form names', ->

Integers with correct data.

            node = OM.integer 5
            expect( JSON.parse node.encode() ).toEqual { t : 'i', v : 5 }
            node = OM.integer '-5872935432043289'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'i', v : '-5872935432043289' }

An invalid integer.

            expect( OM.integer 'five' ).toMatch /Not an integer/

Float with correct data.

            node = OM.float 5.573289
            expect( JSON.parse node.encode() ).toEqual {
                t : 'f', v : 5.573289 }

An invalid float.

            expect( OM.float 'five point stuff' ).toMatch /Not a number/

Strings with correct data.

            node = OM.string ''
            expect( JSON.parse node.encode() ).toEqual { t : 'st', v : '' }
            node = OM.string 'Hello there'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'st', v : 'Hello there' }
            node = OM.string { }.toString()
            expect( JSON.parse node.encode() ).toEqual {
                t : 'st', v : '[object Object]' }

An invalid string.

            expect( OM.string null ).toMatch /Value for st type was/

Byte arrays with correct data.

            node = OM.bytearray new Uint8Array
            expect( JSON.parse node.encode() ).toEqual {
                t : 'ba', v : new Uint8Array }
            node = OM.bytearray new Uint8Array [ 3, 1, 4, 1, 5, 9 ]
            expect( JSON.parse node.encode() ).toEqual {
                t : 'ba'
                v : new Uint8Array [ 3, 1, 4, 1, 5, 9 ]
            }

An invalid byte array.

            expect( OM.bytearray [ 1, 2, 3 ] ).toMatch /not an instance of/

Symbols with correct data.

            node = OM.symbol 'name', 'cd'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'sy', n : 'name', cd : 'cd' }
            node = OM.symbol 'a', 'b', 'c'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'sy'
                n : 'a'
                cd : 'b'
                uri : 'c'
            }

A few invalid symbols.

            expect( OM.symbol 'x' ).toMatch /CD for sy type/
            expect( OM.symbol 1, 2 ).toMatch /Name for sy type/
            expect( OM.symbol 'valid', 'in valid' ).toMatch \
                /Invalid identifier/

Variables with correct data.

            node = OM.variable 'humperdink'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'v', n : 'humperdink' }
            node = OM.variable 'X'
            expect( JSON.parse node.encode() ).toEqual { t : 'v', n : 'X' }

A few invalid variables.

            expect( OM.variable 'stop saying that name' ).toMatch \
                /Invalid identifier/
            expect( OM.variable 'i\'m not listening' ).toMatch \
                /Invalid identifier/
            expect( OM.variable '' ).toMatch /Invalid identifier/

Applications with correct contents.

            node = OM.application OM.variable( 'f' ), OM.variable( 'x' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'v', n : 'f' }
                    { t : 'v', n : 'x' }
                ]
            }
            node = OM.application OM.symbol( 'a', 'b' ), OM.integer( 3 ),
                OM.application OM.variable( 'g' ), OM.float( 7.7 )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'sy', n : 'a', cd : 'b' }
                    { t : 'i', v : 3 }
                    {
                        t : 'a'
                        c : [
                            { t : 'v', n : 'g' }
                            { t : 'f', v : 7.7 }
                        ]
                    }
                ]
            }

A few invalid applications.

            expect( OM.application() ).toMatch /must have at least one/
            expect( OM.application 'not', 'OM', 'nodes' ).toMatch \
                /Expected an object/

Attributions with correct contents.

            node = OM.attribution OM.integer( -300 ),
                OM.symbol( 'isNegative', 'foo' ), OM.string( 'true' ),
                OM.symbol( 'isEnormous', 'foo' ), OM.string( 'false' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'i'
                v : -300
                a : {
                    '{"t":"sy","n":"isNegative","cd":"foo"}' :
                        { t : 'st', v : 'true' }
                    '{"t":"sy","n":"isEnormous","cd":"foo"}' :
                        { t : 'st', v : 'false' }
                }
            }
            node = OM.attribution OM.application OM.variable 'f'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [ { t : 'v', n : 'f' } ]
            }

A few invalid attributions.

            expect( OM.attribution() ).toMatch /Invalid first parameter/
            expect( OM.attribution OM.variable( 'x' ),
                                   OM.variable( 'y' ) ).toMatch \
                /Incomplete key-value pair/
            expect( OM.attribution OM.variable( 'x' ), OM.variable( 'y' ),
                                   OM.variable( 'z' ) ).toMatch \
                /Key (.*) is not a symbol/

Bindings with correct contents.

            node = OM.binding OM.symbol( 'exists', 'logic' ),
                OM.variable( 'x' ),
                OM.application OM.variable( 'Q' ), OM.variable( 'x' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'exists', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'Q' }
                        { t : 'v', n : 'x' }
                    ]
                }
            }
            node = OM.application OM.symbol( 'and', 'logic' ),
                OM.binding( OM.symbol( 'exists', 'logic' ),
                    OM.variable( 'x' ),
                    OM.application OM.variable( 'Q' ), OM.variable( 'x' ) ),
                OM.variable( 'Other' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'sy', n : 'and', cd : 'logic' }
                    {
                        t : 'bi'
                        s : { t : 'sy', n : 'exists', cd : 'logic' }
                        v : [ { t : 'v', n : 'x' } ]
                        b : {
                            t : 'a'
                            c : [
                                { t : 'v', n : 'Q' }
                                { t : 'v', n : 'x' }
                            ]
                        }
                    }
                    { t : 'v', n : 'Other' }
                ]
            }
            node = OM.binding OM.symbol( 'exists', 'logic' ),
                OM.variable( 'x' ),
                OM.application( OM.symbol( 'and', 'logic' ),
                    OM.application( OM.variable( 'Q' ),
                                    OM.variable( 'x' ) ),
                    OM.variable( 'Other' ) )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'exists', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'sy', n : 'and', cd : 'logic' }
                        {
                            t : 'a'
                            c : [
                                { t : 'v', n : 'Q' }
                                { t : 'v', n : 'x' }
                            ]
                        }
                        { t : 'v', n : 'Other' }
                    ]
                }
            }
            node = OM.binding OM.symbol( 'a', 'b' ), OM.variable( 'x' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'a', cd : 'b' }
                v : [ ]
                b : { t : 'v', n : 'x' }
            }
            node = OM.binding OM.symbol( 'lambda', 'foo' ),
                OM.variable( 'x' ), OM.variable( 'y' ),
                OM.application( OM.symbol( 'plus', 'arith1' ),
                    OM.variable( 'x' ), OM.variable( 'y' ) )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'lambda', cd : 'foo' }
                v : [ { t : 'v', n : 'x' }, { t : 'v', n : 'y' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'sy', n : 'plus', cd : 'arith1' }
                        { t : 'v', n : 'x' }
                        { t : 'v', n : 'y' }
                    ]
                }
            }

A few invalid bindings.

            expect( OM.binding() ).toMatch /Invalid first parameter/
            expect( OM.binding 'not', 'OM', 'nodes' ).toMatch \
                /Invalid first parameter/
            expect( OM.binding OM.symbol 'a', 'b' ).toMatch \
                /Invalid last parameter/
            expect( OM.binding OM.symbol( 'a', 'b' ), OM.integer( 3 ),
                OM.variable( 'z' ) ).toMatch /must have type v/

Errors with correct structure.

            node = OM.error OM.symbol( 'ex', 'ample' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'e'
                s : { t : 'sy', n : 'ex', cd : 'ample' }
                c : [ ]
            }
            node = OM.error OM.symbol( 'ex', 'ample' ),
                OM.string( 'param1' ), OM.variable( 'param2' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'e'
                s : { t : 'sy', n : 'ex', cd : 'ample' }
                c : [
                    { t : 'st', v : 'param1' }
                    { t : 'v', n : 'param2' }
                ]
            }

A few invalid errors.

            expect( OM.error() ).toMatch /Invalid first parameter/
            expect( OM.error OM.string 'foo' ).toMatch /must be a symbol/

### should support short-form names

        it 'should support short-form names', ->

This test just re-runs a small selection of those from the previous test
case, but now using short-form names in place of their long-form
counterparts.

            node = OM.int 5
            expect( JSON.parse node.encode() ).toEqual { t : 'i', v : 5 }
            expect( OM.flo 'five point stuff' ).toMatch /Not a number/
            node = OM.str 'Hello there'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'st', v : 'Hello there' }
            expect( OM.byt [ 1, 2, 3 ] ).toMatch /not an instance of/
            node = OM.sym 'name', 'cd'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'sy', n : 'name', cd : 'cd' }
            expect( OM.var '' ).toMatch /Invalid identifier/
            node = OM.app OM.sym( 'a', 'b' ), OM.int( 3 ),
                OM.app OM.var( 'g' ), OM.flo( 7.7 )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'sy', n : 'a', cd : 'b' }
                    { t : 'i', v : 3 }
                    {
                        t : 'a'
                        c : [
                            { t : 'v', n : 'g' }
                            { t : 'f', v : 7.7 }
                        ]
                    }
                ]
            }
            expect( OM.att OM.var( 'x' ), OM.var( 'y' ) ).toMatch \
                /Incomplete key-value pair/
            node = OM.bin OM.sym( 'exists', 'logic' ), OM.var( 'x' ),
                OM.app OM.var( 'Q' ), OM.var( 'x' )
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'exists', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [
                        { t : 'v', n : 'Q' }
                        { t : 'v', n : 'x' }
                    ]
                }
            }
            expect( OM.err OM.str 'foo' ).toMatch /must be a symbol/

## Simple encoding and decoding

    describe 'Simple encoding and decoding', ->

These tests test the functions `node.simpleEncode()` and
`OMNode.simpleDecode()`.  These are analogous to `node.encode()` and
`OMNode.decode()`, but are different in two ways.
 * They are much easier to use.
 * They support only a subset of the full functionality.
See their documentation for more details.

### should decode valid simple forms

We provide several valid string inputs to `OMNode.simpleDecode()` and verify
that they all generate the expected `OMNode` structures.

        it 'should decode valid simple forms', ->

We begin with atomic forms.

            node = OM.simple '3'
            expect( JSON.parse node.encode() ).toEqual { t : 'i', v : 3 }
            node = OM.simple '-473825903'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'i', v : -473825903 }
            node = OM.simple '47354735436545463546825903'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'i', v : '47354735436545463546825903' }
            node = OM.simple '5784.58309'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'f', v : 5784.58309 }
            node = OM.simple '-.01'
            expect( JSON.parse node.encode() ).toEqual { t : 'f', v : -.01 }
            node = OM.simple 'thing1.thing2'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'sy', n : 'thing2', cd : 'thing1' }
            node = OM.simple 'arith1.plus'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'sy', n : 'plus', cd : 'arith1' }
            node = OM.simple 'x'
            expect( JSON.parse node.encode() ).toEqual { t : 'v', n : 'x' }
            node = OM.simple 'holierThanThou'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'v', n : 'holierThanThou' }
            node = OM.simple '"wonderful"'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'st', v : 'wonderful' }
            node = OM.simple '"It\'s a \\"Wonderful\\" Life"'
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'st', v : 'It\'s a "Wonderful" Life' }
            node = OM.simple '\'It\\\'s a "Wonderful" Life\''
            expect( JSON.parse node.encode() ).toEqual \
                { t : 'st', v : 'It\'s a "Wonderful" Life' }

Now we consider applications and bindings, as well as nesting thereof, and
even the application of applications to other arguments.

            node = OM.simple 'f(x,y,300)'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'v', n : 'f' }
                    { t : 'v', n : 'x' }
                    { t : 'v', n : 'y' }
                    { t : 'i', v : 300 }
                ]
            }
            node = OM.simple 'logic.forall[x,P(x)]'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : [ { t : 'v', n : 'x' } ]
                b : {
                    t : 'a'
                    c : [ { t : 'v', n : 'P' }, { t : 'v', n : 'x' } ]
                }
            }
            node = OM.simple 'A.B(g(c),h.k[i,i(1)])'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    { t : 'sy', n : 'B', cd : 'A' }
                    {
                        t : 'a'
                        c : [
                            { t : 'v', n : 'g' }
                            { t : 'v', n : 'c' }
                        ]
                    }
                    {
                        t : 'bi'
                        s : { t : 'sy', n : 'k', cd : 'h' }
                        v : [ { t : 'v', n : 'i' } ]
                        b : {
                            t : 'a'
                            c : [ { t : 'v', n : 'i' }, { t : 'i', v : 1 } ]
                        }
                    }
                ]
            }
            node = OM.simple 'F(x)(y)'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [
                    {
                        t : 'a'
                        c : [
                            { t : 'v', n : 'F' }
                            { t : 'v', n : 'x' }
                        ]
                    }
                    { t : 'v', n : 'y' }
                ]
            }
            node = OM.simple 'zero_args_is_okay()'
            expect( JSON.parse node.encode() ).toEqual {
                t : 'a'
                c : [ { t : 'v', n : 'zero_args_is_okay' } ]
            }

### should give errors when decoding invalid simple forms

We provide several invalid string inputs to `OMNode.simpleDecode()` and
verify that a suitable error message is returned in each case.

        it 'should give errors when decoding invalid simple forms', ->

Invalid atomics.

            expect( OM.simple 'spaces disallowed' ).toMatch \
                /Could not understand from here:  dis/
            expect( OM.simple '1.2.3' ).toMatch /Unexpected \.3/
            expect( OM.simple '"string"oops"' ).toMatch \
                /Could not understand from here: "/
            expect( OM.simple 'invalid.1' ).toMatch /Unexpected \.1/
            expect( OM.simple 'f(--3)' ).toMatch \
                /Could not understand from here: --3/
            expect( OM.simple 'thing.' ).toMatch \
                /Could not understand from here: \./

Invalid compound expressions.

            expect( OM.simple 'f(x' ).toMatch /Unexpected end of input/
            expect( OM.simple 'f(x]' ).toMatch /Mismatch: \(/
            expect( OM.simple 'f[x)' ).toMatch /Mismatch: \[/
            expect( OM.simple 'f[x,y]' ).toMatch \
                /Head of a binding must be a symbol/
            expect( OM.simple 'example.symbol[3,9]' ).toMatch \
                /all values in the v array must have type v/
            expect( OM.simple 'hark(the,,herald)' ).toMatch /Unexpected ,/
            expect( OM.simple 'once(upon,)' ).toMatch /Unexpected \)/
            expect( OM.simple '(x)' ).toMatch /Unexpected \(/
            expect( OM.simple 'f((x))' ).toMatch /Unexpected \(/
            expect( OM.simple 'f(g(x)' ).toMatch /Unexpected end of input/
            expect( OM.simple 'x,y,z' ).toMatch /Unexpected end of input/

### should encode valid simple forms

We take several `OMNode` instances that can be encoded using the simple
encoding, and call `encode()` in each, verifying that they produce the
expected string output in each case.

        it 'should encode valid simple forms', ->

Atomic cases first.

            node = OM.decode { t : 'i', v : 12345 }
            expect( node.simpleEncode() ).toEqual '12345'
            node = OM.decode { t : 'f', v : -123.45 }
            expect( node.simpleEncode() ).toEqual '-123.45'
            node = OM.decode { t : 'v', n : 'variable' }
            expect( node.simpleEncode() ).toEqual 'variable'
            node = OM.decode { t : 'st', v : 'thinking about you, love' }
            expect( node.simpleEncode() ).toEqual \
                "'thinking about you, love'"
            node = OM.decode { t : 'st', v : 'something in "quotes"' }
            expect( node.simpleEncode() ).toEqual \
                "'something in \"quotes\"'"
            node = OM.decode { t : 'st', v : 'something isn\'t right' }
            expect( node.simpleEncode() ).toEqual \
                "'something isn\\'t right'"
            node = OM.decode { t : 'sy', n : 'times', cd : 'arith1' }
            expect( node.simpleEncode() ).toEqual 'arith1.times'

Compound cases second.

            node = OM.decode {
                t : 'a'
                c : [
                    { t : 'v', n : 'Gamma' }
                    { t : 'i', v : 7 }
                    {
                        t : 'a'
                        c : [
                            { t : 'sy', n : 'plus', cd : 'arith1' }
                            { t : 'v', n : 'y' }
                            { t : 'f', v : 0.05 }
                        ]
                    }
                ]
            }
            expect( node.simpleEncode() ).toEqual \
                'Gamma(7,arith1.plus(y,0.05))'
            node = OM.decode {
                t : 'bi'
                s : { t : 'sy', n : 'forall', cd : 'logic' }
                v : [ { t : 'v', n : 'a' }, { t : 'v', n : 'b' } ]
                b : {
                    t : 'bi'
                    s : { t : 'sy', n : 'exists', cd : 'logic' }
                    v : [ { t : 'v', n : 'c' } ]
                    b : {
                        t : 'a'
                        c : [
                            { t : 'sy', n : 'lessthan', cd : 'whatever' }
                            { t : 'v', n : 'a' }
                            { t : 'v', n : 'c' }
                            { t : 'v', n : 'b' }
                        ]
                    }
                }
            }
            expect( node.simpleEncode() ).toEqual \
                'logic.forall[a,b,logic.exists[c,whatever.lessthan(a,c,b)]]'

### should give errors when encoding invalid simple forms

We take several `OMNode` instances that cannot be encoded using the simple
encoding, and call `encode()` in each, verifying that a suitable error is
thrown in each case.

        it 'should give errors when encoding invalid simple forms', ->

Variables with dots in their names conflict with the naming of symbols in
the simple encoding, but will be encoded as their names.

            node = OM.decode { t : 'v', n : 'looksLike.aSymbol' }
            expect( node.simpleEncode() ).toEqual 'looksLike.aSymbol'
            node = OM.decode { t : 'v', n : 't.o.o.m.a.n.y.d.o.t.s' }
            expect( node.simpleEncode() ).toEqual 't.o.o.m.a.n.y.d.o.t.s'

Symbols will be correctly encoded with the exception that any URI will be
dropped, and the same issue with dots applies to symbol and CD names.

            node = OM.decode {
                t : 'sy'
                n : 'name'
                cd : 'cd'
                uri : 'this will be dropped'
            }
            expect( node.simpleEncode() ).toEqual 'cd.name'
            node = OM.decode {
                t : 'sy'
                n : 'na.me'
                cd : 'cd.with.dots'
                uri : 'this will be dropped'
            }
            expect( node.simpleEncode() ).toEqual 'cd.with.dots.na.me'
            node = OM.decode {
                t : 'sy'
                n : 'name.17'
                cd : 'cd.dvd.bluray'
            }
            expect( node.simpleEncode() ).toEqual 'cd.dvd.bluray.name.17'

Byte arrays and errors have no simple encoding, and will thus all be
converted to a string containing the words "byte array" or "error,"
respectively.

            node = OM.decode { t : 'ba', v : new Uint8Array }
            expect( node.simpleEncode() ).toEqual "'byte array'"
            node = OM.decode { t : 'ba', v : new Uint8Array 100 }
            expect( node.simpleEncode() ).toEqual "'byte array'"
            node = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'error-name', cd : 'error-cd' }
                c : [ ]
            }
            expect( node.simpleEncode() ).toEqual "'error'"
            node = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'does', cd : 'not' }
                c : [
                    { t : 'v', n : 'matter' }
                    { t : 'st', v : 'what we put here' }
                ]
            }
            expect( node.simpleEncode() ).toEqual "'error'"

All attributions are dropped.

            node = OM.decode {
                t : 'i'
                v : 10000
                a : {
                    '{"t":"sy","n":"foo","cd":"bar"}' : { t : 'i', v : 3 }
                    '{"t":"sy","n":"baz","cd":"bar"}' : { t : 'i', v : 4 }
                    '{"t":"sy","n":"bash","cd":"bar"}' : { t : 'i', v : 5 }
                }
            }
            expect( node.simpleEncode() ).toEqual "10000"
            node = OM.decode {
                t : 'st'
                v : 'a long long time ago'
                a : {
                    '{"t":"sy","n":"foo","cd":"bar"}' : { t : 'i', v : 3 }
                    '{"t":"sy","n":"baz","cd":"bar"}' : { t : 'i', v : 4 }
                    '{"t":"sy","n":"bash","cd":"bar"}' : { t : 'i', v : 5 }
                }
            }
            expect( node.simpleEncode() ).toEqual "'a long long time ago'"
            node = OM.decode {
                t : 'a'
                c : [
                    { t : 'v', n : 'f' }
                    {
                        t : 'f'
                        v : 19.95
                        a : {
                            '{"t":"sy","n":"foo","cd":"bar"}' :
                                { t : 'i', v : 3 }
                            '{"t":"sy","n":"baz","cd":"bar"}' :
                                { t : 'i', v : 4 }
                            '{"t":"sy","n":"bash","cd":"bar"}' :
                                { t : 'i', v : 5 }
                        }
                    }
                ]
            }
            expect( node.simpleEncode() ).toEqual "f(19.95)"

## `OMNode` getters

`OMNode` instances have getters for type, value, name, cd, uri, symbol,
body, children, and variables.  This section ensures that they function as
desired for a sample of different kinds of OMNode structures.

    describe 'OMNode getters', ->

### should return values for properties the structure has

Here we create OMNode structures of each type test only those properties
that the structure is supposed to have, e.g., variables are supposed to have
a type and a name, so we don't test (until later, below) for any of its
other properties.

        it 'should return values for properties the structure has', ->

Integers, floats, strings, and byte arrays have type and value.

            node = OM.simple '5'
            expect( node.type ).toBe 'i'
            expect( node.value ).toBe 5
            node = OM.simple '5.5'
            expect( node.type ).toBe 'f'
            expect( node.value ).toBe 5.5
            node = OM.simple '"thing"'
            expect( node.type ).toBe 'st'
            expect( node.value ).toBe 'thing'
            node = OM.decode { t : 'ba', v : new Uint8Array [ 1, 2, 3 ] }
            expect( node.type ).toBe 'ba'
            expect( node.value[0] ).toBe 1
            expect( node.value[1] ).toBe 2
            expect( node.value[2] ).toBe 3

Symbols have type, name, cd, and sometimes uri.

            node = OM.simple 'foo.bar'
            expect( node.type ).toBe 'sy'
            expect( node.name ).toBe 'bar'
            expect( node.cd ).toBe 'foo'
            expect( node.uri ).toBeUndefined()
            node = OM.decode { t : 'sy', n : 'one', cd : 'two', uri : '3' }
            expect( node.type ).toBe 'sy'
            expect( node.name ).toBe 'one'
            expect( node.cd ).toBe 'two'
            expect( node.uri ).toBe '3'

Variables have type and name.

            node = OM.simple 'foo'
            expect( node.type ).toBe 'v'
            expect( node.name ).toBe 'foo'

Applications have a type and a children array.

            node = OM.simple 'f(x,y,z)'
            expect( node.type ).toBe 'a'
            expect( node.children.length ).toBe 4
            expect( node.children[0].type ).toBe 'v'
            expect( node.children[0].name ).toBe 'f'
            expect( node.children[1].type ).toBe 'v'
            expect( node.children[1].name ).toBe 'x'
            expect( node.children[2].type ).toBe 'v'
            expect( node.children[2].name ).toBe 'y'
            expect( node.children[3].type ).toBe 'v'
            expect( node.children[3].name ).toBe 'z'

Bindings have a symbol, a variable list, and a body.

            node = OM.simple 'f.g[x,y,z]'
            expect( node.type ).toBe 'bi'
            expect( node.symbol.type ).toBe 'sy'
            expect( node.symbol.name ).toBe 'g'
            expect( node.symbol.cd ).toBe 'f'
            expect( node.symbol.uri ).toBeUndefined()
            expect( node.variables.length ).toBe 2
            expect( node.variables[0].type ).toBe 'v'
            expect( node.variables[0].name ).toBe 'x'
            expect( node.variables[1].type ).toBe 'v'
            expect( node.variables[1].name ).toBe 'y'
            expect( node.body.type ).toBe 'v'
            expect( node.body.name ).toBe 'z'

Errors have a symbol and children.

            node = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'cos', cd : 'transc1' }
                c : [ { t : 'st', v : 'some content here' } ]
            }
            expect( node.type ).toBe 'e'
            expect( node.symbol.type ).toBe 'sy'
            expect( node.symbol.name ).toBe 'cos'
            expect( node.symbol.cd ).toBe 'transc1'
            expect( node.symbol.uri ).toBeUndefined()
            expect( node.children.length ).toBe 1
            expect( node.children[0].type ).toBe 'st'
            expect( node.children[0].value ).toBe 'some content here'

### should return undefined for properties the structure doesn't have

Here we create OMNode structures of each type test only those properties
that the structure is *not* supposed to have, e.g., variables are supposed
to have a type and a name, so we query properties like symbol and value and
ensure that they are undefined, or properties like children and ensure that
they are an empty array.

        it 'should return undefined for properties the structure doesn\'t
        have', ->

Integers, floats, strings, and byte arrays do not have name, cd, uri,
symbol, body, children, or variables.

            node = OM.simple '5'
            expect( node.name ).toBeUndefined()
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.children ).toEqual [ ]
            expect( node.variables ).toEqual [ ]
            node = OM.simple '5.5'
            expect( node.name ).toBeUndefined()
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.children ).toEqual [ ]
            expect( node.variables ).toEqual [ ]
            node = OM.simple '"thing"'
            expect( node.name ).toBeUndefined()
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.children ).toEqual [ ]
            expect( node.variables ).toEqual [ ]

Symbols do not have value, symbol, body, children, or variables.

            node = OM.simple 'cd.name'
            expect( node.value ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.children ).toEqual [ ]
            expect( node.variables ).toEqual [ ]

Variables do not have cd, uri, value, symbol, body, children, or variables.

            node = OM.simple 'var'
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.value ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.children ).toEqual [ ]
            expect( node.variables ).toEqual [ ]

Applications do not have name, cd, uri, value, symbol, body, or variables.

            node = OM.simple 'f(x)'
            expect( node.name ).toBeUndefined()
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.value ).toBeUndefined()
            expect( node.symbol ).toBeUndefined()
            expect( node.body ).toBeUndefined()
            expect( node.variables ).toEqual [ ]

Bindings do not have name, cd, uri, value, or children.

            node = OM.simple 'f.g[x,y]'
            expect( node.name ).toBeUndefined()
            expect( node.cd ).toBeUndefined()
            expect( node.uri ).toBeUndefined()
            expect( node.value ).toBeUndefined()
            expect( node.children ).toEqual [ ]

## Comparing structures

We can compare two `OMNode` instances for structural equality with their
`equals` member function.  We test it here.

    describe 'Comparing structures', ->

### should return true for equal atomics

We restrict ourselves only two atomic-type `OMNode` instances here, and only
verify that the function returns true when the objects have the same
contents, whether or not they are the same object.

        it 'should return true for equal atomics', ->

Integers:

            lhs = OM.simple '5'
            rhs = OM.simple '5'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Floats:

            lhs = OM.simple '-0.01'
            rhs = OM.simple '-0.01'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Strings:

            lhs = OM.simple '"jfkldsfjls"'
            rhs = OM.simple '"jfkldsfjls"'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Byte arrays:

            lhs = OM.decode { t : 'ba', v : new Uint8Array [ 9, 8, 50 ] }
            rhs = OM.decode { t : 'ba', v : new Uint8Array [ 9, 8, 50 ] }
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Symbols:

            lhs = OM.simple 'harry.truman'
            rhs = OM.simple 'harry.truman'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Variables:

            lhs = OM.simple 'harry'
            rhs = OM.simple 'harry'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

### should return false for unequal atomics

Here we add some complexity over the previous test by comparing not only
unequal atomics of the same type, but a sampling of the possible cross-type
comparisons as well.

        it 'should return false for unequal atomics', ->

Integers:

            lhs_i = OM.simple '5'
            rhs_i = OM.simple '7'
            expect( lhs_i.equals lhs_i ).toBeTruthy()
            expect( rhs_i.equals rhs_i ).toBeTruthy()
            expect( lhs_i.equals rhs_i ).toBeFalsy()

Floats:

            lhs_f = OM.simple '-0.01'
            rhs_f = OM.simple '8723.11'
            expect( lhs_f.equals lhs_f ).toBeTruthy()
            expect( rhs_f.equals rhs_f ).toBeTruthy()
            expect( lhs_f.equals rhs_f ).toBeFalsy()
            expect( lhs_f.equals rhs_i ).toBeFalsy()

Strings:

            lhs_st = OM.simple '"jfkldsfjls"'
            rhs_st = OM.simple '"jfkfjls"'
            expect( lhs_st.equals lhs_st ).toBeTruthy()
            expect( rhs_st.equals rhs_st ).toBeTruthy()
            expect( lhs_st.equals rhs_st ).toBeFalsy()
            expect( lhs_st.equals rhs_f ).toBeFalsy()
            expect( lhs_st.equals rhs_i ).toBeFalsy()

Byte arrays:

            lhs_ba = OM.decode { t : 'ba', v : new Uint8Array [ 9, 8, 50 ] }
            rhs_ba = OM.decode { t : 'ba', v : new Uint8Array [ 9, 8, 51 ] }
            expect( lhs_ba.equals lhs_ba ).toBeTruthy()
            expect( rhs_ba.equals rhs_ba ).toBeTruthy()
            expect( lhs_ba.equals rhs_ba ).toBeFalsy()
            expect( lhs_ba.equals rhs_st ).toBeFalsy()
            expect( lhs_ba.equals rhs_f ).toBeFalsy()
            expect( lhs_ba.equals rhs_i ).toBeFalsy()

Symbols:

            lhs_sy = OM.simple 'harry.truman'
            rhs_sy = OM.simple 'alben.barkley'
            expect( lhs_sy.equals lhs_sy ).toBeTruthy()
            expect( rhs_sy.equals rhs_sy ).toBeTruthy()
            expect( lhs_sy.equals rhs_sy ).toBeFalsy()
            expect( lhs_sy.equals rhs_ba ).toBeFalsy()
            expect( lhs_sy.equals rhs_st ).toBeFalsy()
            expect( lhs_sy.equals rhs_f ).toBeFalsy()
            expect( lhs_sy.equals rhs_i ).toBeFalsy()

Variables:

            lhs_v = OM.simple 'harry'
            rhs_v = OM.simple 'truman'
            expect( lhs_v.equals lhs_v ).toBeTruthy()
            expect( rhs_v.equals rhs_v ).toBeTruthy()
            expect( lhs_v.equals rhs_v ).toBeFalsy()
            expect( lhs_v.equals rhs_sy ).toBeFalsy()
            expect( lhs_v.equals rhs_ba ).toBeFalsy()
            expect( lhs_v.equals rhs_st ).toBeFalsy()
            expect( lhs_v.equals rhs_f ).toBeFalsy()
            expect( lhs_v.equals rhs_i ).toBeFalsy()

### should return true for equal compounds

Just like the test for equal atomics, but now we're building application and
binding trees instead, as well as error objects.

        it 'should return true for equal compounds', ->

Applications:

            lhs = OM.simple 'f(g(x,y),too.tee)'
            rhs = OM.simple 'f(g(x,y),too.tee)'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Bindings:

            lhs = OM.simple 'logic.forall[x,logic.exists[y,Q(x,y)]]'
            rhs = OM.simple 'logic.forall[x,logic.exists[y,Q(x,y)]]'
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

Errors:

            lhs = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'djskfl', cd : 'jfklds' }
                c : [ { t : 'i', v : 8250 } ]
            }
            rhs = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'djskfl', cd : 'jfklds' }
                c : [ { t : 'i', v : 8250 } ]
            }
            expect( lhs.equals lhs ).toBeTruthy()
            expect( rhs.equals rhs ).toBeTruthy()
            expect( lhs.equals rhs ).toBeTruthy()
            expect( lhs is rhs ).toBeFalsy()

### should return false for unequal compounds

Just like the test for unequal atomics, but now we're building application
and binding trees instead, as well as error objects, and comparing them to
different objects of the same type, and comparing across types, and also
comparing to some atomic nodes as well.

        it 'should return true for unequal compounds', ->

Atomics to use below for comparison:

            node_i = OM.simple '7'
            node_f = OM.simple '8.2380'
            node_v = OM.simple 'var'
            node_st = OM.simple '"rtuyperq"'
            node_sy = OM.simple 'vncmx.fdhjs'
            node_ba = { t : 'ba', v : new Uint8Array [ 25, 38, 196, 29 ] }

Applications:

            lhs_a = OM.simple 'f(g(x,y),too.tee)'
            rhs_a = OM.simple 'f(G(x,y),too.tee)'
            expect( lhs_a.equals lhs_a ).toBeTruthy()
            expect( rhs_a.equals rhs_a ).toBeTruthy()
            expect( lhs_a.equals rhs_a ).toBeFalsy()
            expect( lhs_a.equals node_i ).toBeFalsy()
            expect( lhs_a.equals node_f ).toBeFalsy()
            expect( lhs_a.equals node_v ).toBeFalsy()
            expect( lhs_a.equals node_st ).toBeFalsy()
            expect( lhs_a.equals node_sy ).toBeFalsy()
            expect( lhs_a.equals node_ba ).toBeFalsy()

Bindings:

            lhs_bi = OM.simple 'logic.forall[x,logic.exists[y,Q(x,y)]]'
            rhs_bi = OM.simple 'logic.foraye[x,logic.exists[y,Q(x,y)]]'
            expect( lhs_bi.equals lhs_bi ).toBeTruthy()
            expect( rhs_bi.equals rhs_bi ).toBeTruthy()
            expect( lhs_bi.equals rhs_bi ).toBeFalsy()
            expect( lhs_bi.equals lhs_a ).toBeFalsy()
            expect( lhs_bi.equals node_i ).toBeFalsy()
            expect( lhs_bi.equals node_f ).toBeFalsy()
            expect( lhs_bi.equals node_v ).toBeFalsy()
            expect( lhs_bi.equals node_st ).toBeFalsy()
            expect( lhs_bi.equals node_sy ).toBeFalsy()
            expect( lhs_bi.equals node_ba ).toBeFalsy()

Errors:

            lhs_e = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'dijkstra', cd : 'jfklds' }
                c : [ { t : 'i', v : 8250 } ]
            }
            rhs_e = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'djskfl', cd : 'jfklds' }
                c : [ { t : 'i', v : 8250 } ]
            }
            expect( lhs_e.equals lhs_e ).toBeTruthy()
            expect( rhs_e.equals rhs_e ).toBeTruthy()
            expect( lhs_e.equals rhs_e ).toBeFalsy()
            expect( lhs_e.equals lhs_a ).toBeFalsy()
            expect( lhs_e.equals lhs_bi ).toBeFalsy()
            expect( lhs_e.equals node_i ).toBeFalsy()
            expect( lhs_e.equals node_f ).toBeFalsy()
            expect( lhs_e.equals node_v ).toBeFalsy()
            expect( lhs_e.equals node_st ).toBeFalsy()
            expect( lhs_e.equals node_sy ).toBeFalsy()
            expect( lhs_e.equals node_ba ).toBeFalsy()

## Copying structures

We can copy an `OMNode` instance and it should yield a completely different
object (with all different children and valid parent pointers) but that is
equivalent to the first (in that `original.equals( copy )` returns true).

    describe 'Copying structures', ->

### should make distinct but equal copies of atomics

Verify that for all atomic types, a copy is a distinct object, but equal to
the original.

        it 'should make distinct but equal copies of atomics', ->

Integer:

            original = OM.simple '832'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

Float:

            original = OM.simple '8.32'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

String:

            original = OM.simple '"foo"'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

Byte array:

            original =
                OM.decode { t : 'ba', v : new Uint8Array [ 53, 103 ] }
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

Symbol:

            original = OM.simple 'reyui.vnm'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

Variable:

            original = OM.simple 'fdjls'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()

### should make distinct but equal copies of compounds

Verify that for all compound types, a copy is a distinct object, but equal
to the original.  Furthermore (unlike the case of atomics) we must also test
that the corresponding sub-objects are not actually equal to those of the
original, but are distinct objects as well.

        it 'should make distinct but equal copies of compounds', ->

Application:

            original = OM.simple 'please(hammer,donut(hertz,umm))'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()
            expect( original.children[0] ).not.toBe copy.children[0]
            expect( original.children[0].equals copy.children[0] ) \
                .toBeTruthy()
            expect( original.children[1] ).not.toBe copy.children[1]
            expect( original.children[1].equals copy.children[1] ) \
                .toBeTruthy()
            expect( original.children[2] ).not.toBe copy.children[2]
            expect( original.children[2].equals copy.children[2] ) \
                .toBeTruthy()
            expect( original.children[2].children[0] ).not.toBe \
                copy.children[2].children[0]
            expect( original.children[2].children[0].equals \
                copy.children[2].children[0] ).toBeTruthy()
            expect( original.children[2].children[1] ).not.toBe \
                copy.children[2].children[1]
            expect( original.children[2].children[1].equals \
                copy.children[2].children[1] ).toBeTruthy()
            expect( original.children[2].children[2] ).not.toBe \
                copy.children[2].children[2]
            expect( original.children[2].children[2].equals \
                copy.children[2].children[2] ).toBeTruthy()

Binding:

            original = OM.simple 'al.ph[ab,et]'
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()
            expect( original.symbol ).not.toBe copy.symbol
            expect( original.symbol.equals copy.symbol ).toBeTruthy()
            expect( original.body ).not.toBe copy.body
            expect( original.body.equals copy.body ).toBeTruthy()
            expect( original.variables[0] ).not.toBe copy.variables[0]
            expect( original.variables[0].equals copy.variables[0] ) \
                .toBeTruthy()

Error:

            original = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'file_not_found', cd : 'http' }
                c : [ { t : 'i', v : 404 } ]
            }
            copy = original.copy()
            expect( original ).not.toBe copy
            expect( original.equals copy ).toBeTruthy()
            expect( original.symbol ).not.toBe copy.symbol
            expect( original.symbol.equals copy.symbol ).toBeTruthy()
            expect( original.children[0] ).not.toBe copy.children[0]
            expect( original.children[0].equals copy.children[0] ) \
                .toBeTruthy()

## Parent-child relationships

There are many functions for making, changing, and querying parent-child
relationships in OMNode tree structures.  This section tests them all.

    describe 'Parent-child relationships', ->

### should be queryable with `findInParent`

Test all types of situations in which `findInParent` could be called.

        it 'should be queryable with findInParent', ->

On any tree without a parent, it should be undefined.

            expect( OM.simple( '3' ).findInParent() ).toBeUndefined()
            expect( OM.simple( 'f(x)' ).findInParent() ).toBeUndefined()
            expect( OM.simple( 'g.a[z,t]' ).findInParent() ).toBeUndefined()
            expect( OM.simple( '-725.38' ).findInParent() ).toBeUndefined()

On any child, it should return "ci", where i is the index of the child.

            outer = OM.simple 'f(x,y,z)'
            expect( outer.children[0].findInParent() ).toBe 'c0'
            expect( outer.children[1].findInParent() ).toBe 'c1'
            expect( outer.children[2].findInParent() ).toBe 'c2'
            expect( outer.children[3].findInParent() ).toBe 'c3'

On any variable, it should return "vi", where i is the index of the
variable.

            outer = OM.simple 'F.f[x,y,h(y,x,x)]'
            expect( outer.variables[0].findInParent() ).toBe 'v0'
            expect( outer.variables[1].findInParent() ).toBe 'v1'

On any binding's symbol or body, it should return "s" or "b", respectively.

            outer = OM.simple 'F.f[x,y,h(y,x,x)]'
            expect( outer.symbol.findInParent() ).toBe 's'
            expect( outer.body.findInParent() ).toBe 'b'
            outer = OM.simple 'total.other[example,dude]'
            expect( outer.symbol.findInParent() ).toBe 's'
            expect( outer.body.findInParent() ).toBe 'b'

The values of an object's attributes have their keys as the result.

            outer = OM.decode {
                t : 'i'
                v : 1209
                a : {
                    '{"t":"sy","n":"X","cd":"Y"}' : { t : 'f', v : -0.5 }
                    '{"t":"sy","n":"Z","cd":"W"}' : { t : 'v', n : 'foo' }
                }
            }
            key = '{"t":"sy","n":"X","cd":"Y"}'
            value = new OMNode outer.tree.a[key]
            expect( value.findInParent() ).toBe key
            key = '{"t":"sy","n":"Z","cd":"W"}'
            value = new OMNode outer.tree.a[key]
            expect( value.findInParent() ).toBe key

### can be broken with `remove()`

Test all situations in which one node is nested inside another, and we call
`remove()` on the inner node.  Parent-child relationships in both directions
should be broken (sometimes invalidating the parent's structure).

        it 'can be broken with remove()', ->

On any tree without a parent, `remove()` should do nothing.  We test this
on just a small set of example expressions.

            original = OM.simple '3'
            copy = original.copy()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            original.remove()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            expect( original.equals copy ).toBeTruthy()
            original = OM.simple 'f(x)'
            copy = original.copy()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            original.remove()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            expect( original.equals copy ).toBeTruthy()
            original = OM.simple '"fjdklsfjdslkjfdsklf"'
            copy = original.copy()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            original.remove()
            expect( original.parent ).toBeFalsy()
            expect( copy.parent ).toBeFalsy()
            expect( original.equals copy ).toBeTruthy()

Children of an application node should be removable with `remove()`.

            original = OM.simple 'sum(1,4,9,16)'
            expect( original.children.length ).toBe 5
            child = original.children[0]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            expect( original.children.length ).toBe 4
            expect( original.equals OM.simple '1(4,9,16)' ).toBeTruthy()
            child = original.children[2]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            expect( original.children.length ).toBe 3
            expect( original.equals OM.simple '1(4,16)' ).toBeTruthy()
            child = original.children[2]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            expect( original.children.length ).toBe 2
            expect( original.equals OM.simple '1(4)' ).toBeTruthy()
            child = original.children[0]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            expect( original.children.length ).toBe 1
            expect( original.equals OM.simple '4()' ).toBeTruthy()

All parts of a binding node should be removable with `remove()`.

            original = OM.simple 'ask.and[you,shall,receive]'
            expect( original.variables.length ).toBe 2
            variable = original.variables[1]
            expect( variable.parent.sameObjectAs original ).toBeTruthy()
            variable.remove()
            expect( variable.parent ).toBeUndefined()
            expect( original.variables.length ).toBe 1
            expect( original.equals OM.simple 'ask.and[you,receive]' ) \
                .toBeTruthy()
            symbol = original.symbol
            expect( symbol.parent.sameObjectAs original ).toBeTruthy()
            symbol.remove()
            expect( symbol.parent ).toBeUndefined()
            expect( original.variables.length ).toBe 1
            expect( original.symbol ).toBeUndefined()
            body = original.body
            expect( body.parent.sameObjectAs original ).toBeTruthy()
            body.remove()
            expect( body.parent ).toBeUndefined()
            expect( original.variables.length ).toBe 1
            expect( original.body ).toBeUndefined()

All parts of an error node should be removable with `remove()`.

            original = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'c3po', cd : 'r2d2' }
                c : [
                    { t : 'sy', n : 'luke', cd : 'skywalker' }
                    { t : 'sy', n : 'han', cd : 'solo' }
                ]
            }
            expect( original.children.length ).toBe 2
            child = original.children[1]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            newVersion = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'c3po', cd : 'r2d2' }
                c : [ { t : 'sy', n : 'luke', cd : 'skywalker' } ]
            }
            expect( original.equals newVersion ).toBeTruthy()
            child = original.children[0]
            expect( child.parent.sameObjectAs original ).toBeTruthy()
            child.remove()
            expect( child.parent ).toBeUndefined()
            newVersion = OM.decode {
                t : 'e'
                s : { t : 'sy', n : 'c3po', cd : 'r2d2' }
                c : [ ]
            }
            expect( original.equals newVersion ).toBeTruthy()
            symbol = original.symbol
            expect( symbol.parent.sameObjectAs original ).toBeTruthy()
            symbol.remove()
            expect( symbol.parent ).toBeUndefined()
            expect( original.symbol ).toBeUndefined()

### are consistent with getAttribute()

Querying an OMNode's attributes with `getAttribute()` should not only yield
correct results, but should also yield nodes whose parent is the node in
which the query was performed.

        it 'are consistent with getAttribute()', ->

We choose two examples, the first a tiny one with no attributes.

            node = OM.simple 'hello'
            expect( node.getAttribute OM.simple 'sym.bol' ).toBeUndefined()
            expect( node.getAttribute OM.simple 'o.ther' ).toBeUndefined()

The second example has two attributes on each level of a two-tier structure.

            node = OM.decode {
                t : 'a'
                c : [
                    t : 'v'
                    n : 'f'
                    a : {
                        '{"t":"sy","n":"one","cd":"two"}' :
                            { t : 'i', v : 42 }
                        '{"t":"sy","n":"three","cd":"four"}' :
                            { t : 'f', v : -42.42 }
                    }
                ,
                    t : 'a'
                    c : [
                        t : 'v'
                        n : 'g'
                    ,
                        t : 'v'
                        n : 'x'
                        a : {
                            '{"t":"sy","n":"five","cd":"six"}' :
                                { t : 'st', v : 'the question' }
                            '{"t":"sy","n":"seven","cd":"eight"}' :
                                { t : 'st', v : 'the answer' }
                        }
                    ]
                ]
            }

Looking up an attribute that isn't there doesn't work:

            value = node.getAttribute OM.simple 'two.one'
            expect( value ).toBeUndefined()

But looking up those that are there give the correct results, with the
correct parent-child relationships:

            value = node.children[0].getAttribute OM.simple 'two.one'
            expect( value.equals OM.simple '42' ).toBeTruthy()
            expect( value.parent.sameObjectAs node.children[0] ) \
                .toBeTruthy()
            value = node.children[0].getAttribute OM.simple 'four.three'
            expect( value.equals OM.simple '-42.42' ).toBeTruthy()
            expect( value.parent.sameObjectAs node.children[0] ) \
                .toBeTruthy()

Looking up an attribute that isn't there doesn't work:

            value = node.children[1].getAttribute OM.simple 'six.five'
            expect( value ).toBeUndefined()

But looking up those that are there give the correct results, with the
correct parent-child relationships:

            value = node.children[1].children[0].getAttribute \
                OM.simple 'six.five'
            expect( value ).toBeUndefined()
            value = node.children[1].children[1].getAttribute \
                OM.simple 'six.five'
            expect( value.equals OM.simple '"the question"' ).toBeTruthy()
            expect( value.parent.sameObjectAs \
                node.children[1].children[1] ).toBeTruthy()
            value = node.children[1].children[1].getAttribute \
                OM.simple 'eight.seven'
            expect( value.equals OM.simple '"the answer"' ).toBeTruthy()
            expect( value.parent.sameObjectAs \
                node.children[1].children[1] ).toBeTruthy()

### are consistent with removeAttribute()

Removing an OMNode's attributes with `removeAttribute()` should not only
yield correct results, but should also modify parent pointers appropriately.

        it 'are consistent with removeAttribute()', ->

We choose just one example, with two attributes, and we remove them one at
a time, testing the results in each case.

            node = OM.decode {
                t : 'st'
                v : 'this is a string'
                a : {
                    '{"t":"sy","n":"attr1","cd":"foo"}' : { t : 'i', v : 3 }
                    '{"t":"sy","n":"attr2","cd":"foo"}' : { t : 'i', v : 9 }
                }
            }
            value1 = node.getAttribute OM.simple 'foo.attr1'
            value2 = node.getAttribute OM.simple 'foo.attr2'
            expect( value1.parent.sameObjectAs node ).toBeTruthy()
            expect( value2.parent.sameObjectAs node ).toBeTruthy()

We've established a baseline by looking up two attributes with correct
parent pointers.  Now we remove one of them, then verify that the other is
still there, but the removed one can no longer be queried with
`getAttribute()`, and the parent pointer of the originally-looked-up object
has been deleted.

            node.removeAttribute OM.simple 'foo.attr1'
            value1b = node.getAttribute OM.simple 'foo.attr1'
            value2b = node.getAttribute OM.simple 'foo.attr2'
            expect( value1b ).toBeUndefined()
            expect( value2b.parent.sameObjectAs node ).toBeTruthy()
            expect( value2b.equals value2 ).toBeTruthy()
            expect( value1.parent ).toBeUndefined()

Repeat the same exact removal, and verify that it doesn't actually do
anything the second time.

            node.removeAttribute OM.simple 'foo.attr1'
            value1c = node.getAttribute OM.simple 'foo.attr1'
            value2c = node.getAttribute OM.simple 'foo.attr2'
            expect( value1c ).toBeUndefined()
            expect( value2c.parent.sameObjectAs node ).toBeTruthy()
            expect( value2c.equals value2 ).toBeTruthy()
            expect( value1.parent ).toBeUndefined()

Remove the second attribute, and make the same checks that we did after
removing the first.

            node.removeAttribute OM.simple 'foo.attr2'
            value1d = node.getAttribute OM.simple 'foo.attr1'
            value2d = node.getAttribute OM.simple 'foo.attr2'
            expect( value1d ).toBeUndefined()
            expect( value2d ).toBeUndefined()
            expect( value2.parent ).toBeUndefined()
            expect( value1.parent ).toBeUndefined()
