
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

