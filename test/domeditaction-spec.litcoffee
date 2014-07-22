
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

    { phantomDescribe, pageExpects, pageExpectsError,
      inPage, pageDo } = require './phantom-utils'

## DOMEditAction class

    phantomDescribe 'DOMEditAction class', './app/index.html', ->

### should exist

That is, the class should be defined in the global namespace of
the browser after loading the main app page.

        it 'should exist', inPage ->
            pageExpects ( -> DOMEditAction ), 'toBeTruthy'

### should have "appendChild" instances

That is, we should be able to construct instances of the class with
the type "appendChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `toAppend` member that stores the child to be
appended.

        it 'should have "appendChild" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'appendChild', div,
                    document.createElement 'span'
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.toAppend ),
                'toEqual', tagName : 'SPAN'
            pageExpects ( -> T.type ), 'toEqual', 'appendChild'

### should correctly describe "appendChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "appendChild" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                window.T = new DOMEditAction 'appendChild', div,
                    span
            pageExpects ( -> T.toString() ),
                'toEqual', 'Add Hello, friend.'

### should have "insertBefore" instances

That is, we should be able to construct instances of the class with
the type "insertBefore", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `toInsert` member that stores the child to be
inserted, as well as an integer member `insertBefore` that is the
index that the newly inserted child will have after insertion.

        it 'should have "insertBefore" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'insertBefore', div,
                    document.createElement 'span'
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.toInsert ),
                'toEqual', tagName : 'SPAN'
            pageExpects ( -> T.insertBefore ), 'toEqual', 1
            pageExpects ( -> T.type ), 'toEqual', 'insertBefore'

### should correctly describe "insertBefore" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "insertBefore" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                window.T = new DOMEditAction 'insertBefore', div,
                    span
            pageExpects ( -> T.toString() ),
                'toEqual', 'Insert Hello, friend.'

### should have "normalize" instances

That is, we should be able to construct instances of the class with
the type "normalize", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `textChildren` member that maps the indices of
child text elements (before the normalization) to their text
content at that time.

        it 'should have "normalize" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                div.innerHTML = 'one'
                div.appendChild document.createTextNode 'two'
                span = document.createElement 'span'
                span.appendChild document.createTextNode 'three'
                span.appendChild document.createTextNode 'four'
                div.appendChild span
                div.appendChild document.createTextNode 'five'
                window.T = new DOMEditAction 'normalize', div
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.toJSON() ), 'toEqual', {
                node : [], type : 'normalize',
                sequences : {
                    '[0]' : [ 'one', 'two' ]
                    '[1,0]' : [ 'three', 'four' ]
                }
            }

### should correctly describe "normalize" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "normalize" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                div.appendChild document.createTextNode 'one'
                div.appendChild document.createTextNode 'two'
                window.T = new DOMEditAction 'normalize', div
            pageExpects ( -> T.toString() ),
                'toEqual', 'Normalize text'

### should have "removeAttribute" instances

That is, we should be able to construct instances of the class with
the type "removeAttribute", as described [in the documentation for
the class's constructor](domeditaction.litcoffee.html#constructor).
These will have a `name` member containing the (string) key of the
attribute to remove, and a `value` member containing the (string)
value that the attribute had before removal.

        it 'should have "removeAttribute" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'removeAttribute',
                    div, 'id'
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.name ), 'toEqual', 'id'
            pageExpects ( -> T.value ), 'toEqual', '0'
            pageExpects ( -> T.type ), 'toEqual', 'removeAttribute'

### should correctly describe "removeAttribute" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeAttribute" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'removeAttribute',
                    div, 'id'
            pageExpects ( -> T.toString() ),
                'toEqual', 'Remove id attribute'

### should have "removeAttributeNode" instances

That is, we should be able to construct instances of the class with
the type "removeAttributeNode", as described [in the documentation
for the class's constructor](
domeditaction.litcoffee.html#constructor).
These will have a `name` member containing the (string) key of the
attribute to remove, and a `value` member containing the (string)
value that the attribute had before removal.

        it 'should have "removeAttributeNode" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'removeAttributeNode',
                    div, div.getAttributeNode 'id'
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.name ), 'toEqual', 'id'
            pageExpects ( -> T.value ), 'toEqual', '0'
            pageExpects ( -> T.type ),
                'toEqual', 'removeAttributeNode'

### should correctly describe "removeAttributeNode" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeAttributeNode" ' +
           'instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                togo = document.createAttribute 'id'
                window.T = new DOMEditAction 'removeAttributeNode',
                    div, togo
            pageExpects ( -> T.toString() ),
                'toEqual', 'Remove id attribute'

### should have "removeChild" instances

That is, we should be able to construct instances of the class with
the type "removeChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have an integer `childIndex` member containing the
index of the child before removal, and a `child` member containing
a serialized version of the removed child.

        it 'should have "removeChild" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                div.innerHTML = 'first child text node'
                span = document.createElement 'span'
                span.innerHTML = 'span contents, just text'
                div.appendChild span
                div.appendChild document.createTextNode 'more text'
                window.T = new DOMEditAction 'removeChild', div,
                    span
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.childIndex ), 'toEqual', 1
            pageExpects ( -> T.child ), 'toEqual', {
                'tagName' : 'SPAN'
                'children' : [ 'span contents, just text' ]
            }
            pageExpects ( -> T.type ), 'toEqual', 'removeChild'

