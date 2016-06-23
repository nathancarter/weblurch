
# Tests of the Unification module

Here we import the module we're about to test and the related OM module that
we'll use when testing.

    { Match, setMetavariable, clearMetavariable, isMetavariable, unify } =
        unification = require '../src/unification-duo'
    { OM, OMNode } = require '../src/openmath-duo'

We create two convenience functions for creating expression functions
and applications thereof, as defined in [the unification source
code](#../src/unification-duo.litcoffee#functions-and-function-applications).  These use the `quick` function defined below.

    ef = ( variable, body ) ->
        if variable not instanceof OMNode then variable = quick variable
        if body not instanceof OMNode then body = quick body
        Match.makeExpressionFunction variable, body
    aef = ( func, param ) ->
        if func not instanceof OMNode then func = quick func
        if param not instanceof OMNode then param = quick param
        Match.makeExpressionFunctionApplication func, param

Several times in this test we will want to use the convention that a
variable beginning with an underscore should have the underscore removed,
but then be flagged as a metavariable.  That is, `f(x)` is different from
`_f(x)` only in that the latter will have its head variable `f` marked with
the property of being a metavariable.  To facilitate this, we have the
following convenience function that applies `OM.simple` to a string, then
traverses the resulting tree to apply this convention.

It also supports symbols, so that '_s.s' is interpreted as the symbol 's.s',
but with the property of being a metavariable.

It also supports the convention that `f_of_x` should expand to
`aef quick( f ), quick( x )`.  The `f` and `x` in this example are
permitted to begin with additional underscores.

    quick = ( string ) ->
        tree = OM.simple string
        if typeof tree is 'string'
            throw "Error calling quick on '#{string}': #{tree}"
        for variable in tree.descendantsSatisfying( ( x ) -> x.type is 'v' )
            if match = /^(.+)_of_(.+)$/.exec variable.name
                variable.replaceWith aef quick( match[1] ), quick match[2]
            else if /^_/.test variable.name
                variable.replaceWith OM.simple variable.name[1..]
                setMetavariable variable
        for symbol in tree.descendantsSatisfying( ( x ) -> x.type is 'sy' )
            if /^_/.test symbol.cd
                symbol.replaceWith OM.simple \
                    "#{symbol.cd[1..]}.#{symbol.name}"
                setMetavariable symbol
        tree

## Global functions and a class

This section tests just the existence and simplest functioning of the main
class (Match) and some supporting global functions, as well as the main
export of the unification module, the `unify` function.

    describe 'Global functions and a class', ->

### should be defined

First we verify that the Match class and the related functions are defined,
together with the main `unify` function.

        it 'should be defined', ->
            expect( Match ).toBeTruthy()
            expect( setMetavariable ).toBeTruthy()
            expect( clearMetavariable ).toBeTruthy()
            expect( isMetavariable ).toBeTruthy()
            expect( unify ).toBeTruthy()

### should reliably mark metavariables

Then we verify that we can mark variables as metavariables, query those
marks reliably, and clear them.

        it 'should reliably mark metavariables', ->

First we test that the functions work correctly on several variable and
symbol nodes.

            x = OM.simple 'x'
            y = OM.simple 'y'
            z = OM.simple 'z.z'
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

Then we test that we cannot actually mark objects that are neither variables
nor symbols as metavariables.

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

### should reliably make expression functions

Then we verify that we can make expression functions and query that status
reliably.

        it 'should reliably make expression functions', ->

Some simple tests should be sufficient here.

            x = OM.simple 'x'
            body1 = OM.simple 'x(1,2)'
            body2 = OM.simple 'z.z(x,y.y)'
            expect( Match.isExpressionFunction x ).toBeFalsy()
            expect( Match.isExpressionFunction body1 ).toBeFalsy()
            expect( Match.isExpressionFunction body2 ).toBeFalsy()
            f = Match.makeExpressionFunction x, body1
            g = Match.makeExpressionFunction x, body2
            expect( Match.isExpressionFunction f ).toBeTruthy()
            expect( Match.isExpressionFunction g ).toBeTruthy()

### should reliably make expression function applications

Then we verify that we can make applications of expression functions and
reliably query whether something is such a structure.

        it 'should reliably make expression function applications', ->

Some simple tests should be sufficient here.

            F = OM.simple 'F'
            x = OM.simple 'x'
            y = OM.simple 'y'
            expect( Match.isExpressionFunctionApplication F ).toBeFalsy()
            expect( Match.isExpressionFunctionApplication x ).toBeFalsy()
            expect( Match.isExpressionFunctionApplication y ).toBeFalsy()
            Fx = Match.makeExpressionFunctionApplication F, x
            expect( Match.isExpressionFunctionApplication Fx ).toBeTruthy()
            Fx2 = OM.app F, x
            expect( Match.isExpressionFunctionApplication Fx2 ).toBeFalsy()
            Fx3 = OM.app Fx.symbol, Fx.variables..., Fx.body, y
            expect( Match.isExpressionFunctionApplication Fx3 ).toBeFalsy()

## Match objects

This section tests the member functions of the Match class, in isolation
from the unification algorithm in which they will play a central role.  (The
unification algorithm is tested in the next section.)

    describe 'Match objects', ->

### should correctly get, set, clear, and test their mapping

We first test the `get`, `set`, `clear`, `has`, and `keys` functions that
manipulate and query the variable-name-to-expression mapping stored in the
Match object.

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

Test the `keys` and `has` functions in this simple situation.

            expect( m.has a ).toBeTruthy()
            expect( m.has 'a' ).toBeTruthy()
            expect( m.has b ).toBeFalsy()
            expect( m.has 'b' ).toBeFalsy()
            expect( m.keys() ).toEqual [ 'a' ]

Try to remove that one entry in the map.

            m.clear 'a'
            expect( m.has a ).toBeFalsy()
            expect( m.has 'a' ).toBeFalsy()
            expect( m.keys() ).toEqual [ ]

Add multiple entries to the map and ensure that queries are correct.

            m.set a, expr1
            m.set b, expr2
            m.set c, expr3
            expect( m.keys().sort() ).toEqual [ 'a', 'b', 'sea' ]
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

Clear it out one variable at a time, and watch `keys` and `has` to ensure
they behave as expected.

            expect( m.keys().sort() ).toEqual [ 'a', 'b', 'sea' ]
            m.clear b
            expect( m.get( a ).equals expr3 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get( c ).equals expr3 ).toBeTruthy()
            expect( m.get( c ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has c ).toBeTruthy()
            expect( m.keys().sort() ).toEqual [ 'a', 'sea' ]
            m.clear c
            expect( m.get( a ).equals expr3 ).toBeTruthy()
            expect( m.get( a ).sameObjectAs expr3 ).toBeFalsy()
            expect( m.has a ).toBeTruthy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get c ).toBeUndefined()
            expect( m.has c ).toBeFalsy()
            expect( m.keys().sort() ).toEqual [ 'a' ]
            m.clear a
            expect( m.get a ).toBeUndefined()
            expect( m.has a ).toBeFalsy()
            expect( m.get b ).toBeUndefined()
            expect( m.has b ).toBeFalsy()
            expect( m.get c ).toBeUndefined()
            expect( m.has c ).toBeFalsy()
            expect( m.keys() ).toEqual [ ]

### should correctly apply their mapping

This test applies some mappings to some patterns and verifies that the
results are as they should be.

        it 'should correctly apply their mapping', ->

Construct the same expressions as in the previous test and put them in a
Match instance.

            expr1 = OM.simple 'thing'
            expr2 = OM.simple 't("some")'
            expr3 = OM.simple 'y.y[q,r,s,body(of,binding)]'
            a = OM.simple 'a'
            b = OM.simple 'b'
            c = OM.simple 'sea'
            m = new Match
            m.set a, expr1
            m.set b, expr2
            m.set c, expr3

Construct a trivial pattern and test the substitution.

            pattern = quick '_a'
            expect( isMetavariable pattern ).toBeTruthy()
            result = m.applyTo pattern
            expect( result.equals pattern ).toBeFalsy()
            expect( result.equals expr1 ).toBeTruthy()

Repeat the test with a pattern that will not be affected by `m`.

            pattern = quick '_thing'
            expect( isMetavariable pattern ).toBeTruthy()
            result = m.applyTo pattern
            expect( result.equals pattern ).toBeTruthy()
            expect( result.equals expr1 ).toBeFalsy()

Now use an application expression with several different metavariables.

            pattern = quick 'myFunc(_a,sum(_b,3,_sea))'
            result = m.applyTo pattern
            shouldBe = OM.simple \
                'myFunc(thing,sum(t("some"),3,y.y[q,r,s,body(of,binding)]))'
            expect( result.equals pattern ).toBeFalsy()
            expect( result.equals shouldBe ).toBeTruthy()

Same test as the previous, but now with some variables repeated.

            pattern = quick 'myFunc(_a,foo(_b),sum(_b,3,_a))'
            result = m.applyTo pattern
            shouldBe = OM.simple \
                'myFunc(thing,foo(t("some")),sum(t("some"),3,thing))'
            expect( result.equals pattern ).toBeFalsy()
            expect( result.equals shouldBe ).toBeTruthy()

Same test as previous, but now with a binding instead of an application.

            pattern = quick 'logic.exists[t,and(_a,sum(_b,3,_a))]'
            result = m.applyTo pattern
            shouldBe = OM.simple \
                'logic.exists[t,and(thing,sum(t("some"),3,thing))]'
            expect( result.equals pattern ).toBeFalsy()
            expect( result.equals shouldBe ).toBeTruthy()

### should be able to copy themselves

Match objects provide a copy function; we test it briefly here.  No
extensive testing is done, because the copy function is not complex.

        it 'should be able to copy themselves', ->

Construct an empty match and make a copy.  Verify that they have everything
in common.

            m = new Match
            c = m.copy()
            expect( m is c ).toBeFalsy()
            expect( c.keys() ).toEqual [ ]

Add some things to each part of `m`, then verify that `c` has not changed.

            left = quick 'a'
            right = quick 'b'
            m.set 'A', left
            m.set 'B', right
            expect( m is c ).toBeFalsy()
            expect( c.keys() ).toEqual [ ]

Make a second copy of `m` and verify that all this new data is preserved
into the copy.

            c2 = m.copy()
            expect( c2.keys().sort() ).toEqual [ 'A', 'B' ]
            expect( c2.get( 'A' ).equals left ).toBeTruthy()
            expect( c2.get( 'B' ).equals right ).toBeTruthy()

## Unification

This section is the most important in this test suite, and checks many cases
of the main unification algorithm.

    describe 'The unification algorithm', ->

### should work for atomic patterns

The following tests are for the case where the pattern is atomic, first when
it is not a metavariable, then when it is.

        it 'should work for atomic patterns', ->

Unifying `a` with `a` should yield `[ { } ]`.

            result = unify quick( 'a' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Unifying `a` with `b` should yield `[ ]`.

            result = unify quick( 'a' ), quick( 'b' )
            expect( result ).toEqual [ ]

Unifying `a` with `2` should yield `[ ]`.

            result = unify quick( 'a' ), quick( '2' )
            expect( result ).toEqual [ ]

Unifying `a` with `f(x)` should yield `[ ]`.

            result = unify quick( 'a' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Unifying `9` with `9` should yield `[ { } ]`.

            result = unify quick( '9' ), quick( '9' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Unifying `9` with `b` should yield `[ ]`.

            result = unify quick( '9' ), quick( 'b' )
            expect( result ).toEqual [ ]

Unifying `9` with `2` should yield `[ ]`.

            result = unify quick( '9' ), quick( '2' )
            expect( result ).toEqual [ ]

Unifying `9` with `f(x)` should yield `[ ]`.

            result = unify quick( '9' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Unifying `"slow"` with `a` should yield `[ { } ]`.

            result = unify quick( '"slow"' ), quick( '"slow"' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Unifying `"slow"` with `b` should yield `[ ]`.

            result = unify quick( '"slow"' ), quick( 'b' )
            expect( result ).toEqual [ ]

Unifying `"slow"` with `2` should yield `[ ]`.

            result = unify quick( '"slow"' ), quick( '2' )
            expect( result ).toEqual [ ]

Unifying `"slow"` with `f(x)` should yield `[ ]`.

            result = unify quick( '"slow"' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Unifying `_A` (now a metavariable, following the notational convention in
the `quick` function defined at the top of this test file) with anything
should yield `[ A : thing ]`.

            result = unify quick( '_A' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            result = unify quick( '_A' ), quick( '23645' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick '23645' ).toBeTruthy()
            result = unify quick( '_A' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f(x)' ).toBeTruthy()

### should work for compound patterns

The following tests are for the case where the pattern is compound,
including application, binding, and error types.  No expression function
patterns are tested yet; they appear in later tests.  (Actually, error types
are of little importance to most of our uses, and function so much like
application types that we have little to no tests of error types below.)

        it 'should work for compound patterns', ->

First, applications:

Unifying `_A(x)` with `f(x)` should yield `[ { A : f } ]`.

            result = unify quick( '_A(x)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Unifying `_A(_B)` with `f(x)` should yield `[ { A : f, B : x } ]`.

            result = unify quick( '_A(_B)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()

Unifying `_A(_B)` with `f(x,y)` should yield `[ ]`.

            result = unify quick( '_A(_B)' ), quick( 'f(x,y)' )
            expect( result ).toEqual [ ]

Unifying `_A(_B)` with `f()` should yield `[ ]`.

            result = unify quick( '_A(_B)' ), quick( 'f()' )
            expect( result ).toEqual [ ]

Unifying `_A(_B)` with `some_var` should yield `[ ]`.

            result = unify quick( '_A(_B)' ), quick( 'some_var' )
            expect( result ).toEqual [ ]

Next, bindings:

Unifying `_A.A[x,y]` with `f.f[x,y]` should yield `[ { A : f.f } ]`.

            result = unify quick( '_A.A[x,y]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A.A' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()

Unifying `_A.A[_B,_C]` with `f.f[x,y]` should yield
`[ { A.A : f.f, B : x, C : y } ]`.

            result = unify quick( '_A.A[_B,_C]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual \
                [ 'A.A', 'B', 'C' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'y' ).toBeTruthy()

Unifying `_A.A[_B,_C]` with `f.f[x,y,z]` should yield `[ ]`.

            result = unify quick( '_A.A(_B,_C)' ), quick( 'f.f[x,y,z]' )
            expect( result ).toEqual [ ]

Unifying `_A.A[_B,_C,_D]` with `f.f[x,y]` should yield `[ ]`.

            result = unify quick( '_A.A(_B,_C,_D)' ), quick( 'f.f[x,y]' )
            expect( result ).toEqual [ ]

Unifying `_A.A[_B,_C]` with `some_var` should yield `[ ]`.

            result = unify quick( '_A.A[_B,_C]' ), quick( 'some_var' )
            expect( result ).toEqual [ ]

### should ignore attributes

We repeat a selection of the above tests, now adding attributes to some of
the nodes in either the pattern or the expression, and verifying that the
results are exactly the same in all cases.

        it 'should ignore attributes', ->

Unifying `a` with `a` should yield `[ { } ]`.

            left = quick 'a'
            right = quick 'a'
            left.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Unifying `_A` with `a` should yield `[ { A : a } ]`.

            left = quick '_A'
            right = quick 'a'
            right.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals right, no ).toBeTruthy()

Unifying `_A(x)` with `f(x)` should yield `[ { A : f } ]`.

            left = quick '_A(x)'
            right = quick 'f(x)'
            left.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer 200
            right.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer -1
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Unifying `_A.A[_B,_C]` with `f.f[x,y]` should yield
`[ { A.A : f.f, B : x, C : y } ]`.

            left = quick '_A.A[_B,_C]'
            right = quick 'f.f[x,y]'
            left.setAttribute OM.symbol( 'thing1', 'thing2' ),
                OM.simple 'f(x)'
            right.setAttribute OM.symbol( 'santy', 'claus' ),
                OM.simple 'g(y)'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual \
                [ 'A.A', 'B', 'C' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'y' ).toBeTruthy()

### should work for a simple rule form

We create a few tests based on the equality introduction rule, the simplest
of all the rule forms in first-order logic.  More complex rule forms come as
later tests, below.

        it 'should work for a simple rule form', ->

Unifying `Rule(eq(_a,_a))` with `Rule(eq(7,7))` should yield `a : 7`.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(7,7))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'a' ]
            expect( result[0].get( 'a' ).equals quick '7' ).toBeTruthy()

Unifying `Rule(eq(_a,_a))` with `Rule(eq(t,t))` should yield `a : t`.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(t,t))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'a' ]
            expect( result[0].get( 'a' ).equals quick 't' ).toBeTruthy()

Unifying `Rule(eq(_a,_a))` with `Rule(eq(a,a))` should yield `a : a`.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(a,a))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'a' ]
            expect( result[0].get( 'a' ).equals quick 'a' ).toBeTruthy()

Unifying `Rule(eq(_a,_a))` with `Rule(eq(1,2))` should fail.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(1,2))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(eq(_a,_a))` with `Rule(eq(a,2))` should fail.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(a,2))'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle simple expression functions

This is the first test of the unification algorithm's ability to handle
expression functions, which are patterns containing instructions to generate
a function as part of the unification process, then apply it to an
expression before ensuring the match.  These are the smallest tests of that
type.

Starting at this point, I write `A((B))` to mean that `A` is a function from
expressions to expressions (called an "expression function" herein) and `B`
is an argument to which it is applied.  This is to distinguish from `A(B)`,
which is the ordinary application structure of OpenMath.

        it 'should handle simple expression functions', ->

Unifying `_F((_v))` with `2` should yield `{ F : lambda(v0,2), v : v0 }`.
The `v0` instances are new variables created to not conflict with anything
in the pattern or the expression.

            left = quick '_F_of__v'
            right = quick '2'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'F', 'v' ]
            expect( result[0].get( 'F' ).equals ef 'v0', 'v0' ).toBeTruthy()
            expect( result[0].get( 'v' ).equals quick '2' ).toBeTruthy()

Unifying `f(_F((0)),_F((x)))` with `f(0,x)` should yield
`{ F : lambda(v0,v0) }`.

            left = quick 'f(_F_of_0,_F_of_x)'
            right = quick 'f(0,x)'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'F' ]
            expect( result[0].get( 'F' ).equals ef 'v0', 'v0' ).toBeTruthy()

Unifying `f(_F((0)),_F((_y)))` with `f(0,x)` should yield `F :
lambda(v0,v0), y : x`.

            left = quick 'f(_F_of_0,_F_of__y)'
            right = quick 'f(0,x)'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'F', 'y' ]
            expect( result[0].get( 'F' ).equals ef 'v0', 'v0' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'x' ).toBeTruthy()

Unifying `f(_F((0)),_F((y)))` with `f(g(0),g(y))` should yield `F :
lambda(v0,g(v0))`.

            left = quick 'f(_F_of_0,_F_of_y)'
            right = quick 'f(g(0),g(y))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'F' ]
            expect( result[0].get( 'F' ).equals ef 'v0', 'g(v0)' ) \
                .toBeTruthy()

Unifying `f(_F((_x)),_F((_y)))` with `f(g(0),g(1))` should yield two
results, the first being `F : lambda(v0,g(v0)), x : 0, y : 1` and the second
`F : lambda(v0,v0), x : g(0), y : g(1)`.

            left = quick 'f(_F_of__x,_F_of__y)'
            right = quick 'f(g(0),g(1))'
            result = unify left, right
            expect( result.length ).toBe 2
            expect( result[0].keys().sort() ).toEqual [ 'F', 'x', 'y' ]
            expect( result[0].get( 'F' ).equals ef 'v0', 'g(v0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'x' ).equals quick '0' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick '1' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'F', 'x', 'y' ]
            expect( result[1].get( 'F' ).equals ef 'v0', 'v0' ).toBeTruthy()
            expect( result[1].get( 'x' ).equals quick 'g(0)' ).toBeTruthy()
            expect( result[1].get( 'y' ).equals quick 'g(1)' ).toBeTruthy()

Unifying `f(_F((0)),_F((1)))` with `f(0,0)` should yield `F : lambda(v0,0)`.

            left = quick 'f(_F_of_0,_F_of_1)'
            right = quick 'f(0,0)'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'F' ]
            expect( result[0].get( 'F' ).equals ef 'v0', '0' ).toBeTruthy()

Unifying `f(_F((0)),_F((1)))` with `f(0,2)` should fail.

            left = quick 'f(_F_of_0,_F_of_1)'
            right = quick 'f(0,2)'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the equality elimination rule

The following tests deal with one particular use of expression functions,
the equality elimination rule (a.k.a. "substitution") from first-order
logic.

        it 'should handle the equality elimination rule', ->

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(t,1),gt(t,0),gt(1,0))` should yield `a : t, b : 1, P :
lambda(v0,gt(v0,0))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),gt(t,0),gt(1,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick 't' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(t,1),gt(1,0),gt(t,0))` should fail.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),gt(1,0),gt(t,0))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(t,1),eq(plus(t,1),2),eq(plus(1,1),2))` should yield `a : t, b : 1,
P : lambda(v0,eq(plus(v0,1),2))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),eq(plus(t,1),2),eq(plus(1,1),2))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick 't' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(v0,1),2)' ).toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(t,1),eq(plus(1,1),2),eq(plus(t,1),2))` should fail.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),eq(plus(1,1),2),eq(plus(t,1),2))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),2))` should yield `a : 1, b : 2,
P : lambda(v0,eq(plus(v0,v0),2))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),2))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(v0,v0),2)' ).toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,1),2))` should yield `a : 1, b : 2,
P : lambda(v0,eq(plus(v0,1),2))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,1),2))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(v0,1),2)' ).toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,2),2))` should yield `a : 1, b : 2,
P : lambda(v0,eq(plus(1,v0),2))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,2),2))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(1,v0),2)' ).toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),2))` should yield `a : 1, b : 2,
P : lambda(v0,eq(plus(1,1),2))`.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),2))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'a', 'b' ]
            expect( result[0].get( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(1,1),2)' ).toBeTruthy()

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),1))` should fail.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),1))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),1))` should fail.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),1))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(eq(_a,_b),_P((_a)),_P((_b)))` with
`Rule(eq(x,y),exi.sts[y,ne(y,x)],exi.sts[y,ne(y,y)])` should fail.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(x,y),exi.sts[y,ne(y,x)],exi.sts[y,ne(y,y)])'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the universal elimination rule

