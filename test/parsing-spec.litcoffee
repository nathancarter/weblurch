
# Tests of the Parsing module

Here we import the module we're about to test.

    { Grammar, Tokenizer } = require '../src/parsing.duo'
    { OM, OMNode } = require '../src/openmath.duo'
    full = ( x ) -> require( 'util' ).inspect x, depth : null

## The Grammar class

This section tests just the existence of the main class (Grammar).

    describe 'Grammar and Tokenizer classes', ->

### should be defined

        it 'should be defined', ->
            expect( Grammar ).toBeTruthy()
            expect( Tokenizer ).toBeTruthy()

## A simple grammar

This section defines a very simple grammer for sums and products of
integers, then verifies that it can be applied to parse expressions in that
language.

    describe 'A simple grammar', ->

Define the grammar here.  D is for digit, I for (nonnegative) integer, M for
multiplication expression, and S for summation expression.

        G = null
        beforeEach ->
            G = new Grammar 'S'
            G.addRule 'D', /[0-9]/
            G.addRule 'I', 'D', 'I D'
            G.addRule 'M', 'I', [ 'M', /\*/, 'I' ]
            G.addRule 'S', 'M', [ 'S', /\+/, 'M' ]

### should parse nonnegative integers

The grammar should correctly parse nonnegative integers.

        it 'should parse nonnegative integers', ->
            expect( G.parse '5' ).toEqual \
                [ [ 'S', [ 'M', [ 'I', [ 'D', '5' ] ] ] ] ]
            expect( G.parse '19' ).toEqual \
                [ [ 'S', [ 'M', [ 'I', [ 'I', [ 'D', '1' ] ],
                                       [ 'D', '9' ] ] ] ] ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            expect( G.parse '5' ).toEqual [ '5' ]
            expect( G.parse '19' ).toEqual [ [ '1', '9' ] ]

### should parse products of nonnegative integers

The grammar should correctly parse products of nonnegative integers.

        it 'should parse products of nonnegative integers', ->
            expect( G.parse '7*5' ).toEqual \
                [ [ 'S', [ 'M', [ 'M', [ 'I', [ 'D', '7' ] ] ], '*',
                                [ 'I', [ 'D', '5' ] ] ] ] ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            expect( G.parse '7*5*3*1' ).toEqual \
                [ [ [ [ '7', '*', '5' ], '*', '3' ], '*', '1' ] ]

### should parse sums of products of nonnegative integers

The grammar should correctly parse sums of products of nonnegative integers.

        it 'should parse sums of products of nonnegative integers', ->
            expect( G.parse '1+2' ).toEqual \
                [ [ 'S', [ 'S', [ 'M', [ 'I', [ 'D', '1' ] ] ] ], '+',
                         [ 'M', [ 'I', [ 'D', '2' ] ] ] ] ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            expect( G.parse '3*6+9' ).toEqual \
                [ [ [ '3', '*', '6' ], '+', '9' ] ]
            expect( G.parse '3+6*9' ).toEqual \
                [ [ '3', '+', [ '6', '*', '9' ] ] ]
            G.setOption 'expressionBuilder', ( x ) ->
                if x instanceof Array then "(#{x.join ''})" else "#{x}"
            expect( G.parse '3+6*9' ).toEqual [ '(3+(6*9))' ]

## A simple tokenizer

This section defines a very simple tokenizer for numbers, identifiers,
string literals, parentheses, and the operations of arithmetic.  It then
verifies that it can be applied to tokenize expressions in that language.

    describe 'A simple tokenizer', ->

### should tokenize arithmetic expressions

The tokenizer should correctly tokenize arithmetic expressions.

        it 'should tokenize arithmetic expressions', ->
            T = new Tokenizer
            T.addType /[a-zA-Z_][a-zA-Z_0-9]*/
            T.addType /\.[0-9]+|[0-9]+\.?[0-9]*/
            T.addType /"(?:[^\\"]|\\\\|\\")*"/
            T.addType /[()+/*-]/
            expect( T.tokenize '5' ).toEqual [ '5' ]
            expect( T.tokenize '19' ).toEqual [ '19' ]
            expect( T.tokenize '6-9' ).toEqual [ '6', '-', '9' ]
            expect( T.tokenize 'x*-5.0/(_tmp+k)' ).toEqual \
                [ 'x', '*', '-', '5.0', '/', '(', '_tmp', '+', 'k', ')' ]
            expect( T.tokenize 'alert("message")' ).toEqual \
                [ 'alert', '(', '"message"', ')' ]

### should support format functions

The tokenizer should permit `addType` to provide formatting functions that
change the token to be added to the tokens array, or even remove it
entirely.

        it 'should support format functions', ->
            T = new Tokenizer
            T.addType /\s/, -> null
            T.addType /[a-zA-Z_][a-zA-Z_0-9]*/
            T.addType /\.[0-9]+|[0-9]+\.?[0-9]*/
            T.addType /"(?:[^\\"]|\\\\|\\")*"/
            T.addType /\/((?:[^\\\/]|\\\\|\\\/)*)\//,
                ( text, match ) -> "RegExp(#{match[1]})"
            T.addType /[()+/*-]/
            expect( T.tokenize '5' ).toEqual [ '5' ]
            expect( T.tokenize '19' ).toEqual [ '19' ]
            expect( T.tokenize '6-9' ).toEqual [ '6', '-', '9' ]
            expect( T.tokenize 'x*-5.0/(_tmp+k)' ).toEqual \
                [ 'x', '*', '-', '5.0', '/', '(', '_tmp', '+', 'k', ')' ]
            expect( T.tokenize 'alert("message")' ).toEqual \
                [ 'alert', '(', '"message"', ')' ]
            expect( T.tokenize 'my(/regexp/)+6' ).toEqual \
                [ 'my', '(', 'RegExp(regexp)', ')', '+', '6' ]
            expect( T.tokenize '64 - 8320   + K' ).toEqual \
                [ '64', '-', '8320', '+', 'K' ]

### should support format strings

The tokenizer should permit `addType` to provide formatting strings that
change the token to be added to the tokens array.

        it 'should support format strings', ->
            T = new Tokenizer
            T.addType /[a-zA-Z_][a-zA-Z_0-9]*/
            T.addType /\.[0-9]+|[0-9]+\.?[0-9]*/
            T.addType /"(?:[^\\"]|\\\\|\\")*"/
            T.addType /\/((?:[^\\\/]|\\\\|\\\/)*)\//, 'RegExp(%1)'
            T.addType /[()+/*-]/
            expect( T.tokenize '5' ).toEqual [ '5' ]
            expect( T.tokenize '19' ).toEqual [ '19' ]
            expect( T.tokenize '6-9' ).toEqual [ '6', '-', '9' ]
            expect( T.tokenize 'x*-5.0/(_tmp+k)' ).toEqual \
                [ 'x', '*', '-', '5.0', '/', '(', '_tmp', '+', 'k', ')' ]
            expect( T.tokenize 'alert("message")' ).toEqual \
                [ 'alert', '(', '"message"', ')' ]
            expect( T.tokenize 'my(/regexp/)+6' ).toEqual \
                [ 'my', '(', 'RegExp(regexp)', ')', '+', '6' ]

## Tokenizing and parsing

Naturally tokenizing and parsing go hand-in-hand, the former usually paving
the way for the latter.  Here we test to be sure that the parser can handle
arbitrary array inputs, and that in particular it can handle the output of
a tokenizer.

    describe 'Tokenizing and parsing', ->

### should support parsing arrays

First we just test the parser alone, that it can handle arrays, which are
what the tokenizer will produce.  We use the same simple grammar for sums
and products of integers from earlier, but now we need not process
digit-by-digit, because we will provide the integers as single entres in the
input array, not each digit separately.

        it 'should support parsing arrays', ->
            G = new Grammar 'S'
            G.addRule 'I', /[0-9]+/
            G.addRule 'M', 'I', [ 'M', /\*/, 'I' ]
            G.addRule 'S', 'M', [ 'S', /\+/, 'M' ]
            expect( G.parse [ '5' ] ).toEqual \
                [ [ 'S', [ 'M', [ 'I', '5' ] ] ] ]
            expect( G.parse [ '19' ] ).toEqual \
                [ [ 'S', [ 'M', [ 'I', '19' ] ] ] ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            expect( G.parse [ '5' ] ).toEqual [ '5' ]
            expect( G.parse [ '19' ] ).toEqual [ '19' ]
            expect( G.parse [ '7', '*', '50', '*', '33', '*', '1' ] ) \
                .toEqual [ [ [ [ '7', '*', '50' ], '*', '33' ], '*', '1' ] ]
            G.setOption 'expressionBuilder', ( x ) ->
                if x instanceof Array then "(#{x.join ''})" else "#{x}"
            expect( G.parse [ '333', '+', '726', '*', '2349' ] ) \
                .toEqual [ '(333+(726*2349))' ]

### should be chainable

Now we test that we can create a tokenizer whose output will flow naturally
into a parser.  This is (almost) the culmination of the entire module.  The
only remaining test is the next one below, which makes this process simpler,
but performs essentially the same functions.

        it 'should be chainable', ->
            T = new Tokenizer
            T.addType /\s/, -> null
            T.addType /[a-zA-Z_][a-zA-Z_0-9]*/
            T.addType /\.[0-9]+|[0-9]+\.?[0-9]*/
            T.addType /"(?:[^\\"]|\\\\|\\")*"/
            T.addType /[()+/*-]/
            G = new Grammar 'expr'
            G.addRule 'expr', 'sumdiff'
            G.addRule 'atomic', /[a-zA-Z_][a-zA-Z_0-9]*/
            G.addRule 'atomic', /\.[0-9]+|[0-9]+\.?[0-9]*/
            G.addRule 'atomic', /"(?:[^\\"]|\\\\|\\")*"/
            G.addRule 'atomic', [ /\(/, 'sumdiff', /\)/ ]
            G.addRule 'prodquo', [ 'atomic' ]
            G.addRule 'prodquo', [ 'prodquo', /[*/]/, 'atomic' ]
            G.addRule 'sumdiff', [ 'prodquo' ]
            G.addRule 'sumdiff', [ 'sumdiff', /[+-]/, 'prodquo' ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            G.setOption 'expressionBuilder', ( expr ) ->
                if expr[0] is '(' and expr[2] is ')' and expr.length is 3
                    expr[1]
                else
                    expr
            expect( G.parse T.tokenize 'ident-7.8/other' ).toEqual \
                [ [ 'ident', '-', [ '7.8', '/', 'other' ] ] ]
            expect( G.parse T.tokenize 'ident*7.8/other' ).toEqual \
                [ [ [ 'ident', '*', '7.8' ], '/', 'other' ] ]
            expect( G.parse T.tokenize 'ident*(7.8/other)' ).toEqual \
                [ [ 'ident', '*', [ '7.8', '/', 'other' ] ] ]

### should be connectable using a parser option

We can set the tokenizer as an option on the parser and thus not have to
manually call the `tokenize` function.  It should be called automatically
for us.  Thus this test is exactly like the previous, except we just call
`G.parse` in each test, and verify that tokenization must therefore be
happening automatically.

        it 'should be connectable using a parser option', ->
            T = new Tokenizer
            T.addType /\s/, -> null
            T.addType /[a-zA-Z_][a-zA-Z_0-9]*/
            T.addType /\.[0-9]+|[0-9]+\.?[0-9]*/
            T.addType /"(?:[^\\"]|\\\\|\\")*"/
            T.addType /[()+/*-]/
            G = new Grammar 'expr'
            G.addRule 'expr', 'sumdiff'
            G.addRule 'atomic', /[a-zA-Z_][a-zA-Z_0-9]*/
            G.addRule 'atomic', /\.[0-9]+|[0-9]+\.?[0-9]*/
            G.addRule 'atomic', /"(?:[^\\"]|\\\\|\\")*"/
            G.addRule 'atomic', [ /\(/, 'sumdiff', /\)/ ]
            G.addRule 'prodquo', [ 'atomic' ]
            G.addRule 'prodquo', [ 'prodquo', /[*\/]/, 'atomic' ]
            G.addRule 'sumdiff', [ 'prodquo' ]
            G.addRule 'sumdiff', [ 'sumdiff', /[+-]/, 'prodquo' ]
            G.setOption 'addCategories', no
            G.setOption 'collapseBranches', yes
            G.setOption 'expressionBuilder', ( expr ) ->
                if expr[0] is '(' and expr[2] is ')' and expr.length is 3
                    expr[1]
                else
                    expr
            G.setOption 'tokenizer', T
            expect( G.parse 'ident-7.8/other' ).toEqual \
                [ [ 'ident', '-', [ '7.8', '/', 'other' ] ] ]
            expect( G.parse 'ident*7.8/other' ).toEqual \
                [ [ [ 'ident', '*', '7.8' ], '/', 'other' ] ]
            expect( G.parse 'ident*(7.8/other)' ).toEqual \
                [ [ 'ident', '*', [ '7.8', '/', 'other' ] ] ]

## A larger, useful grammar

This section creates and tests a grammar for parsing the output of the
`mathQuillToMeaning` function defined in
[setup.litcoffee](../app/setup.litcoffee).  It can be any of a wide variety
of common mathematical expressions supported by MathQuill, and converted to
string representation by `mathQuillToMeaning`.

The sample inputs used in the tests below were either manually captured from
a test run of `mathQuillToMeaning` from the JavaScript console in the main
app itself, or a natural modification of such data.  They are therefore
realistic.

    describe 'A larger, useful grammar', ->

Here we define the grammar.

        G = null
        beforeEach ->
            G = new Grammar 'expression'

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

Rules for plus, minus, times, and divide:

            G.addRule 'prodquo', 'atomic'
            G.addRule 'prodquo', [ 'prodquo', /[÷×·]/, 'atomic' ]
            G.addRule 'prodquo', [ /-/, 'prodquo' ]
            G.addRule 'sumdiff', 'prodquo'
            G.addRule 'sumdiff', [ 'sumdiff', /[+-]/, 'prodquo' ]

Rules for various structures, like fractions, which are treated indivisibly,
and thus as if they were atomics:

            G.addRule 'fraction',
                [ /fraction/, /\(/, 'expression', 'expression', /\)/ ]
            G.addRule 'atomic', 'fraction'

Rule for groupers:

            G.addRule 'atomic', [ /\(/, 'expression', /\)/ ]

And finally, place "expression" at the top of the grammar:

            G.addRule 'expression', 'sumdiff'

A function that recursively assembles OpenMath nodes from the hierarchy of
arrays created by the parser:

            G.setOption 'expressionBuilder', ( expr ) ->
                symbols =
                    '+' : OM.symbol 'plus', 'arith1'
                    '-' : OM.symbol 'minus', 'arith1'
                    '×' : OM.symbol 'times', 'arith1'
                    '·' : OM.symbol 'times', 'arith1'
                    '÷' : OM.symbol 'divide', 'arith1'
                    '∞' : OM.symbol 'infinity', 'nums1'
                result = switch expr[0]
                    when 'digit', 'nonnegint' then expr[1..].join ''
                    when 'integer'
                        OM.integer parseInt expr[1..].join ''
                    when 'float'
                        intvalue = OM.decode( expr[1] ).value
                        fullvalue = parseFloat \
                            "#{intvalue}#{expr[2..].join ''}"
                        OM.float fullvalue
                    when 'variable' then OM.variable expr[1]
                    when 'infinity' then symbols[expr[1]]
                    when 'sumdiff', 'prodquo'
                        switch expr.length
                            when 4 then OM.application symbols[expr[2]],
                                OM.decode( expr[1] ), OM.decode( expr[3] )
                            when 3 then OM.application symbols[expr[1]],
                                OM.decode expr[2]
                            else expr[1]
                    when 'fraction'
                        OM.application symbols['÷'],
                            OM.decode( expr[3] ), OM.decode( expr[4] )
                    when 'atomic'
                        if expr.length is 4 and expr[1] is '(' and \
                           expr[3] is ')' then expr[2] else expr[1]
                    else expr[1]
                if result instanceof OMNode then result = result.encode()
                # console.log JSON.stringify( expr ), '--->', result
                result

### should parse numbers

        it 'should parse numbers', ->

An integer first (which also counts as a float):

            input = '1 0 0'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.integer 100 ).toBeTruthy()

A floating point value second:

            input = '3 . 1 4 1 5 9'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple '3.14159' ).toBeTruthy()

