
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



# Canvas Utilities

This module defines several functions useful when working with the HTML5
Canvas.

## Rounded rectangles

The following function traces a rounded rectangle path in the context.  It
sits entirely inside the rectangle from the upper-left point (x1,y1) to the
lower-right point (x2,y2), and its corners are quarter circles with the
given radius.

It calls `beginPath()` and `closePath()` but does not stroke or fill the
path.  You should do whichever (or both) of those you like.

    CanvasRenderingContext2D::roundedRect = ( x1, y1, x2, y2, radius ) ->
        @beginPath()
        @moveTo x1 + radius, y1
        @lineTo x2 - radius, y1
        @arcTo x2, y1, x2, y1 + radius, radius
        @lineTo x2, y2 - radius
        @arcTo x2, y2, x2 - radius, y2, radius
        @lineTo x1 + radius, y2
        @arcTo x1, y2, x1, y2 - radius, radius
        @lineTo x1, y1 + radius
        @arcTo x1, y1, x1 + radius, y1, radius
        @closePath()

## Rounded zones

The following function traces a rounded rectangle that extends from
character in a word processor to another, which are on different lines, and
thus the rectangle is stretched.  Rather than looking like a normal
rectangle, the effect looks like the following illustration, with X
indicating text and lines indicating the boundaries of the rounded zone.

```
  x x x x x x x x x x x x
       /------------------+
  x x x|x x x x x x x x x |
+------+                  |
| x x x x x x x x x x x x |
|          +--------------|
| x x x x x|x x x x x x x
+----------/
  x x x x x x x x x x x x
```

The corners marked with slashes are to be rounded, and the other corners are
square.  The left and right edges are the edges of the canvas, minus the
given values of `leftMargin` and `rightMargin`.  The y coordinates of the
two interior horizontal lines are given by `upperLine` and `lowerLine`,
respectively.

It calls `beginPath()` and `closePath()` but does not stroke or fill the
path.  You should do whichever (or both) of those you like.

    CanvasRenderingContext2D::roundedZone = ( x1, y1, x2, y2,
    upperLine, lowerLine, leftMargin, rightMargin, radius ) ->
        @beginPath()
        @moveTo x1 + radius, y1
        @lineTo @canvas.width - rightMargin, y1
        @lineTo @canvas.width - rightMargin, lowerLine
        @lineTo x2, lowerLine
        @lineTo x2, y2 - radius
        @arcTo x2, y2, x2 - radius, y2, radius
        @lineTo leftMargin, y2
        @lineTo leftMargin, upperLine
        @lineTo x1, upperLine
        @lineTo x1, y1 + radius
        @arcTo x1, y1, x1 + radius, y1, radius
        @closePath()

## Rectangle overlapping

The following routine computes whether two rectangles collide.  The first is
given by upper-left corner (x1,y1) and lower-right corner (x2,y2).  The
second is given by upper-left corner (x3,y3) and lower-right corner (x4,y4).
The routine returns true iff the interior of the rectangles intersect.
(If they intersect only on their boundaries, false is returned.)

    window.rectanglesCollide = ( x1, y1, x2, y2, x3, y3, x4, y4 ) ->
        not ( x3 >= x2 or x4 <= x1 or y3 >= y2 or y4 <= y1 )

## Rendering HTML to Images and/or Canvases

This section provides two routines, one for converting arbitrary HTML to an
SVG Blob object, and another for rendering such SVGs onto a canvas.  Here is
the first of those two routines.

Because this function makes use of the document's body, it can only be
called once page loading has completed.

    window.svgBlobForHTML = ( html, style = 'font-size:12px' ) ->

First, compute its dimensions using a temporary span in the document.

        span = document.createElement 'span'
        span.setAttribute 'style', style
        span.innerHTML = html
        document.body.appendChild span
        span = $ span
        width = span.width() + 2 # cushion for error
        height = span.height() + 2
        span.remove()

Then build an SVG and store it as blob data.  (See the next function in this
file for how the blob is built.)

        makeBlob "<svg xmlns='http://www.w3.org/2000/svg' width='#{width}'
                  height='#{height}'><foreignObject width='100%'
                  height='100%'><div xmlns='http://www.w3.org/1999/xhtml'
                  style='#{style}'>#{html}</div></foreignObject></svg>",
                 'image/svg+xml;charset=utf-8'

