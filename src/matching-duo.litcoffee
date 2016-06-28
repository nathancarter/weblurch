
# The Matching Module

This module implements the algorithm documented thoroughly in an unpublished
paper entitled "A First Matching Algorithm for Lurch."  Contact the owners
of this source code repository for a copy.

The following lines ensure that this file works in Node.js, for testing.

    if not exports? then exports = module?.exports ? window
    if require? then { OM, OMNode } = require './openmath-duo'

## Metavariables

All of the routines in this section make use of a single common symbol, so
we create one instance here for use repeatedly.  We also create an instance
of a string that signifies a boolean true value, because that will be the
value of the attribute whose key is the metavariable symbol.

    metavariableSymbol = OM.symbol 'metavariable', 'lurch'
    trueValue = OM.string 'true'

We begin with a routine that marks a variable as a metavariable.  It accepts
as parameter any `OMNode` instance (as implemented
[here](openmath-duo.litcoffee)) and gives it an attribute that the rest of
this package recognizes as meaning "this variable is actually a
metavariable."  This routine does nothing if the given input is not an
OMNode of type variable or type symbol.

(It is necessary to permit symbols to be metavariables because there are
some positions in an OpenMath tree that can only be occupied by symbols.
For instance, if we wished to express the pattern "forall x, P(x)" but with
the forall symbol replaced by a metavariable, it would need to be a symbol
in order for the expression to be a valid OpenMath object.)

    exports.setMetavariable = setMetavariable = ( variable ) ->
        if variable not instanceof OMNode or \
           variable.type not in [ 'v', 'sy' ] then return
        variable.setAttribute metavariableSymbol, trueValue.copy()

To undo the above action, call the following function, which removes the
attribute.

    exports.clearMetavariable = clearMetavariable = ( metavariable ) ->
        metavariable.removeAttribute metavariableSymbol

To query whether a variable has been marked as a metaviariable, use the
following routine, which tests for the presence of the attribute in
question.

    exports.isMetavariable = isMetavariable = ( variable ) ->
        variable instanceof OMNode and variable.type in [ 'v', 'sy' ] and \
            variable.getAttribute( metavariableSymbol )?.equals trueValue

## Expression functions and expression function applications

This module supports patterns that express the application of a function to
a parameter, where the function maps OpenMath expressions to OpenMath
expressions, as described in the paper cited at the top of this file.  We
will represent a function with the following binding head symbol.

    expressionFunction = OM.symbol 'EF', 'lurch'

We express the application of such a function to an argument as an
application of the following symbol.

    expressionFunctionApplication = OM.symbol 'EFA', 'lurch'

So for example, `P(x)` would be expressed as `OM.simple 'lurch.EFA(P,X)'`
and the map from input `p` to output `h(x,p,p)` as `OM.simple
'lurch.EF[p,h(x,p,p)]'`.

We therefore construct a few convenience functions for testing whether an
expression is of one of the types above, and for constructing expressions of
those types.

    exports.makeExpressionFunction =
    makeExpressionFunction = ( variable, body ) =>
        if variable.type isnt 'v' then throw 'When creating an expression
            function, its parameter must be a variable'
        OM.bin expressionFunction, variable, body
    exports.isExpressionFunction =
    isExpressionFunction = ( expression ) =>
        expression.type is 'bi' and expression.variables.length is 1 and \
            expression.symbol.equals expressionFunction
    exports.makeExpressionFunctionApplication =
    makeExpressionFunctionApplication = ( func, argument ) =>
        OM.app expressionFunctionApplication, func, argument
    exports.isExpressionFunctionApplication =
    isExpressionFunctionApplication = ( expression ) =>
        expression.type is 'a' and expression.children.length is 3 and \
            expression.children[0].equals expressionFunctionApplication

You can also apply expression functions to expressions (unsurprisingly, as
that is their purpose).

    exports.applyExpressionFunction =
    applyExpressionFunction = ( func, expression ) ->
        result = func.body.copy()
        result.replaceFree func.variables[0], expression
        result

We also include a function that tests whether two expression functions are
alpha equivalent.

    exports.alphaEquivalent = alphaEquivalent = ( func1, func2 ) ->
        index = 0
        newVar = -> OM.var "v#{index}"
        isNewVar = ( expr ) -> expr.equals newVar()
        pair = OM.app func1, func2
        while pair.hasDescendantSatisfying isNewVar then index++
        apply1 = applyExpressionFunction func1, newVar()
        apply2 = applyExpressionFunction func2, newVar()
        isExpressionFunction( func1 ) and \
        isExpressionFunction( func2 ) and apply1.equals apply2

