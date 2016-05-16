
# Unification Module

This file implements an algorithm for matching an expression to a pattern.
Pattern expressions are those containing *metavariables*, which means that
they can be matched against any subexpression.

For instance, the pattern `f(X)`, with `X` a metavariable, will match the
actual expressions `f(2)`, `f("hello")`, `f(x)`, `f(y)`, and
`f(and(k,g(2,k)))`.  In each case, the match is expressed by a mapping that
assigns to the name X a copy of the subexpression to which it corresponds.

However, `f(X)` would not match `g(x)`, because the `f` is not a
metavariable, and thus must match up with itself.  Similarly, it would not
match `f(2,3)`, for the structural difference in number of parameters.

The following lines ensure that this file works in Node.js, for testing.

    if not exports? then exports = module?.exports ? window
    if require? then { OM, OMNode } = require './openmath.duo'

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

## Match class

A match object represents the results of a successful unification operation,
and thus is a map from metavariable names to OpenMath expressions that can
be used to instantiate those metavariables.

    exports.Match = Match = class

### Unifier constructor

Constructing a new one simply initializes the map to an empty map

        constructor : -> @map = { }

### Metavariable mapping

We then provide functions for getting, setting, clearing, querying, and
using the map.  Parameters with the name "varOrSym" can either be strings
(the simple encoding notation of a variable or symbol, such as "f" or "a.b")
or actual OpenMath variable or symbol objects, in which case their simple
encodings will be computed and used instead of the objects themselves.
Parameters with the name "expr" can be any OpenMath expressions, and only
copies of them will be stored in this object when queried, the copies will
be returned.

The `set` function assigns an expression to a variable or symbol in the
mapping.  A copy of the given expression is stored.

        set : ( varOrSym, expr ) =>
            if varOrSym.simpleEncode?
                varOrSym = varOrSym.simpleEncode()
            @map[varOrSym] = expr.copy()

The `get` function queries the mapping for a variable or symbol, and returns
the same copy made at the time `set` was called (which is also still stored
internally in the map).

        get : ( varOrSym ) => @map[varOrSym.simpleEncode?() ? varOrSym]

The `clear` function removes a variable or symbol from the map (and whatever
expression it was paired with).

        clear : ( varOrSym ) =>
            varOrSym = varOrSym.simpleEncode?() ? varOrSym
            delete @map[varOrSym]

The `has` function just returns true or false value indicating whether the
variable or symbol appears in the map as a key.

        has : ( varOrSym ) =>
            @map.hasOwnProperty varOrSym.simpleEncode?() ? varOrSym

The `keys` function lists the names of all variables or symbols that appear
as keys in the mapping, in no particular order.  The results will be an
array of strings containing simple encodings of variables and symbols, such
as "x" and "y.z".

        keys : => Object.keys @map

The map can be applied to an expression, and all metavariables in it
(whether they are variables or symbols) will be replaced with a copy of
their values in the map.  Those metavariables that do not appear in the map
will be unaffected.  This is not performed in-place in the given pattern,
but rather in a copy, which is returned.

        applyTo : ( pattern ) =>
            result = pattern.copy()
            for metavariable in result.descendantsSatisfying isMetavariable
                if @has metavariable
                    metavariable.replaceWith @get( metavariable ).copy()
            result

### Functions and function applications

This module supports patterns that express the application of a function to
a parameter, where the function maps OpenMath expressions to OpenMath
expressions.  I will write `P[X]` to indicate the function expression `P`
applied to the expression `X`.  For example, the pattern `pair(P[1],P[2])`
would match the expression `pair(h(x,1,1),h(x,2,2))` with the metavariable
`P` instantiated as the function that maps its expression input `p` to the
output `h(x,p,p)`.

In this module, we will represent a function with the following binding head
symbol.

        @expressionFunction : OM.symbol 'EF', 'lurch'

We express the application of such a function to an argument as an
application of the following symbol.

        @expressionFunctionApplication : OM.symbol 'EFA', 'lurch'

So for example, `P[X]` would be expressed as `OM.simple
'lurch.expressionFunctionApplication(P,X)'` and the map from input `p` to
output `h(x,p,p)` as `OM.simple 'lurch.expressionFunction[p,h(x,p,p)]'`.

