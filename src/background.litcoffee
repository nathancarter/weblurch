
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
            if not window.Background.functions.hasOwnProperty funcName
                return
            ( window.Background.tasks ?= [ ] ).push
                name : funcName
                inputs : inputGroups
                callback : callback
            if window.Background.tasks.length is 1
                setTimeout window.Background.doNextTask, 10

This function is not part of the public API.  It is used internally to
dequeue the next computation and run it.

        doNextTask : ->
            task = window.Background.tasks.shift()
            for group in task.inputs
                if group.deleted then return
            try
                result =
                    window.Background.functions[task.name] task.inputs...
            catch e
                console.log "Error running #{task.name} task: #{e.stack}"
            if window.Background.tasks.length > 0
                setTimeout window.Background.doNextTask, 10
            task.callback result

## `BackgroundFunction` class

We define the following class for encapsulating functions that are ready to
be run in the background.  For now, it runs them in the main thread, but
this abstraction is ready for later changes when we add support for Web
Workers.

    BackgroundFunction = class

The constructor just stores in the `@function` member the function that this
object is able to run in the background.

       constructor : ( @function ) -> # no body needed

Background functions need to be callable.  Calling them returns a promise
object into which we can install callbacks for when the result is computed,
or when an error occurs.

        call : =>

The promise object, which will be returned, permits chaining.  Thus all of
its method return the promise object itself.  There are only two methods,
`sendTo`, for specifying the result callback, and `orElse`, for specifying
the error callback.  Thus the use of this call function looks like
`bgfunc.call( args... ).sendTo( resultHandler ).orElse( errorHandler )`.

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

Run the computation soon, but not now.  When it is run, store the result or
error in the promise, and call the result or error handler, whichever is
appropriate, assuming it has been defined by then.  If it hasn't been
defined at that time, the result/error will be stored and set to the result
or error callback the moment one is registered, using one of the two
functions defined above, in the promise object.

            setTimeout =>
                try
                    @promise.result = @function arguments...
                catch e
                    @promise.error = e
                    @promise.errorCallback? @promise.error
                    return
                @promise.resultCallback? @promise.result
            , 0

Return the promise object, for chaining.

            @promise