## Consistent patterns

A list of patterns is consistent if every metavariable appearing in any of
the patterns in the position of an expression function always appears as an
expression function (or equivalently any metavariable appearing anywhere
other than as the first child of an expression function application never
appears anywhere as the first child of an expression function application).

The motivation is that it would be inconsistent to demand that one pattern
instantiate a metavariable as an expression function, but another pattern
demand that the same metavariable be instantiated as a plain expression.

    exports.consistentPatterns = consistentPatterns = ( patterns... ) ->
        nonFunctionMetavariables = [ ]
        functionMetavariables = [ ]
        for pattern in patterns
            for M in pattern.descendantsSatisfying isMetavariable
                if isExpressionFunctionApplication( M.parent ) and \
                        M.findInParent() is 'c1'
                    if M.name in nonFunctionMetavariables then return no
                    if M.name not in functionMetavariables
                        functionMetavariables.push M.name
                else
                    if M.name in functionMetavariables then return no
                    if M.name not in nonFunctionMetavariables
                        nonFunctionMetavariables.push M.name
        yes

## Constraint class

A constraint is a pair of OpenMath expressions, the first of which will be
interpreted as a pattern, and the second as an expression.  Constraints can
be used as part of a problem to solve, or as part of a solution.  When they
are part of a solution, the pattern is always a lone metavariable.

    exports.Constraint = Constraint = class

Construct a constraint by providing the pattern and the expression.

        constructor : ( @pattern, @expression ) ->

They can be copied by copying each component.

        copy : -> new Constraint @pattern.copy(), @expression.copy()

Two are equal if their components are equal.

        equals : ( other ) ->
            @pattern.equals( other.pattern, no ) and \
            @expression.equals( other.expression, no )

## Constraint list class

A constraint list is simply an array of constraints, with a few convenience
functions added for adding, removing, and searching in a way unique to lists
of constraints.  It can be used to express a problem as a list of
constraints, or a solution as a list of metavariable-expression pairs.

    exports.ConstraintList = ConstraintList = class

Construct a constraint list by providing zero or more constraints to add to
it initially.  Besides simply storing those constraints, this function also
computes the first variable from the list `v0`, `v1`, `v2`, ... that does
not appear in any of the constraints.  Call it `vn`.  Then later the
`newVariable` member can be called in this object at any time to generate an
infinite stream of new variables starting with `vn`.

        constructor : ( @contents... ) ->
            @nextNewVariableIndex = 0
            checkVariable = ( variable ) =>
                if /^v[0-9]+$/.test variable.name
                    @nextNewVariableIndex = Math.max @nextNewVariableIndex,
                        parseInt( variable.name[1..] ) + 1
            variablesIn = ( expression ) ->
                expression.descendantsSatisfying ( d ) -> d.type is 'v'
            for constraint in @contents
                for variable in variablesIn constraint.pattern
                    checkVariable variable
                for variable in variablesIn constraint.expression
                    checkVariable variable

Generating new variables, as documented in the previous function, is
accomplished by this function.

        nextNewVariable : -> OM.simple "v#{@nextNewVariableIndex++}"

The length of the constraint list is just the length of its contents array.

        length : -> @contents.length

You can create a copy by just creating a copy of all the entries.  If this
object has not had any constraints modified or removed since its creation,
that simple kind of copy would naturally result in the correct value of
`nextNewVariableIndex` in the copy, but of course this object may have had
some constraints modified or removed since its creation, so we copy that
datum over explicitly.

        copy : ->
            result = new ConstraintList ( c.copy() for c in @contents )...
            result.nextNewVariableIndex = @nextNewVariableIndex
            result

The following function is mostly for internal use, in defining functions
below.  It finds the first index at which the given predicate holds of the
constraint at that index, or returns -1 if there is no such index.

        indexAtWhich : ( predicate ) ->
            for constraint, index in @contents
                if predicate constraint then return index
            -1

This function adds constraints to the list, but each constraint is only
added if it's not already on the list (using the `equals` member of the
constraint class for comparison).

        plus : ( constraints... ) ->
            result = @copy()
            for constraint in constraints
                index = result.indexAtWhich ( c ) -> c.equals constraint, no
                if index is -1 then result.contents.push constraint
            result

This function removes constraints from the list.  Any constraint passed that
is not on the list is silently ignored.

        minus : ( constraints... ) ->
            result = @copy()
            for constraint in constraints
                index = result.indexAtWhich ( c ) -> c.equals constraint, no
                if index > -1 then result.contents.splice index, 1
            result

