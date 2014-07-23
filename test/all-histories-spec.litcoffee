
# All test histories

Test histories are recorded by users of the test app into JSON
files that contains a sequence of JavaScript commands to execute,
and waypoints at which to compare the state of the document against
known-correct (and even known-incorrect) states.

This test suite will eventually traverse a folder hierarchy of many
such tests, running them all.  For now, it just runs one example
test history file.

First, we load the necessary tools.

    { runTestHistory } = require './phantom-utils'
    fs = require 'fs'
    path = require 'path'

Next, we define a function that will find all `.json` files in a
given directory hierarchy, and treat each as a test history to be
run.  It runs such histories in breadth-first-search order.

    walk = ( dir ) ->

Classify the things we find in `dir` as `.json` files, directories,
or neither (which we ignore).

        files = []
        dirs = []
        for entry in fs.readdirSync dir
            entry = path.join dir, entry
            if ( fs.statSync entry )?.isDirectory()
                dirs.push entry
            else if entry[-5..].toLowerCase() is '.json'
                files.push entry

In order to keep the search breadth-first, we process the files
in *this* folder first, then recur on any subfolders we found.

        runTestHistory file for file in files
        walk dir for dir in dirs

Now we apply that function to the hierarchy of test histories
stored in this repository.

    walk 'test/histories'

