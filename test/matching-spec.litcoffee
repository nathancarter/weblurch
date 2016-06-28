
# Tests of the Matching module

Here we import the module we're about to test and the related OM module that
we'll use when testing.

    { setMetavariable, clearMetavariable, isMetavariable, Constraint,
      ConstraintList, makeExpressionFunction, isExpressionFunction,
      makeExpressionFunctionApplication, applyExpressionFunction,
      isExpressionFunctionApplication, findDifferencesBetween,
      parentAddresses, partitionedAddresses, differenceIterator,
      expressionDepth, sameDepthAncestors, subexpressionIterator,
      prefixIterator, suffixIterator, filterIterator, composeIterator,
      concatenateIterators, alphaEquivalent, consistentPatterns,
      multiReplace, nextMatch, setMatchDebug, bindingConstraints1,
      bindingConstraints2, satisfiesBindingConstraints1,
      satisfiesBindingConstraints2 } =
        matching = require '../src/matching-duo'
    { OM, OMNode } = require '../src/openmath-duo'

Several times in this spec we will want to use the convention that a
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

We create two convenience functions for creating expression functions and
applications thereof, as defined in [the matching source
code](#../src/matching-duo.litcoffee).  These use the `quick` function
defined above.

    ef = ( variable, body ) ->
        if variable not instanceof OMNode then variable = quick variable
        if body not instanceof OMNode then body = quick body
        makeExpressionFunction variable, body
    aef = ( func, param ) ->
        if func not instanceof OMNode then func = quick func
        if param not instanceof OMNode then param = quick param
        makeExpressionFunctionApplication func, param

## Global functions and classes

This section tests just the existence and simplest functioning of the main
classes (Constraint, ConstraintList) and some supporting global functions.

    describe 'Global functions and classes', ->

### should be defined

First we verify that the Constraint and ConstraintList classes and the
related functions are defined.

        it 'should be defined', ->
            expect( Constraint ).toBeTruthy()
            expect( ConstraintList ).toBeTruthy()
            expect( setMetavariable ).toBeTruthy()
            expect( clearMetavariable ).toBeTruthy()
            expect( isMetavariable ).toBeTruthy()
            expect( makeExpressionFunction ).toBeTruthy()
            expect( isExpressionFunction ).toBeTruthy()
            expect( makeExpressionFunctionApplication ).toBeTruthy()
            expect( isExpressionFunctionApplication ).toBeTruthy()
            expect( applyExpressionFunction ).toBeTruthy()
            expect( findDifferencesBetween ).toBeTruthy()
            expect( parentAddresses ).toBeTruthy()
            expect( partitionedAddresses ).toBeTruthy()
            expect( expressionDepth ).toBeTruthy()
            expect( sameDepthAncestors ).toBeTruthy()
            expect( differenceIterator ).toBeTruthy()
            expect( subexpressionIterator ).toBeTruthy()
            expect( prefixIterator ).toBeTruthy()
            expect( suffixIterator ).toBeTruthy()
            expect( composeIterator ).toBeTruthy()
            expect( filterIterator ).toBeTruthy()
            expect( concatenateIterators ).toBeTruthy()
            expect( alphaEquivalent ).toBeTruthy()
            expect( consistentPatterns ).toBeTruthy()
            expect( multiReplace ).toBeTruthy()
            expect( nextMatch ).toBeTruthy()
            expect( setMatchDebug ).toBeTruthy()
            expect( bindingConstraints1 ).toBeTruthy()
            expect( bindingConstraints2 ).toBeTruthy()
            expect( satisfiesBindingConstraints1 ).toBeTruthy()
            expect( satisfiesBindingConstraints2 ).toBeTruthy()

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
            expect( isExpressionFunction x ).toBeFalsy()
            expect( isExpressionFunction body1 ).toBeFalsy()
            expect( isExpressionFunction body2 ).toBeFalsy()
            f = makeExpressionFunction x, body1
            g = makeExpressionFunction x, body2
            expect( isExpressionFunction f ).toBeTruthy()
            expect( isExpressionFunction g ).toBeTruthy()

### should reliably make expression function applications

Then we verify that we can make applications of expression functions and
reliably query whether something is such a structure.

        it 'should reliably make expression function applications', ->

Some simple tests should be sufficient here.

            F = OM.simple 'F'
            x = OM.simple 'x'
            y = OM.simple 'y'
            expect( isExpressionFunctionApplication F ).toBeFalsy()
            expect( isExpressionFunctionApplication x ).toBeFalsy()
            expect( isExpressionFunctionApplication y ).toBeFalsy()
            Fx = makeExpressionFunctionApplication F, x
            expect( isExpressionFunctionApplication Fx ).toBeTruthy()
            Fx2 = OM.app F, x
            expect( isExpressionFunctionApplication Fx2 ).toBeFalsy()
            Fx3 = OM.app Fx.symbol, Fx.variables..., Fx.body, y
            expect( isExpressionFunctionApplication Fx3 ).toBeFalsy()

### should correctly apply expression functions to arguments

Test the `applyExpressionFunction` function on a variety of arguments,
paying particular attention to a case with free and bound instances of the
same variable.

        it 'should correctly apply expression functions to arguments', ->
            f = makeExpressionFunction OM.var( 'v' ), OM.simple 'plus(v,2)'
            x = OM.simple 'minus(3,k)'
            result = applyExpressionFunction f, x
            expect( result.equals OM.simple 'plus(minus(3,k),2)' )
                .toBeTruthy()
            f = makeExpressionFunction OM.var( 't' ), OM.simple 't(t(tt))'
            x = OM.simple 'for.all[x,P(x)]'
            result = applyExpressionFunction f, x
            expect( result.equals OM.app x, OM.app x, OM.var 'tt' )
                .toBeTruthy()
            f = makeExpressionFunction OM.var( 'var' ),
                OM.simple 'two(free(var),bou.nd[var,f(var)])'
            x = OM.simple '10'
            result = applyExpressionFunction f, x
            expect( result.equals OM.simple \
                'two(free(10),bou.nd[var,f(var)])' ).toBeTruthy()

### should implement alpha equivalence of expression functions

Creates four similar functions, only two of which are alpha equivalent.
Tests all pairings, in both directions, to ensure symmetry of the relation.

        it 'should implement alpha equivalence of expression functions', ->
            f = makeExpressionFunction OM.var( 'v' ), OM.simple 'plus(v,2)'
            expect( alphaEquivalent f, f ).toBeTruthy()
            g = makeExpressionFunction OM.var( 'w' ), OM.simple 'plus(w,2)'
            expect( alphaEquivalent g, g ).toBeTruthy()
            expect( alphaEquivalent f, g ).toBeTruthy()
            expect( alphaEquivalent g, f ).toBeTruthy()
            h = makeExpressionFunction OM.var( 'v' ), OM.simple 'plus(w,2)'
            expect( alphaEquivalent h, h ).toBeTruthy()
            expect( alphaEquivalent f, h ).toBeFalsy()
            expect( alphaEquivalent h, f ).toBeFalsy()
            expect( alphaEquivalent g, h ).toBeFalsy()
            expect( alphaEquivalent h, g ).toBeFalsy()
            k = makeExpressionFunction OM.var( 'w' ), OM.simple 'plus(w,w)'
            expect( alphaEquivalent k, k ).toBeTruthy()
            expect( alphaEquivalent f, k ).toBeFalsy()
            expect( alphaEquivalent k, f ).toBeFalsy()
            expect( alphaEquivalent g, k ).toBeFalsy()
            expect( alphaEquivalent k, g ).toBeFalsy()
            expect( alphaEquivalent h, k ).toBeFalsy()
            expect( alphaEquivalent k, h ).toBeFalsy()

## Consistent patterns

This section tests the function `consistentPatterns`.

    describe 'Consistent patterns', ->

### should correctly judge consistency of patterns

        it 'should correctly judge consistency of patterns', ->
            p1 = quick 'f(x,y,z)'
            expect( consistentPatterns p1 ).toBeTruthy()
            p2 = quick 'and(f_of_x,g_of_y)'
            expect( consistentPatterns p2 ).toBeTruthy()
            expect( consistentPatterns p1, p2 ).toBeTruthy()
            expect( consistentPatterns p2, p1 ).toBeTruthy()
            p3 = quick '_f(x,y,z)'
            expect( consistentPatterns p3 ).toBeTruthy()
            expect( consistentPatterns p1, p2, p3 ).toBeTruthy()
            p4 = quick 'and(_f_of__x,_g_of__y)'
            expect( consistentPatterns p4 ).toBeTruthy()
            expect( consistentPatterns p1, p4 ).toBeTruthy()
            expect( consistentPatterns p2, p4 ).toBeTruthy()
            expect( consistentPatterns p3, p4 ).toBeFalsy()
            p5 = quick '_f_of__y'
            expect( consistentPatterns p5 ).toBeTruthy()
            expect( consistentPatterns p1, p5 ).toBeTruthy()
            expect( consistentPatterns p2, p5 ).toBeTruthy()
            expect( consistentPatterns p3, p5 ).toBeFalsy()
            expect( consistentPatterns p4, p5 ).toBeTruthy()
            p6 = quick '_f_of__f'
            expect( consistentPatterns p6 ).toBeFalsy()
            expect( consistentPatterns p1, p6 ).toBeFalsy()
            expect( consistentPatterns p1, p2, p3, p4, p5, p6 ).toBeFalsy()
            p7 = quick '_T_of__f'
            expect( consistentPatterns p7 ).toBeTruthy()
            expect( consistentPatterns p1, p2, p7 ).toBeTruthy()
            expect( consistentPatterns p3, p7 ).toBeTruthy()
            expect( consistentPatterns p4, p7 ).toBeFalsy()
            expect( consistentPatterns p5, p7 ).toBeFalsy()
            expect( consistentPatterns p6, p7 ).toBeFalsy()

## Constraint class

This section tests the member functions of the `Constraint` class.

    describe 'The Constraint class', ->

### should construct new instances correctly

        it 'should construct new instances correctly', ->
            p1 = quick '_f(_x)'
            e1 = quick 'a(b)'
            c = new Constraint p1, e1
            expect( c ).toBeTruthy()
            expect( c instanceof Constraint ).toBeTruthy()
            expect( c.pattern.sameObjectAs p1 ).toBeTruthy()
            expect( c.expression.sameObjectAs e1 ).toBeTruthy()

### should make copies correctly

        it 'should make copies correctly', ->
            p1 = quick '_f(_x)'
            e1 = quick 'a(b)'
            c1 = new Constraint p1, e1
            c2 = c1.copy()
            expect( c1 ).toBeTruthy()
            expect( c1 instanceof Constraint ).toBeTruthy()
            expect( c1.pattern.sameObjectAs p1 ).toBeTruthy()
            expect( c1.expression.sameObjectAs e1 ).toBeTruthy()
            expect( c2 ).toBeTruthy()
            expect( c2 instanceof Constraint ).toBeTruthy()
            expect( c2.pattern.equals p1 ).toBeTruthy()
            expect( c2.expression.equals e1 ).toBeTruthy()
            expect( c2.pattern.sameObjectAs p1 ).toBeFalsy()
            expect( c2.expression.sameObjectAs e1 ).toBeFalsy()

### should check equality correctly

        it 'should check equality correctly', ->
            p1 = quick '_f(_x)'
            e1 = quick 'a(b)'
            p2 = quick '_g(_x)'
            e2 = quick 'a(b)'
            p3 = quick '_f(_x)'
            e3 = quick '17'
            c1 = new Constraint p1, e1
            c2 = new Constraint p2, e2
            c3 = new Constraint p3, e3
            c3copy = new Constraint p3.copy(), e3.copy()
            expect( c1 ).toBeTruthy()
            expect( c1 instanceof Constraint ).toBeTruthy()
            expect( c1.equals c1 ).toBeTruthy()
            expect( c2 ).toBeTruthy()
            expect( c2 instanceof Constraint ).toBeTruthy()
            expect( c2.equals c2 ).toBeTruthy()
            expect( c1.equals c2 ).toBeFalsy()
            expect( c2.equals c1 ).toBeFalsy()
            expect( c3 ).toBeTruthy()
            expect( c3 instanceof Constraint ).toBeTruthy()
            expect( c3.equals c3 ).toBeTruthy()
            expect( c1.equals c3 ).toBeFalsy()
            expect( c3.equals c1 ).toBeFalsy()
            expect( c2.equals c3 ).toBeFalsy()
            expect( c3.equals c2 ).toBeFalsy()
            expect( c3copy ).toBeTruthy()
            expect( c3copy instanceof Constraint ).toBeTruthy()
            expect( c3copy.equals c3copy ).toBeTruthy()
            expect( c1.equals c3copy ).toBeFalsy()
            expect( c3copy.equals c1 ).toBeFalsy()
            expect( c2.equals c3copy ).toBeFalsy()
            expect( c3copy.equals c2 ).toBeFalsy()
            expect( c3.equals c3copy ).toBeTruthy()
            expect( c3copy.equals c3 ).toBeTruthy()

## ConstraintList class

This section tests the member functions of the `ConstraintList` class.

    describe 'The ConstraintList class', ->

### should construct instances with right new variable lists

        it 'should construct instances with right new variable lists', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            expect( CL1 ).toBeTruthy()
            expect( CL1 instanceof ConstraintList ).toBeTruthy()
            next = CL1.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v0'
            next = CL1.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v1'
            CL2 = new ConstraintList con1, con2, con3
            expect( CL2 ).toBeTruthy()
            expect( CL2 instanceof ConstraintList ).toBeTruthy()
            next = CL2.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v2'
            next = CL2.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v3'
            CL3 = new ConstraintList con1
            expect( CL3 ).toBeTruthy()
            expect( CL3 instanceof ConstraintList ).toBeTruthy()
            next = CL3.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v0'
            next = CL3.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v1'
            CL4 = new ConstraintList con3
            expect( CL4 ).toBeTruthy()
            expect( CL4 instanceof ConstraintList ).toBeTruthy()
            next = CL4.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v2'
            next = CL4.nextNewVariable()
            expect( next instanceof OM ).toBeTruthy()
            expect( next.type ).toBe 'v'
            expect( next.name ).toBe 'v3'

### should construct instances with right lengths

        it 'should construct instances with right lengths', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            expect( CL1 ).toBeTruthy()
            expect( CL1 instanceof ConstraintList ).toBeTruthy()
            expect( CL1.length() ).toBe 0
            CL2 = new ConstraintList con1, con2, con3
            expect( CL2 ).toBeTruthy()
            expect( CL2 instanceof ConstraintList ).toBeTruthy()
            expect( CL2.length() ).toBe 3
            CL3 = new ConstraintList con1
            expect( CL3 ).toBeTruthy()
            expect( CL3 instanceof ConstraintList ).toBeTruthy()
            expect( CL3.length() ).toBe 1
            CL4 = new ConstraintList con3
            expect( CL4 ).toBeTruthy()
            expect( CL4 instanceof ConstraintList ).toBeTruthy()
            expect( CL4.length() ).toBe 1

### should copy instances correctly

        it 'should copy instances correctly', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            CL1copy = CL1.copy()
            expect( CL1 ).toBeTruthy()
            expect( CL1copy ).toBeTruthy()
            expect( CL1 instanceof ConstraintList ).toBeTruthy()
            expect( CL1copy instanceof ConstraintList ).toBeTruthy()
            expect( CL1.length() ).toBe CL1copy.length()
            expect( CL1.nextNewVariable().equals \
                CL1copy.nextNewVariable() ).toBeTruthy()
            CL2 = new ConstraintList con1, con2, con3
            CL2copy = CL2.copy()
            expect( CL2 ).toBeTruthy()
            expect( CL2copy ).toBeTruthy()
            expect( CL2 instanceof ConstraintList ).toBeTruthy()
            expect( CL2copy instanceof ConstraintList ).toBeTruthy()
            expect( CL2.length() ).toBe CL2copy.length()
            expect( CL2.contents[0].equals \
                CL2copy.contents[0] ).toBeTruthy()
            expect( CL2.contents[1].equals \
                CL2copy.contents[1] ).toBeTruthy()
            expect( CL2.contents[2].equals \
                CL2copy.contents[2] ).toBeTruthy()
            expect( CL2.nextNewVariable().equals \
                CL2copy.nextNewVariable() ).toBeTruthy()
            CL3 = new ConstraintList con1
            CL3copy = CL3.copy()
            expect( CL3 ).toBeTruthy()
            expect( CL3copy ).toBeTruthy()
            expect( CL3 instanceof ConstraintList ).toBeTruthy()
            expect( CL3copy instanceof ConstraintList ).toBeTruthy()
            expect( CL3.length() ).toBe CL3copy.length()
            expect( CL3.contents[0].equals \
                CL3copy.contents[0] ).toBeTruthy()
            expect( CL3.nextNewVariable().equals \
                CL3copy.nextNewVariable() ).toBeTruthy()
            CL4 = new ConstraintList con3
            CL4copy = CL4.copy()
            expect( CL4 ).toBeTruthy()
            expect( CL4copy ).toBeTruthy()
            expect( CL4 instanceof ConstraintList ).toBeTruthy()
            expect( CL4copy instanceof ConstraintList ).toBeTruthy()
            expect( CL4.length() ).toBe CL4copy.length()
            expect( CL4.contents[0].equals \
                CL4copy.contents[0] ).toBeTruthy()
            expect( CL4.nextNewVariable().equals \
                CL4copy.nextNewVariable() ).toBeTruthy()

### should add constraints correctly

        it 'should add constraints correctly', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            CL2 = new ConstraintList con1, con2, con3
            expect( CL1.length() ).toBe 0
            expect( CL2.length() ).toBe 3
            expect( CL2.contents[0] ).toBe con1
            expect( CL2.contents[1] ).toBe con2
            expect( CL2.contents[2] ).toBe con3
            fakeCL2 = CL1.plus con1, con2, con3
            expect( fakeCL2.length() ).toBe 3
            expect( fakeCL2.contents[0] ).toBe con1
            expect( fakeCL2.contents[1] ).toBe con2
            expect( fakeCL2.contents[2] ).toBe con3
            CL3 = new ConstraintList con1
            fakeCL3 = CL1.plus con1
            expect( CL3.length() ).toBe 1
            expect( CL3.contents[0] ).toBe con1
            expect( fakeCL3.length() ).toBe 1
            expect( fakeCL3.contents[0] ).toBe con1
            CL4 = new ConstraintList con3
            fakeCL4 = CL1.plus con3
            expect( CL4.length() ).toBe 1
            expect( CL4.contents[0] ).toBe con3
            expect( fakeCL4.length() ).toBe 1
            expect( fakeCL4.contents[0] ).toBe con3
            otherCL = CL3.plus con2
            expect( otherCL.length() ).toBe 2
            expect( otherCL.contents[0] ).not.toBe con1
            expect( otherCL.contents[0].equals con1 ).toBeTruthy()
            expect( otherCL.contents[1] ).toBe con2

### should subtract constraints correctly

        it 'should subtract constraints correctly', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            CL2 = new ConstraintList con1, con2, con3
            expect( CL1.length() ).toBe 0
            expect( CL2.length() ).toBe 3
            expect( CL2.contents[0] ).toBe con1
            expect( CL2.contents[1] ).toBe con2
            expect( CL2.contents[2] ).toBe con3
            fakeCL1 = CL2.minus con1, con2, con3
            expect( fakeCL1.length() ).toBe 0
            CL3 = new ConstraintList con1
            fakeCL3 = CL2.minus con3, con2
            expect( CL2.length() ).toBe 3
            expect( CL2.contents[0] ).toBe con1
            expect( CL2.contents[1] ).toBe con2
            expect( CL2.contents[2] ).toBe con3
            expect( fakeCL3.length() ).toBe 1
            expect( fakeCL3.contents[0] ).not.toBe con1
            expect( fakeCL3.contents[0].equals con1 ).toBeTruthy()
            CL4 = new ConstraintList con3
            fakeCL4 = CL2.minus con1, con2
            expect( CL4.length() ).toBe 1
            expect( CL4.contents[0] ).toBe con3
            expect( CL2.length() ).toBe 3
            expect( CL2.contents[0] ).toBe con1
            expect( CL2.contents[1] ).toBe con2
            expect( CL2.contents[2] ).toBe con3
            expect( fakeCL4.length() ).toBe 1
            expect( fakeCL4.contents[0] ).not.toBe con3
            expect( fakeCL4.contents[0].equals con3 ).toBeTruthy()
            otherCL = CL2.minus con3
            expect( otherCL.length() ).toBe 2
            expect( otherCL.contents[0] ).not.toBe con1
            expect( otherCL.contents[0].equals con1 ).toBeTruthy()
            expect( otherCL.contents[1] ).not.toBe con2
            expect( otherCL.contents[1].equals con2 ).toBeTruthy()

### should find constraint indices correctly

        it 'should find constraint indices correctly', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            CL2 = new ConstraintList con1, con2, con3
            CL3 = new ConstraintList con1
            CL4 = new ConstraintList con3
            expect( CL1.firstSatisfying -> yes ).toBeNull()
            expect( CL2.firstSatisfying -> yes ).toBe con1
            expect( CL2.firstSatisfying ( c ) -> c.pattern.type is 'v' )
                .toBe con3
            expect( CL3.firstSatisfying ( c ) -> c.pattern.type is 'v' )
                .toBeNull()
            expect( CL4.firstSatisfying ( c ) -> c.pattern.type is 'v' )
                .toBe con3
            expect( CL2.firstSatisfying ( c ) -> c.expression.type is 'v' )
                .toBe con2
            expect( CL4.firstSatisfying ( c ) -> c.expression.type is 'v' )
                .toBe con3
            expect( CL3.firstSatisfying ( c ) -> c.expression.type is 'v' )
                .toBeNull()

### should find constraint pairs correctly

        it 'should find constraint pairs correctly', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            CL1 = new ConstraintList()
            CL2 = new ConstraintList con1, con2, con3
            CL3 = new ConstraintList con1, con2
            CL4 = new ConstraintList con3
            expect( CL1.firstPairSatisfying -> yes ).toBeNull()
            [ a, b ] = CL2.firstPairSatisfying -> yes
            expect( a ).toBe con1
            expect( b ).toBe con2
            expressionTypesEqual = ( constr1, constr2 ) ->
                constr1.expression.type is constr2.expression.type
            expect( CL1.firstPairSatisfying expressionTypesEqual )
                .toBeNull()
            expect( CL2.firstPairSatisfying expressionTypesEqual ).toEqual \
                [ con2, con3 ]
            expect( CL3.firstPairSatisfying expressionTypesEqual )
                .toBeNull()
            expect( CL4.firstPairSatisfying expressionTypesEqual )
                .toBeNull()
            biggerPattern = ( constr1, constr2 ) ->
                constr1.pattern.simpleEncode().length >
                    constr2.pattern.simpleEncode().length
            expect( CL1.firstPairSatisfying biggerPattern ).toBeNull()
            expect( CL2.firstPairSatisfying biggerPattern ).toEqual \
                [ con1, con3 ]
            expect( CL3.firstPairSatisfying biggerPattern ).toEqual \
                [ con2, con1 ]
            expect( CL4.firstPairSatisfying biggerPattern ).toBeNull()

### should know if an instance is a function

        it 'should know if an instance is a function', ->
            con1 = new Constraint quick( 'and(_A,_B)' ), quick( 'and(x,y)' )
            con2 = new Constraint quick( 'plus(_x,_x)' ), quick( 'HELLO' )
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            con4 = new Constraint quick( '_v0' ), quick( 'thing(one,two)' )
            con5 = new Constraint quick( '_yo' ), quick( 'dawg' )
            empty = new ConstraintList()
            fun1 = new ConstraintList con3
            fun2 = new ConstraintList con4
            fun3 = new ConstraintList con3, con5
            fun4 = new ConstraintList con4, con5
            non1 = new ConstraintList con1
            non2 = new ConstraintList con3, con4
            expect( empty.isFunction() ).toBeTruthy()
            expect( fun1.isFunction() ).toBeTruthy()
            expect( fun2.isFunction() ).toBeTruthy()
            expect( fun3.isFunction() ).toBeTruthy()
            expect( fun4.isFunction() ).toBeTruthy()
            expect( non1.isFunction() ).toBeFalsy()
            expect( non2.isFunction() ).toBeFalsy()

### should correctly handle lookups

        it 'should correctly handle lookups', ->
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            con4 = new Constraint quick( '_v0' ), quick( 'thing(one,two)' )
            con5 = new Constraint quick( '_yo' ), quick( 'dawg' )
            empty = new ConstraintList()
            fun1 = new ConstraintList con3
            fun2 = new ConstraintList con4
            fun3 = new ConstraintList con3, con5
            fun4 = new ConstraintList con4, con5
            expect( empty.lookup 'v0' ).toBeNull()
            expect( empty.lookup 'yo' ).toBeNull()
            expect( fun1.lookup( 'v0' ).equals quick 'v1' ).toBeTruthy()
            expect( fun1.lookup 'yo' ).toBeNull()
            expect( fun2.lookup( 'v0' ).equals quick 'thing(one,two)' )
                .toBeTruthy()
            expect( fun2.lookup 'yo' ).toBeNull()
            expect( fun3.lookup( 'v0' ).equals quick 'v1' ).toBeTruthy()
            expect( fun3.lookup( 'yo' ).equals quick 'dawg' ).toBeTruthy()
            expect( fun4.lookup( 'v0' ).equals quick 'thing(one,two)' )
                .toBeTruthy()
            expect( fun4.lookup( 'yo' ).equals quick 'dawg' ).toBeTruthy()

### should correctly apply itself

        it 'should correctly apply itself', ->
            con3 = new Constraint quick( '_v0' ), quick( 'v1' )
            con4 = new Constraint quick( '_v0' ), quick( 'thing(one,two)' )
            con5 = new Constraint quick( '_yo' ), quick( 'dawg' )
            empty = new ConstraintList()
            fun1 = new ConstraintList con3
            fun2 = new ConstraintList con4
            fun3 = new ConstraintList con3, con5
            fun4 = new ConstraintList con4, con5
            expect( fun1.apply( quick 'well(_v0,_v0,and_even(_yo))' )
                .equals quick 'well(v1,v1,and_even(_yo))' )
            expect( fun2.apply( quick 'well(_v0,_v0,and_even(_yo))' )
                .equals quick \
                    'well(thing(one,two),thing(one,two),and_even(_yo))' )
            expect( fun3.apply( quick 'well(_v0,_v0,and_even(_yo))' )
                .equals quick 'well(v1,v1,and_even(dawg))' )
            expect( fun4.apply( quick 'well(_v0,_v0,and_even(_yo))' )
                .equals quick \
                    'well(thing(one,two),thing(one,two),and_even(dawg))' )

## Finding differences between expressions

This section tests the `findDifferencesBetween` function.

    describe 'Finding differences between expressions', ->

### should compute correct results

        it 'should compute correct results', ->
            e1 = OM.simple 'f'
            e2 = OM.simple 'f'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 0
            e2 = OM.simple 'g'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual []
            e1 = OM.simple 'f(x)'
            e2 = OM.simple 'f(y)'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual [ 'c1' ]
            e1 = OM.simple 'f(x,x)'
            e2 = OM.simple 'f(x,y)'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual [ 'c2' ]
            e1 = OM.simple 'f(x,x)'
            e2 = OM.simple 'f(y,y)'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 2
            expect( result[0] ).toEqual [ 'c1' ]
            expect( result[1] ).toEqual [ 'c2' ]
            e1 = OM.simple 'a.b[c,d(e)]'
            e2 = OM.simple 'a.b[c,d(E)]'
            result = findDifferencesBetween e1, e2
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual [ 'b', 'c1' ]

## Finding parent address sets

This section tests the `parentAddresses` function.

    describe 'Finding parent address sets', ->

### should compute correct results

        it 'should compute correct results', ->
            addrset = []
            result = parentAddresses addrset
            expect( result ).toBeNull()
            addrset = [ [] ]
            result = parentAddresses addrset
            expect( result ).toBeNull()
            addrset = [ [ 'c1' ] ]
            result = parentAddresses addrset
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual []
            addrset = [ [ 'c1' ], [ 'b' ] ]
            result = parentAddresses addrset
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual []
            addrset = [ [ 'b', 'c1' ] ]
            result = parentAddresses addrset
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual [ 'b' ]
            addrset = [ [ 'b', 'c1' ], [ 'b' ] ]
            result = parentAddresses addrset
            expect( result.length ).toBe 2
            expect( result[0] ).toEqual [ 'b' ]
            expect( result[1] ).toEqual []
            addrset = [ [ 'b', 'c1' ], [ 'b', 'c2' ], [ 'b', 'c3' ] ]
            result = parentAddresses addrset
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual [ 'b' ]

## Subexpressions

This section tests the `partitionedAddresses` function.

    describe 'Subexpressions', ->

### should partition addresses correctly

        it 'should partition addresses correctly', ->
            expr = OM.simple 'foo'
            result = partitionedAddresses expr
            expect( result.length ).toBe 1
            expect( result[0].subexpression.equals expr ).toBeTruthy()
            expect( result[0].addresses ).toEqual [ [] ]
            expr = OM.simple 'foo(x)'
            result = partitionedAddresses expr
            expect( result.length ).toBe 3
            expect( result[0].subexpression.equals expr ).toBeTruthy()
            expect( result[0].addresses ).toEqual [ [] ]
            expect( result[1].subexpression.equals OM.simple 'foo' )
                .toBeTruthy()
            expect( result[1].addresses ).toEqual [ [ 'c0' ] ]
            expect( result[2].subexpression.equals OM.simple 'x' )
                .toBeTruthy()
            expect( result[2].addresses ).toEqual [ [ 'c1' ] ]
            expr = OM.simple 'foo(a(b),a(b))'
            result = partitionedAddresses expr
            expect( result.length ).toBe 5
            expect( result[0].subexpression.equals expr ).toBeTruthy()
            expect( result[0].addresses ).toEqual [ [] ]
            expect( result[1].subexpression.equals OM.simple 'foo' )
                .toBeTruthy()
            expect( result[1].addresses ).toEqual [ [ 'c0' ] ]
            expect( result[2].subexpression.equals OM.simple 'a(b)' )
                .toBeTruthy()
            expect( result[2].addresses ).toEqual [ [ 'c1' ], [ 'c2' ] ]
            expect( result[3].subexpression.equals OM.simple 'a' )
                .toBeTruthy()
            expect( result[3].addresses ).toEqual [ [ 'c1', 'c0' ],
                                                    [ 'c2', 'c0' ] ]
            expect( result[4].subexpression.equals OM.simple 'b' )
                .toBeTruthy()
            expect( result[4].addresses ).toEqual [ [ 'c1', 'c1' ],
                                                    [ 'c2', 'c1' ] ]
            expr = OM.simple 'foo(a(b),c)'
            result = partitionedAddresses expr
            expect( result.length ).toBe 6
            expect( result[0].subexpression.equals expr ).toBeTruthy()
            expect( result[0].addresses ).toEqual [ [] ]
            expect( result[1].subexpression.equals OM.simple 'foo' )
                .toBeTruthy()
            expect( result[1].addresses ).toEqual [ [ 'c0' ] ]
            expect( result[2].subexpression.equals OM.simple 'a(b)' )
                .toBeTruthy()
            expect( result[2].addresses ).toEqual [ [ 'c1' ] ]
            expect( result[3].subexpression.equals OM.simple 'a' )
                .toBeTruthy()
            expect( result[3].addresses ).toEqual [ [ 'c1', 'c0' ] ]
            expect( result[4].subexpression.equals OM.simple 'b' )
                .toBeTruthy()
            expect( result[4].addresses ).toEqual [ [ 'c1', 'c1' ] ]
            expect( result[5].subexpression.equals OM.simple 'c' )
                .toBeTruthy()
            expect( result[5].addresses ).toEqual [ [ 'c2' ] ]

## Difference iterators

This section tests the `differenceIterator` function and its related
supporting functions.

    describe 'Difference iterators', ->

### should compute expression depth correctly

        it 'should compute expression depth correctly', ->
            expect( expressionDepth quick 'f' ).toBe 1
            expect( expressionDepth quick '2' ).toBe 1
            expect( expressionDepth quick '"yo"' ).toBe 1
            expect( expressionDepth quick 'sym.bol' ).toBe 1
            expect( expressionDepth quick 'f(x)' ).toBe 2
            expect( expressionDepth quick 'f(x,y,z)' ).toBe 2
            expect( expressionDepth quick 'f(g(2))' ).toBe 3
            expect( expressionDepth quick 'f("hi",g("bye"))' ).toBe 3

### should compute same depth ancestor sets correctly

        it 'should compute same depth ancestor sets correctly', ->
            expr = quick 'f(g(1,h(2)),3,x(y,z(w),a))'

Applying it to two leaves should yield just those leaves.

            addresses = [ [ 'c1', 'c2', 'c1' ], # 2
                          [ 'c3', 'c2', 'c1' ] ] # w
            result = sameDepthAncestors expr, addresses
            expect( result.length ).toBe 2
            expect( result[0] ).toEqual addresses[0]
            expect( result[1] ).toEqual addresses[1]

Applying it to a leaf and a depth-2 subtree should yield two depth-2
subtrees (because of the configuration of the tree surrounding the two
addresses in question).

            addresses = [ [ 'c1', 'c2', 'c1' ], # 2
                          [ 'c3', 'c2' ] ] # z
            result = sameDepthAncestors expr, addresses
            expect( result.length ).toBe 2
            expect( result[0] ).toEqual addresses[0][...-1]
            expect( result[1] ).toEqual addresses[1]

Applying it to a leaf and a depth-2 subtree should yield two depth-3
subtrees (because of the configuration of the tree surrounding the two
addresses in question).

            addresses = [ [ 'c1', 'c1' ], # 1
                          [ 'c3', 'c2' ] ] # z
            result = sameDepthAncestors expr, addresses
            expect( result.length ).toBe 2
            expect( result[0] ).toEqual [ 'c1' ]
            expect( result[1] ).toEqual [ 'c3' ]

Applying it to three leaves should yield those same three leaves.

            addresses = [ [ 'c1', 'c2', 'c1' ], # 2
                          [ 'c3', 'c2', 'c1' ], # w
                          [ 'c2' ] ] # 3
            result = sameDepthAncestors expr, addresses
            expect( result.length ).toBe 3
            expect( result[0] ).toEqual addresses[0]
            expect( result[1] ).toEqual addresses[1]
            expect( result[2] ).toEqual addresses[2]

Applying it to two leaves and a depth-2 subtree, in this case, requires
moving all the way back to the root before the criteria are satisfied.

            addresses = [ [ 'c1', 'c1' ], # 1
                          [ 'c3', 'c2' ], # z
                          [ 'c2' ] ] # 3
            result = sameDepthAncestors expr, addresses
            expect( result.length ).toBe 1
            expect( result[0] ).toEqual []

### should yield the correct results when called iteratively

Finally, we have the test of the iterator itself.

        it 'should yield the correct results when called iteratively', ->

First, the easy cases when the complexities of the difference iterator are
not really shown, because parent address computations can be done simply,
without the need for the full power of `sameDepthAncestors`.

            e1 = OM.simple 'f'
            e2 = OM.simple 'g'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x)'
            e2 = OM.simple 'f(y)'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [ 'c1' ] ]
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x,x)'
            e2 = OM.simple 'f(y,y)'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [ 'c1' ], [ 'c2' ] ]
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x,y)'
            e2 = OM.simple 'f(y,x)'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(g(t,s),g(t,s))'
            e2 = OM.simple 'f(g(k,m),g(k,m))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [ 'c1' ], [ 'c2' ] ]
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()

