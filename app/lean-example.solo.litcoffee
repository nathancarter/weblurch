
# Lean Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example.solo.litcoffee) and then
for [the complex example application](complex-example.solo.litcoffee).
This application is more useful than either of those.

    setAppName 'LeanApp'
    addHelpMenuSourceCodeLink 'app/lean-example.solo.litcoffee'

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

    markValid = ( group, validOrNot, message ) ->
        color = if validOrNot then 'green' else 'red'
        symbol = if validOrNot then '&#10003;' else '&#10006;'
        group.set 'closeDecoration',
            "<font color='#{color}'>#{symbol}</font>"
        group.set 'closeHoverText', message
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
        for line, index in leanInput = documentToCode()
            if m = /[ ]--[ ](\d+)$/.exec line
                lineToGroupId[index + 1] = parseInt m[1]

Run Lean on that input and process all output.

        lastError = -1
        for message in runLeanOn leanInput.join '\n'
            id = lineToGroupId[message.line]
            if isError = /error:/.test message.info then lastError = id
            markValid groups[id], not isError,
                "#{message.info + message.text.join '\n'}
                 (character ##{parseInt( message.char) + 1})"
        for id in groups.ids()
            if id is lastError then break
            if not hasValidity groups[id]
                markValid groups[id], yes, 'No errors reported.'

Validation is complete.

        validationRunning = no

## Term Groups

    window.groupTypes = [
        name : 'term'
        text : 'Lean Term'
        tooltip : 'Make the selection a Lean term'
        color : '#666666'
        imageHTML : '<font color="#666666"><b>[ ]</b></font>'
        openImageHTML : '<font color="#666666"><b>[</b></font>'
        closeImageHTML : '<font color="#666666"><b>]</b></font>'
        contentsChanged : clearAllValidity
        # tagContents : ( group ) -> ...nothing here yet...
        # tagMenuItems : ( group ) -> ...compute them here...
        # contextMenuItems : ( group ) -> ...compute them here...
    ]

The following function computes the meaning of a top-level Term Group in the
document.  If the group contains any other group, have the result be the
empty string.  Otherwise, the result is the group's contents, as text,
followed by a one-line comment character, followed by the group's ID.

    termGroupToCode = window.termGroupToCode = ( group ) ->
        if group.children.length > 0 then return ''
        "#{group.contentAsText()} -- #{group.id()}"

The following function converts the document into Lean code by calling
`termGroupToCode` on all top-level term groups in the document.  If this
array were joined with newlines between, it would be suitable for passing
to Lean.

    documentToCode = window.documentToCode = ->
        for group in tinymce.activeEditor.Groups.topLevel
            termGroupToCode group
