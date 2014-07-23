
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

We initialize a module-level variable to store all test histories
in one big data structure.  We populate this as we walk the folder
hierarchy, below.  We also provide a filename into which this
structure will be saved, once it's fully populated.

    historyHierarchy = { }
    historyOutFile = './testapp/all-test-histories.js'

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
As we process the files, we store them in the global data structure
if and only if they were an array, which means the test attempted.

        for file in files
            testHistory = runTestHistory file
            if testHistory instanceof Array
                historyHierarchy[file] = testHistory
        walk dir for dir in dirs

Now we apply that function to the hierarchy of test histories
stored in this repository.

    walk 'test/histories'

Save the global data structure of all test histories in a file in
the test app folder.  The output format is JavaScript, initializing
a global variable to contain the JSON data.

    stringForm = JSON.stringify historyHierarchy
    fs.writeFileSync historyOutFile,
        "window.allTestHistories = #{stringForm};"

