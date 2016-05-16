
# Background Computations

This module defines an API for enqueueing background computations on groups
in webLurch.  It provides an efficient means for running those computations,
no matter how numerous they might be, while keeping the UI responsive.

## Global Background object

The first object defined herein is the global `Background` object, which
encapsulates all activity that will take place "in the background."  This
means that such activity, will not begin immediately, but will be queued for
later processing (possibly in a thread other than the main UI thread).  It
is called `Background` because you should think of this as encapsulating the
very notion of running a job in the background.

    window.Background =

The first public API this global object provides is a way to register script
functions as jobs that can be run in the background.  This does not enqueue
a task for running; it simply gives a name to a function that can later be
used in the background.  Code cannot be run in the backgorund unless it has
first been added to this global library of background-runnable functions,
using this very API.

The optional third parameter is a dictionary of name-function pairs that
will be installed in the background function's namespace when it is used.
If the background function uses a Web Worker, these will be sent as strings
to the worker for recreation into functions (so their environments will not
be preserved).  If the background function is executed in the main thread
(in environments that don't support Web Workers), a `with` clause will be
used to ensure that the functions are in scope.  In that case, environments
are preserved.  So write your functions independent of environment.

The optional fourth parameter is an array of scripts to import into the web
worker.  In a Web Worker implementation, these will be run using
`importScripts`.  In a non-Web Worker implementation, these will do nothing;
you should ensure that these same scripts are already imported into the
environment from which this function is being called.

        functions : { }
        registerFunction : ( name, func, globals = { }, scripts = [ ] ) ->
            window.Background.functions[name] =
                function : func
                globals : globals
                scripts : scripts

The second public API this global object provides is the `addTask` function,
which lets you add a task to the background processing queue, to be handled
as soon as earlier-added tasks are complete and resources are available.

The first parameter must be the name of a function that has been passed to
`registerFunction`.  If the name has not been registered, this task will not
be added to the queue.  The second parameter must be a list of group objects
on which to perform the given computation.  The third parameter is the
callback function that will be called with the result when the computation
is complete.

Keep in mind that the goal should be for the registered function (whose name
is provided here in `funcName`) to do the vast majority of the work of the
computation, and that `callback` should simply take that result and store it
somewhere or report it to the user.  The `callback` will be executed in the
UI thread, and thus must be lightweight.  The function whose name is
`funcName` will be run in the background, and thus can have arbitrary
complexity.

        runningTasks : [ ]
        waitingTasks : [ ]
        addTask : ( funcName, inputGroups, callback ) ->
            newTask =
                name : funcName
                inputs : inputGroups
                callback : callback
                id : "#{funcName},#{group.id() for group in inputGroups}"

Before we add the function to the queue, we filter the current "waiting"
queue so that any previous copy of this exact same computation (same
function name and input group list) is removed.  (If there were such a one,
it would mean that it had been enqueued before some change in the document,
which necessitated recomputing the same values based on new data.  Thus we
throw out the old computation and keep the new, later one, since it may sit
chronologically among a list of waiting-to-run computations in a way in
which order is important.)  We only need to seek one such copy, since we
filter every time one is added, so there cannot be more than one.

            for task, index in window.Background.waitingTasks
                if task.id is newTask.id
                    window.Background.waitingTasks.splice index, 1
                    break

Then repeat the same procedure with the currently running tasks, except also
call `terminate()` in the running task before deleting it.

            for task, index in window.Background.runningTasks
                if task.id is newTask.id
                    task.runner?.worker?.terminate?()
                    window.Background.runningTasks.splice index, 1
                    break

Now we can enqueue the task and call `update()` to possibly begin processing
it.

            window.Background.waitingTasks.push newTask
            window.Background.update()

The update function just mentioned will verify that as many tasks as
possible are running concurrently.  That number will be determined by [the
code below](#ideal-amount-of-concurrency).  The update function, however, is
implemented here.

        available : { }
        update : ->
            B = window.Background
            while B.runningTasks.length < B.concurrency()
                if not ( toStart = B.waitingTasks.shift() )? then return

If we have a `BackgroundFunction` object that's not running, and is of the
appropriate type, let's re-use it.  Otherwise, we must create a new one.
Either way, add it to the running tasks list if we were able to create an
appropriate `BackgroundFunction` instance.

                runner = B.available[toStart.name]?.pop()
                if not runner?
                    data = B.functions[toStart.name]
                    if not data? then continue
                    runner = new BackgroundFunction data.function,
                        data.globals, data.scripts
                toStart.runner = runner
                B.runningTasks.push toStart

From here onward, we will be creating some callbacks, and thus need to
protect the variable `toStart` from changes in later loop iterations.

                do ( toStart ) ->

When the task completes, we will want to remove it from the list of running
tasks and place `runner` on the `available` list for reuse.  Then we should
make another call to this very update function, in case the end of this task
makes possible the start of another task, within the limits of ideal
concurrency.

We define this cleanup function to do all that, so we can use
it in two cases below.

                    cleanup = ->
                        index = B.runningTasks.indexOf toStart
                        B.runningTasks.splice index, 1
                        ( B.available[toStart.name] ?= [ ] ).push runner
                        window.Background.update()

Start the background process.  Call `cleanup` whether the task succeeds or
has an error, but only call the callback if it succeeds.

                    runner.call( toStart.inputs... ).sendTo ( result ) ->
                        cleanup()
                        toStart.callback? result
                    .orElse cleanup

## Ideal amount of concurrency

Because the Background object will be used to run tasks in the background,
it will need to know how many concurrent tasks it should attempt to run.
The answer is one per available core on the client's machine.  The client's
machine will have some number, n, of cores, one of which will be for the UI.
Thus n-1 will be available for background tasks.  We need to know n.  The
following function (defined in
[this polyfill](https://github.com/oftn/core-estimator), which this project
imports) computes that value for later use.

    navigator.getHardwareConcurrency -> # no body

We then write the following function to compute the number of background
tasks we should attempt to run concurrently.  It returns n-1, as described
above.  It rounds that value up to 1, however, in the event that the machine
has only 1 core.  Also, if the number of cores could not be (or has not yet
been) computed, it returns 1.

    window.Background.concurrency = ->
        Math.max 1, ( navigator.hardwareConcurrency ? 1 ) - 1

## `BackgroundFunction` class

We define the following class for encapsulating functions that are ready to
be run in the background.  For now, it runs them in the main thread, but
this abstraction is ready for later changes when we add support for Web
Workers.

    BackgroundFunction = class

The constructor stores in the `@function` member the function that this
object is able to run in the background.

        constructor : ( @function, @globals, @scripts ) ->

The promise object, which will be returned from the `call` member, permits
chaining.  Thus all of its method return the promise object itself.  There
are only two methods, `sendTo`, for specifying the result callback, and
`orElse`, for specifying the error callback.  Thus the use of the call
member looks like `bgfunc.call( args... ).sendTo( resultHandler ).orElse(
errorHandler )`.

            @promise =
                sendTo : ( callback ) =>
                    @promise.resultCallback = callback
                    if @promise.hasOwnProperty 'result'
                        @promise.resultCallback @promise.result
                    @promise
                orElse : ( callback ) =>
                    @promise.errorCallback = callback
                    if @promise.hasOwnProperty 'error'
                        @promise.errorCallback @promise.error
                    @promise

If Web Workers are supported in the current environment, we create one for
this background function.  Otherwise, we do not, and we will have to fall
back on a much simpler technique later.

            if window.Worker
                @worker = new window.Worker 'worker-solo.js'
                @worker.addEventListener 'message', ( event ) =>
                    @promise.result = event.data
                    @promise?.resultCallback? event.data
                , no
                @worker.addEventListener 'error', ( event ) =>
                    @promise.error = event
                    @promise?.errorCallback? event
                , no
                @worker.postMessage setFunction : "#{@function}"
                for own name, func of @globals
                    @globals[name] = "#{func}"
                @worker.postMessage install : @globals
                @worker.postMessage import : @scripts

Background functions need to be callable.  Calling them returns the promise
object defined in the constructor, into which we can install callbacks for
when the result is computed, or when an error occurs.

        call : ( args... ) =>

First, clear out any old data in the promise object from a previous call of
this background function.

            delete @promise.result
            delete @promise.resultCallback
            delete @promise.error
            delete @promise.errorCallback

Second, prepare all arguments (which must be Group objects) for use in the
worker thread by serializing them.  If any of the groups on which we should
run this function have been deleted since it was created, we quit and do
nothing.

            for group in arguments
                if group.deleted then return
            groups = ( group.toJSON() for group in args )

Run the computation soon, but not now.  When it is run, store the result or
error in the promise, and call the result or error handler, whichever is
appropriate, assuming it has been defined by then.  If it hasn't been
defined at that time, the result/error will be stored and set to the result
or error callback the moment one is registered, using one of the two
functions defined above, in the promise object.

If Web Workers are supported, we use the one constructed in this object's
constructor.  If not, we fall back on simply using a zero timer, the poor
man's "background" processing.

When Web Workers are used, we must first serialize each group passed to the
web worker, because it cannot be passed as is, containing DOM objects.  So
we do that in both cases, so that functions can be consistent, and not need
to know whether they're running in a worker or not.

            if @worker?
                @worker.postMessage runOn : groups
            else
                setTimeout =>
                    try
                        `with ( this.globals ) {`
                        @promise.result = @function groups...
                        `}`
                    catch e
                        @promise.error = e
                        @promise.errorCallback? @promise.error
                        return
                    @promise.resultCallback? @promise.result
                , 0

Return the promise object, for chaining.

            @promise