We therefore construct a few convenience functions for testing whether an
expression is of one of the types above, and for constructing expressions of
those types.

        @makeExpressionFunction : ( input, body ) =>
            if input.type isnt 'v' then throw 'When creating an expression
                function, its parameter must be a variable'
            OM.bin @expressionFunction, input, body
        @isExpressionFunction : ( expr ) =>
            expr.type is 'bi' and expr.variables.length is 1 and \
                expr.symbol.equals @expressionFunction
        @makeExpressionFunctionApplication : ( ef, arg ) =>
            OM.app @expressionFunctionApplication, ef, arg
        @isExpressionFunctionApplication : ( expr ) =>
            c = expr.children
            expr.type is 'a' and c.length is 3 and \
                c[0].equals @expressionFunctionApplication

### Copying match objects

It is straightforward to copy a match object; just copy the map within it, a
deep copy.

        copy : =>
            result = new Match
            for own key, value of @map
                result.map[key] = value.copy()
            result

### For debugging

It's often handy to be able to convert a Match object to a string for
debugging purposes.  This method creates a simple representation of a match
object.

        toString : =>
            result = '{'
            for own key, value of @map ? { }
                if result.length > 1 then result += ','
                result += "#{key}:#{value.simpleEncode()}"
            result + '}'

## Unification Algorithm

For both this algorithm and the next, it is handy to be able to create a new
variable that does not appear anywhere in a certain expression.  We thus
create the following convenience function for doing so.  You can pass any
number of expressions as parameters, and this will yield a new variable
that appears in none of them.

    newVariableNotIn = ( expressions... ) ->
        index = 0
        varname = -> OM.var "v#{index}"
        works = ->
            a = varname()
            isBad = ( node ) -> node.equals a, no
            for expression in expressions
                if expression.hasDescendantSatisfying isBad then return no
            yes
        while not works() then index++
        varname()

This routine is complex and occasionally needs careful debugging.  We do not
wish, however, to spam the console in production code.  So we define a
debugging routine here that can be enabled or disabled.

    exports.debugOn = no
    udebug = ( args... ) ->
        if exports.debugOn then console.log args...

The main purpose of this module is to expose this function to the client.
It unifies the given pattern with the given expression and returns a match
object, a mapping from metavariables to their instantiations.  To see many
examples of how this routine functions, see
[its unit tests](../test/unification-spec.litcoffee).  Clients should ignore
the third parameter; it is for internal use only.

    exports.unify = unify = ( pattern, expression, solution = new Match ) ->
        udebug '\nunify', pattern.simpleEncode(), expression.simpleEncode()

First, verify that the `expression` input is valid; it is not permitted to
contain metavariables.

        if expression.hasDescendantSatisfying isMetavariable
            throw 'Unifier rejects expressions containing metavariables'

Next, create a convenience function that can generate new variables whose
names do not appear in the pattern or the expression.

        newVariable = -> newVariableNotIn pattern, expression

Create a list of problems to solve, and initialize it with just the one
problem we've been given in the parameters, with a so-far-empty solution
that will grow (or be destroyed) as this routine does its work.

        problemsToSolve = [
            constraints : [ { pattern : pattern, expression : expression } ]
            solution : solution
        ]

The following loop goes forever, but various points in its code will break
out if we solve all the problems in `problemsToSolve`.

        loop

Find the first problem with constraints left for us to solve.

            i = 0
            while i < problemsToSolve.length and
                  problemsToSolve[i].constraints.length is 0
                i++
            udebug '\tloop', i, 'in', ( ''+( "(#{c.pattern?.simpleEncode()},#{c.expression?.simpleEncode()})" for c in P.constraints )+P.solution?.toString() for P in problemsToSolve ).join( ' ; ' )

If there wasn't one, then we've solved all the problems and can return their
solutions as our list of results.

            if i >= problemsToSolve.length
                udebug '\tabout to check constraints and return solutions'
                for p in problemsToSolve
                    udebug '\t\twould', pattern.simpleEncode(),
                        'and', p.solution?.toString(),
                        'violate capture constraints?',
                        ( if p.solution then violatesCaptureConstraints( \
                            pattern, p.solution ) else 'N/A' )
                return ( p.solution for p in problemsToSolve \
                         when p.solution isnt null and not \
                         violatesCaptureConstraints pattern, p.solution )

