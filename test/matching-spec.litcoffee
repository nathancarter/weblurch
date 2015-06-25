
# Tests of the Matching module

Here we import the module we're about to test.

    { Match, setMetavariable, clearMetavariable, isMetavariable } =
        require '../src/matching.duo'

## Global functions and a class

This section verifies that the Match class is defined, and some related
global methods.

    describe 'Global functions and a class', ->
        it 'should be defined', ->
            expect( Match ).toBeTruthy()
            expect( setMetavariable ).toBeTruthy()
            expect( clearMetavariable ).toBeTruthy()
            expect( isMetavariable ).toBeTruthy()
