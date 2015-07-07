
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
            G = require( '../src/mathquill-parser.solo' ).mathQuillParser

### should parse numbers

        it 'should parse numbers', ->

An integer first (which also counts as a float):

            input = '1 0 0'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.integer 100 ).toBeTruthy()

A floating point value second:

            input = '3 . 1 4 1 5 9'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple '3.14159' ).toBeTruthy()

Let's pretend infinity is a number, and include it in this test.

            input = [ '∞' ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'nums1.infinity' ).toBeTruthy()

### should parse variables

        it 'should parse variables', ->

Roman letters, upper and lower case:

            input = [ "x" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'x' ).toBeTruthy()
            input = [ "R" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'R' ).toBeTruthy()

Greek letters:

            input = [ "α" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'α' ).toBeTruthy()
            input = [ "π" ]
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.variable 'π' ).toBeTruthy()

Subscripted variables:

            input = 'x sub i'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'x(i)' ).toBeTruthy()
            input = 'T sub ( j + k )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'T(arith1.plus(j,k))' ) \
                .toBeTruthy()

### should parse simple arithmetic expressions

By this, we mean sums, differences, products, and quotients.

        it 'should parse simple arithmetic expressions', ->

Try one of each operation in isolation:

            input = '6 + k'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.plus(6,k)' ).toBeTruthy()
            node = output[1]
            input = '1 . 9 - T'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.minus(1.9,T)' ) \
                .toBeTruthy()
            input = '0 . 2 · 0 . 3'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.times(0.2,0.3)' ) \
                .toBeTruthy()
            input = 'v ÷ w'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.divide(v,w)' ) \
                .toBeTruthy()
            input = 'v ± w'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'multiops.plusminus(v,w)' ) \
                .toBeTruthy()
            input = '2 sup k'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.power(2,k)' ) \
                .toBeTruthy()

Now try same-precedence operators in sequence, and ensure that they
left-associate.

            input = '5 . 0 - K + e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.minus(5.0,K),e)' ).toBeTruthy()
            input = '5 . 0 × K ÷ e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.times(5.0,K),e)' ).toBeTruthy()
            input = '( a sup b ) sup c'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.power(arith1.power(a,b),c)' ).toBeTruthy()

Now try different-precendence operators in combination, and ensure that
precedence is respected.

            input = '5 . 0 - K · e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(5.0,arith1.times(K,e))' ).toBeTruthy()
            input = '5 . 0 × K + e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.times(5.0,K),e)' ).toBeTruthy()
            input = 'u sup v × w sup x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(arith1.power(u,v),arith1.power(w,x))' ) \
                .toBeTruthy()

Verify that unary negation works.

            input = '- 7'.split ' '
            output = G.parse input
            expect( output.length ).toBe 2
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple '-7' ).toBeTruthy()
            node = output[1]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.unary_minus(7)' ) \
                .toBeTruthy()
            input = 'A + - B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(A,arith1.unary_minus(B))' ).toBeTruthy()
            input = '- A + B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.unary_minus(A),B)' ).toBeTruthy()
            input = '- A sup B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.unary_minus(arith1.power(A,B))' ).toBeTruthy()

### should respect parentheses

That is, we can override precedence using parentheses, and the correct
expression trees are created.

        it 'should respect parentheses', ->

First, verify that a chain of sums left-associates.

            input = '6 + k + 5'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.plus(6,k),5)' ).toBeTruthy()

Now verify that we can override that with parentheses.

            input = '6 + ( k + 5 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(6,arith1.plus(k,5))' ).toBeTruthy()

And verify that parentheses override precedence as well.  Contrast the
following tests to those at the end of the previous section, which tested
the default precendence of these operators.

            input = '( 5 . 0 - K ) · e'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(arith1.minus(5.0,K),e)' ).toBeTruthy()
            input = '5 . 0 × ( K + e )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(5.0,arith1.plus(K,e))' ).toBeTruthy()
            input = '- ( K + e )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.unary_minus(arith1.plus(K,e))' ).toBeTruthy()
            input = '- ( A sup B )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.unary_minus(arith1.power(A,B))' ).toBeTruthy()

### should support fractions

Fractions come as text of the form "fraction ( N D )" where N and D are the
numerator and denominator expressions respectively.

        it 'should support fractions', ->

