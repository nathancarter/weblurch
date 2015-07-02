
# Tests of the Matching module

Here we import the module we're about to test and the related OM module that
we'll use when testing.

    { Match, setMetavariable, clearMetavariable, isMetavariable, matches } =
        require '../src/matching.duo'
    { OM, OMNode } = require '../src/openmath.duo'

Several times in this test we will want to use the convention that a
variable beginning with an underscore should have the underscore removed,
but then be flagged as a metavariable.  That is, `f(x)` is different from
`_f(x)` only in that the latter will have its head variable `f` marked with
the property of being a metavariable.  To facilitate this, we have the
following convenience function that applies `OM.simple` to a string, then
traverses the resulting tree to apply this convention.

It also supports symbols, so that '_s.s' is interpreted as the symbol 's.s',
but with the property of being a metavariable.

    quick = ( string ) ->
        tree = OM.simple string
        if typeof tree is 'string'
            throw "Error calling quick on '#{string}': #{tree}"
        for variable in tree.descendantsSatisfying( ( x ) -> x.type is 'v' )
            if /^_/.test variable.name
                variable.replaceWith OM.simple variable.name[1..]
                setMetavariable variable
        for symbol in tree.descendantsSatisfying( ( x ) -> x.type is 'sy' )
            if /^_/.test symbol.cd
                symbol.replaceWith OM.simple \
                    "#{symbol.cd[1..]}.#{symbol.name}"
                setMetavariable symbol
        tree

