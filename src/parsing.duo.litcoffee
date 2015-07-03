
# Parsing Module

## Introduction

This module implements the Earley Parser, an algorithm [given on Wikipedia
here](https://en.wikipedia.org/wiki/Earley_parser).  Much of this code was
translated from [the desktop version of Lurch](www.lurchmath.org).

Although the module functions well, it would be great to enhance it to
accept non-string input, any array, actually.  We provide a tokenizer in
this module also, whose output would be perfectly sensible parser input.

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
                expressionBuilder : null

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
 * `expressionBuilder` can be set to a function that will be called each
   time a production is completed.  It will receive as input the results of
   that production (wrapped in an array if `collapseBranches` is true, with
   the category name prepended if `addCategories` is true) and it can return
   any object to replace that array in the final result.  Since this will be
   called at every level of the hierarchy, you can use this to recursively
   build expressions from the leaves upwards.  Because it will need to be
   copyable, outputs are restricted to JSON data.

This algorithm is documented to some degree, but it will make much more
sense if you have read the Wikipedia page cited at the top of this file.

        parse : ( input, options = { } ) =>
            options.addCategories ?= @defaults.addCategories
            options.collapseBranches ?= @defaults.collapseBranches
            options.showDebuggingOutput ?= @defaults.showDebuggingOutput
            options.expressionBuilder ?= @defaults.expressionBuilder
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
                                if options.expressionBuilder?
                                    got = options.expressionBuilder got
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

## Tokenizing

We also provide a class for doing simple tokenization of strings into arrays
of tokens, which can then be passed to a parser.  To use this class, create
an instance, add some token types using the `addType` function documented
below, then either call its `tokenize` function yourself on a string, or
just set this tokenizer as the default tokenizer on a parser.

    exports.Tokenizer = class Tokenizer
        constructor : -> @tokenTypes = [ ]

This function adds a token type to this object.  The first parameter is the
regular expression used to match the tokens.  The second parameter can be
either of three things:
 * If it is a function, that function will be run on every instance of the
   token that's found in any input being tokenized, and the output of the
   function used in place of the token string in the return value from this
   tokenizer.  But if the function returns null, the tokenizer will omit
   that token from the output array.  This is useful for, say, removing
   whitespace:  `addType( /\s/, -> null )`.  The function will actually
   receive two parameters, the second being the regular expresison match
   object, which can be useful if there were captured subexpressions.
 * If it is a string, that string will be used as the output token instead
   of the actual matched token.  All `%n` patterns in the output will be
   simultaneously replaced with the captured expressions of the type's
   regular expression (with zero being the entire match).  This is useful
   for reformatting tokens by adding detail.  Example:
   `addType( /-?[0-9]+/, 'Integer(%0)' )`
 * The second parameter may be omitted, and it will be treated as the
   identity function, as in the first bullet point above.

        addType : ( regexp, formatter = ( x ) -> x ) =>
            if regexp.source[0] isnt '^'
                regexp = new RegExp "^(?:#{regexp.source})"
            @tokenTypes.push
                regexp : regexp
                formatter : formatter

Tokenizing is useful for grouping large, complex chunks of text into one
piece before parsing, so that the parsing rules can be simpler and clearer.
For example, a regular expression that groups double-quoted string literals
into single tokens is `/"(?:[^\\"]|\\\\|\\")*"/`.  That's a much shorter bit
of code to write than a complex set of parsing rules that accomplish the
same purpose; it will also run more efficiently than those rules would.

The following routine tokenizes the input, returning one of two things:
 * an array of tokens, each of which was the output of the formatter
   function/string provided to `addType()`, above, or
 * null, because some portion of the input string did not match any of the
   token types added with `addType()`.

The routine simply tries every regular expression of every token type added
with `addType()`, above, and when one succeeds, it pops that text off the
input string, saving it to a results list after passing it throught he
corresponding formatter.  If at any point none of the regular expressions
matches the beginning of the remaining input, null is returned.

        tokenize : ( input ) =>
            result = [ ]
            while input.length > 0
                original = input.length
                for type in @tokenTypes
                    if not match = type.regexp.exec input then continue
                    input = input[match[0].length..]
                    if type.formatter instanceof Function
                        next = type.formatter match[0], match
                        if next? then result.push next
                    else
                        format = "#{type.formatter}"
                        token = ''
                        while next = /\%([0-9]+)/.exec format
                            token += format[...next.index] + match[next[1]]
                            format = format[next.index+next[0].length..]
                        result.push token + format
                    break
                if input.length is original then return null
            result

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