The following tests deal with one particular use of expression functions,
the universal elimination rule from first-order logic.

        it 'should handle the universal elimination rule', ->

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,ge(x,0)],ge(7,0))` should yield `x : x, P :
lambda(v0,ge(v0,0)), t : 7`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,ge(x,0)],ge(7,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '7' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ge(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,ge(x,0)],ge(7,7))` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,ge(x,0)],ge(7,7))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,Q],Q)` should yield `x : x, P : Q`, with `t` left
unspecified.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,Q],Q)'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'Q' ).toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[s,eq(sq(s),s)],eq(sq(1),1))` should yield
`x : s, P : lambda(v0,eq(sq(v0),v0)), t : 1`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[s,eq(sq(s),s)],eq(sq(1),1))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 's' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'eq(sq(v0),v0)' ) \
                .toBeTruthy()

Unifying `Rule(forall[_x,_P((_x))],_P((_t)))` with
`Rule(forall[x,R(x,y)],R(x,3))` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,y)],R(x,3))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,R(x,y)],R(3,y))` should yield
`P : lambda(v0,R(v0,y)), x : x, t : 3`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,y)],R(3,y))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'R(v0,y)' ) \
                .toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,R(x,x)],R(3,3))` should yield
`P : lambda(v0,R(v0,v0)), x : x, t : 3`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(3,3))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'R(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,R(x,x)],R(3,x))` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(3,x))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,R(x,x)],R(x,3))` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(x,3))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,R(x,x)],R(x,x))` should yield
`x : x, P : lambda(v0,R(v0,v0)), t : x`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(x,x))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'R(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[s,eq(plus(s,s),r)],eq(plus(t,s),r))` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[s,eq(plus(s,s),r)],eq(plus(t,s),r))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,eq(x,x)],eq(iff(P,Q),iff(P,Q)))` should yield
`x : x, P : lambda(v0,eq(v0,v0)), t : iff(P,Q)`.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,eq(x,x)],eq(iff(P,Q),iff(P,Q)))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick 'iff(P,Q)' ) \
                .toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'eq(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(for.all[_x,_P((_x))],_P((_t)))` with
