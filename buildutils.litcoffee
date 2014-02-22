
# Utility functions supporting the build process

## Task queueing

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

