
# Utility functions supporting the build process

Several places in this module we access the filesystem, spawn child
processes with `exec`, or output text in color.  So import those modules up
front.

    fs = require 'fs'
    { exec } = require 'child_process'
    colors = require 'colors'

## Task queue

### Enqueueing and dequeueing tasks

The next few functions make it possible to add tasks to a queue and dequeue
them later into active duty.  Enqueueing any string stores it for later
execution, which happens when you dequeue; that passes the string to
`cake`'s `invoke`.  Such strings should be names of tasks defined in the
cakefile.

First, we need an empty queue.

    queue = []

Next, the enqueue function simply pushes onto that array.

    exports.enqueue = ( tasks... ) ->
        queue = queue.concat tasks

The dequeue function passes the next task name on the queue to `cake`'s
`invoke` function (thereby removing it from the queue), if and only if there
is a next task to dequeue.  The exception to this is that if the next task
on the queue is not a string (a task name) but instead is a function, then
we just call it.

    exports.dequeue = ->
        if queue.length > 0
            next = queue.shift()
            if typeof next is 'string' then invoke next else next()

### Automatic dequeueing and messaging

Each task function would therefore have to end with a call to `dequeue`, so
that after each task is completed, if there are more tasks still in the
queue, the next one gets run.  But that is undesirable.  It would be better
if the task definer provided by `cake` did this for us.  So we redefine it
to do so.

While we're at it, we will print messages saying which tasks are being
started/completed, so that the individual tasks no longer need to handle
that on their own.

First, define a new task function unique to this module.

    exports.task = ( name, description, func ) ->

Call the cake task function, but this time supply a different task execution
function, one that does whatever the actual task function is, then calls
dequeue.

        task name, description, ( options ) ->
            console.log "Begin building #{name}..."
            func options
            console.log "Done building #{name}."
            exports.dequeue()

Now, some build tasks may be asynchronous, and we'll need to wait until
they're done before calling dequeue.  So here's a way to define asynchronous
tasks whose task functions will take a `done` function that you should call
when the task is done.

    exports.asyncTask = ( name, description, func ) ->
        task name, description, ( options ) ->
            console.log "Begin building #{name}..."
            func ->
                console.log "Done building #{name}."
                exports.dequeue()
            , options

Those last lines mean that your asynchronous task function needs to take a
`done` function as parameter, and call it when the task is finally complete.
It will then print done and do a dequeue.

## Verifying npm install has been run

It is useful to verify that `npm install` has been run in this folder before
attempting to load `node` modules mentioned in the `package.json` file.

This is because the build process relies on a few such modules, and it is
very frustrating for the build process to crash because it's missing one of
them, showing what would be a cryptic error message to a new downloader.  So
this routine first checks to be sure that the required modules are present,
and exits with a helpful error message if any are not.

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

Often during the build process, we need a list of all files of a certain
type in a certain directory.  This simple function does that for us,
returning the result as an array.

It takes parameters in pairs, a folder as a string, then a regexp to use for
filtering files in that folder (only those that match are returned).  As
many folder-regexp pairs as you want may be passed; the concatenated results
are returned, each as a string that begins with the folder name it belongs
in (e.g., `'data/images/thing.png'`).

    exports.dir = ( args... ) ->
        result = []
        for i in [0...args.length-1] by 2
            if args[i][-1..] != '/' then args[i] += '/'
            for file in fs.readdirSync args[i]
                if args[i+1].test file
                    result.push args[i]+file
        result

## Loading contents of text files

It is convenient to be able to load the contents of many text files at once,
and this function does so.  Pass it an array of filenames, and you get back
an object whose keys are those filenames and whose values are the text
contents of the files.

Obviously for many very large files, this will use a lot of memory. For a
reasonable number of text files, there is no problem.

    exports.readFiles = ( names ) ->
        result = { }
        for name in names
            console.log "\tReading #{name}..."
            result[name] = fs.readFileSync name, 'utf8'
        result

## Shortening filenames

Shortens a filename relative to the current folder, for use in logging.

    shortFilename = ( filename ) ->
        dir = __dirname + '/'
        if filename[...dir.length] is dir
            filename[dir.length..]
        else
            filename

## Testing if a file is up-to-date

This can be called in one of four ways.
 1. `mustUpdate input, output` takes two filenames and looks up the last
    modified time of each, returning true iff the input's time is after the
    output's time
 1. The other three ways are that either or both of the arguments can be an
    array, and the result is true iff `mustUpdate x, y` would be true for
    any x from the first array and any y from the second.


    exports.mustUpdate = ( input, output ) ->
        if input instanceof Array
            for i in input
                if exports.mustUpdate i, output then return yes
            return no
        if output instanceof Array
            for o in output
                if exports.mustUpdate input, o then return yes
            return no
        try
            fs.statSync( input ).mtime.getTime() > \
                fs.statSync( output ).mtime.getTime()
        catch e
            yes

## Copying a file