Now some tests where differences occur at different depths, thus making a
better test of `sameDepthAncestors`.

            e1 = OM.simple 'f(x,y(x))'
            e2 = OM.simple 'f(1,y(1))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [ 'c1' ], [ 'c2', 'c1' ] ]
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x,y(y))'
            e2 = OM.simple 'f(1,y(1))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x,y(x))'
            e2 = OM.simple 'f(1,y(2))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(x,y(y))'
            e2 = OM.simple 'f(1,y(2))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            e1 = OM.simple 'f(y,g(x))'
            e2 = OM.simple 'f(h,h(x))'
            it = differenceIterator e1, e2
            expect( it ).toBeTruthy()
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()

## Subexpression iterators

This section tests the `subexpressionIterator` function.

    describe 'Subexpression iterators', ->

### should yield the correct results when called iteratively

        it 'should yield the correct results when called iteratively', ->
            expr = OM.simple 'f'
            it = subexpressionIterator expr
            expect( it() ).toEqual [ [] ]
            expect( it() ).toBeNull()
            expr = OM.simple 'f(x)'
            it = subexpressionIterator expr
            expect( it() ).toEqual [ [] ]
            expect( it() ).toEqual [ [ 'c0' ] ]
            expect( it() ).toEqual [ [ 'c1' ] ]
            expect( it() ).toBeNull()
            expr = OM.simple 'f(x,x)'
            it = subexpressionIterator expr
            expect( it() ).toEqual [ [] ]
            expect( it() ).toEqual [ [ 'c0' ] ]
            expect( it() ).toEqual [ [ 'c1' ] ]
            expect( it() ).toEqual [ [ 'c2' ] ]
            expect( it() ).toEqual [ [ 'c1' ], [ 'c2' ] ]
            expect( it() ).toBeNull()
            expr = OM.simple 'f(x,g(x),y(g))'
            it = subexpressionIterator expr
            expect( it() ).toEqual [ [] ]
            expect( it() ).toEqual [ [ 'c0' ] ]
            expect( it() ).toEqual [ [ 'c1' ] ]
            expect( it() ).toEqual [ [ 'c2', 'c1' ] ]
            expect( it() ).toEqual [ [ 'c1' ], [ 'c2', 'c1' ] ]
            expect( it() ).toEqual [ [ 'c2' ] ]
            expect( it() ).toEqual [ [ 'c2', 'c0' ] ]
            expect( it() ).toEqual [ [ 'c3', 'c1' ] ]
            expect( it() ).toEqual [ [ 'c2', 'c0' ], [ 'c3', 'c1' ] ]
            expect( it() ).toEqual [ [ 'c3' ] ]
            expect( it() ).toEqual [ [ 'c3', 'c0' ] ]
            expect( it() ).toBeNull()

