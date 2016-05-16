
# Scripts supporting the CP test webpage

The question is what set of tools a user needs to be able to define any
language (and thus a parser for it) that we might want Lurch users to be
able to define.  Thus we create an app for testing that very thing, a
simple web page supported by the scripts defined in this file.  It gives the
users tools for defining languages, and we can test to see if we ourselves
can use those tools (in an intuitive and natural way) to define the
languages we envision Lurch users wanting to define.

The code in this file is pretty much a mess.  If it were to be incorporated
into any of the real apps in this repository (as opposed to just into a
test app, as it is now), it would need to be liberally commented and
possibly significantly refactored.  Right now, it is just a test.

## Rethinking

 * You can always specify that category X is a subset of category Y, so that
   for instance if you've defined nonnegativeinteger to be a character from
   0-9 followed by zero or more additional such things, you can then say
   that nonnegativeinteger is a subset of integer.
 * There are predefined categories for integer, float, variable, string,
   and symbol that are all subcategories of the predefined category atomic.
   By default these have no rules within them, but you can add them.  By
   default, atomic isn't a subset of anything, but you can make it such.
 * Rather than provide a subcategory for things like integer, variable,
   etc., you can just ask Lurch to use a predefined and common syntax for
   these standard categories.  Examples:
   * Base-n notation, for any n from 1 to 36, defaulting to 10, for integers
     and floats
   * For floats, choose whether the thousands separator is permitted, and
     whether you're using US or EU convention for . and ,
   * Standard notation for strings, "..." or '...' or both
   * Variables using the standard OM variable regexp, or any of a few common
     subsets thereof (e.g., just Roman letters, or single-letter variables)
 * 

## To-dos

 * Test it on a real language.
 * Enhance it so that non-terminals that are just collections of other
   non-terminals can simply get the tags from those sub-categories, rather
   than add their own (more vague) tag label.  E.g., "atomic expression"
   shouldn't have its own tag; it should just inherit variable, integer, ...

## Storing the model

    model =
        name : 'Example'
        elements : [ type : 'definition' ]
    do addModelFunctions = ->
        model.insert = ( n, element ) ->
            model.elements = [
                model.elements[...n]...
                element
                model.elements[n...]...
            ]
            showModelInView()
            ( $ 'html,body' ).scrollTop ( $ getRow n ).offset().top
            ( $ getRow n ).fadeOut( 0 ).fadeIn 500
        model.remove = ( n ) ->
            model.elements = [
                model.elements[...n]...
                model.elements[n+1...]...
            ]
            if model.elements.length is 0
                model.elements = [ type : 'definition' ]
            showModelInView()
            ( $ 'html,body' ).scrollTop ( $ getRow n ).offset().top
        model.swap = ( n ) ->
            if n < 0 or n >= model.elements.length - 1
                alert 'That cannot be moved any further in that direction.'
            else
                model.elements = [
                    model.elements[...n]...
                    model.elements[n+1]
                    model.elements[n]
                    model.elements[n+2...]...
                ]
                showModelInView()
                ( $ 'html,body' ).scrollTop ( $ getRow n ).offset().top
                ( $ getRow n ).fadeOut( 0 ).fadeIn 500
                ( $ getRow n+1 ).fadeOut( 0 ).fadeIn 500

## Loading and saving state

    getState = -> model
    setState = ( state ) ->
        model = state
        addModelFunctions()
        showModelInView()
    saveState = ( name ) ->
        object = JSON.parse window.localStorage.languageData ? "{}"
        object[name] = getState()
        window.localStorage.languageData = JSON.stringify object
    savedStates = ->
        object = JSON.parse window.localStorage.languageData ? "{}"
        Object.keys( object ).sort()
    loadState = ( name ) ->
        object = JSON.parse window.localStorage.languageData ? "{}"
        setState object[name]
    removeState = ( name ) ->
        object = JSON.parse window.localStorage.languageData ? "{}"
        delete object[name]
        window.localStorage.languageData = JSON.stringify object

