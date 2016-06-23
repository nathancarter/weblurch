
# MathQuill Parser

This file depends upon [the parsing module](parsing-duo.litcoffee), and uses
it to define a parser for the types of expressions that come out of the
[MathQuill](www.mathquill.com) plugin ([stored here](../app/eqed)).  More
details are given below.

The following lines ensure that this file works in Node.js, for testing.

    if not exports? then exports = module?.exports ? window
    if require?
        { OM, OMNode } = require './openmath-duo'
        { Grammar } = require './parsing-duo'
    else
        Grammar = window.Grammar
        OM = window.OM
        OMNode = window.OMNode

## Extracting text from MathQuill DOM nodes

The third-party plugin for math equations can have its rough meaning
extracted by the following function, which can be applied to any DOM element
that has the style "mathquill-rendered-math."  For instance, the expression
$x^2+5$ in MathQuill would become `["x","sup","2","+","5"]` as returned by
this function, similar to the result of a tokenizer, ready for a parser.

That's why this function appears in this file, because it prepares MathQuill
nodes for the parser defined below.

    window.mathQuillToMeaning = exports.mathQuillToMeaning = ( node ) ->
        if node instanceof Text then return node.textContent
        result = [ ]
        for child in node.childNodes
            if ( $ child ).hasClass( 'selectable' ) or \
               ( $ child ).hasClass( 'cursor' ) or \
               /width:0/.test child.getAttribute? 'style'
                continue
            result = result.concat mathQuillToMeaning child
        if node.tagName in [ 'SUP', 'SUB' ]
            name = node.tagName.toLowerCase()
            if ( $ node ).hasClass 'nthroot' then name = 'nthroot'
            if result.length > 1
                result.unshift '('
                result.push ')'
            result.unshift name
        for marker in [ 'fraction', 'overline', 'overarc' ]
            if ( $ node ).hasClass marker
                if result.length > 1
                    result.unshift '('
                    result.push ')'
                result.unshift marker
        for marker in [ 'numerator', 'denominator' ]
            if ( $ node ).hasClass marker
                if result.length > 1
                    result.unshift '('
                    result.push ')'
        if result.length is 1 then result[0] else result

## Grammar definition

The `mathQuillToMeaning` function defined in
[the main app setup file](../app/setup.litcoffee) converts a WYSIWYG math
expression into a chain of tokens that can be read by a parser.  For
instance, a fraction with numerator x+1 and denominator t squared would
become the expression "fraction ( ( x + 1 ) ( t sup 2 ) )".  This module
defines a grammar for parsing such expressions (including arithmetic,
radicals, transcendental functions, limits, summations, integrals,
differentials, absolute values, and relations).

    exports.mathQuillParser = G = new Grammar 'expression'

Rules for numbers:

    G.addRule 'digit', /[0-9]/
    G.addRule 'nonnegint', 'digit'
    G.addRule 'nonnegint', [ 'digit', 'nonnegint' ]
    G.addRule 'integer', 'nonnegint'
    G.addRule 'integer', [ /-/, 'nonnegint' ]
    G.addRule 'float', [ 'integer', /\./, 'nonnegint' ]
    G.addRule 'float', [ 'integer', /\./ ]
    G.addRule 'infinity', [ /∞/ ]

Rule for variables:

    G.addRule 'variable', /[a-zA-Z\u0374-\u03FF]/

The above togeteher are called "atomics":

    G.addRule 'atomic', 'integer'
    G.addRule 'atomic', 'float'
    G.addRule 'atomic', 'variable'
    G.addRule 'atomic', 'infinity'

Rules for the operations of arithmetic:

    G.addRule 'factor', 'atomic'
    G.addRule 'factor', [ 'atomic', /sup/, 'atomic' ]
    G.addRule 'factor', [ 'factor', /[%]/ ]
    G.addRule 'factor', [ /\$/, 'factor' ]
    G.addRule 'factor', [ 'factor', /sup/, /[∘]/ ]
    G.addRule 'prodquo', 'factor'
    G.addRule 'prodquo', [ 'prodquo', /[÷×·]/, 'factor' ]
    G.addRule 'prodquo', [ /-/, 'prodquo' ]
    G.addRule 'sumdiff', 'prodquo'
    G.addRule 'sumdiff', [ 'sumdiff', /[+±−-]/, 'prodquo' ]