## Prefix and suffix iterators

This section tests the `prefixIterator` and `suffixIterator` functions.  In
order to do so, we first create a simple array iterator, which returns the
elements of the array one at a time, then null as a fixed point thereafter.

    arrayIterator = ( array ) ->
        -> if array.length > 0 then array.shift() else null

Now, the test.

    describe 'Prefix and suffix iterators', ->

### should verify first that array iterators work

        it 'should verify first that array iterators work', ->
            it = arrayIterator [ 1, 2 ]
            expect( it() ).toBe 1
            expect( it() ).toBe 2
            expect( it() ).toBeNull()

### should prefix iterator correctly

        it 'should prefix iterator correctly', ->
            it = arrayIterator [ 1, 2 ]
            it2 = prefixIterator 700, it
            expect( it2() ).toBe 700
            expect( it2() ).toBe 1
            expect( it2() ).toBe 2
            expect( it2() ).toBeNull()
            it = arrayIterator 'a sequence of words'.split ' '
            specificObject = { }
            it2 = prefixIterator specificObject, it
            expect( it2() ).toBe specificObject
            expect( it2() ).toBe 'a'
            expect( it2() ).toBe 'sequence'
            expect( it2() ).toBe 'of'
            expect( it2() ).toBe 'words'
            expect( it2() ).toBeNull()
            it = arrayIterator []
            it2 = prefixIterator ':)', it
            expect( it2() ).toBe ':)'
            expect( it2() ).toBeNull()