`Rule(for.all[x,exists[y,lt(x,y)]],exists[y,lt(y,y)])` should fail.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,exi.sts[y,lt(x,y)]],exi.sts[y,lt(y,y)])'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the universal introduction rule

The following tests deal with one particular use of expression functions,
the universal introduction rule from first-order logic.  Here I use `S` to
indicate a subproof structure.

        it 'should handle the universal introduction rule', ->

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[a,r(a,a)],forall[b,r(b,b)])` should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[a,r(a,a)],forall[b,r(b,b)])` should yield `x : a, P :
lambda(v0,r(v0,v0)), y : b`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'b' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'r(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[a,gt(a,3)],forall[a,gt(a,3)])` should yield `x : a, P :
lambda(v0,gt(v0,3)), y : a`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,3)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[a,gt(a,3)],forall[x,gt(x,3)])` should yield `x : a, P :
lambda(v0,gt(v0,3)), y : x`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,3)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[T,R(T,T)],forall[T,R(T,T)])` should yield `x : T, P :
lambda(v0,R(v0,v0)), y : T`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'T' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'T' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'R(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[T,R(T,T)],forall[x,R(T,x)])` should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[y,ne(0,1)],forall[z,ne(0,1)])` should yield `x : y, P :
lambda(v0,ne(0,1)), y : z`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[y,ne(0,1)],for.all[z,ne(0,1)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'z' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ne(0,1)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[b,eq(minus(b,b),0)],forall[c,eq(minus(b,c),0)])` should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[b,eq(minus(b,b),0)],for.all[c,eq(minus(b,c),0)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[a,gt(a,3)],forall[a,gt(a,3)])` should yield `x : a, P :
lambda(v0,gt(v0,3))`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,3)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[a,gt(a,3)],forall[x,gt(x,3)])` should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[T,R(T,T)],forall[T,R(T,T)])` should yield `x : T, P :
lambda(v0,R(v0,v0))`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'T' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'R(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[T,R(T,T)],forall[x,R(T,x)])` should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(subproof[_x,_P((_x))],forall[_x,_P((_x))])` with
`Rule(subproof[y,ne(0,1)],forall[y,ne(0,1)])` should yield `x : y, P :
lambda(v0,ne(0,1))`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[y,ne(0,1)],for.all[y,ne(0,1)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ne(0,1)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[x,eq(x,x)],forall[x,eq(x,x)])` should yield `x : x, y : x,
P : lambda(v0,eq(v0,v0))`.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[x,eq(x,x)],for.all[x,eq(x,x)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'eq(v0,v0)' ) \
                .toBeTruthy()

