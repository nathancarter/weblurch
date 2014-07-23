
# Tests for the undo/redo features of `DOMEditAction`s

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe, pageDo, pageExpects,
      pageExpectsError, inPage } = require './phantom-utils'

## Undo and redo

    phantomDescribe 'Undo and redo', './app/index.html', ->

### should work for "appendChild" actions

We will test this by performing an "appendChild" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "appendChild" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        '
                        {
                            tagName : 'SPAN'
                            children : [
                                {
                                    tagName : 'I'
                                    children : [ 'stuff,' ]
                                }
                                ' bro'
                            ]
                        }
                    ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div
                window.span = document.createElement 'span'
                span.innerHTML = '<i>stuff,</i> bro'

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.appendChild span
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'appendChild',
                toAppend : {
                    tagName : 'SPAN'
                    children : [
                        {
                            tagName : 'I'
                            children : [ 'stuff,' ]
                        }
                        ' bro'
                    ]
                }
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

### should work for "insertBefore" actions

We will test this by performing an "insertBefore" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "insertBefore" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [
                                {
                                    tagName : 'I'
                                    children : [ 'stuff,' ]
                                }
                                ' bro'
                            ]
                        }
                        '\n        '
                    ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div
                window.span = document.createElement 'span'
                span.innerHTML = '<i>stuff,</i> bro'

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.insertBefore span, div.childNodes[0]
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'insertBefore',
                insertBefore : 0, toInsert : {
                    tagName : 'SPAN'
                    children : [
                        {
                            tagName : 'I'
                            children : [ 'stuff,' ]
                        }
                        ' bro'
                    ]
                }
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "normalize" actions

We will test this by performing a "normalize" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "normalize" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        '
                        'one'
                        {
                            tagName : 'SPAN'
                            children : [ 'one and', ' a half' ]
                        }
                        'two'
                    ]
                }
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        one'
                        {
                            tagName : 'SPAN'
                            children : [ 'one and a half' ]
                        }
                        'two'
                    ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div
                div.appendChild document.createTextNode 'one'
                window.span = document.createElement 'span'
                span.innerHTML = 'one and'
                span.appendChild document.createTextNode ' a half'
                div.appendChild span
                div.appendChild document.createTextNode 'two'

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.normalize()
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'normalize',
                sequences : {
                    '[0]' : [ '\n        ', 'one' ]
                    '[1,0]' : [ 'one and', ' a half' ]
                }
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "removeAttribute" actions

We will test this by performing a "removeAttribute" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "removeAttribute" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    children : [ '\n        ' ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.removeAttribute 'id'
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'removeAttribute',
                name : 'id', value : '0'
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "removeAttributeNode" actions

We will test this by performing a "removeAttributeNode" action,
then asking it to be undone, then asking it to be redone, and
inspecting the DOM at each step to ensure it's as expected.

        it 'should work for "removeAttributeNode" actions',
        inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    children : [ '\n        ' ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.removeAttributeNode div.getAttributeNode 'id'
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'removeAttributeNode',
                name : 'id', value : '0'
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "removeChild" actions

We will test this by performing a "removeChild" action, then asking
it to be undone, then asking it to be redone, and inspecting the
DOM at each step to ensure it's as expected.

        it 'should work for "removeChild" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        '
                        {
                            tagName : 'SPAN'
                            children : [ 'this is a test' ]
                        }
                    ]
                }
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.span = document.createElement 'span'
                span.innerHTML = 'this is a test'
                div.appendChild span
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.removeChild span
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : [], type : 'removeChild',
                childIndex : 1, child : {
                    tagName : 'SPAN'
                    children : [ 'this is a test' ]
                }
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "replaceChild" actions

We will test this by performing a "replaceChild" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "replaceChild" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        '
                        {
                            tagName : 'SPAN'
                            children : [ 'this is a test' ]
                        }
                    ]
                }
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [
                        '\n        '
                        {
                            tagName : 'H1'
                            children : [
                                'a'
                                {
                                    tagName : 'SUP'
                                    children : [ 'b' ]
                                }
                            ]
                        }
                    ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.span = document.createElement 'span'
                span.innerHTML = 'this is a test'
                div.appendChild span
                window.repl = document.createElement 'h1'
                repl.innerHTML = 'a<sup>b</sup>'
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.replaceChild repl, span
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : []
                type : 'replaceChild'
                childIndex : 1
                oldChild : {
                    tagName : 'SPAN'
                    children : [ 'this is a test' ]
                }
                newChild : {
                    tagName : 'H1'
                    children : [
                        'a'
                        {
                            tagName : 'SUP'
                            children : [ 'b' ]
                        }
                    ]
                }
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "setAttribute" actions

We will test this by performing a "setAttribute" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "setAttribute" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    attributes : { id : '0', thing : 'whatever' }
                    children : [ '\n        ' ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                div.setAttribute 'thing', 'whatever'
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : []
                type : 'setAttribute'
                name : 'thing'
                newValue : 'whatever'
                oldValue : ''
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

### should work for "setAttributeNode" actions

We will test this by performing a "setAttributeNode" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "setAttributeNode" actions', inPage ->

Because undo and redo march a document through a sequence of states
(both forwards and backwards) we create that sequence of states
here, up front, so that we can simply index into it throughout this
test.  In this case we only have two states, the first before the
edit, and the second after it.

            states = [
                {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                {
                    tagName : 'DIV'
                    attributes : { id : '0', thing : 'whatever' }
                    children : [ '\n        ' ]
                }
            ]

Create DOM objects used in this test, and set up a tracker.

            pageDo ->
                window.div = document.getElementById '0'
                window.tracker = DOMEditTracker.instanceOver div

Verify that the initial state matches what's stored in the state
history, above, and is therefore expected.

            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform the editing action, and validate both it and its results.

            pageDo ->
                attr = document.createAttribute 'thing'
                attr.value = 'whatever'
                div.setAttributeNode attr
                window.action =
                    tracker.stack[tracker.stack.length - 1]
            pageExpects ( -> action.toJSON() ), 'toEqual', {
                node : []
                type : 'setAttributeNode'
                name : 'thing'
                newValue : 'whatever'
                oldValue : ''
            }
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Perform an undo of that action, and verify that the results are
back to the initial state.

            pageDo -> action.undo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[0]

Perform a redo of that action, and verify that the restuls are
back to the second state.

            pageDo -> action.redo()
            pageExpects ( -> div.toJSON() ), 'toEqual', states[1]

Then we perform an undo of that action, and then record the
results.