### should suffix iterator correctly

        it 'should suffix iterator correctly', ->
            it = arrayIterator [ 1, 2 ]
            it2 = suffixIterator it, 700
            expect( it2() ).toBe 1
            expect( it2() ).toBe 2
            expect( it2() ).toBe 700
            expect( it2() ).toBeNull()
            it = arrayIterator 'a sequence of words'.split ' '
            specificObject = { }
            it2 = suffixIterator it, specificObject
            expect( it2() ).toBe 'a'
            expect( it2() ).toBe 'sequence'
            expect( it2() ).toBe 'of'
            expect( it2() ).toBe 'words'
            expect( it2() ).toBe specificObject
            expect( it2() ).toBeNull()
            it = arrayIterator []
            it2 = suffixIterator it, ':)'
            expect( it2() ).toBe ':)'
            expect( it2() ).toBeNull()

## Compose iterators

This section tests the `composeIterator` function.  It re-uses the array
iterator defined in the previous section.

    describe 'Compose iterators', ->

### should yield the correct results when called iteratively

        it 'should yield the correct results when called iteratively', ->
            it = arrayIterator [ 10, 20, 30 ]
            it2 = composeIterator it, ( value ) -> value / 2
            expect( it2() ).toBe 5
            expect( it2() ).toBe 10
            expect( it2() ).toBe 15
            expect( it2() ).toBeNull()
            it = arrayIterator 'things we love'.split ' '
            it2 = composeIterator it, ( value ) -> value.length
            expect( it2() ).toBe 6
            expect( it2() ).toBe 2
            expect( it2() ).toBe 4
            expect( it2() ).toBeNull()
            it = arrayIterator []
            it2 = composeIterator it, ( value ) -> value + 1000
            expect( it2() ).toBeNull()

## Filter iterators

This section tests the `filterIterator` function.  It re-uses the array
iterator defined in an earlier section.

    describe 'Filter iterators', ->

### should yield the correct results when called iteratively

        it 'should yield the correct results when called iteratively', ->
            it = arrayIterator [ 10, 20, 30 ]
            it2 = filterIterator it, ( value ) -> value > 15
            expect( it2() ).toBe 20
            expect( it2() ).toBe 30
            expect( it2() ).toBeNull()
            it = arrayIterator 'things we love'.split ' '
            it2 = filterIterator it, ( value ) -> value.length < 4
            expect( it2() ).toBe 'we'
            expect( it2() ).toBeNull()
            it = arrayIterator []
            it2 = filterIterator it, ( value ) -> true
            expect( it2() ).toBeNull()
            it = arrayIterator []
            it2 = filterIterator it, ( value ) -> false
            expect( it2() ).toBeNull()
            it = arrayIterator [ 1, 2, 3, 4, 5 ]
            it2 = filterIterator it, ( value ) -> false
            expect( it2() ).toBeNull()

## Concatenate iterators

This section tests the `concatenateIterators` function.  It re-uses the
array iterator defined in an earlier section.

    describe 'Concatenate iterators', ->

### should yield the correct results when called iteratively

        it 'should yield the correct results when called iteratively', ->
            it1 = arrayIterator [ 10, 20, 30 ]
            it2 = arrayIterator [ 'sam', 'bob', 'dee' ]
            it = concatenateIterators it1, it2
            expect( it() ).toBe 10
            expect( it() ).toBe 20
            expect( it() ).toBe 30
            expect( it() ).toBe 'sam'
            expect( it() ).toBe 'bob'
            expect( it() ).toBe 'dee'
            expect( it() ).toBeNull()
            it3 = arrayIterator 'things we love'.split ' '
            it4 = arrayIterator 'to do today'.split ' '
            it = concatenateIterators it4, it3
            expect( it() ).toBe 'to'
            expect( it() ).toBe 'do'
            expect( it() ).toBe 'today'
            expect( it() ).toBe 'things'
            expect( it() ).toBe 'we'
            expect( it() ).toBe 'love'
            expect( it() ).toBeNull()

## Matching

The main event of this test suite, the matching algorithm itself.  This
section will include a great many tests of an enormous variety of matching
problems.

    describe 'Matching', ->

We will want some debugging routines for use in the testing below.

        CToString = ( c ) ->
            "(#{c.pattern.simpleEncode()},#{c.expression.simpleEncode()})"
        CLToString = ( cl ) ->
            if cl is null then return null
            "{ #{( CToString(c) for c in cl.contents ).join ', '} }"
        CLSetToString = ( cls ) ->
            if cls is null then return null
            '[\n'+( "\t#{CLToString(cl)}" for cl in cls ).join( '\n' )+'\n]'

### should have a working multiReplace function

        it 'should have a working multiReplace function', ->
            start = quick 'top(first(x,y),second(x,y),y,g(x),h)'
            other = quick 'OTHER'
            subset = []
            result = multiReplace start, subset, other
            expected = start.copy()
            expect( result.equals expected ).toBeTruthy()
            subset = [ [ 'c0' ] ]
            result = multiReplace start, subset, other
            expected = quick 'OTHER(first(x,y),second(x,y),y,g(x),h)'
            expect( result.equals expected ).toBeTruthy()
            subset = [ [ 'c0' ], [ 'c7' ] ]
            result = multiReplace start, subset, other
            expected = quick 'OTHER(first(x,y),second(x,y),y,g(x),h)'
            expect( result.equals expected ).toBeTruthy()
            subset = [ [ 'c1' ], [ 'c3' ], [ 'c5' ] ]
            result = multiReplace start, subset, other
            expected = quick 'top(OTHER,second(x,y),OTHER,g(x),OTHER)'
            expect( result.equals expected ).toBeTruthy()
            subset = [ [ 'c1', 'c1' ], [ 'c4', 'c0' ] ]
            result = multiReplace start, subset, other
            expected = quick 'top(first(OTHER,y),second(x,y),y,OTHER(x),h)'
            expect( result.equals expected ).toBeTruthy()

### should have a working bindingConstraints1 function

We test the function that computes the first type of binding constraints
from a given pattern.

        it 'should have a working bindingConstraints1 function', ->

Random example to start.

            pattern = quick 'for.all[_v,_w,foo(_v,_w,_z)]'
            result = bindingConstraints1 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 2
            expect( result.contents[0].pattern.equals quick '_v' )
                .toBeTruthy()
            expect( result.contents[0].expression.equals quick '_z' )
                .toBeTruthy()
            expect( result.contents[1].pattern.equals quick '_w' )
                .toBeTruthy()
            expect( result.contents[1].expression.equals quick '_z' )
                .toBeTruthy()

Now an example where there are no free metavariables inside a binder.

            pattern = quick 'and(for.all[_x,P_of__x],exi.sts[_y,Q_of__y])'
            result = bindingConstraints1 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 0

Now that same example with some variables converted to metavariables, so
that this final test is actually a lot like the existential elimination
rule in first order logic.  (Not in form, just in metavariable free/bound
concerns.)

            pattern = quick 'and(for.all[_x,_P_of__x],exi.sts[_y,_Q_of__y])'
            result = bindingConstraints1 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 2
            expect( result.contents[0].pattern.equals quick '_x' )
                .toBeTruthy()
            expect( result.contents[0].expression.equals quick '_P' )
                .toBeTruthy()
            expect( result.contents[1].pattern.equals quick '_y' )
                .toBeTruthy()
            expect( result.contents[1].expression.equals quick '_Q' )
                .toBeTruthy()

### should have a working satisfiesBindingConstraints1 function

        it 'should have a working satisfiesBindingConstraints1 function', ->

Construct the binding constraints from the end of the last test.

            bc = new ConstraintList \
                new Constraint( quick( '_x' ), quick( '_P' ) ),
                new Constraint( quick( '_y' ), quick( '_Q' ) )