Otherwise, we have a problem with at least one constraint left to work on.
Call that problem it `Q`, and call its first pattern `P`, its first
expression `E`, and it solution (so far) `S`.

            Q = problemsToSolve[i]
            first = Q.constraints.shift()
            P = first.pattern
            E = first.expression
            S = Q.solution

We will sometimes want to add new constraints to `Q`, but it is important
not to add duplicate constraints.  Thus we create the following function for
pushing or unshifting a constraint iff the constraint isn't already present.

            addConstraint = ( pushOrUnshift, pat, exp ) ->
                if pushOrUnshift not in [ 'push', 'unshift' ] then return
                for constraint in Q.constraints
                    if constraint.pattern.equals( pat ) and \
                       constraint.expression.equals exp then return
                Q.constraints[pushOrUnshift]
                    pattern : pat
                    expression : exp

If `P` is atomic and not a metavariable, we do a simple equality comparison.
If it succeeds, we leave the existing solution intact.  Otherwise, mark the
problem as hopeless and finished.

            if P.type not in [ 'a', 'bi', 'e' ] and not isMetavariable P
                if not P.equals E, no
                    Q.constraints = [ ]
                    Q.solution = null
                continue

If `P` is a metavariable in `S`, then add back onto the constraints list the
pair `S[P]` and `E`.

            if isMetavariable P
                if S.has P
                    addConstraint 'push', S.get( P ), E

If `P` is a metavariable not in `S`, then assign `E` to `P` in `S`.

                else
                    S.set P, E
                continue

We now know that `P` is compound, not atomic.

If `P` is not a substitution form, then it must match `E` in type and we
must unify each of its children against those of `E`.  We must therefore
first check to see if they have the same number of children.  If not, this
problem fails to unify.  If so, add the child constraints to the constraints
list.

            if P.type is 'bi'
                pc = [ P.symbol, P.variables..., P.body ]
                ec = [ E.symbol, E.variables..., E.body ]
            else
                pc = P.children
                ec = E.children
            if not Match.isExpressionFunctionApplication P
                if P.type isnt E.type or pc.length isnt ec.length
                    Q.constraints = [ ]
                    Q.solution = null
                else
                    for index in [pc.length-1..0]
                        addConstraint 'unshift', pc[index], ec[index]
                continue

We now know that `P` is a substitution form, so extract its contents.  Say
it is of the form `F(v)`, so we use those names below.

            F = pc[1]
            v = pc[2]

If `F` is not a metavariable, throw an exception, because we do not support
that.

            if not isMetavariable F then throw 'First argument to an
                expression function must be a metavariable'

If there are any non-substitution forms in the constraint list, let's handle
those first, to have as much information in `S` as possible when addressing
substitution forms.  So we handle the current constraint later; right now we
just push it to the end of the constraints list.

            nonSubstForms = ( c for c in Q.constraints \
                when not Match.isExpressionFunctionApplication c.pattern )
            if nonSubstForms.length > 0
                udebug '\t\tdelaying substitution forms...'
                addConstraint 'push', P, E
                continue

If `F` is in `S`, apply `F` to `v` and push the result back onto the
constraints list, to be matched against the same expression.

            if S.has F
                udebug '\t\tthe ef is in the solution set'
                body = S.get( F ).body.copy()
                body.replaceFree S.get( F ).variables[0], v
                addConstraint 'unshift', body, E
                continue

If any constraint on the list contains `v` but not `F`, throw an exception
because we can't handle that type of complexity.

            for constraint in Q.constraints
                isV = ( node ) -> node.equals v
                isF = ( node ) -> node.equals F
                if constraint.pattern.hasDescendantSatisfying( isV ) and \
                   not constraint.pattern.hasDescendantSatisfying( isF )
                    throw 'Parameter of one function application appears in
                        another function application; this level of
                        complexity is not supported by this unification
                        algorithm.'

