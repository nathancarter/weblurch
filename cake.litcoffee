
# Build process definitions

This file defines the build processes in this repository.
It is imported by the `Cakefile` in this repository,
the source code of which is kept to a one-liner,
so that most of the repository can be written
in [the literate variant of CoffeeScript][litcoffee].

## Easy way to build all

If you want to build and test evertything, just run `cake all`.
It simply invokes all the other tasks, defined below.

    queue = []
    dequeue = -> if queue.length > 0 then invoke queue.shift()
    task 'all', 'Build app, testapp, docs, and run tests', ->
        queue = [ 'app', 'testapp', 'test', 'doc' ]
        dequeue()

## Requirements

First, verify that `npm install` has been run in this folder.

    fs = require 'fs'
    pkg = JSON.parse fs.readFileSync 'package.json'
    for key of pkg.dependencies
        if !fs.existsSync "./node_modules/#{key}"
            console.log """
                        This folder is not yet set up.
                        Missing node.js package: #{key}
                        To fix this, run: npm install
                        """
            process.exit 1

Next import other modules we'll need later.

    { exec } = require 'child_process'
    { parseString } = require 'xml2js'

## Constants

These constants define how the functions below perform.

    srcdir = './src/'
    appdir = './app/'
    tappdir = './testapp/'
    srcout = 'weblurch.litcoffee'
    tappout = 'testapp.litcoffee'
    docdir = './doc/'
    doctmp = 'template.html'
    testdir = './test/'
    repdir = './reports/'
    mapfile = './reports/unit-test-names.json'
    linkpng = '<img src="link.png" class="anchor">'
    mainpg = 'index.md'

## The `app` build process

    task 'app', 'Build the main app', ( options ) ->
        console.log 'Begin building app...'

Before building the app, ensure that the output folder exists.

        fs.mkdirSync appdir unless fs.existsSync appdir

Next concatenate all `.litcoffee` source files into one.

        all = []
        for file, index in fs.readdirSync srcdir
            if /\.litcoffee$/.test file
                console.log "\tReading #{srcdir + file}..."
                all.push fs.readFileSync srcdir + file, 'utf8'
        console.log "\tWriting #{appdir+srcout}..."
        fs.writeFileSync appdir+srcout, all.join( '\n\n' ), 'utf8'

Run `coffee` compiler on that file, also creating a source map.
This generates `.js` and `.js.map` files.

        console.log "\tCompiling #{appdir+srcout}..."
        exec "coffee --map --compile #{srcout}", { cwd : appdir },
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr
            throw err if err