Construct a solution that respects it, by not having the instantiation of P
contain any free occurrences of the instantiation of x, nor the
instantiation of Q any free occurrences of the instantiation of y.  But they
will each contain bound occurrences of them!

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ), quick( 'for.all[a,b(a)]' ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ), quick( 'exi.sts[c,d(c)]' ) )
            expect( satisfiesBindingConstraints1 solution, bc ).toBeTruthy()

Construct a solution that does not respect bc, because the instantiation of
P contains a free occurrence of the instantiation of x, though the (y,Q)
pair does not contain a violation.

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ), quick( 'for.all[x,b(a)]' ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ), quick( 'foo' ) )
            expect( satisfiesBindingConstraints1 solution, bc ).toBeFalsy()

Construct a parallel violation, this time with the (y,Q) pair, while the
(x,P) pair is okay.

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ), quick( 'bar' ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ), quick( 'plus(2,c)' ) )
            expect( satisfiesBindingConstraints1 solution, bc ).toBeFalsy()

### should have a working bindingConstraints2 function

We test the function that computes the second type of binding constraints
from a given pattern.

        it 'should have a working bindingConstraints2 function', ->

Random example to start.

            pattern = quick 'foo(P_of_x,_Q_of__y)'
            result = bindingConstraints2 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 1
            expect( result.contents[0].pattern.equals quick '_Q' )
                .toBeTruthy()
            expect( result.contents[0].expression.equals quick '_y' )
                .toBeTruthy()

Now an example where there are no expression function applications.

            pattern = quick 'and(for.all[_x,_P],exi.sts[_y,_Q])'
            result = bindingConstraints2 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 0

Now that same example with two expression function applications

            pattern = quick 'and(for.all[_x,_P_of__x],exi.sts[_y,_Q_of__y])'
            result = bindingConstraints2 pattern
            expect( result instanceof ConstraintList ).toBeTruthy()
            expect( result.length() ).toBe 2
            expect( result.contents[0].pattern.equals quick '_P' )
                .toBeTruthy()
            expect( result.contents[0].expression.equals quick '_x' )
                .toBeTruthy()
            expect( result.contents[1].pattern.equals quick '_Q' )
                .toBeTruthy()
            expect( result.contents[1].expression.equals quick '_y' )
                .toBeTruthy()

### should have a working satisfiesBindingConstraints2 function

        it 'should have a working satisfiesBindingConstraints2 function', ->

Construct the binding constraints from the end of the last test.

            bc = new ConstraintList \
                new Constraint( quick( '_P' ), quick( '_x' ) ),
                new Constraint( quick( '_Q' ), quick( '_y' ) )

Construct a solution that respects it, by having the instantiations of x and
y be simple variables that don't show up in P or Q.

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ),
                    makeExpressionFunction quick( 'v' ), quick( '2' ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ),
                    makeExpressionFunction quick( 'v' ), quick( 'f(v)' ) )
            expect( satisfiesBindingConstraints2 solution, bc ).toBeTruthy()

Construct a solution that does not respect bc, because the body of the
instantiation of P contains a free occurrence of the variable of P that is
surrounded by a quantifier whose variable is the instantiation of x.  Let
the (Q,y) pair not contain a violation.

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ),
                    makeExpressionFunction( quick( 'v' ),
                        quick( 'for.all[a,b(v)]' ) ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ),
                    makeExpressionFunction quick( 'v' ), quick( 'f(v)' ) )
            expect( satisfiesBindingConstraints2 solution, bc ).toBeFalsy()

Construct a parallel violation, this time with the (Q,y) pair, while the
(P,x) pair is okay.

            solution = new ConstraintList \
                new Constraint( quick( '_x' ), quick( 'a' ) ),
                new Constraint( quick( '_P' ),
                    makeExpressionFunction( quick( 'v' ),
                        quick( 'and(a,b(v))' ) ) ),
                new Constraint( quick( '_y' ), quick( 'c' ) ),
                new Constraint( quick( '_Q' ),
                    makeExpressionFunction quick( 'v' ),
                        quick( 'for.all[c,hay(v,v)]' ) )
            expect( satisfiesBindingConstraints2 solution, bc ).toBeFalsy()

### should work for atomic patterns

In the next few tests, we will want to be able to conveniently grab all the
matches that the iteration of the `nextMatch` function will eventually give.
We create the following function to make this easier.

It also embodies the idea that it will not return matches that do not pass
the binding constraints embodied in

        someMatches = ( LHS, RHS, number = 10, debug = no ) ->
            results = [ ]
            bc1 = bindingConstraints1 LHS
            bc2 = bindingConstraints2 LHS
            args = [ new ConstraintList new Constraint LHS, RHS ]
            while results.length < number
                [ result, args ] = nextMatch args...
                if debug then console.log 'NEXT RESULT:', CLToString result
                if result? and satisfiesBindingConstraints1( result, bc1 ) \
                        and satisfiesBindingConstraints2( result, bc2 )
                    already = no
                    for earlier in results
                        if earlier.equals result
                            already = yes
                            break
                    if not already then results.push result
                if not args? then break
            results

Back to testing...

        it 'should work for atomic patterns', ->

Matching `a` to `a` should yield one solution, the empty map.

            result = someMatches quick( 'a' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 0

Matching `a` to `b` should yield no solutions.

            result = someMatches quick( 'a' ), quick( 'b' )
            expect( result.length ).toBe 0

Matching `a` to `2` should yield no solutions.

            result = someMatches quick( 'a' ), quick( '2' )
            expect( result.length ).toBe 0

Matching `a` to `f(x)` should yield no solutions.

            result = someMatches quick( 'a' ), quick( 'f(x)' )
            expect( result.length ).toBe 0

Matching `9` to `9` should yield one solution, the empty map.

            result = someMatches quick( '9' ), quick( '9' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 0

Matching `9` to `b` should yield no solutions.

            result = someMatches quick( '9' ), quick( 'b' )
            expect( result.length ).toBe 0

Matching `9` to `2` should yield no solutions.

            result = someMatches quick( '9' ), quick( '2' )
            expect( result.length ).toBe 0

Matching `9` to `f(x)` should yield no solutions.

            result = someMatches quick( '9' ), quick( 'f(x)' )
            expect( result.length ).toBe 0

Matching `"slow"` to `9` should yield one solution, the empty map.

            result = someMatches quick( '"slow"' ), quick( '9' )
            expect( result.length ).toBe 0

Matching `"slow"` to `b` should yield no solutions.

            result = someMatches quick( '"slow"' ), quick( 'b' )
            expect( result.length ).toBe 0

Matching `"slow"` to `2` should yield no solutions.

            result = someMatches quick( '"slow"' ), quick( '2' )
            expect( result.length ).toBe 0

Matching `"slow"` to `f(x)` should yield no solutions.

            result = someMatches quick( '"slow"' ), quick( 'f(x)' )
            expect( result.length ).toBe 0

Matching `_A` (now a metavariable, following the notational convention in
the `quick` function defined earlier in this spec) with anything should
yield one solution, which maps A to that thing.

            result = someMatches quick( '_A' ), quick( 'a' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick 'a' ).toBeTruthy()
            result = someMatches quick( '_A' ), quick( '23645' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick '23645' )
                .toBeTruthy()
            result = someMatches quick( '_A' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick 'f(x)' )
                .toBeTruthy()

### should work for compound patterns

The following tests are for the case where the pattern is compound,
including application, binding, and error types.  No expression function
patterns are tested yet; they appear in later tests.  (Actually, error types
are of little importance to most of our uses, and function so much like
application types that we have little to no tests of error types below.)

        it 'should work for compound patterns', ->

First, applications:

Matching `_A(x)` to `f(x)` should yield one solution, which maps A to f.

            result = someMatches quick( '_A(x)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `_A(_B)` to `f(x)` should yield one solution, which maps A to f and
B to x.

            result = someMatches quick( '_A(_B)' ), quick( 'f(x)' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'A' ).equals quick 'f' ).toBeTruthy()
            expect( result[0].lookup( 'B' ).equals quick 'x' ).toBeTruthy()

Matching `_A(_B)` to `f(x,y)` should yield no solutions.

            result = someMatches quick( '_A(_B)' ), quick( 'f(x,y)' )
            expect( result.length ).toBe 0

Matching `_A(_B)` to `f()` should yield no solutions.

            result = someMatches quick( '_A(_B)' ), quick( 'f()' )
            expect( result.length ).toBe 0

Matching `_A(_B)` to `some_var` should yield no solutions.

            result = someMatches quick( '_A(_B)' ), quick( 'some_var' )
            expect( result.length ).toBe 0

Next, bindings:

Matching `_A.A[x,y]` to `f.f[x,y]` should yield one solution, which maps A.A
to f.f.

            result = someMatches quick( '_A.A[x,y]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( quick 'A.A' ).equals quick 'f.f' )
                .toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y]` should yield one solution, which maps
A.A to f.f, B to x, and C to y.

            result = someMatches quick( '_A.A[_B,_C]' ), quick( 'f.f[x,y]' )
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( quick 'A.A' ).equals quick 'f.f' )
                .toBeTruthy()
            expect( result[0].lookup( quick 'B' ).equals quick 'x' )
                .toBeTruthy()
            expect( result[0].lookup( quick 'C' ).equals quick 'y' )
                .toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y,z]` should yield no solutions.

            result = someMatches quick( '_A.A[_B,_C]' ),
                quick( 'f.f[x,y,z]' )
            expect( result.length ).toBe 0

Matching `_A.A[_B,_C,_D]` to `f.f[x,y]` should yield no solutions.

            result = someMatches quick( '_A.A[_B,_C,_D]' ),
                quick( 'f.f[x,y]' )
            expect( result.length ).toBe 0

Matching `_A.A[_B,_C]` to `some_var` should yield no solutions.

            result = someMatches quick( '_A.A[_B,_C]' ), quick( 'some_var' )
            expect( result.length ).toBe 0

### should ignore attributes

We repeat a selection of the above tests, now adding attributes to some of
the nodes in either the pattern or the expression, and verifying that the
results are exactly the same in all cases.

        it 'should ignore attributes', ->

Matching `a` to `a` should yield one solution, the empty map.

            left = quick 'a'
            right = quick 'a'
            left.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 0

Matching `_A` to `a` should yield one solution, mapping A to a.

            left = quick '_A'
            right = quick 'a'
            left.setAttribute OM.symbol( 'a', 'b' ), OM.integer 200
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick 'a' ).toBeTruthy()

Matching `_A(x)` to `f(x)` should yield one solution, mapping A to f.

            left = quick '_A(x)'
            right = quick 'f(x)'
            left.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer 200
            right.children[1].setAttribute OM.symbol( 'a', 'b' ),
                OM.integer -1
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'A' ).equals quick 'f' ).toBeTruthy()

Matching `_A.A[_B,_C]` to `f.f[x,y]` should yield one solution, mapping A.A
to f.f, B to x, and C to y.

            left = quick '_A.A[_B,_C]'
            right = quick 'f.f[x,y]'
            left.setAttribute OM.symbol( 'thing1', 'thing2' ),
                OM.simple 'f(x)'
            right.setAttribute OM.symbol( 'santy', 'claus' ),
                OM.simple 'g(y)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( quick 'A.A' ).equals quick 'f.f' )
                .toBeTruthy()
            expect( result[0].lookup( 'B' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'C' ).equals quick 'y' ).toBeTruthy()

### should work for a simple rule form

We create a few tests based on the equality introduction rule, the simplest
of all the rule forms in first-order logic.  More complex rule forms come as
later tests, below.

        it 'should work for a simple rule form', ->

Matching `Rule(eq(_a,_a))` to `Rule(eq(7,7))` should give one solution,
which maps a to 7.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(7,7))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'a' ).equals quick '7' ).toBeTruthy()

Matching `Rule(eq(_a,_a))` to `Rule(eq(t,t))` should give one solution,
which maps a to t.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(t,t))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'a' ).equals quick 't' ).toBeTruthy()

Matching `Rule(eq(_a,_a))` to `Rule(eq(a,a))` should give one solution,
which maps a to a.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(a,a))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'a' ).equals quick 'a' ).toBeTruthy()

