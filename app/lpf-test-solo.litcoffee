
# Scripts supporting the LPF test webpage

The LPF (L^2 Proof Format) is documented on OverLeaf, where Nathan and Ken
can access it.  We need to test several things about that spec, most and one
of those things is whether the algorithm for converting LPF arrays into Lean
code (and extracting and translating errors from evaluating that code) works
as we want it to.  Thus we create an app for testing that very thing, a
simple web page supported by the scripts defined in this file.

The code in this file is pretty much a mess.  If it were to be incorporated
into any of the real apps in this repository (as opposed to just into a
test app, as it is now), it would need to be liberally commented and
possibly significantly refactored.  Right now, it is just a test.

## Loading and saving tests

    saveTest = ( name, code ) ->
        object = JSON.parse window.localStorage.testData ? "{}"
        object[name] = code
        window.localStorage.testData = JSON.stringify object
    savedTests = ->
        object = JSON.parse window.localStorage.testData ? "{}"
        Object.keys( object ).sort()
    loadTest = ( name ) ->
        object = JSON.parse window.localStorage.testData ? "{}"
        object[name]
    removeTest = ( name ) ->
        object = JSON.parse window.localStorage.testData ? "{}"
        delete object[name]
        window.localStorage.testData = JSON.stringify object

## Utilities for timing things

    myTimer = null
    now = -> ( new Date ).getTime()
    startTimer = -> myTimer = now()
    checkTimer = -> "(took #{now() - myTimer} ms)"

## Setting up the object that will become the Lean virtual machine

    # console.log( '--- Loading Lean VM...' ); startTimer();
    Module = window.Module = { }
    Module.TOTAL_MEMORY = 64 * 1024 * 1024
    Module.noExitRuntime = true
    myLeanOutputTracker = null
    fullOutputArray = null
    Module.print = ( text ) ->
        match = null
        if match = /FLYCHECK_BEGIN (.*)/.exec text
            myLeanOutputTracker = type : match[1], text : [ ]
        else if not myLeanOutputTracker
            throw new Error 'Unexpected output from Lean: ' + text
        else if match = /([^:]+):(\d+):(\d+): (.*)/.exec text
            myLeanOutputTracker.file = match[1]
            myLeanOutputTracker.line = match[2]
            myLeanOutputTracker.char = match[3]
            myLeanOutputTracker.info = match[4]
        else if /FLYCHECK_END/.test text
            # console.log 'Lean output: ' \
            #           + JSON.stringify myLeanOutputTracker, null, 4
            fullOutputArray.push myLeanOutputTracker
            myLeanOutputTracker = null
        else
            myLeanOutputTracker.text.push text
    Module.preRun = [
        ->
            # console.log '--- Lean VM loaded.', checkTimer()
            # console.log '--- Running Lean VM...'
            startTimer()
    ]
    # Module.postRun = ->
    #     console.log '--- Lean VM has been run.', checkTimer()

## A function for running Lean on any code

    runLeanOn = window.runLeanOn = ( code ) ->
        # console.log '--- Calling lean_init()...'
        startTimer()
        Module.lean_init()
        # console.log '--- lean_init() complete.', checkTimer()
        # console.log '--- Importing Lean standard module...'
        # startTimer();
        # Module.lean_import_module "standard"
        # console.log '--- Standard module imported.', checkTimer()
        # console.log '--- Writing test.lean to virtual FS...'
        startTimer()
        # console.log code
        FS.writeFile 'test.lean', code, encoding : 'utf8'
        # console.log '--- test.lean written.', checkTimer()
        # console.log '--- Running Lean on test.lean...'
        startTimer()
        fullOutputArray = [ ]
        Module.lean_process_file 'test.lean'
        # console.log '--- Lean has been run on test.lean.', checkTimer()
        fullOutputArray

