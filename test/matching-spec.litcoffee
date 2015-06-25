
# Tests of the Matching module

Here we import the module we're about to test and the related OM module that
we'll use when testing.

    { Match, setMetavariable, clearMetavariable, isMetavariable } =
        require '../src/matching.duo'
    { OM, OMNode } = require '../src/openmath.duo'

## Global functions and a class

This section tests just the existence and simplest functioning of the main
class (Match) and some supporting global functions.

    describe 'Global functions and a class', ->

### should be defined

First we verify that the Match class and the related functions are defined.

        it 'should be defined', ->
            expect( Match ).toBeTruthy()
            expect( setMetavariable ).toBeTruthy()
            expect( clearMetavariable ).toBeTruthy()
            expect( isMetavariable ).toBeTruthy()

### should reliably mark metavariables

Then we verify that we can mark variables as metavariables, query those
marks reliably, and clear them.

        it 'should reliably mark metavariables', ->

First we test that the functions work correctly on several variable nodes.

            x = OM.simple 'x'
            y = OM.simple 'y'
            z = OM.simple 'z'
            expect( isMetavariable x ).toBeFalsy()
            expect( isMetavariable y ).toBeFalsy()
            expect( isMetavariable z ).toBeFalsy()
            setMetavariable x
            expect( isMetavariable x ).toBeTruthy()
            expect( isMetavariable y ).toBeFalsy()
            expect( isMetavariable z ).toBeFalsy()
            setMetavariable y
            expect( isMetavariable x ).toBeTruthy()
            expect( isMetavariable y ).toBeTruthy()
            expect( isMetavariable z ).toBeFalsy()
            setMetavariable z
            expect( isMetavariable x ).toBeTruthy()
            expect( isMetavariable y ).toBeTruthy()
            expect( isMetavariable z ).toBeTruthy()
            clearMetavariable x
            expect( isMetavariable x ).toBeFalsy()
            expect( isMetavariable y ).toBeTruthy()
            expect( isMetavariable z ).toBeTruthy()
            clearMetavariable y
            expect( isMetavariable x ).toBeFalsy()
            expect( isMetavariable y ).toBeFalsy()
            expect( isMetavariable z ).toBeTruthy()
            clearMetavariable z
            expect( isMetavariable x ).toBeFalsy()
            expect( isMetavariable y ).toBeFalsy()
            expect( isMetavariable z ).toBeFalsy()

Then we test that we cannot actually mark non-variables as metavariables.

            one = OM.simple '1'
            fofx = OM.simple 'f(x)'
            hi = OM.simple '"hi"'
            expect( isMetavariable one ).toBeFalsy()
            expect( isMetavariable fofx ).toBeFalsy()
            expect( isMetavariable hi ).toBeFalsy()
            setMetavariable one
            setMetavariable fofx
            setMetavariable hi
            expect( isMetavariable one ).toBeFalsy()
            expect( isMetavariable fofx ).toBeFalsy()
            expect( isMetavariable hi ).toBeFalsy()

## Match objects

This section tests the member functions of the Match class, in isolation
from the matching algorithm in which they will play a central role.  (The
matching algorithm is tested in the next section.)

    describe 'Match objects', ->

### should correctly get, set, clear, and test their mapping

We first test the `get`, `set`, `clear`, `has`, and `variables` functions
that manipulate and query the variable-name-to-expression mapping stored in
the Match object.

        it 'should correctly get, set, clear, and test their mapping', ->

Ensure we can create a match object.

            m = new Match
            expect( m ).toBeTruthy()

Create some expressions to put into it, and some variables under which to
store them.

            expr1 = OM.simple 'thing'
            expr2 = OM.simple 't("some")'
            expr3 = OM.simple 'y.y[q,r,s,body(of,binding)]'
            a = OM.simple 'a'
            b = OM.simple 'b'
            c = OM.simple 'sea'

Store a value and be sure we can look it up.  Ensure that the result is a
copy, and that it can be looked up using either a string or a variable
OMNode.

            m.set 'a', expr1
            expect( m.get( 'a' ).equals expr1 ).toBeTruthy()
            expect( m.get( 'a' ).sameObjectAs expr1 ).toBeFalsy()
            expect( m.get( a ).equals expr1 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr1 ).toBeFalsy()
            expect( m.get( a ).sameObjectAs m.get 'a' ).toBeTruthy()

Test the `variables` and `has` functions in this simple situation.

            expect( m.has a ).toBeTruthy()
            expect( m.has 'a' ).toBeTruthy()
            expect( m.has b ).toBeFalsy()
            expect( m.has 'b' ).toBeFalsy()
            expect( m.variables() ).toEqual [ 'a' ]

Try to remove that one entry in the map.

            m.clear 'a'
            expect( m.has a ).toBeFalsy()
            expect( m.has 'a' ).toBeFalsy()
            expect( m.variables() ).toEqual [ ]

Add multiple entries to the map and ensure that queries are correct.

            m.set a, expr1
            m.set b, expr2
            m.set c, expr3
            expect( m.variables().sort() ).toEqual [ 'a', 'b', 'sea' ]
            expect( m.get( a ).equals expr1 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr1 ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.get( b ).equals expr2 ).toBeTruthy()
            expect( m.get( b ).sameObjectAs expr2 ).toBeFalsy()
            expect( m.has b ).toBeTruthy()
            expect( m.get( c ).equals expr3 ).toBeTruthy()
            expect( m.get( c ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has c ).toBeTruthy()

Change one of them to match another's value, and ensure a copy was made.

            m.set a, expr3
            expect( m.get( a ).equals m.get c ).toBeTruthy()
            expect( m.get( a ).sameObjectAs m.get c ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.has b ).toBeTruthy()
            expect( m.has c ).toBeTruthy()

Clear it out one variable at a time, and watch `variables` and `has` to
ensure they behave as expected.

            expect( m.variables().sort() ).toEqual [ 'a', 'b', 'sea' ]
            m.clear b
            expect( m.get( a ).equals expr3 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get( c ).equals expr3 ).toBeTruthy()
            expect( m.get( c ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has c ).toBeTruthy()
            expect( m.variables().sort() ).toEqual [ 'a', 'sea' ]
            m.clear c
            expect( m.get( a ).equals expr3 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get c ).toBeUndefined()
            expect( m.has c ).toBeFalsy()
            expect( m.variables().sort() ).toEqual [ 'a' ]
            m.clear a
            expect( m.get a ).toBeUndefined()
            expect( m.has a ).toBeFalsy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get c ).toBeUndefined()
            expect( m.has c ).toBeFalsy()
            expect( m.variables() ).toEqual [ ]