Matching `Rule(eq(_a,_a))` to `Rule(eq(1,2))` should give no solutions.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(1,2))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(eq(_a,_a))` to `Rule(eq(a,2))` should give no solutions.

            left = quick 'Rule(eq(_a,_a))'
            right = quick 'Rule(eq(a,2))'
            result = someMatches left, right
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

Matching `_F((_v))` to `2` should give two solutions.
 * One will map F to lambda[v0,v0] and v to 2.
 * The other will map F to lambda[v0,2] and will not constrain v.

The `v0` instances are new variables created to not conflict with anything
in the pattern or the expression.

            left = quick '_F_of__v'
            right = quick '2'
            result = someMatches left, right
            expect( result.length ).toBe 2
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'F' ).equals ef 'v0', 'v0' )
                .toBeTruthy()
            expect( result[0].lookup( 'v' ).equals quick '2' ).toBeTruthy()
            expect( result[1].length() ).toBe 1
            expect( alphaEquivalent result[1].lookup( 'F' ),
                ef 'v0', '2' ).toBeTruthy()

Matching `f(_F((0)),_F((x)))` to `f(0,x)` should give one solution, mapping
F to lambda[v0,v0].

            left = quick 'f(_F_of_0,_F_of_x)'
            right = quick 'f(0,x)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'F' ).equals ef 'v0', 'v0' )
                .toBeTruthy()

Matching `f(_F((0)),_F((_y)))` to `f(0,x)` should give one solution, mapping
F to lambda[v0,v0].

            left = quick 'f(_F_of_0,_F_of__y)'
            right = quick 'f(0,x)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'F' ).equals ef 'v0', 'v0' )
                .toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'x' ).toBeTruthy()

Matching `f(_F((0)),_F((y)))` to `f(g(0),g(y))` should give one solution,
mapping F to lambda[v0,g(v0)].

            left = quick 'f(_F_of_0,_F_of_y)'
            right = quick 'f(g(0),g(y))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( result[0].lookup( 'F' ).equals ef 'v0', 'g(v0)' )
                .toBeTruthy()

Matching `f(_F((_x)),_F((_y)))` to `f(g(0),g(1))` should give two solutions.
 * One will map F to lambda[v0,g(v0)], x to 0, y to 1.
 * The other will map F to lambda[v0,v0], x to g(0), y to g(1).

The matching operation generates new variables, so it actually uses v1
instead of v0 for the second solution.  Rather than stipulate that this is
required by the test, we just use the `alphaEquivalent` function to leave
the bound variable unconstrained.

            left = quick 'f(_F_of__x,_F_of__y)'
            right = quick 'f(g(0),g(1))'
            result = someMatches left, right
            expect( result.length ).toBe 2
            expect( result[0].length() ).toBe 3
            expect( alphaEquivalent result[0].lookup( 'F' ),
                ef 'v0', 'g(v0)' ).toBeTruthy()
            expect( result[0].lookup( 'x' ).equals quick '0' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick '1' ).toBeTruthy()
            expect( result[1].length() ).toBe 3
            expect( alphaEquivalent result[1].lookup( 'F' ), ef 'v0', 'v0' )
                .toBeTruthy()
            expect( result[1].lookup( 'x' ).equals quick 'g(0)' )
                .toBeTruthy()
            expect( result[1].lookup( 'y' ).equals quick 'g(1)' )
                .toBeTruthy()

Matching `f(_F((0)),_F((1)))` to `f(0,0)` should give one solution, mapping
F to lambda[v0,0].

            left = quick 'f(_F_of_0,_F_of_1)'
            right = quick 'f(0,0)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 1
            expect( alphaEquivalent result[0].lookup( 'F' ), ef 'v0', '0' )
                .toBeTruthy()

Matching `f(_F((0)),_F((1)))` to `f(0,2)` should give no solutions.

            left = quick 'f(_F_of_0,_F_of_1)'
            right = quick 'f(0,2)'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should ambiguous expression function situations

The following tests ensure that the algorithm works correctly in situations
where the constraints are not as tight as they would be in normal usage in a
logical system, but instead produce strange or very ambiguous situations.

        it 'should ambiguous expression function situations', ->

Matching `Rule(P((x)),P((y)))` to `Rule(b(2),b(3))` gives two solutions:
 * x=2, y=3, and P=lambda[v,b(v)]
 * x=b(2), y=b(3), and P=lambda[v,v]

            left = quick 'Rule(_P_of__x,_P_of__y)'
            right = quick 'Rule(b(2),b(3))'
            result = someMatches left, right
            expect( result.length ).toBe 2
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick '2' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick '3' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'b(v0)' ).toBeTruthy()
            expect( result[1].length() ).toBe 3
            expect( result[1].lookup( 'x' ).equals quick 'b(2)' )
                .toBeTruthy()
            expect( result[1].lookup( 'y' ).equals quick 'b(3)' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()

Matching `Rule(P((x)),P((y)))` to `Rule(eq(plus(2,3),5),eq(5,5))` gives two
solutions:
 * x=plus(2,3), y=5, and P=lambda[v,eq(v,5)]
 * x=eq(plus(2,3),5), y=eq(5,5), and P=lambda[v,v]

            left = quick 'Rule(_P_of__x,_P_of__y)'
            right = quick 'Rule(eq(plus(2,3),5),eq(5,5))'
            result = someMatches left, right
            expect( result.length ).toBe 2
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'plus(2,3)' )
                .toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick '5' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(v0,5)' ).toBeTruthy()
            expect( result[1].length() ).toBe 3
            expect( result[1].lookup( 'x' ).equals quick 'eq(plus(2,3),5)' )
                .toBeTruthy()
            expect( result[1].lookup( 'y' ).equals quick 'eq(5,5)' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()

Matching `Rule(P((x)),P((y)))` to `Rule(A(1,2,3),A(2,1,3))` gives one
solution:  x=A(1,2,3), y=A(2,1,3), and P=lambda[v,v].

            left = quick 'Rule(_P_of__x,_P_of__y)'
            right = quick 'Rule(A(1,2,3),A(2,1,3))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'A(1,2,3)' )
                .toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'A(2,1,3)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()

Matching `Rule(P((x)),P((y)))` to `Rule(A(1,2,3),A(2,1,3))` gives one
solution:  x=A(1,2,3), y=A(2,1,3), and P=lambda[v,v].

            left = quick 'Rule(_P_of__x,_P_of__y)'
            right = quick 'Rule(A(1,2,3),A(2,1,3))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'A(1,2,3)' )
                .toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'A(2,1,3)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()

Matching `Rule(P((x)),P((x)))` to `Rule(A(1,2,3),A(2,1,3))` gives no
solutions.  (The only change from the previous test is that both of the
children of the pattern expression use the variable x.)

            left = quick 'Rule(_P_of__x,_P_of__x)'
            right = quick 'Rule(A(1,2,3),A(2,1,3))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(P((x)),P((y)))` to `Rule(f(1,2),f(1,2))` gives five
solutions:
 * x=f, y=f, P=lambda[v,v(1,2)]
 * x=1, y=1, and P=lambda[v,f(v,2)]
 * x=2, y=2, and P=lambda[v,f(1,2)]
 * x=f(1,2), y=f(1,2), P=lambda[v,v]
 * P=lambda[v,f(1,2)], with x and y unconstrained

            left = quick 'Rule(_P_of__x,_P_of__y)'
            right = quick 'Rule(f(1,2),f(1,2))'
            result = someMatches left, right
            expect( result.length ).toBe 5
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'f(1,2)' )
                .toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'f(1,2)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()
            expect( result[1].length() ).toBe 3
            expect( result[1].lookup( 'x' ).equals quick 'f' )
                .toBeTruthy()
            expect( result[1].lookup( 'y' ).equals quick 'f' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'v0(1,2)' ).toBeTruthy()
            expect( result[2].length() ).toBe 3
            expect( result[2].lookup( 'x' ).equals quick '1' )
                .toBeTruthy()
            expect( result[2].lookup( 'y' ).equals quick '1' )
                .toBeTruthy()
            expect( alphaEquivalent result[2].lookup( 'P' ),
                ef 'v0', 'f(v0,2)' ).toBeTruthy()
            expect( result[3].length() ).toBe 3
            expect( result[3].lookup( 'x' ).equals quick '2' )
                .toBeTruthy()
            expect( result[3].lookup( 'y' ).equals quick '2' )
                .toBeTruthy()
            expect( alphaEquivalent result[3].lookup( 'P' ),
                ef 'v0', 'f(1,v0)' ).toBeTruthy()
            expect( result[4].length() ).toBe 1
            expect( alphaEquivalent result[4].lookup( 'P' ),
                ef 'v0', 'f(1,2)' ).toBeTruthy()

Matching `P((x))` to `g(k,e(2))` gives six solutions:
 * x=g(k,e(2)) and P=lambda[v,v]
 * x=g and P=lambda[v,v(k,e(2))]
 * x=k and P=lambda[v,g(v,e(2))]
 * x=e(2) and P=lambda[v,g(k,v)]
 * x=e and P=lambda[v,g(k,v(2))]
 * x=2 and P=lambda[v,g(k,e(v))]
 * P=lambda[v,g(k,e(2))] and x is unconstrained

            left = quick '_P_of__x'
            right = quick 'g(k,e(2))'
            result = someMatches left, right
            expect( result.length ).toBe 7
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'g(k,e(2))' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()
            expect( result[1].length() ).toBe 2
            expect( result[1].lookup( 'x' ).equals quick 'g' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'v0(k,e(2))' ).toBeTruthy()
            expect( result[2].length() ).toBe 2
            expect( result[2].lookup( 'x' ).equals quick 'k' )
                .toBeTruthy()
            expect( alphaEquivalent result[2].lookup( 'P' ),
                ef 'v0', 'g(v0,e(2))' ).toBeTruthy()
            expect( result[3].length() ).toBe 2
            expect( result[3].lookup( 'x' ).equals quick 'e(2)' )
                .toBeTruthy()
            expect( alphaEquivalent result[3].lookup( 'P' ),
                ef 'v0', 'g(k,v0)' ).toBeTruthy()
            expect( result[4].length() ).toBe 2
            expect( result[4].lookup( 'x' ).equals quick 'e' )
                .toBeTruthy()
            expect( alphaEquivalent result[4].lookup( 'P' ),
                ef 'v0', 'g(k,v0(2))' ).toBeTruthy()
            expect( result[5].length() ).toBe 2
            expect( result[5].lookup( 'x' ).equals quick '2' )
                .toBeTruthy()
            expect( alphaEquivalent result[5].lookup( 'P' ),
                ef 'v0', 'g(k,e(v0))' ).toBeTruthy()
            expect( result[6].length() ).toBe 1
            expect( alphaEquivalent result[6].lookup( 'P' ),
                ef 'v0', 'g(k,e(2))' ).toBeTruthy()

Matching `P((x))` to `f(a,a)` gives six solutions:
 * x=f(a,a) and P=lambda[v,v]
 * x=f and P=lambda[v,v(a,a)]
 * x=a and P=lambda[x,f(a,v)]
 * x=a and P=lambda[x,f(v,a)]
 * x=a and P=lambda[x,f(v,v)]
 * P=lambda[x,f(a,a)] and x is unconstrained

            left = quick '_P_of__x'
            right = quick 'f(a,a)'
            result = someMatches left, right
            expect( result.length ).toBe 6
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'f(a,a)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0' ).toBeTruthy()
            expect( result[1].length() ).toBe 2
            expect( result[1].lookup( 'x' ).equals quick 'f' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'v0(a,a)' ).toBeTruthy()
            expect( result[2].length() ).toBe 2
            expect( result[2].lookup( 'x' ).equals quick 'a' )
                .toBeTruthy()
            expect( alphaEquivalent result[2].lookup( 'P' ),
                ef 'v0', 'f(v0,a)' ).toBeTruthy()
            expect( result[3].length() ).toBe 2
            expect( result[3].lookup( 'x' ).equals quick 'a' )
                .toBeTruthy()
            expect( alphaEquivalent result[3].lookup( 'P' ),
                ef 'v0', 'f(a,v0)' ).toBeTruthy()
            expect( result[4].length() ).toBe 2
            expect( result[4].lookup( 'x' ).equals quick 'a' )
                .toBeTruthy()
            expect( alphaEquivalent result[4].lookup( 'P' ),
                ef 'v0', 'f(v0,v0)' ).toBeTruthy()
            expect( result[5].length() ).toBe 1
            expect( alphaEquivalent result[5].lookup( 'P' ),
                ef 'v0', 'f(a,a)' ).toBeTruthy()

