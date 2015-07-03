
# Parsing Module

## Introduction

This module implements the Earley Parser, an algorithm [given on Wikipedia
here](https://en.wikipedia.org/wiki/Earley_parser).  Much of this code was
translated from [the desktop version of Lurch](www.lurchmath.org).

Although the module functions well, several potential enhancements remain,
listed here.
 * Eliminate the need for the two current options by letting clients provide
   an arbitrary function that will be run on each matched rule to construct
   the resulting expression.
 * Accept non-string input (any array, maybe that came from a tokenizer).
 * Provide a simple tokenization routine that takes a string and an array
   and does this:
   * Try each regexp in the array on the start of the string; for the first
     one that succeeds:
     * Pop the matched text and save it as a token in the output array.
     * If the regexp is followed in the input array by a function, run that
       on the token.  Replace the token in the output array with the result
       of the function, unless it's null, which means remove the token from
       the output array.
     * If instead it's followed by a string, do simultaneous replacement of
       all %n patterns with the regexp captures, and use that in place of
       the token.
   * If no regexp matches, pop a single char as a token.
This last feature allows us to create things like the following.
 * Example whitespace remover: `[ /\s/, null ]`
   * `'2 + 3 * 4' -> ['2','+','3','*','4']`
 * Example quotation tokenizer: `[ /"(?:[^\\"]|\\\\|\\")*"/ ]`
   * `f("Hello") -> ['f','(','"Hello"',')']`

## Utilities

The following lines ensure that this file works in Node.js, for testing.

    if not exports? then exports = module?.exports ? window

An Earley state is an object of the following form.  The `lhs` and `rhs`
together are the rule currently being matched, `pos` is the current
position in that production, a zero-based index through all the interstitial
points in `rhs` (zero being before the whole thing, 1 after the first
entry, etc.), `ori` the position in the input text at which the match
began (called the origin), and `got` is the list of tokens parsed so far.
```
{
    lhs : categoryname,
    rhs : [ ... ],
    pos : integerindex,
    ori : integerindex,
    got : [ ... ]
}
```
A parsed token is either a plain string containing the terminal or an array
whose first element is the category name and the rest of which are the
terminals and nonterminals in its parsing.

    getNext = ( state ) ->
        if state.pos < state.rhs.length then state.rhs[state.pos] else null

The following simple tool is used to copy state objects.  It is a shallow
copy in all except the `got` array.

    copyState = ( state ) ->
        lhs : state.lhs
        rhs : state.rhs
        pos : state.pos
        ori : state.ori
        got : JSON.parse JSON.stringify state.got

We will later need to compare two arrays of strings and/or regular
expressions for equality.  This function does so.

    equalArrays = ( array1, array2 ) ->
        if array1.length isnt array2.length then return no
        for entry1, index in array1
            entry2 = array2[index]
            if entry1 instanceof RegExp
                if entry2 not instanceof RegExp or \
                    entry1.source isnt entry2.source then return no
            else
                if entry1 isnt entry2 then return no
        yes

## Grammar class

All of the functionality of this module is embedded in a class called
`Grammar`, which lets you define new grammars and then run them on strings
to parse those strings.  This section defines that class.

As mentioned on the Wikipedia page linked to above, a grammar is a set of
rules of the form `C -> A1 A2 ... An` where `C` is the name of a category
and each `Ai` can be a category name or a terminal.

The `Grammar` class defined below stores a grammar as an object whose keys
are category names with values of the following form.
```
    [
        [ 'catname', 'catname', /terminal/, /terminal/, ... ],
        [ 'catname', /terminal/, 'catname', /terminal/, ... ],
        ...
    ],
```
Each row in the two-dimensional array represents the right-hand side of one
rule in the grammar, whose left hand side is the category name under which
the entire two-dimensional array is stored.

The entries in the arrays can be strings (which signify the names of
non-terminals) or regular expressions (which signify that they are
terminals, which must match the regular expression).

Now we begin the class.

    exports.Grammar = class Grammar

## Constructor

Indicate which of the categories is the starting category by passing its
name to a grammar when you construct one.

        constructor : ( @START ) ->
            @rules = { }
            @defaults =
                addCategories : yes
                collapseBranches : no
                showDebuggingOutput : no

The default options for the parsing algorithm are initialized in the
constructor above, but you can change them using the following routine.  The
first parameter is the name of the option (from the list immediately above)
and the second parameter is its new value.  The meaning of these options is
documented [below](#earley-algorithm).

        setOption : ( optionName, optionValue ) =>
            @defaults[optionName] = optionValue

Add a rule to the grammar by specifying the category name and the sequence
of Ai that appear on the right hand side.  This creates/extends the
two-dimensional array described above.

You can pass more than one sequence by providing additional parameters, to
add them all at once.  You can also provide a string instead of an array,
and it will be converted into an array by splitting at spaces as if it were
a string.  Regular expressions will be automatically wrapped in `^...$` for
you, so that they are always tested against the entire string.

        addRule : ( categoryName, sequences... ) =>
            for sequence in sequences
                if sequence instanceof RegExp
                    sequence = [ sequence ]
                if sequence not instanceof Array
                    sequence = "#{sequence}".split ' '
                for entry, index in sequence
                    if entry instanceof RegExp
                        sequence[index] = new RegExp "^#{entry.source}$"
                ( @rules[categoryName] ?= [ ] ).push sequence

## Earley Algorithm

The following function is the workhorse of this module.  It assumes that the
input is a string of a nonzero length.  Options is not a required parameter,
but if it is present it should be an object with some subset of the
following properties.  Any unspecified properties take the defaults given in
the constructor for this class, unless you changed them with `setOption`,
defined [above](#constructor).
 * `addCategories : true` iff category names should be prepended to each
   match sequence
 * `collapseBranches : true` iff one-argument match sequences should be
   collapsed, as in `[[[[a]]]] -> a`
 * `showDebuggingOutput : true` iff lots of debugging spam should be dumped
   to the console as the algorithm executes

This algorithm is documented to some degree, but it will make much more
sense if you have read the Wikipedia page cited at the top of this file.

        parse : ( input, options = { } ) =>
            options.addCategories ?= @defaults.addCategories
            options.collapseBranches ?= @defaults.collapseBranches
            options.showDebuggingOutput ?= @defaults.showDebuggingOutput
            debug = if options.showDebuggingOutput then console.log else ->
            debug '\n\n'

Initialize the set of states to teh array `[ [], [], ..., [] ]`, one entry
for each interstice between characters in `input`, including one for before
the first character and one for after the last.

            stateGrid = ( [] for i in [0..input.length] )

Push all productions for the starting non-terminal onto the initial state
set.

            stateGrid[0].push
                lhs : ''
                rhs : [ @START ]
                pos : 0
                ori : 0
                got : []

Do the main nested loop which solves the whole problem.

            for stateSet, i in stateGrid
                debug "processing stateSet #{i} in this stateGrid
                    (with input #{input}):"
                debug '----------------------'
                for tmpi in [0...stateGrid.length]
                    debug "|    state set #{tmpi}:"
                    for tmpj in [0...stateGrid[tmpi].length]
                        debug "|        entry #{tmpj}:
                            #{debugState stateGrid[tmpi][tmpj]}"
                debug '----------------------'

The following loop is written in this indirect way (not using `for`) because
the contents of `stateSet` may be modified within the loop, so we need to be
sure that we do not pre-compute its length, but allow it to grow.

                j = 0
                while j < stateSet.length
                    state = stateSet[j]
                    debug "entry #{j}:", debugState state

There are three possibilities.
 * The next state is a terminal,
 * the next state is a production, or
 * there is no next state.
Each of these is handled by a separate sub-task of the Earley algorithm.

                    next = getNext state
                    debug 'next:', next
                    if next is null

This is the case in which there is no next state.  It is handled by running
the "completer":  We just completed a nonterminal, so mark progress in
whichever rules spawned it by copying them into the next column in
`stateGrid`, with progress incremented one step.

                        debug 'considering if this completion matters to
                            state set', state.ori
                        for s, k in stateGrid[state.ori]
                            if getNext( s ) is state.lhs
                                s = copyState s
                                s.pos++
                                got = JSON.parse JSON.stringify state.got
                                if options.addCategories
                                    got.unshift state.lhs
                                if options.collapseBranches and \
                                    got.length is 1 then got = got[0]
                                s.got.push got
                                stateGrid[i].push s
                                debug "completer added this to #{i}:",
                                    debugState s
                        j++
                        continue
                    if i >= input.length then j++ ; continue
                    debug 'is it a terminal?', next instanceof RegExp
                    if next instanceof RegExp

This is the case in which the next state is a terminal.  It is handled by
running the "scanner":  If the next terminal in `state` is the one we see
coming next in the input string, then find every production at that
terminal's origin that contained that terminal, and mark progress here.

                        if next.test input[i]
                            copy = copyState state
                            copy.pos++
                            copy.got.push input[i]
                            stateGrid[i+1].push copy
                            debug "scanner added this to #{i+1}:",
                                debugState copy
                        j++
                        continue
                    if not @rules.hasOwnProperty next
                        throw "Unknown non-terminal in grammar rule:
                            #{next}"

This is the case in which the next state is a non-terminal, i.e., the lhs of
one or more rules.  It is handled by running the "predictor:"  For every
rule that starts with the non-terminal that's coming next, add that rule to
the current state set so that it will be explored in future passes through
the inner of the two main loops.

                    rhss = @rules[next]
                    debug "rhss: [#{rhss.join('],[')}]"
                    for rhs, k in rhss
                        found = no
                        for s in stateSet
                            if s.lhs is next and equalArrays( s.rhs, rhs ) \
                                    and s.pos is 0
                                found = yes
                                break
                        if not found
                            stateSet.push
                                lhs : next
                                rhs : rhs
                                pos : 0
                                ori : i
                                got : []
                            debug 'adding this state:',
                                debugState stateSet[stateSet.length-1]
                    j++
            debug "finished processing this stateGrid
                (with input #{input}):"
            debug '----------------------'
            for tmpi in [0...stateGrid.length]
                debug "|    state set #{tmpi}:"
                for tmpj in [0...stateGrid[tmpi].length]
                    debug "|        entry #{tmpj}:
                        #{debugState stateGrid[tmpi][tmpj]}"
            debug '----------------------'

The main loop is complete.  Any completed production in the final state set
that's marked as a result (and thus coming from state 0 to boot) is a valid
parsing and should be returned.

            ( stateSet.got[0] \
              for stateSet in stateGrid[stateGrid.length-1] when \
              stateSet.lhs is '' and getNext( stateSet ) is null )

## Debugging

The following debugging routines are used in some of the code above.

    debugNestedArrays = ( ary ) ->
        if ary instanceof Array
           '[' + ary.map( debugNestedArrays ).join( ',' ) + ']'
        else
            ary
    debugState = ( state ) ->
        "(#{state.lhs} -> #{state.pos}in[#{state.rhs}], #{state.ori}) got
            #{debugNestedArrays state.got}"
