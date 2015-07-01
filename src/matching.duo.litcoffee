
# Matching Module

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
of a string that signifies a boolean true value.

    metavariableSymbol = OM.symbol 'metavariable', 'lurch'
    trueValue = OM.string 'true'

We begin with a routine that marks a variable as a metavariable.  It accepts
as parameter any `OMNode` instance (as implemented
[here](openmath.duo.litcoffee)) and gives it an attribute that the rest of
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

A match object represents the results of a successful matching operation,
and thus is a map from metavariable names to OpenMath expressions that can
be used to instantiate those metavariables.

    exports.Match = Match = class

### Match constructor

Constructing a new one simply initializes the map to an empty map and
"visited" list.  The map is discussed in the following section, and the
visited list is discussed [further below](#visiting).

        constructor : ->
            @map = { }
            @visited = [ ]

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

It then updates the "unavailable" list for the substitution, which will make
sense after reading [the substitutions section below](#substitutions).

            if @substitution?
                @substitution.unavailable =
                    ( vname for vname in @substitution.unavailable \
                      when vname isnt varOrSym )

The `get` function queries the mapping for a variable or symbol, and returns
the same copy made at the time `set` was called (which is also still stored
internally in the map).

        get : ( varOrSym ) => @map[varOrSym.simpleEncode?() ? varOrSym]

The `clear` function removes a variable or symbol from the map (and whatever
expression it was paired with).

        clear : ( varOrSym ) =>
            varOrSym = varOrSym.simpleEncode?() ? varOrSym
            delete @map[varOrSym]

Like `set`, this function, too, updates the "unavaiable" list in the
substitution.  To understand this, refer to [the substitutions section
below](#substitutions).

            if varOrSym in ( @substitution?.metavariables ? [ ] )
                if varOrSym not in @substitution.unavailable
                    @substitution.unavailable.push varOrSym

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

### Substitutions

This module supports patterns that express optional or required
substitutions.  The informal notation `A[x=y]` means "the expression `A`
with every free occurrence of the subexpression `x` replaced by the
subexpression `y`, when `y` is free to replace `x`."  The informal notation
`A[x~y]` is the same idea, but with "every occurrence" replaced by "zero or
more occurrences."  Thus `A[x=y]` is a computation that can be done, but
`A[x~y]` is a criterion that can be matched against.

We call the first of these two a "required substitution" and the second an
"optional substitution."  In this module, we will represent them as
applications of the following two head symbols.

        @requiredSubstitution : OM.symbol 'replaceAll', 'lurch'
        @optionalSubstitution : OM.symbol 'replaceSome', 'lurch'

So for example, `A[x=y]` could be expressed as
`OM.simple 'lurch.replaceAll(A,x,y)'`.

[The matching algorithm defined below](#matching-algorithm) must track where
a substitution expression appears in the pattern, and what its parts are.
Thus this class provides methods for storing and querying the substitution
that is in effect, if any, what type it is, and what its arguments are.  The
matching algorithm can then track substitution data using Match objects.

First, a method for storing a substitution.  In `A[x=y]`, `x` is called the
left hand side, `y` is called the right hand side.  When calling the
following function to store that substitution pattern, you pass the entire
expression and its two sides and its type (required, =, or optional, ~) are
extracted and stored, not as copies but as the originals.

        setSubstitution : ( substitution ) =>
            @substitution =
                original : substitution
                required : substitution.children[0].equals \
                    Match.requiredSubstitution
                root : substitution.children[1]
                leftHandSide : substitution.children[2]
                rightHandSide : substitution.children[3]
                metavariables : [ ]

This function also computes the list of metavariable names that appear in
either side of the substitution, and then computes the subset of those names
that do not yet appear as keys in the mapping.  This will help us know when
the substitution has been fully determined (as this object's mapping grows).

            leftMetavariables =
                @substitution.leftHandSide.descendantsSatisfying \
                    isMetavariable
            for v in leftMetavariables
                if v.name not in @substitution.metavariables
                    @substitution.metavariables.push v.name
            rightMetavariables =
                @substitution.rightHandSide.descendantsSatisfying \
                    isMetavariable
            for v in rightMetavariables
                if v.name not in @substitution.metavariables
                    @substitution.metavariables.push v.name
            @substitution.unavailable =
                ( vname for vname in @substitution.metavariables \
                  when not @map.hasOwnProperty vname )

We also provide a reverse method, for removing a stored substitution.

        clearSubstitution : => delete @substitution

We also provide a method for reconstructing a copy of the original
substitution expression based on the data about it stored herein.  This is
like an inverse to `setSubstitution()`.

        saveSubstitution : =>
            head = if @getSubstitutionRequired()
                Match.requiredSubstitution
            else
                Match.optionalSubstitution
            OM.application head, @getSubstitutionRoot(),
                @getSubstitutionLeft(), @getSubstitutionRight()

To go with the above function for registering a substitution pattern, we
also provide several methods for querying the substitution data stored.
Remember that the original values are returned, so do not modify them unless
that is your intent.

        hasSubstitution : => @substitution?
        getSubstitutionRequired : => @substitution?.required
        getSubstitutionRoot : => @substitution?.root
        getSubstitutionLeft : => @substitution?.leftHandSide
        getSubstitutionRight : => @substitution?.rightHandSide
        getSubstitutionNode : => @substitution?.original

### Completing a match

When the [the matching algorithm](#matching-algorithm) has been run, but not
all metavariables were forced into a particular instantiation, we will still
want to return a match object that has values for *all* metavariables.  We
therefore provide a function that finds all metavariables in the pattern,
and for those that do not yet have an assignment, it creates a new
assignment to a variable unused in the pattern, the expression, and any of
the existing instantiations.

In order to do so, we must know what the outermost pattern and expression
are. We therefore begin by defining a simple function for storing the
topmost pattern and expression, that is, those that were passed to the
outermost call to `matches`.  That outermost execution of the `matches`
function is responsible for calling this function to store those two values.
They are necessary for the purpose just described.

        storeTopmostPair : ( pattern, expression ) =>
            @pattern = pattern
            @expression = expression

And now the function that completes a match object by instantiating all
metavariables in the pattern.  We instantiate them with new variables of
the form "unused_N" for various positive integers N, starting with the
smallest N for which no instance of "unused_N" appears in the pattern,
expression, or current match data.

This function modifies this match object in-place.

        complete : =>

We need the pattern and expression, so give up if they're not here.

            return unless @pattern? and @expression?

We will create variables of the form "unused_N" for various positive
integers N.  We must find a complete list of such variables already in use
(unlikely as that may be).  We search in the pattern, the expression, and
all existing instantiations in `@map`.

            unusedRE = /^unused_([0-9]+)$/
            unusedCheck = ( node ) ->
                node.type is 'v' and unusedRE.test node.name
            unused = @pattern.descendantsSatisfying unusedCheck
                .concat @expression.descendantsSatisfying unusedCheck
            for own key, value of @map
                unused =
                    unused.concat value.descendantsSatisfying unusedCheck

We then begin counting after the largest of them.  E.g., if it was unused_7,
we start using unused_8, unused_9, etc.

            integers = [ 0 ] # ensure there is one
            for variable in unused
                match = unusedRE.exec variable.name
                integers.push parseInt match[1]
            integers = integers.sort ( a, b ) -> a - b
            last = integers[integers.length-1]

Find all uninstantiated metavariables in the pattern, and give them values
from the unused list, as just described.

            metavariables = @pattern.descendantsSatisfying isMetavariable
            for metavariable in metavariables
                if not @has metavariable
                    @set metavariable, OM.variable "unused_#{++last}"

### Copying match objects

It is straightforward to copy a match object; just copy all of its members.
But it matters which ones are deeply copied and which ones are not.  Here
are the details.
 * The values in the map are copies of those in the original map.
 * The values in the visited list are equal to those in the original map,
   but the array itself is a copy.
 * The result's substitution is a shallow copy of this object's
   substitution; only the variable arrays are copied deeply.
 * The pattern and expression are not deeply copied; the same objects are
   shared with the result of this function.

        copy : =>
            result = new Match
            for own key, value of @map
                result.map[key] = value.copy()
            result.visited = @visited[..]
            if @substitution?
                result.substitution =
                    original : @substitution.original
                    root : @substitution.root
                    leftHandSide : @substitution.leftHandSide
                    rightHandSide : @substitution.rightHandSide
                    required : @substitution.required
                    metavariables : @substitution.metavariables[..]
                    unavailable : @substitution.unavailable[..]
            if @pattern? then result.pattern = @pattern
            if @expression? then result.expression = @expression
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
            result += '}'
            if @hasSubstitution()
                result += '[' + @getSubstitutionLeft().simpleEncode() + \
                    ( if @getSubstitutionRequired() then '=' else '~' ) + \
                    @getSubstitutionRight().simpleEncode() + ' in ' + \
                    @getSubstitutionRoot().simpleEncode() + ']'
            result

## Matching Algorithm

This routine is complex and occasionally needs careful debugging.  We do not
wish, however, to spam the console in production code.  So we define a
debugging routine here that can be enabled or disabled.

    matchDebuggingEnabled = no
    mdebug = ( args... ) ->
        if matchDebuggingEnabled then console.log args...

The main purpose of this module is to expose this function to the client. It
matches the given pattern against the given expression and returns a match
object, a mapping from metavariables to their instantiations.  The third and
fourth parameters are for internal use during recursion, and should not be
passed by clients.  To see many examples of how this routine functions, see
[its unit tests](../test/matching-spec.litcoffee#matching).

    exports.matches = matches = ( pattern, expression, soFar ) ->

Determine whether we're the outermost call in the recursion, for use below.

        outermost = not soFar?
        soFar ?= new Match
        mdebug "#{if outermost then '\n' else ''}MATCHES:",
            pattern?.simpleEncode?() ? pattern,
            expression?.simpleEncode?() ? expression,
            "#{soFar}"

If this is the outermost call, then apply all substitutions in the
expression.  (The expression must contain only required substitutions, not
optional ones.)

        if outermost
            soFar.storeTopmostPair pattern, expression
            substitutions = expression.descendantsSatisfying ( x ) ->
                x.type is 'a' and x.children.length is 4 and \
                    x.children[0].equals Match.requiredSubstitution
            for substitution in substitutions
                left = substitution.children[2]
                right = substitution.children[3]
                substitution.replaceWith substitution.children[1]
                substitution.replaceFree left, right

We build one final preparatory function before diving into the actual
algorithm.  This function should be returned when the match would fail
without the aid of any substitution that may be in effect.  This function
checks to see if the current substitution in effect (if any) can make the
match pass; if so, it returns the array of match objects corresopnding to
the successful matches.  If not, it returns the empty array.

At many points in the algorithm below, rather than returning an empty array
to indicate a failed match, we return `trySubs()`, because it gives any
substitution currently in effect a chance to save the day.

        trySubs = ->
            if not soFar.hasSubstitution() then return [ ]
            mdebug '    match of', pattern.simpleEncode(), 'to',
                expression.simpleEncode(), 'failed; trying subs...',
                soFar.toString()
            save = soFar.saveSubstitution()
            pair = OM.application
            sub = pair soFar.getSubstitutionLeft(),
                soFar.getSubstitutionRight()
            root = soFar.getSubstitutionRoot()
            rhs = soFar.getSubstitutionRight()
            soFar.clearSubstitution()
            [ walk1, walk2, results ] = [ pattern, expression, [ ] ]
            while walk1? and walk2?
                mdebug '    attempting subs at this level:',
                    sub.simpleEncode(),
                    OM.application( walk1, walk2 ).simpleEncode(),
                    "#{soFar}..."
                for match in matches sub, pair( walk1, walk2 ), soFar, no
                    mdebug '        checking this:', "#{match}"
                    lhsLocation = walk1.address root
                    instantiated = match.applyTo root
                    lhsInThere = instantiated.index lhsLocation
                    fullRHS = match.applyTo rhs
                    mdebug "        is #{fullRHS?.simpleEncode?()}
                        free to replace #{lhsInThere?.simpleEncode?()} in
                        #{instantiated?.simpleEncode?()}?
                        #{fullRHS.isFreeToReplace lhsInThere, instantiated}"
                    if fullRHS.isFreeToReplace lhsInThere, instantiated
                        results.push match
                if walk1.sameObjectAs root then break
                [ walk1, walk2 ] = [ walk1.parent, walk2.parent ]
            result.setSubstitution save for result in results
            mdebug '    done attempting all subs; results:',
                ( "#{result}" for result in results )
            results

Now the preparatory phase of the routine is complete, and we begin some of
the cases of the actual matching algorithm.

If the patterns of the form `x[y=z]` or `x[y~z]`, proceed as follows, first
detect which of the two it is.  Then ensure that this is the first
substitution encountered in the pattern (since only one is permitted).  Then
pop off its left and right hand sides, store them in the match object, and
recur.  There is no need to filter the results after the recursion, because
filtering only matters inside a substitution, and we are currently just
outside of one.

        if pattern.type is 'a' and pattern.children.length is 4 and \
            ( pattern.children[0].equals( Match.requiredSubstitution ) or \
              pattern.children[0].equals( Match.optionalSubstitution ) )
            mdebug '    pattern is a substitution...'
            if soFar.hasSubstitution()
                throw 'Only one substitution permitted in a pattern'
            soFar.setSubstitution pattern
            rhs = soFar.getSubstitutionRight()
            results = matches pattern.children[1], expression, soFar
            newResults = [ ]
            for result in results
                mdebug '    checking substitution match', "#{result}"

Optional substitutions always pass this check.

                if pattern.children[0].equals Match.optionalSubstitution
                    mdebug '        optional, so we approve it'
                    result.clearSubstitution()
                    newResults.push result
                    continue

Substitutions with not-yet-instantiated metavariables in their left hand
sides pass the check, because they will have no impact on the final result;
those metavariables will be instantiated into unused identifiers.

                lhs = result.getSubstitutionLeft()
                existUnusedMetavars = lhs.hasDescendantSatisfying ( d ) ->
                    isMetavariable( d ) and not result.has d
                if existUnusedMetavars
                    mdebug '        approved because of unused metavars'
                    result.clearSubstitution()
                    newResults.push result
                    continue

Compute the list of descendants of the instantiated pattern that equal the
left hand side, have no metavariables in them and are free in the
instantiated pattern.

                root = soFar.getSubstitutionRoot()
                rinstantiated = result.applyTo root
                lhs = result.applyTo lhs
                descs = rinstantiated.descendantsSatisfying ( d ) ->
                    d.equals( lhs ) and \
                    not d.hasDescendantSatisfying( isMetavariable ) \
                    and d.isFree rinstantiated
                mdebug '        instantiated root:',
                    rinstantiated.simpleEncode()
                mdebug '        instances of lhs:',
                    ( d.address pattern for d in descs )

Compute the list of subexpressions at the corresponding locations within
`expression`.

                einstantiated = result.applyTo expression
                mdebug '        instantiated expression:',
                    einstantiated.simpleEncode()
                exprs = for d in descs
                    einstantiated.index d.address rinstantiated
                mdebug '        corresponding expression subtrees:',
                    ( e.simpleEncode() for e in exprs )

Recur matching `exprs` as a tuple against a tuple of the same size
containing repeated copies of the instantiated RHS of the substitution.

                tuple = ( args... ) ->
                    OM.application OM.string( "tuple" ), args...
                fullRHS = result.applyTo rhs
                many = ( fullRHS for e in exprs )
                mdebug '        will now recur on these tuples:'
                mdebug "        #{tuple( many... ).simpleEncode()}"
                mdebug "        #{tuple( exprs... ).simpleEncode()}"
                result.clearSubstitution()
                recur = matches tuple( many... ), tuple( exprs... ),
                    result
                mdebug '        recursion on tuples complete; testing...'

With each match object in the result of that recursion, proceed as follows.

                for recurResult in recur

Re-instantiate `rhs` with the (now expanded) match result.  If it's free to
replace every one of the `exprs`, then push this match object onto the list
of new results.

                    mdebug '        testing:', "#{recurResult}"
                    newRHS = recurResult.applyTo rhs
                    freeToReplace = yes
                    for expr in exprs
                        if not newRHS.isFreeToReplace expr, expression
                            freeToReplace = no
                            break
                    if freeToReplace
                        mdebug '        approved after extending:',
                            "#{recurResult}"
                        newResults.push recurResult
                    else
                        mdebug '        rejected after extending:',
                            "#{recurResult}"
            results = newResults
            if outermost then result.complete() for result in results
            mdebug '    results have been completed:',
                ( "#{r}" for r in results )
            mdebug '<--', ( "#{r}" for r in newResults )
            return newResults

If the pattern is a single metavariables, then there are two cases.  If it
has an instantiation, then we must use that instantiation and either return
the current match object or failure.  But if it has no instantiation, we can
store the current expression as its instantiation, to permit the matching
process to continue.

        if isMetavariable pattern
            mdebug '    pattern is a metavariable'
            if test = soFar.get pattern
                mdebug '    we use its already-determined value:'
                result = matches test, expression, soFar
                mdebug '<--', ( "#{r}" for r in result )
                return result
            soFar.set pattern, expression
            mdebug '    stored new assignment', pattern.simpleEncode(),
                '=', expression.simpleEncode(), 'yielding', "#{soFar}"
            results = [ soFar ]
            if outermost then result.complete() for result in results
            mdebug '    results have been completed:',
                ( "#{r}" for r in results )
            mdebug '<--', ( "#{r}" for r in results )
            return results

If the types of the pattern and expression don't match, then the only thing
that might save us is a substitution, if there is one.

        mdebug '    comparing types...', pattern.type, expression.type
        if pattern.type isnt expression.type
            result = trySubs()
            mdebug '<--', ( "#{r}" for r in result )
            return result

If the pattern is atomic, then it must flat-out equal the expression.  If
this is not the case, we can only fall back on a possible substitution.

        if pattern.type in [ 'i', 'f', 'st', 'ba', 'sy', 'v' ]
            if pattern.equals expression, no
                results = [ soFar ]
                if outermost then result.complete() for result in results
                mdebug '    results have been completed:',
                    ( "#{r}" for r in results )
            else
                results = trySubs()
            mdebug '<--', ( "#{r}" for r in results )
            return results

If the pattern is non-atomic, then it must match the expression
structurally.  The first step in doing so is to have the same size.  We use
`childrenSatisfying()` here because it returns all immediate subexpressions,
children or head symbols or bound variables or binding bodies.

        pchildren = pattern.childrenSatisfying()
        mdebug '    pattern children:',
            ( p.simpleEncode() for p in pchildren )
        echildren = expression.childrenSatisfying()
        mdebug '    expression children:',
            ( e.simpleEncode() for e in echildren )
        if pchildren.length isnt echildren.length
            result = trySubs()
            mdebug '<--', ( "#{r}" for r in result )
            return result

Now that we've determined that the pattern and expression have the same
structure at this level, we must compute the match recursively on the
children.  Before we can do so, however, we must verify the assumptions of
this routine:  There can be no more than one substitution expression in the
pattern, and it must appear as the last child.  If there is more than one,
we throw an error.  If there is one, we permute the children to put it as
the last.

        substIndex = -1
        isASubstitution = ( node ) ->
            node.type is 'a' and \
            ( ( node.children[0].equals Match.requiredSubstitution ) or \
              ( node.children[0].equals Match.optionalSubstitution ) )
        for pchild, index in pchildren
            if pchild.descendantsSatisfying( isASubstitution ).length > 0
                if substIndex > -1
                    throw 'Only one substitution permitted in a pattern'
                substIndex = index
        if substIndex > -1
            last = pchildren.length-1
            [ pchildren[substIndex], pchildren[last] ] =
                [ pchildren[last], pchildren[substIndex] ]
            [ echildren[substIndex], echildren[last] ] =
                [ echildren[last], echildren[substIndex] ]
            mdebug '    reordered children to put substitution at end...'
            mdebug '    pattern children:',
                ( p.simpleEncode() for p in pchildren )
            mdebug '    expression children:',
                ( e.simpleEncode() for e in echildren )

We now form an array of results, containing just the one match object we've
been building so far, and then let that array grow as we test it against
each child.

        results = [ soFar ]
        for pchild, index in pchildren
            echild = echildren[index]
            mdebug '    recurring at', index, 'on', pchild.simpleEncode(),
                'and', echild.simpleEncode(), 'with results',
                ( "#{r}" for r in results )
            newResults = [ ]
            for sf in results
                newResults = newResults.concat matches pchild, echild,
                    sf.copy()
            if ( results = newResults ).length is 0 then break
        mdebug '    recursion complete; new result set:',
            ( "#{r}" for r in results )

Before returning the results, if we are the outermost call, instantiate all
unused metavariables to things like "unused_1", etc.  And, of course, filter
them through `markVisited` as usual.

        if outermost then result.complete() for result in results
        mdebug '    results have been completed:',
            ( "#{r}" for r in results )
        mdebug '<--', ( "#{r}" for r in results )
        results
