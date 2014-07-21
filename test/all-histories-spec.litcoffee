
# All test histories

Test histories are recorded by users of the test app into JSON
files that contains a sequence of JavaScript commands to execute,
and waypoints at which to compare the state of the document against
known-correct (and even known-incorrect) states.

This test suite will eventually traverse a folder hierarchy of many
such tests, running them all.  For now, it just runs one example
test history file.

First, we load the necessary tools.

    { phantomDescribe, runTestHistory } = require './phantom-utils'

Next, we run the single test in question.

    runTestHistory 'example-test-history.json'