This function returns the first constraint in the list satisfying the given
predicate, or null if there is not one.

        firstSatisfying : ( predicate ) ->
            @contents[@indexAtWhich predicate] ? null

This function returns a length-two array containing the first two
constraints satisfying the given binary predicate, or null if there is not
one.  In this case, "first" means by dictionary ordering the pair of the
indices of the two constraints returned.  If there is no such pair, this
returns null.

        firstPairSatisfying : ( predicate ) ->
            for constraint1, index1 in @contents
                for constraint2, index2 in @contents
                    if index1 isnt index2
                        if predicate constraint1, constraint2
                            return [ constraint1, constraint2 ]
            null

Some constraint lists are functions from the space of metavariables to the
space of expressions.  To be such a function, the constraint list must
contain only constraints whose left hand sides are metavariables, and none
msut appear in more than one constraint.  This function determines whether
that is true.

        isFunction : ->
            seenSoFar = [ ]
            for constraint in @contents
                if not isMetavariable constraint.pattern then return no
                if constraint.pattern.name in seenSoFar then return no
                seenSoFar.push constraint.pattern.name
            yes

A constraint list that is a function can be used as a lookup table.  This
routine implements the lookup function.  It can accept a variable (an
`OMNode` object) or just the name of one (a string) as argument.  This
routine finds the first pair in the list for which that variable name is the
left hand side, and returns the right hand side.  If `isFunction()` is true,
then it will be the only such pair.  If ther is no such pair, this returns
null.

The input, if it is an OMNode, will have its metavariable flag set.  If you
do not want your input changed, pass a copy.  The result will be the actual
OMNode that is in the other half of the constraint pair.  If you plan to
modify it, make a copy.

        lookup : ( variable ) ->
            if variable not instanceof OM then variable = OM.var variable
            setMetavariable variable
            for constraint in @contents
                if constraint.pattern.equals variable, no
                    return constraint.expression
            null

You can also apply a constraint list that is a function to a larger
expression containing metavariables, to replace them all at once.  This
member function does so, after first creating a copy of the expression, so
as not to alter the original.

        apply : ( expression ) ->
            result = expression.copy()
            metavariables = result.descendantsSatisfying isMetavariable
            for metavariable in metavariables
                if ( value = @lookup metavariable )?
                    metavariable.replaceWith value
            result

Two constraint lists are equal if a pair in either is also in the other.

        equals : ( other ) ->
            for constraint in @contents
                if not other.firstSatisfying( ( c ) -> c.equals constraint )
                    return no
            for constraint in other.contents
                if not @firstSatisfying( ( c ) -> c.equals constraint )
                    return no
            yes

## Differences and parent addresses

The notion of an address is defined in [the OpenMath
module](../src/openmath-duo.litcoffee).

This function computes the set of addresses at which two expressions differ.
It uses an internal recursive function that fills a list that's initially
empty.

    exports.findDifferencesBetween =
    findDifferencesBetween = ( expression1, expression2 ) ->
        differences = [ ]
        recur = ( A, B ) ->
            if A.type isnt B.type
                return differences.push A.address expression1
            if A.type is 'bi'
                Ac = [ A.symbol, A.variables..., A.body ]
                Bc = [ B.symbol, B.variables..., B.body ]
            else
                Ac = A.children
                Bc = B.children
            if Ac.length isnt Bc.length or \
               ( Ac.length + Bc.length is 0 and not A.equals B, no )
                differences.push A.address expression1
            else
                recur child, Bc[index] for child, index in Ac
        recur expression1, expression2
        differences

Given a set of addresses, we can compute the set of parent addresses of
those addresses.  This function does so, but using lists in place of sets.
Note that the empty address has no parent, so if we ask what the set of
parent addresses are of [ empty address ], we get null.

    exports.parentAddresses =
    parentAddresses = ( addresses ) ->
        results = [ ]
        for address in addresses
            if address.length is 0 then continue
            serialized = JSON.stringify address[...-1]
            if serialized not in results then results.push serialized
        if results.length is 0 then return null
        JSON.parse address for address in results

## Subexpressions

The following function partitions the addresses of all subexpressions of
the given expression into equivalence classes by equality of subexpressions
at those addresses.  Each part in the partition is actually an object with
two members, one begin the `subexpression`

    exports.partitionedAddresses =
    partitionedAddresses = ( expression ) ->
        partition = []
        recur = ( subexpression ) ->
            found = no
            for part in partition
                if subexpression.equals part.subexpression, no
                    part.addresses.push subexpression.address expression
                    found = yes
                    break
            if not found then partition.push
                subexpression : subexpression
                addresses : [ subexpression.address expression ]
            recur child for child in subexpression.children
        recur expression
        partition