## Responding to UI events

    $ ->
        ( $ '[data-toggle="tooltip"]' ).tooltip()
        lastInputCode = null
        lastOutputLeanCode = null
        lastOutputLeanMsgs = null
        lastOutputTranslated = null
        tabNumber = ->
            outputLink = ( $ '.output-tabs > li.active > a' ).get 0
            parseInt outputLink.getAttribute( 'id' )[-1..]
        clickTab = ( number ) ->
            ( $ '.output-tabs > li' ).removeClass 'active'
            link = ( $ ".output-tabs > li > a#tab#{number}" ).get( 0 )
            ( $ link.parentNode ).addClass 'active'
            showOutput()
        showOutput = ->
            ( $ '#output' ).val switch tabNumber()
                when 1 then lastOutputLeanCode
                when 2 then lastOutputLeanMsgs
                when 3 then lastOutputTranslated
        ( $ '.output-tabs > li > a' ).click ( event ) ->
            ( $ '.output-tabs > li' ).removeClass 'active'
            ( $ @parentNode ).addClass 'active'
            showOutput()
        setInterval ->
            newInputCode = ( $ '#input' ).val()
            if newInputCode is lastInputCode then return
            lastInputCode = newInputCode
            ( $ '#output' ).val '...RUNNING...'
            setTimeout ->
                try
                    compiled = compileLPF lastInputCode
                    lastOutputLeanCode = compiled.code()
                catch e
                    lastOutputLeanCode = 'Error in compilation!\n' + \
                        e.stack
                try
                    lastOutputLeanObjs = runLeanOn lastOutputLeanCode
                    lastOutputLeanMsgs = JSON.stringify \
                        lastOutputLeanObjs, null, 4
                catch e
                    lastOutputLeanObjs = null
                    lastOutputLeanMsgs = 'Error in Lean run!\n' + \
                        e.stack
                try
                    if lastOutputLeanObjs is null
                        throw Error 'Previous step encountered an error...
                            Check earlier tabs for details.'
                    for object in lastOutputLeanObjs
                        line = parseInt object.line ? 1
                        compiled.lineToElement( line ).feedback = object
                    lastOutputTranslated = ''
                    for element in compiled.elements
                        if not element.lpfCode then continue
                        lastOutputTranslated += element.lpfCode
                        if lastOutputTranslated[-1..] isnt '\n'
                            lastOutputTranslated += '\n'
                        if d = element.feedbackData()
                            lastOutputTranslated += "    #{d.result}\n"
                            if d.reason
                                lastOutputTranslated += "    #{d.reason}\n"
                            for own k, v of d
                                if k is 'result' or k is 'reason'
                                    continue
                                lastOutputTranslated += "    #{k} = #{v}\n"
                catch e
                    lastOutputTranslated = 'Error in translation!\n' + \
                        e.stack
                showOutput()
            , 0
        , 1000
        ( $ '#loadButton' ).click ( event ) ->
            thingsToLoad = savedTests()
            if thingsToLoad.length is 0
                alert 'You have not saved any LPF arrays yet.'
            else
                toLoad = prompt "Type the name of the LPF array to load,
                    chosen from the following list:\n
                    \n#{thingsToLoad.join '\n'}", thingsToLoad[0]
                if not toLoad? then return
                loaded = loadTest toLoad
                if not loaded
                    alert "I could not load the LPF array \"#{toLoad}.\""
                else
                    ( $ '#input' ).val loadTest toLoad
        lastSavedFilename = null
        ( $ '#saveButton' ).click ( event ) ->
            toSave = prompt "Type the name under which to save this LPF
                array.", lastSavedFilename
            if not toSave? then return
            if toSave in savedTests()
                if not confirm "Save over LPF array of that same name?"
                    return
            saveTest toSave, ( $ '#input' ).val()
            lastSavedFilename = toSave
        ( $ '#eraseButton' ).click ( event ) ->
            thingsToErase = savedTests()
            if thingsToErase.length is 0
                alert 'You have not saved any LPF arrays yet.'
            else
                toErase = prompt "Type the name of the LPF array to erase,
                    chosen from the following list:\n
                    \n#{thingsToErase.join '\n'}", thingsToErase[0]
                if not toErase? then return
                if toErase not in thingsToErase then return
                if not confirm "Are you SURE you want to ERASE #{toErase}?"
                    return
                removeTest toErase
        ( $ '#input' ).keydown ( event ) ->
            up = 1 : 2, 2 : 3, 3 : 1
            down = 1 : 3, 2 : 1, 3 : 2
            if event.altKey
                if event.keyCode is 219 # [
                    clickTab down[tabNumber()]
                    event.preventDefault()
                    false
                else if event.keyCode is 221 # ]
                    clickTab up[tabNumber()]
                    event.preventDefault()
                    false
        ( $ '#input' ).val '//
            \n// EXAMPLE CODE TO GET YOU STARTED
            \n//
            \nGlobal(SYMBOL,_true,[],Prop,[])
            \nGlobal(SYMBOL,_false,[],Prop,[])
            \nGlobal(SYMBOL,_or,[Prop,Prop],Prop,[])
            \nGlobal(RULE,_true_intro,[],_true,[])
            \nGlobal(RULE,_or_intro_left,[A:Prop,B:Prop,B],_or A B,[A,B])
            \nGlobal(RULE,_or_intro_right,[A:Prop,B:Prop,A],_or A B,[A,B])
            \nBegin()
            \nLocal(X,Prop,[])
            \nStep(_true,[],_true_intro,[])
            \nStep(_or X _true,[X],_or_intro_left,[8])
            \nEnd()'
        ( $ '#input' ).focus()