We also create two convenience functions for creating expressions of the
form `x[y=z]` and `x[y~z]`, whose definitions appear in [the matching
module itself](../src/matching.duo.litcoffee#substitutions).

    reqSub = ( x, y, z ) ->
        if x not instanceof OMNode then x = quick x
        if y not instanceof OMNode then y = quick y
        if z not instanceof OMNode then z = quick z
        OM.application Match.requiredSubstitution, x, y, z
    optSub = ( x, y, z ) ->
        if x not instanceof OMNode then x = quick x
        if y not instanceof OMNode then y = quick y
        if z not instanceof OMNode then z = quick z
        OM.application Match.optionalSubstitution, x, y, z

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

## Match objects

This section tests the member functions of the Match class, in isolation
from the matching algorithm in which they will play a central role.  (The
matching algorithm is tested in the next section.)

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

### should be able to store/retrieve substitution data

The implementations of the functions for getting and setting substitution
data in a match object are quite trivial.  For that reason, they need little
testing, and thus we keep this particular test very short.

        it 'should be able to store/retrieve substitution data', ->

Construct a match and verify that it has no substitution data initially.
Also verify that all queries to the data return undefined.

            m = new Match
            expect( m.hasSubstitution() ).toBeFalsy()
            expect( m.getSubstitutionLeft() ).toBeUndefined()
            expect( m.getSubstitutionRight() ).toBeUndefined()
            expect( m.getSubstitutionRequired() ).toBeUndefined()

Construct some expressions and store them as a substitution, then query the
results to ensure that copies of the expressions were correctly stored and
returned.

            left = OM.simple '"apply"(a,string)'
            right = OM.simple '7829.189'
            m.setSubstitution OM.app Match.requiredSubstitution,
                OM.int( 3 ), left, right
            expect( m.hasSubstitution() ).toBeTruthy()
            expect( m.getSubstitutionLeft().equals left ).toBeTruthy()
            expect( m.getSubstitutionLeft().sameObjectAs left ).toBeFalsy()
            expect( m.getSubstitutionRight().equals right ).toBeTruthy()
            expect( m.getSubstitutionRight().sameObjectAs right ) \
                .toBeFalsy()
            expect( m.getSubstitutionRequired() ).toBeTruthy()

Clear the substitution and verify that it has been removed.

            m.clearSubstitution()
            expect( m.hasSubstitution() ).toBeFalsy()
            expect( m.getSubstitutionLeft() ).toBeUndefined()
            expect( m.getSubstitutionRight() ).toBeUndefined()
            expect( m.getSubstitutionRequired() ).toBeUndefined()

Store a non-required substitution and verify that it is stored accurately,
just as in the test in which we stored a required substitution.

            left = quick '_A'
            right = quick '_B(10)'
            m.setSubstitution OM.app Match.optionalSubstitution,
                OM.int( 3 ), left, right
            expect( m.hasSubstitution() ).toBeTruthy()
            expect( m.getSubstitutionLeft().equals left ).toBeTruthy()
            expect( m.getSubstitutionLeft().sameObjectAs left ).toBeFalsy()
            expect( m.getSubstitutionRight().equals right ).toBeTruthy()
            expect( m.getSubstitutionRight().sameObjectAs right ) \
                .toBeFalsy()
            expect( m.getSubstitutionRequired() ).toBeFalsy()

Clear the substitution and verify that it has been removed.

            m.clearSubstitution()
            expect( m.hasSubstitution() ).toBeFalsy()
            expect( m.getSubstitutionLeft() ).toBeUndefined()
            expect( m.getSubstitutionRight() ).toBeUndefined()
            expect( m.getSubstitutionRequired() ).toBeUndefined()

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
            expect( c.hasSubstitution() ).toBeFalsy()
            expect( c.pattern ).toBeUndefined()
            expect( c.expression ).toBeUndefined()

Add some things to each part of `m`, then verify that `c` has not changed.

            pattern = quick 'f(x)'
            expression = quick 't(u)'
            left = quick 'a'
            right = quick 'b'
            m.storeTopmostPair pattern, expression
            m.setSubstitution OM.app Match.optionalSubstitution,
                OM.int( 3 ), left, right
            m.set 'A', left
            m.set 'B', right
            expect( m is c ).toBeFalsy()
            expect( c.keys() ).toEqual [ ]
            expect( c.hasSubstitution() ).toBeFalsy()
            expect( c.pattern ).toBeUndefined()
            expect( c.expression ).toBeUndefined()

Make a second copy of `m` and verify that all this new data is preserved
into the copy.

            c2 = m.copy()
            expect( c2.keys().sort() ).toEqual [ 'A', 'B' ]
            expect( c2.get( 'A' ).equals left ).toBeTruthy()
            expect( c2.get( 'B' ).equals right ).toBeTruthy()
            expect( c2.hasSubstitution() ).toBeTruthy()
            expect( c2.getSubstitutionLeft().equals left ).toBeTruthy()
            expect( c2.getSubstitutionRight().equals right ).toBeTruthy()
            expect( c2.getSubstitutionRequired() ).toBeFalsy()
            expect( c2.pattern.sameObjectAs pattern ).toBeTruthy()
            expect( c2.expression.sameObjectAs expression ) \
                .toBeTruthy()

### should be able to complete themselves

Match objects can complete themselves to ensure that all metavariables in
the pattern have an instantiation.  We test that here.

        it 'should be able to complete themselves', ->

Construct an empty match object and specify its pattern and expression.  It
should have absolutely no variables instantiated, so when asked to complete
itself, it should assign unused variables to all the metavariables in the
pattern.

            m = new Match
            pattern = quick '_mv1(_mv2)'
            expression = quick 'f(x)'
            m.storeTopmostPair pattern, expression
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'unused_1' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_2' ).toBeTruthy()

Repeat the same test, but this time assign to some of the variables in the
pattern first, and ensure those remain unchanged by the completion.

            m = new Match
            pattern = quick '_mv1(_mv2)'
            expression = quick 'f(x)'
            m.storeTopmostPair pattern, expression
            m.set 'mv1', quick 'example'
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'example' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_1' ).toBeTruthy()

Repeat the same test, but this time put some instances of variables with
names of the form "unused_n" into the pattern to ensure that it avoids them.

            m = new Match
            pattern = quick '_mv1(_mv2,unused_21(unused_14))'
            expression = quick 'f(x)'
            m.storeTopmostPair pattern, expression
            m.set 'mv1', quick 'example'
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'example' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_22' ).toBeTruthy()

Repeat the same test, but this time put some instances of variables with
names of the form "unused_n" into the expression also, to ensure that it
avoids them as well.

            m = new Match
            pattern = quick '_mv1(_mv2,unused_21(unused_14))'
            expression = quick 'f(x,unused_100)'
            m.storeTopmostPair pattern, expression
            m.set 'mv1', quick 'example'
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'example' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_101' ).toBeTruthy()

Repeat the same test, but this time put some instances of variables with
names of the form "unused_n" into the instantiations also, to ensure that it
avoids them as well.

            m = new Match
            pattern = quick '_mv1(_mv2,unused_21(unused_14))'
            expression = quick 'f(x,unused_100)'
            m.storeTopmostPair pattern, expression
            m.set 'mv1', quick 'unused_345'
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'unused_345' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_346' ).toBeTruthy()

## Matching

This section is the most important in this test suite, and checks many cases
of the main pattern-matching algorithm.

    describe 'The pattern-matching algorithm', ->

### should work for atomic patterns

The following tests are for the case where the pattern is atomic, first when
it is not a metavariable, then when it is.

        it 'should work for atomic patterns', ->

Matching `a` to `a` should yield `[ { } ]`.

            result = matches quick( 'a' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Matching `a` to `b` should yield `[ ]`.

            result = matches quick( 'a' ), quick( 'b' )
            expect( result ).toEqual [ ]

Matching `a` to `2` should yield `[ ]`.

            result = matches quick( 'a' ), quick( '2' )
            expect( result ).toEqual [ ]

Matching `a` to `f(x)` should yield `[ ]`.

            result = matches quick( 'a' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Matching `9` to `a` should yield `[ { } ]`.

            result = matches quick( '9' ), quick( '9' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Matching `9` to `b` should yield `[ ]`.

            result = matches quick( '9' ), quick( 'b' )
            expect( result ).toEqual [ ]

Matching `9` to `2` should yield `[ ]`.

            result = matches quick( '9' ), quick( '2' )
            expect( result ).toEqual [ ]

Matching `9` to `f(x)` should yield `[ ]`.

            result = matches quick( '9' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Matching `"slow"` to `a` should yield `[ { } ]`.

            result = matches quick( '"slow"' ), quick( '"slow"' )
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Matching `"slow"` to `b` should yield `[ ]`.

            result = matches quick( '"slow"' ), quick( 'b' )
            expect( result ).toEqual [ ]

Matching `"slow"` to `2` should yield `[ ]`.

            result = matches quick( '"slow"' ), quick( '2' )
            expect( result ).toEqual [ ]

Matching `"slow"` to `f(x)` should yield `[ ]`.

            result = matches quick( '"slow"' ), quick( 'f(x)' )
            expect( result ).toEqual [ ]

Matching `_A` (now a metavariable, following the notational convention in
the `quick` function defined at the top of this test file) to anything
should yield `[ A : thing ]`.

            result = matches quick( '_A' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            result = matches quick( '_A' ), quick( '23645' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick '23645' ).toBeTruthy()
            result = matches quick( '_A' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f(x)' ).toBeTruthy()

### should work for compound patterns

The following tests are for the case where the pattern is compound,
including application, binding, and error types.  No substitution patterns
are tested yet; they appear in later tests.  (Actually, error types are of
little importance to most of our uses, and function so much like
application types that we have little to no tests of error types below.)

        it 'should work for compound patterns', ->

First, applications:

Matching `_A(x)` to `f(x)` should yield `[ { A : f } ]`.

            result = matches quick( '_A(x)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `_A(_B)` to `f(x)` should yield `[ { A : f, B : x } ]`.

            result = matches quick( '_A(_B)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()

Matching `_A(_B)` to `f(x,y)` should yield `[ ]`.

            result = matches quick( '_A(_B)' ), quick( 'f(x,y)' )
            expect( result ).toEqual [ ]

Matching `_A(_B)` to `f()` should yield `[ ]`.

            result = matches quick( '_A(_B)' ), quick( 'f()' )
            expect( result ).toEqual [ ]

Matching `_A(_B)` to `some_var` should yield `[ ]`.

            result = matches quick( '_A(_B)' ), quick( 'some_var' )
            expect( result ).toEqual [ ]

Next, bindings:

Matching `_A.A(x,y)` to `f.f[x,y]` should yield `[ { A : f.f } ]`.

            result = matches quick( '_A.A[x,y]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A.A' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y]` should yield
`[ { A.A : f.f, B : x, C : y } ]`.

            result = matches quick( '_A.A[_B,_C]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual \
                [ 'A.A', 'B', 'C' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'y' ).toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y,z]` should yield `[ ]`.

            result = matches quick( '_A.A(_B,_C)' ), quick( 'f.f[x,y,z]' )
            expect( result ).toEqual [ ]

Matching `_A.A[_B,_C,_D]` to `f.f[x,y]` should yield `[ ]`.

            result = matches quick( '_A.A(_B,_C,_D)' ), quick( 'f.f[x,y]' )
            expect( result ).toEqual [ ]

Matching `_A.A[_B,_C]` to `some_var` should yield `[ ]`.

            result = matches quick( '_A.A[_B,_C]' ), quick( 'some_var' )
            expect( result ).toEqual [ ]

### should ignore attributes

We repeat a selection of the above tests, now adding attributes to some of
the nodes in either the pattern or the expression, and verifying that the
results are exactly the same in all cases.

        it 'should ignore attributes', ->

Matching `a` to `a` should yield `[ { } ]`.

            left = quick 'a'
            right = quick 'a'
            left.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].map ).toEqual { }

Matching `_A` to `a` should yield `[ { A : a } ]`.

            left = quick '_A'
            right = quick 'a'
            right.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals right, no ).toBeTruthy()

Matching `_A(x)` to `f(x)` should yield `[ { A : f } ]`.

            left = quick '_A(x)'
            right = quick 'f(x)'
            left.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer 200
            right.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer -1
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y]` should yield
`[ { A.A : f.f, B : x, C : y } ]`.

            left = quick '_A.A[_B,_C]'
            right = quick 'f.f[x,y]'
            left.setAttribute OM.symbol( 'thing1', 'thing2' ),
                OM.simple 'f(x)'
            right.setAttribute OM.symbol( 'santy', 'claus' ),
                OM.simple 'g(y)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual \
                [ 'A.A', 'B', 'C' ]
            expect( result[0].get( 'A.A' ).equals quick 'f.f' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'y' ).toBeTruthy()

### should handle simple substitutions

This is the first test of the matching algorithm's ability to handle
substitution expressions (i.e., `x[y=z]` or `x[y~z]`).  These are the
smallest tests of that type.

        it 'should handle simple substitutions', ->

Matching `f(x)` to `f(x)[x=y]` should yield `[ ]`.

            left = quick 'f(x)'
            right = reqSub 'f(x)', 'x', 'y'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `f(x)` to `f(x)[z=y]` should yield `[ { } ]`.

            left = quick 'f(x)'
            right = reqSub 'f(x)', 'z', 'y'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Matching `f(x)` to `f(z)[z=x]` should yield `[ { } ]`.

            left = quick 'f(x)'
            right = reqSub 'f(z)', 'z', 'x'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Matching `for.all[x,f(x)]` to `for.all[x,f(x)[z=y]]` should yield `[ ]`.

            left = quick 'for.all[x,f(x)]'
            right = OM.binding quick( 'for.all' ), quick( 'x' ),
                reqSub 'f(x)', 'x', 'y'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `for.all[x,f(x)]` to `for.all[x,f(x)][z=y]` should yield `[ { } ]`.

            left = quick 'for.all[x,f(x)]'
            right = reqSub quick( 'for.all[x,f(x)]' ), 'x', 'y'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Repeats of all the above tests with the pattern and expression swapped:

            left = quick 'f(x)'
            right = reqSub 'f(x)', 'x', 'y'
            result = matches right, left
            expect( result ).toEqual [ ]
            left = quick 'f(x)'
            right = reqSub 'f(x)', 'z', 'y'
            result = matches right, left
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]
            left = quick 'f(x)'
            right = reqSub 'f(z)', 'z', 'x'
            result = matches right, left
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]
            left = quick 'for.all[x,f(x)]'
            right = OM.binding quick( 'for.all' ), quick( 'x' ),
                reqSub 'f(x)', 'x', 'y'
            result = matches right, left
            expect( result ).toEqual [ ]
            left = quick 'for.all[x,f(x)]'
            right = reqSub quick( 'for.all[x,f(x)]' ), 'x', 'y'
            result = matches right, left
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

### should handle compound expression with metavariables

This series of tests involve application and binding expressions that
contain at least one (and usually several) metavariables.

        it 'should handle compound expression with metavariables', ->

Matching `f(_A,_B)` to `f(c,d)` should yield `[ { A : c, B : d } ]`.

            left = quick 'f(_A,_B)'
            right = quick 'f(c,d)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'c' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'd' ).toBeTruthy()

Matching `f(_A,_A)` to `f(c,d)` should yield `[ ]`.

            left = quick 'f(_A,_A)'
            right = quick 'f(c,d)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `f(_A,_B)` to `g(c,d)` should yield `[ ]`.

            left = quick 'f(_A,_B)'
            right = quick 'g(c,d)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `f(_B,_A)` to `f(c,d)` should yield `[ { A : d, B : c } ]`.

            left = quick 'f(_B,_A)'
            right = quick 'f(c,d)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'd' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'c' ).toBeTruthy()

Matching `f(_A,_A)` to `f(c,c)` should yield `[ { A : c } ]`.

            left = quick 'f(_A,_A)'
            right = quick 'f(c,c)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'c' ).toBeTruthy()

Matching `f(g(_A),k(_A))` to `f(g(a),k(a))` should yield `[ { A : a } ]`.

            left = quick 'f(g(_A),k(_A))'
            right = quick 'f(g(a),k(a))'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()

Matching `f(g(_A),_B)` to `f(g(a),k(a))` should yield
`[ { A : a, B : k(a) } ]`.

            left = quick 'f(g(_A),_B)'
            right = quick 'f(g(a),k(a))'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'k(a)' ).toBeTruthy()

Matching `f(_A(c),_A(_B))` to `f(g(c),k(c))` should yield `[ ]`.

            left = quick 'f(_A(c),_A(_B))'
            right = quick 'f(g(c),k(c))'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `f(g(_A),_A(_B))` to `f(g(c),c(k))` should yield
`[ A : c, B : k ]`.

            left = quick 'f(g(_A),_A(_B))'
            right = quick 'f(g(c),c(k))'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'c' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'k' ).toBeTruthy()

We now repeat a selection of the above tests using bindings instead of
applications.

            left = quick 'f.f[_A,_A]'
            right = quick 'f.f[c,d]'
            result = matches left, right
            expect( result ).toEqual [ ]
            left = quick 'f.f[_A,_A]'
            right = quick 'f.f[c,c]'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'c' ).toBeTruthy()
            left = quick 'f.f[c,dummy(_A(c),_A(_B))]'
            right = quick 'f.f[c,dummy(g(c),k(c))]'
            result = matches left, right
            expect( result ).toEqual [ ]
            left = quick 'f(g.g[v,_A.A],_A.A[_B,_B])'
            right = quick 'f(g.g[v,c.c],c.c[k,k])'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A.A', 'B' ]
            expect( result[0].get( 'A.A' ).equals quick 'c.c' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'k' ).toBeTruthy()

### should handle instances of universal elimination

The desktop version of Lurch (v0.8) came with libraries defining the
universal elimination rule of first-order logic as follows.  From forall x,
A, conclude A[x=t].  We test several valid and invalid uses of the rule,
ensuring that the matching algorithm approves of the valid ones and
disapproves of the invalid ones.

For the sake of brevity, we encode the universal quantifier as the symbol
`for.all`, below.  To form a rule from a sequence of one or more statements,
we simply put them in a list, as in `list(expr1,...,exprN)`.

        it 'should handle instances of universal elimination', ->

In each test below, the rule to match is the following.

            rule = OM.app OM.var( 'list' ),
                quick( 'for.all[_X,_A]' ), reqSub '_A', '_X', '_T'

The instance of the rule will vary from test to test (and will sometimes not
actually *be* an instance of the rule, at which point we expect the patterns
not to match).

Matching the rule to `list( for.all[x,f(x)=f(y)] , f(6)=f(y) )` should yield
`[ { X : x, A : f(x)=f(y), T : 6 } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[x,eq(f(x),f(y))]' ),
                quick( 'eq(f(6),f(y))' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'eq(f(x),f(y))' ) \
                .toBeTruthy()
            expect( result[0].get( 'T' ).equals quick '6' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to `list( for.all[x,P(x,x)] , P(7.1,7.1) )` should yield
`[ { X : x, A : P(x,x), T : 7.1 } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[x,P(x,x)]' ), quick( 'P(7.1,7.1)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'P(x,x)' ) \
                .toBeTruthy()
            expect( result[0].get( 'T' ).equals quick '7.1' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to `list( for.all[x,P(x,x)] , P(3,4) )` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[x,P(x,x)]' ), quick( 'P(3,4)' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements
`for.all[x,and(gt(x,7),for.all[y,P(x,y)])]` and
`and(gt(9,7),for.all[y,P(9,y)])` should yield
`[ { X : x, A : and(gt(x,7),for.all[y,P(x,y)]), T : 9 } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[x,and(gt(x,7),for.all[y,P(x,y)])]' ),
                quick( 'and(gt(9,7),for.all[y,P(9,y)])' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals \
                quick 'and(gt(x,7),for.all[y,P(x,y)])' ).toBeTruthy()
            expect( result[0].get( 'T' ).equals quick '9' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to the statements
`for.all[x,and(gt(x,7),for.all[y,P(x,y)])]` and
`and(gt(9,7),for.all[y,P(x,y)])` should yield `[ ]`.

This test is exactly the same as the previous, except that not all instances
of x have been replaced by 9.  The universal elmination rule requires that
all instances be replaced, not just some, so this should not match.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[x,and(gt(x,7),for.all[y,P(x,y)])]' ),
                quick( 'and(gt(9,7),for.all[y,P(x,y)])' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements `for.all[A,f(X,A)]` and `f(X,X)` should
yield `[ { X : A, A : f(X,A), T : X } ]`.

Note that this test intentionally uses variables that have exactly the same
names as metavariables, to test whether this causes confusion for the
matching algorithm.

            instance = OM.app OM.var( 'list' ),
                quick( 'for.all[A,f(X,A)]' ), quick( 'f(X,X)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'f(X,A)' ) \
                .toBeTruthy()
            expect( result[0].get( 'T' ).equals quick 'X' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'A' ).toBeTruthy()

### should handle instances of existential elimination

The desktop version of Lurch (v0.8) came with libraries defining the
existential elimination rule of first-order logic as follows.  From
exists x, A and the declaration of c as a constant, conclude A[x=c].  We
test several valid and invalid uses of the rule, ensuring that the matching
algorithm approves of the valid ones and disapproves of the invalid ones.

For the sake of brevity, we encode the existential quantifier as the symbol
`exi.sts`, below.  We will also abbreviate constant declarations using the
symbol `dec.con`.  We form rules using `list` as in earlier tests in this
file.

        it 'should handle instances of existential elimination', ->

In each test below, the rule to match is the following.

            rule = OM.app OM.var( 'list' ),
                quick( 'exi.sts[_X,_A]' ), quick( 'dec.con(_C)' ),
                reqSub '_A', '_X', '_C'

The instance of the rule will vary from test to test (and will sometimes not
actually *be* an instance of the rule, at which point we expect the patterns
not to match).

Matching the rule to
`list( exi.sts[t,lt(sq(t),0)] , dec.con(r), lt(sq(r),0) )` should yield
`[ { X : t, A : lt(sq(t),0), C : r } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(t),0)]' ), quick( 'dec.con(r)' )
                quick( 'lt(sq(r),0)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(sq(t),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'r' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to
`list( exi.sts[t,lt(sq(t),0)] , dec.con(r), lt(sq(t),0) )` should yield
`[ ]`.

This test is exactly the same as the previous, except that the variable t
appears in the final step rather than the variable r.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(t),0)]' ), quick( 'dec.con(r)' )
                quick( 'lt(sq(t),0)' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to
`list( exi.sts[t,lt(sq(t),0)] , dec.con(t), lt(sq(r),0) )` should yield
`[ ]`.

This test is exactly the same as the previous, except that the t and r in
the last two steps have been swapped.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(t),0)]' ), quick( 'dec.con(t)' )
                quick( 'lt(sq(r),0)' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to
`list( exi.sts[t,lt(sq(t),0)] , dec.con(t), lt(sq(t),0) )` should yield
`[ { X : t, A : lt(sq(t),0), C : t } ]`.

This is the same as the first test in this section, but with t's instead of
r's.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(t),0)]' ), quick( 'dec.con(t)' )
                quick( 'lt(sq(t),0)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(sq(t),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 't' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to
`list( exi.sts[t,lt(sq(t),0)] , dec.con(plus(sq(phi),9)), lt(sq(plus(sq(phi),9)),0) )` should yield
`[ { X : t, A : lt(sq(t),0), C : plus(sq(phi),9) } ]`.

This is the same as the first test in this section, but with a larger
expression instead of r.  That would not actually be valid in desktop Lurch,
because you cannot declare any thing but a single identifier to be a
constant, but it is a valid pattern match, which is what we're testing here.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(t),0)]' ),
                quick( 'dec.con(plus(sq(phi),9))' )
                quick( 'lt(sq(plus(sq(phi),9)),0)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(sq(t),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'plus(sq(phi),9)' ) \
                .toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to
`list( exi.sts[t,lt(sq(r),0)] , dec.con(r), lt(sq(r),0) )` should yield
`[ { X : t, A : lt(sq(r),0), C : r } ]`.

This is similar to several earlier tests in this section.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[t,lt(sq(r),0)]' ), quick( 'dec.con(r)' )
                quick( 'lt(sq(r),0)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(sq(r),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'r' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to
`list( exi.sts[r,lt(sq(r),0)] , dec.con(r), lt(sq(r),0) )` should yield
`[ { X : r, A : lt(sq(r),0), C : r } ]`.

This is similar to several earlier tests in this section.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[r,lt(sq(r),0)]' ), quick( 'dec.con(r)' )
                quick( 'lt(sq(r),0)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(sq(r),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'r' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'r' ).toBeTruthy()

Matching the rule to
`list( exi.sts[C,lt(A,C)] , dec.con(X), lt(A,X) )` should yield
`[ { X : C, A : lt(A,C), C : X } ]`.

Note that this test intentionally uses variables that have exactly the same
names as metavariables, to test whether this causes confusion for the
matching algorithm.

            instance = OM.app OM.var( 'list' ),
                quick( 'exi.sts[C,lt(A,C)]' ), quick( 'dec.con(X)' )
                quick( 'lt(A,X)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'C', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'lt(A,C)' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'X' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'C' ).toBeTruthy()

### should handle instances of universal introduction

The desktop version of Lurch (v0.8) came with libraries defining the
universal introduction rule of first-order logic as follows.  From a
variable introduction of v and any statement A, conclude forall x, A[v=x].
We test several valid and invalid uses of the rule, ensuring that the
matching algorithm approves of the valid ones and disapproves of the invalid
ones.

The same uses of `for.all` and `list` apply as in earlier tests.  We declare
variables with the symbol `dec.var`.

        it 'should handle instances of universal introduction', ->

In each test below, the rule to match is the following.

            rule = OM.app OM.var( 'list' ),
                quick( 'dec.var(_V)' ), quick( '_A' ),
                OM.bin quick( 'for.all' ), quick( '_X' ),
                    reqSub '_A', '_V', '_X'

The instance of the rule will vary from test to test (and will sometimes not
actually *be* an instance of the rule, at which point we expect the patterns
not to match).

Matching the rule to
`list( dec.var(x), gt(sq(x),0), for.all[t,gt(sq(t),0)] )` should yield
`[ { V : x, A : gt(sq(x),0), X : t } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(x)' ), quick( 'gt(sq(x),0)' )
                quick( 'for.all[t,gt(sq(t),0)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'V', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'gt(sq(x),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'V' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to
`list( dec.var(x), gt(sq(x),0), for.all[x,gt(sq(x),0)] )` should yield
`[ { V : x, A : gt(sq(x),0), X : x } ]`.

This is the same as the previous test, but with all t's replaced by x's.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(x)' ), quick( 'gt(sq(x),0)' )
                quick( 'for.all[x,gt(sq(x),0)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'V', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'gt(sq(x),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'V' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to
`list( dec.var(x), gt(sq(x),0), for.all[x,gt(sq(t),0)] )` should yield
`[ ]`.

This is the same as the previous test, but with one variable renamed to be
inconsistent with the rest, and hence the match should fail.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(x)' ), quick( 'gt(sq(x),0)' )
                quick( 'for.all[x,gt(sq(t),0)]' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to
`list( dec.var(x), gt(sq(t),0), for.all[x,gt(sq(x),0)] )` should yield
`[ ]`.

This is the same as the previous test, but with a different variable renamed
to be inconsistent with the rest, and hence the match should fail.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(x)' ), quick( 'gt(sq(t),0)' )
                quick( 'for.all[x,gt(sq(x),0)]' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to
`list( dec.var(x), gt(sq(t),0), for.all[x,gt(sq(t),0)] )` should yield
`[ { V : x, A : gt(sq(t),0), X : x } ]`.

This is the same as the first test in this section, but here the quantifier
does not bind any variables.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(x)' ), quick( 'gt(sq(t),0)' )
                quick( 'for.all[x,gt(sq(t),0)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'V', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'gt(sq(t),0)' ) \
                .toBeTruthy()
            expect( result[0].get( 'V' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to
`list( dec.var(V), hi(A,V), for.all[X,hi(A,X)] )` should yield
`[ { V : V, A : hi(A,V), X : X } ]`.

Note that this test intentionally uses variables that have exactly the same
names as metavariables, to test whether this causes confusion for the
matching algorithm.

            instance = OM.app OM.var( 'list' ),
                quick( 'dec.var(V)' ), quick( 'hi(A,V)' )
                quick( 'for.all[X,hi(A,X)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'V', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'hi(A,V)' ) \
                .toBeTruthy()
            expect( result[0].get( 'V' ).equals quick 'V' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'X' ).toBeTruthy()

### should handle instances of existential introduction

The desktop version of Lurch (v0.8) came with libraries defining the
existential introduction rule of first-order logic as follows.  You may
conclude exists x, A from any statement of the form A[x=t].  We test several
valid and invalid uses of the rule, ensuring that the matching algorithm
approves of the valid ones and disapproves of the invalid ones.

The same uses of `exi.sts` and `list` apply as in earlier tests.

        it 'should handle instances of existential introduction', ->

In each test below, the rule to match is the following.

            rule = OM.app OM.var( 'list' ),
                reqSub( '_A', '_X', '_T' ), quick 'exi.sts[_X,_A]'

The instance of the rule will vary from test to test (and will sometimes not
actually *be* an instance of the rule, at which point we expect the patterns
not to match).

Matching the rule to the statements
`and(in(5,nat),notin(5,evens))` and
`exi.sts[t,and(in(t,nat),notin(t,evens))]` should yield
`[ { A : and(in(t,nat),notin(t,evens)), X : t, T : 5 } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'and(in(5,nat),notin(5,evens))' ),
                quick( 'exi.sts[t,and(in(t,nat),notin(t,evens))]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals \
                quick 'and(in(t,nat),notin(t,evens))' ).toBeTruthy()
            expect( result[0].get( 'T' ).equals quick '5' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 't' ).toBeTruthy()

Matching the rule to the statements
`uncble(minus(reals,rats))` and
`exi.sts[S,uncble(S)]` should yield
`[ { A : uncble(S), X : S, T : minus(reals,rats) } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'uncble(minus(reals,rats))' ),
                quick( 'exi.sts[S,uncble(S)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'uncble(S)' ) \
                .toBeTruthy()
            expect( result[0].get( 'T' ).equals \
                quick 'minus(reals,rats)' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'S' ).toBeTruthy()

Matching the rule to the statements
`uncble(k)` and `exi.sts[S,uncble(S)]` should yield
`[ { A : uncble(S), X : S, T : minus(reals,rats) } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'uncble(k)' ),
                quick( 'exi.sts[S,uncble(S)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'uncble(S)' ) \
                .toBeTruthy()
            expect( result[0].get( 'T' ).equals quick 'k' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'S' ).toBeTruthy()

Matching the rule to the statements
`and(in(4,nat),notin(5,evens))` and
`exi.sts[t,and(in(t,nat),notin(t,evens))]` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'and(in(4,nat),notin(5,evens))' ),
                quick( 'exi.sts[t,and(in(t,nat),notin(t,evens))]' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements
`and(in(5,nat),notin(4,evens))` and
`exi.sts[t,and(in(t,nat),notin(t,evens))]` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'and(in(5,nat),notin(4,evens))' ),
                quick( 'exi.sts[t,and(in(t,nat),notin(t,evens))]' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements
`and(in(5,nat),notin(5,evens))` and
`exi.sts[x,and(in(t,nat),notin(t,evens))]` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'and(in(5,nat),notin(5,evens))' ),
                quick( 'exi.sts[x,and(in(t,nat),notin(t,evens))]' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements
`and(in(5,nat),notin(5,evens))` and
`exi.sts[x,and(in(5,nat),notin(5,evens))]` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'and(in(5,nat),notin(5,evens))' ),
                quick( 'exi.sts[x,and(in(5,nat),notin(5,evens))]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals \
                quick 'and(in(5,nat),notin(5,evens))' ).toBeTruthy()
            expect( result[0].get( 'T' ).equals \
                quick 'unused_1' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'x' ).toBeTruthy()

Matching the rule to the statements `L` and `exi.sts[M,L]` should yield
`[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'L' ), quick( 'exi.sts[M,L]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'L' ).toBeTruthy()
            expect( result[0].get( 'T' ).equals \
                quick 'unused_1' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'M' ).toBeTruthy()

Matching the rule to the statements `L(M)` and `exi.sts[N,L(N)]` should
yield `[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'L(M)' ), quick( 'exi.sts[N,L(N)]' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'T', 'X' ]
            expect( result[0].get( 'A' ).equals quick 'L(N)' ).toBeTruthy()
            expect( result[0].get( 'T' ).equals quick 'M' ).toBeTruthy()
            expect( result[0].get( 'X' ).equals quick 'N' ).toBeTruthy()

### should handle instances of equality elimination

The desktop version of Lurch (v0.8) came with libraries defining the
equality elimination rule of first-order logic as follows.  From any
equation a=b and any statement S, you may conclude S[a~b] and/or S[b~a]. For
a rule with multiple conclusions, we consider only one of the conclusions at
a time; the matching algorithm would be applied separately for each
conclusion.  Thus here we take only the conclusion S[a~b].  We test several
valid and invalid uses of the rule, ensuring that the matching algorithm
approves of the valid ones and disapproves of the invalid ones.

The same use of `list` applies as in earlier tests.  We use here the symbol
`e.q` to mean "equals."

        it 'should handle instances of equality elimination', ->

In each test below, the rule to match is the following.

            rule = OM.app OM.var( 'list' ),
                quick( 'e.q(_A,_B)' ), quick( '_S' ),
                optSub( '_S', '_A', '_B' )

The instance of the rule will vary from test to test (and will sometimes not
actually *be* an instance of the rule, at which point we expect the patterns
not to match).

Matching the rule to the statements `x=7`, `f(x)=y`, and `f(7)=y`
should yield `[ { A : x, B : 7, S : f(x)=y } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'e.q(x,7)' ), quick( 'e.q(f(x),y)' ),
                quick( 'e.q(f(7),y)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B', 'S' ]
            expect( result[0].get( 'A' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick '7' ).toBeTruthy()
            expect( result[0].get( 'S' ).equals \
                quick 'e.q(f(x),y)' ).toBeTruthy()

Matching the rule to the statements `x=7`, `f(x)=y`, and `f(7)=7`
should yield `[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'e.q(x,7)' ), quick( 'e.q(f(x),y)' ),
                quick( 'e.q(f(7),7)' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements `f(x)=y`, `x=7`, and `f(7)=7`
should yield `[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'e.q(f(x),y)' ), quick( 'e.q(x,7)' ),
                quick( 'e.q(f(7),7)' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements `a=b`, `a=a`, and `b=a`
should yield `[ { A : a, B : b, S : a=a } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( 'e.q(a,b)' ), quick( 'e.q(a,a)' ),
                quick( 'e.q(b,a)' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B', 'S' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'b' ).toBeTruthy()
            expect( result[0].get( 'S' ).equals \
                quick 'e.q(a,a)' ).toBeTruthy()

Matching the rule to the statements `2^n-1=sum(i,0,n-1,2^i)`,
`(2^n-1)+1=2^n`, and `sum(i,0,n-1,2^i)+1=2^n` should yield `[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( \
                    'e.q(minus(pow(2,n),1),sum(i,0,minus(n,1),pow(2,i)))' ),
                quick( 'e.q(plus(minus(pow(2,n),1),1),pow(2,n))' ),
                quick( 'e.q(plus(sum(i,0,minus(n,1),pow(2,i))),pow(2,n))' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements `sum(i,0,n-1,2^i)=2^n-1`,
`(2^n-1)+1=2^n`, and `sum(i,0,n-1,2^i)+1=2^n` should yield `[ ]`.

            instance = OM.app OM.var( 'list' ),
                quick( \
                    'e.q(sum(i,0,minus(n,1),pow(2,i)),minus(pow(2,n),1))' ),
                quick( 'e.q(plus(minus(pow(2,n),1),1),pow(2,n))' ),
                quick( \
                    'e.q(plus(sum(i,0,minus(n,1),pow(2,i)),1),pow(2,n))' )
            result = matches rule, instance
            expect( result ).toEqual [ ]

Matching the rule to the statements `2^n-1=sum(i,0,n-1,2^i)`,
`(2^n-1)+1=2^n`, and `sum(i,0,n-1,2^i)+1=2^n` should yield
`[ { A : 2^n-1, B : sum(i,0,n-1,2^i), S : (2^n-1)+1=2^n } ]`.

            instance = OM.app OM.var( 'list' ),
                quick( \
                    'e.q(minus(pow(2,n),1),sum(i,0,minus(n,1),pow(2,i)))' ),
                quick( 'e.q(plus(minus(pow(2,n),1),1),pow(2,n))' ),
                quick( \
                    'e.q(plus(sum(i,0,minus(n,1),pow(2,i)),1),pow(2,n))' )
            result = matches rule, instance
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B', 'S' ]
            expect( result[0].get( 'A' ).equals \
                quick 'minus(pow(2,n),1)' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals \
                quick 'sum(i,0,minus(n,1),pow(2,i))' ).toBeTruthy()
            expect( result[0].get( 'S' ).equals \
                quick 'e.q(plus(minus(pow(2,n),1),1),pow(2,n))' ) \
                .toBeTruthy()

### should handle harder substitution situations

Here are a few small but strange and nasty tests of the way the matching
algorithm handles substitution expressions.

        it 'should handle harder substitution situations', ->

Matching `(a=b)[_X=_Y]` to `a=b` should yield
`[ { X : unused_1, Y : unused_2 } ]`.

            left = reqSub 'e.q(a,b)', '_X', '_Y'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'X', 'Y' ]
            expect( result[0].get( 'X' ).equals quick 'unused_1' ) \
                .toBeTruthy()
            expect( result[0].get( 'Y' ).equals quick 'unused_2' ) \
                .toBeTruthy()

Matching `(a=b)[_X=a]` to `a=b` should yield `[ { X : unused_1 } ]`.

            left = reqSub 'e.q(a,b)', '_X', 'a'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'X' ]
            expect( result[0].get( 'X' ).equals quick 'unused_1' ) \
                .toBeTruthy()

Matching `(a=b)[a=_Y]` to `a=b` should yield `[ { Y : a } ]`.

            left = reqSub 'e.q(a,b)', 'a', '_Y'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'Y' ]
            expect( result[0].get( 'Y' ).equals quick 'a' ).toBeTruthy()

Matching `(a=b)[_X=_Y]` to `a=b` should yield
`[ { X : unused_1, Y : unused_2 } ]`.

            left = reqSub 'e.q(a,b)', '_X', '_Y'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'X', 'Y' ]
            expect( result[0].get( 'X' ).equals quick 'unused_1' ) \
                .toBeTruthy()
            expect( result[0].get( 'Y' ).equals quick 'unused_2' ) \
                .toBeTruthy()

Matching `(a=b)[a=b]` to `a=b` should yield `[ ]`.

            left = reqSub 'e.q(a,b)', 'a', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `(a=b)[a~b]` to `a=b` should yield `[ { } ]`.

            left = optSub 'e.q(a,b)', 'a', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Matching `(a=b)[a=c]` to `a=b` should yield `[ ]`.

            left = reqSub 'e.q(a,b)', 'a', 'c'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `(a=b)[a~c]` to `a=b` should yield `[ { } ]`.

            left = optSub 'e.q(a,b)', 'a', 'c'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Matching `(a=b)[a=a]` to `a=b` should yield `[ { } ]`.

            left = reqSub 'e.q(a,b)', 'a', 'a'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ ]

Matching `_A[a=b]` to `a=b` should yield `[ ]`.

            left = reqSub '_A', 'a', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `_A[a~b]` to `a=b` should yield `[ { A : a=b } ]`.

            left = optSub '_A', 'a', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'e.q(a,b)' ) \
                .toBeTruthy()

Matching `_A[c=b]` to `a=b` should yield `[ { A : a=b } ]`.

            left = reqSub '_A', 'c', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'e.q(a,b)' ) \
                .toBeTruthy()

Matching `_A[c~b]` to `a=b` should yield `[ { A : a=b } ]`.

            left = optSub '_A', 'c', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'e.q(a,b)' ) \
                .toBeTruthy()

Matching `_A[_B=b]` to `a=b` should yield `[ { A : a=b, B : unused_1 } ]`.

            left = reqSub '_A', '_B', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'e.q(a,b)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'unused_1' ) \
                .toBeTruthy()

Matching `_A[_B~b]` to `a=b` should yield `[ { A : a=b, B : unused_1 } ]`.

            left = optSub '_A', '_B', 'b'
            right = quick 'e.q(a,b)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'e.q(a,b)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'unused_1' ) \
                .toBeTruthy()

Matching `f(f[_A=g])` to `f(g)` should yield `[ { A : f } ]`.

            left = OM.app OM.var( 'f' ), reqSub 'f', '_A', 'g'
            right = quick 'f(g)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `f(f)[_A=g]` to `g(g)` should yield `[ { A : f } ]`.

            left = reqSub 'f(f)', '_A', 'g'
            right = quick 'g(g)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys() ).toEqual [ 'A' ]
            expect( result[0].get( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `f(f[_A=g])` to `g(g)` should yield `[ ]`.

            left = OM.app OM.var( 'f' ), reqSub 'f', '_A', 'g'
            right = quick 'g(g)'
            result = matches left, right
            expect( result ).toEqual [ ]

Matching `f(g(a))[_A=_B]` to `f(g(b))` should yield three matches:
`{ A : a, B : b }`, `{ A : g(a), B : g(b) }`, and
`{ A : f(g(a)), B : f(g(b)) }`.

            left = reqSub 'f(g(a))', '_A', '_B'
            right = quick 'f(g(b))'
            result = matches left, right
            expect( result.length ).toBe 3
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'b' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[1].get( 'A' ).equals quick 'g(a)' ).toBeTruthy()
            expect( result[1].get( 'B' ).equals quick 'g(b)' ).toBeTruthy()
            expect( result[2].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[2].get( 'A' ).equals quick 'f(g(a))' ) \
                .toBeTruthy()
            expect( result[2].get( 'B' ).equals quick 'f(g(b))' ) \
                .toBeTruthy()

Matching `f(g(a),a)[_A=_B]` to `f(g(b),a)` should yield two matches:
`{ A : g(a), B : g(b) }`, and `{ A : f(g(a),a), B : f(g(b),a) }`.

            left = reqSub 'f(g(a),a)', '_A', '_B'
            right = quick 'f(g(b),a)'
            result = matches left, right
            expect( result.length ).toBe 2
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'g(a)' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'g(b)' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[1].get( 'A' ).equals quick 'f(g(a),a)' ) \
                .toBeTruthy()
            expect( result[1].get( 'B' ).equals quick 'f(g(b),a)' ) \
                .toBeTruthy()

Matching `f(g(a),a)[_A~_B]` to `f(g(b),a)` should yield three matches:
`{ A : a, B : b }`, `{ A : g(a), B : g(b) }`, and
`{ A : f(g(a),a), B : f(g(b),a) }`.

            left = optSub 'f(g(a),a)', '_A', '_B'
            right = quick 'f(g(b),a)'
            result = matches left, right
            expect( result.length ).toBe 3
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'b' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[1].get( 'A' ).equals quick 'g(a)' ).toBeTruthy()
            expect( result[1].get( 'B' ).equals quick 'g(b)' ).toBeTruthy()
            expect( result[2].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[2].get( 'A' ).equals quick 'f(g(a),a)' ) \
                .toBeTruthy()
            expect( result[2].get( 'B' ).equals quick 'f(g(b),a)' ) \
                .toBeTruthy()

Matching `f(g(a),a)[_A=_B]` to `f(g(b),c)` should yield
`[ { A : f(g(a),a), B : f(g(b),c) } ]`.

            left = reqSub 'f(g(a),a)', '_A', '_B'
            right = quick 'f(g(b),c)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f(g(a),a)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'f(g(b),c)' ) \
                .toBeTruthy()

Matching `f(g(a),a)[_A~_B]` to `f(g(b),c)` should yield
`[ { A : f(g(a),a), B : f(g(b),c) } ]`.

            left = optSub 'f(g(a),a)', '_A', '_B'
            right = quick 'f(g(b),c)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f(g(a),a)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'f(g(b),c)' ) \
                .toBeTruthy()

Matching `f(a,g(a))[_A=_B]` to `f(a,g(b))` should yield two matches:
`{ A : g(a), B : g(b) }`, and `{ A : f(a,g(a)), B : f(a,g(b)) }`.

            left = reqSub 'f(a,g(a))', '_A', '_B'
            right = quick 'f(a,g(b))'
            result = matches left, right
            expect( result.length ).toBe 2
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'g(a)' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'g(b)' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[1].get( 'A' ).equals quick 'f(a,g(a))' ) \
                .toBeTruthy()
            expect( result[1].get( 'B' ).equals quick 'f(a,g(b))' ) \
                .toBeTruthy()

Matching `f(a,g(a))[_A~_B]` to `f(a,g(b))` should yield three matches:
`{ A : a, B : b }`, `{ A : g(a), B : g(b) }`, and
`{ A : f(a,g(a)), B : f(a,g(b)) }`.

            left = optSub 'f(a,g(a))', '_A', '_B'
            right = quick 'f(a,g(b))'
            result = matches left, right
            expect( result.length ).toBe 3
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'b' ).toBeTruthy()
            expect( result[1].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[1].get( 'A' ).equals quick 'g(a)' ).toBeTruthy()
            expect( result[1].get( 'B' ).equals quick 'g(b)' ).toBeTruthy()
            expect( result[2].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[2].get( 'A' ).equals quick 'f(a,g(a))' ) \
                .toBeTruthy()
            expect( result[2].get( 'B' ).equals quick 'f(a,g(b))' ) \
                .toBeTruthy()

Matching `f(a,g(a))[_A=_B]` to `f(c,g(b))` should yield
`[ { A : f(a,g(a)), B : f(c,g(b)) } ]`.

            left = reqSub 'f(a,g(a))', '_A', '_B'
            right = quick 'f(c,g(b))'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f(a,g(a))' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'f(c,g(b))' ) \
                .toBeTruthy()

Matching `f(a,g(a))[_A~_B]` to `f(c,g(b))` should yield
`[ { A : f(a,g(a)), B : f(c,g(b)) } ]`.

            left = optSub 'f(a,g(a))', '_A', '_B'
            right = quick 'f(c,g(b))'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B' ]
            expect( result[0].get( 'A' ).equals quick 'f(a,g(a))' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'f(c,g(b))' ) \
                .toBeTruthy()

### should handle underspecified substitution situations

An underspecified substitution situation is one in which one or more
metavariables will be unused.  We've seen some such instances in the tests
above, but we test a few more extreme cases here.

        it 'should handle underspecified substitution situations', ->

Matching `_A[_B=_C]` to `any(thing)` should yield
`[ { A : any(thing), B : unused_1, C : unused_2 } ]`.

            left = reqSub '_A', '_B', '_C'
            right = quick 'any(thing)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B', 'C' ]
            expect( result[0].get( 'A' ).equals quick 'any(thing)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'unused_1' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'unused_2' ) \
                .toBeTruthy()

Matching `_A[_B~_C]` to `any(thing)` should yield
`[ { A : any(thing), B : unused_1, C : unused_2 } ]`.

            left = optSub '_A', '_B', '_C'
            right = quick 'any(thing)'
            result = matches left, right
            expect( result.length ).toBe 1
            expect( result[0].keys().sort() ).toEqual [ 'A', 'B', 'C' ]
            expect( result[0].get( 'A' ).equals quick 'any(thing)' ) \
                .toBeTruthy()
            expect( result[0].get( 'B' ).equals quick 'unused_1' ) \
                .toBeTruthy()
            expect( result[0].get( 'C' ).equals quick 'unused_2' ) \
                .toBeTruthy()
