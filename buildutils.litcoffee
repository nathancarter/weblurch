
# Utility functions supporting the build process

Several places in this module we access the filesystem, or spawn
child processes with `exec`.  So import those modules up front.

    fs = require 'fs'
    { exec } = require 'child_process'

## Task queue

### Enqueueing and dequeueing tasks

The next few functions make it possible to add tasks to a queue and
dequeue them later into active duty.  Enqueueing any string stores
it for later execution, which happens when you dequeue; that passes
the string to `cake`'s `invoke`.  Such strings should be names of
tasks defined in the cakefile.

First, we need an empty queue.

    queue = []

Next, the enqueue function simply pushes onto that array.

    exports.enqueue = ( tasks... ) ->
        queue = queue.concat tasks

The dequeue function passes the next task name on the queue to
`cake`'s `invoke` function (thereby removing it from the queue), if
and only if there is a next task to dequeue.  The exception to this
is that if the next task on the queue is not a string (a task name)
but instead is a function, then we just call it.

    exports.dequeue = ->
        if queue.length > 0
            next = queue.shift()
            if typeof next is 'string' then invoke next else next()

### Automatic dequeueing and messaging

Each task function would therefore have to end with a call to
`dequeue`, so that after each task is completed, if there are more
tasks still in the queue, the next one gets run.  But that is
undesirable.  It would be better if the task definer provided by
`cake` did this for us.  So we redefine it to do so.

While we're at it, we will print messages saying which tasks are
being started/completed, so that the individual tasks no longer
need to handle that on their own.

First, define a new task function unique to this module.

    exports.task = ( name, description, func ) ->

Call the cake task function, but this time supply a different task
execution function, one that does whatever the actual task function
is, then calls dequeue.

        task name, description, ->
            console.log "Begin building #{name}..."
            func()
            console.log "Done building #{name}."
            exports.dequeue()

Now, some build tasks may be asynchronous, and we'll need to wait
until they're done before calling dequeue.  So here's a way to
define asynchronous tasks whose task functions will take a `done`
function that you should call when the task is done.

    exports.asyncTask = ( name, description, func ) ->
        task name, description, ->
            console.log "Begin building #{name}..."
            func ->
                console.log "Done building #{name}."
                exports.dequeue()

Those last lines mean that your asynchronous task function needs to
take a `done` function as parameter, and call it when the task is
finally complete.  It will then print done and do a dequeue.

## Verifying npm install has been run

It is useful to verify that `npm install` has been run in this
folder before attempting to load `node` modules mentioned in the
`package.json` file.

This is because the build process relies on a few such modules, and
it is very frustrating for the build process to crash because it's
missing one of them, showing what would be a cryptic error message
to a new downloader.  So this routine first checks to be sure that
the required modules are present, and exits with a helpful error
message if any are not.

    exports.verifyPackagesInstalled = ->
        pj = JSON.parse fs.readFileSync 'package.json'
        missing = ( key for key of pj.dependencies when \
            not fs.existsSync "./node_modules/#{key}" )
            .join ', '
        if missing isnt ''
            console.log """
                        This folder is not yet set up.
                        Missing node.js package(s): #{missing}
                        To fix this, run: npm install
                        """
            process.exit 1

## Fetching filenames from a folder

Often during the build process, we need a list of all files of a
certain type in a certain directory.  This simple function does
that for us, returning the result as an array.

It takes parameters in pairs, a folder as a string, then a regexp
to use for filtering files in that folder (only those that match
are returned).  As many folder-regexp pairs as you want may be
passed; the concatenated results are returned, each as a string
that begins with the folder name it belongs in (e.g.,
`'data/images/thing.png'`).

    exports.dir = ( args... ) ->
        result = []
        for i in [0...args.length-1] by 2
            if args[i][-1..] != '/' then args[i] += '/'
            for file in fs.readdirSync args[i]
                if args[i+1].test file
                    result.push args[i]+file
        result

## Loading contents of text files

It is convenient to be able to load the contents of many text files
at once, and this function does so.  Pass it an array of filenames,
and you get back an object whose keys are those filenames and whose
values are the text contents of the files.

Obviously for many very large files, this will use a lot of memory.
For a reasonable number of text files, there is no problem.

    exports.readFiles = ( names ) ->
        result = { }
        for name in names
            console.log "\tReading #{name}..."
            result[name] = fs.readFileSync name, 'utf8'
        result

## Compile literate coffeescript files

Call this function with an input filename and a callback function.
The input filename should contain the path also, unless it is the
current directory.

