
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
