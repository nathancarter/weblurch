
# Basic tests of compiled app code

*This file does not have any comments in it right now, but it
should.  Other test files say that readers should refer to this one
if they need to understand the basic structure of a test spec file,
but this one has no helpful comments.  That is a TO-DO that is
still pending; see the end of [the project plan](plan.md.html).*

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## app/index.html page

    phantomDescribe 'app/index.html page', './app/index.html', ->

### should load

        it 'should load', ( done ) =>
            expect( @page.loaded ).toBeTruthy()
            done()

### should find all its resources

        it 'should find all its resources', ( done ) =>
            expect( @page.reserr ).toBeFalsy()
            done()

### should load without errors

        it 'should load without errors', ( done ) =>
            expect( @page.err ).toBeFalsy()
            done()

### should have global variables defined

        it 'should have global variables defined', ( done ) =>
            @page.evaluate ->
                {
                    address : Node::address
                    lurchEditor : LurchEditor
                }
            , ( err, result ) ->
                expect( result.address ).toBeTruthy()
                expect( result.lurchEditor ).toBeTruthy()
                done()

### should initialize main div to id 0

Note that this assumes that the main div has been assigned to the
global variable `LE`, which is a rather arbitrary choice in the
[app](../app/index.html) and [testapp](../testapp/index.html) code.

        it 'should initialize main div to id 0', ( done ) =>
            @page.evaluate ( -> LE.getElement().id ),
            ( err, result ) ->
                expect( result ).toEqual '0'
                done()

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

## testapp/index.html page

    phantomDescribe 'testapp/index.html page', \
    './testapp/index.html', ->

### should load

        it 'should load', ( done ) =>
            expect( @page.loaded ).toBeTruthy()
            done()

### should find all its resources

        it 'should find all its resources', ( done ) =>
            expect( @page.reserr ).toBeFalsy()
            done()

### should load without errors

        it 'should load without errors', ( done ) =>
            expect( @page.err ).toBeFalsy()
            done()

### should have global variables defined

        it 'should have global variables defined', ( done ) =>
            @page.evaluate ->
                {
                    address : Node::address
                    lurchEditor : LurchEditor
                    maindiv : maindiv instanceof HTMLElement
                }
            , ( err, result ) ->
                expect( result.address ).toBeTruthy()
                expect( result.lurchEditor ).toBeTruthy()
                expect( result.maindiv ).toBeTruthy()
                done()

### should initialize main div to id 0

        it 'should initialize main div to id 0', ( done ) =>
            @page.evaluate ( -> LE.getElement().id ),
            ( err, result ) ->
                expect( result ).toEqual '0'
                done()

Later we will also add tests that use `page.get 'content'`,
`page.render 'outfile.png'`, etc.