The input file should be a `.litcoffee` file, and this function
will generate a corresponding `.js` file (compiled coffeescript),
`.min.js` file (minified version of the previous), and
`.map` and `.min.js.map` files (source map files for both).
When the compilation is done, the callback function will be called.

    exports.compile = ( srcfile, callback ) ->

Separate the path and filename out from one another.

        [ all, path, file ] = /^(.*)\/([^\\]*)$/.exec srcfile
        console.log "\tCompiling #{srcfile}..."

Run the `coffee` compiler on the file, also creating a source map.
This generates both `.js` and `.js.map` files.

        exec "coffee --map --compile #{file}", { cwd : path },
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr
            throw err if err

Run [uglifyjs](http://github.com/mishoo/UglifyJS) to minify the
results, taking source maps into account.  Call the callback when
done, or throw an error if there was one.

(The `uglify` output is not printed unless there was an error,
because `uglify` dumps a bit of spam I'm suppressing.)

            base = /^(.*)\.[^.]*$/.exec( file )[1]
            console.log "\tMinifying #{base}.js..."
            exec "../node_modules/uglify-js/bin/uglifyjs " +
                 "-c -m -v false --in-source-map #{base}.map " +
                 "-o #{base}.min.js " +
                 "--source-map #{base}.min.js.map", { cwd : path },
            ( err, stdout, stderr ) ->
                if err then console.log stdout + stderr ; throw err
                callback()

## Converting Markdown to HTML

The following function uses the
[marked](http://github.com/chjj/marked) module to parse
[Markdown](http://daringfireball.net/projects/markdown), including
syntax highlighting of indented code blocks as
[coffeescript](http://coffeescript.org).  The highlighting is done
by [highlight.js](http://highlightjs.org), and one of its
stylehseets is already installed in the `doc/` output folder.

The following image is used to indicate an anchor.

    linkcode = '<span class="glyphicon glyphicon-link"></span>'

And now, the conversion function.

    exports.md2html = ( infile ) ->
        marked = require 'marked'

We install a routine that creates headings in the format we want
them for our documentation.  This routine makes each heading an
anchor so that links can point to it.  It also makes headings in
test files include links to the results of those tests.  Finally,
it remembers all the headings it makes in a file, and returns not
only the generated HTML but a corresponding table of contents (TOC)
with links to each of the anchors in each of the generated
headings.

        renderer = new marked.Renderer()
        toc = ''
        lastlevel = 1
        renderer.heading = ( text, level ) ->

Remove any instances of XHTML escape characters before creating
links, to be consistent with anchor names generated elsewhere.

            collapsed = text.replace( /&\w+;/g, ' ' )
            if m = /^(.*) \([0-9.]+ ms\)/.exec collapsed
                escapedText = exports.escapeHeading m[1]
            else
                escapedText = exports.escapeHeading collapsed

If this is a heading in a test suite, create a link to the test
results.  The only exception is top-level headings, which do not
have corresponding entries in the test suite resutls page.

            if level > 1 and /-spec\.litcoffee/.test infile
                results = "<font size=-1><a href='" +
                          "test-results.md.html#" +
                          "#{escapedText}'>see results</a></font>"
            else
                results = ''

Accrue headings in the `toc` variable declared above.

            if level > lastlevel
                toc += '<ul>\n'
                lastlevel = level
            while level < lastlevel
                toc += '</ul>\n'
                lastlevel = level
            toc += "<#{if level > 1 then 'li' else 'p'}>" +
                   "<a href='##{escapedText}'>#{text}</a>" +
                   "</#{if level > 1 then 'li' else 'p'}>"

Return the final HTML string for the heading

            "<h#{level}><a name='#{escapedText}'></a>#{text} " +
            "&nbsp; #{results} <font size=-1><a href='" +
            "##{escapedText}'>#{linkcode}</a></font></h#{level}>"

Install the renderer just created, as well as highlighting support
provided by `highlight.js`.

        marked.setOptions
            highlight: ( code ) ->
                hljs = require( 'highlight.js' )
                lang = 'coffeescript'
                if /^\s*#\s*(html|HTML)\s*\n/.test code
                    lang = 'html'
                    code = code.split( '\n' )[1..].join( '\n' )
                hljs.highlight( lang, code ).value
            renderer: renderer

The return value is an object, containing both the HTML for the
page and the HTML for the page's table of contents (`toc`).

        {
            html : marked fs.readFileSync infile, 'utf8'
            toc : toc
        }

This utility function escapes text into lower-case with no spaces,
and is used in a routine above, as well as other parts of the build
process.

    exports.escapeHeading = ( text ) ->
        text.toLowerCase().replace /[^\w]+/g, '-'

