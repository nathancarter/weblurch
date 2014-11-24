
# Tests of the utils module

Test specifications still need to be documented.

    require '../src/utils'

## JSON.equals

This section tests the equality function for JSON objects, called
`JSON.equals`.

    describe 'JSON.equals', ->

### should call equal atomic values equal

        it 'should call equal atomic values equal', ->
            expect( JSON.equals 3, 3 ).toBeTruthy()
            expect( JSON.equals '3', '3' ).toBeTruthy()
            expect( JSON.equals 'three', 'three' ).toBeTruthy()
            expect( JSON.equals null, null ).toBeTruthy()
            expect( JSON.equals undefined, undefined ).toBeTruthy()

### should call unequal atomic values unequal

        it 'should call unequal atomic values unequal', ->
            expect( JSON.equals 3, 4 ).toBeFalsy()
            expect( JSON.equals '3', '03' ).toBeFalsy()
            expect( JSON.equals 'three', 'tree' ).toBeFalsy()
            expect( JSON.equals null, undefined ).toBeFalsy()
            expect( JSON.equals undefined, 0 ).toBeFalsy()
            expect( JSON.equals null, 0 ).toBeFalsy()

### should distinguish atomics from non-atomics

        it 'should distinguish atomics from non-atomics', ->
            expect( JSON.equals 3, {} ).toBeFalsy()
            expect( JSON.equals '3', {} ).toBeFalsy()
            expect( JSON.equals 'three', JSON ).toBeFalsy()
            expect( JSON.equals null, (->) ).toBeFalsy()
            expect( JSON.equals undefined, {a:3} ).toBeFalsy()

### should call equal-structure objects equal

This includes not only objects but also arrays, and nestings of the two,
where key order is irrelevant.

        it 'should call equal-structure objects equal', ->

Objects with depth 1:

            expect JSON.equals
                thing : 'foo'
                other : 169
            ,
                other : 169
                thing : 'foo'
            .toBeTruthy()

Arrays with depth 1:

            expect( JSON.equals [ 7, 'eight', 9999 ],
                [ 7, 'eight', 9999 ] ).toBeTruthy()

Mixed objects and arrays, with depth greater than 1:

            expect JSON.equals
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
                list : [
                    { }
                    { }
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
            ,
                list : [
                    { }
                    { }
                    { beverly : 'cleary', henry : 'huggins' }
                    50
                ]
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
            .toBeTruthy()
            expect( JSON.equals [ { }, JSON, { a:1, b:2, c:3 } ],
                [ { }, JSON, { b:2, a:1, c:3 } ] ).toBeTruthy()

### should call unequal-structure objects unequal

This includes not only objects but also arrays, and nestings of the two,
where key order is irrelevant.  So in these tests, I will keep key order the
same, and yet the objects should still differ.

        it 'should call unequal-structure objects unequal', ->

Objects with depth 1:

            expect JSON.equals
                thing : 'foo'
                other : 169
            ,
                thing : 'foo'
                other : 168
            .toBeFalsy()
            expect JSON.equals
                thing : 'foo'
                other : 169
            ,
                thing : 'foo'
            .toBeFalsy()
            expect JSON.equals
                thing : 'foo'
            ,
                other : 169
                thing : 'foo'
            .toBeFalsy()

Arrays with depth 1:

            expect( JSON.equals [ 7, 8, 9999 ],
                [ 7, 'eight', 9999 ] ).toBeFalsy()
            expect( JSON.equals [ 7, 8, 9999 ], [ 7, 9999, 8 ] \
                ).toBeFalsy()

Mixed objects and arrays, with depth greater than 1:

            expect JSON.equals
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
                list : [
                    { }
                    { }
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
            ,
                thing : [ 1, 2, 3, 4 ]
                other : { foo : [] }
                list : [
                    { }
                    { }
                    { beverly : 'cleary', henry : 'huggins' }
                    50
                ]
            .toBeFalsy()
            expect JSON.equals
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
                list : [
                    { }
                    [ ]
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
            ,
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
                list : [
                    { }
                    { }
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
            .toBeFalsy()
            expect JSON.equals
                thing : [ 1, 2, 3 ]
                other : { foo : [] }
                list : [
                    { }
                    { }
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
            ,
                list : [
                    { }
                    { }
                    { henry : 'huggins', beverly : 'cleary' }
                    50
                ]
                thing : [ 1, 2, 3 ]
            .toBeFalsy()
            expect( JSON.equals [ { }, JSON, { a:1, b:2, c:3 } ],
                [ { }, JSON, { a:1, b:2, c:3, JSON } ]
                ).toBeFalsy()
