python
# Definitions for the Sidebar Example App

The main file for the app is located [here](sidebar-example-solo.litcoffee).

This file contains the definitions of code forms and categories as well as
their validation functions, plus translation routines for various languages.

## Registering basic code forms and categories

    registerCategory 'Data', [
        registerCodeForm 'Variable', ( group, verbose ) ->
            variableRE = /^[a-zA-Z_][a-zA-Z_0-9]*$/
            if variableRE.test group.contentAsText()
                result : 'valid'
                message : 'This is a valid variable name.'
            else
                result : 'invalid'
                message : 'This is not a valid variable name.'
                verbose : 'It must begin with a Roman letter or an
                    underscore, and contain only Roman letters, underscores,
                    or Arabic digits.'
        registerCodeForm 'Number', ( group, verbose ) ->
            numberRE = /^[+-]?([0-9]+\.[0-9]*|[0-9]*\.?[0-9]+)$/
            if numberRE.test group.contentAsText()
                result : 'valid'
                message : 'This is a valid number.'
            else
                result : 'invalid'
                message : 'This is not a valid number.'
                verbose : 'Numbers may contain only Arabic digits and one
                    optional decimal point, plus optionally a leading + or
                    - sign.'
        registerCodeForm 'Text', ( group, verbose ) ->
            if group.children.length > 0
                result : 'invalid'
                message : 'Text data cannot have any inner structure.'
                verbose : 'This text data has at least one inner structure,
                    but it should be just text.  Remove the inner
                    structures to fix this problem.'
            else
                result : 'valid'
                message : 'This is valid text.'
    ]
    registerCategory 'Simple actions', [
        registerCodeForm 'Store a value',
            [ 'Variable', 'Number/Text/Mathematical expression' ]
        registerCodeForm 'Pick a random integer',
            [ 'Number/Variable', 'Number/Variable' ]
        registerCodeForm 'Mathematical expression', ( group, verbose ) ->
            meaning = mathQuillToOpenMath group
            if meaning not instanceof window.OMNode
                return result : 'invalid', message : meaning
            result : 'valid'
            message : 'This is a valid mathematical expression'
            openmath : meaning.encode()
    ]
    registerCategory 'Input/Output', [
        registerCodeForm 'Display a value',
            [ 'Number/Variable/Text/Mathematical expression' ]
        registerCodeForm 'Request a value from the user',
            [ 'Variable/Text', 'Variable/Text' ]
    ]
    registerCategory 'Control flow', [
        registerCodeForm 'Make a decision', [
            'Variable/Mathematical expression'
            'Store a value/Display a value/Request a value from the user'
            'Store a value/Display a value/Request a value from the user'
        ]
        registerCodeForm 'For each integer in a range', [
            'Variable'
            'Number/Variable'
            'Number/Variable'
            'Store a value/Display a value/Make a decision'
        ]
    ]

## Registering English boilerplate

    registerTranslator 'Variable', 'en', 'example',
        'the variable <Variable>x</Variable>'
    registerTranslator 'Number', 'en', 'example',
        'the number <Number>5</Number>'
    registerTranslator 'Text', 'en', 'example',
        'the text <Text>Hello, World!</Text>'
    registerTranslator 'Mathematical expression', 'en', 'example',
        'the result of <Mathematical
         expression><span class="math">x^2+y^2</span></Mathematical
         expression>'
    registerTranslator 'Store a value', 'en', 'example',
        '<Store a value>Let the variable <Variable>x</Variable>
         have the value <Number>3</Number>.</Store a value>'
    registerTranslator 'Pick a random integer', 'en', 'example',
        '<Pick a random integer>a random integer between <Number>1</Number>
         and <Number>10</Number> (inclusive)</Pick a random integer>'
    registerTranslator 'Display a value', 'en', 'example',
        '<Display a value>Display the value of <Variable>x</Variable> to the
         user.</Display a value>'
    registerTranslator 'Request a value from the user', 'en', 'example',
        '<Request a value from the user>Prompt the user for the value of the
         variable <Variable>N</Variable>, by saying <Text>What\'s your
         name?</Text> and providing the default value of <Text>John</Text>
         (if the interface supports default
         values).</Request a value from the user>'
    registerTranslator 'Make a decision', 'en', 'example',
        '<Make a decision>Check to see if <Variable>P</Variable> is true.
         <br>If so, do this: <Store a value>Let <Variable>x</Variable> be
         the number <Number>100</Number>.</Store a value>
         <br>If not, do this: <Store a value>Let <Variable>y</Variable> be
         the text <Text>Hello</Text>.</Store a value></Make a decision>'
    registerTranslator 'For each integer in a range', 'en', 'example',
        '<For each integer in a range>Let <Variable>i</Variable> count from
         <Number>1</Number> to <Number>5</Number>, and each step of the
         way, <Display a value>show the user the value of <Mathematical
         expression><span class="math">\\frac{i^2}{2}</span></Mathematical
         expression></Display a value>.</For each integer in a range>'