If no other constraint on the list has `F` applied to something as its
pattern, then we have a lot of freedom.

            anotherStartingWithF = -1
            for constraint, index in Q.constraints
                if Match.isExpressionFunctionApplication( \
                        constraint.pattern ) \
                   and constraint.pattern.children[1].equals F
                    anotherStartingWithF = index
                    break
            if anotherStartingWithF is -1

There are two subcases to consider, if `v` is in `S` and if it is not.
Consider first the case where `v` is not in `S`.  In that case there are an
enormous number of options.  Rather than attempt to create them all and
yield a huge explosion in the problem, we create a new variable and assign
`lambda(newvar,newvar)` to `F` in `S`. Then assign `E` to `v` in `S`.  This
is one of the two potential weaknesses of this algorithm; the other is a
similar situation that shows up in `merge()`, below.

                N = newVariable()
                if not S.has v
                    S.set F, Match.makeExpressionFunction N, N
                    S.set v, E
                    udebug '\t\t1 constraint w/this func, v known'

The other subcase is when `v` is in `S`.  In that case, we must find all
occurrences of `S[v]` in `E` and consider all the possible `F`s we might
create (exponential in the number of occurrences) and construct all of them.

                else
                    value = S.get v
                    udebug '\t\texponential explosion w/v',
                        value.simpleEncode(), 'and E', E.simpleEncode()
                    newsolutions = allBinaryFunctions E, value, N, S, F
                    problemsToSolve.splice i, 1,
                        ( { constraints : Q.constraints[..], \
                            solution : s } for s in newsolutions )...
                continue

Since some other constraint on the list has `F` applied to something as its
pattern, we have less freedom.  Remove the first such constraint and call it
`(F(v'),E')`.  Replace `Q` in the problems list with the result of calling
the merge algorithm below on `(F,E,E',v,v',S)`.

            vprime = Q.constraints[anotherStartingWithF].pattern.children[2]
            Eprime = Q.constraints[anotherStartingWithF].expression
            Q.constraints.splice anotherStartingWithF, 1
            mergeResults = merge F, E, Eprime, v, vprime, S
            problemsToSolve.splice i, 1,
                ( { constraints : Q.constraints[..], \
                    solution : MR.copy() } for MR in mergeResults )...
            udebug '\t\tmerging with index', anotherStartingWithF

## Merge Algorithm

This algorithm attempts to determine what function `F` satisfies the
constraint that `F(v)` unifies with `E` while `F(v')` unifies with `E'`, in
the context of the solution object `S`.  `F` must be a metavariable that
will be added to solution object `S`, and `F` must not already be in `S`.
The expressions `v` and `v'` may be metavariables or other types of
expressions, including compound expressions with metavariables inside; in
any of those cases, the metavariable(s) in `v` and `v'` may or may not
appear in `S`.

    merge = ( F, E, Eprime, v, vprime, S ) ->
        udebug '\nmerge F:', F.simpleEncode(), ', E:', E.simpleEncode(),
            ', E\':', Eprime.simpleEncode(), ', v:', v.simpleEncode(),
            ', v\':', vprime.simpleEncode(), ', S:', S.toString()

First, create a convenience function that can generate a new variable not in
any of the expressions passed to this function.

        newVariable = -> newVariableNotIn F, E, Eprime, v, vprime

If `E` or `E'` contains a metavariable or a substitution expression, throw
an exception because we do not support that.

        if E.hasDescendantSatisfying( \
           Match.isExpressionFunctionApplication ) or \
           Eprime.hasDescendantSatisfying( \
           Match.isExpressionFunctionApplication )
            throw 'The merge algorithm does not support expressions
                containing applications of expression functions.'

