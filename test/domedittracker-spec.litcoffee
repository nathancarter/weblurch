
# Tests for the `DOMEditTracker` class

This file contains the specifications for tests of the
`DOMEditTracker` class.  One of its aspects is that it manages an
undo/redo stack.  Testing of foundational undo/redo functionality
of `DOMEditActions` cannot, however, be found in this file; for
that, see [a different test suite](undoredo-spec.litcoffee.html).

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe, pageExpects, pageExpectsError,
      inPage, pageDo } = require './phantom-utils'

## DOMEditTracker class

    phantomDescribe 'DOMEditTracker class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', inPage ->
            pageExpects -> DOMEditTracker

### should track instances

Each instance of the class created should be placed in an array
stored in the class variable `@instances`.

        it 'should track instances', inPage ->

First of all, the page itself instantiates an edit tracker upon
loading, one surrounding a child of the document body.  So we first
check that there is an instance already, and its element has the
desired id.

            pageExpects ( ->
                DOMEditTracker.instances.length ), 'toEqual', 1
            pageExpects ->
                DOMEditTracker.instances[0] \
                    .getElement().parentNode is document.body

Create an edit tracker and check to be sure the instances array
has length 2 and contains the new instance.

            pageDo -> window.T1 = new DOMEditTracker
            pageExpects ( -> DOMEditTracker.instances.length ),
                'toEqual', 2
            pageExpects -> DOMEditTracker.instances[1] is T1

Create another, this one around an element outside the document,
and check to be sure the instances array has length 3 and contains
the two new instances in the appropriate order.

            pageDo ->
                div = document.createElement 'div'
                window.T2 = new DOMEditTracker div
            pageExpects ( -> DOMEditTracker.instances.length ),
                'toEqual', 3
            pageExpects -> DOMEditTracker.instances[2] is T2

### should find the correct containers

There will already be one `DOMEditTracker` instance in place,
instantiated by the index page itself.  It is over the first div in
the document.

This test creates a second div in the document and places another
`DOMEditTracker` instance over it, then checks to be sure that
each of the two instances that have elements can be found as the
instances in charge of those elements and their descendants.
It also tests the same for an instance whose element is outside
the document.

        it 'should find the correct containers', inPage ->

Here is the new div to add to the document, with some inner
elements and a `DOMEditTracker` instance around it.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = '''
                    <div>just some tags in a hierarchy
                    <span>for testing purposes</span></div>
                    '''
                window.ielt = document.createElement 'i'
                ielt.textContent = 'dummy'
                div.appendChild ielt
                window.another = new DOMEditTracker div

First, is the original `DOMEditTracker` instance in charge of the
first div in the document?

            pageExpects ->
                firstDiv = document.body
                    .getElementsByTagName( 'div' )[0]
                DOMEditTracker.instances[0] is
                    DOMEditTracker.instanceOver firstDiv

Second, is the new `DOMEditTracker` instance in charge of the div
created above?  And of one of its child nodes?  And one of its
grandchild nodes?

            pageExpects -> another is
                DOMEditTracker.instanceOver div
            pageExpects -> another is
                DOMEditTracker.instanceOver ielt
            pageExpects -> another is
                DOMEditTracker.instanceOver ielt.childNodes[0]

Now create an instance around a div outside the document, and do
similar tests on it.

            pageDo ->
                window.outside = document.createElement 'div'
                window.child = document.createElement 'p'
                outside.appendChild child
                window.grandchild = document.createElement 'b'
                grandchild.textContent = 'waah'
                child.appendChild grandchild
                window.final = new DOMEditTracker outside
            pageExpects ->
                final is DOMEditTracker.instanceOver outside
            pageExpects ->
                final is DOMEditTracker.instanceOver child
            pageExpects ->
                final is DOMEditTracker.instanceOver grandchild
            pageExpects -> final is DOMEditTracker.instanceOver \
                grandchild.childNodes[0]

## DOMEditTracker instances without DIVs

    phantomDescribe 'DOMEditTracker instances without DIVs',
    './app/index.html', ->

### should return a null element

An instance of the `DOMEditTracker` class created without a div
should return null from its `getElement` method.

        it 'should return a null element', inPage ->
            pageExpects ( ->
                D = new DOMEditTracker()
                D.getElement()
            ), 'toBeNull'

## DOMEditTracker instances with DIVs

We now test constructing a new `DOMEditTracker` instance around an
existing DOM element, and verify that it does the correct things
with ids.  See the documentation in
[the Lurch Editor class itself](lurcheditor.litcoffee.html) for
details on what the constructor is expected to do in these
situations, or read each test description below.

    phantomDescribe 'DOMEditTracker instances with DIVs',
    './app/index.html', ->

### should return the correct div

        it 'should return the correct div', inPage ->

