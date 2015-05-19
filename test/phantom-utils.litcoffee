
# Utilities useful to the testing suite

The compiled app runs in a web browser, so this module provides utility
functions for dealing with the headless browser
[PhantomJS](http://phantomjs.org/) for use in automated testing. This is
done through a bridge from [node.js](http://nodejs.org/) to PhantomJS,
called [node-phantom-simple](
https://npmjs.org/package/node-phantom-simple).

    nps = require 'node-phantom-simple'

# The main API, `phantomDescribe`

The `phantomDescribe` function makes it easy to set up a PhantomJS instance
and load into it a page from a given URL.  If any errors take place during
the loading process, they are thrown as exceptions, or recorded as
attributes of the page object.
 * `page.reserr` will be a resource error object, if there was a resource
   error
 * `page.err` will be a generic error object, if there was a generic error

This can easily be used within the asynchronous test framework in
[Jasmine](http://jasmine.github.io/) by replacing a call to Jasmine's
`describe` function with a call to `phantomDescribe`. An example appears
[further below](#example).

# Private API

Here is a global variable in which I store the one PhantomJS instance I
create.  (Creating many PhantomJS instances leads to errors about too many
listeners for an `EventEmitter`, so I use one global PhantomJS instance.)
It starts uninitialized, and I provide a function for querying whether it
has been initialized since then.

    P = phantom: null, page: null, queue: [ ]
    phantomInitialized = -> P?.phantom and P?.page

This function loads into that global instance any given URL. It does not
check `phantomInitialized` first; that is the business of the next function,
below. Once the URL is loaded, this function calls the given callback.

It sets `P.page` to be false before the page opening is attempted, and sets
it to true if the opening complets without error.

    loadURLInPhantom = ( url, callback ) ->
        P.page.loaded = no
        P.page.open url, ( err, status ) ->
            if err then console.log err ; throw err
            P.page.loaded = yes
            callback()

This function initializes the global variable `P`, loads the given URL into
the page stored in that global variable, and then calls a callback function.
If `P` was already initialized, then this just calls the callback.

    initializePhantom = ( url, callback ) ->
        if phantomInitialized()
            loadURLInPhantom url, callback
        else
            nps.create ( err, ph ) ->
                if err then console.log err ; throw err
                P.phantom = ph
                P.phantom.createPage ( err, pg ) ->
                    if err then console.log err ; throw err
                    P.page = pg
                    P.page.onResourceError = ( err ) ->
                        console.log 'Page resource error:', err
                        P.page.reserr = err
                    P.page.onError = ( err ) ->
                        console.log 'Page error:', err
                        P.page.err = err
                    P.page.onConsoleMessage = ( message ) ->
                        console.log message
                    loadURLInPhantom url, callback

# Public API

And now we define the one function this module exports, which will
initialize the members of `P` if and when needed.

    exports.phantomDescribe = ( text, url, tests ) ->
        describe text, ->

Before each test, load the given page into the headless browser and be sure
it loaded successfully.

            beforeEach ( done ) -> initializePhantom url, done

Run the tests that the user passed in as a function. Provide the user the
`phantom` and `page` objects from earlier as attributes of the `this` object
when `tests` is run. Thus they can access them as `@phantom` and `@page`.

            tests.apply P

# Example

Example use (note the very important `=>` for preserving `this`):

    # phantomDescribe 'My page', './index.html', ->
    #     it 'must load', ( done ) =>
    #         expect( @page.loaded ).toBeTruthy()
    #         done()

# Convenience function for tests

In order to make writing tests shorter, we provide the following convenience
function.  Consider the following idiom that we wish to avoid.

    # it 'name of test here', ( done ) =>
    #     @page.evaluate =>
    #         result = []
    #         result.push( statement1 we want to test )
    #         result.push( statement2 we want to test )
    #         result.push( statement3 we want to test )
    #         result
    #     , ( err, result ) ->
    #         expect( err ).toBeNull()
    #         expect( result[0] ).toBeSuchAndSuch()
    #         expect( result[1] ).toBeSuchAndSuch()
    #         expect( result[2] ).toEqual soAndSo
    #         done()

This pattern would appear throughout our testing suite, and thus can be made
shorter by defining the following functions.

Because calls to `P.page.evaluate` return immediately and send the results
back asynchronously in a callback, there is a danger of sending several such
messages before the first one completes running.  Thus we implement a job
queue, using the following two functions.

This function adds to the job queue a job that will call the given function
on the given argument list.  It also adds to the job the current error
stack, so that if an error occurs later when running the function, we can
reference the point in the test suite at which the test is defined.  This is
more helpful to clients.

    addJob = ( func, args... ) ->
        stack = Error().stack.split '\n'
        P.queue.push
            func : func
            args : args
            stack : [ stack[0], stack[4..]... ].join '\n'

There is also a version that adds the job at top priority; this is used only
by `pageWaitFor`, below.

    addTopJob = ( func, args... ) ->
        stack = Error().stack.split '\n'
        P.queue.unshift
            func : func
            args : args
            stack : [ stack[0], stack[4..]... ].join '\n'

This function pops a job off the job queue and runs it.  It also stores in
the current Jasmine test spec a copy of the error stack saved above, so that
if the test fails, that stack can be used in error reporting.  (See
[below](#jasmine-modifications).)

    nextJob = ->
        if P.queue.length is 0 then return
        next = P.queue.shift()
        spec = jasmine?.getEnv().currentSpec
        if not spec
            throw Error 'No current spec in which to set error point'
        spec.overrideStack_ = next.stack
        next.func.apply null, next.args

Now we create a function to store the `done` function in the global object
`P` for later use.  Although this function is a bit confusing at first, see
the example code further below for how to use it with the functions defined
hereafter.

    exports.inPage = ( func ) ->
        ( done ) ->
            P.done = done

The following call will make many calls to `addJob()`, thus building up a
queue of work to be done.

            func()

At the end of the queue, we want Jasmine's `done` function to be called, so
we add that as the last action on the queue, then start the queue running.

            addJob done
            nextJob()

We now have some functions that can be used in place of the normal Jasmine
test functions, to run tests in the Phantom page, rather than in this
(node-based) JavaScript environment.

This one can be used in place of `expect` to provide the extra checks we
desire, and cause `done` to be called for us.  Note that the default value
for `check` enables the idiom `pageExpects -> expression` as a shortcut for
`pageExpects ( -> expression ), 'toBeTruthy'`.

    pageExpects = ( func, check = 'toBeTruthy', args... ) ->
        P.page.evaluate ( evaluateThis ) ->
            result = try eval evaluateThis catch e then e
            if typeof result is 'undefined'
                result = [ 'undefined' ]
            else if result is null
                result = [ 'null' ]
            else
                result = [ 'value', result ]
            result
        , ( err, result ) ->
            expect( err ).toBeNull()
            if result?[0] is 'null'
                result = null
            else if result?[0] is 'value'
                result = result[1]
            else
                result = undefined
            if check is 'toBeSimilarHTML'
                check = 'toEqual'
                result = simplifiedHTML "#{result}"
                args[0] = simplifiedHTML "#{args[0]}"
            if typeof result isnt 'undefined'
                expect( result )[check](args...)
            else
                expect( undefined )[check](args...)
            nextJob()
        , "(#{func.toString()})()"
    exports.pageExpects = ( func, check = 'toBeTruthy', args... ) ->
        addJob pageExpects, func, check, args...

The new idiom that can replace the old is therefore the following.

    # it 'name of test here', inPage ->
    #     pageExpects ( -> statement1 we want to test ),
    #         'toBeSuchAndSuch'
    #     pageExpects ( -> statement2 we want to test ),
    #         'toBeSuchAndSuch'
    #     pageExpects ( -> statement3 we want to test ),
    #         'toEqual', soAndSo

Sometimes a test may wish to wait until a specific condition is true in the
page.  The following function is useful for that purpose.  It fails if the
function to evaluate in the page causes an error, or returns false
repeatedly until the time limit is exceeded (2 seconds by default).

    pageWaitFor = ( func, waitUntil ) ->
        P.page.evaluate ( evaluateThis ) ->
            not not eval evaluateThis
        , ( err, result ) ->
            expect( err ).toBeNull()
            if not result
                if new Date < waitUntil
                    addTopJob pageWaitFor, func, waitUntil
                else
                    expect( 'Waiting time expired' ).toBeFalsy() # fail
            nextJob()
        , "(#{func.toString()})()"
    exports.pageWaitFor = ( func, maximumWaitTime = 2000 ) ->
        addJob pageWaitFor, func, ( new Date ).getTime() + maximumWaitTime

If you expect an error, you can do so with this routine.  The `check` and
`args` parameters are optional, and will be used on the error object (if one
exists) if and only if they're provided.

    pageExpectsError = ( func, check, args... ) ->
        P.page.evaluate ( evaluateThis ) ->
            try eval evaluateThis ; null catch e then e
        , ( err, result ) ->
            expect( err ).toBeNull()
            expect( result ).not.toBeNull()
            if check then expect( result.message )[check](args...)
            nextJob()
        , "(#{func.toString()})()"
    exports.pageExpectsError = ( func, check, args... ) ->
        addJob pageExpectsError, func, check, args...

Use it as per the following examples.

    # it 'name of test here', inPage ->
    #     pageExpectsError ( -> undefinedVar )
    #     pageExpectsError ( -> foo('hello') ),
    #         'toMatch', /parameter must be an integer/

Furthermore, if some setup code needs to be run in the page, which does not
require any tests to be called on it, but still needs to run without errors,
then the following may be useful.

    pageDo = ( func, args... ) ->
        P.page.evaluate func, ( err, result ) ->
            expect( err ).toBeNull()
            nextJob()
        , args...
    exports.pageDo = ( func, args... ) -> addJob pageDo, func, args...

One can then do the following.

    # it 'name of test here', inPage ->
    #     pageDo ->
    #         ...put a lot of code here, and if assigning to any
    #         variables, be sure to use window.varName...
    #     pageExpects ( -> back to more tests here ),
    #         'toBeTruthyOrWhatever'

# Simulating User Interaction

Although the `page` object provides the `sendEvent` member for simulating
mouse and keyboard interaction, the following convenience functions make
using that functionality much easier.

The first is for typing a string of text.  Currently this only functions for
upper case letters, spaces, and digits.

    pageType = ( text ) ->
        for character in text
            code = character.toUpperCase().charCodeAt 0
            if ( '0'.charCodeAt( 0 ) <= code <= '9'.charCodeAt( 0 ) ) or
               ( 'A'.charCodeAt( 0 ) <= code <= 'Z'.charCodeAt( 0 ) ) or
               ( ' '.charCodeAt( 0 ) is code )
                P.page.sendEvent 'keypress', code, null, null, 0
            else
                throw Error 'Cannot type this into the page: ' + character
        nextJob()
    exports.pageType = ( text ) -> addJob pageType, text

The second is for pressing any of the special keys on the keyboard.  A full
list of valid string arguments is available [here](
http://phantomjs.org/api/webpage/method/send-event.html), but for some
reason the alleged `page.events` object does not exist in this context.
Thus I copy a selection of the most important ones into `export.pageKey`
itself: `left`, `right`, `up`, `down`, `backspace`, `delete`, and `tab`.

    pageKey = ( code, modifiers = 0 ) ->
        P.page.sendEvent 'keypress', code, null, null, modifiers
        nextJob()
    exports.pageKey = ( code, modifiers = 0 ) ->
        if typeof code is 'string'
            code = exports.pageKey[code.toLowerCase()]
        if typeof modifiers is 'string'
            modifiers = exports.pageKey[modifiers.toLowerCase()]
        addJob pageKey, code, modifiers
    exports.pageKey.shift = 0x02000000
    exports.pageKey.ctrl = 0x04000000
    exports.pageKey.alt = 0x08000000
    exports.pageKey.meta = 0x10000000
    exports.pageKey.keypad = 0x20000000
    exports.pageKey.left = 16777234
    exports.pageKey.right = 16777236
    exports.pageKey.up = 16777235
    exports.pageKey.down = 16777237
    exports.pageKey.backspace = 16777219
    exports.pageKey.delete = 16777223
    exports.pageKey.tab = 16777217
    exports.pageKey.home = 16777232
    exports.pageKey.end = 16777233
    exports.pageKey.enter = 16777221

When you need lower-level functionality, refer to [the documentation on the
PhantomJS homepage](
http://phantomjs.org/api/webpage/method/send-event.html).

In particular, not the useful command `P.page.sendEvent 'click', x, y`,
which can be invoked from tests using `@page.sendEvent 'click', x, y`.

# Jasmine modifications

The `pageExpects` and `pageExpectsError` functions, above, make asynchronous
calls to `page.evaluate` and then perform `expect` calls in the callback.
The problem with this is that if any of the tests in the `expect` calls
fails, the traceback used to report the error location will have the wrong
call stack.  It will be the call stack for the callback, which will usually
come from a `node.js` timer function, rather than the caller of the
`pageExpects` function, for instance.  This makes it very hard to track down
the errors, and is thus undesirable.

To fix this problem, we make some modifications to the Jasmine API, so that
we can set the stack trace before the asynchronous code begins, and that
stack trace will be used in later error reports.

First, the `addJob()` and `nextJob()` functions defined
[earlier](#convenience-function-for-tests) place into the
currently-running-spec object an error stack that was created at the time
that the job was placed onto the queue.  Such an error stack correctly
points to where (in the test suite code) the test was defined, so that we
can throw errors to that (more helpful) point if a test fails.

Second, we wrap the `addMatcherResult` function in `jasmine.Spec` with a
"before" clause that looks up the data stored in the spec, and uses it (if
present) to overwrite any existing error stack.

    oldFn = jasmine.Spec.prototype.addMatcherResult
    jasmine.Spec.prototype.addMatcherResult = ( result ) ->
        if @overrideStack_ and result.passed_ is no
            result.trace.stack = @overrideStack_
        oldFn.apply this, [ result ]

Finally, we create a wrapper around the test-result-reporting routine, so
that it kills the PhantomJS subprocess before the test process exits.
Without this, we leave a child process hanging around every time the test
suite is invoked.

    oldObj = jasmine.getEnv().reporter
    oldFn2 = oldObj.reportRunnerResults
    oldObj.reportRunnerResults = ( arg ) ->
        P?.phantom?.exit()
        oldFn2.apply oldObj, [ arg ]

# Utilities

When comparing two strings containing HTML code, we want to ignore some
irrelevant differences.  The following function simplifies HTML by removing
all space between tags and all Apple-style spans that some WebKit-based
browsers insert (including the headless testing browser in PhantomJS).

    exports.simplifiedHTML = simplifiedHTML = ( html ) ->
        html = html.replace />\s*</g, '><'
        old = ''
        while html isnt old
            old = html
            html = html.replace \
                /<span[^>]+Apple-style-span[^>]+>(.*?)<\/span>/g, '$1'
        html
