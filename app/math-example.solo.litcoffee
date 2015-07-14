
# Mathematical Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example.solo.litcoffee) and then
for [the complex example application](complex-example.solo.litcoffee).
This application is more useful than either of those.

    setAppName 'MathApp'
    window.menuBarIcon = { }
    window.helpAboutText =
        'See the fully documented source code for this demo app at the
        following URL:\n
        \nhttps://github.com/nathancarter/weblurch/blob/master/app/math-example.solo.litcoffee'

[See a live version of this application online here.](
http://nathancarter.github.io/weblurch/app/math-example.html)

## Define one group type

For information on what this code does, see the simple example linked to
above.

    window.groupTypes = [
        name : 'me'
        text : 'Mathematical Expression'
        tooltip : 'Make the selection a mathematical expression'
        color : '#666699'
        imageHTML : '<font color="#666699"><b>[ ]</b></font>'
        openImageHTML : '<font color="#666699"><b>[</b></font>'
        closeImageHTML : '<font color="#666699"><b>]</b></font>'

The `contentsChanged` function is called on a group whenever that group just
had its contents changed.  In this case, we simply compute the contents of
the bubble tag and store them in the group.

        contentsChanged : ( group, firstTime ) ->
            info = inspect group
            if info instanceof window.OMNode
                info = switch info.type
                    when 'i' then 'integer'
                    when 'f' then 'float'
                    when 'st' then 'string'
                    when 'ba' then 'byte array'
                    when 'sy' then 'symbol'
                    when 'v' then 'variable'
                    when 'a' then switch info.children[0].simpleEncode()
                        when 'arith1.plus', 'arith1.sum' then 'sum'
                        when 'arith1.minus' then 'difference'
                        when 'arith1.plusminus' then 'sum/difference'
                        when 'arith1.times' then 'product'
                        when 'arith1.divide' then 'quotient'
                        when 'arith1.power' then 'exponentiation'
                        when 'arith1.root' then 'radical'
                        when 'arith1.abs' then 'absolute value'
                        when 'arith1.unary_minus' then 'negation'
                        when 'relation1.eq' then 'equation'
                        when 'relation1.approx' then 'approximation'
                        when 'relation1.neq' then 'negated equation'
                        when 'relation1.lt', 'relation1.le', \
                             'relation1.gt', 'relation1.ge'
                            'inequality'
                        when 'logic1.not' then 'negated sentence'
                        when 'calculus1.int' then 'indefinite integral'
                        when 'calculus1.defint' then 'definite integral'
                        when 'transc1.sin', 'transc1.cos', 'transc1.tan', \
                             'transc1.cot', 'transc1.sec', 'transc1.csc'
                            'trigonometric function'
                        when 'transc1.arcsin', 'transc1.arccos', \
                             'transc1.arctan', 'transc1.arccot', \
                             'transc1.arcsec', 'transc1.arccsc'
                            'inverse trigonometric function'
                        when 'overarc' then 'overarc'
                        when 'overline' then 'overline'
                        when 'd.diff' then 'differential'
                        when 'interval1.interval_oo', \
                             'interval1.interval_oc', \
                             'interval1.interval_co', \
                             'interval1.interval_cc' then 'interval'
                        when 'integer1.factorial' then 'factorial'
                        when 'limit1.limit' then 'limit'
                    when 'b' then 'lambda closure'

If we make a change to the group *in the change handler,* that will trigger
another change handler, which will create an infinite loop (and eventually a
"maximum call stack size exceeded" error in the browser).  Thus we first
inspect to see if the result we're about to store in the group is already
there; if so, we do nothing, and the loop ceases.

            if info isnt group.get 'tag' then group.set 'tag', info

When the group's tag needs to be computed, we simply lift the data out of
the result already stored in the group from the above computation, and use
that to determine the contents of the bubble tag.

        tagContents : ( group ) -> group.get 'tag'

Clicking the tag or the context menu brings up the same menu, defined in
[the menu function below](#utility-functions-used-by-the-code-above).

        tagMenuItems : ( group ) -> menu group
        contextMenuItems : ( group ) -> menu group
    ]

## Utility functions used by the code above

The "inspect" command looks at the contents of the group, and tries to
interpret it as containing a single MathQuill instance.  It returns one of
two things.  If it returns an OMNode instance, it will be the meaning of the
one MathQuill instance in the bubble, if there is one instance in the bubble
and such a meaning is parseable from it, using
[the parser defined here](../src/mathquill-parser.solo.litcoffee).  If
instead there was some error in computing that, then a string will be
returned containing the error.

    inspect = ( group ) ->
        nodes = $ group.contentNodes()
        selector = '.mathquill-rendered-math'
        nodes = nodes.find( selector ).add nodes.filter selector
        newTag = null
        if nodes.length is 0 then return 'add math using the f(x) button'
        if nodes.length > 1 then return 'more than one math expression'
        node = nodes.get 0
        try
            toParse = mathQuillToMeaning node
        catch e
            console.log 'node:', node
            return "Error converting math expression to text: #{e?.message}"
        try
            parsed = mathQuillParser.parse( toParse )?[0]
        catch e
            console.log 'cannot parse:', toParse
            return "Error parsing math expression as text: #{e?.message}"
        if parsed instanceof window.OMNode then return parsed
        console.log node, toParse
        "Could not parse this mathematical text: #{toParse?.join? ' '} --
            Error: #{parsed}"

The following function provides the contents of either the tag menu or the
context menu for a group; both are the same.

    menu = ( group ) -> [
        text : 'See full OpenMath structure'
        onclick : ->
            if ( info = inspect group ) not instanceof OMNode
                alert "Could not evaluate the bubble contents:\n #{info}"
            else
                try
                    alert ( toXML info ) ? "Some part of that expression is
                        not supported in this demo for conversion to XML."
                catch e then alert e.message ? e
    ,
        text : 'Evaluate this'
        onclick : ->
            if ( info = inspect group ) not instanceof OMNode
                info = "Could not evaluate the bubble contents:\n #{info}"
            else
                result = compute info
                info = "#{result.value}"
                if result.message?
                    info += "\n\nNote:\n#{result.message}"
            alert info
    ]

This is an incomplete implementation of the XML encoding for OpenMath trees.
It is very piecemeal, spotty, and untested, but is here just for the
purposes of this demo application.

    toXML = ( node ) ->
        indent = ( text ) -> "  #{text.replace RegExp( '\n', 'g' ), '\n  '}"
        switch node.type
            when 'i' then "<OMI>#{node.value}</OMI>"
            when 'sy' then "<OMS cd=\"#{node.cd}\" name=\"#{node.name}\"/>"
            when 'v' then "<OMV name=\"#{node.name}\"/>"
            when 'f' then "<OMF dec=\"#{node.value}\"/>"
            when 'st'
                text = node.value.replace /\&/g, '&amp;'
                .replace /</g, '&lt;'
                "<OMSTR>#{text}</OMSTR>"
            when 'a'
                inside = ( indent toXML c for c in node.children ).join '\n'
                "<OMA>\n#{inside}\n</OMA>"
            when 'bi'
                head = indent toXML node.symbol
                vars = ( toXML v for v in node.variables ).join ''
                vars = indent "<OMBVAR>#{vars}</OMBVAR>"
                body = indent toXML node.body
                "<OMBIND>\n#{head}\n#{vars}\n#{body}\n</OMBIND>"
            else
                throw "Cannot convert this to XML: #{node.simpleEncode()}"

### Evaluating mathematical expressions numerically

The following is a very limited routine that evaluates mathematical
expressions numerically when possible, and returns an explanation of why it
could not evaluate them in cases where it could not.  The result is an
object with "value" and "message" attributes.

    compute = ( node ) ->
        call = ( func, indices... ) ->
            message = undefined
            args = [ ]
            for index in indices
                arg = compute node.children[index]
                if not arg.value? then return arg
                if arg.message?
                    if not message? then message = '' else message += '\n'
                    message += arg.message
                args.push arg.value
            try
                value = func args...
            catch e
                if not message? then message = '' else message += '\n'
                message += e.message
            value : value
            message : message
        result = switch node.type
            when 'i', 'f', 'st', 'ba' then value : node.value
            when 'v' then switch node.name
                when 'π'
                    value : Math.PI
                    message : 'The actual value of π has been rounded.'
                when 'e'
                    value : Math.exp 1
                    message : 'The actual value of e has been rounded.'
            when 'sy' then switch node.simpleEncode()
                when 'units.degrees' then value : Math.PI/180
                when 'units.percent' then value : 0.01
                when 'units.dollars'
                    value : 1
                    message : 'Dollar units were dropped'
            when 'a' then switch node.children[0].simpleEncode()
                when 'arith1.plus' then call ( ( a, b ) -> a + b ), 1, 2
                when 'arith1.minus' then call ( ( a, b ) -> a - b ), 1, 2
                when 'arith1.times' then call ( ( a, b ) -> a * b ), 1, 2
                when 'arith1.divide' then call ( ( a, b ) -> a / b ), 1, 2
                when 'arith1.power' then call Math.pow, 1, 2
                when 'arith1.root'
                    call ( ( a, b ) -> Math.pow b, 1/a ), 1, 2
                when 'arith1.abs' then call Math.abs, 1
                when 'arith1.unary_minus' then call ( ( a ) -> -a ), 1
                when 'relation1.eq' then call ( ( a, b ) -> a is b ), 1, 2
                when 'relation1.approx'
                    tmp = call ( ( a, b ) -> Math.abs( a - b ) < 0.01 ),
                        1, 2
                    if ( tmp.message ?= '' ).length then tmp.message += '\n'
                    tmp.message += 'Values were rounded to two decimal
                        places for approximate comparison.'
                    tmp
                when 'relation1.neq'
                    call ( ( a, b ) -> a isnt b ), 1, 2
                when 'relation1.lt' then call ( ( a, b ) -> a < b ), 1, 2
                when 'relation1.gt' then call ( ( a, b ) -> a > b ), 1, 2
                when 'relation1.le' then call ( ( a, b ) -> a <= b ), 1, 2
                when 'relation1.ge' then call ( ( a, b ) -> a >= b ), 1, 2
                when 'logic1.not' then call ( ( a ) -> not a ), 1
                when 'transc1.sin' then call Math.sin, 1
                when 'transc1.cos' then call Math.cos, 1
                when 'transc1.tan' then call Math.tan, 1
                when 'transc1.cot' then call ( ( a ) -> 1/Math.tan(a) ), 1
                when 'transc1.sec' then call ( ( a ) -> 1/Math.cos(a) ), 1
                when 'transc1.csc' then call ( ( a ) -> 1/Math.sin(a) ), 1
                when 'transc1.arcsin' then call Math.asin, 1
                when 'transc1.arccos' then call Math.acos, 1
                when 'transc1.arctan' then call Math.atan, 1
                when 'transc1.arccot'
                    call ( ( a ) -> Math.atan 1/a ), 1
                when 'transc1.arcsec'
                    call ( ( a ) -> Math.acos 1/a ), 1
                when 'transc1.arccsc'
                    call ( ( a ) -> Math.asin 1/a ), 1
                when 'transc1.ln' then call Math.log, 1
                when 'transc1.log' then call ( base, arg ) ->
                    Math.log( arg ) / Math.log( base )
                , 1, 2
                when 'integer1.factorial'
                    call ( a ) ->
                        if a <= 1 then return 1
                        if a >= 20 then return Infinity
                        result = 1
                        result *= i for i in [1..a|0]
                        result
                    , 1
                # Maybe later I will come back and implement these, but this
                # is just a demo app, so there is no need to get fancy.
                # when 'arith1.sum'
                # when 'calculus1.int'
                # when 'calculus1.defint'
                # when 'limit1.limit'
        result ?= value : undefined
        if typeof result.value is 'undefined'
            result.message = "Could not evaluate #{node.simpleEncode()}"
        # console.log "#{node.simpleEncode()} --> #{JSON.stringify result}"
        result
