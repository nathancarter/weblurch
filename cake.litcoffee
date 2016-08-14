
# Build process definitions

This file defines the build processes in this repository. It is imported by
the `Cakefile` in this repository, the source code of which is kept to a
one-liner, so that most of the repository can be written in [the literate
variant of CoffeeScript]( http://coffeescript.org/#literate).

We keep a set of build utilities in a separate module, which we now load.

    build = require './buildutils'

## Options

All tests are run by default, but you can run just one if you prefer, with
this option.  It takes either a full test name, or any prefix thereof.  It
runs only one test, the first one whose filename matches the given name.  If
none do, cake halts with an error.

    option '-t', '--test [NAME]', 'Choose just one test to run'

## Easy way to build all

If you want to build and test evertything, just run `cake all`. It simply
invokes all the other tasks, defined below.

    build.task 'all', 'Build app and run tests', ->
        build.enqueue 'app', 'submodules', 'docs', 'test'

## Requirements

Verify that `npm install` has been run in this folder, then import other
modules we'll need later (which were installed by npm install).

    build.verifyPackagesInstalled()
    { parseString } = require 'xml2js'
    fs = require 'fs'
    exec = require( 'child_process' ).exec

## Constants

These constants define how the functions below perform.

    p = require 'path'
    title = 'webLurch'
    srcdir = p.resolve __dirname, 'src'
    srcorder = [
        'utils.litcoffee'
        'openmath-duo.litcoffee'
        'matching-duo.litcoffee'
    ]
    appdir = p.resolve __dirname, 'app'
    fddir = p.resolve appdir, 'filedialog'
    srcout = 'weblurch.litcoffee'
    appout = 'app.litcoffee'
    testdir = p.resolve __dirname, 'test'
    testresults = p.resolve testdir, 'test-results.md'
    repdir = p.resolve testdir, 'reports'
    jasmine = p.resolve __dirname, 'node_modules', 'jasmine-node', 'lib',
        'jasmine-node', 'cli.js'
    submodules =
        jsfs : "npm install
             && ./node_modules/.bin/cake all
             && cp demo/*.js demo/*.map demo/*.litcoffee demo/close.png
                   demo/copy.png demo/delete.png demo/folder.png
                   demo/move.png demo/text-file.png demo/up-arrow.png
                   node_modules/lz-string/libs/lz-string-1.3.3.js
                   #{fddir}"

## The `app` build process

    build.asyncTask 'app', 'Build the main app', ( done ) ->

Before building the app, ensure that the output folder exists.

        fs.mkdirSync appdir unless fs.existsSync appdir

Compute size of folder prefix, for showing relative paths later, for
brevity.

        L = __dirname.length + 1

Next concatenate all `.litcoffee` source files into one.  The only exception
to this rule is if any of them end in `-solo.litcoffee`, then they're
requesting that they be compiled individually.  So we filter those out.  We
also respect the ordering in `srcorder` to put some of the files first on
the list.

        all = build.dir srcdir, /.litcoffee$/
        moveup = [ ]
        for file in srcorder
            moveup = moveup.concat ( fullpath for fullpath in all \
                when RegExp( "/#{file}$" ).test fullpath )
        all = ( file for file in all when file not in moveup )
        all = moveup.concat all
        all = ( f for f in all when f[-15..] isnt '-solo.litcoffee' )
        build.concatFiles all, '\n\n', p.resolve appdir, srcout

Also compile any files specific to the main app, which will sit in the app
folder rather than the source folder.  The exceptions to this rule are:
 * if any of them end in `-solo.litcoffee`, then they're requesting that
   they be compiled individually, so we filter those out, and
 * if any of them end in `-duo.litcoffee`, then they've been copied to the
   app folder from the source folder, and don't need to be compiled again.

        all = ( f for f in build.dir( appdir, /\.litcoffee$/ ) \
            when f.indexOf( srcout ) is -1 and
                 f.indexOf( appout ) is -1 and
                 f[-15..] isnt '-solo.litcoffee' and
                 f[-14..] isnt '-duo.litcoffee' )
        build.concatFiles all, '\n\n', p.resolve appdir, appout

Run the compile process defined in [the build utilities
module](buildutils.litcoffee).  This compiles, minifies, and generates
source maps.  We run it in sequence on the source files, the app-specific
files, and the "solo" files in the app folder.

First, here is a little function that recursively runs the build process on
all `*-solo.litcoffee` files in the src and app folders.  It also processes
`*-duo.litcoffee` files, which are compiled into the app *and* compiled into
individual `.min.js` files (for importing into web workers).

        solofiles = build.dir appdir, /\-solo.litcoffee$/
        srcsolofiles = build.dir srcdir, /\-(solo|duo).litcoffee$/
        buildNext = ->
            if solofiles.length > 0
                build.compile solofiles.shift(), buildNext
            else if srcsolofiles.length > 0
                file = srcsolofiles.shift()
                prefix = file.split( '/' ).pop()[..-10]
                build.copyFile "src/#{prefix}litcoffee",
                    "app/#{prefix}litcoffee",
                    -> build.compile file, buildNext, appdir
            else
                done()

We put that function as the last step in the compilation sequence, by using
it as the last callback, below.

        build.compile p.resolve( appdir, srcout ), ->
            build.compile p.resolve( appdir, appout ), ->
                build.copyFile \
                    'node_modules/lz-string/libs/lz-string-1.3.3.js',
                    "#{appdir}/lz-string-1.3.3.js", buildNext

## The `submodules` build process

Although there is currently only one submodule, this task is ready in the
event that there will be more later.  It enters each of their subfolders and
runs any necessary build process on those submodules.  For instance, the
`jsfs` submodule requires compiling and minifying CoffeeScript code just
like this project does, because they are structured the same way.

    build.asyncTask 'submodules', 'Build any git submodule projects',
    ( done ) ->
        commands = for own submodule, command of submodules
            description : "Running #{submodule} build process...".green
            command : "cd #{submodule} && #{command} && cd .."
        build.runShellCommands commands, done

## The `docs` build process

We use [mkdocs](http://www.mkdocs.org), so this is a single shell command.

    build.asyncTask 'docs', 'Run mkdocs to convert doc-src/ into docs/',
    ( done ) ->
        build.runShellCommands [
            description : "Running mkdocs build...".green
            command : "mkdocs build"
        ], done

## The `test` build process

    build.asyncTask 'test', 'Run unit tests', ( done, options ) ->

First remove all old reports in the test reports folder. If we do not do
this, then any deleted tests will still have their reports lingering in the
output folder forever.

        fs.mkdirSync repdir unless fs.existsSync repdir
        for report in fs.readdirSync repdir
            fs.unlinkSync p.resolve repdir, report

If the `--test` option was used, then just run that one test instead.  In
case the option precedes just a prefix of the test suite to run, search the
test folder for all files that match, and use the first.

        target = testdir
        if options.test?
            for testfile in fs.readdirSync testdir
                if testfile[...options.test.length] is options.test
                    target = p.resolve target, testfile
                    break
            if target is testdir
                console.log "Found no tests starting with
                    #{options.test}.".red
                process.exit 1

Run [jasmine](http://jasmine.github.io/) on all files in the `test/` folder,
and produce output in `junitreport` format (a bunch of XML files).

        exec "node #{jasmine} --junitreport --output #{repdir} --verbose
                   --coffee --forceexit #{target}",
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr

Create the header for the test output page and two functions for flagging
test passes/failures with the appropriate CSS classes.

            md = '''
                 # Autogenerated test results

                 This file was autogenerated by the build system.


                 '''
            pass = '<span class="test-pass">Pass</span>'
            re = /^Expected (.*) to equal (.*)\.$/
            fail = ( x ) ->

The following if/try block is a simple attempt at formatting object code
nicer.  It will not work in all situations, but it is nice for those
situations in which it does work.  The difficult-to-read output that comes
to the console will appear much more nicely in the web output, and the
developer can look there to help compare the unmatched objects.

                if m = re.exec x
                    try
                        obj1 = JSON.parse m[1] \
                            .replace( /&apos;/g, '"' ) \
                            .replace( /([{,])\s*(\w+)\s*:/g,
                                '$1 "$2" :' )
                        obj2 = JSON.parse m[2] \
                            .replace( /&apos;/g, '"' ) \
                            .replace( /([{,])\s*(\w+)\s*:/g,
                                '$1 "$2" :' )
                        x = "Expected these to be equal:
                            <br>
                            <table width=100% cellspacing=0
                                   cellpadding=0>
                            <tr><td>
                            Actual:
                            \n
                            \n```
                            \n#{JSON.stringify obj1, null, 2}
                            \n```
                            \n
                            \n</td><td>
                            Expected:
                            \n
                            \n```
                            \n#{JSON.stringify obj2, null, 2}
                            \n```
                            \n</td></tr></table>"
                "<span class='test-fail'>Failure: #{x}</span>"

Read those XML files and produce [Markdown](markdown) output, all together
into a single output file.

            for report in build.dir repdir, /\.xml$/i
                parseString fs.readFileSync( report ),
                ( err, result ) ->
                    for item in result.testsuites.testsuite

Create header for this test and a subheader for each case within it.

                        name = item.$.name
                        md += "## #{name} (#{item.$.time} ms)\n\n"
                        for c in item.testcase
                            cn = c.$.name
                            md += "### #{cn} (#{c.$.time} ms)\n\n"

Create list item for each failure, or one single item reporting a pass if
there were no failures.

                            if c.failure
                                for f in c.failure
                                    md += " * #{fail f.$.message}\n\n"
                            else
                                md += " * #{pass}\n\n"

Create a footer for this test, summarizing its time and totals.

                        md += "Above tests run at
                               #{item.$.timestamp}.
                               Tests: #{item.$.tests} -
                               Errors: #{item.$.errors} -
                               Failures: #{item.$.failures}\n\n"

That output file goes in the `doc/` folder for later processing by the doc
task, defined above.

            fs.writeFileSync testresults, md, 'utf8'

If a test failed, stop here and return the failure exit code, so that this
script will indicate to the shell that the tests did not all pass.
Otherwise, move on to the next task (or a peaceful exit) with `done()`.

            if err then process.exit err.code
            done()

## The `pages` build process

After changes are made to the master branch of this repository in git, we
eventually want to propagate them to the gh-pages branch, because that
branch is the one that github uses as the basis for the project web pages
(hence the name, short for "github pages"). Usually you should do this
before pushing commits to github, so that the website on github reflects the
latest state of the repository.

This build task switches to the gh-pages branch, merges in all changes from
master, re-runs all other build tasks, commits the resulting documentation
changes, and switches branches back to master.  It's just what you should
run before pushing to github.

It's an asynchronous task because it uses `exec`.  We begin with switching
to gh-pages and merging in changes.

    build.asyncTask 'pages',
    'Update gh-pages branch before pushing', ( done ) ->
        console.log '''
            In case any step of this lengthy process goes wrong,
            here are the commands that are about to be run, so
            that you can complete the process:
                git checkout gh-pages
                git merge master --no-commit
                touch app/*-solo.litcoffee
                touch app/setup.litcoffee
                touch src/*.litcoffee
                cake app
                cake submodules
                cake docs
                git commit -a -m 'Updating gh-pages with latest app build'
                git checkout master
            '''.yellow
        build.runShellCommands [
            description : 'Switching to gh-pages branch...'.green
            command : 'git checkout gh-pages'
        ,
            description : 'Merging in changes...'.green
            command : 'git merge master --no-commit'
        ,
            description : 'Pausing a moment...'.green
            command : 'sleep 2'
        ,
            description : 'Marking app files dirty...'.green
            command : 'touch app/*-solo.litcoffee'
        ,
            description : 'Marking setup file dirty...'.green
            command : 'touch app/setup.litcoffee'
        ,
            description : 'Pausing a moment...'.green
            command : 'sleep 2'
        ,
            description : 'Marking src files dirty...'.green
            command : 'touch src/*.litcoffee'
        ], ->
            console.log 'Building app and submodules in gh-pages...'.green
            build.enqueue 'app', 'submodules', 'docs', ->
                build.runShellCommands [
                    description : 'Committing changes... (which may fail if
                        there were no changes to the app itself; in that
                        case, just git checkout master and push.)'.green
                    command : "git commit -a -m 'Updating gh-pages with
                        latest generated docs'"
                ,
                    description : 'Going back to master...'.green
                    command : 'git checkout master'
                ], ->
                    console.log 'Done.'.green
                    console.log '''
                    If you're happy with the results of this process, just \
                    type "git push" to publish them.
                    '''

We report that we're done with this task once we enqueue those things, so
that the build system will then start processing what we put on the queue.

            done()