Let's begin with fractions of atomics.

            input = 'fraction ( 1 2 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(1,2)' ).toBeTruthy()
            input = 'fraction ( p q )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(p,q)' ).toBeTruthy()

Now we'll try fractions of larger things

            input = 'fraction ( ( 1 + t ) 3 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(1,t),3)' ).toBeTruthy()
            input = 'fraction ( ( a + b ) ( a - b ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(a,b),arith1.minus(a,b))' ) \
                .toBeTruthy()

And lastly we verify that parsing takes place correctly inside the
numerator and denominator of fractions.

            input = 'fraction ( ( 1 + 2 × v ) ( - w ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(arith1.plus(1,arith1.times(2,v)),' + \
                'arith1.unary_minus(w))' ).toBeTruthy()

### should support square roots and nth roots

Square roots come as text of the form "√ E" where E is an expression.
Nth roots come as text of the form "nthroot N √ E" where N is an expression
outside the radical (the N in Nth root) and E is the expression whose root
is being expressed.  For example, the third root of x is "nthroot 3 √ x".

        it 'should support square roots and nth roots', ->

First, square roots of simple expressions.

            input = '√ 2'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.root(2,2)' ).toBeTruthy()
            input = '√ ( 1 0 - k + 9 . 6 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.root(arith1.plus(arith1.minus(10,k),9.6),2)' ) \
                .toBeTruthy()

Second, nth roots of simple expressions.

            input = 'nthroot p √ 2'.split ' '
            output = G.parse input

            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.root(2,p)' ).toBeTruthy()
            input = 'nthroot 5 0 √ ( 1 0 - k + 9 . 6 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.root(arith1.plus(arith1.minus(10,k),9.6),50)' ) \
                .toBeTruthy()

Next, square roots of fractions and of other roots, and placed in context.

            input = 'fraction ( 6 √ fraction ( 1 2 ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(6,arith1.root(arith1.divide(1,2),2))' ) \
                .toBeTruthy()
            input = '√ ( 1 + √ 5 ) + 1'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.root(arith1.plus(' + \
                '1,arith1.root(5,2)),2),1)' ).toBeTruthy()

Finally, nth roots containing more complex expressions.

            input = 'nthroot ( 2 + t ) √ ( 1 ÷ ∞ )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.root(arith1.divide(1,nums1.infinity),' + \
                'arith1.plus(2,t))' ).toBeTruthy()

### should support logarithms of all types

This includes natural logarithms, "ln x", logarithms with an assumed base
10, "log x", and logarithms with an explicit base, "log sub 2 8".

        it 'should support logarithms of all types', ->

Natural logarithms of a simple thing and a larger thing.

            input = 'ln x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'transc1.ln(x)' ).toBeTruthy()
            input = 'ln fraction ( 2 ( x + 1 ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'transc1.ln(arith1.divide(2,arith1.plus(x,1)))' ) \
                .toBeTruthy()

Logarithms with an implied base 10, of a simple thing and a larger thing.

            input = 'log 1 0 0 0'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'transc1.log(10,1000)' ) \
                .toBeTruthy()
            input = 'log ( e sup x × y )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'transc1.log(10,arith1.times(arith1.power(e,x),y))' ) \
                .toBeTruthy()

Logarithms with an explicit base, of a simple thing and a larger thing.

            input = 'log sub ( 3 1 ) 6 5'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'transc1.log(31,65)' ) \
                .toBeTruthy()
            input = 'log sub ( - t ) ( k + 5 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'transc1.log(arith1.unary_minus(t),arith1.plus(k,5))' ) \
                .toBeTruthy()

### should support sentences

Sentences are formed by using relations (such as equality or less than) to
connect two nouns, or by negating existing sentences.

        it 'should support sentences', ->