Only copies the file if the destination is older than the source.  Calls the
callback when done.

    exports.copyFile = ( source, destination, callback ) ->
        src = shortFilename source
        dst = shortFilename destination
        if exports.mustUpdate source, destination
            exports.runShellCommands [
                description : "\tCopying #{src} to #{dst}..."
                command : "cp #{source} #{destination}"
            ], callback
        else
            console.log "\tNot copying #{src} to #{dst}
                -- unchanged.".gray
            callback()

## Concatenating text files

This function takes an array of input text files, a separator, and a single
filename for the output text file.  It reads all the input files, joins them
using the separator, and writes the result to the named output file.

    exports.concatFiles = ( inputs, separator, output ) ->

Do we even need to do this?  Maybe nothing changed...

        if not exports.mustUpdate inputs, output
            console.log "\tNot combining files into
                #{output.split( '/' ).pop()} -- inputs unchanged".gray
            return

Yes, we need to do it, so do so.

        console.log "\tCombining files into #{output.split( '/' ).pop()}..."
        all = ( fs.readFileSync name for name in inputs )
        fs.writeFileSync output, all.join( separator ), 'utf8'

## Run a sequence of shell scripts

The following utility function is handy for executing a sequence of shell
commands, and ensuring each succeeds before proceeding on to the next.  It
can be used in any file that imports this module, but it will also be used
to define the compilation task in the next section.

Provide it data as a list of object, each with these attributes.
 * `command :` required attribute, string, shell command to run
 * `cwd :` optional attribute, defaults to `'.'`, current working directory
   in which to run the command
 * `description :` optional attribute, defaults to `command`, the text that
   will be printed to the console when the command is started

    exports.runShellCommands = ( commandData, callback = -> ) ->
        if commandData.length is 0 then return callback()
        nextCommand = commandData.shift()
        if not nextCommand.command
            throw Error 'Missing command field in command datum'
        console.log nextCommand.description or nextCommand.command
        exec nextCommand.command, { cwd : nextCommand.cwd or '.' },
        ( err, stdout, stderr ) ->
            if stdout + stderr then console.log stdout + stderr.red
            throw err if err
            exports.runShellCommands commandData, callback

## Compile literate coffeescript files

Call this function with an input filename and a callback function. The input
filename should contain the path also, unless it is the current directory.

The input file should be a `.litcoffee` file, and this function will
generate a corresponding `.js` file (compiled coffeescript), `.min.js` file
(minified version of the previous), and `.map` and `.min.js.map` files
(source map files for both). When the compilation is done, the callback
function will be called.

    exports.compile = ( srcfile, callback, moveTo ) ->

Separate the path and filename out from one another, then the base name from
the filename.

        [ all, path, file ] = /^(.*)\/([^\\]*)$/.exec srcfile
        base = /^(.*)\.[^.]*$/.exec( file )[1]
        p = require 'path'
        coffee = p.resolve __dirname, 'node_modules', '.bin', 'coffee'
        uglify = p.resolve __dirname, 'node_modules', '.bin', 'uglifyjs'
        prefixlen = __dirname.length + 1

Do we even need to do this?  Maybe the source file didn't change.

        prefix = moveTo ? path
        outputs = ( "#{prefix}/#{base}.#{extension}" for extension in \
            [ 'js', 'min.js', 'js.map', 'min.js.map' ] )
        if not exports.mustUpdate srcfile, outputs
            console.log "\tNot recompiling #{srcfile.split( '/' ).pop()}
                -- unchanged".gray
            return callback()

Run the `coffee` compiler on the file, also creating a source map. This
generates both `.js` and `.js.map` files.

        exports.runShellCommands [
            description : "\tCompiling #{srcfile[prefixlen..]}...".green
            command : "#{coffee} --map --compile #{file}"
            cwd : path

Run [uglifyjs](http://github.com/mishoo/UglifyJS) to minify the results,
taking source maps into account.  Call the callback when done, or throw an
error if there was one.

(The `uglify` output is not printed unless there was an error, because
`uglify` dumps a bit of spam I'm suppressing.)

        ,
            description : "\tMinifying #{base}.js..."
            command : "#{uglify} -c -m -v false #{base}.js
                       --in-source-map #{base}.js.map -o #{base}.min.js
                       --source-map #{base}.min.js.map"
            cwd : path
        ], ->
            if moveTo?
                if moveTo[-1..] isnt '/' then moveTo += '/'
                dir = __dirname + '/'
                short = shortFilename moveTo
                exports.runShellCommands [
                    description : "\tMoving #{base}.js to #{short}..."
                    command : "mv #{base}.js #{moveTo}"
                    cwd : path
                ,
                    description : "\tMoving #{base}.js.map to #{short}..."
                    command : "mv #{base}.js.map #{moveTo}"
                    cwd : path
                ,
                    description : "\tMoving #{base}.min.js to #{short}..."
                    command : "mv #{base}.min.js #{moveTo}"
                    cwd : path
                ,
                    description : "\tMoving #{base}.min.js.map to
                        #{short}..."
                    command : "mv #{base}.min.js.map #{moveTo}"
                    cwd : path
                ], callback
            else
                callback()
