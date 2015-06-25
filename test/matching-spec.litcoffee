
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

We first test the `get`, `set`, `clear`, and `has` functions that manipulate
and query the variable-name-to-expression mapping stored in the Match
object.

        it 'should correctly get, set, clear, and test their mapping', ->
            m = new Match
            expect( m ).toBeTruthy()
            # test not yet complete