## Iterators

For the purposes of this file, an iterator is a function that, when called
with zero arguments, returns new values from each call, until it eventually
returns null (which is a fixed point, and it will continue to return null
for all subsequent calls).

Given two expressions $e_1$ and $e_2$, compute their difference set, as
defined in the paper cited at the top of this document, and call it $D$.
Let $A$ be the set of ancestor sets to $D$ that are uniform on both $e_1$
and $e_2$.  This iterator enumerates $A$.

It relies on the fact that, in order for an address set to be uniform on any
expression, the addresses in the set must all be to subtrees of the same
height.  Thus the first step of the iteration is to shrink the addresses in
a difference set until all subtrees have the same height.  Then we can
enumerate $A$ by simply repeatedly computing parent addresses of the entire
set.  This makes the enumeration linear.  Consequently, we need the
following handy function.

    exports.expressionDepth = expressionDepth = ( expression ) ->
        children = [ expression.children..., expression.variables... ]
        if expression.body then children.push expression.body
        if expression.symbol then children.push expression.symbol
        1 + Math.max 0, ( expressionDepth child for child in children )...

Given a set $S$ of addresses into an expression $e$, with varying depths of
subtrees $e[s]$ for $s\in S$, we will want to compute the set of ancestors
of addresses in $S$ whose subexpressions in $e$ all have the same depth, the
maximum depth of the $e[s]$ for $s\in S$.  This function does so.  Note that
it never returns an empty array (if the input list was nonempty) because the
address `[]` is an ancestor to every address, and so the set `[ [] ]` will
always be a valid same-depth ancestor set to the input (though possibly not
the minimum depth one).

    exports.sameDepthAncestors =
    sameDepthAncestors = ( expression, addresses ) ->

Try to find a pair of addresses of different depths.

        for address1, index1 in addresses
            depth1 = expressionDepth expression.index address1
            for address2, index2 in addresses
                depth2 = expressionDepth expression.index address2
                if depth1 is depth2 then continue

Ensure the shallower is #1 and the deeper is #2, then deepen #1.

                if depth1 > depth2
                    [ address1, address2 ] = [ address2, address1 ]
                    [ index1, index2 ] = [ index2, index1 ]
                deeper = address1[...-1]

Replace the old, shallower version with its deeper version, then recur.

                improvement = addresses[..]
                improvement[index1] = address1[...-1]
                return sameDepthAncestors expression, improvement

If there was no pair of addresses of different depths, then we just remove
duplicates to ensure that this is a set, and we're done.

        results = []
        for address in addresses
            serialized = JSON.stringify address
            if serialized not in results then results.push serialized
        JSON.parse serialized for serialized in results

Now we can use those two functions to build the difference iterator
specified at the start of this section.  Note that it assumes that the two
expressions passed in are not equal, so that there exists a difference set.

    exports.differenceIterator =
    differenceIterator = ( expression1, expression2 ) ->
        nextAddressSet = sameDepthAncestors expression1, \
            findDifferencesBetween expression1, expression2
        indexedSubexpressionsAreEqual = ( addresses ) ->
            for address1 in addresses
                for address2 in addresses
                    if not expression1.index( address1 ).equals \
                            expression1.index( address2 ), no then return no
                    if not expression2.index( address1 ).equals \
                            expression2.index( address2 ), no then return no
            yes
        ->
            while nextAddressSet? and \
                  not indexedSubexpressionsAreEqual nextAddressSet
                pars = parentAddresses nextAddressSet
                nextAddressSet =
                    pars and sameDepthAncestors expression1, pars
            result = nextAddressSet
            if result isnt null
                pars = parentAddresses nextAddressSet
                nextAddressSet =
                    pars and sameDepthAncestors expression1, pars
            result

Given an expression $e$, we consider the set of all subexpressions $U$ of
$e$, and say that they are labeled $u_1,\ldots,u_n$.  For any $u_i$, let
$A_{u_i}$ be the set of addresses (in the sense defined in [the OpenMath
module](../src/openmath-duo.litcoffee)) to all instances of $u_i$ in $e$.
For each $A_{u_i}$, we enumerate its nonempty subsets, and call them
$S_{i,1},\ldots,S_{i,m_i}$.  This iterator returns the list
$S_{1,1},S_{1,2},\ldots,S_{n,m_n}$, followed by the string `'done'`.

    exports.subexpressionIterator =
    subexpressionIterator = ( expression ) ->
        partition = partitionedAddresses expression
        state =
            next : partition.shift()
            rest : partition
            subsetIndex : 1
        iterator = ->
            matchDebug '\t\tsubexpression iterator for',
                expression.simpleEncode(), 'next:',
                JSON.stringify( state.next.addresses ), 'rest:',
                JSON.stringify( ( x.addresses for x in state.rest ) ),
                'subsetIndex:', state.subsetIndex
            if state.subsetIndex < 2 ** state.next.addresses.length
                result = ( state.next.addresses[i] \
                    for i in [0...state.next.addresses.length] \
                    when 0 < ( state.subsetIndex & 2 ** i ) )
                state.subsetIndex++
                return result
            if state.rest.length > 0
                state.next = state.rest.shift()
                state.subsetIndex = 1
                return iterator()
            return null
        iterator

