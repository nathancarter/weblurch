
# Build process definitions

This file defines the build processes in this repository.
It is imported by the `Cakefile` in this repository,
the source code of which is kept to a one-liner,
so that most of the repository can be written
in [the literate variant of CoffeeScript][litcoffee].

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

## Constants

These constants define how the functions below perform.

    srcdir = './src/'
    outdir = './app/'
    srcout = 'weblurch.litcoffee'

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
        ( require 'child_process' ).exec \
        "coffee --map --compile #{outdir+srcout}",
        ( err, stdout, stderr ) ->
            console.log stdout + stderr if stdout + stderr
            throw err if err

Run `uglifyjs` to minify the results,
taking source maps into account.
Report completion when done, or throw an error if there was one.
(Note that `uglify` output is not printed unless there was an
error, because uglify dumps a bit of spam I'm suppressing.)

            srcoutbase = /^(.*)\.[^.]*$/.exec( srcout )[1]
            console.log "\tMinifying #{srcoutbase}.js..."
            ( require 'child_process' ).exec \
                "../node_modules/uglify-js/bin/uglifyjs " +
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

[litcoffee]: (http://coffeescript.org/#literate)