Let's pretend infinity is a number, and include it in this test.

            input = [ '∞' ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'nums1.infinity' ).toBeTruthy()

### should parse variables

        it 'should parse variables', ->

Roman letters, upper and lower case:

            input = [ "x" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'x' ).toBeTruthy()
            input = [ "R" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'R' ).toBeTruthy()

Greek letters:

            input = [ "α" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'α' ).toBeTruthy()
            input = [ "π" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'π' ).toBeTruthy()

### should parse simple arithmetic expressions

By this, we mean sums, differences, products, and quotients.

        it 'should parse simple arithmetic expressions', ->

Try one of each operation in isolation:

            input = '6 + k'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.plus(6,k)' ).toBeTruthy()
            node = OM.decode output[1]
            input = '1 . 9 - T'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.minus(1.9,T)' ) \
                .toBeTruthy()
            input = '0 . 2 · 0 . 3'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.times(0.2,0.3)' ) \
                .toBeTruthy()
            input = 'v ÷ w'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.divide(v,w)' ) \
                .toBeTruthy()

Now try same-precedence operators in sequence, and ensure that they
left-associate.

            input = '5 . 0 - K + e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.minus(5.0,K),e)' ).toBeTruthy()
            input = '5 . 0 × K ÷ e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.times(5.0,K),e)' ).toBeTruthy()

