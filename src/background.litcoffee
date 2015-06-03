
# Background Computations

This module defines an API for enqueueing background computations on groups
in webLurch.  It provides an efficient means for running those computations,
no matter how numerous they might be, while keeping the UI responsive.

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
            setTimeout window.Background.doNextTask, 10

This function is not part of the public API.  It is used internally to
dequeue the next computation and run it.

        doNextTask : ->
            task = window.Background.tasks.shift()
            try
                result =
                    window.Background.functions[task.name] task.inputs...
            catch e
                console.log "Error running #{task.name} task: #{e.stack}"
            if window.Background.tasks.length > 0
                setTimeout window.Background.doNextTask, 10
            task.callback result