### should correctly describe "removeChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "removeChild" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                div.appendChild span
                window.T = new DOMEditAction 'removeChild', div,
                    span
            pageExpects ( -> T.toString() ),
                'toEqual', 'Remove Hello, friend.'

### should have "replaceChild" instances

That is, we should be able to construct instances of the class with
the type "replaceChild", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have an integer `childIndex` member containing the
index of the child being replaced, an `oldChild` member containing
a serialized version of the replaced child, and a `newChild`
member containing a serialization of the replacement child.

        it 'should have "replaceChild" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                div.innerHTML = 'first child text node'
                span = document.createElement 'span'
                span.innerHTML = 'span contents, just text'
                div.appendChild span
                div.appendChild document.createTextNode 'more text'
                repl = document.createElement 'h1'
                repl.innerHTML = 'Announcement!'
                window.T = new DOMEditAction 'replaceChild',
                    div, repl, span
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.childIndex ), 'toEqual', 1
            pageExpects ( -> T.oldChild ), 'toEqual', {
                'tagName' : 'SPAN'
                'children' : [ 'span contents, just text' ]
            }
            pageExpects ( -> T.newChild ), 'toEqual', {
                'tagName' : 'H1'
                'children' : [ 'Announcement!' ]
            }
            pageExpects ( -> T.type ), 'toEqual', 'replaceChild'

### should correctly describe "replaceChild" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "replaceChild" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                div.appendChild span
                span2 = document.createElement 'span'
                span2.innerHTML = '<h1>Heading</h1>'
                window.T = new DOMEditAction 'replaceChild', div,
                    span2, span
            pageExpects ( -> T.toString() ),
                'toEqual', 'Replace Hello, friend. with Heading'

### should have "setAttribute" instances

That is, we should be able to construct instances of the class with
the type "setAttribute", as described [in the documentation for the
class's constructor](domeditaction.litcoffee.html#constructor).
These will have a string `name` member containing the name of the
attribute being changed, a string `oldValue` member containing the
value of the attribute before it was set, and a string `newValue`
member containing the value after the attribute is set.

        it 'should have "setAttribute" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'setAttribute', div,
                    'id', 1
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.name ), 'toEqual', 'id'
            pageExpects ( -> T.oldValue ), 'toEqual', '0'
            pageExpects ( -> T.newValue ), 'toEqual', '1'
            pageExpects ( -> T.type ), 'toEqual', 'setAttribute'

### should correctly describe "setAttribute" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "setAttribute" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                window.T = new DOMEditAction 'setAttribute', div,
                    'id', 17
            pageExpects ( -> T.toString() ),
                'toEqual', 'Change id from 0 to 17'

### should have "setAttributeNode" instances

That is, we should be able to construct instances of the class with
the type "setAttributeNode", as described [in the documentation for
the class's constructor](domeditaction.litcoffee.html#constructor).
These will have a string `name` member containing the name of the
attribute being changed, a string `oldValue` member containing the
value of the attribute before it was set, and a string `newValue`
member containing the value after the attribute is set.

        it 'should have "setAttributeNode" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                attr = document.createAttribute 'id'
                attr.value = 1
                window.T = new DOMEditAction 'setAttributeNode',
                    div, attr
            pageExpects ( ->
                T.tracker is DOMEditTracker.instances[0] ),
                'toBeTruthy'
            pageExpects ( -> T.node ), 'toEqual', []
            pageExpects ( -> T.name ), 'toEqual', 'id'
            pageExpects ( -> T.oldValue ), 'toEqual', '0'
            pageExpects ( -> T.newValue ), 'toEqual', '1'
            pageExpects ( -> T.type ),
                'toEqual', 'setAttributeNode'

### should correctly describe "setAttributeNode" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "setAttributeNode" ' +
           'instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                change = document.createAttribute 'id'
                change.value = 17
                window.T = new DOMEditAction 'setAttributeNode',
                    div, change
            pageExpects ( -> T.toString() ),
                'toEqual', 'Change id from 0 to 17'

### should have no other instances

That is, we should get errors if we attempt to construct instances
of the class with types other than those tested in the other tests
in this specification, above.

        it 'should have no other instances', inPage ->
            pageDo ->
                window.div = document.getElementById '0'
            pageExpectsError ( -> new DOMEditAction 'foo', div )
            pageExpectsError ( -> new DOMEditAction div, div )
            pageExpectsError ( -> new DOMEditAction 17, div )
            pageExpectsError ( ->
                new DOMEditAction 'appendChildren', div )

Eventually it would also be good to test here every other error
case in the constructor, but I have not yet written such tests.
I have added them to [the planning document](plan.md.html),
however, so they are not forgotten.

