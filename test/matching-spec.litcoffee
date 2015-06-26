
# Tests of the Matching module

Here we import the module we're about to test and the related OM module that
we'll use when testing.

    { Match, setMetavariable, clearMetavariable, isMetavariable } =
        require '../src/matching.duo'
    { OM, OMNode } = require '../src/openmath.duo'

Several times in this test we will want to use the convention that a
variable beginning with an underscore should have the underscore removed,
but then be flagged as a metavariable.  That is, `f(x)` is different from
`_f(x)` only in that the latter will have its head variable `f` marked with
the property of being a metavariable.  To facilitate this, we have the
following convenience function that applies `OM.simple` to a string, then
traverses the resulting tree to apply this convention.

    quick = ( string ) ->
        tree = OM.simple string
        for variable in tree.descendantsSatisfying( ( x ) -> x.type is 'v' )
            if /^_/.test variable.name
                variable.replaceWith OM.simple variable.name[1..]
                setMetavariable variable
        tree

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
            m.setSubstitution left, right, true
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
            m.setSubstitution left, right, false
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

### should correctly track visits

Match objects provide functions for tracking pattern tree traversal, by
marking some subexpressions of the pattern as visited.  We test those
functions here.

        it 'should correctly track visits', ->

Construct a match and verify that it has an empty visited list and no known
pattern.

            m = new Match
            expect( m.getVisitedList() ).toEqual [ ]
            expect( m.getPattern() ).toBeUndefined()
            expect( m.getExpression() ).toBeUndefined()

Construct a pattern and visit its first few nodes.  This should store the
pattern in the match object, but not impact the visited list at all, because
visited lists are only updated when the match object has a substitution
stored.

            pattern = OM.simple 'f(x,lurch.replaceAll(g(y,7),B,C),z)'
            expression = OM.simple 'a(b,c(u,v),d)'
            m.markVisited pattern, expression
            m.markVisited pattern.children[0], expression.children[0]
            m.markVisited pattern.children[1], expression.children[1]
            expect( m.getVisitedList() ).toEqual [ ]
            expect( m.getPattern().sameObjectAs pattern ).toBeTruthy()
            expect( m.getExpression().sameObjectAs expression ).toBeTruthy()

Now store the substitution from the pattern in the match object and visit
the subexpressions of the first replacement child.  Verify that this does
impact the visited nodes list.

            subst = pattern.children[2]
            esub = expression.children[2]
            m.setSubstitution subst.children[1], subst.children[2], true
            m.markVisited subst.children[1], esub.children[1]
            m.markVisited subst.children[1].children[0],
                esub.children[1].children[0]
            m.markVisited subst.children[1].children[1],
                esub.children[1].children[1]
            m.markVisited subst.children[1].children[2],
                esub.children[1].children[2]
            expect( m.getVisitedList().length ).toEqual 4
            expect( m.getVisitedList()[0].sameObjectAs subst.children[1] ) \
                .toBeTruthy()
            expect( m.getVisitedList()[1].sameObjectAs \
                subst.children[1].children[0] ).toBeTruthy()
            expect( m.getVisitedList()[2].sameObjectAs \
                subst.children[1].children[1] ).toBeTruthy()
            expect( m.getVisitedList()[3].sameObjectAs \
                subst.children[1].children[2] ).toBeTruthy()
            expect( m.getPattern().sameObjectAs pattern ).toBeTruthy()
            expect( m.getExpression().sameObjectAs expression ).toBeTruthy()

Remove the substitution and ensure that a further call to `markVisited` has
no impact on the visited list or pattern.

            m.clearSubstitution()
            m.markVisited pattern.children[3], expression.children[3]
            expect( m.getVisitedList().length ).toEqual 4
            expect( m.getVisitedList()[0].sameObjectAs subst.children[1] ) \
                .toBeTruthy()
            expect( m.getVisitedList()[1].sameObjectAs \
                subst.children[1].children[0] ).toBeTruthy()
            expect( m.getVisitedList()[2].sameObjectAs \
                subst.children[1].children[1] ).toBeTruthy()
            expect( m.getVisitedList()[3].sameObjectAs \
                subst.children[1].children[2] ).toBeTruthy()
            expect( m.getPattern().sameObjectAs pattern ).toBeTruthy()
            expect( m.getExpression().sameObjectAs expression ).toBeTruthy()