## Utilities for timing things

    myTimer = null
    now = -> ( new Date ).getTime()
    startTimer = -> myTimer = now()
    checkTimer = -> "(took #{now() - myTimer} ms)"

## Placing content in the page

    mainContainer = -> ( $ '#main' ).get 0
    numRows = -> mainContainer().childNodes.length
    getRow = ( n ) -> mainContainer().childNodes[n]
    addRow = ( node ) -> mainContainer().appendChild node
    takeRow = ( n ) -> mainContainer().removeChild getRow n
    insertRow = ( n, node ) ->
        if n is numRows() then return addRow node
        mainContainer().insertBefore node, getRow n
    swapRows = ( n, m ) ->
        insertRow Math.min( n, m ), takeRow Math.max( n, m )
    setRow = ( n, node ) ->
        if n is numRows() then return addRow node
        mainContainer().insertAfter node, getRow n
        takeRow n
    makeDiv = ( html, classes = null ) ->
        result = document.createElement 'div'
        result.innerHTML = html
        if classes? then result.setAttribute 'class', classes
        result

## Constructing input widgets

    makeRuleForm = ( n ) ->
        makeDiv "<div class='panel-heading'>
              <div class='row'>
              <div class='col-md-6'><h5>New form in the language</h5></div>
              <div class='col-md-6' style='text-align: right;'>
                Move <button type='button' id='move_up_button_#{n}'
                        data-toggle='tooltip' title='Move this form up'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='move_down_button_#{n}'
                        data-toggle='tooltip' title='Move this form down'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                Test <button type='button' id='test_above_button_#{n}'
                        data-toggle='tooltip' title='Add test above'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='test_below_button_#{n}'
                        data-toggle='tooltip' title='Add test below'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                Form <button type='button' id='form_above_button_#{n}'
                        data-toggle='tooltip' title='Add form above'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='form_below_button_#{n}'
                        data-toggle='tooltip' title='Add form below'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
                <button type='button' id='duplicate_form_button_#{n}'
                        data-toggle='tooltip' title='Duplicate this form'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-plus'
                        aria-hidden='true'></span></button>
                <button type='button' id='delete_form_button_#{n}'
                        data-toggle='tooltip' title='Delete this form'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-remove'
                        aria-hidden='true'></span></button>
              </div></div>
            </div>
            <div class='panel-body container'>
              <div class='row form-group'>
                <div class='col-md-3' style='text-align: right;'>
                  We define a(n)
                </div>
                <div class='col-md-8'>
                  <input type='text' class='form-control'
                         id='input_name#{n}'
                         placeholder='examples: integer, sum, fraction, variable, factorial, ...'>
                </div>
                <div class='col-md-1'>
                  <a href='#' onclick='javascript:showHelp(#{n},\"name\");'>
                    <span class='glyphicon glyphicon-question-sign'
                          aria-hidden='true'></span></a>
                </div>
              </div>
              <div class='row form-group'>
                <div class='col-md-3' style='text-align: right;'>
                  by this syntax:
                </div>
                <div class='col-md-8 form-inline'>
                  <select class='selectpicker' id='form_choice_#{n}'>
                    <option selected='true'>one of these characters:</option>
                    <option>of the following form:</option>
                  </select>
                  <input type='text' class='form-control' size=60
                         id='input_chars#{n}'
                         placeholder='examples: 0-9 or a-zA-Z'>
                  <span><span id='input_form#{n}'>example:left + right</span></span>.
                </div>
                <div class='col-md-1'>
                  <a href='#' onclick='javascript:showHelp(#{n},\"form\");'>
                    <span class='glyphicon glyphicon-question-sign'
                          aria-hidden='true'></span></a>
                </div>
              </div>
              <div class='row form-group'>
                <div class='col-md-3' style='text-align: right;'>
                  We labeled it as
                </div>
                <div class='col-md-8'>
                  <input type='text' class='form-control' id='input_tag#{n}'
                         placeholder='number, sum/difference, polynomial, factor in a product, ...'>
                </div>
                <div class='col-md-1'>
                  <a href='#' onclick='javascript:showHelp(#{n},\"tag\");'>
                    <span class='glyphicon glyphicon-question-sign'
                          aria-hidden='true'></span></a>
                </div>
              </div>
              <div class='row form-group'>
                <div class='col-md-3' style='text-align: right;'>
                  and interpret it as
                </div>
                <div class='col-md-8 form-inline'>
                  <select class='selectpicker' id='input_interpret_#{n}'>
                    <option selected='true'>a symbol application</option>
                    <option>a binding expression</option>
                    <option>a string</option>
                    <option>an integer</option>
                    <option>a floating point number</option>
                    <option>a variable</option>
                    <option>(no change to interpretation)</option>
                  </select>
                  <span id='span_for_bound_vars_#{n}' class='hidden'>
                    , binding the variables at indices
                    <input type='text' class='form-control' size=10
                           id='bound_vars_#{n}' placeholder='1 3'></span>
                  <span id='span_for_symbol_for_#{n}'>
                    of the symbol
                    <input type='text' class='form-control' size=30
                           id='symbol_for_#{n}'
                           placeholder='example: binary addition'></span>.
                </div>
                <div class='col-md-1'>
                  <a href='#'
                     onclick='javascript:showHelp(#{n},\"interp\");'>
                    <span class='glyphicon glyphicon-question-sign'
                          aria-hidden='true'></span></a>
                </div>
              </div>
            </div>", 'panel panel-info is-a-definition'
    setupRuleForm = ( n ) ->
        # load data from model
        ( $ "#input_name#{n}" ).val model.elements[n]?.name ? ''
        ( $ "#input_chars#{n}" ).val model.elements[n]?.chars ? ''
        ( $ "#input_form#{n}" ).mathquill 'editable'
        if model.elements[n]?.form?
            ( $ "#input_form#{n}" ).mathquill 'latex',
                model.elements[n].form
        ( $ "#input_tag#{n}" ).val model.elements[n]?.tag ? ''
        ( $ "#symbol_for_#{n}" ).val model.elements[n]?.sym ? ''
        ( $ "#bound_vars_#{n}" ).val model.elements[n]?.bound ? ''
        selected = model.elements[n]?.choice ? 'one of these characters:'
        ( $ "#form_choice_#{n} option" ).each ( index, option ) ->
            option = $ option
            option.prop 'selected', option.text() is selected
        selected = model.elements[n]?.interp ? 'an expression tree'
        ( $ "#input_interpret_#{n} option" ).each ( index, option ) ->
            option = $ option
            option.prop 'selected', option.text() is selected
        do hideShowSpans = ->
            selected = $ "#form_choice_#{n} option:selected"
            if selected.text() is 'one of these characters:'
                ( $ "#input_chars#{n}" ).removeClass 'hidden'
                ( $ "#input_form#{n}" ).get( 0 ).parentNode.style.display =
                    'none'
            else
                ( $ "#input_chars#{n}" ).addClass 'hidden'
                ( $ "#input_form#{n}" ).get( 0 ).parentNode.style.display =
                    'inline'
            selected = $ "#input_interpret_#{n} option:selected"
            if selected.text() is 'a binding expression'
                ( $ "#span_for_bound_vars_#{n}" ).removeClass 'hidden'
            else
                ( $ "#span_for_bound_vars_#{n}" ).addClass 'hidden'
            if selected.text() is 'a symbol application'
                ( $ "#span_for_symbol_for_#{n}" ).removeClass 'hidden'
            else
                ( $ "#span_for_symbol_for_#{n}" ).addClass 'hidden'
        # set up event handlers for controls
        ( $ "#form_choice_#{n}" ).change hideShowSpans
        ( $ "#input_interpret_#{n}" ).change hideShowSpans
        ( $ "#test_above_button_#{n}" ).click ( event ) ->
            model.insert n, type : 'test'
        ( $ "#test_below_button_#{n}" ).click ( event ) ->
            model.insert n+1, type : 'test'
        ( $ "#form_above_button_#{n}" ).click ( event ) ->
            model.insert n, type : 'definition'
        ( $ "#form_below_button_#{n}" ).click ( event ) ->
            model.insert n+1, type : 'definition'
        ( $ "#delete_form_button_#{n}" ).click ( event ) -> model.remove n
        ( $ "#duplicate_form_button_#{n}" ).click ( event ) ->
            model.insert n, JSON.parse JSON.stringify model.elements[n]
        ( $ "#move_up_button_#{n}" ).click ( event ) -> model.swap n-1
        ( $ "#move_down_button_#{n}" ).click ( event ) -> model.swap n
    makeTestZone = ( n ) ->
        numRulesBefore = 0
        for i in [0...n]
            if model.elements[i].type is 'definition' then numRulesBefore++
        makeDiv "<div class='panel-heading'>
            <div class='row'>
              <div class='col-md-6'><h5>Test of the language defined
                above (containing #{numRulesBefore} forms)</h5></div>
              <div class='col-md-6' style='text-align: right;'>
                Move <button type='button' id='move_up_button_#{n}'
                        data-toggle='tooltip' title='Move this test up'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='move_down_button_#{n}'
                        data-toggle='tooltip' title='Move this test down'
                        class='btn btn-md btn-default'><span
                          class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                Test <button type='button' id='test_above_button_#{n}'
                        data-toggle='tooltip' title='Add test above'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='test_below_button_#{n}'
                        data-toggle='tooltip' title='Add test below'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                Form <button type='button' id='form_above_button_#{n}'
                        data-toggle='tooltip' title='Add form above'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-up'
                        aria-hidden='true'></span></button>
                <button type='button' id='form_below_button_#{n}'
                        data-toggle='tooltip' title='Add form below'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-arrow-down'
                        aria-hidden='true'></span></button>
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
                <button type='button' id='duplicate_test_button_#{n}'
                        data-toggle='tooltip' title='Duplicate this test'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-plus'
                        aria-hidden='true'></span></button>
                <button type='button' id='delete_test_button_#{n}'
                        data-toggle='tooltip' title='Delete this test'
                        class='btn btn-md btn-default'><span
                        class='glyphicon glyphicon-remove'
                        aria-hidden='true'></span></button>
              </div>
            </div></div>
            <div class='panel-body'>
              <div>Enter an expression in your language, then press enter to
                see the parsed result</div>
              <div><p><span id='test_input_#{n}'>temp</span></p></div>
              <div><pre id='test_output_#{n}'></pre></div>
            </div>", 'panel panel-success is-a-test-zone'
    setupTestZone = ( n ) ->
        # load data from model
        ( $ "#test_input_#{n}" ).mathquill 'editable'
        ( $ "#test_input_#{n}" ).mathquill 'latex',
            model.elements[n]?.input ? 'PutTestHere'
        ( $ "#test_output_#{n}" ).text model.elements[n]?.output ? ''
        # set up event handlers for controls
        ( $ "#test_output_#{n}" ).text "(Result will be shown here.)"
        ( $ "#test_above_button_#{n}" ).click ( event ) ->
            model.insert n, type : 'test'
        ( $ "#test_below_button_#{n}" ).click ( event ) ->
            model.insert n+1, type : 'test'
        ( $ "#form_above_button_#{n}" ).click ( event ) ->
            model.insert n, type : 'definition'
        ( $ "#form_below_button_#{n}" ).click ( event ) ->
            model.insert n+1, type : 'definition'
        ( $ "#delete_test_button_#{n}" ).click ( event ) -> model.remove n
        ( $ "#duplicate_test_button_#{n}" ).click ( event ) ->
            model.insert n, JSON.parse JSON.stringify model.elements[n]
        ( $ "#move_up_button_#{n}" ).click ( event ) -> model.swap n-1
        ( $ "#move_down_button_#{n}" ).click ( event ) -> model.swap n
    showModelInView = ->
        # console.log 'showed model', JSON.stringify model.elements, null, 4
        while numRows() > 0 then takeRow 0
        for element, index in model.elements
            if element.type is 'definition'
                addRow makeRuleForm index
                setupRuleForm index
            else
                addRow makeTestZone index
                setupTestZone index
                updateTestResult index
        ( $ '.selectpicker' ).selectpicker()
        timerId = null
        ( $ 'input' ).keyup ( event ) ->
            if timerId? then clearTimeout timerId
            timerId = setTimeout updateModel, 500
        ( $ '.mathquill-editable' ).keyup ( event ) ->
            if timerId? then clearTimeout timerId
            timerId = setTimeout updateModel, 500
        ( $ 'select' ).change ( event ) ->
            if timerId? then clearTimeout timerId
            timerId = setTimeout updateModel, 500
    getVariablesBefore = ( n ) ->
        ( array ) ->
            for i in [0...n]
                if model.elements[i].type isnt 'definition' then continue
                if not ( name = model.elements[i].name )? then continue
                attempt = array[...name.length].join ''
                if name is attempt then return name
    updateTestResult = ( n ) ->
        mqnode = ( $ "#test_input_#{n}" ).get 0
        ( $ "#test_output_#{n}" ).text parse n,
            window.mathQuillToMeaning mqnode, getVariablesBefore n
    updateModel = ->
        for n in [0...numRows()]
            if ( $ getRow n ).hasClass 'is-a-definition'
                model.elements[n] ?= { }
                model.elements[n].type = 'definition'
                model.elements[n].name = ( $ "#input_name#{n}" ).val()
                model.elements[n].chars = ( $ "#input_chars#{n}" ).val()
                model.elements[n].form =
                    ( $ "#input_form#{n}" ).mathquill 'latex'
                mqnode = ( $ "#input_form#{n}" ).get 0
                model.elements[n].form_array =
                    window.mathQuillToMeaning mqnode, getVariablesBefore n
                model.elements[n].tag = ( $ "#input_tag#{n}" ).val()
                model.elements[n].sym = ( $ "#symbol_for_#{n}" ).val()
                model.elements[n].bound = ( $ "#bound_vars_#{n}" ).val()
                model.elements[n].interp =
                    ( $ "#input_interpret_#{n} option:selected" ).text()
                model.elements[n].choice =
                    ( $ "#form_choice_#{n} option:selected" ).text()
            else
                model.elements[n] ?= { }
                model.elements[n].type = 'test'
                model.elements[n].input =
                    ( $ "#test_input_#{n}" ).mathquill 'latex'
                model.elements[n].output = ( $ "#test_output_#{n}" ).val()
                updateTestResult n
        # console.log 'saved model', JSON.stringify model.elements, null, 4

## Event handlers

    window.showHelp = ( id, topic ) ->
        alert switch topic
            when 'name'
                'This must be a valid identifier, meaning that it must start
                with a letter or underscore, and then can contain any
                sequence of letters, numbers, or underscores.\n    Examples:
                \n    sum, product, hex_digit, integerBelow10'
            when 'form'
                '1. If you choose "one of these characters," then this blank
                must be filled with a list of individual characters, and the
                form being defined matches exactly one of them.  Thus, for
                instance, you could define a single digit this way:
                \n    0123456789
                \nNote that this only defines a single digit, not an entire
                sequence of digits.  For that, create a higher-level
                syntactic form, using the option 2., below.
                \nHyphens indicate ranges of digits, so the above set of
                characters could also be defined this way:
                \n    0-9
                \nTo include an actual hyphen as a valid character, put it
                first or last in the list.
                \n
                \n2. If you choose "of the following form," then this blank
                must exhibit the form in question.  Identifiers that have
                been previously declared as names for forms are interpreted
                as such; whitespace is interpreted as optional and of any
                length; everything else is interpreted as exact text.
                Examples:
                \n    Natural numbers:
                \n        Base form:       digit
                \n        Inductive form:  digit natural
                \n    Sums:
                \n        Base form:       term
                \n        Inductive form:  term + sum
                \n    Grouping symbols:
                \n        One form:        ( expression )'
            when 'tag'
                'Any human-readable phrase can go here, but it should be
                brief, because it will be used to populate bubble tags when
                expressions of this form appear inside the bubble.'
            when 'interp'
                'If the piece of syntax you\'re defining should have special
                meaning (e.g., as a number for us in computations, or as a
                variable for use in quantifiers) then mark it here as
                having such an interpretation.  If you\'re defining
                something hierarchical (e.g., a binary sum) then you should
                mark it as "an expression tree."  If you\'re defining a
                quantifier (or any operator that binds variables, such as a
                summation, product, integral, lambda, etc.) then you should
                mark it as a binding expression.  In that case, you say
                which of the tokens in the expression are variables that
                should be bound.  For instance, if you define an expression
                \n    Sum sub ( variable = term ) sup ( term ) term
                \nthen you should say item 3 (the fourth counting from zero,
                the "variable" token) is a variable to be bound.'

## Setup

    $ ->
        ( $ '#loadButton' ).click ( event ) ->
            thingsToLoad = savedStates()
            if thingsToLoad.length is 0
                alert 'You have not saved any language definitions yet.'
            else
                toLoad = prompt "Type the name of the language definition to
                    load, chosen from the following list:\n
                    \n#{thingsToLoad.join '\n'}", thingsToLoad[0]
                if not toLoad? then return
                loadState toLoad
        lastSavedFilename = null
        ( $ '#saveButton' ).click ( event ) ->
            toSave = prompt "Type the name under which to save this
                language definition.", lastSavedFilename
            if not toSave? then return
            if toSave in savedStates()
                if not confirm "Save over language definition of that same
                    name?" then return
            saveState lastSavedFilename = toSave
        ( $ '#eraseButton' ).click ( event ) ->
            thingsToErase = savedStates()
            if thingsToErase.length is 0
                alert 'You have not saved any language definitions yet.'
            else
                toErase = prompt "Type the name of the language definition
                    to erase, chosen from the following list:\n
                    \n#{thingsToErase.join '\n'}", thingsToErase[0]
                if not toErase? then return
                if toErase not in thingsToErase then return
                if not confirm "Are you SURE you want to ERASE #{toErase}?"
                    return
                removeState toErase
        showModelInView()

## Building parsers

    parse = ( n, input ) ->
        G = new Grammar
        # console.log '\n\n-----\n----- defining grammar\n-----'
        try
            nameToData = { }
            for i in [0...n]
                if model.elements[i].type is 'definition'
                    def = model.elements[i]
                    name = def.name?.trim() ? ''
                    if not /^[a-zA-Z_][a-zA-Z_0-9]*$/.test name
                        throw "This name was not an identifier: #{name}"
                    sym = def.sym?.trim()
                    tag = def.tag?.trim()
                    interp = def.interp?.trim()
                    sre = /^[a-zA-Z_][a-zA-Z_0-9]*\.[a-zA-Z_][a-zA-Z_0-9]*$/
                    obj = nameToData[name] ?= { }
                    if obj.tag? and obj.tag isnt tag
                        throw "Inconsistent tag names for #{name}:
                            #{obj.tag} and #{tag}"
                    obj.tag = tag
                    if obj.interp? and obj.interp isnt interp
                        throw "Inconsistent tag names for #{name}:
                            #{obj.interp} and #{interp}"
                    obj.interp = interp
                    if sre.test sym
                        nameToData[name].sym = OM.symbol sym.split( '.' )...
                    else
                        newsym = if /[a-zA-Z_]/.test sym[0] then '' else '_'
                        for i in [0...sym.length]
                            if /[a-zA-Z_]/.test sym[i]
                                newsym += sym[i]
                            else
                                newsym += "#{sym.charCodeAt i}"
                        nameToData[name].sym = OM.symbol newsym, 'Lurch'
                    if interp is 'a binding expression'
                        indices = def.bound?.trim()?.split /\s+/
                        for index in indices
                            if not /^[0-9]+$/.test index
                                throw "This variable index is not a natural
                                    number: #{v}.  The list of bound
                                    variables should be just natural numbers
                                    separated by whitespace."
                        nameToData[name].bound = indices
                    chars = ( def.chars ? '' ).trim()
                    rhs = if def.choice is 'one of these characters:'
                        RegExp "[#{RegExp.escape2 chars}]"
                    else
                        for element in def.form_array ? [ ]
                            if G.rules.hasOwnProperty element
                                element
                            else
                                RegExp RegExp.escape element
                    G.addRule name, rhs
                    # console.log 'adding rule', name, rhs
                    if not G.START?
                        G.START = name
                        # console.log 'initialized START to', name
                    if rhs.length is 1 and G.START is rhs[0]
                        G.START = name
                        # console.log 'generalized START to', name
            # console.log '-----\n----- done\n-----'
            # console.log 'grammar start symbol is', G.START
            parseKey = OM.sym 'Lurch', 'ParsedFrom'
            lastExpressionBuilt = null
            G.setOption 'expressionBuilder', ( expr ) ->
                # console.log 'build', expr
                name = expr[0]
                data = nameToData[name]
                lastExpressionBuilt = data.tag
                toValue = ( v ) ->
                    if v instanceof OM
                        ( v.getAttribute( parseKey ) ? v ).value
                    else
                        v
                collapse = ( array ) ->
                    ( "#{toValue elt}" for elt in array ).join ''
                result = switch data.interp
                    when 'a symbol application'
                        args = ( e for e in expr when e instanceof OM )
                        if args.length > 0
                            OM.application data.sym, args...
                        else
                            data.sym
                    when 'a binding expression'
                        bound = ( expr[i] for i in data.bound )
                        rest = ( i for i in [0...expr.length] \
                                 when i not in data.bound )
                        rest = ( expr[i] for i in rest \
                                 when expr[i] instanceof OM )
                        OM.application data.sym, bound..., rest...
                    when 'a string'
                        OM.string collapse expr[1...]
                    when 'an integer'
                        text = collapse expr[1...]
                        text = text.replace /\u2212/g, '-'
                        tmp = OM.integer parseInt text
                        tmp.setAttribute OM.sym( 'Lurch', 'ParsedFrom' ),
                            OM.str text
                        tmp
                    when 'a floating point number'
                        text = collapse expr[1...]
                        text = text.replace /\u2212/g, '-'
                        tmp = OM.float parseFloat text
                        tmp.setAttribute OM.sym( 'Lurch', 'ParsedFrom' ),
                            OM.str text
                        tmp
                    when 'a variable'
                        OM.variable collapse expr[1...]
                    when '(no change to interpretation)'
                        expr[1]
                # console.log 'result after recursion:', JSON.stringify result
                result
            G.setOption 'comparator', ( a, b ) -> a?.equals? b
            if not G.START then throw 'No grammar rules have been defined.'
            results = G.parse input#, showDebuggingOutput : yes
            results = for parsed in results
                if parsed not instanceof OM
                    "Not an OMNode: #{JSON.stringify parsed}"
                else
                    hasKey = ( om ) -> om.getAttribute parseKey
                    for d in parsed.descendantsSatisfying hasKey
                        d.removeAttribute parseKey
                    JSON.stringify JSON.parse( parsed.encode() ), null, 4
            return "Input: #{input}
                \nResult: #{results.join '\nResult: '}
                \nType: #{lastExpressionBuilt}"
        catch e
            console.log e.stack
            return "Language definition error:  #{e}"
    RegExp.escape = ( s ) -> s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'
    RegExp.escape2 = ( s ) -> s.replace /[\/\\^$*+?.()|[\]{}]/g, '\\$&'