The previous function makes use of the following cross-browser Blob-building
utility gleaned from [this StackOverflow
post](http://stackoverflow.com/questions/15293694/blob-constructor-browser-compatibility).

    makeBlob = ( data, type ) ->
        try
            new Blob [ data ], type : type
        catch e
            # TypeError old chrome and FF
            window.BlobBuilder = window.BlobBuilder ?
                                 window.WebKitBlobBuilder ?
                                 window.MozBlobBuilder ?
                                 window.MSBlobBuilder
            if e.name is 'TypeError' and window.BlobBuilder?
                bb = new BlobBuilder()
                bb.append data.buffer
                bb.getBlob type
            else if e.name is 'InvalidStateError'
                # InvalidStateError (tested on FF13 WinXP)
                new Blob [ data.buffer ], type : type

Now we move on to the routine for rendering arbitrary HTML to a canvas, but
there are some preliminaries we need to build first.

Canvas rendering happens asynchronously.  If the routine returns false, then
it did not render, but rather began preparing the HTML for rendering (by
initiating the background rendering of the HTML to an image).  Those results
will then be cached, so later calls to this routine will return true,
indicating success (immediate rendering).

To support this, we need a cache.  The following routines define the cache.

    drawHTMLCache = order : [ ], maxSize : 100
    cacheLookup = ( html, style ) ->
        key = JSON.stringify [ html, style ]
        if drawHTMLCache.hasOwnProperty key then drawHTMLCache[key] \
            else null
    addToCache = ( html, style, image ) ->
        key = JSON.stringify [ html, style ]
        drawHTMLCache[key] = image
        markUsed html, style
    markUsed = ( html, style ) ->
        key = JSON.stringify [ html, style ]
        if ( index = drawHTMLCache.order.indexOf key ) > -1
            drawHTMLCache.order.splice index, 1
        drawHTMLCache.order.unshift key
        pruneCache()
    pruneCache = ->
        while drawHTMLCache.order.length > drawHTMLCache.maxSize
            delete drawHTMLCache[drawHTMLCache.order.pop()]

And now, the rendering routine, which is based on code taken from [this MDN
article](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Drawing_DOM_objects_into_a_canvas).

    CanvasRenderingContext2D::drawHTML =
    ( html, x, y, style = 'font-size:12px' ) ->

If the given HTML has already been rendered to an image that remains in the
cache, just use that immediately and return success.

        if image = cacheLookup html, style
            @drawImage image, x, y
            markUsed html, style
            return yes

Otherwise, begin rendering that HTML to an image, for later insertion into
the cache, and return (temporary) failure.  Start by creating the image and
assign its URL, so that when rendering completes asynchronously, we can
store the results in the cache.

        url = objectURLForBlob svgBlobForHTML html, style
        image = new Image()
        image.onload = ->
            addToCache html, style, image
            ( window.URL ? window.webkitURL ? window ).revokeObjectURL url
        image.onerror = ( error ) ->
            addToCache html, style, new Image()
            console.log 'Failed to load SVG with this <foreignObject> div
                content:', html
        image.src = url
        no

The above function makes use of the following routine, which converts a Blob
into an image URL using `createObjectURL`.

    window.objectURLForBlob = ( blob ) ->
        ( window.URL ? window.webkitURL ? window ).createObjectURL blob

The following does the same thing, but creates a URL with the base-64
encoding of the blob in it.  This must be done asynchronously, but then the
URL can be used anywhere, not just in this script environment.  The result
is sent to the given callback.

    window.base64URLForBlob = ( blob, callback ) ->
        reader = new FileReader
        reader.onload = ( event ) -> callback event.target.result
        reader.readAsDataURL blob

The following routine queries the same cache to determine the width and
height of a given piece of HTML that could be rendered to the canvas.  If
the HTML is not in the cache, this returns null.  Otherwise, it returns an
object with width and height attributes.

    CanvasRenderingContext2D::measureHTML =
    ( html, style = 'font-size:12px' ) ->
        if image = cacheLookup html, style
            markUsed html, style
            width : image.width
            height : image.height
        else
            @drawHTML html, 0, 0, style # forces caching
            null



# Utility functions for working with the DOM

This file defines all of its functions inside one enormous `installIn`
function, which installs those methods into a particular `window` instance.
This is so that it can be used in an iframe in addition to the main window.
This file itself calls `installIn` on the main `window` instance, so you do
not need to.  But if you also wish to use these functions within an iframe,
you can call `installIn` on the `window` instance for that iframe.

    window.installDOMUtilitiesIn = ( window ) ->

## Address

The address of a node `N` in an ancestor node `M` is an array `a` of
non-negative integer indices such that
`M.childNodes[a[0]].childNodes[a[1]]. ... .childNodes[a[a.length-1]] == N`.
Think of it as the path one must walk through children to get from `M` down
to `N`.  Special cases:
 * If the array is of length 1, then `M == N.parentNode`.
 * If the array is empty, `[]`, then `M == N`.
 * If `M` is not an ancestor of `N`, then we say the address of `N`
   within `M` is null (not an array at all).

The following member function of the `Node` class adds the address function
to that class.  Using the `M` and `N` from above, one would call it like
`N.address M`.  [See below](#index) for its inverse function, `index`.

It computes the address of any one DOM node within any other. If the
parameter (the ancestor, called `M` above) is not supplied, then it defaults
to the top-level Node above `N` (i.e., the furthest-up ancestor, with no
`.parentNode`, which usually means it's the global variable `document`).

        window.Node::address = ( ancestor = null ) ->

The base case comes in two flavors. First, if the parameter is this node,
then the correct result is the empty array.

            if this is ancestor then return []

Second, if we've reached the top level then we must consider the second
parameter.  Were we restricted to a specific ancestor?  If so, we didn't
find it, so return null.  If not, return the empty array, because we have
reached the top level.

            if not @parentNode
                return if ancestor then null else []

Otherwise, recur up the ancestor tree, and concatenate our own index in our
parent with the array we compute there, if there is one.

            recur = @parentNode.address ancestor
            if recur is null then return null
            recur.concat [ @indexInParent() ]

You'll notice that the final line of code above depends on the
as-yet-undefined helper function `indexInParent()`.  We therefore create
that simple helper function now, which is also a useful member of the `Node`
prototype.

        window.Node::indexInParent = ->
            if @parentNode
                Array::slice.apply( @parentNode.childNodes ).indexOf this
            else
                -1

## Index

This function is an inverse for `address`, [defined above](#address).

The node at index `I` in node `N` is the descendant `M` of `N` in the node
hierarchy such that `M.address N` is `I`. In short, if `N` is any ancestor
of `M`, then `N.index(M.address(N)) == M`.

Keeping in mind that an address is simply an array of nonnegative integers,
the implementation is simply repeated lookups in some `childNodes` arrays.
It is therefore quite short, with most of the code going to type safety.

        window.Node::index = ( address ) ->

Require that the parameter be an array.

            if address not instanceof Array
                throw Error 'Node address function requires an array'

If the array is empty, we've hit the base case of this recursion.

            if address.length is 0 then return this

Othwerise, recur on the child whose index is the first element of the given
address.  There are two safety checks here.  First, we verify that the index
we're about to look up is a number (otherwise things like `[0]` will be
treated as zero, which is probably erroneous).  Second, the `?.` syntax
below ensures that that index is valid, so that we do not attempt to call
this function recursively on something other than a node.

            if typeof address[0] isnt 'number' then return undefined
            @childNodes[address[0]]?.index address[1..]

## Serialization

### From DOM Nodes to objects

These methods are for serializing and unserializing DOM nodes to objects
that are amenable to JSON processing.

First, the function for converting a DOM Node to an object that can be
serialized with `JSON.stringify`.  After this function is defined, one can
take any node `N` and call `N.toJSON()`.

        window.Node::toJSON = ( verbose = yes ) ->

The `verbose` parameter uses human-readable object keys, and is the default.
A more compact version can be obtained by setting that value to false.  The
inverse function below can handle either format.  The shrinking of keys
follows the following convention.
 * tagName becomes t
 * attributes becomes a
 * children becomes c
 * comment becomes m
 * content becomes n

Text nodes are simply returned as strings.

            if this instanceof window.Text then return @textContent

Comment nodes are returned as objects with a comment flag and a text content
attribute.

            if this instanceof window.Comment
                return if verbose
                    comment : yes, content : @textContent
                else
                    m : yes, n : @textContent

All other types of nodes must be elements in order to be serialized by this
routine.

            if this not instanceof window.Element
                throw Error "Cannot serialize this node: #{this}"

A serialized Element is an object with up to three properties, tag name,
attribute dictionary, and child nodes array.  We create that object, then
add the attributes dictionary and children array if and only if they are
nonempty.

            result = tagName : @tagName
            if @attributes.length
                result.attributes = { }
                for attribute in @attributes
                    result.attributes[attribute.name] = attribute.value
            if @childNodes.length
                result.children =
                    ( chi.toJSON verbose for chi in @childNodes )

If verbosity is disabled, change all the object keys to one-letter
abbreviations.

            if not verbose
                result.t = result.tagName ; delete result.tagName
                result.a = result.attributes ; delete result.attributes
                result.c = result.children ; delete result.children
            result

### From objects to DOM Nodes

Next, the function for converting an object produced with `N.toJSON()` back
into an actual DOM Node.  This function requires its one parameter to be one
of two types, either a string (meaning that a text node should be returned)
or an object with the three properties given above (tagName, attributes,
children, meaning that an Element should be returned).  One calls it by
writing `Node.toJSON object`.

        window.Node.fromJSON = ( json ) ->

Handle the easy case first:  strings yield text nodes.

            if typeof json is 'string'
                return window.document.createTextNode json

Next, if we can find a comment flag in the object, then we create and return
a comment.

            if 'comment' of json and json.comment
                return window.document.createComment json.content
            if 'm' of json and json.m
                return window.document.createComment json.n

The only other possibility is that the object encodes an Element. So if we
can't get a tag name from the object, we cannot proceed, and thus the input
was invalid.

            if not 'tagName' of json and not 't' of json
                throw Error "Object has no t[agName]: #{this}"

Create an element using the tag name, add any attributes from the given
object, and recur on the child array if there is one.

            result = window.document.createElement json.tagName or json.t
            if attributes = json.attributes or json.a
                for own key, value of attributes
                    result.setAttribute key, value
            if children = json.children or json.c
                for child in children
                    result.appendChild Node.fromJSON child
            result

## Next and previous leaves

Although the DOM provides properties for the next and previous siblings of
any node, it does not provide a method for finding the next or previous
*leaf* nodes.  The following additions to the Node prototype do just that.

One can call `N.nextLeaf()` to get the next leaf node in the document
strictly after `N` (regardless of whether `N` itself is a leaf), or
`N.nextLeaf M` to restrict the search to within the ancestor node `M`.  `M`
defaults to the entire document.  `M` must be an ancestor of `N`, or this
default is used.

        window.Node::nextLeaf = ( container = null ) ->

Walk up the DOM tree until we can find a previous sibling.  Do not step
outside the bounds of the document or `container`.

            walk = this
            while walk and walk isnt container and not walk.nextSibling
                walk = walk.parentNode

If no next sibling could be found, quit now, returning null.

            walk = walk?.nextSibling
            if not walk then return null

We have a next sibling, so return its first leaf node.

            while walk.childNodes.length > 0 then walk = walk.childNodes[0]
            walk

The following routine is analogous to the previous one, but in the opposite
direction (finding the previous leaf node, within the given `container`, if
such a leaf node exists).  Its code is not documented because it is so
similar to the previous routine, which is documented.

        window.Node::previousLeaf = ( container = null ) ->
            walk = this
            while walk and walk isnt container and not walk.previousSibling
                walk = walk.parentNode
            walk = walk?.previousSibling
            if not walk then return null
            while walk.childNodes.length > 0
                walk = walk.childNodes[walk.childNodes.length - 1]
            walk

## More convenient `remove` method

Some browsers provide the `remove` method in the `Node` prototype, but some
do not.  To make things standard, I create the following member in the
`Node` prototype.  It guarantees that for any node `N`, the call
`N.remove()` has the same effect as the (more verbose and opaque) call
`N.parentNode.removeChild N`.

        window.Node::remove = -> @parentNode?.removeChild this

## Adding classes to and removing classes from elements

It is handy to have methods that add and remove CSS classes on HTML element
instances.

First, for checking if one is there:

        window.Element::hasClass = ( name ) ->
            classes = ( @getAttribute 'class' )?.split /\s+/
            classes and name in classes

Next, for adding a class to an element:

        window.Element::addClass = ( name ) ->
            classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
            if name not in classes then classes.push name
            @setAttribute 'class', classes.join ' '

Last, for removing one:

        window.Element::removeClass = ( name ) ->
            classes = ( ( @getAttribute 'class' )?.split /\s+/ ) or []
            classes = ( c for c in classes when c isnt name )
            if classes.length > 0
                @setAttribute 'class', classes.join ' '
            else
                @removeAttribute 'class'

## Converting (x,y) coordinates to nodes

The browser will convert an (x,y) coordinate to an element, but not to a
text node within the element.  The following routine fills that gap.  Thanks
to [this StackOverflow answer](http://stackoverflow.com/a/13789789/670492).

        window.document.nodeFromPoint = ( x, y ) ->
            elt = window.document.elementFromPoint x, y
            for node in elt.childNodes
                if node instanceof window.Text
                    range = window.document.createRange()
                    range.selectNode node
                    for rect in range.getClientRects()
                        if rect.left < x < rect.right and \
                           rect.top < y < rect.bottom then return node
            return elt

## Installation into main window global namespace

As mentioned above, we defined all of the functions in one big `installIn`
function so that we can install them in an iframe in addition to the main
window.  We now call `installIn` on the main `window` instance, so clients
do not need to do so.

    installDOMUtilitiesIn window



# OpenMath module

This module implements an encoding of OpenMath objects as JSON.  It is *not*
an official encoding endorsed by the OpenMath Society.  It is merely my own
choice of how to do the encoding, in the absence of an official standard
(that I could find).

Objects are encoded as follows.  (If these phrases are unfamiliar to you,
see [the OpenMath Standard,
v2.0](http://www.openmath.org/standard/om20-2004-06-30/).)
 * OMI - `{ t : 'i', v : 6 }` (where `t` stands for type and `v` for value),
   and integers may also be stored as strings if desired (e.g., `-6`)
 * OMF - `{ t : 'f', v : -0.521 }`
 * OMSTR - `{ t : 'st', v : 'example' }`
 * OMB - `{ t : 'ba', v : aUint8ArrayHere }`
 * OMS - `{ t : 'sy', n : 'symbolName', cd : 'cd', uri : 'http://...' }`,
   where the URI is optional
 * OMV - `{ t : 'v', n : 'name' }`
 * OMA - `{ t : 'a', c : [ child, objects, here ] }` (children are the
   required operator, followed by zero or more operands)
 * OMATTR - rather than wrap things in OMATTR nodes, simply add the
   attributes object (a mapping from string keys to objects) to the existing
   object, with 'a' as its key.  To create the string key for an OM symbol,
   just use its JSON form (fully compact, as created by `JSON.stringify`
   with one argument).
 * OMBIND - `{ t : 'bi', s : object, v : [ bound, vars ], b : object }`,
   where `s` stands for the head symbol and `b` for the body
 * OMERR - `{ t : 'e', s : object, c : [ child, nodes, here ] }`, where `s`
   stands for the head symbol, and `c` can be omitted if empty.
 * No encoding for foreign objects is specified here.

The following line ensures that this file works in Node.js, for testing.

    if not exports? then exports = module?.exports ? window

## OpenMath Node class

    exports.OMNode = exports.OM = OM = class OMNode

### Class ("static") methods

The following class method checks to see if an object is of any one of the
formats specified above; if so, it returns true, and if not, it returns an
error describing why not.  It is recursive, verifying that children are also
of the correct form.

It either returns a string, meaning that the object is invalid, and the
string contains the reason why, or it returns null, meaning that the object
is valid.

        @checkJSON : ( object ) ->
            if object not instanceof Object
                return "Expected an object, found #{typeof object}"

If the object has attributes, we must verify that their keys are the
stringified forms of JSON objects representing OpenMath symbols and their
values also pass this same validity test, recursively.

            if object.hasOwnProperty 'a'
                for own key, value of object.a
                    try
                        symbol = JSON.parse key
                    catch e
                        return "Key #{key} invalid JSON"
                    if symbol.t isnt 'sy'
                        return "Key #{key} is not a symbol"
                    if reason = @checkJSON symbol then return reason
                    if reason = @checkJSON value then return reason

This function verifies that the object doesn't have any keys beyond those on
the list, plus 't' for type and 'a' for attributes.

            checkKeys = ( list... ) ->
                for key in Object.keys object
                    if key not in list and key isnt 't' and key isnt 'a'
                        return "Key #{key} not valid in object of type
                            #{object.t}"
                null

This is not nearly the full range of Unicode symbols permitted for
identifiers in the OpenMath specification, but is a useful subset for this
first implementation.  See page 14 of [the
standard](http://www.openmath.org/standard/om20-2004-06-30/omstd20.pdf) for
the exact regular expression.

            identRE = /^[:A-Za-z_][:A-Za-z_.0-9-]*$/

Now we consider each type of object separately.

            switch object.t

Integers must have t and v keys, and the latter must look like an integer,
whether it's actually one or a string doesn't matter.

                when 'i'
                    if reason = checkKeys 'v' then return reason
                    if not /^[+-]?[0-9]+$/.test "#{object.v}"
                        return "Not an integer: #{object.v}"

Floats must have t and v keys, and the latter must be a number.

                when 'f'
                    if reason = checkKeys 'v' then return reason
                    if typeof object.v isnt 'number'
                        return "Not a number: #{object.v} of type
                            #{typeof object.v}"
                    if isNaN object.v
                        return 'OpenMath floats cannot be NaN'
                    if not isFinite object.v
                        return 'OpenMath floats must be finite'

Strings must have t and v keys, and the latter must be a string.

                when 'st'
                    if reason = checkKeys 'v' then return reason
                    if typeof object.v isnt 'string'
                        return "Value for st type was #{typeof object.v},
                            not string"

Byte Arrays must have t and v keys, the latter of which is a `Uint8Array`.

                when 'ba'
                    if reason = checkKeys 'v' then return reason
                    if object.v not instanceof Uint8Array
                        return "Value for ba type was not an instance of
                            Uint8Array"

Symbols must have t, n, and cd keys, with an optional uri key, all of which
must be strings.  The n key (for "name") must be a valid identifier, in that
it must match the regular expression defined above.

                when 'sy'
                    if reason = checkKeys 'n','cd','uri' then return reason
                    if typeof object.n isnt 'string'
                        return "Name for sy type was #{typeof object.n},
                            not string"
                    if typeof object.cd isnt 'string'
                        return "CD for sy type was #{typeof object.cd},
                            not string"
                    if object.uri? and typeof object.uri isnt 'string'
                        return "URI for sy type was #{typeof object.uri},
                            not string"
                    if not identRE.test object.n
                        return "Invalid identifier as symbol name:
                            #{object.n}"
                    if not identRE.test object.cd
                        return "Invalid identifier as symbol CD:
                            #{object.cd}"

Variables must have t and n keys, the latter of which must be a valid
identifier, matching the same regular expression as above.

                when 'v'
                    if reason = checkKeys 'n' then return reason
                    if typeof object.n isnt 'string'
                        return "Name for v type was #{typeof object.n},
                            not string"
                    if not identRE.test object.n
                        return "Invalid identifier as variable name:
                            #{object.n}"

Applications must have t and c keys, the latter of which must be an array of
objects that pass this same validity test, applied recursively.  It may not
be empty.

                when 'a'
                    if reason = checkKeys 'c' then return reason
                    if object.c not instanceof Array
                        return "Children of application object was not an
                            array"
                    if object.c.length is 0
                        return "Application object must have at least one
                            child"
                    for child in object.c
                        if reason = @checkJSON child then return reason

Bindings must have t, s, v, and b keys, where s is a symbol, v an array of
variables, and b any OpenMath node.

                when 'bi'
                    if reason = checkKeys 's', 'v', 'b' then return reason
                    if reason = @checkJSON object.s then return reason
                    if object.s.t isnt 'sy'
                        return "Head of a binding must be a symbol"
                    if object.v not instanceof Array
                        return "In a binding, the v value must be an array"
                    for variable in object.v
                        if reason = @checkJSON variable then return reason
                        if variable.t isnt 'v'
                            return "In a binding, all values in the v array
                                must have type v"
                    if reason = @checkJSON object.b then return reason

Errors must have t, s, and c keys, with s a symbol and c an array of child
nodes.

                when 'e'
                    if reason = checkKeys 's', 'c' then return reason
                    if reason = @checkJSON object.s then return reason
                    if object.s.t isnt 'sy'
                        return "Head of an error must be a symbol"
                    if object.c not instanceof Array
                        return "In an error, the c key must be an array"
                    for child in object.c
                        if reason = @checkJSON child then return reason

If the object's type is not on that list, it's not valid.

                else
                    return "Invalid type: #{object.t}"

If all of the above checks pass then we return null, meaning the object is
valid (no errors).

            null

The following function converts a string encoding of an OpenMath structure
and creates an instance of `OMNode` for the corresponding structure.
 * If the string contains invalid JSON, this routine will return an
   error message string rather than an OMNode object.
 * If it contains JSON for a structure that doesn't pass `checkJSON`, above,
   again, an error message string is returned.
 * Otherwise it adds appropriate parent pointers to the nodes in the
   resulting tree, then wraps it in an instance of OMNode and returns it.
The function can also take an object that has been parsed from such JSON
text.

        @decode : ( json ) ->
            if typeof json is 'string'
                try json = JSON.parse json catch e then return e.message
            if reason = @checkJSON json then return reason
            setParents = ( node ) ->
                for c in node.c ? [ ] # children, if any
                    c.p = node
                    setParents c
                for v in node.v ? [ ] # bound variables, if any
                    v.p = node
                    setParents v
                for own k, v of node.a ? { } # attribute values, if any
                    v.p = node
                    setParents v
                # head symbol and body object, if any
                if node.s? then node.s.p = node ; setParents node.s
                if node.b? then node.b.p = node ; setParents node.b
            setParents json
            json.p = null
            new OMNode json

### Constructor

The above factory function uses the following constructor.  The constructor
also defines several properties for the object, by installing getters for
the common attributes type, value, name, cd, uri, symbol, body, children,
and variables.  These all return undefined if they do not apply to the
current structure, except children and variables, which return empty arrays
in that case.

        constructor : ( @tree ) ->
            Object.defineProperty this, 'parent',
                get : -> if @tree.p then new OMNode @tree.p else undefined
            Object.defineProperty this, 'type', get : -> @tree.t
            Object.defineProperty this, 'value',
                get : -> if @tree.t isnt 'bi' then @tree.v else undefined
            Object.defineProperty this, 'name', get : -> @tree.n
            Object.defineProperty this, 'cd', get : -> @tree.cd
            Object.defineProperty this, 'uri', get : -> @tree.uri
            Object.defineProperty this, 'symbol',
                get : -> if @tree.s then new OMNode @tree.s else undefined
            Object.defineProperty this, 'body',
                get : -> if @tree.b then new OMNode @tree.b else undefined
            Object.defineProperty this, 'children',
                get : -> new OMNode child for child in @tree.c ? [ ]
            Object.defineProperty this, 'variables',
                get : -> if @tree.t is 'bi'
                    new OMNode variable for variable in @tree.v
                else
                    [ ]

### Serialization

Unserializing an `OMNode` object from a string is done by the `decode`
method, above.  Serializing is done by its inverse, here, which simply uses
`JSON.stringify`, but filters out parent pointers.

        encode : =>
            JSON.stringify @tree, ( k, v ) ->
                if k is 'p' then undefined else v

### Copies and equality

Two instances will often want to be compared for equality, structurally.
This is essentially the same activity as comparing equality of two JSON
structures, except parent pointers should be ignored so that the recursion
remains acyclic.

You can pass a second parameter indicating whether to pay attention to
attributes in the comparison.  By default it is true, meaning consider all
attributes.  If it is false, no attributes will be considered.  Other values
may be supported in the future.

        equals : ( other, attributes = yes ) =>
            recur = ( a, b ) ->

If they are atomically equal, we're done.

                if a is b then return yes

If they're arrays, ensure they have the same length, type, and contents.

                if a instanceof Array or a instanceof Uint8Array
                    if ( a instanceof Array ) and ( b not instanceof Array )
                        return no
                    if ( a instanceof Uint8Array ) and \
                       ( b not instanceof Uint8Array )
                        return no
                    if a.length isnt b.length then return no
                    for element, index in a
                        if not recur element, b[index] then return no
                    return yes

Otherwise, they must be objects, with all the same key-value pairs.

                if a not instanceof Object then return no
                if b not instanceof Object then return no
                for own key, value of a
                    if key is 'p' or not attributes and key is 'a'
                        continue
                    if not b.hasOwnProperty key then return no
                    if not recur value, b[key] then return no
                for own key, value of b
                    if key is 'p' or not attributes and key is 'a'
                        continue
                    if not a.hasOwnProperty key then return no
                yes
            recur @tree, other.tree

There is also a much stricter notion of equality:  Do the two OMNode objects
actually wrap the same object underneath?  That is, are they pointing to the
same tree in memory?  This function can detect that.

        sameObjectAs : ( other ) => @tree is other?.tree

On a similar note, you may want to create a distinct copy of any given
OMNode instance.  Here is a method for doing so.

        copy : =>
            recur = ( tree ) ->
                switch tree.t

Integers, floats, and strings are easy to copy; just duplicate type and
value.  Variables and symbols are easy for the same reason, but different
atomic members.

                    when 'i', 'f', 'st' then { t : tree.t, v : tree.v }
                    when 'v' then { t : 'v', n : tree.n }
                    when 'sy'
                        result = { t : 'sy', n : tree.n, cd : tree.cd }
                        if tree.hasOwnProperty 'uri'
                            result.uri = tree.uri
                        result

Byte arrays require making a copy of the byte array object, which can be
accomplished with the constructor.

                    when 'ba' then { t : 'ba', v : new Uint8Array tree.v }

For errors and applications, we copy the children array; for errors we also
include the symbol.

                    when 'e', 'a'
                        result =
                            t : tree.t
                            c : ( recur child for child in tree.c )
                        if tree.t is 'e' then result.s = recur tree.s
                        result

Lastly, for bindings, we copy each sub-part: symbol, body, variable list.

                    when 'bi'
                        t : 'bi'
                        s : recur tree.s
                        v : ( recur variable for variable in tree.v )
                        b : recur tree.b
            OMNode.decode recur @tree

### Factory functions

We provide here functions for creating each type of OMNode, from integer to
error.  Each is a "static" (class) method, documented separately.  It
returns an error message as a string if there was an error, instead of the
desired OMNode instance.

The integer factory function creates an OpenMath integer node, and must be
passed a single parameter containing either an integer or a string
representation of an integer, e.g., `OM.integer 100`.

        @integer : ( value ) ->
            OMNode.decode { t : 'i', v : value }

The float factory function creates an OpenMath float node, and must be
passed a single parameter containing a number, e.g., `OM.integer 1.234`,
and that number cannot be infinite or NaN.

        @float : ( value ) ->
            OMNode.decode { t : 'f', v : value }

The string factory function creates an OpenMath string node, and must be
passed a single parameter containing a string, e.g., `OM.integer 'hi'`.

        @string : ( value ) ->
            OMNode.decode { t : 'st', v : value }

The byte array factory function creates an OpenMath byte array node, and
must be passed a single parameter that is an instance of `Uint8Array`.

        @bytearray : ( value ) ->
            OMNode.decode { t : 'ba', v : value }

The symbol factory function creates an OpenMath symbol node, and must be
passed two or three parameters, in this order: symbol name (a string),
content dictionary name (a string), and optionally the CD's base URI (a
string).

        @symbol : ( name, cd, uri ) ->
            OMNode.decode if uri?
                { t : 'sy', n : name, cd : cd, uri : uri }
            else
                { t : 'sy', n : name, cd : cd }

The variable factory function creates an OpenMath variable node, and must be
passed one parameter, the variable name (a string).

        @variable : ( name ) ->
            OMNode.decode { t : 'v', n : name }

The application factory creates an OpenMath application node, and accepts a
variable number of arguments, each of which must be either an `OMNode`
instance or the JSON object that could function as the tree within such an
instance.  `OMNode` instances are copied, objects are used as-is.

        @application : ( args... ) ->
            result = { t : 'a', c : [ ] }
            for arg in args
                result.c.push if arg instanceof OMNode
                    JSON.parse arg.encode() # copy without parent pointers
                else
                    arg
            OMNode.decode result

The attribution factory creates an OpenMath node from its first argument,
and attaches to it the attributes specified by the remaining arguments.
Those remaining arguments must come in pairs k1, v1, through kn, vn, and
each ki,vi pair must be an OpenMath symbol node followed by any OpenMath
node.  As in the case of applications, such nodes may be JSON objects or
`OMNode` instances; the former are used as-is and the latter copied.  The
first parameter can also be either a JSON object or an `OMNode` instance,
and in the latter case it, too, is copied.

        @attribution : ( node, attrs... ) ->
            if node not instanceof Object
                return 'Invalid first parameter to attribution'
            if attrs.length % 2 isnt 0
                return 'Incomplete key-value pair in attribution'
            if node instanceof OMNode then node = JSON.parse node.encode()
            while attrs.length > 0
                node.a ?= { }
                key = attrs.shift()
                key = if key instanceof OMNode
                    key.encode()
                else
                    JSON.stringify key
                value = attrs.shift()
                node.a[key] = if value instanceof OMNode
                    JSON.parse value.encode() # copy without parent pointers
                else
                    value
            OMNode.decode node

The binding factory functions exactly like the application factory, except
that it has restrictions on the types of its arguments.  The first must be a
symbol (used as the head of the binding), the last can be any OpenMath node,
and all those in between must be variables.  Furthermore, there must be at
least two arguments, so that there is a head and a body.  Just as in the
case of applications, `OMNode` instances are copied, but straight JSON
objects are used as-is.

        @binding : ( head, vars..., body ) ->
            if head not instanceof Object
                return 'Invalid first parameter to binding'
            if body not instanceof Object
                return 'Invalid last parameter to binding'
            result =
                t : 'bi'
                s : if head instanceof OMNode
                    JSON.parse head.encode()
                else
                    head
                v : [ ]
                b : if body instanceof OMNode
                    JSON.parse body.encode()
                else
                    body
            for variable in vars
                result.v.push if variable instanceof OMNode
                    JSON.parse variable.encode() # copy w/o parent pointers
                else
                    variable
            OMNode.decode result

The error factory functions exactly like the application factory, except
that it has one restriction on the types of its arguments:  The first must
be a symbol.  Just as in the case of applications, `OMNode` instances are
copied, but straight JSON objects are used as-is.

        @error : ( head, others... ) ->
            if head not instanceof Object
                return 'Invalid first parameter to binding'
            result =
                t : 'e'
                s : if head instanceof OMNode
                    JSON.parse head.encode()
                else
                    head
                c : [ ]
            for other in others
                result.c.push if other instanceof OMNode
                    JSON.parse other.encode() # copy without parent pointers
                else
                    other
            OMNode.decode result

### Simple encoding and decoding

The above functions can be used to create OpenMath data structures of
arbitrary complexity and type.  But most use cases can be handled with only
a subset of that full complexity, and we provide the following toosl for
doing so.

`OMNode.simpleDecode()` takes a string as input (like `OMNode.decode()`
does), but this string is in a much simple form.  Here are the formats it
supports.
 * `anyIdentifier` will be treated as a variable.  Examples:
   * `x`
   * `thing_7`
 * `ident1.ident2` will be treated as a symbol (CD and name, respectively).
   Examples:
   * `arith1.plus`
   * `transc1.arcsin`
 * any integer will be treated as an integer.  Examples:
   * -6
   * 57328074078459027340 (value will be a string, due to size)
 * any float will be treated as a float.  Examples:
   * 582.53280
   * -0.00001
 * a string literal enclosed in quotation marks (`"`) will be treated as a
   string, but with no support for escape codes, other than `\"`.  Examples:
   * "this is a string"
   * ""
 * a string literal enclosed in single quotes (`'`) behaves the same way,
   escaping only `\'`
   * 'this is also a string, ain\'t it?'
   * '""'
 * `F(A1,...,An)`, where `F` is any valid form and each `Ai` is as well,
   is interpreted as the application of `F` to the `Ai` in the order given.
   Here `n` may be zero.  Examples:
   * `f(x)`
   * `transc1.arcsin(arith1.divide(1,2))`
 * `F[A1,...,An]` behaves the same as the previous case, except that the
   `Ai` entries before `An` must all be variables, and they will be bound;
   i.e., this yields an OpenMath binding object, not an application object.
   Examples:
   * `logic.forall(x,P(x))`
   * `foo.lambda(x,f(x,7,"bar"))`
This syntax does not allow for the expression of OpenMath error objects,
attributions, symbol URIs, byte arrays, or very large integers.

We declare the following structure for use in the routine below.

        tokenTypes = [
            name : 'symbol'
            pattern : /[:A-Za-z_][:A-Za-z_0-9-]*\.[:A-Za-z_][:A-Za-z_0-9-]*/
        ,
            name : 'variable'
            pattern : /[:A-Za-z_][:A-Za-z_0-9-]*/
        ,
            name : 'float'
            pattern : /[+-]?(?:[0-9]+\.[0-9]*|[0-9]*\.[0-9]+)/
        ,
            name : 'integer'
            pattern : /[+-]?[0-9]+/
        ,
            name : 'string'
            pattern : /"(?:[^"\\]|\\"|\\\\)*"|'(?:[^'\\]|\\'|\\\\)*'/
        ,
            name : 'comma'
            pattern : /,/
        ,
            name : 'openParen'
            pattern : /\(/
        ,
            name : 'closeParen'
            pattern : /\)/
        ,
            name : 'openBracket'
            pattern : /\[/
        ,
            name : 'closeBracket'
            pattern : /\]/
        ]

Now the routine itself.

        @simpleDecode = ( input ) ->

Ensure the input is a string.

            if typeof input isnt 'string'
                return 'Input was not a string'

Tokenize it using the above token data.

            tokens = [ ]
            while input.length > 0
                originally = input.length
                for tokenType in tokenTypes
                    match = tokenType.pattern.exec input
                    if match? and match.index is 0
                        tokens.push
                            type : tokenType.name
                            text : match[0]
                        input = input[match[0].length..]
                if input.length is originally
                    return "Could not understand from here: #{input[..10]}"

Parse tokens using two states: one for when an expression is about to start,
and one for when an expression just ended.  Maintain a stack of expressions
already parsed, for forming application and binding expressions.

            state = 'expression about to start'
            stack = [ ]
            while tokens.length > 0
                next = tokens.shift()
                switch state
                    when 'expression about to start'
                        switch next.type
                            when 'symbol'
                                halves = next.text.split '.'
                                stack.unshift
                                    node :
                                        OMNode.symbol halves[1], halves[0]
                            when 'variable'
                                stack.unshift
                                    node : OMNode.variable next.text
                            when 'integer'
                                int = parseInt next.text
                                if /\./.test int then int = next.text
                                stack.unshift node : OMNode.integer int
                            when 'float'
                                stack.unshift
                                    node : OMNode.float parseFloat next.text
                            when 'string'
                                type = next.text[0]
                                next = next.text[1...-1].replace \
                                    RegExp( "\\\\#{type}", 'g' ), type
                                stack.unshift node : OMNode.string next
                            else return "Unexpected #{next.text}"
                        state = 'expression ended'
                    when 'expression ended'
                        switch next.type
                            when 'comma'
                                state = 'expression about to start'
                            when 'openParen'
                                stack[0].head = 'application'
                                if tokens?[0]?.type is 'closeParen'
                                    tokens.shift()
                                    stack.unshift
                                        node : OMNode.application \
                                            stack.shift().node
                                    state = 'expression ended'
                                else
                                    state = 'expression about to start'
                            when 'openBracket'
                                stack[0].head = 'binding'
                                state = 'expression about to start'
                            when 'closeParen'
                                for expr, index in stack
                                    if expr.head is 'application' then break
                                    if expr.head is 'binding'
                                        return "Mismatch: [ closed by )"
                                if index is stack.length
                                    return "Unexpected )"
                                children = [ ]
                                for i in [0..index]
                                    children.unshift stack.shift().node
                                stack.unshift
                                    node : OMNode.application.apply \
                                        null, children
                            when 'closeBracket'
                                for expr, index in stack
                                    if expr.head is 'binding' then break
                                    if expr.head is 'application'
                                        return "Mismatch: ( closed by ]"
                                if index is stack.length
                                    return "Unexpected ]"
                                children = [ ]
                                for i in [0..index]
                                    children.unshift stack.shift().node
                                stack.unshift
                                    node : OMNode.binding.apply \
                                        null, children
                            else return "Unexpected #{next.text}"
                if typeof stack?[0].node is 'string'
                    return stack[0].node # error in building OMNode

Parsing complete so there should be just one node on the stack, the result.
If there is more than one, we have an error.

            if stack.length > 1
                "Unexpected end of input"
            else
                stack[0].node

The inverse to the above function is a simple encoding function.  It can
operate on only a subset of the full complexity of OMNode trees, and thus in
some cases it gives results that are not representative of the input.  Here
are the details:
 * integers, floats, and strings will all be correctly encoded
 * variables without dots in their names will be correctly encoded; those
   with dots in their names conflict with the naming of symbols in the
   simple encoding, but will be encoded as their names
 * symbols will be correctly encoded with the exception that any URI will be
   dropped, and the same issue with dots applies to symbol and CD names
 * byte arrays and errors have no simple encoding, and will thus all be
   converted to a string containing the words "byte array" or "error,"
   respectively
 * all attributions are dropped

        simpleEncode : =>
            recur = ( tree ) ->
                switch tree?.t
                    when 'i', 'f' then "#{tree.v}"
                    when 'v' then tree.n
                    when 'st' then "'#{tree.v.replace /'/g, '\\\''}'"
                    when 'sy' then "#{tree.cd}.#{tree.n}"
                    when 'ba' then "'byte array'"
                    when 'e' then "'error'"
                    when 'a'
                        children = ( recur c for c in tree.c )
                        head = children.shift()
                        "#{head}(#{children.join ','})"
                    when 'bi'
                        variables = ( recur v for v in tree.v )
                        head = recur tree.s
                        body = recur tree.b
                        "#{head}[#{variables.join ','},#{body}]"
                    else "Error: Invalid OpenMath type #{tree?.t}"
            recur @tree

### Parent-child relationships

The functions in this category make, break, or report the relationship of an
OMNode instance to its parents or children.

This first function reports where the node is in its parent.  The return
value will be one of five types:
 * a string containing "c" followed by a number, as in 'c7' - this means
   that the node is in it's parent's `children` array, and is at index 7
 * a string containing "v" followed by a number, as in 'v0' - this is the
   same as the previous, but for the parent's `variables` array
 * the string "b" - this means that the node is the body and its parent is
   a binding
 * the string "s" - this means that the node is a symbol for its parent,
   which is either an error or a binding
 * a lengthier string beginning with "{" - this is the JSON encoded version
   of the attribute key for which the node is the corresponding value
 * undefined if none of the above apply (e.g., no parent, or invalid tree
   structure)

        findInParent : =>
            if not @parent then return undefined
            for child, index in @parent.children
                if @sameObjectAs child then return "c#{index}"
            if @type is 'v'
                for variable, index in @parent.variables
                    if @sameObjectAs variable then return "v#{index}"
            if @sameObjectAs @parent.symbol then return 's'
            if @sameObjectAs @parent.body then return 'b'
            for own key, value of @parent.tree.a ? { }
                if @tree is value then return key
            undefined # should not happen

The following function breaks the relationship of the object with its
parent.  In some cases, this can invalidate the parent (e.g., by giving a
binding or error object no head symbol, or a binding no body, or no bound
variables).  If the object has no parent or its position in that parent is
undefined (as determined by `@findInParent()`) then this does nothing.

        remove : =>
            if not index = @findInParent() then return
            switch index[0]
                when 'c'
                    @parent.tree.c.splice parseInt( index[1..] ), 1
                when 'v'
                    @parent.tree.v.splice parseInt( index[1..] ), 1
                when 'b' then delete @parent.tree.b
                when 's' then delete @parent.tree.s
                when '{' then delete @parent.tree.a[index]
            delete @tree.p

Then we have three functions that let us manipulate attributes without
worrying about the unpredictable ordering of keys in a JSON stringification
of an object.

The first takes an OMNode instance as input and looks up the corresponding
key-value pair in this object's attributes, if there is one.  If so, it
returns the corresponding value as an OMNode instance.  Otherwise, it
returns undefined.

For efficiency, this considers only the names and CDs of the key when
searching.  If that becomes a problem later, it could be changed here in
this function, as well as in the two that follow.

        getAttribute : ( keySymbol ) =>
            if keySymbol not instanceof OMNode then return undefined
            if keySymbol.type isnt 'sy' then return undefined
            nameRE = RegExp "\"n\":\"#{keySymbol.name}\""
            cdRE = RegExp "\"cd\":\"#{keySymbol.cd}\""
            for own key, value of @tree.a ? { }
                if nameRE.test( key ) and cdRE.test( key )
                    return new OMNode value

The second takes an OMNode instance as input and looks up the corresponding
key-value pair in this object's attributes, if there is one.  If so, it
deletes that key-value pair, which includes calling `remove()` on the value.
Otherwise, it does nothing.

The same efficiency comments apply to this function as to the previous.

        removeAttribute : ( keySymbol ) =>
            if keySymbol not instanceof OMNode then return
            if keySymbol.type isnt 'sy' then return
            nameRE = RegExp "\"n\":\"#{keySymbol.name}\""
            cdRE = RegExp "\"cd\":\"#{keySymbol.cd}\""
            for own key, value of @tree.a ? { }
                if nameRE.test( key ) and cdRE.test( key )
                    ( new OMNode value ).remove()
                    delete @tree.a[key]
                    return

The third and final function of the set takes two OMNode instances as input,
a key and a new value.  It looks up the corresponding key-value pair in this
object's attributes, if there is one.  If so, it replaces the original value
with the new value, including calling `remove()` on the old value.
Otherwise, it inserts a new key-value pair corresponding to the two
parameters.  In either case, `remove()` is called on the new value before it
is inserted into this tree, in case it is already in another tree.

The same efficiency comments apply to this function as to the previous.

        setAttribute : ( keySymbol, newValue ) =>
            if keySymbol not instanceof OMNode or \
               newValue not instanceof OMNode then return
            if keySymbol.type isnt 'sy' then return
            @removeAttribute keySymbol
            newValue.remove()
            ( @tree.a ?= { } )[keySymbol.encode()] = newValue.tree
            newValue.tree.p = @tree

## Nicknames

Here we copy each of the factory functions to a short version if its own
name, so that they can be combined in more compact form when creating
expressions.  Each short version is simply the first 3 letters of its long
version, to make them easy to remember.

    OM.int = OM.integer
    OM.flo = OM.float
    OM.str = OM.string
    OM.byt = OM.bytearray
    OM.sym = OM.symbol
    OM.var = OM.variable
    OM.app = OM.application
    OM.att = OM.attribution
    OM.bin = OM.binding
    OM.err = OM.error
    OM.simple = OM.simpleDecode



# Generic Utilities

This file provides functions useful across a wide variety of situations.
Utilities specific to the DOM appear in [the DOM utilities
package](domutilities.litcoffee.html).  More generic ones appear here.

## Equal JSON objects

By a "JSON object" I mean an object where the only information we care about
is that which would be preserved by `JSON.stringify` (i.e., an object that
can be serialized and deserialized with JSON's `stringify` and `parse`
without bringing any harm to our data).

We wish to be able to compare such objects for semantic equality (not actual
equality of objects in memory, as `==` would do).  We cannot simply do this
by comparing the `JSON.stringify` of each, because [documentation on
JSON.stringify](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify)
says that we cannot rely on a consistent ordering of the object keys.  Thus
we implement the following comparison routine.

Note that this only works for objects that fit the requirements above; if
equality (in your situation) is affected by the prototype chain, or if your
object contains functions, or any other similar difficulty, then this
routine is not guaranteed to work for you.

It yields the same result as `JSON.stringify(x) is JSON.stringify(y)` would
if `stringify` always gave the same ordering of object keys.

    JSON.equals = ( x, y ) ->

If only one is an object, or only one is an array, then they're not equal.
If neither is an object, you can use plain simple `is` to compare.

        return no if ( x instanceof Object ) isnt ( y instanceof Object )
        return no if ( x instanceof Array ) isnt ( y instanceof Array )
        if x not instanceof Object then return x is y

So now we know that both inputs are objects.

Get their keys in a consistent order.  If they aren't the same for both
objects, then the objects aren't equal.

        xkeys = ( Object.keys x ).sort()
        ykeys = ( Object.keys y ).sort()
        return no if ( JSON.stringify xkeys ) isnt ( JSON.stringify ykeys )

If there's any key on which the objects don't match, then they aren't equal.
Otherwise, they are.

        for key in xkeys
            if not JSON.equals x[key], y[key] then return no
        yes
