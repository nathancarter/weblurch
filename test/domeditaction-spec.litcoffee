
# Tests for the `DOMEditAction` class

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
                ]
                result
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual tagName : 'SPAN'
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual tagName : 'SPAN'
                expect( result[3] ).toEqual 1
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
                div.appendChild span
                div.appendChild document.createTextNode 'four'
                T = new DOMEditAction 'normalize', div
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.textChildren
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual
                    0 : 'one', 1 : 'two', 3 : 'four'
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 1
                expect( result[3] ).toEqual
                    'tagName' : 'SPAN',
                    'children' : [ 'span contents, just text' ]
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
                    div, span, repl
                result = [
                    T.tracker is DOMEditTracker.instances[0]
                    T.node
                    T.childIndex
                    T.oldChild
                    T.newChild
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual '1'
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
                ]
            , ( err, result ) ->
                expect( result[0] ).toBeTruthy()
                expect( result[1] ).toEqual []
                expect( result[2] ).toEqual 'id'
                expect( result[3] ).toEqual '0'
                expect( result[4] ).toEqual '1'
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