Run [uglifyjs](https://github.com/mishoo/UglifyJS)
to minify the results, taking source maps into account.
Report completion when done, or throw an error if there was one.
(Note that `uglify` output is not printed unless there was an
error, because uglify dumps a bit of spam I'm suppressing.)

            srcoutbase = /^(.*)\.[^.]*$/.exec( srcout )[1]
            console.log "\tMinifying #{srcoutbase}.js..."
            exec "../node_modules/uglify-js/bin/uglifyjs " +
                 "-c -m -v false " +
                 "--in-source-map #{srcoutbase}.map " +
                 "-o #{srcoutbase}.min.js " +
                 "--source-map #{srcoutbase}.min.js.map",
            { cwd : appdir }, ( err, stdout, stderr ) ->
                if err
                    console.log stdout + stderr
                    throw err
                console.log 'Done building app.'
                dequeue()

## The `testapp` build process

This build process is nearly identical to that of `app`.

    task 'testapp', 'Build the testapp', ( options ) ->
        console.log 'Begin building testapp...'

Before building, ensure that the output folder exists.

        fs.mkdirSync tappdir unless fs.existsSync tappdir

Next concatenate all `.litcoffee` source files from the test app
directory into one.

        all = []
        for file, index in fs.readdirSync tappdir
            if file isnt tappout and /\.litcoffee$/.test file
                console.log "\tReading #{tappdir + file}..."
                all.push fs.readFileSync tappdir + file, 'utf8'
        console.log "\tWriting #{tappdir+tappout}..."
        fs.writeFileSync tappdir+tappout, all.join( '\n\n' ),
            'utf8'

Run `coffee` compiler on that file, also creating a source map.
This generates `.js` and `.js.map` files.

        console.log "\tCompiling #{tappdir+tappout}..."
        exec "coffee --map --compile #{tappout}",
        { cwd : tappdir }, ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr
            throw err if err

Run [uglifyjs](https://github.com/mishoo/UglifyJS)
to minify the results, taking source maps into account.
Report completion when done, or throw an error if there was one.
(Note that `uglify` output is not printed unless there was an
error, because uglify dumps a bit of spam I'm suppressing.)

            tappoutbase = /^(.*)\.[^.]*$/.exec( tappout )[1]
            console.log "\tMinifying #{tappoutbase}.js..."
            exec "../node_modules/uglify-js/bin/uglifyjs " +
                 "-c -m -v false " +
                 "--in-source-map #{tappoutbase}.map " +
                 "-o #{tappoutbase}.min.js " +
                 "--source-map #{tappoutbase}.min.js.map",
            { cwd : tappdir }, ( err, stdout, stderr ) ->
                if err
                    console.log stdout + stderr
                    throw err
                console.log 'Done building testapp.'
                dequeue()

## The `doc` build process

    task 'doc', 'Build the documentation', ( options ) ->
        console.log 'Begin building doc...'

Fetch all files in the source directory, plus this file,
plus any `.md` files in the `doc/` dir that need converting,
and the template HTML output file from the `doc/` directory.

        all = [ 'cake.litcoffee' ]
        all = all.concat( srcdir + f for f in \
            fs.readdirSync srcdir when /\.litcoffee$/.test( f ) )
        all = all.concat( testdir + f for f in \
            fs.readdirSync testdir when /\.litcoffee$/.test( f ) )
        all = all.concat( docdir + f for f in \
            fs.readdirSync docdir when /\.md$/.test( f ) )
        all = all.concat( tappdir + f for f in \
            fs.readdirSync tappdir when /\.litcoffee$/.test( f ) \
            and f isnt tappout )
        html = fs.readFileSync docdir + doctmp, 'utf8'

Build a file navigation list from those files' names.

        nav = {}
        navtxt = '<h3 align=center>Navigation</h3><br>'
        for file in all
            end = ( path = file.split '/' ).pop()
            if end is mainpg
                navtxt += "<h3><a href='#{mainpg}.html'>" +
                          "Main Page</a></h3>"
            else
                ( nav[path.join '/'] ?= [] ).push {
                    file : end, text : end }
        ( nav[appdir[...-1]] ?= [] ).push {
            file : ".#{appdir}index", text : 'index.html' }
        ( nav[tappdir[...-1]] ?= [] ).push {
            file : ".#{tappdir}index", text : 'index.html' }
        for path in ( Object.keys nav ).sort()
            navtxt += "<p>#{path || './'}</p><ul>"
            for e in nav[path]
                navtxt += "<li><a href='#{e.file}.html'>" +
                          "#{e.text}</a></li>"
            navtxt += '</ul>'

Load the [marked](https://github.com/chjj/marked) module,
for parsing [Markdown](markdown)
and doing syntax highlighting of indented code blocks.
Set its options to use [hightlight.js](http://highlightjs.org/)
for code highlighting, which handles
[coffeescript](http://coffeescript.org/) very well,
and one of whose stylesheets is already installed
in the `doc/` output folder.

        marked = require 'marked'
        renderer = new marked.Renderer()
        renderer.heading = ( text, level ) ->
            if m = /^(.*) \([0-9.]+ ms\)/.exec text
                escapedText = escapeHeadingText m[1]
            else
                escapedText = escapeHeadingText text
            if marked.isTestFile
                results = "<font size=-1><a href='" +
                          "test-results.md.html#" +
                          "#{escapedText}'>see results</a></font>"
            else
                results = ''
            "<h#{level}><a name='#{escapedText}'></a>#{text} " +
            "&nbsp; #{results} <font size=-1><a href='" +
            "##{escapedText}'>#{linkpng}</a></font></h#{level}>"
        marked.setOptions
            highlight: ( code ) ->
                require( 'highlight.js' ) \
                    .highlightAuto( code ).value
            renderer: renderer

Read each source file and place its marked-down version into the
HTML template, saving it into the docs directory.

        for file in all
            end = file.split( '/' ).pop()
            console.log "\tCreating #{end}.html..."
            contents = fs.readFileSync file, 'utf8'
            marked.isTestFile = /-spec\.litcoffee/.test end
            myhtml = html.replace( 'LEFT',
                                   'weblurch source code docs' )
                         .replace( 'RIGHT', navtxt )
                         .replace( 'MIDDLE', marked contents )
                         .replace( /<pre><code>/g,
                                   '<pre class="hljs"><code>' )
            fs.writeFileSync "#{docdir+end}.html", myhtml, 'utf8'

Indicate successful completion of the task.

        console.log 'Done building doc.'
        dequeue()

## The `test` build process

    task 'test', 'Run all unit tests', ->
        console.log '''Begin tests...
                       (Please wait while PhantomJS loads.)'''

First remove all old reports in the test reports folder.
If we do not do this, then any deleted tests will still have their
reports lingering in the output folder forever.

        for report in fs.readdirSync repdir
            fs.unlinkSync repdir + report

Run [jasmine](http://jasmine.github.io/) on all files in the
`test/` folder, and produce output in `junitreport` format (a
bunch of XML files).

        exec "node node_modules/jasmine-node/lib/jasmine-node/" +
             "cli.js --junitreport --verbose --coffee #{testdir}",
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr

Now that the tests have been run, see if they created a file
mapping the unit test names to the files in which they are defined.
If so, we will use it below to create links from test results to
test definition files.

            try
                mapping = JSON.parse fs.readFileSync mapfile
            catch error
                mapping = null

Create the header for the test output page and two functions for
flagging test passes/failures with the appropriate CSS classes.

            md = '''
                 # Autogenerated test results

                 This file was autogenerated by the build system.


                 '''
            pass = '<span class="test-pass">Pass</span>'
            fail = ( x ) ->
                "<span class='test-fail'>Failure #{x}</span>"

Read those XML files and produce [Markdown](markdown) output,
all together into a single output file.

            for report in fs.readdirSync repdir
                if !/\.xml$/i.test report then continue
                parseString fs.readFileSync( repdir + report ),
                ( err, result ) ->
                    for item in result.testsuites.testsuite

Create header for this test.  Use the `mapping` computed above to
create links, if possible.

                        name = item.$.name
                        md += "# #{name} (#{item.$.time} ms)"
                        if name of mapping
                            escapedName = escapeHeadingText name
                            md += " <font size=-1>" +
                                  "<a href='#{mapping[name]}" +
                                  ".html##{escapedName}'>" +
                                  "see source</a></font>"
                        md += '\n\n'

Create subheader for each case in the test.  Again, use the
`mapping` computed above to create links, if possible.

                        for c in item.testcase
                            cn = c.$.name
                            md += "### #{cn} (#{c.$.time} ms)"
                            if item.$.name of mapping
                                esc = escapeHeadingText c.$.name
                                md += " <font size=-1>" +
                                      "<a href='" +
                                      "#{mapping[item.$.name]}." +
                                      "html##{esc}'>see source" +
                                      "</a></font>"
                            md += '\n\n'

Create list item for each failure, or one single item reporting
a pass if there were no failures.

                            if c.failure
                                for f in c.failure
                                    md += " * #{fail f}\n\n"
                            else
                                md += " * #{pass}\n\n"

Create a footer for this test, summarizing its time and totals.

                        md += "Above tests run at " +
                              "#{item.$.timestamp}.  " +
                              "Tests: #{item.$.tests} - " +
                              "Errors: #{item.$.errors} - " +
                              "Failures: #{item.$.failures}\n\n"

That output file goes in the `doc/` folder for later processing
by the doc task, defined above.

            fs.writeFileSync "#{docdir}/test-results.md",
                md, 'utf8'

Indicate successful completion of the task.

            console.log 'Tests done.'
            dequeue()

Function that escapes heading text into lower-case text with no
spaces, used in a few of the tasks above.

    escapeHeadingText = ( text ) ->
        text.toLowerCase().replace /[^\w]+/g, '-'

[litcoffee]: (http://coffeescript.org/#literate)
[markdown]: (http://daringfireball.net/projects/markdown/)