First, relations among nouns.

            input = '2 < 3'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.lt(2,3)' ).toBeTruthy()
            input = '- 6 > k'.split ' '
            output = G.parse input
            expect( output.length ).toBe 2
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.gt(-6,k)' ).toBeTruthy()
            node = output[1]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.gt(arith1.unary_minus(6),k)' ).toBeTruthy()
            input = 't + u = t + v'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.eq(arith1.plus(t,u),arith1.plus(t,v))' ) \
                .toBeTruthy()
            input = 't + u = t + v'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.eq(arith1.plus(t,u),arith1.plus(t,v))' ) \
                .toBeTruthy()

            input = 't + u ≠ t + v'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.neq(arith1.plus(t,u),arith1.plus(t,v))' ) \
                .toBeTruthy()
            input = 'fraction ( a ( 7 + b ) ) ≈ 0 . 7 5'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.approx(arith1.divide(' + \
                'a,arith1.plus(7,b)),0.75)' ).toBeTruthy()
            input = 't sup 2 ≤ 1 0'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.le(arith1.power(t,2),10)' ).toBeTruthy()
            input = '1 + 2 + 3 ≥ 6'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'relation1.ge(arith1.plus(arith1.plus(1,2),3),6)' ) \
                .toBeTruthy()
            input = 'k ≃ l'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'integer2.modulo_relation(k,l)' ) \
                .toBeTruthy()

Second, sentences with a "therefore" at the front.

            input = '∴ 1 < 2'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'relation1.lt(1,2)' ).toBeTruthy()

Finally, sentences that are negated.

            input = '¬ A + B = C sup D'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'logic1.not(relation1.eq(arith1.plus(A,B),' + \
                'arith1.power(C,D)))' ).toBeTruthy()
            input = '¬ ¬ x = x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'logic1.not(logic1.not(relation1.eq(x,x)))' ).toBeTruthy()

### should support units

Units are formed by multiplying a value by the symbol for "degrees,"
"dollars," or "percent."  These are not symbols in any official OpenMath
content dictionary, but are supported by MathQuill, so I include symbols
for them here.

        it 'should support units', ->

            input = '1 0 0 %'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(100,units.percent)' ).toBeTruthy()
            input = '$ ( d + 5 0 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(arith1.plus(d,50),units.dollars)' ) \
                .toBeTruthy()
            input = '4 5 sup ∘'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(45,units.degrees)' ).toBeTruthy()

### should support decorations (overline, overarc)

These use nonstandard symbols and apply them like functions to the
expression with the arc or line over it.

        it 'should support decorations (overline, overarc)', ->

            input = 'overline ( x )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'decoration.overline(x)' ).toBeTruthy()
            input = 'overarc ( 6 - fraction ( e 3 ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'decoration.overarc(arith1.minus(6,arith1.divide(e,3)))' ) \
                .toBeTruthy()

### should support intervals of all four types

There are intervals of the form (a,b), (a,b], [a,b), and [a,b].  All four
should be supported, and none should get confused with parentheses nearby.

        it 'should support intervals of all four types', ->

First, just some simple tests with easy contents.

            input = '( 1 , 2 ]'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_oc(1,2)' ).toBeTruthy()
            input = '( t , k )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_oo(t,k)' ).toBeTruthy()
            input = '[ I , J ]'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_cc(I,J)' ).toBeTruthy()
            input = '[ 3 0 , 5 2 . 9 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_co(30,52.9)' ).toBeTruthy()

Now tests that are trickier because of intervals near other intervals, or
intervals within intervals, or parentheses in or around intervals.

            input = '( 4 × ( t + u ) , 2 sup 9 ]'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_oc(' + \
                'arith1.times(4,arith1.plus(t,u)),' + \
                'arith1.power(2,9))' ).toBeTruthy()
            input = '( 3 - [ 1 , 2 ] ) × 4'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(arith1.minus(3,' + \
                'interval1.interval_cc(1,2)),4)' ).toBeTruthy()
            input = '[ ( 2 , 3 ] , ( j , j + 1 ] )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'interval1.interval_co(' + \
                'interval1.interval_oc(2,3),' + \
                'interval1.interval_oc(j,arith1.plus(j,1)))' ).toBeTruthy()

### should support absolute values

These can be tricky because the left and right edges are indistinguishable.

        it 'should support absolute values', ->

First, absolute values of atomics.

            input = '| a |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.abs(a)' ).toBeTruthy()
            input = '| - 9 6 2 |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 2
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.abs(-962)' ).toBeTruthy()
            node = output[1]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.abs(arith1.unary_minus(962))' ).toBeTruthy()

