
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
            expect( OMNode.checkJSON { t : 'a', c : [ ] } ).toBeNull()

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
            throw 'NOT YET IMPLEMENTED'

### should find compound nodes with the wrong form invalid

        it 'should find compound nodes with the wrong form invalid', ->
            throw 'NOT YET IMPLEMENTED'
