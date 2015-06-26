
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
OMNode of type variable.

    exports.setMetavariable = setMetavariable = ( variable ) ->
        if variable not instanceof OMNode or variable.type isnt 'v'
            return
        variable.setAttribute metavariableSymbol, trueValue.copy()

To undo the above action, call the following function, which removes the
attribute.

    exports.clearMetavariable = clearMetavariable = ( metavariable ) ->
        metavariable.removeAttribute metavariableSymbol

To query whether a variable has been marked as a metaviariable, use the
following routine, which tests for the presence of the attribute in
question.

    exports.isMetavariable = isMetavariable = ( variable ) ->
        variable instanceof OMNode and variable.type is 'v' and \
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
using the map.  Parameters with the name "variable" can either be strings
(the name of the variable) or actual OpenMath variable objects, in which
case their name will be used.  Parameters with the name "expr" can be any
OpenMath expressions, and only copies of them will be stored in this object
when queried, the copies will be returned.

The `set` function assigns an expression to a variable in the mapping.  A
copy of the given expression is stored.

        set : ( variable, expr ) =>
            if variable.name? then variable = variable.name
            @map[variable] = expr.copy()

The `get` function queries the mapping for a variable name, and returns the
same copy made at the time `set` was called (which is also still stored
internally in the map).

        get : ( variable ) => @map[variable.name ? variable]

The `clear` function removes a variable from the map (and whatever
expression it was paired with).

        clear : ( variable ) => delete @map[variable.name ? variable]

The `has` function just returns a true or false value indicating whether
the variable appears in the map as a key.

        has : ( variable ) => @map.hasOwnProperty variable.name ? variable

The `variables` function lists the names of all variables that appear in
the mapping, in no particular order.

        variables : => Object.keys @map

The map can be applied to an expression, and all metavariables in it will
be replaced with a copy of their values in the map.  Those metavariables
that do not appear in the map will be unaffected.  This is not performed
in-place in the given pattern, but rather in a copy, which is returned.

        applyTo : ( pattern ) =>
            result = pattern.copy()
            for metavariable in result.descendantsSatisfying isMetavariable
                if @has metavariable
                    metavariable.replaceWith @get( metavariable ).copy()
            result

### Substitutions

This matching package supports patterns that express optional or required
substitutions.  The informal notation `A[x=y]` means "the expression `A`
with every free occurrence of the subexpression `x` replaced by the
subexpression `y`, where `y` is free to replace `x`."  The informal notation
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

When these show up in matching patterns, the matching algorithm must track
them.  Thus this class provides methods for storing and querying the
replacement pattern that is in force, if any, what type it is, and what its
arguments are.

First, a method for storing a substitution.  In `A[x=y]`, `x` is the left
hand side, `y` is the right hand side, and we could pass both of those
subexpressions as the first two arguments of the following function.  You
can safely pass the originals; they will be copied.  The third parameter, in
that case, would be `true`, to indicate that it is a required substitution.
If it had been `A[x~y]`, then the third parameter would be false.

        setSubstitution : ( leftHandSide, rightHandSide, required ) =>
            @substitution =
                leftHandSide : leftHandSide.copy()
                rightHandSide : rightHandSide.copy()
                required : required

Second, several methods for querying the data stored using the previous
function.

        hasSubstitution : => @substitution?
        getSubstitutionLeft : => @substitution?.leftHandSide
        getSubstitutionRight : => @substitution?.rightHandSide
        getSubstitutionRequired : => @substitution?.required

Finally, a method for removing a stored substitution.

        clearSubstitution : => delete @substitution

### Visiting

The pattern-matching algorithm implemented later in this file will need to
store in its match object(s) a list of subexpressions of the pattern, as it
visits them.  We thus provide the following functions to enable that.

You can only mark a node visited if a substitution is in force.  This is
because we only track visited nodes so that a substitution can later check
to be sure that it is consistent with all subtrees of its node in the
pattern, which is why we're tracking a visited list in the first place.
(See [the matching algorithm](#matching-algorithm) further below.)

The first time this function is called, it also saves the given `node` as
the full pattern, because the function is called on all nodes in the pattern
in tree order; thus the first will be the pattern.  The matching algorithm
may need to query that member later.

        markVisited : ( node ) =>
            if @hasSubstitution() then @visited.push node
            @pattern ?= node

And now two getters for the same stored data.  Note that the visited list is
returned as the actual nodes visited, not copies, so be careful not to
modify them unless you intend to modify the pattern itself.

        getVisitedList : => @visited[..]
        getPattern : => @pattern

### Copying match objects

It is straightforward to copy a match object; just copy all of its members.
But it matters which ones are deeply copied and which ones are not.  Here
are the details.
 * The values in the map are copies of those in the original map.
 * The values in the visited list are equal to those in the original map,
   but the array itself is a copy.
 * The result's substitution is a deep copy of this object's substitution.
 * The pattern is assigned to the result as well, not deeply copied.

        copy : =>
            result = new Match
            for own key, value of @map
                result.map[key] = value.copy()
            result.visited = @visited[..]
            if @substitution?
                result.substitution =
                    leftHandSide : @substitution.leftHandSide.copy()
                    rightHandSide : @substitution.rightHandSide.copy()
                    required : @substitution.required
            if @pattern? then result.pattern = @pattern
            result

## Matching Algorithm

NOTE:  This module is not yet complete!
