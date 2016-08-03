
# Lean Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example-solo.litcoffee) and then
for [the complex example application](complex-example-solo.litcoffee).
This application is more useful than either of those.

    setAppName 'LeanApp'
    addHelpMenuSourceCodeLink 'app/lean-example-solo.litcoffee'
    window.helpAboutText =
        'See the fully documented source code for this demo app at the
        following URL:\n
        \nhttps://github.com/nathancarter/weblurch/blob/master/app/lean-example-solo.litcoffee'

[See a live version of this application online here.](
http://nathancarter.github.io/weblurch/app/lean-example.html)

## Utilities for timing things

    myTimer = null
    now = -> ( new Date ).getTime()
    startTimer = -> myTimer = now()
    checkTimer = -> "(took #{now() - myTimer} ms)"

## Lean VM Setup

Here we begin loading the Lean virtual machine.  This takes some time.  We
do it silently, but we leave several commented-out `console.log` statements
below, so that you can see where certain events take place, and can monitor
those events on the console if you like, by uncommenting those lines.

The global variable `LeanOutputObject` is the current (if still under
construction) or most recent (if just completed) object dumped by the Lean
VM on its standard output channel.  The global variable `LeanOutputArray` is
the ordered collection of all such output objects, in the order they were
produced.

    # console.log( '--- Loading Lean VM...' );
    Module = window.Module = { }
    Module.TOTAL_MEMORY = 64 * 1024 * 1024
    Module.noExitRuntime = true
    LeanOutputObject = null
    LeanOutputArray = null
    Module.print = ( text ) ->
        match = null
        if match = /FLYCHECK_BEGIN (.*)/.exec text
            LeanOutputObject = type : match[1], text : [ ]
        else if not LeanOutputObject
            throw new Error 'Unexpected output from Lean: ' + text
        else if match = /([^:]+):(\d+):(\d+): (.*)/.exec text
            LeanOutputObject.file = match[1]
            LeanOutputObject.line = match[2]
            LeanOutputObject.char = match[3]
            LeanOutputObject.info = match[4]
        else if /FLYCHECK_END/.test text
            # console.log 'Lean output: ' \
            #           + JSON.stringify LeanOutputObject, null, 4
            LeanOutputArray.push LeanOutputObject
            LeanOutputObject = null
        else
            LeanOutputObject.text.push text
    Module.preRun = [
        ->
            # console.log '--- Lean VM loaded.', checkTimer()
            # console.log '--- Running Lean VM...'
            # startTimer()
    ]
    # Module.postRun = ->
    #     console.log '--- Lean VM has been run.', checkTimer()

## Lean Engine

The following function runs the Lean engine on a string input, treating that
string as an entire input file (with line and column numbers, as if Lean
were being run from the command line, not the web).  All feedback and/or
error messages produced by the engine are converted into output objects by
the `Module.print` function, above, and collected into the global variable
`LeanOutputArray`, which this function then returns.

    runLeanOn = window.runLeanOn = ( code ) ->
        # console.log '--- Calling lean_init()...'
        # startTimer()
        Module.lean_init false
        # console.log '--- lean_init() complete.', checkTimer()
        # console.log '--- Importing Lean standard module...'
        # startTimer();
        Module.lean_import_module "standard"
        # console.log '--- Standard module imported.', checkTimer()
        # console.log '--- Writing test.lean to virtual FS...'
        # startTimer()
        # console.log code
        FS.writeFile 'test.lean', code, encoding : 'utf8'
        # console.log '--- test.lean written.', checkTimer()
        # console.log '--- Running Lean on test.lean...'
        # startTimer()
        LeanOutputArray = [ ]
        Module.lean_process_file 'test.lean'
        # console.log '--- Lean has been run on test.lean.', checkTimer()
        LeanOutputArray

## Validation

To track whether validation is running, we use a global boolean.

    validationRunning = no

We also create a few functions for marking a group valid or invalid, for
clearing or checking whether a group has validation information, and for
clearing all validation information so that a new run of validation can then
operate on a clean slate.

    setValidity = ( group, symbol, hoverText ) ->
        group.set 'closeDecoration', symbol
        group.set 'closeHoverText', hoverText
    markValid = ( group, validOrNot, message ) ->
        color = if validOrNot then 'green' else 'red'
        symbol = if validOrNot then '&#10003;' else '&#10006;'
        setValidity group, "<font color='#{color}'>#{symbol}</font>",
            message
    clearValidity = ( group ) ->
        group.clear 'closeDecoration'
        group.clear 'closeHoverText'
    hasValidity = ( group ) ->
        'undefined' isnt typeof group.get 'closeDecoration'
    clearAllValidity = ->
        if validationRunning then return
        validationRunning = yes
        groups = tinymce.activeEditor.Groups
        clearValidity groups[id] for id in groups.ids()
        validationRunning = no

Now, the validation routine that operates on the whole document at once.  It
presumes that you have just run `clearAllValidity()`.

    validate = window.validate = ->
        groups = tinymce.activeEditor.Groups

If validation is running, then this call is probably the result of
recursion.  That is, changes to the document that happen during validation
are attempting to re-start validation in response to those changes.  They
should be ignored.

        if validationRunning then return
        validationRunning = yes

For any term group whose parent is also a term group, mark it invalid for
that reason.

        for id in groups.ids()
            if groups[id].typeName() is 'term' and \
               groups[id].parent?.typeName() is 'term'
                markValid groups[id], no,
                    'A term group cannot be inside another term group.'

Compute the Lean code for the entire document.  (This routine is defined
later in this file.)  We then create a mapping from lines in that file to
group IDs that generated those lines, so that we can trace errors back to
their origins.

        lineToGroupId = { }
        for line, index in ( leanCode = documentToCode() ).lines
            if m = /[ ]--[ ](\d+)$/.exec line
                lineToGroupId[index + 1] = parseInt m[1]

Run Lean on that input and process all output.

        lastError = -1
        code = leanCode.lines.join( '\n' ).replace \
            String.fromCharCode( 160 ), String.fromCharCode( 32 )
        for message in runLeanOn code
            id = lineToGroupId[message.line]
            if isError = /error:/.test message.info then lastError = id
            detail = "Lean reported:\n\n#{message.info}"
            if message.text.length
                detail += '\n' + message.text.join '\n'
            citation = parseInt message.char
            citation = if citation > 0
                codeline = leanCode.lines[message.line - 1]
                "\n\ncharacter ##{citation + 1} in this code:
                 \n#{/^(.*) -- \d+$/.exec( codeline )[1]}"
            else
                ''
            markValid groups[id], not isError, detail + citation
        for id in groups.ids()
            if id is lastError then break
            if not hasValidity groups[id]
                markValid groups[id], yes, 'No errors reported.'

Any type groups without arrows to term groups must be marked with a message
to tell the user that they were not part of validation (and perhaps indicate
a mistake on the user's part in input).  The only exceptions are body groups
acting as subterms.

        for id in groups.ids()
            if ( typeName = groups[id].typeName() ) is 'type'
                if isSubterm groups[id] then continue
                modifiedTerms = ( connection[1] \
                    for connection in groups[id].connectionsOut() \
                    when groups[connection[1]].typeName() is 'term' )
                if modifiedTerms.length is 0
                    setValidity groups[id],
                        '<font color="#aaaa00"><b>&#10039;</b></font>',
                        "This #{typeName} does not modify any terms, and was
                        thus ignored in validation.  Did you mean to connect
                        it to a term?"

Also mark invalid any group that couldn't be converted to Lean code in the
first place.

        for own id, message of leanCode.errors
            markValid groups[id], no, message

Validation is complete.

        validationRunning = no

Add a validate button to the toolbar.  It disables itself and shows
alternate text while Lean is running, because that process is time-consuming
and therefore needs some visual cue for the user about its progress.  We use
the zero timeout below to ensure that the UI is updated with the
"Running..." message before it locks up during the Lean run.

    validateButton = null
    window.groupToolbarButtons.validate =
        text : 'Run Lean'
        tooltip : 'Run Lean on this document'
        onclick : ->
            validateButton.text 'Running...'
            validateButton.disabled yes
            setTimeout ->
                validate()
                validateButton.disabled no
                validateButton.text 'Run Lean'
            , 0
        onPostRender : -> validateButton = this

## Lean Commands

The following Lean commands are permissible on terms.  Each comes with a
format for how it is converted into a line of Lean code.

    leanCommands =
        check : 'check (TERM)'
        eval : 'eval (TERM)'
        print : 'print "TERM"'
        import : 'import TERM'
        open : 'open TERM'
        constant : 'constant TERM'
        variable : 'variable TERM'
        definition : 'definition TERM'
        theorem : 'theorem TERM'
        example : 'example TERM'

## Term Groups

Declare a new type of group in the document, for Lean terms.

    window.groupTypes = [
        name : 'term'
        text : 'Lean Term'
        tooltip : 'Make the selection a Lean term'
        color : '#666666'
        imageHTML : '<font color="#666666"><b>[ ]</b></font>'
        openImageHTML : '<font color="#666666"><b>[</b></font>'
        closeImageHTML : '<font color="#666666"><b>]</b></font>'
        contentsChanged : clearAllValidity

Its tag will advertise any Lean command embedded in the group.

        tagContents : ( group ) ->
            if command = group.get 'leanCommand'
                "Command: #{command}"
            else
                null

Its context menu permits adding, editing, or removing a Lean command
embedded in the group.

        contextMenuItems : ( group ) -> [
            text : 'Edit command...'
            onclick : ->
                newval = prompt 'Enter the Lean command to use on this code
                    (or leave blank for none).\n
                    \nValid options include:\n' + \
                    Object.keys( leanCommands ).join( ' ' ),
                    group.get( 'leanCommand' ) ? ''
                if newval isnt null
                    if newval is ''
                        group.clear 'leanCommand'
                    else if newval not of leanCommands
                        alert 'That was not one of the choices.  No change
                            has been made to your document.'
                    else
                        group.set 'leanCommand', newval
        ]

We can connect term groups to other term groups, or to body groups.  We are
not permitted to make a cycle.

        connectionRequest : ( from, to ) ->
            if to.typeName() isnt 'term' and to.typeName() isnt 'body'
                return
            if to.id() in ( c[1] for c in from.connectionsOut() )
                undoable -> from.disconnect to
            else if pathExists to.id(), from.id()
                alert 'That would create a cycle of arrows, which is not
                    permitted.'
            else
                undoable -> from.connect to

When drawing term groups, draw all arrows that come in or go out.  (The
default is to only draw arrows that go out; we override that here, so that a
term's type is clearly highlighted when the term is highlighted.)

        connections : ( group ) ->
            outs = group.connectionsOut()
            ins = group.connectionsIn()
            [ outs..., ins...,
              ( t[1] for t in outs )..., ( t[0] for t in ins )... ]
        # tagMenuItems : ( group ) -> ...compute them here...
    ]

The following function computes the meaning of a top-level Term Group in the
document.

    termGroupToCode = window.termGroupToCode = ( group ) ->
        groups = tinymce.activeEditor.Groups

If the group contains any other group, have the result be the empty string,
because that structure is invalid.

        if group.children.length > 0
            throw Error 'Invalid structure: Term groups may not contain
                other groups'

Start with the group's contents, as text.  This can be something as simple
as `1` for a term for the number one, or as complex as an entire proof
object, written in Lean syntax (e.g., `(assume H : p, ...big proof...)`).

        term = group.contentAsText().trim()

If this group has arrows to other groups, compute their meanings for use as
part of this group's meaning.

        args = ( connection[1] for connection in group.connectionsOut() )
        argMeanings = for arg in args
            try
                if groups[arg].typeName() is 'term'
                    termGroupToCode groups[arg]
                else
                    bodyGroupToCode groups[arg]
            catch e
                markValid groups[arg], no, e.message
                throw Error "A term to which this term points (directly or
                    indirectly) contains an error, and thus this term's
                    meaning cannot be determined."

If there were arguments, make this term an application of its head to those
arguments.

        if args.length > 0
            term = "( -- #{group.id()}\n
            #{term} -- #{group.id()}\n
            #{argMeanings.join '\n'}\n
            )"

Find any incoming arrows to this term that may matter below.

        parentTerms = [ ]
        assignedTypes = [ ]
        assignedBodies = [ ]
        for connection in group.connectionsIn()
            source = groups[connection[0]]
            if source.typeName() is 'type'
                type = source.contentAsText().trim()
                if type not in assignedTypes then assignedTypes.push type
            else if source.typeName() is 'body' and \
               source.id() not in assignedBodies
                assignedBodies.push source.id()
            else if source.typeName() is 'term'
                parentTerms.push source

If there is more than one type group modifying this group, or more than one
body group modifying this group, throw an error.  If this is a subterm of
another term, permit no type or body assignments.

        if assignedTypes.length > 1
            throw Error "Invalid structure: Two different types are assigned
                to this term (#{assignedTypes.join ', '})"
        if assignedBodies.length > 1
            throw Error "Invalid structure:
                Two bodies are assigned to this term."
        if parentTerms.length > 0
            if assignedTypes.length > 0
                throw Error "Invalid structure: A subterm of another term
                    cannot have a type assigned."
            if assignedBodies.length > 0
                throw Error "Invalid structure: A subterm of another term
                    cannot have a body assigned."

If we've found a unique type, insert it after the first identifier, or after
the end of the whole term.  For example, if the term were `a := b` we would
create `a : type := b`, but if it were `(and.intro H1 H2)` then we would
create `(and.intro H1 H2) : type`.

        if assignedTypes.length > 0
            type = assignedTypes[0]
            if match = /^\s*check\s+(.*)$/.exec term
                term = "check (#{match[1]} : #{type})"
            else if match = /^\s*check\s+\((.*)\)\s*$/.exec term
                term = "check (#{match[1]} : #{type})"
            else if match = /^(.*):=(.*)$/.exec term
                term = "#{match[1]} : #{type} := #{match[2]}"
            else
                term = "#{term} : #{type}"

Prepend any Lean command embedded in the group.

        if command = group.get 'leanCommand'
            term = leanCommands[command].replace 'TERM', term

Append a one-line comment character, followed by the group's ID, to track
where this line of code came from in the document, for the purposes of
transferring Lean output back to this group as user feedback.

        result = "#{term} -- #{group.id()}"

If we've found a unique body, insert it after the term, with a `:=` in
between.

        if assignedBodies.length > 0
            commandsTakingBodies = [ 'theorem', 'definition', 'example' ]
            if command not in commandsTakingBodies
                throw Error "Terms may only be assigned bodies if they embed
                    one of these commands:
                    #{commandsTakingBodies.join ', '}."
            result += "\n:= #{bodyGroupToCode groups[assignedBodies[0]]}"

Done computing the code for this term group.

        result

The following function converts the document into Lean code by calling
`termGroupToCode` on all top-level term groups in the document.  If this
array were joined with newlines between, it would be suitable for passing
to Lean.  It ignores non-term groups, and it ignores term groups that are
subterms of other terms.  The only exception to this is body terms not
attached to a term, which therefore function as sections.

    documentToCode = window.documentToCode = ->
        result = lines : [ ], errors : { }
        for group in tinymce.activeEditor.Groups.topLevel

If it's a section, handle that with `sectionGroupToCode`.

            if group.typeName() is 'body' and bodyIsASection group
                lineOrLines = sectionGroupToCode group
                result.lines = result.lines.concat lineOrLines.split '\n'
                continue

Then filter out non-terms and subterms.

            if group.typeName() isnt 'term' or isSubterm group
                continue

Here we call the appropriate code-generating function, and handle any errors
it generates.

            try
                lineOrLines = termGroupToCode group
                result.lines = result.lines.concat lineOrLines.split '\n'
            catch e
                result.errors[group.id()] = e.message
        result

Here is the `isSubterm` function used below.  It determines whether a term
group is a subterm of another term group.

    isSubterm = ( term ) ->
        for connection in term.connectionsIn()
            if tinymce.activeEditor.Groups[connection[0]].typeName() \
                is 'term' then return yes
        no

The following function determines if a body is attached to no term, and thus
functions as a section.

    bodyIsASection = ( group ) ->
        for connection in group.connectionsOut()
            if tinymce.activeEditor.Groups[connection[1]].typeName() \
                is 'term' then return no
        yes

The following function checks to see if you can get from one group to
another in the document by following connections forwards.  This is useful
in the code above for preventing cyclic connections.

It tracks which nodes we've visited (starting with none) and which nodes we
must explore from (starting with just the source).  At each step, it visits
the next unexplored node, marks it visited, and if it's the first stop
there, adds all its reachable neighbors to the nodes we must explore from.
If at any point we see the destination, say so.  If we finish exploring all
reachable nodes without seeing it, say so.

    pathExists = ( source, destination ) ->
        groups = tinymce.activeEditor.Groups
        visited = [ ]
        toExplore = [ source ]
        while toExplore.length > 0
            if ( nextId = toExplore.shift() ) is destination then return yes
            if nextId in visited then continue else visited.push nextId
            toExplore = toExplore.concat \
                ( c[1] for c in groups[nextId].connectionsOut() )
        no

## Type Groups

Declare a new type of group in the document, for Lean types.

    window.groupTypes.push
        name : 'type'
        text : 'Lean Type'
        tooltip : 'Make the selection a Lean type'
        color : '#66bb66'
        imageHTML : '<font color="#66bb66"><b>[ ]</b></font>'
        openImageHTML : '<font color="#66bb66"><b>[</b></font>'
        closeImageHTML : '<font color="#66bb66"><b>]</b></font>'
        contentsChanged : clearAllValidity

We can connect type groups to term groups only.  We are not permitted to
make a cycle.

        connectionRequest : ( from, to ) ->
            if to.typeName() isnt 'term' then return
            if to.id() in ( c[1] for c in from.connectionsOut() )
                undoable -> from.disconnect to
            else
                undoable -> from.connect to

Install the arrows UI so that types can connect to terms.

    window.useGroupConnectionsUI = yes

## Body Groups

Declare a new type of group in the document, for the bodies of definitions,
theorems, examples, sections, and namespaces.

    window.groupTypes.push
        name : 'body'
        text : 'Body of a Lean definition or section'
        tooltip : 'Make the selection a body'
        color : '#6666bb'
        imageHTML : '<font color="#6666bb"><b>[ ]</b></font>'
        openImageHTML : '<font color="#6666bb"><b>[</b></font>'
        closeImageHTML : '<font color="#6666bb"><b>]</b></font>'
        contentsChanged : clearAllValidity

Its context menu permits converting an unconnected body group between being
a namespace and being a section.

        contextMenuItems : ( group ) ->
            rename = ->
                newval = prompt 'Enter the identifier to use as the name of
                    the namespace.', group.get 'namespace'
                if newval isnt null
                    if not /^[a-zA-Z_][a-zA-Z0-9_]*$/.test newval
                        alert 'That was a valid Lean identifier.  No change
                            has been made to your document.'
                    else
                        group.set 'namespace', newval
            if not bodyIsASection group
                [ ]
            else if name = group.get 'namespace'
                [
                    text : 'Make this a section'
                    onclick : -> group.clear 'namespace'
                ,
                    text : 'Rename this namespace...'
                    onclick : rename
                ]
            else
                [
                    text : 'Make this a namespace...'
                    onclick : rename
                ]

If this body is unconnected to a term, then it functions as a section.

        tagContents : ( group ) ->
            if bodyIsASection group
                if name = group.get 'namespace'
                    "Namespace: #{name}"
                else
                    'Section'
            else
                ''

We can connect body groups to term groups only.  We are not permitted to
make a cycle.

        connectionRequest : ( from, to ) ->
            if to.typeName() isnt 'term' then return
            if to.id() in ( c[1] for c in from.connectionsOut() )
                undoable -> from.disconnect to
            else if pathExists to.id(), from.id()
                alert 'That would create a cycle of arrows, which is not
                    permitted.'
            else
                undoable -> from.connect to

The following function computes the meaning of a top-level Body Group in the
document.  It is like `termGroupToCode`, but for bodies instead.

    bodyGroupToCode = window.bodyGroupToCode = ( group ) ->

Find body/term-type children, and verify that at least one exists.  If not,
then we treat this as a special case, a body containing just one term,
expressed as Lean code.  (This is handy for very small bodies, such as a
single identifier or number.)

        children = ( child for child in group.children \
            when child.typeName() is 'term' or child.typeName() is 'body' )
        if children.length is 0
            return "#{group.contentAsText()} -- #{group.id()}"

Verify that none but the last one is a body group (although the last one is
also permitted to be a term group).

        for child, index in children[...-1]
            if child.typeName() is 'body'
                throw Error "A body group can only contain other body groups
                    as its final child.  This one has another body group
                    as child ##{index + 1}."

Verify that none of the children has a body group pointing to it, because
definitions, sections, etc. cannot be nested.

        groups = tinymce.activeEditor.Groups
        traverseForBodies = ( g ) ->
            for connection in g.connectionsIn()
                if groups[connection[0]].typeName() is 'body'
                    throw Error 'One of the groups inside this body has a
                        body group connected to it.  That type of nesting is
                        not permitted.'
            traverseForBodies child for child in g.children
        traverseForBodies group

Recur on all children that are not subterms of something else.

        results = [ ]
        for child in children
            if child.typeName() == 'term'
                if isSubterm child then continue
                results.push termGroupToCode child
            else
                results.push bodyGroupToCode child

Adjust all but the last entry to be assumptions, and we're done.

        for index in [0...results.length-1]
            match = /^(.*) -- (\d+)$/.exec results[index]
            results[index] = "assume #{match[1]}, -- #{match[2]}"
        results.join '\n'

An empty body functions as a section.

    sectionGroupToCode = window.sectionGroupToCode = ( group ) ->
        name = group.get 'namespace'
        type = if name then 'namespace' else 'section'
        suffix = name ? group.id()
        identifier = ( if type is 'namespace' then '' else type ) + suffix
        results = [ ]
        for child in group.children
            if isSubterm child then continue
            try
                if child.typeName() is 'term'
                    results.push termGroupToCode child
                else if child.typeName() is 'body'
                    if not bodyIsASection child then continue
                    results.push sectionGroupToCode child
            catch e
                markValid child, no, e.message
        "#{type} #{identifier} -- #{group.id()}\n
        #{results.join '\n'}\n
        end #{identifier} -- #{group.id()}"

## Substitutions

Now we install code that watches for certain key text pieces that can be
replaced by Lean-related symbols.

    window.afterEditorReady = ( editor ) ->
        editor.on 'KeyUp', ( event ) ->
            movements = [ 33..40 ] # arrows, pgup/pgdn/home/end
            modifiers = [ 16, 17, 18, 91 ] # alt, shift, ctrl, meta
            if event.keyCode in movements or event.keyCode in modifiers
                return
            range = editor.selection.getRng()
            if range.startContainer is range.endContainer and \
               range.startContainer instanceof editor.getWin().Text
                allText = range.startContainer.textContent
                lastCharacter = allText[range.startOffset-1]
                if lastCharacter isnt ' ' and lastCharacter isnt '\\' and \
                   lastCharacter isnt String.fromCharCode( 160 )
                    return
                allBefore = allText.substr 0, range.startOffset - 1
                allAfter = allText.substring range.startOffset - 1
                startFrom = allBefore.lastIndexOf '\\'
                if startFrom is -1 then return
                toReplace = allBefore.substr startFrom + 1
                allBefore = allBefore.substr 0, startFrom
                if not replaceWith = corrections[toReplace] then return
                newCursorPos = range.startOffset - toReplace.length - 1 + \
                    replaceWith.length
                if lastCharacter isnt '\\'
                    allAfter = allAfter.substr 1
                    newCursorPos--
                range.startContainer.textContent =
                    allBefore + replaceWith + allAfter
                range.setStart range.startContainer, newCursorPos
                range.setEnd range.startContainer, newCursorPos
                editor.selection.setRng range