### should be able to copy themselves

Match objects provide a copy function; we test it briefly here.  No
extensive testing is done, because the copy function is not complex.

        it 'should be able to copy themselves', ->

Construct an empty match and make a copy.  Verify that they have everything
in common.

            m = new Match
            c = m.copy()
            expect( m is c ).toBeFalsy()
            expect( c.variables() ).toEqual [ ]
            expect( c.hasSubstitution() ).toBeFalsy()
            expect( c.getPattern() ).toBeUndefined()
            expect( c.getPattern() ).toBeUndefined()
            expect( c.getVisitedList() ).toEqual [ ]

Add some things to each part of `m`, then verify that `c` has not changed.

            pattern = quick 'f(x)'
            expression = quick 't(u)'
            left = quick 'a'
            right = quick 'b'
            m.markVisited pattern, expression
            m.setSubstitution left, right, false
            m.markVisited pattern.children[0], expression.children[0]
            m.markVisited pattern.children[1], expression.children[1]
            m.set 'A', left
            m.set 'B', right
            expect( m is c ).toBeFalsy()
            expect( c.variables() ).toEqual [ ]
            expect( c.hasSubstitution() ).toBeFalsy()
            expect( c.getPattern() ).toBeUndefined()
            expect( c.getPattern() ).toBeUndefined()
            expect( c.getVisitedList() ).toEqual [ ]

Make a second copy of `m` and verify that all this new data is preserved
into the copy.

            c2 = m.copy()
            expect( c2.variables().sort() ).toEqual [ 'A', 'B' ]
            expect( c2.get( 'A' ).equals left ).toBeTruthy()
            expect( c2.get( 'B' ).equals right ).toBeTruthy()
            expect( c2.hasSubstitution() ).toBeTruthy()
            expect( c2.getSubstitutionLeft().equals left ).toBeTruthy()
            expect( c2.getSubstitutionRight().equals right ).toBeTruthy()
            expect( c2.getSubstitutionRequired() ).toBeFalsy()
            expect( c2.getPattern().sameObjectAs pattern ).toBeTruthy()
            expect( c2.getExpression().sameObjectAs expression ) \
                .toBeTruthy()
            expect( c2.getVisitedList().length ).toBe 2
            expect( c2.getVisitedList()[0].sameObjectAs \
                pattern.children[0] ).toBeTruthy()
            expect( c2.getVisitedList()[1].sameObjectAs \
                pattern.children[1] ).toBeTruthy()

### should be able to complete themselves

Match objects can complete themselves to ensure that all metavariables in
the pattern have an instantiation.  We test that here.

        it 'should be able to complete themselves', ->

Construct an empty match object and then have it visit a pattern and
expression.  It should then have absolutely no variables instantiated, so
when asked to complete itself, it should assign unused variables to all the
metavariables in the pattern.

            m = new Match
            pattern = quick '_mv1(_mv2)'
            expression = quick 'f(x)'
            m.markVisited pattern, expression
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
            m.markVisited pattern, expression
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
            m.markVisited pattern, expression
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
            m.markVisited pattern, expression
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
            m.markVisited pattern, expression
            m.set 'mv1', quick 'unused_345'
            m.complete()
            expect( m.has 'mv1' ).toBeTruthy()
            expect( m.has 'mv2' ).toBeTruthy()
            expect( m.get( 'mv1' ).equals quick 'unused_345' ).toBeTruthy()
            expect( m.get( 'mv2' ).equals quick 'unused_346' ).toBeTruthy()

### Back-checking

We do not test the `backCheckSubstitution()` routine in the Match class,
because it would be complex to contrive all the man situations in which it
would need to be tested.  We already have extensive tests planned for the
actual matching algorithm, which uses `backCheckSubstitution()` constantly,
so we will consider those indirect tests sufficient.

## Matching

This section is the most important in this test suite, and checks many cases
of the main pattern-matching algorithm.

    describe 'The pattern-matching algorithm', ->
        throw 'TESTS NOT YET COMPLETE'
