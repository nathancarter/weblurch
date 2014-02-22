
# Utility functions supporting the build process

## Task queue

### Enqueueing and dequeueing tasks

The next few functions make it possible to add tasks to a queue and
dequeue them later into active duty.  Enqueueing any string stores
it for later execution, which happens when you dequeue; that passes
the string to `cake`'s `invoke`.  Such strings should be names of
tasks defined in the cakefile.

First, we need an empty queue.

    queue = []

Next, the enqueue function simply pushes onto that array.

    exports.enqueue = ( strings... ) ->
        queue = queue.concat strings

The dequeue function passes the next task name on the queue to
`cake`'s `invoke` function (thereby removing it from the queue), if
and only if there is a next task to dequeue.

    exports.dequeue = -> invoke queue.shift() if queue.length > 0

### Automatically dequeueing

Each task function would therefore have to end with a call to
`dequeue`, so that after each task is completed, if there are more
tasks still in the queue, the next one gets run.  But that is
undesirable.  It would be better if the task definer provided by
`cake` did this for us.  So we redefine it to do so.

First, define a new task function unique to this module.

    exports.task = ( name, description, func ) ->

Call the cake task function, but this time supply a different task
execution function, one that does whatever the actual task function
is, then calls dequeue.

        task name, description, ->
            func()
            exports.dequeue()

Now, some build tasks may be asynchronous, and we'll need to wait
until they're done before calling dequeue.  So here's a way to
define asynchronous tasks whose task functions will take a `done`
function that you should call when the task is done.

    exports.asyncTask = ( name, description, func ) ->
        task name, description, ->
            func -> exports.dequeue()

That last line means that your asynchronous task function needs to
take a `done` function as parameter, and call it when the task is
finally complete.  It will then run the dequeue call.