Rules for logarithms:

    G.addRule 'ln', [ /ln/, 'atomic' ]
    G.addRule 'log', [ /log/, 'atomic' ]
    G.addRule 'log', [ /log/, /sub/, 'atomic', 'atomic' ]
    G.addRule 'prodquo', 'ln'
    G.addRule 'prodquo', 'log'

Rules for factorial:

    G.addRule 'factorial', [ 'atomic', /!/ ]
    G.addRule 'factor', 'factorial'

Rules for the operations of set theory (still incomplete):

    G.addRule 'setdiff', 'variable'
    G.addRule 'setdiff', [ 'setdiff', /[∼]/, 'variable' ]

Rules for subscripts, which count as function application (so that "x sub i"
still contains i as a free variable):

    G.addRule 'subscripted', [ 'atomic', /sub/, 'atomic' ]
    G.addRule 'noun', 'subscripted'

Rules for various structures, like fractions, which are treated indivisibly,
and thus as if they were atomics:

    G.addRule 'fraction',
        [ /fraction/, /\(/, 'atomic', 'atomic', /\)/ ]
    G.addRule 'atomic', 'fraction'
    G.addRule 'root', [ /√/, 'atomic' ]
    G.addRule 'root', [ /nthroot/, 'atomic', /√/, 'atomic' ]
    G.addRule 'atomic', 'root'
    G.addRule 'decoration', [ /overline/, 'atomic' ]
    G.addRule 'decoration', [ /overarc/, 'atomic' ]
    G.addRule 'atomic', 'decoration'
    G.addRule 'trigfunc', [ /sin|cos|tan|cot|sec|csc/ ]
    G.addRule 'trigapp', [ 'trigfunc', 'prodquo' ]
    G.addRule 'trigapp',
        [ 'trigfunc', /sup/, /\(/, /-|−/, /1/, /\)/, 'prodquo' ]
    G.addRule 'atomic', 'trigapp'

Rules for limits and summations:

    G.addRule 'limit', [ /lim/, /sub/,
        /\(/, 'variable', /[→]/, 'expression', /\)/, 'prodquo' ]
    G.addRule 'takesleftcoeff', 'limit'
    G.addRule 'sum', [ /[Σ]/,
        /sub/, /\(/, 'variable', /[=]/, 'expression', /\)/,
        /sup/, 'atomic', 'prodquo' ]
    G.addRule 'sum', [ /[Σ]/, /sup/, 'atomic',
        /sub/, /\(/, 'variable', /[=]/, 'expression', /\)/,
        'prodquo' ]
    G.addRule 'takesleftcoeff', 'sum'

Rules for differential and integral calculus:

    G.addRule 'differential', [ /d/, 'atomic' ]
    G.addRule 'difffrac',
        [ /fraction/, /\(/, /d/, /\(/, /d/, 'variable', /\)/, /\)/ ]
    G.addRule 'indefint', [ /[∫]/, 'prodquo' ]
    G.addRule 'defint',
        [ /[∫]/, /sub/, 'atomic', /sup/, 'atomic', 'prodquo' ]
    G.addRule 'defint',
        [ /[∫]/, /sup/, 'atomic', /sub/, 'atomic', 'prodquo' ]
    G.addRule 'factor', 'differential'
    G.addRule 'factor', 'difffrac'
    G.addRule 'takesleftcoeff', 'indefint'
    G.addRule 'takesleftcoeff', 'defint'