Matching `Rule(P((x)),x)` to `Rule(f(a,a),b)` gives one solution:
x=b and P=lambda[v,f(a,a)].

            left = quick 'Rule(_P_of__x,_x)'
            right = quick 'Rule(f(a,a),b)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'b' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'f(a,a)' ).toBeTruthy()

Matching `Rule(P((x)),x)` to `Rule(f(a,a),f)` gives two solutions:
 * x=f and P=lambda[v,v(a,a)]
 * x=f and P=lambda[v,f(a,a)]

            left = quick 'Rule(_P_of__x,_x)'
            right = quick 'Rule(f(a,a),f)'
            result = someMatches left, right
            expect( result.length ).toBe 2
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'f' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'v0(a,a)' ).toBeTruthy()
            expect( result[1].length() ).toBe 2
            expect( result[1].lookup( 'x' ).equals quick 'f' )
                .toBeTruthy()
            expect( alphaEquivalent result[1].lookup( 'P' ),
                ef 'v0', 'f(a,a)' ).toBeTruthy()

Matching `Rule(P((a)),Q((b)))` to `Rule(eq(3,3),gt(5,4))` gives thirty
solutions.  The solutions will be all the combinations of solutions
constructed from the following two lists.

First, the list of partial solutions involving a and P:
 * a=eq(3,3) and P=lambda[v,v]
 * a=eq and P=lambda[v,v(3,3)]
 * a=3 and P=lambda[v,eq(v,3)]
 * a=3 and P=lambda[v,eq(3,v)]
 * a=3 and P=lambda[v,eq(v,v)]
 * P=lambda[v,eq(3,3)] and a is unconstrained

Second, the list of partial solutions involving b and Q:
 * b=gt(5,4) and P=lambda[v,v]
 * b=gt and P=lambda[v,v(5,4)]
 * b=5 and P=lambda[v,gt(v,4)]
 * b=4 and P=lambda[v,gt(5,v)]
 * P=lambda[v,gt(5,4)] and b is unconstrained

            left = quick 'Rule(_P_of__a,_Q_of__b)'
            right = quick 'Rule(eq(3,3),gt(5,4))'
            setMatchDebug off
            result = someMatches left, right, 50, yes
            setMatchDebug off
            expect( result.length ).toBe 30
            for i in [0..5]
                numPa = if i < 5 then 2 else 1
                for j in [0..4]
                    numQb = if j < 4 then 2 else 1
                    next = result.shift()
                    expect( next.length() ).toBe numPa + numQb
                    switch i
                        when 0
                            expect( next.lookup( 'a' ).equals \
                                quick 'eq(3,3)' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'v0' ).toBeTruthy()
                        when 1
                            expect( next.lookup( 'a' ).equals \
                                quick 'eq' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'v0(3,3)' ).toBeTruthy()
                        when 2
                            expect( next.lookup( 'a' ).equals \
                                quick '3' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'eq(v0,3)' ).toBeTruthy()
                        when 3
                            expect( next.lookup( 'a' ).equals \
                                quick '3' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'eq(3,v0)' ).toBeTruthy()
                        when 4
                            expect( next.lookup( 'a' ).equals \
                                quick '3' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'eq(v0,v0)' ).toBeTruthy()
                        when 5
                            expect( alphaEquivalent next.lookup( 'P' ),
                                ef 'v0', 'eq(3,3)' ).toBeTruthy()
                    switch j
                        when 0
                            expect( next.lookup( 'b' ).equals \
                                quick 'gt(5,4)' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'Q' ),
                                ef 'v0', 'v0' ).toBeTruthy()
                        when 1
                            expect( next.lookup( 'b' ).equals \
                                quick 'gt' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'Q' ),
                                ef 'v0', 'v0(5,4)' ).toBeTruthy()
                        when 2
                            expect( next.lookup( 'b' ).equals \
                                quick '5' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'Q' ),
                                ef 'v0', 'gt(v0,4)' ).toBeTruthy()
                        when 3
                            expect( next.lookup( 'b' ).equals \
                                quick '4' ).toBeTruthy()
                            expect( alphaEquivalent next.lookup( 'Q' ),
                                ef 'v0', 'gt(5,v0)' ).toBeTruthy()
                        when 4
                            expect( alphaEquivalent next.lookup( 'Q' ),
                                ef 'v0', 'gt(5,4)' ).toBeTruthy()

### should handle the equality elimination rule

The following tests deal with one particular use of expression functions,
the equality elimination rule (a.k.a. "substitution") from first-order
logic.

        it 'should handle the equality elimination rule', ->

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(t,1),gt(t,0),gt(1,0))` should give one solution, mapping a to t, b
to 1, and P to lambda[v0,gt(v0,0)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),gt(t,0),gt(1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick 't' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals ef 'v0', 'gt(v0,0)' )
                .toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(t,1),gt(1,0),gt(t,0))` should give no solutions.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),gt(1,0),gt(t,0))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(t,1),eq(plus(t,1),2),eq(plus(1,1),2))` should give one solution,
mapping a to t, b to 1, and P to lambda[v0,eq(plus(v0,1),2)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),eq(plus(t,1),2),eq(plus(1,1),2))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick 't' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'eq(plus(v0,1),2)' ).toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(t,1),eq(plus(1,1),2),eq(plus(t,1),2))` should give no solutions.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(t,1),eq(plus(1,1),2),eq(plus(t,1),2))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),2))` should give one solution,
mapping a to 1, b to 2, and P to lambda[v0,eq(plus(v0,v0),2)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),2))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'eq(plus(v0,v0),2)' ).toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,1),2))` should give one solution,
mapping a to 1, b to 2, and P to lambda[v0,eq(plus(v0,1),2)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,1),2))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'eq(plus(v0,1),2)' ).toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,2),2))` should give one solution,
mapping a to 1, b to 2, and P to lambda[v0,eq(plus(1,v0),2)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,2),2))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '2' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'eq(plus(1,v0),2)' ).toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),2))` should give one solution,
mapping a to 1, b to 2, and P to lambda[v0,eq(plus(1,1),2)].

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),2))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'a' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'b' ).equals quick '2' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(plus(1,1),2)' ).toBeTruthy()

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),1))` should give no solutions.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(2,2),1))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),1))` should give no solutions.

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick 'Rule(eq(1,2),eq(plus(1,1),2),eq(plus(1,1),1))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(eq(_a,_b),_P((_a)),_P((_b)))` to
`Rule(eq(x,y),exi.sts[y,ne(y,x)],exi.sts[y,ne(y,y)])` should give no
solutions.  (The `nextMatch` function returns a solution, but it is
filtered out because it violates binding constraints.)

            left = quick 'Rule(eq(_a,_b),_P_of__a,_P_of__b)'
            right = quick \
                'Rule(eq(x,y),exi.sts[y,ne(y,x)],exi.sts[y,ne(y,y)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should handle the universal elimination rule

The following tests deal with one particular use of expression functions,
the universal elimination rule from first-order logic.

        it 'should handle the universal elimination rule', ->

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,ge(x,0)],ge(7,0))` should give one solution, mapping x to x,
P to lambda[v0,ge(v0,0)], and t to 7.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,ge(x,0)],ge(7,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 't' ).equals quick '7' ).toBeTruthy()
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals ef 'v0', 'ge(v0,0)' ) \
                .toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,ge(x,0)],ge(7,7))` should give no solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,ge(x,0)],ge(7,7))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,Q],Q)` should give one solution, mapping x to x,
P to lambda[v0,Q], and t unconstrained.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,Q],Q)'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'Q' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[s,eq(sq(s),s)],eq(sq(1),1))` should give one solution, mapping
x to s, P to lambda[v0,eq(sq(v0),v0)], and t to 1.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[s,eq(sq(s),s)],eq(sq(1),1))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 's' ).toBeTruthy()
            expect( result[0].lookup( 't' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'eq(sq(v0),v0)' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,y)],R(x,3))` should give no solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,y)],R(x,3))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,y)],R(3,y))` should give one solution, mapping
x to x, P to lambda[v0,R(v0,y)], and t to 3.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,y)],R(3,y))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'R(v0,y)' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,x)],R(3,3))` should give one solution, mapping
x to x, P to lambda[v0,R(v0,v0)], and t to 3.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(3,3))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals \
                ef 'v0', 'R(v0,v0)' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,x)],R(3,x))` should give no solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(3,x))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,x)],R(x,3))` should give no solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(x,3))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,R(x,x)],R(x,x))` should give one solution, mapping
x to x, P to lambda[v0,R(v0,v0)], and t to x.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,R(x,x)],R(x,x))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 't' ).equals quick 'x' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'R(v0,v0)' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[s,eq(plus(s,s),r)],eq(plus(t,s),r))` should give no solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[s,eq(plus(s,s),r)],eq(plus(t,s),r))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,eq(x,x)],eq(iff(P,Q),iff(P,Q)))` should give one solution,
mapping x to x, P to lambda[v0,eq(v0,v0)], and t to iff(P,Q).

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick 'Rule(for.all[x,eq(x,x)],eq(iff(P,Q),iff(P,Q)))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 't' ).equals quick 'iff(P,Q)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(v0,v0)' ).toBeTruthy()

Matching `Rule(for.all[_x,_P((_x))],_P((_t)))` to
`Rule(for.all[x,exi.sts[y,lt(x,y)]],exi.sts[y,lt(y,y)])` should give no
solutions.

            left = quick 'Rule(for.all[_x,_P_of__x],_P_of__t)'
            right = quick \
                'Rule(for.all[x,exi.sts[y,lt(x,y)]],exi.sts[y,lt(y,y)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should handle the universal introduction rule

The following tests deal with one particular use of expression functions,
the universal introduction rule from first-order logic.  Here I use `S` to
indicate a subproof structure.

        it 'should handle the universal introduction rule', ->

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])` should give no results.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])` should give one solution,
mapping x to a, P to lambda[v0,r(v0,v0)], and y to b.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,r(a,a)],for.all[b,r(b,b)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'b' ).toBeTruthy()
            expect( result[0].lookup( 'P' ).equals ef 'v0', 'r(v0,v0)' ) \
                .toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])` should give one solution,
mapping x to a, P to lambda[v0,gt(v0,3)], and y to a.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'a' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,3)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])` should give one solution,
mapping x to a, P to lambda[v0,gt(v0,3)], and y to x.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'x' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,3)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])` should give one solution,
mapping x to T, P to lambda[v0,R(v0,v0)], and y to T.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'T' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'T' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'R(v0,v0)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])` should give no solutions.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[y,ne(0,1)],for.all[z,ne(0,1)])` should give one solution,
mapping x to y, P to lambda[v0,ne(0,1)], and y to z.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[y,ne(0,1)],for.all[z,ne(0,1)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'z' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'ne(0,1)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[b,eq(minus(b,b),0)],for.all[c,eq(minus(b,c),0)])` should give
no solutions.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick \
            'Rule(sub.prf[b,eq(minus(b,b),0)],for.all[c,eq(minus(b,c),0)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])` should give one solution,