An instance of the `LurchEditor` class created without a div should
return null from its `getElement` method.  Here we construct the
`DOMEditTracker` instance around the div, as before.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div
            pageExpects -> div is D.getElement()

## The undo/redo stack

The tests in this section concern all functions related to the
undo/redo stack maintained by a `DOMEditTracker` instance.
See the documentation in [the DOMEditTracker source code](
domedittracker.litcoffee.html#undo-redo-stack) for information
about each function to be tested below, or just read the tests
themselves.

    phantomDescribe 'The undo/redo stack', './app/index.html', ->

### should grow when nodeEditHappened

        it 'should grow when nodeEditHappened', inPage ->

When we call `nodeEditHappened` in the `DOMEditTracker` instance,
we require the undo/redo stack to grow, and the stack pointer to
continue to be equal to the size of the stack.

Create the objects needed to run the test.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.span1 = document.createElement 'span'
                window.span2 = document.createElement 'span'
                window.span3 = document.createElement 'span'
                window.D = new DOMEditTracker div

Verify that the inital values of the stack length and stack pointer
are both zero.

            pageExpects ( -> D.stack.length ), 'toEqual', 0
            pageExpects ( -> D.stackPointer ), 'toEqual', 0

Create three editing actions and add them to the stack, verifying
that the stack size and pointer increase with each addition.

            pageDo -> D.nodeEditHappened \
                new DOMEditAction 'appendChild', div, span1
            pageExpects ( -> D.stack.length ), 'toEqual', 1
            pageExpects ( -> D.stackPointer ), 'toEqual', 1
            pageDo -> D.nodeEditHappened \
                new DOMEditAction 'appendChild', div, span2
            pageExpects ( -> D.stack.length ), 'toEqual', 2
            pageExpects ( -> D.stackPointer ), 'toEqual', 2
            pageDo -> D.nodeEditHappened \
                new DOMEditAction 'appendChild', div, span3
            pageExpects ( -> D.stack.length ), 'toEqual', 3
            pageExpects ( -> D.stackPointer ), 'toEqual', 3

Now try to add two invalid actions, and verify that neither the
stack size nor stack pointer changes.

            pageDo -> D.nodeEditHappened null
            pageExpects ( -> D.stack.length ), 'toEqual', 3
            pageExpects ( -> D.stackPointer ), 'toEqual', 3
            pageDo -> D.nodeEditHappened 'not an edit action'
            pageExpects ( -> D.stack.length ), 'toEqual', 3
            pageExpects ( -> D.stackPointer ), 'toEqual', 3

### should truncate if needed

        it 'should truncate if needed', inPage ->

When we call `nodeEditHappened` in the `DOMEditTracker` instance,
if the stack pointer is *not* at the end of the stack, then the
stack should be truncated to make the stack pointer equal to the
stack size before appending the new edit actions.

Create the objects needed to run the test.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div

Set up the stack with three actions in it, and add to a results
array the size of the stack and value of the pointer, to verify
that all three were added successfully.  Also record the type of
the most recent action on the stack.

                D.nodeEditHappened new DOMEditAction \
                    'setAttribute', div, 'key', 'value'
                D.nodeEditHappened new DOMEditAction \
                    'setAttribute', div, 'key2', 'value2'
                span = document.createElement 'span'
                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span

Now we expect to find that there are three edits on the stack, and
that the final one is the "appendChild" action just performed.

            pageExpects ( -> D.stack.length ), 'toEqual', 3
            pageExpects ( -> D.stackPointer ), 'toEqual', 3
            pageExpects ( -> D.stack[D.stack.length - 1].type),
                'toEqual', 'appendChild'

Push the stack pointer back by one, then record a new action, which
should cause the edit tracker to remove the old third action from
the stack before recording the new action.

            pageDo ->
                D.stackPointer--
                D.nodeEditHappened new DOMEditAction 'normalize',
                    div

Verify that the stack has not grown, but that the new most recent
action is of the new type.

            pageExpects ( -> D.stack.length ), 'toEqual', 3
            pageExpects ( -> D.stackPointer ), 'toEqual', 3
            pageExpects ( -> D.stack[D.stack.length - 1].type ),
                'toEqual', 'normalize'

### handles canUndo/canRedo correctly

        it 'handles canUndo/canRedo correctly', inPage ->

The `canUndo` and `canRedo` member functions of a `DOMEditTracker`
instance should return true if and only if the stack pointer is at
a location that permits undo/redo, respectively.  In particular,
one can call undo if and only if the stack pointer is not at the
bottom (zero) and can call redo if and only if it is not at the end
(the stack size).  This test verifies this if-and-only-ifs.

Create the objects needed to run the test.

            pageDo ->
                div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div

Set up the stack with three actions in it.

                D.nodeEditHappened new DOMEditAction \
                    'setAttribute', div, 'key', 'value'
                D.nodeEditHappened new DOMEditAction \
                    'setAttribute', div, 'key2', 'value2'
                span = document.createElement 'span'
                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span

Verify that the stack pointer is at the end, and that we cannot
"redo" from there, but we can "undo."

            pageExpects ( -> D.stackPointer ), 'toEqual', 3
            pageExpects ( -> D.canRedo() ), 'toEqual', no
            pageExpects ( -> D.canUndo() ), 'toEqual', yes

Move the stack pointer down the stack, and verify that at each of
its next two locations, both undo and redo are available.

            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 2
            pageExpects ( -> D.canRedo() ), 'toEqual', yes
            pageExpects ( -> D.canUndo() ), 'toEqual', yes
            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 1
            pageExpects ( -> D.canRedo() ), 'toEqual', yes
            pageExpects ( -> D.canUndo() ), 'toEqual', yes

Move the stack pointer down one more step, which should be to the
bottom, and verify that we can redo but cannot undo.

            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 0
            pageExpects ( -> D.canRedo() ), 'toEqual', yes
            pageExpects ( -> D.canUndo() ), 'toEqual', no

### gives good undo/redo descriptions

        it 'gives good undo/redo descriptions', inPage ->

The `undoDescription` and `redoDescription` member functions of a
`DOMEditTracker` instance should return descriptions of the actions
that would be taken if undo/redo were called (respectively).  This
test verifies, for various locations of the stack pointer in a
stack of three different types of actions, that the undo and redo
descriptiosn are as they should be.

Create the objects needed to run the test.

            pageDo ->
                div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div
                span = document.createElement 'span'

Set up the stack with three actions in it.

                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span
                D.nodeEditHappened new DOMEditAction \
                    'setAttribute', div, 'key', 'value'
                D.nodeEditHappened new DOMEditAction 'normalize',
                    div

Check the initial values of the stack pointer and undo/redo
descriptions.

            pageExpects ( -> D.stackPointer ), 'toEqual', 3
            pageExpects ( -> D.undoDescription() ),
                'toEqual', 'Undo Normalize text'
            pageExpects ( -> D.redoDescription() ), 'toEqual', ''

Move the stack pointer down the stack three times (which should put
it at the bottom) and at each position, check the same data as
above.

            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 2
            pageExpects ( -> D.undoDescription() ),
                'toEqual', 'Undo Change key from empty to value'
            pageExpects ( -> D.redoDescription() ),
                'toEqual', 'Redo Normalize text'
            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 1
            pageExpects ( -> D.undoDescription() ),
                'toEqual', 'Undo Add a node'
            pageExpects ( -> D.redoDescription() ),
                'toEqual', 'Redo Change key from empty to value'
            pageDo -> D.stackPointer--
            pageExpects ( -> D.stackPointer ), 'toEqual', 0
            pageExpects ( -> D.undoDescription() ), 'toEqual', ''
            pageExpects ( -> D.redoDescription() ),
                'toEqual', 'Redo Add a node'

### performs undo/redo in the correct order

        it 'performs undo/redo in the correct order', inPage ->

Although undo/redo are already tested for individual actions in
[the tests for the `DOMEditAction` class](
domeditaction-spec.litcoffee.html), we must still test that this
class manages the stack correctly, so that we can call the `undo`
and `redo` member functions of a `DOMEditTracker` instance
repeatedly and expect them to behave correctly in sequence.

            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div

We expect the div to go through the following four states, so we
create an array of them here.  This will be handy as we repeatedly
undo/redo various actions, and can just compare the state of the
div to various values in this array, using each more than once.

            stateHistory = [

The initial state, an empty div:

                tagName : 'DIV'

The state after we append a span containing "some text":

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [ 'some text' ]
                        }
                    ]
                }