The category `takesleftcoeff` contains those things that can be multiplied
on the left, unambiguously, by a coefficient.  For instance, a limit, when
multiplied on the left by a coefficient, is clearly the coefficient times
the entire limit, as a consequence of the opening marker "lim" which removes
the possibility for ambiguity.  The same is true of summations and
integrals.

    G.addRule 'sumdiff', 'takesleftcoeff'
    G.addRule 'sumdiff', [ 'factor', /[÷×·]/, 'takesleftcoeff' ]
    G.addRule 'sumdiff', [ 'prodquo', /[+±−-]/, 'takesleftcoeff' ]

So far we've only defined rules for forming mathematical nouns, so we wrap
the highest-level non-terminal defined so far, sumdiff, in the label "noun."

    G.addRule 'noun', 'sumdiff'
    G.addRule 'noun', 'setdiff'

Rules for forming sentences from nouns, by placing relations between them:

    G.addRule 'atomicsentence', [ 'noun', /[=≠≈≃≤≥<>]/, 'noun' ]
    G.addRule 'atomicsentence', [ /[¬]/, 'atomicsentence' ]
    G.addRule 'sentence', 'atomicsentence'
    G.addRule 'sentence', [ /[∴]/, 'sentence' ]

Rules for groupers:

    G.addRule 'atomic', [ /\(/, 'noun', /\)/ ]
    G.addRule 'atomicsentence', [ /\(/, 'sentence', /\)/ ]
    G.addRule 'interval',
        [ /[\(\[]/, 'noun', /,/, 'noun', /[\)\]]/ ]
    G.addRule 'atomic', 'interval'
    G.addRule 'absval', [ /\|/, 'noun', /\|/ ]
    G.addRule 'atomic', 'absval'

And finally, place "expression" at the top of the grammar; one is permitted
to use this grammar to express mathematical nouns or complete sentences:

    G.addRule 'expression', 'noun'
    G.addRule 'expression', 'sentence'

