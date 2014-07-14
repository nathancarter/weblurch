
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

    { phantomDescribe } = require './phantom-utils'

## DOMEditTracker class

    phantomDescribe 'DOMEditTracker class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', ( done ) =>
            @page.evaluate ( -> DOMEditTracker ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should track instances

Each instance of the class created should be placed in an array
stored in the class variable `@instances`.

        it 'should track instances', ( done ) =>
            @page.evaluate ->

I will do several tests and put all their results in the following
array, for checking below.

                result = []

First of all, the page itself instantiates an edit tracker upon
loading, one surrounding a child of the document body.  So we first
check that there is an instance already, and its element has the
desired id.

                result.push DOMEditTracker.instances.length
                result.push DOMEditTracker.instances[0] \
                    .getElement().parentNode is document.body

Create an edit tracker and check to be sure the instances array
has length 2 and contains the new instance.

                T1 = new DOMEditTracker
                result.push DOMEditTracker.instances.length
                result.push DOMEditTracker.instances[1] is T1

Create another, this one around an element outside the document,
and check to be sure the instances array has length 3 and contains
the two new instances in the appropriate order.

                div = document.createElement 'div'
                T2 = new DOMEditTracker div
                result.push DOMEditTracker.instances.length
                result.push DOMEditTracker.instances[1] is T1
                result.push DOMEditTracker.instances[2] is T2

Send these results back to be verified.

                result
            , ( err, result ) ->
                expect( result[0] ).toEqual 1
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toEqual 2
                expect( result[3] ).toBeTruthy()
                expect( result[4] ).toEqual 3
                expect( result[5] ).toBeTruthy()
                expect( result[6] ).toBeTruthy()
                done()

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

        it 'should find the correct containers', ( done ) =>
            @page.evaluate ->

Here is the new div to add to the document, with some inner
elements and a `DOMEditTracker` instance around it.

                div = document.createElement 'div'
                document.body.appendChild div
                div.innerHTML = '''
                    <div>just some tags in a hierarchy
                    <span>for testing purposes</span></div>
                    '''
                ielt = document.createElement 'i'
                ielt.textContent = 'dummy'
                div.appendChild ielt
                another = new DOMEditTracker div

Now we do the tests, all of which should come out true.  We check
in the callback function below that they do so.

First, is the original `DOMEditTracker` instance in charge of the
first div in the document?

                result = []
                firstDiv = document.body
                    .getElementsByTagName( 'div' )[0]
                result.push DOMEditTracker.instances[0] is
                    DOMEditTracker.instanceOver firstDiv

Second, is the new `DOMEditTracker` instance in charge of the div
created above?  And of one of its child nodes?  And one of its
grandchild nodes?

                result.push another is
                    DOMEditTracker.instanceOver div
                result.push another is
                    DOMEditTracker.instanceOver ielt
                result.push another is
                    DOMEditTracker.instanceOver ielt.childNodes[0]

Now create an instance around a div outside the document, and do
similar tests on it.

                outside = document.createElement 'div'
                child = document.createElement 'p'
                outside.appendChild child
                grandchild = document.createElement 'b'
                grandchild.textContent = 'waah'
                child.appendChild grandchild
                final = new DOMEditTracker outside
                result.push final is
                    DOMEditTracker.instanceOver outside
                result.push final is
                    DOMEditTracker.instanceOver child
                result.push final is
                    DOMEditTracker.instanceOver grandchild
                result.push final is
                    DOMEditTracker.instanceOver \
                    grandchild.childNodes[0]
                result
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeTruthy()
                expect( result[4] ).toBeTruthy()
                expect( result[5] ).toBeTruthy()
                expect( result[6] ).toBeTruthy()
                expect( result[7] ).toBeTruthy()
                done()

## DOMEditTracker instances without DIVs

    phantomDescribe 'DOMEditTracker instances without DIVs',
    './app/index.html', ->

### should return a null element

An instance of the `DOMEditTracker` class created without a div
should return null from its `getElement` method.

        it 'should return a null element', ( done ) =>
            @page.evaluate ->
                D = new DOMEditTracker()
                D.getElement()
            , ( err, result ) ->
                expect( result ).toBeNull()
                done()

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

        it 'should return the correct div', ( done ) =>

An instance of the `LurchEditor` class created without a div should
return null from its `getElement` method.

            @page.evaluate ->
                div = document.createElement 'div'
                document.body.appendChild div

Construct the `DOMEditTracker` instance around the div, as before.

                D = new DOMEditTracker div
                div is D.getElement()
            , ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

## The undo/redo stack

The tests in this section concern all functions related to the
undo/redo stack maintained by a `DOMEditTracker` instance.
See the documentation in [the DOMEditTracker source code](
domedittracker.litcoffee.html#undo-redo-stack) for information
about each function to be tested below, or just read the tests
themselves.

    phantomDescribe 'The undo/redo stack', './app/index.html', ->

### should grow when nodeEditHappened

        it 'should grow when nodeEditHappened', ( done ) =>

When we call `nodeEditHappened` in the `DOMEditTracker` instance,
we require the undo/redo stack to grow, and the stack pointer to
continue to be equal to the size of the stack.

            @page.evaluate ->

Create the objects needed to run the test.

                div = document.createElement 'div'
                document.body.appendChild div
                span1 = document.createElement 'span'
                span2 = document.createElement 'span'
                span3 = document.createElement 'span'
                D = new DOMEditTracker div

Build a result array that will record the stack length and stack
pointer value at various steps throughout the test.  Add the
initial values of those data.

                result = []
                result.push D.stack.length
                result.push D.stackPointer

Create a few editing actions and add them to the stack, recording
the new stack size and pointer value each time.

                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span1
                result.push D.stack.length
                result.push D.stackPointer
                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span2
                result.push D.stack.length
                result.push D.stackPointer
                D.nodeEditHappened new DOMEditAction 'appendChild',
                    div, span3
                result.push D.stack.length
                result.push D.stackPointer

Now try to add two invalid actions, so that we can test that
nothing happens.

                D.nodeEditHappened null
                result.push D.stack.length
                result.push D.stackPointer
                D.nodeEditHappened 'not an edit action'
                result.push D.stack.length
                result.push D.stackPointer
                result
            , ( err, result ) ->
                expect( result ).toEqual \
                    [ 0, 0, 1, 1, 2, 2, 3, 3, 3, 3, 3, 3 ]
                done()

