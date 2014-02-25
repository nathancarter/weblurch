
# Tests of DOM utilities module

Pull in the utility functions in `phantom-utils` that make it
easier to write the tests below.

    { phantomDescribe } = require './phantom-utils'

## address function

    phantomDescribe 'address function', './app/index.html', ->

### should be defined

        it 'should be defined', ( done ) =>
            @page.evaluate ( -> address ), ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should give null on corner cases

        it 'should give null on corner cases', ( done ) =>

The corner cases to be tested here are these:
 * The address of a DOM node within one of its children.
 * The address of a DOM node within one of its siblings.
Although there are others we could test, these are enough for now.

            @page.evaluate ->
                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
                [
                    address( pardiv, chidiv1 ) is null
                    address( pardiv, chidiv2 ) is null
                    address( chidiv1, chidiv2 ) is null
                    address( chidiv2, chidiv1 ) is null
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toBeTruthy()
                expect( result[2] ).toBeTruthy()
                expect( result[3] ).toBeTruthy()
                done()

### should be empty for N,N

        it 'should be empty for N,N', ( done ) =>

We will test a few cases of `N,N` for various `N`.

            @page.evaluate ->
                pardiv = document.createElement 'div'
                document.body.appendChild pardiv
                chidiv1 = document.createElement 'div'
                pardiv.appendChild chidiv1
                chidiv2 = document.createElement 'div'
                pardiv.appendChild chidiv2
                [
                    address( pardiv, pardiv )
                    address( chidiv1, chidiv1 )
                    address( chidiv2, chidiv2 )
                    address( document, document )
                    address( document.body, document.body )
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ ]
                expect( result[1] ).toEqual [ ]
                expect( result[2] ).toEqual [ ]
                expect( result[3] ).toEqual [ ]
                expect( result[4] ).toEqual [ ]
                done()

### should be empty for top-level,null

        it 'should be empty for top-level,null', ( done ) =>

The simplest way to test this is to compute the address of the
document, and expect it to be the empty array.  But we also have
the document create an empty div and not put it inside any other
node, and we expect that its address will also be the empty array.

            @page.evaluate ->
                [
                    address document
                    address document.createElement 'div'
                ]
            , ( err, result ) ->
                expect( result[0] ).toEqual [ ]
                expect( result[1] ).toEqual [ ]
                done()

### should be length-1 for a child

This test is not yet written.

### should work for grandchildren, etc.

This test is not yet written.

### should throw errors on non-nodes

This test is not yet written.
(Use the `expect( ... ).toThrow()` facility in `jasmine`.)

