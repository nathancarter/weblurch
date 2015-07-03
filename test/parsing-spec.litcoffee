
# Tests of the Parsing module

Here we import the module we're about to test.

    { Grammar, Tokenizer } = require '../src/parsing.duo'
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
            G.setOption 'tokenizer', T
            expect( G.parse 'ident-7.8/other' ).toEqual \
                [ [ 'ident', '-', [ '7.8', '/', 'other' ] ] ]
            expect( G.parse 'ident*7.8/other' ).toEqual \
                [ [ [ 'ident', '*', '7.8' ], '/', 'other' ] ]
            expect( G.parse 'ident*(7.8/other)' ).toEqual \
                [ [ 'ident', '*', [ '7.8', '/', 'other' ] ] ]