Now try different-precendence operators in combination, and ensure that
precedence is respected.

            input = '5 . 0 - K · e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(5.0,arith1.times(K,e))' ).toBeTruthy()
            input = '5 . 0 × K + e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.times(5.0,K),e)' ).toBeTruthy()

Verify that unary negation works.

            input = '- 7'.split ' '
            output = G.parse input
            console.log output
            expect( output.length ).toBe 2
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple '-7' ).toBeTruthy()
            node = OM.decode output[1]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.minus(7)' ).toBeTruthy()
            input = 'A + - B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(A,arith1.minus(B))' ).toBeTruthy()
            input = '- A + B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.minus(A),B)' ).toBeTruthy()

### should respect parentheses

That is, we can override precedence using parentheses, and the correct
expression trees are created.

        it 'should respect parentheses', ->

First, verify that a chain of sums left-associates.

            input = '6 + k + 5'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.plus(6,k),5)' ).toBeTruthy()

Now verify that we can override that with parentheses.

            input = '6 + ( k + 5 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(6,arith1.plus(k,5))' ).toBeTruthy()

And verify that parentheses override precedence as well.  Contrast the
following tests to those at the end of the previous section, which tested
the default precendence of these operators.

            input = '( 5 . 0 - K ) · e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(arith1.minus(5.0,K),e)' ).toBeTruthy()
            input = '5 . 0 × ( K + e )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(5.0,arith1.plus(K,e))' ).toBeTruthy()
            input = '- ( K + e )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(arith1.plus(K,e))' ).toBeTruthy()

### should support fractions

Fractions come as text of the form "fraction ( N D )" where N and D are the
numerator and denominator expressions respectively.

        it 'should support fractions', ->

Let's begin with fractions of atomics.

            input = 'fraction ( 1 2 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(1,2)' ).toBeTruthy()
            input = 'fraction ( p q )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(p,q)' ).toBeTruthy()

Now we'll try fractions of larger things

            input = 'fraction ( ( 1 + t ) 3 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(1,t),3)' ).toBeTruthy()
            input = 'fraction ( ( a + b ) ( a - b ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(a,b),arith1.minus(a,b))' ) \
                .toBeTruthy()

And lastly we verify that parsing takes place correctly inside the
numerator and denominator of fractions.

            input = 'fraction ( ( 1 + 2 × v ) ( - w ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = OM.decode output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(1,arith1.times(2,v)),' + \
                'arith1.minus(w))' ).toBeTruthy()