Compute the set of addresses at which `E` and `E'` differ.  Initialize the
set of addresses to the empty list, then create and run a recursive function
to fill that list.

        differences = [ ]
        findDifferencesBetween = ( A, B ) ->
            udebug '\t\t\tdiff', A.simpleEncode(), A.address( E ),
                B.simpleEncode(), B.address( Eprime )
            if A.type isnt B.type
                udebug '\t\t\ttypes diff;', A.address E
                differences.push A.address E
                return
            if A.type is 'bi'
                Ac = [ A.symbol, A.variables..., A.body ]
                Bc = [ B.symbol, B.variables..., B.body ]
            else
                Ac = A.children
                Bc = B.children
            udebug '\t\t\tchildren:',
                ( c.simpleEncode() for c in Ac ).join( ',' ), ';',
                ( c.simpleEncode() for c in Bc ).join( ',' )
            if Ac.length isnt Bc.length or \
               ( Ac.length + Bc.length is 0 and not A.equals B, no )
                udebug '\t\t\tnon-recursive difference;', A.address E
                differences.push A.address E
            else
                for child, index in Ac
                    findDifferencesBetween child, Bc[index]
        findDifferencesBetween E, Eprime

If there were no differences, there are many possibilities.

        if differences.length is 0
            udebug '\tno differences!'

First, if `v` and `v'` are both known (either non-metavariables, or
metavariables with instantiations specified already in `S`) then we consider
two cases.

            known = ( x ) -> not isMetavariable( x ) or S.has x
            value = ( x ) -> if not isMetavariable x then x else S.get x
            udebug '\t\tv known?', known( v ), 'value',
                value( v )?.simpleEncode(), 'v\' known?', known( vprime ),
                'value', value( vprime )?.simpleEncode()
            N = newVariable()
            return if known( v ) and known vprime

If the values of `v` and `v'` are different, then the only
possibility is to have `F` be a constant function.

                if not value( v ).equals value vprime
                    S.set F, Match.makeExpressionFunction N, E
                    [ S ]

Otherwise, there are many possibilities, and we return them all.

                else
                    allBinaryFunctions E, value( v ), N, S, F

Second, if `v` has a value but `v'` is an uninstantiated metavariable, then
we consider the case where `v'` is unconstrainted and `F` is a constant
function, together with the case where `F` is any other of the many
functions that would yield `E` when applied to `v`, and `v'` equal to `v`.

            else if known v
                newsols = allBinaryFunctions E, value( v ), N, S, F
                sol.set vprime, value v for sol in newsols[1..]
                udebug '\t\tknown/unknown result:',
                    ( s.toString() for s in newsols ).join ' ; '
                newsols

Third is the symmetrical case with `v` and `v'` reversed.

            else if known vprime
                newsols = allBinaryFunctions E, value( vprime ), N, S, F
                sol.set v, value vprime for sol in newsols[1..]
                udebug '\t\tunknown/known result:',
                    ( s.toString() for s in newsols ).join ' ; '
                newsols

Finally, if neither `v` nor `v'` is known, there are a huge number of
possibilities.  One could write an algorithm that considers all the
subexpressions of `E` as possible values for `v` or `v'` and runs the
`allBinaryFunctions()` procedure in each case, but the number of solutions
would explode.  To avoid this, we simply return the single simplest
solution, although I honestly don't know if that could every cause problems,
because it's not perfectly general.  I suspect one could cook up a rare
example that causes some complex form to fail to unify when it ought to
unify.  I should come back to this eventually.

            else
                S.set F, Match.makeExpressionFunction N, E
                [ S ]

Initialize the solution set to the empty list, then proceed with a loop
that considers first the differences just computed, then their parents, then
grandparents, and so on until we hit the top level.

        solutions = [ ]
        loop
            udebug '\tdifferences: [',
                ( "[#{d}]" for d in differences ).join( ' ; ' ), ']'
            udebug '\t\trecursively calling unify...'

Create a function `F` that replaces all the differences with its parameter,
and attempt to simultaneously unify `F(v)` with `E` and `F(v')` with `E'`
(by creating pairs).  If this works, add it to the solution set.  If not,
don't.

            parameter = newVariable()
            body = E.copy()
            for address in differences
                body.index( address ).replaceWith parameter.copy()
            func = Match.makeExpressionFunction parameter, body
            Fofv = body.copy()
            Fofv.replaceFree parameter, v
            Fofvprime = body.copy()
            Fofvprime.replaceFree parameter, vprime
            lhs = OM.app Fofv, Fofvprime
            rhs = OM.app E, Eprime
            udebug '\t\t\tfunc', func.simpleEncode()
            udebug '\t\t\tF(v)', Fofv.simpleEncode(), 'F(v\')',
                Fofvprime.simpleEncode()
            udebug '\t\t\tE', E.simpleEncode(), 'E\'', Eprime.simpleEncode()
            for solution in unify lhs, rhs, S.copy()
                solution.set F, func
                solutions.push solution
            udebug '\t\tafter recursion, extended solutions:'
            udebug '\t\t', ( s.toString() for s in solutions ).join ' ; '

