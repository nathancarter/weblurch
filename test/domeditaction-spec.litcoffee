
# Tests for the `DOMEditAction` class

Those aspects of the `DOMEditAction` class that relate to undoing
and redoing edit actions can be found in [a different test suite](
undoredo-spec.litcoffee.html).  This file tests the remainder of
the class's functionality.

Pull in the utility functions in
[phantom-utils](phantom-utils.litcoffee.html) that make it
easier to write the tests below.  Then follow the same structure
for setting up tests as documented more thoroughly in
[the basic unit test](basic-spec.litcoffee.html).

    { phantomDescribe } = require './phantom-utils'

## DOMEditAction class

    phantomDescribe 'DOMEditAction class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', ( done ) =>
            @page.evaluate ( -> DOMEditAction ),
            ( err, result ) ->
                expect( result ).toBeTruthy()
                done()

### should have "appendChild" instances

That is, we should be able to construct instances of the class with
the type "appendChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `toAppend` member that stores the child to be
appended.

        it 'should have "appendChild" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                T = new DOMEditAction 'appendChild', div, span
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.toAppend
                    T.type
                ]
                result
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual tagName : 'SPAN'
                expect( result[3] ).toEqual 'appendChild'
                done()

### should correctly describe "appendChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "appendChild" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                T = new DOMEditAction 'appendChild', div, span
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Add Hello, friend.'
                done()

### should have "insertBefore" instances

That is, we should be able to construct instances of the class with
the type "insertBefore", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `toInsert` member that stores the child to be
inserted, as well as an integer member `insertBefore` that is the
index that the newly inserted child will have after insertion.

        it 'should have "insertBefore" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                T = new DOMEditAction 'insertBefore', div, span
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.toInsert
                    T.insertBefore
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual tagName : 'SPAN'
                expect( result[3] ).toEqual 1
                expect( result[4] ).toEqual 'insertBefore'
                done()

### should correctly describe "insertBefore" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "insertBefore" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                T = new DOMEditAction 'insertBefore', div, span
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Insert Hello, friend.'
                done()

### should have "normalize" instances

That is, we should be able to construct instances of the class with
the type "normalize", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `textChildren` member that maps the indices of
child text elements (before the normalization) to their text
content at that time.

        it 'should have "normalize" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = 'one'
                div.appendChild document.createTextNode 'two'
                span = document.createElement 'span'
                span.appendChild document.createTextNode 'three'
                span.appendChild document.createTextNode 'four'
                div.appendChild span
                div.appendChild document.createTextNode 'five'
                T = new DOMEditAction 'normalize', div
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.toJSON()
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual {
                    node : [], type : 'normalize',
                    sequences : {
                        '[0]' : [ 'one', 'two' ]
                        '[1,0]' : [ 'three', 'four' ]
                    }
                }
                done()

### should correctly describe "normalize" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "normalize" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.appendChild document.createTextNode 'one'
                div.appendChild document.createTextNode 'two'
                T = new DOMEditAction 'normalize', div
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Normalize text'
                done()

### should have "removeAttribute" instances

