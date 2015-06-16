
# Universal Web Worker

This file implements a Web Worker that can take any function and compile it
for later calling (in a background thread) on arbitrary inputs.  The
general idea of the code in this file comes from [this blog post](
http://www.scottlogic.com/blog/2011/02/24/web-workers-part-3-creating-a-generic-worker.html).
Thanks, Jonathan!

## Utilities

The following routine constructs functions from strings more efficiently
than `eval` would.

    buildFunction = ( funcStr ) ->

We find the first "(...)" section of the string and lift out of it the
arguments list for the function.  Then we find the largest "{...}" section
of the string and lift out of it the function body.

            argList = funcStr.substring funcStr.indexOf( '(' ) + 1,
                                       funcStr.indexOf( ')' )
            body = funcStr.substring funcStr.indexOf( '{' ) + 1,
                                     funcStr.lastIndexOf( '}' )

We then call the `Function` constructor on those strings and store the
result.

            new Function argList, body

Ensure that this acts like a browser in the simple way that `window` means
the global scope.

    self.window = self

Now we create the main event handler through which clients communicate with
this worker.

    self.addEventListener 'message', ( event ) ->

## Receiving the function to execute

When we receive a message that tells us what function we will be running,
that message will contain the function as a string.

        if event.data.hasOwnProperty 'setFunction'
            self.action = buildFunction event.data.setFunction

Thus a caller should send us this message with code such as
`workerObject.postMessage setFunction : myFunction`.

## Calling the function we've stored

When we receive a message that tells us to run our function on a given
argument list, we call the function stored earlier (if it exists) on that
argument list.

        if event.data.hasOwnProperty 'runOn'
            self.postMessage self.action? event.data.runOn...

Thus a caller should send us this message with code such as
`workerObject.postMessage runOn : argumentList`.

## Installing global functions

Clients can also install functions globally in this environment by passing
the string version of the function to us, together with the name of the
global identifier by which it should be named.  The following case
implements that feature.

        if event.data.hasOwnProperty 'install'
            for own name, func of event.data.install
                self[name] = buildFunction func

Thus a caller should send us this message with code such as
`workerObject.postMessage install : { f : myFunc, g : otherFunc }`.

## Importing external scripts

Clients can also ask this worker to import external scripts.  They do so by
sending a message of the form `{ import : [ list, of, scripts ] }`, where
each entry in the list is the string name of a JavaScript file to import.
We handle such requests as follows.

        if event.data.hasOwnProperty 'import'
            importScripts event.data.import...

    , no
