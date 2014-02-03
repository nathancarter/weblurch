
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
    task 'all', 'Build app, doc, and run tests', ->
        queue = [ 'app', 'doc', 'test' ]
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

## Constants

These constants define how the functions below perform.

    srcdir = './src/'
    outdir = './app/'
    srcout = 'weblurch.litcoffee'
    docdir = './doc/'
    doctmp = 'template.html'
    testdir = './test/'

## The `app` build process

    task 'app', 'Build the entire app', ( options ) ->
        console.log 'Begin building app...'

Before building the app, ensure that the output folder exists.

        if !fs.existsSync 'app'
            fs.mkdirSync 'app'

Next concatenate all `.litcoffee` source files into one.

        all = []
        for file, index in fs.readdirSync srcdir
            do ( file, index ) ->
                if /\.litcoffee$/.test file
                    console.log "\tReading #{srcdir + file}..."
                    all.push fs.readFileSync srcdir + file, 'utf8'
        console.log "\tWriting #{outdir+srcout}..."
        fs.writeFileSync outdir+srcout, all.join( '\n\n' ), 'utf8'

Run `coffee` compiler on that file, also creating a source map.
This generates `.js` and `.js.map` files.

        console.log "\tCompiling #{outdir+srcout}..."
        exec "coffee --map --compile #{srcout}", { cwd : outdir },
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
                 { cwd : outdir },
            ( err, stdout, stderr ) ->
                if err
                    console.log stdout + stderr
                    throw err
                console.log 'Done building app.'
                dequeue()

## The `doc` build process

    task 'doc', 'Build the documentation', ( options ) ->
        console.log 'Begin building doc...'

Fetch all files in the source directory, plus this file,
plus any `.md` files in the `doc/` dir that need converting,
and the template HTML output file from the `doc/` directory.

        all = ( srcdir + f for f in fs.readdirSync srcdir )
        all.push 'cake.litcoffee'
        all = all.concat( testdir + f for f in \
            fs.readdirSync testdir when /\.litcoffee$/.test( f ) )
        all = all.concat( docdir + f for f in \
            fs.readdirSync docdir when /\.md$/.test( f ) )
        html = fs.readFileSync docdir + doctmp, 'utf8'

Build a file navigation list from those files' names.

        nav = {}
        for file in all
            end = ( path = file.split '/' ).pop()
            ( nav[path.join '/'] ?= [] ).push end
        navtxt = ''
        for path, entries of nav
            navtxt += "<p>#{path || './'}</p><ul>"
            for e in entries
                navtxt += "<li><a href='#{e}.html'>#{e}</a></li>"
            navtxt += '</ul>'

Load the [marked](https://github.com/chjj/marked) module,
for parsing markdown
and doing syntax highlighting of indented code blocks.
Set its options to use [hightlight.js](http://highlightjs.org/)
for code highlighting, which handles
[coffeescript](http://coffeescript.org/) very well,
and one of whose stylesheets is already installed
in the `doc/` output folder.

        marked = require 'marked'
        marked.setOptions highlight: ( code ) ->
            require( 'highlight.js' ).highlightAuto( code ).value

Read each source file and place its marked-down version into the
HTML template, saving it into the docs directory.

        for file in all
            end = file.split( '/' ).pop()
            console.log "\tCreating #{end}.html..."
            contents = fs.readFileSync file, 'utf8'
            myhtml = html.replace( 'RIGHT',
                                   'weblurch source code docs' )
                         .replace( 'LEFT', navtxt )
                         .replace( 'MIDDLE', marked contents )
                         .replace( /<pre><code>/g,
                                   '<pre class="hljs"><code>' )
            fs.writeFileSync "#{docdir+end}.html", myhtml, 'utf8'

Indicate successful completion of the task.

        console.log 'Done building doc.'
        dequeue()

## The `test` build process

    task 'test', 'Run all unit tests', ->
        console.log 'Begin tests...'
        exec "node node_modules/jasmine-node/lib/jasmine-node/" +
             "cli.js --verbose --coffee #{testdir}",
             (err, stdout, stderr) ->
                 console.log stdout + stderr if stdout + stderr
                 throw err if err
                 console.log 'Tests done.'
                 dequeue()

[litcoffee]: (http://coffeescript.org/#literate)