The state after we append another text node to the same span:

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [ 'some text',
                                        'other text' ]
                        }
                    ]
                }

The state after we normalize, to unite the two adjacent text node
siblings into one:

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [ 'some textother text' ]
                        }
                    ]
                }
            ]

Verify that the current state of the div is empty.  Then store it
for later comparison after undo operations.

            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[0]

Perform three actions, checking the state of the same div after
each one, to be sure we get descriptions of adding a span with some
text in it, adding more text, and normalizing to unite the texts.

            pageDo ->
                window.span = document.createElement 'span'
                span.textContent = 'some text'
                div.appendChild span
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[1]
            pageDo ->
                text = document.createTextNode 'other text'
                span.appendChild text
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[2]
            pageDo -> div.normalize()
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[3]

Undo all three actions, checking the state of the same div after
each call to `undo`.  We ask it to call `undo` four times, just to
be sure that the fourth one has no effect.  We also check the
stack pointer after each undo, to be sure it's being decremented.

            for index in [2,1,0,0]
                pageDo -> D.undo()
                pageExpects ( -> D.stackPointer ),
                    'toEqual', index
                pageExpects ( -> div.toJSON() ),
                    'toEqual', stateHistory[index]

Redo all three actions, checking the state of the same div after
each call to `redo`.  We ask it to call `redo` four times, just to
be sure that the fourth one has no effect.  We also check the
stack pointer after each redo, to be sure it's being incremented.

            for index in [1,2,3,3]
                pageDo -> D.redo()
                pageExpects ( -> D.stackPointer ),
                    'toEqual', index
                pageExpects ( -> div.toJSON() ),
                    'toEqual', stateHistory[index]