## Compiling the LPF array into Lean code

    compileLPF = ( code ) ->
        result = { }
        # things to ignore
        commentRE = /^\/\/(.*)(\n|$)/
        whitespaceRE = /^\s+/
        # Global(SYMBOL,and,[Prop,Prop],Prop,[])
        # Global(RULE,and_intro,[A:Prop,B:Prop,A,B],and A B,[A,B])
        globalRE = ///
            ^Global\s*\(\s*(SYMBOL|RULE)\s*,\s*
            (\w+)\s*,\s*
            \[([^\]]*)\]\s*,\s*
            ([^,]+)\s*,\s*
            \[([^\]]*)\]\s*\)
            ///
        # Step(true,[],true_intro_axiom,[])
        # Step(and true true,[],and_intro,[5,5])
        # Step(and A and B C,[A,B,C],and_intro,[6,13])
        stepRE = ///
            ^Step\s*\(\s*
            ([^,]+)\s*,\s*
            \[([^\]]*)\]\s*,\s*
            (\w+)\s*,\s*
            \[((\s|\d|,)*)\]\s*\)
            ///
        # Type(Prop)
        typeRE = /^Type\s*\(\s*(\w+)\s*\)/
        # Begin()
        beginRE = /^Begin\s*\(\s*\)/
        # End()
        endRE = /^End\s*\(\s*\)/
        # Local(x,Real,[])
        localRE = ///
            ^Local\s*\(\s*
            (\w+)\s*,\s*
            (\w+)\s*,\s*
            \[([^\]]*)\]\s*\)
            ///
        # now apply those
        result = [ ]
        lines = { }
        frees = { }
        env = [ ]
        lastType = null
        count = 0
        originalCode = code
        positionInCode = null
        match = null
        result.elements = [
            lpfCode : ''
            lpfPosition : -1
            leanCode : 'notation `Prop` := Type.{0}'
            numLines : 1
        ]
        feedbackData = ->
            if not @feedback? then return null
            console.log @feedback
            if @feedback.info is 'information:check result:'
                result : 'VALID'
            else if @feedback.info is 'error: type mismatch at application'
                result : 'INVALID'
                reason : 'bad premise'
                premiseIndex : parseInt( @feedback.text[2].trim()[5..] ) + 1
                correctType : @feedback.text[4].trim()
                assertedType : @feedback.text[6].trim()
            else if match = /error: unknown identifier '([^']+)'/.exec \
                    @feedback.info
                result : 'INVALID'
                reason : 'undeclared identifier'
                identifier : match[1]
            else if @feedback.info is 'error: type mismatch at term'
                result : 'INVALID'
                reason : 'bad conclusion'
                correctType : @feedback.text[2].trim()
                assertedType : @feedback.text[4].trim()
            else
                result : 'INVALID'
                reason : @feedback.info
                warning : 'Unknown error type -- could not translate'
        result.lineToElement = ( lineNum ) ->
            linesFound = 0
            for element in @elements
                linesFound += element.numLines
                if linesFound >= lineNum then return element
            null
        result.code = -> ( elt.leanCode for elt in @elements ).join '\n'
        result.add = ( code ) ->
            @elements.push
                lpfCode : match[0]
                lpfPosition : positionInCode
                leanCode : code
                numLines : code.split( '\n' ).length
                feedbackData : feedbackData
        dot2comma = ( code ) -> code.replace /\./g, ','
        while code.length > 0
            positionInCode = originalCode.length - code.length
            if match = commentRE.exec code
                result.add '-- ' + match[1]
            else if match = whitespaceRE.exec code
                # pass
            else if match = globalRE.exec code
                type = match[1]
                name = "#{match[2]}"
                inputs = match[3]
                if not /^\s*$/.test inputs
                    inputs = ( i.trim() for i in inputs.split ',' )
                else
                    inputs = [ ]
                output = match[4]
                freevars = match[5]
                if not /^\s*$/.test freevars
                    freevars = ( t.trim() for t in freevars.split ',' )
                else
                    freevars = [ ]
                inputs = for entry, index in inputs
                    if /^\s*[a-zA-Z_][a-zA-Z_0-9]*\s*:/.test entry
                        [ ( t.trim() for t in entry.split ':' )..., 'pair' ]
                    else
                        [ "dummy#{index}", entry, 'singleton' ]
                if type is 'SYMBOL' and inputs.length is 0
                    result.add "constant #{name} : #{dot2comma output}"
                else if type is 'SYMBOL'
                    inames = ( v[0] for v in inputs )
                    inputs =
                        ( "(#{v[0]} : #{dot2comma v[1]})" for v in inputs )
                    result.add "inductive #{name} #{inputs.join ' '} :
                        #{output} := mk : #{inames.join ' -> '} ->
                        #{name} #{inames.join ' '}"
                else if type is 'RULE'
                    inputs = for v in inputs
                        if v[2] is 'pair'
                            "{#{v[0]} : #{dot2comma v[1]}}"
                        else
                            "(#{v[0]} : #{dot2comma v[1]})"
                    result.add "constant #{name} #{inputs.join ' '} :
                        #{dot2comma output}"
                else
                    result.add '-- Invalid Global type: ' + type
                count++
            else if match = stepRE.exec code
                conclusion = dot2comma match[1]
                freevars = match[2]
                if not /^\s*$/.test freevars
                    freevars = ( t.trim() for t in freevars.split ',' )
                else
                    freevars = [ ]
                reason = "#{match[3]}"
                premises = match[4]
                allfrees = freevars[..]
                if not /^\s*$/.test premises
                    premises =
                        ( parseInt i.trim() for i in premises.split ',' )
                    for i in premises
                        for free in frees[i] ? [ ]
                            if free not in allfrees
                                allfrees.push free
                    premises = ( "(#{lines[i]})" for i in premises )
                else
                    premises = [ ]
                declarations = ''
                getTypeOf = ( name ) ->
                    i = env.length - 1
                    while i >= 0
                        for pair in env[i]
                            if pair[0] is name then return pair[1]
                        i--
                    lastType
                if allfrees.length > 0
                    undeclared = [ ]
                    for v in allfrees
                        if not getTypeOf v
                            undeclared.push v
                    if undeclared.length > 0
                        result.add '-- Undeclared variable(s): ' + \
                            undeclared.join ', '
                        break
                    allfrees = ( "(#{v} : #{dot2comma getTypeOf v})" \
                        for v in allfrees )
                    declarations = allfrees.join ' '
                if premises.length > 0
                    for premise, index in premises
                        declarations += " (dummy#{index} : #{premise})"
                        premises[index] = "dummy#{index}"
                if declarations.length > 0
                    declarations = 'variables ' + declarations
                else
                    declarations = '-- no variable declarations needed'
                result.add "section
                    \n  #{declarations}
                    \n  check ((#{reason} #{premises.join ' '}) :
                    #{conclusion})
                    \nend"
                lines[count] = conclusion
                frees[count] = freevars[..]
                count++
            else if match = typeRE.exec code
                result.add '-- Type ' + dot2comma match[1]
                lastType = dot2comma match[1]
                count++
            else if match = beginRE.exec code
                result.add '-- Begin'
                env.push [ ]
                count++
            else if match = endRE.exec code
                result.add '-- End'
                if env.length is 0
                    result.add '-- Cannot do End here!'
                    break
                if not ( conclusion = lines[count-1] )?
                    result.add '-- Subproof had no conclusion!'
                    break
                premises = for pair in env.pop()
                    "(#{pair[0]} : #{pair[1]})"
                lines[count] = "Pi #{premises.join ' '}, (#{conclusion})"
                count++
            else if match = localRE.exec code
                result.add '-- Local ' + match[1] + ' ' + match[2] \
                    + ' ' + match[3]
                if env.length is 0
                    result.add '-- Cannot do Local here!'
                    break
                last = env[env.length-1]
                okayToAdd = yes
                for pair in last
                    if pair[0] is match[1]
                        result.add "-- Cannot redeclare #{match[1]} here!"
                        okayToAdd = no
                        break
                if okayToAdd then last.push [ match[1], dot2comma match[2] ]
                lines[count] = dot2comma match[2]
                count++
            else
                result.add '-- Cannot understand: ' + code
                break
            code = code[match[0].length..]
        console.log lines
        result