The following function takes an iterator and an element, and yields a new
iterator whose return list is the same as that of the given iterator, but
prefixed with the new element (just once).

    exports.prefixIterator = prefixIterator = ( element, iterator ) ->
        firstCallHasHappened = no
        ->
            if firstCallHasHappened then return iterator()
            firstCallHasHappened = yes
            element

The following function takes an iterator and an element, and yields a new
iterator whose return list is the same as that of the given iterator, but
suffixed with the new element (just once).

    exports.suffixIterator = suffixIterator = ( iterator, element ) ->
        suffixHasHappened = no
        ->
            result = iterator()
            if result is null and not suffixHasHappened
                result = element
                suffixHasHappened = yes
            result

The following function takes an iterator and composes it with a function,
returning a new iterator that returns a list each of whose values is the
same as the old iterator would have returned, but first passed through the
given function.

    exports.composeIterator = composeIterator = ( iterator, func ) ->
        -> if result = iterator() then func result else null

The following function takes an iterator and a filter.  It yields a new
iterator that yields a subsequence of what the given iterator yields,
specifically exactly those results that pass the test of the filter.

    exports.filterIterator = filterIterator = ( iterator, filter ) ->
        ->
            next = iterator()
            while next and not filter next then next = iterator()
            next

The following function takes two iterators and concatenates them, returning
a new iterator that returns first all the items from the first iterator (not
including the terminating null sequence), followed by all the items from the
second iterator (including the terminating null sequence).

    exports.concatenateIterators = concatenateIterators =
        ( first, second ) -> -> first() or second()

## Matching

The matching algorithm below makes use of the notion of replacing several
subexpressions of a larger expression at once.  The following function
accomplishes this.  It replaces every subexpression of the given expression
at any one of the given addresses with a copy of the replacement expression.

    exports.multiReplace =
    multiReplace = ( expression, addresses, replacement ) ->
        result = expression.copy()
        for address in addresses
            result.index( address )?.replaceWith replacement.copy()
        result

The matching algorithm implemented at the end of this file does not take
restrictions fo bound/free variables into account.  Clients who care about
that distinction should extract from the constraint set the bound/free
restrictions using the following function, then test to see if a solution
obeys them using the function after that.

This first function extracts from a pattern a list of metavariable pairs
(m1,m2).  Such a pair means the restriction that a solution s cannot have
s(m1) appearing free in s(m2).  Pairs are represented as instances of the
`Constraint` class, and lists of pairs as a `ConstraintList`.

    exports.bindingConstraints1 = bindingConstraints1 = ( pattern ) ->
        result = new ConstraintList()
        isBinder = ( d ) -> d.type is 'bi'
        for binding in pattern.descendantsSatisfying isBinder
            for m in binding.descendantsSatisfying isMetavariable
                if not m.isFree binding then continue
                for v in binding.variables
                    if not isMetavariable v then continue
                    newConstraint = new Constraint v, m
                    already = ( c ) -> c.equals newConstraint
                    if not result.firstSatisfying already
                        result.contents.push newConstraint
        result

This second function tests whether a given solution (expressed as a
`ConstraintList` instance) obeys a set of binding constraints (expressed as
another `ConstraintList` instance) computed by `bindingConstraints1`.  It
returns a boolean.

    exports.satisfiesBindingConstraints1 =
    satisfiesBindingConstraints1 = ( solution, constraints ) ->
        for constraint in constraints.contents
            sv = solution.lookup constraint.pattern
            sm = solution.lookup( constraint.expression ).copy()
            if sm.occursFree sv then return no
        yes

This third function extracts from a pattern a list of pairs (P,x) such that
the expression function application P(x) appeared in the pattern.  Such a
pair means the restriction that a solution s must have s(x) free to have
s(P) applied to it.  Pairs are represented as instances of the `Constraint`
class, and lists of pairs as a `ConstraintList`.

    exports.bindingConstraints2 = bindingConstraints2 = ( pattern ) ->
        result = new ConstraintList()
        for efa in pattern.descendantsSatisfying \
                isExpressionFunctionApplication
            if not isMetavariable efa.children[1] then continue
            newConstraint = new Constraint efa.children[1..2]...
            if not result.firstSatisfying( ( c ) -> c.equals newConstraint )
                result.contents.push newConstraint
        result

