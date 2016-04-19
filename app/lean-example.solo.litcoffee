
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

    window.runLeanOn = ( code ) ->
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
        # Module.lean_process_file 'test.lean'
        # console.log '--- Lean has been run on test.lean.', checkTimer()
        LeanOutputArray

## Term Groups

    window.groupTypes = [
        name : 'term'
        text : 'Lean Term'
        tooltip : 'Make the selection a Lean term'
        color : '#666666'
        imageHTML : '<font color="#666666"><b>[ ]</b></font>'
        openImageHTML : '<font color="#666666"><b>[</b></font>'
        closeImageHTML : '<font color="#666666"><b>]</b></font>'
        # contentsChanged : ( group, firstTime ) -> ...nothing here yet...
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
        "#{group.contentAsText()} # #{group.id()}"

The following function converts the document into Lean code by calling
`termGroupToCode` on all top-level term groups in the document, and joining
the results with newlines between.

    documentToCode = window.documentToCode = ->
        ( termGroupToCode g \
            for g in tinymce.activeEditor.Groups.topLevel ).join '\n'