Unifying `Rule(subproof[_x,_P((_x))],forall[_y,_P((_y))])` with
`Rule(subproof[x,exists[y,lt(x,y)]],forall[y,exists[y,lt(y,y)]])`
should fail.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[x,exi.sts[y,lt(x,y)]],for.all[y,exi.sts[y,lt(y,y)]])'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the existential introduction rule

The following tests deal with one particular use of expression functions,
the existential introduction rule from first-order logic.

        it 'should handle the existential introduction rule', ->

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(ge(1,0),exists[x,ge(x,0)])` should yield `P : lambda(v0,ge(v0,0)), t :
1, x : x`.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ge(1,0),exi.sts[x,ge(x,0)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '1' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ge(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(eq(choose(6,3),20),exists[n,eq(choose(6,n),20)])` should yield
`P : lambda(v0,eq(choose(6,v0),20)), t : 3, x : n`.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(eq(choose(6,3),20),exi.sts[n,eq(choose(6,n),20)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(choose(6,v0),20)' ).toBeTruthy()

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(lt(pow(t,x),5),exists[x,lt(pow(x,x),5)])` should fail.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(lt(pow(t,x),5),exi.sts[x,lt(pow(x,x),5)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(eq(int[x,sq(x)],etc.etc),exists[f,eq(int[x,f],etc.etc)])` should yield
`P : lambda(v0,eq(int[x,v0],etc.etc)), t : sq(x), x : f`.

No, this fails because `sq(x)` contains an `x` bound by the integral.  (At
least, I think that's why.)  This requires more thought before it becomes a
unit test.

            # left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            # right = quick 'Rule(eq(inte.gral[x,sq(x)],etc.etc),exi.sts[f,eq(inte.gral[x,f],etc.etc)])'
            # result = unify left, right
            # expect( result.length ).toBe 1
            # expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            # expect( result[0].get( 't' ).equals quick 'sq(x)' ).toBeTruthy()
            # expect( result[0].get( 'x' ).equals quick 'f' ).toBeTruthy()
            # expect( result[0].get( 'P' ).equals ef 'v0',
            #     'lambda(v0,eq(inte.gral[x,v0],etc.etc))' ).toBeTruthy()

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(ne(x,t),exists[y,ne(y,t)])` should yield
`P : lambda(v0,ne(v0,t)), t : x, x : y`.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ne(x,t),exi.sts[y,ne(y,t)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 't', 'x' ]
            expect( result[0].get( 't' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ne(v0,t)' ) \
                .toBeTruthy()

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(ne(x,t),exists[x,ne(x,x)])` should fail.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ne(x,t),exi.sts[x,ne(x,x)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(_P((_t)),exists[_x,_P((_x))])` with
`Rule(forall[t,eq(t,t)],exists[x,forall[t,eq(x,t)]])` should fail.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(for.all[t,eq(t,t)],exi.sts[x,for.all[t,eq(x,t)]])'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the induction scheme for N

The following tests deal with one particular use of expression functions,
the induction scheme for the natural numbers.

        it 'should handle the induction scheme for N', ->

The induction scheme is the lengthy expression
`Rule(_P((0)),forall[_k,imp(_P((_k)),_P((plus(_k,1))))],forall[_n,_P((_n))])`.
Unifying it with
`Rule(ge(0,0),forall[n,imp(ge(n,0),ge(plus(n,1),0))],forall[n,ge(n,0)])`
should yield `P : lambda(v0,ge(v0,0)), k : n, n : n`.

            piece = quick 'plus(_k,1)'
            piece = aef '_P', piece
            piece = OM.app quick( 'imp' ), quick( '_P_of__k' ), piece
            left = OM.app quick( 'Rule' ),
                quick( '_P_of_0' ),
                OM.bin( quick( 'for.all' ), quick( '_k' ), piece ),
                quick 'for.all[_n,_P_of__n]'
            right = quick 'Rule(ge(0,0),for.all[n,imp(ge(n,0),ge(plus(n,1),0))],for.all[n,ge(n,0)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'k', 'n' ]
            expect( result[0].get( 'k' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'ge(v0,0)' ) \
                .toBeTruthy()

Unifying the same induction rule with
`Rule(eq(plus(0,0),0),forall[m,imp(eq(plus(m,0),m),eq(plus(plus(m,1),0),plus(m,1)))],forall[k,eq(plus(k,0),k)])`
should yield `P : lambda(v0,eq(plus(v0,0),0)), k : m, n : k`.

            right = quick 'Rule(eq(plus(0,0),0),for.all[m,imp(eq(plus(m,0),m),eq(plus(plus(m,1),0),plus(m,1)))],for.all[k,eq(plus(k,0),k)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'k', 'n' ]
            expect( result[0].get( 'k' ).equals quick 'm' ).toBeTruthy()
            expect( result[0].get( 'n' ).equals quick 'k' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0',
                'eq(plus(v0,0),v0)' ).toBeTruthy()

Unifying the same induction rule with
`Rule(P(0),forall[k,imp(P(k),P(plus(k,1)))],forall[n,P(n)])`
should yield `P : lambda(v0,P(v0)), k : k, n : n`.

            right = quick 'Rule(P(0),for.all[k,imp(P(k),P(plus(k,1)))],for.all[n,P(n)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'k', 'n' ]
            expect( result[0].get( 'k' ).equals quick 'k' ).toBeTruthy()
            expect( result[0].get( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'P(v0)' ) \
                .toBeTruthy()

Unifying the same induction rule with
`Rule(eq(7,5),forall[k,imp(eq(7,5),eq(7,5))],forall[n,eq(7,5)])`
should yield `P : lambda(v0,eq(7,5)), k : n, n : n`.

            right = quick 'Rule(eq(7,5),for.all[n,imp(eq(7,5),eq(7,5))],for.all[n,eq(7,5)])'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'k', 'n' ]
            expect( result[0].get( 'k' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'eq(7,5)' ) \
                .toBeTruthy()

Unifying the same induction rule with
`Rule(R(n,1),forall[m,imp(R(m,1),R(plus(m,1),1))],forall[m,R(m,1)])`
should fail.

            right = quick 'Rule(R(n,1),for.all[m,imp(R(m,1),R(plus(m,1),1))],for.all[m,R(m,1)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying the same induction rule with
`Rule(ge(k,0),forall[k,imp(ge(k,k),ge(k,plus(k,1)))],forall[n,ge(n,k)])`
should fail.

            right = quick 'Rule(ge(k,0),for.all[k,imp(ge(k,k),ge(k,plus(k,1)))],for.all[n,ge(n,k)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying the same induction rule with
`Rule(ge(n,0),forall[k,imp(ge(n,k),ge(n,plus(k,1)))],forall[n,ge(n,n)])`
should fail.

            right = quick 'Rule(ge(n,0),for.all[k,imp(ge(n,k),ge(n,plus(k,1)))],for.all[n,ge(n,n)])'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying the same induction rule with
`Rule(ge(0,0),forall[n,imp(ge(n,0),ge(plus(n,1),0))],forall[n,ge(0,0)])`
(just changing the final `n` to a zero) should fail.

            right = quick 'Rule(ge(0,0),for.all[n,imp(ge(n,0),ge(plus(n,1),0))],for.all[n,ge(0,0)])'
            result = unify left, right
            expect( result.length ).toBe 0

### should handle the existential elimination rule

The following tests deal with one particular use of expression functions,
the existential elimination rule from first-order logic.

        it 'should handle the existential elimination rule', ->

Unifying `Rule(exists[_x,_P((_x))],forall[_x,imp(_P((_x)),_Q)],_Q)` with
`Rule(exists[x,eq(sq(x),1)],forall[x,imp(eq(sq(x),1),ge(1,0))],ge(1,0))`
should yield `x : x, P : lambda(v0,eq(sq(v0),1)), Q : ge(1,0)`.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,eq(sq(x),1)],for.all[x,imp(eq(sq(x),1),ge(1,0))],ge(1,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'Q', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'Q' ).equals quick 'ge(1,0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'eq(sq(v0),1)' ) \
                .toBeTruthy()

Unifying `Rule(exists[_x,_P((_x))],forall[_x,imp(_P((_x)),_Q)],_Q)` with
`Rule(exists[x,eq(sq(x),1)],forall[x,imp(eq(sq(x),1),le(x,1))],le(x,1))`
should fail.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,eq(sq(x),1)],for.all[x,imp(eq(sq(x),1),le(x,1))],le(x,1))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(exists[_x,_P((_x))],forall[_x,imp(_P((_x)),_Q)],_Q)` with
`Rule(exists[x,gt(x,0)],imp(forall[x,gt(x,0)],gt(-1,0)),gt(-1,0))`
should fail.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],imp(for.all[x,gt(x,0)],gt(-1,0)),gt(-1,0))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(exists[_x,_P((_x))],forall[_x,imp(_P((_x)),_Q)],_Q)` with
`Rule(exists[x,gt(x,0)],forall[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))`
should yield `x : x, P : lambda(v0,gt(v0,0)), Q : gt(-1,0)`.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'Q', 'x' ]
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'Q' ).equals quick 'gt(-1,0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(exists[_x,_P((_x))],forall[_x,imp(_P((_x)),_Q)],_Q)` with
`Rule(exists[m,gt(m,0)],forall[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))`
should fail.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[m,gt(m,0)],for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))'
            result = unify left, right
            expect( result.length ).toBe 0