This fourth function tests whether a given solution (expressed as a
`ConstraintList` instance) obeys a set of binding constraints (expressed as
another `ConstraintList` instance) computed by `bindingConstraints2`.  It
returns a boolean.

    exports.satisfiesBindingConstraints2 =
    satisfiesBindingConstraints2 = ( solution, constraints ) ->
        for constraint in constraints.contents
            ef = solution.lookup constraint.pattern
            if not ef?
                matchDebug CLToString( solution ), CLToString( constraints )
            arg = solution.apply constraint.expression
            check = ( d ) -> d.equals ef.variables[0]
            for v in ef.body.descendantsSatisfying check
                if not arg.isFreeToReplace v, ef.body then return no
        yes

The following function, when iterated, will compute all valid solutions to
a given constraint set.  It returns pairs as length-two arrays.  A return
value of `[A,B]` is a solution `A` and the necessary data `B` to iterate the
call.  Specifically, `B` will be a triple suitable for passing as the three
arguments to another call to `nextMatch`, so that one could call
`nextMatch B...` for example.  When `B` is null, there are no more
solutions to be found.

Clients should not pass a value to the third parameter, which is for
internal use only, in recursion.  Clients may optionally pass a value for
the second parameter, as a solution to extend, but this is not the norm.

First, some debugging routines that are able to be turned on and off, for
development purposes.

    CToString = ( c ) ->
        "(#{c.pattern.simpleEncode()},#{c.expression.simpleEncode()})"
    CLToString = ( cl ) ->
        if cl is null then return null
        "{ #{( CToString(c) for c in cl.contents ).join ', '} }"
    CLSetToString = ( cls ) ->
        if cls is null then return null
        '[\n' + ( "\t#{CLToString(cl)}" for cl in cls ).join( '\n' ) + '\n]'
    matchDebugOn = no
    exports.setMatchDebug = ( onoff ) -> matchDebugOn = onoff
    matchDebug = ( args... ) -> if matchDebugOn then console.log args...

Now, the matching algorithm.

    exports.nextMatch =
    nextMatch = ( constraints,
                  solution = new ConstraintList(),
                  iterator = null ) ->

If this function was called with a single constraint in the first position,
rather than a list of them, then convert it to the correct type.

        if constraints instanceof Constraint
            constraints = new ConstraintList constraints
        if constraints not instanceof ConstraintList
            throw 'Invalid first parameter, not a constraint list'
        matchDebug '\nmatchDebug', CLToString( constraints ),
            CLToString( solution ),
            if iterator? then '  ...ITERATOR...' else ''

If we have not been given an iterator, then proceed with normal matching.
When we have an iterator, it means we must take a union over a series of
matching problems; we'll handle that case at the end of this function, far
below.

        if not iterator?

Base case:  If we have consumed all the constraints, then the solution we
have constructed is the only result.

            if constraints.length() is 0
                matchDebug '\tbase case, returning:', CLToString solution
                return [ solution, null ]

Atomic case:  If there is a constraint whose left hand side is atomic and
not a metavariable, then it must perfectly match the right hand side.

            constraint = constraints.firstSatisfying ( c ) ->
                c.pattern.children.length is 0 and \
                c.pattern.variables.length is 0 and \
                not isMetavariable c.pattern
            if constraint?
                return \
                if constraint.pattern.equals constraint.expression, no
                    matchDebug '\tatomic case, recur:', CToString constraint
                    nextMatch constraints.minus( constraint ), solution,
                        iterator
                else
                    matchDebug '\tatomic case, return null for',
                        CToString constraint
                    [ null, null ]

Non-atomic case:  If there is a constraint whose left hand side is
non-atomic and not an expression function application, then we try to break
it down into sub-constraints, as long as the right hand side admits a
corresponding decomposition.

            pseudoChildren = ( expr ) ->
                if expr.type is 'bi'
                    [ expr.symbol, expr.variables..., expr.body ]
                else
                    expr.children
            constraint = constraints.firstSatisfying ( c ) ->
                pseudoChildren( c.pattern ).length > 0 and \
                not isExpressionFunctionApplication c.pattern
            if constraint?
                LHS = constraint.pattern
                RHS = constraint.expression
                if LHS.type isnt RHS.type
                    matchDebug '\tnon-atomic case, type fail:',
                        CToString constraint
                    return [ null, null ]
                leftChildren = pseudoChildren LHS
                rightChildren = pseudoChildren RHS
                if leftChildren.length isnt rightChildren.length
                    matchDebug '\tnon-atomic case, #children fail:',
                        CToString constraint
                    return [ null, null ]
                constraints = constraints.minus( constraint ).plus \
                    ( new Constraint( child, rightChildren[index] ) \
                        for child, index in leftChildren )...
                matchDebug '\tnon-atomic case, recur:', CToString constraint
                return nextMatch constraints, solution, iterator

