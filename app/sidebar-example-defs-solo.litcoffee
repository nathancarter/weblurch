
# Definitions for the Sidebar Example App

The main file for the app is located [here](sidebar-example-solo.litcoffee).

This file contains the definitions of code forms and categories as well as
their validation functions, plus translation routines for various languages.

## Registering basic code forms and categories

    registerCategory 'Coding Basics', [
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
        registerCodeForm 'Mathematical expression', ( group, verbose ) ->
            meaning = mathQuillToOpenMath group
            if meaning not instanceof window.OMNode
                return result : 'invalid', message : meaning
            result : 'valid'
            message : 'This is a valid mathematical expression'
            openmath : meaning.encode()
        registerCodeForm 'Store a value',
            [ 'Variable', 'Number/Text/Mathematical expression' ]
    ]

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

## Utilities used above

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