A function that recursively assembles OpenMath nodes from the hierarchy of
arrays created by the parser:

    G.setOption 'expressionBuilder', ( expr ) ->
        symbols =
            '+' : OM.symbol 'plus', 'arith1'
            '-' : OM.symbol 'minus', 'arith1' # yes these are two
            '−' : OM.symbol 'minus', 'arith1' # different characters!
            '±' : OM.symbol 'plusminus', 'multiops'
            '×' : OM.symbol 'times', 'arith1'
            '·' : OM.symbol 'times', 'arith1'
            '÷' : OM.symbol 'divide', 'arith1'
            '^' : OM.symbol 'power', 'arith1'
            '∞' : OM.symbol 'infinity', 'nums1'
            '√' : OM.symbol 'root', 'arith1'
            '∼' : OM.symbol 'set1', 'setdiff'
            '=' : OM.symbol 'eq', 'relation1'
            '<' : OM.symbol 'lt', 'relation1'
            '>' : OM.symbol 'gt', 'relation1'
            '≠' : OM.symbol 'neq', 'relation1'
            '≈' : OM.symbol 'approx', 'relation1'
            '≤' : OM.symbol 'le', 'relation1'
            '≥' : OM.symbol 'ge', 'relation1'
            '≃' : OM.symbol 'modulo_relation', 'integer2'
            '¬' : OM.symbol 'not', 'logic1'
            '∘' : OM.symbol 'degrees', 'units'
            '$' : OM.symbol 'dollars', 'units'
            '%' : OM.symbol 'percent', 'units'
            '∫' : OM.symbol 'int', 'calculus1'
            'def∫' : OM.symbol 'defint', 'calculus1'
            'ln' : OM.symbol 'ln', 'transc1'
            'log' : OM.symbol 'log', 'transc1'
            'unary-' : OM.symbol 'unary_minus', 'arith1'
            'overarc' : OM.symbol 'overarc', 'decoration'
            'overline' : OM.symbol 'overline', 'decoration'
            'd' : OM.symbol 'd', 'diff'
        build = ( args... ) ->
            args = for a in args
                if typeof a is 'number' then a = expr[a]
                if symbols.hasOwnProperty a then a = symbols[a]
                if typeof a is 'string' then a = OM.decode a
                a
            tmp = OM.application args...
            if G.expressionBuilderDebug
                argstrs = for arg in args
                    if arg instanceof OMNode then arg.encode() \
                        else "#{arg}"
                console.log 'build', argstrs..., '-->', tmp
            tmp
        result = switch expr[0]
            when 'digit', 'nonnegint' then expr[1..].join ''
            when 'integer'
                OM.integer parseInt expr[1..].join ''
            when 'float' then OM.float parseFloat \
                "#{expr[1].value}#{expr[2..].join ''}"
            when 'variable' then OM.variable expr[1]
            when 'infinity' then symbols[expr[1]]
            when 'sumdiff', 'prodquo'
                switch expr.length
                    when 4 then build 2, 1, 3
                    when 3 then build 'unary-', 2
            when 'factor'
                switch expr.length
                    when 4
                        if expr[3] is '∘'
                            build '×', 1, symbols['∘']
                        else
                            build '^', 1, 3
                    when 3
                        if expr[2] is '%'
                            build '×', 1, symbols['%']
                        else
                            build '×', 2, symbols['$']
            when 'fraction' then build '÷', 3, 4
            when 'root'
                switch expr.length
                    when 3 then build '√', 2, OM.integer 2
                    when 5 then build '√', 4, 2
            when 'ln' then build 'ln', 2
            when 'log'
                switch expr.length
                    when 3 then build 'log', OM.integer( 10 ), 2
                    when 5 then build 'log', 3, 4
            when 'atomic'
                if expr.length is 4 and expr[1] is '(' and \
                   expr[3] is ')' then expr[2]
            when 'atomicsentence'
                switch expr.length
                    when 4 then build 2, 1, 3
                    when 3 then build 1, 2
            when 'decoration' then build 1, 2
            when 'sentence' then if expr[1] is '∴' then expr[2]
            when 'interval'
                left = if expr[1] is '(' then 'o' else 'c'
                right = if expr[5] is ')' then 'o' else 'c'
                build OM.symbol( "interval_#{left}#{right}",
                    'interval1' ), 2, 4
            when 'absval' then build OM.symbol( 'abs', 'arith1' ), 2
            when 'trigapp'
                switch expr.length
                    when 3 then build OM.symbol( expr[1],
                        'transc1' ), 2
                    when 8 then build OM.symbol( "arc#{expr[1]}",
                        'transc1' ), 7
            when 'subscripted' then build 1, 3
            when 'factorial' then build OM.symbol( 'factorial',
                'integer1' ), 1
            when 'limit'
                build OM.symbol( 'limit', 'limit1' ), 6,
                    OM.symbol( 'both_sides', 'limit1' ),
                    OM.binding OM.symbol( 'lambda', 'fns1' ),
                        expr[4], expr[8]
            when 'sum'
                [ varname, from, to ] = if expr[2] is 'sup' then \
                    [ 6, 8, 3 ] else [ 4, 6, 9 ]
                build OM.symbol( 'sum', 'arith1' ),
                    OM.application(
                        OM.symbol( 'interval', 'interval1' ),
                        expr[from], expr[to] ),
                    OM.binding( OM.symbol( 'lambda', 'fns1' ),
                        expr[varname], expr[10] )
            when 'differential' then build 'd', 2
            when 'difffrac' then build '÷', 'd', build 'd', 6
            when 'indefint' then build '∫', 2
            when 'defint'
                [ a, b ] = if expr[2] is 'sup' then [ 5, 3 ] \
                    else [ 3, 5 ]
                build 'def∫', a, b, 6
        if not result? then result = expr[1]
        # if result instanceof OMNode then result = result.tree
        if G.expressionBuilderDebug
            console.log ( if expr instanceof OMNode then \
                expr.encode() else "#{expr}" ), '--->',
                if result instanceof OMNode then \
                    result.encode() else result
        result
    G.setOption 'comparator', ( a, b ) -> a?.equals? b