mapping x to a and P to lambda[v0,gt(v0,3)].

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[a,gt(a,3)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'a' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,3)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])` should give no solutions.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[a,gt(a,3)],for.all[x,gt(x,3)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])` should give one solution,
mapping x to T and P to lambda[v0,R(v0,v0)].

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[T,R(T,T)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'T' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'R(v0,v0)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])` should give no solutions.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[T,R(T,T)],for.all[x,R(T,x)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[y,ne(0,1)],for.all[y,ne(0,1)])` should give one solution,
mapping x to y and P to lambda[v0,ne(0,1)].

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[y,ne(0,1)],for.all[y,ne(0,1)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 2
            expect( result[0].lookup( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'ne(0,1)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_y,_P((_y))])` to
`Rule(sub.prf[x,eq(x,x)],for.all[x,eq(x,x)])` should give one solution,
mapping x to x, y to x, and P to lambda[v0,eq(v0,v0)].

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_y,_P_of__y])'
            right = quick 'Rule(sub.prf[x,eq(x,x)],for.all[x,eq(x,x)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'x' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(v0,v0)' ).toBeTruthy()

Matching `Rule(sub.prf[_x,_P((_x))],for.all[_x,_P((_x))])` to
`Rule(sub.prf[x,exi.sts[y,lt(x,y)]],for.all[y,exi.sts[y,lt(y,y)]])` should
give no solutions.

            left = quick 'Rule(sub.prf[_x,_P_of__x],for.all[_x,_P_of__x])'
            right = quick 'Rule(sub.prf[x,exi.sts[y,lt(x,y)]],' + \
                          'for.all[y,exi.sts[y,lt(y,y)]])'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should handle the existential introduction rule

The following tests deal with one particular use of expression functions,
the existential introduction rule from first-order logic.

        it 'should handle the existential introduction rule', ->

Matching `Rule(_P((_t)),exi.sts[_x,_P((_x))])` to
`Rule(ge(1,0),exi.sts[x,ge(x,0)])` should yield one solution, mapping P to
lambda[v0,ge(v0,0)], t to 1, and x to x.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ge(1,0),exi.sts[x,ge(x,0)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 't' ).equals quick '1' ).toBeTruthy()
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'ge(v0,0)' ).toBeTruthy()

Matching `Rule(_P((_t)),exi.sts[_x,_P((_x))])` to
`Rule(eq(choose(6,3),20),exi.sts[n,eq(choose(6,n),20)])` should yield one
solution, mapping P to lambda[v0,eq(choose(6,v0),20)], t to 3, and x to n.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(eq(choose(6,3),20),' + \
                          'exi.sts[n,eq(choose(6,n),20)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 't' ).equals quick '3' ).toBeTruthy()
            expect( result[0].lookup( 'x' ).equals quick 'n' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(choose(6,v0),20)' ).toBeTruthy()

Matching `Rule(_P_of__t,exi.sts[_x,_P_of__x])` to
`Rule(lt(pow(t,x),5),exi.sts[x,lt(pow(x,x),5)])` should give no solutions.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(lt(pow(t,x),5),exi.sts[x,lt(pow(x,x),5)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(_P((_t)),exi.sts[_x,_P((_x))])` to
`Rule(ne(x,t),exi.sts[y,ne(y,t)])` should yield one
solution, mapping P to lambda[v0,ne(v0,t)], t to x, and x to y.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ne(x,t),exi.sts[y,ne(y,t)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 't' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'x' ).equals quick 'y' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'ne(v0,t)' ).toBeTruthy()

Matching `Rule(_P_of__t,exi.sts[_x,_P_of__x])` to
`Rule(ne(x,t),exi.sts[x,ne(x,x)])` should give no solutions.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick 'Rule(ne(x,t),exi.sts[x,ne(x,x)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(_P_of__t,exi.sts[_x,_P_of__x])` to
`Rule(for.all[t,eq(t,t)],exi.sts[x,for.all[t,eq(x,t)]])` should give no
solutions.

            left = quick 'Rule(_P_of__t,exi.sts[_x,_P_of__x])'
            right = quick \
                'Rule(for.all[t,eq(t,t)],exi.sts[x,for.all[t,eq(x,t)]])'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should handle the induction scheme for N

The following tests deal with one particular use of expression functions,
the induction scheme for the natural numbers.

        it 'should handle the induction scheme for N', ->

The induction scheme is the lengthy expression
`Rule(_P((0)),for.all[_k,imp(_P((_k)),_P((plus(_k,1))))],for.all[_n,_P((_n))])`.
Matching it to
`Rule(ge(0,0),for.all[n,imp(ge(n,0),ge(plus(n,1),0))],for.all[n,ge(n,0)])`
should give one solution, mapping P to lambda[v0,ge(v0,0)], k to n, and n to
n.

            piece = quick 'plus(_k,1)'
            piece = aef '_P', piece
            piece = OM.app quick( 'imp' ), quick( '_P_of__k' ), piece
            left = OM.app quick( 'Rule' ),
                quick( '_P_of_0' ),
                OM.bin( quick( 'for.all' ), quick( '_k' ), piece ),
                quick 'for.all[_n,_P_of__n]'
            right = quick 'Rule(ge(0,0),' + \
                          'for.all[n,imp(ge(n,0),ge(plus(n,1),0))],' + \
                          'for.all[n,ge(n,0)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'k' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].lookup( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'ge(v0,0)' ).toBeTruthy()

Matching the same induction scheme to
`Rule(eq(plus(0,0),0),for.all[m,imp(eq(plus(m,0),m),eq(plus(plus(m,1),0),plus(m,1)))],for.all[k,eq(plus(k,0),k)])`
should give one solution, mapping P to lambda[v0,eq(plus(v0,0),v0)], k to m,
and n to k.

            right = quick 'Rule(eq(plus(0,0),0),' + \
                          'for.all[m,imp(eq(plus(m,0),m),' + \
                            'eq(plus(plus(m,1),0),plus(m,1)))],' + \
                          'for.all[k,eq(plus(k,0),k)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'k' ).equals quick 'm' ).toBeTruthy()
            expect( result[0].lookup( 'n' ).equals quick 'k' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(plus(v0,0),v0)' ).toBeTruthy()

Matching the same induction scheme to
`Rule(P(0),for.all[k,imp(P(k),P(plus(k,1)))],for.all[n,P(n)])`
should give one solution, mapping P to lambda[v0,P(v0)], k to k,
and n to n.

            right = quick 'Rule(P(0),for.all[k,imp(P(k),P(plus(k,1)))],' + \
                          'for.all[n,P(n)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'k' ).equals quick 'k' ).toBeTruthy()
            expect( result[0].lookup( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'P(v0)' ).toBeTruthy()

Matching the same induction scheme to
`Rule(eq(7,5),for.all[n,imp(eq(7,5),eq(7,5))],for.all[n,eq(7,5)])`
should give one solution, mapping P to lambda[v0,eq(7,5)], k to n,
and n to n.

            right = quick 'Rule(eq(7,5),for.all[n,imp(eq(7,5),eq(7,5))],' +\
                          'for.all[n,eq(7,5)])'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'k' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].lookup( 'n' ).equals quick 'n' ).toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(7,5)' ).toBeTruthy()

Matching the same induction scheme to
`Rule(R(n,1),for.all[m,imp(R(m,1),R(plus(m,1),1))],for.all[m,R(m,1)])`
should give no solutions.

            right = quick 'Rule(R(n,1),' + \
                'for.all[m,imp(R(m,1),R(plus(m,1),1))],for.all[m,R(m,1)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching the same induction scheme to
`Rule(ge(k,0),for.all[k,imp(ge(k,k),ge(k,plus(k,1)))],for.all[n,ge(n,k)])`
should give no solutions.

            right = quick 'Rule(ge(k,0),' + \
            'for.all[k,imp(ge(k,k),ge(k,plus(k,1)))],for.all[n,ge(n,k)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching the same induction scheme to
`Rule(ge(n,0),for.all[k,imp(ge(n,k),ge(n,plus(k,1)))],for.all[n,ge(n,n)])`
should give no solutions.

            right = quick 'Rule(ge(n,0),' + \
            'for.all[k,imp(ge(n,k),ge(n,plus(k,1)))],for.all[n,ge(n,n)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching the same induction scheme to
`Rule(ge(0,0),for.all[n,imp(ge(n,0),ge(plus(n,1),0))],for.all[n,ge(0,0)])`
should give no solutions.

            right = quick 'Rule(ge(0,0),' + \
            'for.all[n,imp(ge(n,0),ge(plus(n,1),0))],for.all[n,ge(0,0)])'
            result = someMatches left, right
            expect( result.length ).toBe 0

### should handle the existential elimination rule

The following tests deal with one particular use of expression functions,
the existential elimination rule from first-order logic.

        it 'should handle the existential elimination rule', ->

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[x,eq(sq(x),1)],for.all[x,imp(eq(sq(x),1),ge(1,0))],ge(1,0))`
should give one solution, mapping x to x, P to lambda[v0,eq(sq(v0),1)], and
Q to ge(1,0).

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,eq(sq(x),1)],' + \
                          'for.all[x,imp(eq(sq(x),1),ge(1,0))],ge(1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'Q' ).equals quick 'ge(1,0)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'eq(sq(v0),1)' ).toBeTruthy()

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[x,eq(sq(x),1)],for.all[x,imp(eq(sq(x),1),le(x,1))],le(x,1))`
should give no solutions.

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,eq(sq(x),1)],' + \
                          'for.all[x,imp(eq(sq(x),1),le(x,1))],le(x,1))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[x,gt(x,0)],imp(for.all[x,gt(x,0)],gt(-1,0)),gt(-1,0))`
should give no solutions.

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],' + \
                          'imp(for.all[x,gt(x,0)],gt(-1,0)),gt(-1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[x,gt(x,0)],for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))`
should give one solution, mapping x to x, P to lambda[v0,gt(v0,0)], and
Q to gt(-1,0).

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],' + \
                          'for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 3
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'Q' ).equals quick 'gt(-1,0)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,0)' ).toBeTruthy()

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[m,gt(m,0)],for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))`
should give no solutions.

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_x,imp(_P_of__x,_Q)],_Q)'
            right = quick 'Rule(exi.sts[m,gt(m,0)],' + \
                          'for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 0

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_y,imp(_P((_y)),_Q)],_Q)` to
`Rule(exi.sts[x,gt(x,0)],for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))`
should give one solution, mapping x to x, y to x, P to lambda[v0,gt(v0,0)],
and Q to gt(-1,0).

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[x,gt(x,0)],' + \
                          'for.all[x,imp(gt(x,0),gt(-1,0))],gt(-1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 4
            expect( result[0].lookup( 'x' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'x' ).toBeTruthy()
            expect( result[0].lookup( 'Q' ).equals quick 'gt(-1,0)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,0)' ).toBeTruthy()

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_y,imp(_P((_y)),_Q)],_Q)` to
`Rule(exi.sts[m,gt(m,0)],for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))`
should give one solution, mapping x to m, y to n, P to lambda[v0,gt(v0,0)],
and Q to gt(-1,0).

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[m,gt(m,0)],' + \
                          'for.all[n,imp(gt(n,0),gt(-1,0))],gt(-1,0))'
            result = someMatches left, right
            expect( result.length ).toBe 1
            expect( result[0].length() ).toBe 4
            expect( result[0].lookup( 'x' ).equals quick 'm' ).toBeTruthy()
            expect( result[0].lookup( 'y' ).equals quick 'n' ).toBeTruthy()
            expect( result[0].lookup( 'Q' ).equals quick 'gt(-1,0)' )
                .toBeTruthy()
            expect( alphaEquivalent result[0].lookup( 'P' ),
                ef 'v0', 'gt(v0,0)' ).toBeTruthy()

Matching `Rule(exi.sts[_x,_P((_x))],for.all[_x,imp(_P((_x)),_Q)],_Q)` to
`Rule(exi.sts[n,lt(n,a)],for.all[a,imp(lt(a,a),lt(a,a))],lt(a,a))`
should give no solutions.

            left = quick 'Rule(exi.sts[_x,_P_of__x],' + \
                         'for.all[_y,imp(_P_of__y,_Q)],_Q)'
            right = quick 'Rule(exi.sts[n,lt(n,a)],' + \
                          'for.all[a,imp(lt(a,a),lt(a,a))],lt(a,a))'
            result = someMatches left, right
            expect( result.length ).toBe 0