Second, absolute values of some expressions.

            input = '| fraction ( ( a sup b ) 1 0 ) |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.abs(arith1.divide(arith1.power(a,b),10))' ) \
                .toBeTruthy()
            input = '| 9 - 8 + 7 - 6 |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.abs(arith1.minus(arith1.plus(arith1.minus(' + \
                '9,8),7),6))' ).toBeTruthy()

Finally, multiple absolute values in the same expression.

            input = '| 6 + r | - | 6 - r |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(arith1.abs(arith1.plus(6,r)),' + \
                'arith1.abs(arith1.minus(6,r)))' ).toBeTruthy()
            input = '| fraction ( ( | x | ) x ) |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.abs(arith1.divide(arith1.abs(x),x))' ).toBeTruthy()
            input = '| | 1 | + | 1 | |'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.abs(arith1.plus(arith1.abs(1),arith1.abs(1)))' ) \
                .toBeTruthy()

### should support trigonometric functions and inverses

        it 'should support trigonometric functions and inverses', ->

Simple application of a few of the trig functions and/or inverse trig
functions.

            input = 'sin x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'transc1.sin(x)' ).toBeTruthy()
            input = 'tan π'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.app OM.sym( 'tan', 'transc1' ),
                OM.var 'π' ).toBeTruthy()
            input = 'sec sup ( - 1 ) 0'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'transc1.arcsec(0)' ).toBeTruthy()

Now place them inside expressions, or expressions inside them, or both.

            input = 'cos x + 1'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(transc1.cos(x),1)' ).toBeTruthy()
            input = 'cot ( a - 9 . 9 )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'transc1.cot(arith1.minus(a,9.9))' ).toBeTruthy()
            input = '| csc sup ( - 1 ) ( 1 + g ) | sup 2'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.power(arith1.abs(transc1.arccsc(' + \
                'arith1.plus(1,g))),2)' ).toBeTruthy()

### should support factorials

        it 'should support factorials', ->

            input = '1 0 !'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'integer1.factorial(10)' ) \
                .toBeTruthy()
            input = 'W × R !'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(W,integer1.factorial(R))' ).toBeTruthy()
            input = '( W + R ) !'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'integer1.factorial(arith1.plus(W,R))' ).toBeTruthy()

### should support limits

We only support limits of one variable as it goes to a specific value.  We
follow the convention given
[for this OpenMath symbol](http://www.openmath.org/cd/limit1.xhtml#limit).

        it 'should support limits', ->
            input = 'lim sub ( x → t sub 0 ) sin x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'limit1.limit(t(0),limit1.both_sides,' + \
                'fns1.lambda[x,transc1.sin(x)])' ).toBeTruthy()
            input = '3 × lim sub ( a → 1 ) fraction ( a 1 ) + 9'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.times(3,limit1.limit(1,' + \
                'limit1.both_sides,fns1.lambda[a,arith1.divide(a,1)])),9)' \
                ).toBeTruthy()

### should support limits

We only support sums of one variable between two specific values.  We
follow the convention given
[for this OpenMath symbol](http://www.openmath.org/cd/arith1.xhtml#sum).

        it 'should support sums', ->
            input = 'Σ sub ( x = 1 ) sup 5 x sup 2'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.sum(interval1.interval(1,5),' + \
                'fns1.lambda[x,arith1.power(x,2)])' ).toBeTruthy()
            input = 'Σ sup ( n + 1 ) sub ( m = 0 ) m - 1'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'arith1.minus(arith1.sum(' + \
                'interval1.interval(0,arith1.plus(n,1)),' + \
                'fns1.lambda[m,m]),1)' ).toBeTruthy()

### should support differential and integral calculus

        it 'should support differential and integral calculus', ->

Differentials are d followed by a variable:

            input = 'd x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'diff.d(x)' ).toBeTruthy()
            input = 'd Q'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple 'diff.d(Q)' ).toBeTruthy()

Differential fractions are like d/dx (i.e., d over d times a variable):

            input = 'fraction ( d ( d x ) )'.split ' '
            output = G.parse input
            expect( output.length ).toBe 2
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(diff.d,diff.d(x))' ).toBeTruthy()
            node = output[1]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(d,diff.d(x))' ).toBeTruthy()