## Registering English translation

    registerTranslator 'Variable', 'en', 'explanation', ( group ) ->
        "the value of the variable #{group.contentAsText().trim()}"
    registerTranslator 'Number', 'en', 'explanation', ( group ) ->
        "the number #{group.contentAsText().trim()}"
    registerTranslator 'Text', 'en', 'explanation', ( group ) ->
        escaped = group.contentAsText().replace /&/g, '&amp;'
        .replace /</g, '&lt;'
        .replace />/g, '&gt;'
        .replace /"/g, '&quot;'
        .replace /'/g, '&apos;'
        "the text <b>#{escaped}</b>"
    registerTranslator 'Mathematical expression', 'en', 'explanation',
    ( group ) ->
        "the result of #{group.contentAsHTML()}"
    registerTranslator 'Store a value', 'en', 'explanation',
        'Let __A__ be __B__.'
    registerTranslator 'Pick a random integer', 'en', 'explanation',
        'a random integer between __A__ and __B__ (inclusive)'
    registerTranslator 'Display a value', 'en', 'explanation',
        'Display __A__ to the user.'
    registerTranslator 'Request a value from the user', 'en', 'explanation',
        'Prompt the user for the value of __A__, providing __B__ as the
         default value, if the interface supports that.'
    registerTranslator 'Make a decision', 'en', 'explanation',
        'If __A__ is true, then do this:
         <ul><li>__B__</li></ul>
         Otherwise, do this:
         <ul><li>__C__</li></ul>'
    registerTranslator 'For each integer in a range', 'en', 'explanation',
        'While __A__ counts from __B__ to __C__ (inclusive), do:
         <ul><li>__D__</li></ul>'
    registerTranslator 'COMMENT', 'en', 'explanation', 'Note: __A__'

## Registering JavaScript translation

    registerTranslator 'Variable', 'javascript', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Number', 'javascript', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Text', 'javascript', 'code', ( group ) ->
        escaped = group.contentAsText()
            .replace /\\/g, '\\\\'
            .replace /"/g, '\\"'
            .replace /\n/g, '\\n'
        "\"#{escaped}\""
    registerTranslator 'Mathematical expression', 'javascript', 'code',
    ( group ) ->
        openmath = window.OMNode.decode \
            group.get( 'validationResult' ).openmath
        if openmath not instanceof window.OMNode
            "undefined /* #{openmath} */" # includes failure reason
        else
            openmath.toJavaScript()
    registerTranslator 'Store a value', 'javascript', 'code',
        '__A__ = __B__;'
    registerTranslator 'Pick a random integer', 'javascript', 'code',
        '( Math.random() * ( __B__ - ( __A__ ) ) + __A__ ) | 0'
    registerTranslator 'Display a value', 'javascript', 'code',
        'alert( __A__ );'
    registerTranslator 'Request a value from the user', 'javascript',
        'code', 'prompt( __A__, __B__ )'
    registerTranslator 'Make a decision', 'javascript', 'code',
        'if ( __A__ ) {\n  __B__\n} else {\n  __C__\n}'
    registerTranslator 'For each integer in a range', 'javascript', 'code',
        'for ( var __A__ = __B__ ; __A__ <= __C__ ; __A__++ ) {\n  __D__\n}'
    registerTranslator 'COMMENT', 'javascript', 'code', '// __A__'

## Registering Python translation

