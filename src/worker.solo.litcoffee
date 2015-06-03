
# Universal Web Worker

This file implements a Web Worker that can take any function and compile it
for later calling (in a background thread) on arbitrary inputs.  The
general idea of the code in this file comes from [this blog post](
http://www.scottlogic.com/blog/2011/02/24/web-workers-part-3-creating-a-generic-worker.html).
Thanks, Jonathan!

    self.addEventListener 'message', ( event ) ->

## Receiving the function to execute

When we receive a message that tells us what function we will be running,
that message will contain the function as a string.

        if event.hasOwnProperty 'setFunction'
            funcStr = event.data.setFunction

We find the first "(...)" section of the string and lift out of it the
arguments list for the function.  Then we find the largest "{...}" section
of the string and lift out of it the function body.

        	argList = funcStr.substring funcStr.indexOf( '(' ) + 1,
                                        funcStr.indexOf( ')' )
        	body = funcStr.substring funcStr.indexOf( '{' ) + 1,
                                     funcStr.lastIndexOf( '}' )

We then call the `Function` constructor on those strings and store the
result.

        	self.action = new Function argList, body

Thus a caller should send us this message with code such as
`workerObject.postMessage setFunction : myFunction`.

## Calling the function we've stored

When we receive a message that tells us to run our function on a given
argument list, we call the function stored earlier (if it exists) on that
argument list.

        if event.hasOwnProperty 'runOn'
            self.postMessage self.action? event.data.runOn...

Thus a caller should send us this message with code such as
`workerObject.postMessage runOn : argumentList`.