Indefinite integrals:

            input = '∫ x sup 2 · d x'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.int(arith1.times(arith1.power(x,2),' + \
                'diff.d(x)))' ).toBeTruthy()
            input = '∫ ( fraction ( x k ) - 1 0 ) · d k'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.int(arith1.times(arith1.minus(' + \
                'arith1.divide(x,k),10),diff.d(k)))' ).toBeTruthy()

Definite integrals:

            input = '∫ sub 0 sup 2 ( s + t ) · d t'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.defint(0,2,arith1.times(arith1.plus(s,t),' + \
                'diff.d(t)))' ).toBeTruthy()
            input = '∫ sup b sub a | x - 1 | · d x' \
                .split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.defint(a,b,arith1.times(arith1.abs(' + \
                'arith1.minus(x,1)),diff.d(x)))' ).toBeTruthy()

### should read arithmetic around limit-like things correctly

For instance, if we see ∫ A · B, we know that the B is inside the integral,
but if we see ∫ A + B, we know that the B is outside the integral.  And yet
on the left side, as in B · ∫ A or B + ∫ A, both are outside the integral.
We test here to be sure that this distincion is parsed correctly.  These
same tests must also pass for limits and summations, and for quotients and
differences.

        it 'should read arithmetic around limit-like things correctly', ->

We test all the possible combinations regarding integrals first.

Multiplication:

            input = '∫ A · B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.int(arith1.times(A,B))' ).toBeTruthy()
            input = 'B · ∫ A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(B,calculus1.int(A))' ).toBeTruthy()

Division:

            input = '∫ A ÷ B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'calculus1.int(arith1.divide(A,B))' ).toBeTruthy()
            input = 'B ÷ ∫ A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(B,calculus1.int(A))' ).toBeTruthy()

Addition:

            input = '∫ A + B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(calculus1.int(A),B)' ).toBeTruthy()
            input = 'B + ∫ A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(B,calculus1.int(A))' ).toBeTruthy()

Subtraction:

            input = '∫ A - B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(calculus1.int(A),B)' ).toBeTruthy()
            input = 'B - ∫ A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(B,calculus1.int(A))' ).toBeTruthy()

Repeat all the previous tests, but now for limits.

Multiplication:

            input = 'lim sub ( x → t ) A · B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,arith1.times(A,B)])' ).toBeTruthy()
            input = 'B · lim sub ( x → t ) A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(B,limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Division:

            input = 'lim sub ( x → t ) A ÷ B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,arith1.divide(A,B)])' ).toBeTruthy()
            input = 'B ÷ lim sub ( x → t ) A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(B,limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Addition:

            input = 'lim sub ( x → t ) A + B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]),B)' ).toBeTruthy()
            input = 'B + lim sub ( x → t ) A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(B,limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Subtraction:

            input = 'lim sub ( x → t ) A - B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]),B)' ).toBeTruthy()
            input = 'B - lim sub ( x → t ) A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(B,limit1.limit(t,limit1.both_sides,' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Repeat all the previous tests, but now for summations.

Multiplication:

            input = 'Σ sub ( x = 1 ) sup 3 A · B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,arith1.times(A,B)])' ).toBeTruthy()
            input = 'B · Σ sub ( x = 1 ) sup 3 A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.times(B,arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Division:

            input = 'Σ sub ( x = 1 ) sup 3 A ÷ B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,arith1.divide(A,B)])' ).toBeTruthy()
            input = 'B ÷ Σ sub ( x = 1 ) sup 3 A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.divide(B,arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Addition:

            input = 'Σ sub ( x = 1 ) sup 3 A + B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]),B)' ).toBeTruthy()
            input = 'B + Σ sub ( x = 1 ) sup 3 A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.plus(B,arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()

Subtraction:

            input = 'Σ sub ( x = 1 ) sup 3 A - B'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]),B)' ).toBeTruthy()
            input = 'B - Σ sub ( x = 1 ) sup 3 A'.split ' '
            output = G.parse input
            expect( output.length ).toBe 1
            node = output[0]
            expect( node instanceof OMNode ).toBeTruthy()
            expect( node.equals OM.simple \
                'arith1.minus(B,arith1.sum(interval1.interval(1,3),' + \
                'fns1.lambda[x,A]))' ).toBeTruthy()