### supports edit blocks

A sequence of successive edit actions can be treated as a block,
and thus grouped into a single, compound edit action on the
undo/redo stack.  Here we test this feature.

        it 'supports edit blocks', inPage ->
            pageDo ->
                window.div = document.createElement 'div'
                document.body.appendChild div
                window.D = new DOMEditTracker div
            
We expect the div to go through the following four states, so we
create an array of them here.  This will be handy as we repeatedly
undo/redo various actions, and can just compare the state of the
div to various values in this array, using each more than once.

            stateHistory = [

The initial state, with the div empty.

                tagName : 'DIV'

The first action we do will be to append a small span.

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [ 'small' ]
                        }
                    ]
                }

Next will be a compound action, walking the div through the
following three states.  It will do so by appending a second
child, removing the first child, then changing an attribute.

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'SPAN'
                            children : [ 'small' ]
                        }
                        tagName : 'HR'
                    ]
                }
                {
                    tagName : 'DIV'
                    children : [ tagName : 'HR' ]
                }
                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'HR'
                            attributes : 'ex' : 'ample'
                        }
                    ]
                }

Finally we will also do another action after the compound action,
inserting a new first child, thus placing the div in the following
final state.

                {
                    tagName : 'DIV'
                    children : [
                        {
                            tagName : 'P'
                            children : [ 'Lorem ipsum...' ]
                        }
                        {
                            tagName : 'HR'
                            attributes : 'ex' : 'ample'
                        }
                    ]
                }
            ]

First, verify that the div begins in the expected initial state,
and that the undo/redo stack is empty.

            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[0]
            pageExpects ( -> D.stack.length ), 'toEqual', 0

Next, perform the first action, which is *not* part of the sequence
that will be collected into a compound action.  Verify that the
result is as expected from the state history defined above, and
that the undo/redo stack has grown to size 1.

            pageDo ->
                span = document.createElement 'span'
                span.textContent = 'small'
                div.appendChild span
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[1]
            pageExpects ( -> D.stack.length ), 'toEqual', 1

Now begin an edit block in the edit tracker; this is the key aspect
of the edit tracker on which this test focuses.

            pageDo -> D.startCompoundAction 'My example action'

Now perform each of the three actions that will join to form the
compound action, verifying that although the state changes as we
do them, the undo/redo stack does not (yet) grow.

            pageDo -> div.appendChild document.createElement 'hr'
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[2]
            pageExpects ( -> D.stack.length ), 'toEqual', 1
            pageDo -> div.removeChild div.childNodes[0]
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[3]
            pageExpects ( -> D.stack.length ), 'toEqual', 1
            pageDo -> div.childNodes[0].setAttribute 'ex', 'ample'
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[4]
            pageExpects ( -> D.stack.length ), 'toEqual', 1

End the edit block in the edit tracker.  Verify that the document
state does not change, but the undo/redo stack finally grows by 1.

            pageDo -> D.endCompoundAction()
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[4]
            pageExpects ( -> D.stack.length ), 'toEqual', 2

Finally, perform the final action, also *not* part of the sequence
just recorded as a compound action.  Verify that the result is as
expected from the state history defined above, and that the
undo/redo stack has grown to size 3.

            pageDo ->
                p = document.createElement 'p'
                p.textContent = 'Lorem ipsum...'
                div.insertBefore p, div.childNodes[0]
            pageExpects ( -> div.toJSON() ),
                'toEqual', stateHistory[5]
            pageExpects ( -> D.stack.length ), 'toEqual', 3

Undo all three actions, checking the state of the same div after
each call to `undo`.  We ask it to call `undo` four times, just to
be sure that the fourth one has no effect.  

            for index in [4,1,0,0]
                pageDo -> D.undo()
                pageExpects ( -> div.toJSON() ),
                    'toEqual', stateHistory[index]

Redo all three actions, checking the state of the same div after
each call to `redo`.  We ask it to call `redo` four times, just to
be sure that the fourth one has no effect.

            for index in [1,4,5,5]
                pageDo -> D.redo()
                pageExpects ( -> div.toJSON() ),
                    'toEqual', stateHistory[index]