We do not implement the inconsistent case from the paper here, assuming that
it has been weeded out by the caller before this point, usually at the level
of rule validation, using the `consistentPatterns` function implemented
earlier in this file.

Metavariable case:  If there is a constraint whose left hand side is a
single metavariable, then we attempt to resolve it.  If that metavariable is
already set in the solution, then the constraint under consideration must
agree with it; this either results in continued processing or immediately
returning null, depending on that agreement check.  If the metavariable is
not already in the solution, then the constraint under consideration lets us
add it.

            constraint = constraints.firstSatisfying ( c ) ->
                isMetavariable c.pattern
            if constraint?
                if alreadySetTo = solution.lookup constraint.pattern
                    if not constraint.expression.equals alreadySetTo, no
                        matchDebug '\tmetavariable case, mismatch:',
                            CToString constraint
                        return [ null, null ]
                    else
                        matchDebug '\tmetavariable case, already set:',
                            CToString constraint
                else
                    matchDebug '\tmetavariable case, assigning:',
                        CToString constraint
                    solution = solution.plus constraint.copy()
                return nextMatch constraints.minus( constraint ),
                    solution, iterator

First of two expression function application cases:  If there are two
constraints whose left hand sides are both expression function applications,
and both use the same metavariable for the expression function, but the two
right hand sides are different, we can narrow down the meaning of the
metavariable, and in each of some number of cases, compute the meaning of
the arguments to the expression function applications.

            pair = constraints.firstPairSatisfying ( c1, c2 ) ->
                isExpressionFunctionApplication( c1.pattern ) and \
                isExpressionFunctionApplication( c2.pattern ) and \
                c1.pattern.children[1].equals(
                    c2.pattern.children[1], no ) and \
                not c1.expression.equals c2.expression, no
            if pair?
                [ c1, c2 ] = pair
                smallerC = constraints.minus c1, c2
                metavariable = c1.pattern.children[1]
                t1 = c1.pattern.children[2]
                t2 = c2.pattern.children[2]
                e1 = c1.expression
                e2 = c2.expression
                makeMValue = ( subset ) ->
                    v = constraints.nextNewVariable()
                    makeExpressionFunction v, multiReplace e1, subset, v
                iterator = differenceIterator e1, e2
                iterator = filterIterator iterator, ( subset ) ->
                    mValue = solution.lookup metavariable
                    not mValue? or alphaEquivalent mValue, makeMValue subset
                iterator = composeIterator iterator, ( subset ) ->
                    maybeExtended = if solution.lookup metavariable
                        solution.copy()
                    else
                        solution.plus new Constraint metavariable,
                            makeMValue subset
                    [ smallerC.plus(
                        new Constraint( t1, e1.index subset[0] ),
                        new Constraint( t2, e2.index subset[0] ) ),
                      maybeExtended, null ]
                matchDebug '\tefa case 1 of 2, iterating:',
                    CToString( c1 ), CToString( c2 )
                return nextMatch smallerC, solution, iterator

