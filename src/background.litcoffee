
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

        registerFunction : ( name, func ) ->
            ( window.Background.functions ?= { } )[name] = func

The first public API this global object provides is the `addTask` function,
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

        addTask : ( funcName, inputGroups, callback ) ->
            if ( func = window.Background.functions[funcName] )?
                ( new BackgroundFunction func ).call( inputGroups... ) \
                    .sendTo( callback )

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

        constructor : ( @function ) ->

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
                @worker = new window.Worker 'worker.solo.js'
                @worker.addEventListener 'message', ( event ) =>
                    @promise.result = event.data
                    @promise?.resultCallback? event.data
                , no
                @worker.addEventListener 'error', ( event ) =>
                    @promise.error = event
                    @promise?.errorCallback? event
                , no
                @worker.postMessage setFunction : "#{@function}"

Background functions need to be callable.  Calling them returns the promise
object defined in the constructor, into which we can install callbacks for
when the result is computed, or when an error occurs.

        call : ( args... ) =>

First, clear out any old callbacks in the promise object from a previous
call of this background function.

            delete @promise.resultCallback
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
                        @promise.result = @function groups...
                    catch e
                        @promise.error = e
                        @promise.errorCallback? @promise.error
                        return
                    @promise.resultCallback? @promise.result
                , 0

Return the promise object, for chaining.

            @promise
