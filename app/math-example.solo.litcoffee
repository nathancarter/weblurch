
# Mathematical Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example.solo.litcoffee) and then
for [the complex example application](complex-example.solo.litcoffee).
This application is more useful than either of those.

    setAppName 'MathApp'
    window.menuBarIcon = { }

[See a live version of this application online here.](
http://nathancarter.github.io/weblurch/app/math-example.html)

## Define one group type

For information on what this code does, see the simple example linked to
above.

    window.groupTypes = [
        name : 'me'
        text : 'Mathematical Expression'
        tooltip : 'Make the selection a mathematical expression'
        color : '#666699'
        imageHTML : '<font color="#666699"><b>[ ]</b></font>'
        openImageHTML : '<font color="#666699"><b>[</b></font>'
        closeImageHTML : '<font color="#666699"><b>]</b></font>'

The `contentsChanged` function is called on a group whenever that group just
had its contents changed.  In this case, we run [MathJS](http://mathjs.org/)
on the contents of the group, and store the result in the group itself.

[It is possible to run MathJS in a Web Worker thread](
http://mathjs.org/examples/browser/webworkers/index.html), and
[webLurch supports background threads](complex-example.solo.litcoffee),
but most computations here are brief enough that we can run them
immediately, in the foreground, and the user will notice absolutely no
hangups in the UI.  It also keeps the example simpler.

If we make a change to the group *in the change handler,* that will trigger
another change handler, which will create an infinite loop (and eventually a
"maximum call stack size exceeded" error in the browser).  Thus we first
inspect to see if the result we're about to store in the group is already
there; if so, we do nothing, and the loop ceases.

        contentsChanged : ( group, firstTime ) ->
            result =
                try "#{math.eval group.contentAsText()}" catch e then "???"
            if result isnt group.get 'result'
                group.set 'result', result

When the group's tag needs to be computed, we simply lift the data out of
the result already stored in the group from the above computation, and use
that to determine the contents of the bubble tag.

        tagContents : ( group ) -> group.get 'result'
    ]