Second of two expression function application cases:  If there are two
constraints whose left hand sides are both expression function applications,
and both use the same metavariable for the expression function, and the two
right hand sides are equal, we can narrow down the meaning of the
metavariable, and in each of some number of cases, compute the meaning of
the arguments to the expression function applications.  (Note that because
the constraint set is indeed a set, in this situation we know that the two
parameters to the expression functions must be different.)

            pair = constraints.firstPairSatisfying ( c1, c2 ) ->
                isExpressionFunctionApplication( c1.pattern ) and \
                isExpressionFunctionApplication( c2.pattern ) and \
                c1.pattern.children[1].equals(
                    c2.pattern.children[1], no ) and \
                c1.expression.equals c2.expression, no
            if pair?
                [ c1, c2 ] = pair
                smallerC = constraints.minus c1, c2
                metavariable = c1.pattern.children[1]
                t1 = c1.pattern.children[2]
                t2 = c2.pattern.children[2]
                e = c1.expression
                makeMValue = ( subset ) ->
                    v = constraints.nextNewVariable()
                    makeExpressionFunction v, multiReplace e, subset, v
                iterator = subexpressionIterator e
                iterator = filterIterator iterator, ( subset ) ->
                    mValue = solution.lookup metavariable
                    not mValue? or alphaEquivalent mValue, makeMValue subset
                iterator = suffixIterator iterator, [ ]
                iterator = composeIterator iterator, ( subset ) ->
                    newMValue = makeMValue subset
                    if oldMValue = solution.lookup metavariable
                        if not alphaEquivalent oldMValue, newMValue
                            return null
                        maybeExtended = solution.copy()
                    else
                        maybeExtended = solution.plus \
                            new Constraint metavariable, newMValue
                    newConstraints = smallerC
                    if subset.length isnt 0
                        newConstraints = newConstraints.plus \
                            new Constraint( t1, e.index subset[0] ),
                            new Constraint( t2, e.index subset[0] )
                    [ newConstraints, maybeExtended, null ]
                matchDebug '\tefa case 2 of 2, iterating:',
                    CToString( c1 ), CToString( c2 )
                return nextMatch smallerC, solution, iterator

Only remaining case:  Take the first constraint, which we know must be an
expression function application whose expression function is a metavariable
that appears in no other constraint.  Create all possible instantiations for
that metavariable as follows.

            constraint = constraints.contents[0]
            if not isExpressionFunctionApplication constraint.pattern
                throw Error 'Invalid assumption in final case of matching'
            smallerC = constraints.minus constraint
            metavariable = constraint.pattern.children[1]
            t = constraint.pattern.children[2]
            e = constraint.expression
            if mValue = solution.lookup metavariable
                applied = applyExpressionFunction mValue, t
                matchDebug '\tfinal case, applying known metavariable:',
                    CToString constraint
                return nextMatch smallerC.plus( new Constraint mValue, e ),
                    solution, iterator
            makeMValue = ( subset ) ->
                v = constraints.nextNewVariable()
                makeExpressionFunction v, multiReplace e, subset, v
            iterator = subexpressionIterator e
            iterator = filterIterator iterator, ( subset ) ->
                mValue = solution.lookup metavariable
                not mValue? or alphaEquivalent mValue, makeMValue subset
            iterator = suffixIterator iterator, [ ]
            iterator = composeIterator iterator, ( subset ) ->
                matchDebug '\t\tnext subexpression, with subset',
                    JSON.stringify( subset ), 'solution',
                    CLToString( solution ), 'constraints',
                    CLToString( smallerC ), 't', t.simpleEncode(), 'e'
                    e.simpleEncode(), 'metavariable',
                    metavariable.simpleEncode()
                newMValue = makeMValue subset
                if oldMValue = solution.lookup metavariable
                    if not alphaEquivalent oldMValue, newMValue
                        return null
                    maybeExtended = solution.copy()
                else
                    maybeExtended = solution.plus \
                        new Constraint metavariable, newMValue
                newConstraints = smallerC
                if subset.length isnt 0
                    newConstraints = newConstraints.plus \
                        new Constraint t, e.index subset[0]
                [ newConstraints, maybeExtended, null ]
            matchDebug '\tfinal case, iterating:', CToString constraint
            return nextMatch smallerC, solution, iterator

Now handle the case where this call was given an iterator, so we are
essentially just executing a union operation over all calls of that
iterator.

        else
            next = iterator()
            if next is null
                matchDebug '\titerator case, next is null, done!'
                return [ null, null ]
            [ nextConstraints, nextSolution, nextIterator ] = next
            matchDebug '\titerator case, using iterator.next():',
                CLToString( nextConstraints ), CLToString( nextSolution ),
                nextIterator?, '\n--->'
            [ nextResult, nextArguments ] =
                nextMatch nextConstraints, nextSolution, nextIterator
            if not nextResult?
                matchDebug '\n<---\n' + \
                    '\tafter iterator recursion, no result;
                    keep iterating...'
                return nextMatch constraints, solution, iterator
            if not nextArguments?
                matchDebug '\n<---\n\tafter iterator recursion, ' + \
                    'got a unique solution:', CLToString nextResult
                return [ nextResult, [ constraints, solution, iterator ] ]
            matchDebug '\n<---\n\tafter iterator recursion, ' + \
                'got a(nother?) solution:', CLToString( nextResult ),
                'PLUS nextArguments', CLToString( nextArguments[0] ),
                CLToString( nextArguments[1] ), nextArguments[2]?
            nextArguments[2] = concatenateIterators \
                nextArguments[2], iterator
            return [ nextResult, nextArguments ]