These translations assume the code begins with `import math` and
`import random`.

    registerTranslator 'Variable', 'python', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Number', 'python', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Text', 'python', 'code', ( group ) ->
        escaped = group.contentAsText()
            .replace /\\/g, '\\\\'
            .replace /"/g, '\\"'
            .replace /\n/g, '\\n'
        "\"#{escaped}\""
    registerTranslator 'Mathematical expression', 'python', 'code',
    ( group ) ->
        openmath = window.OMNode.decode \
            group.get( 'validationResult' ).openmath
        if openmath not instanceof window.OMNode
            'None'
        else
            openmath.toPython()
    registerTranslator 'Store a value', 'python', 'code',
        '__A__ = __B__'
    registerTranslator 'Pick a random integer', 'python', 'code',
        'random.randint( __B__, __A__ )'
    registerTranslator 'Display a value', 'python', 'code',
        'print __A__'
    registerTranslator 'Request a value from the user', 'python',
        'code', 'raw_input( __A__ )'
    registerTranslator 'Make a decision', 'python', 'code',
        'if __A__:\n  __B__\nelse:\n  __C__'
    registerTranslator 'For each integer in a range', 'python', 'code',
        'for __A__ in range( __B__, __C__ + 1 ):\n  __D__'
    registerTranslator 'COMMENT', 'python', 'code', '# __A__'

## Registering R translation

    registerTranslator 'Variable', 'r', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Number', 'r', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Text', 'r', 'code', ( group ) ->
        escaped = group.contentAsText()
            .replace /\\/g, '\\\\'
            .replace /"/g, '\\"'
            .replace /\n/g, '\\n'
        "\"#{escaped}\""
    registerTranslator 'Mathematical expression', 'r', 'code',
    ( group ) ->
        openmath = window.OMNode.decode \
            group.get( 'validationResult' ).openmath
        if openmath not instanceof window.OMNode
            'NULL'
        else
            openmath.toR()
    registerTranslator 'Store a value', 'r', 'code',
        '__A__ <- __B__'
    registerTranslator 'Pick a random integer', 'r', 'code',
        'sample( (__A__):(__B__), 1 )'
    registerTranslator 'Display a value', 'r', 'code',
        'print( __A__ )'
    registerTranslator 'Request a value from the user', 'r', 'code',
        'readline( __A__ )'
    registerTranslator 'Make a decision', 'r', 'code',
        'if ( __A__ ) {\n  __B__\n} else {\n  __C__\n}'
    registerTranslator 'For each integer in a range', 'r', 'code',
        'for ( __A__ in (__B__):(__C__) ) {\n  __D__\n}'
    registerTranslator 'COMMENT', 'r', 'code', '# __A__'

## Utilities used in the functions above

