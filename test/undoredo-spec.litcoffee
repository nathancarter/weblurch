
# Tests for the undo/redo features of `DOMEditAction`s

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe } = require './phantom-utils'

## Undo and redo

    phantomDescribe 'Undo and redo', './app/index.html', ->

### should work for "appendChild" actions

We will test this by performing an "appendChild" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "appendChild" actions', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                tracker = DOMEditTracker.instanceOver div
                span = document.createElement 'span'
                span.innerHTML = '<i>stuff,</i> bro'

The first part of the result will be a baseline against which to
compare.

                result = []
                result.push div.toJSON()

Then we perform the editing action, and record both it and its
results for testing below.

                div.appendChild span
                action = tracker.stack[tracker.stack.length - 1]
                result.push action.toJSON()
                result.push div.toJSON()

Then we perform an undo of that action, and then record the
results.

                action.undo()
                result.push div.toJSON()

Then we perform a redo of that action, and then record the results.
That's the final data gathering for this test.

                action.redo()
                result.push div.toJSON()
                result
            , ( err, result ) ->

Sanity check to be sure the size of the data is correct.

                expect( result.length ).toEqual 5

Now, is the baseline state of the root div what we expected?
And is the editing action the append child action we expected?
And is the result of that edit the DOM state we expected?
These are checks to be sure the test is doing what we think it is;
this does not test undo/redo functionality.

                expect( result[0] ).toEqual {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                expect( result[1] ).toEqual {
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
                expect( result[2] ).toEqual {
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

Now we check to be sure that the results of the undo action give
the original state of the div back.  We can do this with the
following shortcut.

                expect( result[3] ).toEqual result[0]

Now we check to be sure that the results of the redo action give
the second state of the div back.  We can do this with the
following shortcut.

                expect( result[4] ).toEqual result[2]
                done()

### should work for "insertBefore" actions

We will test this by performing an "insertBefore" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "insertBefore" actions', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                tracker = DOMEditTracker.instanceOver div
                span = document.createElement 'span'
                span.innerHTML = '<i>stuff,</i> bro'

The first part of the result will be a baseline against which to
compare.

                result = []
                result.push div.toJSON()

Then we perform the editing action, and record both it and its
results for testing below.

                div.insertBefore span, div.childNodes[0]
                action = tracker.stack[tracker.stack.length - 1]
                result.push action.toJSON()
                result.push div.toJSON()

Then we perform an undo of that action, and then record the
results.

                action.undo()
                result.push div.toJSON()

Then we perform a redo of that action, and then record the results.
That's the final data gathering for this test.

                action.redo()
                result.push div.toJSON()
                result
            , ( err, result ) ->

Sanity check to be sure the size of the data is correct.

                expect( result.length ).toEqual 5

Now, is the baseline state of the root div what we expected?
And is the editing action the append child action we expected?
And is the result of that edit the DOM state we expected?
These are checks to be sure the test is doing what we think it is;
this does not test undo/redo functionality.

                expect( result[0] ).toEqual {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                expect( result[1] ).toEqual {
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
                expect( result[2] ).toEqual {
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

Now we check to be sure that the results of the undo action give
the original state of the div back.  We can do this with the
following shortcut.

                expect( result[3] ).toEqual result[0]

Now we check to be sure that the results of the redo action give
the second state of the div back.  We can do this with the
following shortcut.

                expect( result[4] ).toEqual result[2]
                done()

### should work for "normalize" actions

We will test this by performing a "normalize" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "normalize" actions', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                tracker = DOMEditTracker.instanceOver div
                div.appendChild document.createTextNode 'one'
                span = document.createElement 'span'
                span.innerHTML = 'one and'
                span.appendChild document.createTextNode ' a half'
                div.appendChild span
                div.appendChild document.createTextNode 'two'

The first part of the result will be a baseline against which to
compare.

                result = []
                result.push div.toJSON()

Then we perform the editing action, and record both it and its
results for testing below.

                div.normalize()
                action = tracker.stack[tracker.stack.length - 1]
                result.push action.toJSON()
                result.push div.toJSON()

Then we perform an undo of that action, and then record the
results.

                action.undo()
                result.push div.toJSON()

Then we perform a redo of that action, and then record the results.
That's the final data gathering for this test.

                action.redo()
                result.push div.toJSON()
                result
            , ( err, result ) ->

Sanity check to be sure the size of the data is correct.

                expect( result.length ).toEqual 5

Now, is the baseline state of the root div what we expected?
And is the editing action the append child action we expected?
And is the result of that edit the DOM state we expected?
These are checks to be sure the test is doing what we think it is;
this does not test undo/redo functionality.

                expect( result[0] ).toEqual {
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
                expect( result[1] ).toEqual {
                    node : [], type : 'normalize',
                    sequences : {
                        '[0]' : [ '\n        ', 'one' ]
                        '[1,0]' : [ 'one and', ' a half' ]
                    }
                }
                expect( result[2] ).toEqual {
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

Now we check to be sure that the results of the undo action give
the original state of the div back.  We can do this with the
following shortcut.

                expect( result[3] ).toEqual result[0]

Now we check to be sure that the results of the redo action give
the second state of the div back.  We can do this with the
following shortcut.

                expect( result[4] ).toEqual result[2]
                done()

### should work for "removeAttribute" actions

We will test this by performing a "removeAttribute" action, then
asking it to be undone, then asking it to be redone, and inspecting
the DOM at each step to ensure it's as expected.

        it 'should work for "removeAttribute" actions', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                tracker = DOMEditTracker.instanceOver div

The first part of the result will be a baseline against which to
compare.

                result = []
                result.push div.toJSON()

Then we perform the editing action, and record both it and its
results for testing below.

                div.removeAttribute 'id'
                action = tracker.stack[tracker.stack.length - 1]
                result.push action.toJSON()
                result.push div.toJSON()

Then we perform an undo of that action, and then record the
results.

                action.undo()
                result.push div.toJSON()

Then we perform a redo of that action, and then record the results.
That's the final data gathering for this test.

                action.redo()
                result.push div.toJSON()
                result
            , ( err, result ) ->

Sanity check to be sure the size of the data is correct.

                expect( result.length ).toEqual 5

Now, is the baseline state of the root div what we expected?
And is the editing action the append child action we expected?
And is the result of that edit the DOM state we expected?
These are checks to be sure the test is doing what we think it is;
this does not test undo/redo functionality.

                expect( result[0] ).toEqual {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                expect( result[1] ).toEqual {
                    node : [], type : 'removeAttribute',
                    name : 'id', value : '0'
                }
                expect( result[2] ).toEqual {
                    tagName : 'DIV'
                    children : [ '\n        ' ]
                }

Now we check to be sure that the results of the undo action give
the original state of the div back.  We can do this with the
following shortcut.

                expect( result[3] ).toEqual result[0]

Now we check to be sure that the results of the redo action give
the second state of the div back.  We can do this with the
following shortcut.

                expect( result[4] ).toEqual result[2]
                done()

### should work for "removeAttributeNode" actions

We will test this by performing a "removeAttributeNode" action,
then asking it to be undone, then asking it to be redone, and
inspecting the DOM at each step to ensure it's as expected.

        it 'should work for "removeAttributeNode" actions',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                tracker = DOMEditTracker.instanceOver div

The first part of the result will be a baseline against which to
compare.

                result = []
                result.push div.toJSON()

Then we perform the editing action, and record both it and its
results for testing below.

                div.removeAttributeNode div.getAttributeNode 'id'
                action = tracker.stack[tracker.stack.length - 1]
                result.push action.toJSON()
                result.push div.toJSON()

Then we perform an undo of that action, and then record the
results.

                action.undo()
                result.push div.toJSON()

Then we perform a redo of that action, and then record the results.
That's the final data gathering for this test.

                action.redo()
                result.push div.toJSON()
                result
            , ( err, result ) ->

Sanity check to be sure the size of the data is correct.

                expect( result.length ).toEqual 5

Now, is the baseline state of the root div what we expected?
And is the editing action the append child action we expected?
And is the result of that edit the DOM state we expected?
These are checks to be sure the test is doing what we think it is;
this does not test undo/redo functionality.

                expect( result[0] ).toEqual {
                    tagName : 'DIV'
                    attributes : id : '0'
                    children : [ '\n        ' ]
                }
                expect( result[1] ).toEqual {
                    node : [], type : 'removeAttributeNode',
                    name : 'id', value : '0'
                }
                expect( result[2] ).toEqual {
                    tagName : 'DIV'
                    children : [ '\n        ' ]
                }

Now we check to be sure that the results of the undo action give
the original state of the div back.  We can do this with the
following shortcut.

                expect( result[3] ).toEqual result[0]

Now we check to be sure that the results of the redo action give
the second state of the div back.  We can do this with the
following shortcut.

                expect( result[4] ).toEqual result[2]
                done()