That is, we should be able to construct instances of the class with
the type "removeAttribute", as described [in the documentation for
the class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `name` member containing the (string) key of the
attribute to remove, and a `value` member containing the (string)
value that the attribute had before removal.

        it 'should have "removeAttribute" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                T = new DOMEditAction 'removeAttribute', div, 'id'
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.name
                    T.value
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual 'removeAttribute'
                done()

### should correctly describe "removeAttribute" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeAttribute" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                T = new DOMEditAction 'removeAttribute', div, 'id'
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Remove id attribute'
                done()

### should have "removeAttributeNode" instances

That is, we should be able to construct instances of the class with
the type "removeAttributeNode", as described [in the documentation
for the class's constructor](
domeditaction.litcoffee.html#constructor).
These will have a `name` member containing the (string) key of the
attribute to remove, and a `value` member containing the (string)
value that the attribute had before removal.

        it 'should have "removeAttributeNode" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                T = new DOMEditAction 'removeAttributeNode', div,
                    div.getAttributeNode 'id'
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.name
                    T.value
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual 'removeAttributeNode'
                done()

### should correctly describe "removeAttributeNode" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeAttributeNode" ' +
           'instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                togo = document.createAttribute 'id'
                T = new DOMEditAction 'removeAttributeNode', div,
                    togo
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Remove id attribute'
                done()

### should have "removeChild" instances

That is, we should be able to construct instances of the class with
the type "removeChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have an integer `childIndex` member containing the
index of the child before removal, and a `child` member containing
a serialized version of the removed child.

        it 'should have "removeChild" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = 'first child text node'
                span = document.createElement 'span'
                span.innerHTML = 'span contents, just text'
                div.appendChild span
                div.appendChild document.createTextNode 'more text'
                T = new DOMEditAction 'removeChild', div, span
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.childIndex
                    T.child
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 1
                expect( result[3] ).toEqual
                    'tagName' : 'SPAN',
                    'children' : [ 'span contents, just text' ]
                expect( result[4] ).toEqual 'removeChild'
                done()

### should correctly describe "removeChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeChild" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                div.appendChild span
                T = new DOMEditAction 'removeChild', div, span
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Remove Hello, friend.'
                done()

### should have "replaceChild" instances

That is, we should be able to construct instances of the class with
the type "replaceChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have an integer `childIndex` member containing the
index of the child being replaced, an `oldChild` member containing
a serialized version of the replaced child, and a `newChild`
member containing a serialization of the replacement child.

        it 'should have "replaceChild" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                div.innerHTML = 'first child text node'
                span = document.createElement 'span'
                span.innerHTML = 'span contents, just text'
                div.appendChild span
                div.appendChild document.createTextNode 'more text'
                repl = document.createElement 'h1'
                repl.innerHTML = 'Announcement!'
                T = new DOMEditAction 'replaceChild',
                    div, repl, span
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.childIndex
                    T.oldChild
                    T.newChild
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 1
                expect( result[3] ).toEqual
                    'tagName' : 'SPAN',
                    'children' : [ 'span contents, just text' ]
                expect( result[4] ).toEqual
                    'tagName' : 'H1',
                    'children' : [ 'Announcement!' ]
                expect( result[5] ).toEqual 'replaceChild'
                done()

### should correctly describe "replaceChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "replaceChild" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                div.appendChild span
                span2 = document.createElement 'span'
                span2.innerHTML = '<h1>Heading</h1>'
                T = new DOMEditAction 'replaceChild', div, span2,
                    span
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual \
                    'Replace Hello, friend. with Heading'
                done()

### should have "setAttribute" instances

That is, we should be able to construct instances of the class with
the type "setAttribute", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a string `name` member containing the name of the
attribute being changed, a string `oldValue` member containing the
value of the attribute before it was set, and a string `newValue`
member containing the value after the attribute is set.

        it 'should have "setAttribute" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                T = new DOMEditAction 'setAttribute', div, 'id', 1
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.name
                    T.oldValue
                    T.newValue
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual '1'
                expect( result[5] ).toEqual 'setAttribute'
                done()

### should correctly describe "setAttribute" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "setAttribute" instances',
        ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                T = new DOMEditAction 'setAttribute', div, 'id', 17
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Change id from 0 to 17'
                done()

### should have "setAttributeNode" instances

That is, we should be able to construct instances of the class with
the type "setAttributeNode", as described [in the documentation for
the class's constructor](domeditaction.litcoffee.html#constructor).
These will have a string `name` member containing the name of the
attribute being changed, a string `oldValue` member containing the
value of the attribute before it was set, and a string `newValue`
member containing the value after the attribute is set.

        it 'should have "setAttributeNode" instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                attr = document.createAttribute 'id'
                attr.value = 1
                T = new DOMEditAction 'setAttributeNode', div, attr
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.name
                    T.oldValue
                    T.newValue
                    T.type
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual '1'
                expect( result[5] ).toEqual 'setAttributeNode'
                done()

### should correctly describe "setAttributeNode" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "setAttributeNode" ' +
           'instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                change = document.createAttribute 'id'
                change.value = 17
                T = new DOMEditAction 'setAttributeNode', div,
                    change
                T.toString()
            , ( err, result ) ->
                expect( result ).toEqual 'Change id from 0 to 17'
                done()

### should have no other instances

That is, we should get errors if we attempt to construct instances
of the class with types other than those tested in the other tests
in this specification, above.

        it 'should have no other instances', ( done ) =>
            @page.evaluate ->
                div = document.getElementById '0'
                result = []
                result.push try new DOMEditAction 'foo', div \
                            catch e then e.message
                result.push try new DOMEditAction div, div \
                            catch e then e.message
                result.push try new DOMEditAction 17, div \
                            catch e then e.message
                result.push try new DOMEditAction \
                            'appendChildren', div \
                            catch e then e.message
                result
            , ( err, result ) ->
                expect( /Invalid DOMEditAction type/.test
                    result[0] ).toBeTruthy()
                expect( /Invalid DOMEditAction type/.test
                    result[1] ).toBeTruthy()
                expect( /Invalid DOMEditAction type/.test
                    result[2] ).toBeTruthy()
                expect( /Invalid DOMEditAction type/.test
                    result[3] ).toBeTruthy()
                done()

Eventually it would also be good to test here every other error
case in the constructor, but I have not yet written such tests.
I have added them to [the planning document](plan.md.html),
however, so they are not forgotten.