Unifying `Rule(exists[_x,_P((_x))],forall[_y,imp(_P((_y)),_Q)],_Q)` with
`Rule(exists[m,gt(m,0)],forall[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))`
should yield `x : x, y : x, P : lambda(v0,gt(v0,0)), Q : gt(-1,0)`.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'Q', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'Q' ).equals quick 'gt(-1,0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(exists[_x,_P((_x))],forall[_y,imp(_P((_y)),_Q)],_Q)` with
`Rule(exists[m,gt(m,0)],forall[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))`
should yield `x : m, y : n, P : lambda(v0,gt(v0,0)), Q : gt(-1,0)`.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[m,gt(m,0)],for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))'
            result = unify left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'P', 'Q', 'x', 'y' ]
            expect( result[0].get( 'x' ).equals quick 'm' ).toBeTruthy()
            expect( result[0].get( 'y' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].get( 'Q' ).equals quick 'gt(-1,0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'P' ).equals ef 'v0', 'gt(v0,0)' ) \
                .toBeTruthy()

Unifying `Rule(exists[_x,_P((_x))],forall[_y,imp(_P((_y)),_Q)],_Q)` with
`Rule(exists[n,lt(n,a)],forall[a,imp(lt(a,a),lt(a,a))],lt(a,a))`
should fail.

            left = quick 'Rule(exi.sts[_x,_P_of__x],for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[n,lt(n,a)],for.all[a,imp(lt(a,a),lt(a,a))],lt(a,a))'
            result = unify left, right
            expect( result.length ).toBe 0