Functions for converting OpenMath data structures into code that computes
them, in various languages.

    OM::toJavaScript = ->
        special = ( func ) =>
            func ( child.toJavaScript() for child in @children[1...] )...
        infix = ( op ) => special ( code... ) -> code.join op
        prefix = ( op ) => special ( code... ) -> "#{op}(#{code.join ','})"
        result = switch @type
            when 'i', 'f', 'st', 'ba' then "#{@value}"
            when 'v' then switch @name
                when '\u03c0' then 'Math.PI' # pi
                when 'e' then 'Math.exp(1)'
                else @name
            when 'sy' then switch @simpleEncode()
                when 'units.degrees' then '(Math.PI/180)'
                when 'units.percent' then '0.01'
                when 'units.dollars' then '1'
            when 'a' then switch @children[0].simpleEncode()
                when 'arith1.plus' then infix '+'
                when 'arith1.minus' then infix '-'
                when 'arith1.times' then infix '*'
                when 'arith1.divide' then infix '/'
                when 'arith1.power' then prefix 'Math.pow'
                when 'arith1.root'
                    special ( a, b ) -> "Math.pow(#{b},1/(#{a}))"
                when 'arith1.abs' then prefix 'Math.abs'
                when 'arith1.unary_minus' then prefix '-'
                when 'relation1.eq' then infix '=='
                when 'relation1.approx'
                    special ( a, b ) -> "(Math.abs((#{a})-(#{b}))<0.01)"
                when 'relation1.neq' then infix '!='
                when 'relation1.lt' then infix '<'
                when 'relation1.gt' then infix '>'
                when 'relation1.le' then infix '<='
                when 'relation1.ge' then infix '>='
                when 'logic1.not' then prefix '!'
                when 'transc1.sin' then prefix 'Math.sin'
                when 'transc1.cos' then prefix 'Math.cos'
                when 'transc1.tan' then prefix 'Math.tan'
                when 'transc1.cot'
                    special ( x ) -> "(1/Math.tan(#{x}))"
                when 'transc1.sec'
                    special ( x ) -> "(1/Math.cos(#{x}))"
                when 'transc1.csc'
                    special ( x ) -> "(1/Math.sin(#{x}))"
                when 'transc1.arcsin' then prefix 'Math.asin'
                when 'transc1.arccos' then prefix 'Math.acos'
                when 'transc1.arctan' then prefix 'Math.atan'
                when 'transc1.arccot'
                    special ( x ) -> "Math.atan(1/(#{x}))"
                when 'transc1.arcsec'
                    special ( x ) -> "Math.acos(1/(#{x}))"
                when 'transc1.arccsc'
                    special ( x ) -> "Math.asin(1/(#{x}))"
                when 'transc1.ln' then prefix 'Math.log'
                when 'transc1.log'
                    special ( x ) -> "(Math.log(#{arg})/Math.log(#{base}))"
                # Maybe later I will come back and implement these, but this
                # is just a demo app, so there is no need to get fancy.
                # when 'integer1.factorial'
                # when 'arith1.sum'
                # when 'calculus1.int'
                # when 'calculus1.defint'
                # when 'limit1.limit'
        result ? "undefined /* Could not evaluate #{@simpleEncode()} */"
    OM::toPython = ->
        special = ( func ) =>
            func ( child.toJavaScript() for child in @children[1...] )...
        infix = ( op ) => special ( code... ) -> code.join op
        prefix = ( op ) => special ( code... ) -> "#{op}(#{code.join ','})"
        result = switch @type
            when 'i', 'f', 'st', 'ba' then "#{@value}"
            when 'v' then switch @name
                when '\u03c0' then 'math.pi' # pi
                when 'e' then 'math.exp(1)'
                else @name
            when 'sy' then switch @simpleEncode()
                when 'units.degrees' then '(math.pi/180)'
                when 'units.percent' then '0.01'
                when 'units.dollars' then '1'
            when 'a' then switch @children[0].simpleEncode()
                when 'arith1.plus' then infix '+'
                when 'arith1.minus' then infix '-'
                when 'arith1.times' then infix '*'
                when 'arith1.divide' then infix '/'
                when 'arith1.power' then infix '**'
                when 'arith1.root'
                    special ( a, b ) -> "#{b}**(1/(#{a}))"
                when 'arith1.abs' then prefix 'math.fabs'
                when 'arith1.unary_minus' then prefix '-'
                when 'relation1.eq' then infix '=='
                when 'relation1.approx'
                    special ( a, b ) -> "(math.fabs((#{a})-(#{b}))<0.01)"
                when 'relation1.neq' then infix '!='
                when 'relation1.lt' then infix '<'
                when 'relation1.gt' then infix '>'
                when 'relation1.le' then infix '<='
                when 'relation1.ge' then infix '>='
                when 'logic1.not' then prefix 'not'
                when 'transc1.sin' then prefix 'math.sin'
                when 'transc1.cos' then prefix 'math.cos'
                when 'transc1.tan' then prefix 'math.tan'
                when 'transc1.cot'
                    special ( x ) -> "(1/math.tan(#{x}))"
                when 'transc1.sec'
                    special ( x ) -> "(1/math.cos(#{x}))"
                when 'transc1.csc'
                    special ( x ) -> "(1/math.sin(#{x}))"
                when 'transc1.arcsin' then prefix 'math.asin'
                when 'transc1.arccos' then prefix 'math.acos'
                when 'transc1.arctan' then prefix 'math.atan'
                when 'transc1.arccot'
                    special ( x ) -> "math.atan(1/(#{x}))"
                when 'transc1.arcsec'
                    special ( x ) -> "math.acos(1/(#{x}))"
                when 'transc1.arccsc'
                    special ( x ) -> "math.asin(1/(#{x}))"
                when 'transc1.ln', 'transc1.log' then prefix 'math.log'
                # Maybe later I will come back and implement these, but this
                # is just a demo app, so there is no need to get fancy.
                # when 'integer1.factorial'
                # when 'arith1.sum'
                # when 'calculus1.int'
                # when 'calculus1.defint'
                # when 'limit1.limit'
        result ? 'None'
    OM::toR = ->
        special = ( func ) =>
            func ( child.toJavaScript() for child in @children[1...] )...
        infix = ( op ) => special ( code... ) -> code.join op
        prefix = ( op ) => special ( code... ) -> "#{op}(#{code.join ','})"
        result = switch @type
            when 'i', 'f', 'st', 'ba' then "#{@value}"
            when 'v' then switch @name
                when '\u03c0' then 'pi' # pi
                when 'e' then 'exp(1)'
                else @name
            when 'sy' then switch @simpleEncode()
                when 'units.degrees' then '(pi/180)'
                when 'units.percent' then '0.01'
                when 'units.dollars' then '1'
            when 'a' then switch @children[0].simpleEncode()
                when 'arith1.plus' then infix '+'
                when 'arith1.minus' then infix '-'
                when 'arith1.times' then infix '*'
                when 'arith1.divide' then infix '/'
                when 'arith1.power' then infix '^'
                when 'arith1.root'
                    special ( a, b ) -> "(#{b})^(1/(#{a}))"
                when 'arith1.abs' then prefix 'abs'
                when 'arith1.unary_minus' then prefix '-'
                when 'relation1.eq' then infix '=='
                when 'relation1.approx'
                    special ( a, b ) -> "(abs((#{a})-(#{b}))<0.01)"
                when 'relation1.neq' then infix '!='
                when 'relation1.lt' then infix '<'
                when 'relation1.gt' then infix '>'
                when 'relation1.le' then infix '<='
                when 'relation1.ge' then infix '>='
                when 'logic1.not' then prefix '!'
                when 'transc1.sin' then prefix 'sin'
                when 'transc1.cos' then prefix 'cos'
                when 'transc1.tan' then prefix 'tan'
                when 'transc1.cot'
                    special ( x ) -> "(1/tan(#{x}))"
                when 'transc1.sec'
                    special ( x ) -> "(1/cos(#{x}))"
                when 'transc1.csc'
                    special ( x ) -> "(1/sin(#{x}))"
                when 'transc1.arcsin' then prefix 'asin'
                when 'transc1.arccos' then prefix 'acos'
                when 'transc1.arctan' then prefix 'atan'
                when 'transc1.arccot' then special ( x ) -> "atan(1/(#{x}))"
                when 'transc1.arcsec' then special ( x ) -> "acos(1/(#{x}))"
                when 'transc1.arccsc' then special ( x ) -> "asin(1/(#{x}))"
                when 'transc1.ln', 'transc1.log' then prefix 'log'
                # Maybe later I will come back and implement these, but this
                # is just a demo app, so there is no need to get fancy.
                # when 'integer1.factorial'
                # when 'arith1.sum'
                # when 'calculus1.int'
                # when 'calculus1.defint'
                # when 'limit1.limit'
        result ? 'NULL'

A function for discerning the OpenMath meaning of a group in the document.
Either a string is returned (as an error) or an OMNode instance, as the
meaning.  If the group has anything but exactly one MathQuill instance in it
then an error is returned for that reason.  Other errors are parsing
related.

    mathQuillToOpenMath = ( group ) ->
        nodes = $ group.contentNodes()
        selector = '.mathquill-rendered-math'
        nodes = nodes.find( selector ).add nodes.filter selector
        if nodes.length is 0 then return 'No math expresion found'
        if nodes.length > 1 then return 'Too many math expressions found'
        try
            toParse = window.mathQuillToMeaning nodes.get 0
        catch e
            return "Error reading math expression to text: #{e?.message}"
        try
            parsed = mathQuillParser.parse( toParse )?[0]
        catch e
            return "Error interpreting math expression: #{e?.message}"
        if parsed instanceof window.OMNode then return parsed
        console.log nodes.get( 0 ), toParse, parsed
        "Could not parse this mathematical text:
            #{toParse?.join? ' '} -- Error: #{parsed}"
