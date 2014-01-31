
# Build process definitions

This file defines the build processes in this repository.
It is imported by the `Cakefile` in this repository,
the source code of which is kept to a one-liner,
so that most of the repository can be written
in [the literate variant of CoffeeScript][litcoffee].

## Constants

These constants define how the functions below perform.

    srcdir = './src/'
    srcout = './app/weblurch.litcoffee'

## The `app` build process

    task 'app', 'Build the entire app', ( options ) ->
        fs = require 'fs'
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
        console.log "\tWriting #{srcout}..."
        fs.writeFileSync srcout, all.join( '\n\n' ), 'utf8'

Run `coffee` compiler on that file, also creating a source map.
This generates `.js` and `.js.map` files.
Report completion when done, or throw an error if there was one.

        console.log "\tCompiling #{srcout}..."
        ( require 'child_process' ).exec \
        "coffee --map --compile #{srcout}",
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr
            throw err if err
            console.log 'Done building app.'

[litcoffee]: (http://coffeescript.org/#literate)

