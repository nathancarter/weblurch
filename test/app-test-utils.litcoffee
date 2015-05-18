
# App-Testing Utilities

When testing the main webLurch app, there are several utilities that it's
handy to have available, including functions for sending UI events to the
headless browser used for testing, as well as functions for comparing DOM
trees and injecting code into the JavaScript environment of the headless
browser.  This module provides those utilities.

## Injecting code

We can easily execute functions in the testing browser using the `pageDo`
routine, but it's not easy to transport a function already defined in the
`node.js`-based testing environment into the headless browser environment,
to assign it to a global variable for later re-use.  The following function
makes that possibly by converting a given function into a new function that
installs the original function into the given global variable.

For example, you could call `pageDo transport myFunc, 'foo'` and then
depend upon the fact that the function `myFunc` from the `node.js`-based
testing environment now existed as `window.foo` in the headless browser
environment.  (Note that the function will not take with it any captured
variables.)

    exports.transport = ( func, name ) ->
        eval "(function(){ window.#{name}=#{func.toString()}; })"