Attempt to move upwards, from each of the differences addresses, to the next
ancestor upwards.  If this cannot be done for any of them (because it is
length zero) then terminate the loop.  Also, ensure there are no duplicates
in the list (since trimming the last entry of an address is not injective).

            newDifferences = [ ]
            newDifferencesAsStrings = [ ]
            terminateTheLoop = no
            for difference in differences
                if difference.length is 0
                    terminateTheLoop = yes
                    break
                shorter = difference[0...-1]
                asString = "#{shorter}"
                if asString not in newDifferencesAsStrings
                    newDifferences.push shorter
                    newDifferencesAsStrings.push asString
            if terminateTheLoop then break
            differences = newDifferences

Return the solution set computed in the above loop.

        udebug '\tfinishing merge with these solutions:'
        udebug '\t\t', ( s.toString() for s in solutions ).join ' ; '
        solutions

## Checking whether a solution violates variable capture constraints

A solution is not valid if, when its map is substituted back into the
pattern, variable capture constraints are violated.  Those constraints are,
specifically, these.
 * When substituting a metavariable's value for the variable itself, if any
   free variable in the value becomes bound by the substitution, variable
   capture constraints have been violated.
 * Substitution takes place from the top down, so that bound metavariables
   have been filled in before the body of the binder is processed.  Capture
   violations occur only in the bodies of binding expressions, not in the
   variables that precede the body.
 * When processing the application of an expression function, we do not
   process the parameter.  Expression function applications are understood
   to be permission, given by the creator of the pattern, to substitute
   *any* value, even if capture would occur.  This is consistent with how
   that notation is used in the typical rules of first-order logic, for
   example.

The following routine determines whether a solution violates variable
capture constraints.  The parameters are the pattern that was used in the
match, together with the solution to be tested.  The third parameter is used
only in recursive calls; do not pass it a value.

    violatesCaptureConstraints = ( pattern, solution, boundVars = [ ] ) ->
        # udebug '\t\t', pattern.simpleEncode(), boundVars
        if isMetavariable pattern
            for freeVarName in solution.get( pattern ).freeVariables()
                if freeVarName in boundVars then return yes
            no
        else if pattern.type is 'bi'
            moreBoundVars = for variable in pattern.variables
                if isMetavariable variable
                    solution.get( variable ).name
                else
                    variable.name
            violatesCaptureConstraints pattern.body, solution,
                boundVars.concat moreBoundVars
        else if Match.isExpressionFunctionApplication pattern
            violatesCaptureConstraints pattern.children[1], solution,
                boundVars
        else
            for child in pattern.children
                if violatesCaptureConstraints child, solution, boundVars
                    return yes
            no

The following routine returns the $2^n$ expressions generated by replacing
all possible subsets of the $n$ occurrences of the given subexpression in
the given expression with the given variable.  It assumes the
replacement is not equal to the subexpression.  The results are then
converted into expression functions parameterized by the variable, and used
to extend the solution set `S` into an array of solution sets, which is
returned.  The solution sets are extended at the entry named `E`.

    allBinaryFunctions = ( expr, subexpr, variable, S, E ) ->
        addresses = ( subexpression.address expr for subexpression in \
            expr.descendantsSatisfying ( node ) -> node.equals subexpr )
        if addresses.length > 4
            throw 'Problem size growing too large for the unification
                algorithm'
        for bits in [0...1<<addresses.length]
            body = expr.copy()
            newsol = S.copy()
            for i in [0...addresses.length]
                if bits & (1<<i)
                    body.index( addresses[i] ).replaceWith variable.copy()
            newsol.set E, Match.makeExpressionFunction variable, body
            newsol
