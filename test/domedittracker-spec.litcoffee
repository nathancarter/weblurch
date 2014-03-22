
# Tests for the `DOMEditTracker` class

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe } = require './phantom-utils'

## DOMEditTracker class

    phantomDescribe 'LurchEditor class', './app/index.html', ->

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

