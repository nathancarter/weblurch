
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
            pageExpects -> DOMEditAction

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "appendChild" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  In every single case, they
should report non-null, since appending a child is always an action
that impacts the DOM, and thus is not a null action.

        it 'should detect null "appendChild" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                span1 = document.createElement 'span'
                span1.innerHTML = 'Hello, <b>friend.</b>'
                span2 = document.createElement 'span'
                span2.innerHTML = 'Hello, <b>frenemy.</b>'
                window.T1 = new DOMEditAction 'appendChild', div,
                    span1
                window.T2 = new DOMEditAction 'appendChild', div,
                    span2
                window.T3 = new DOMEditAction 'appendChild', span1,
                    span2
            pageExpects -> not T1.isNullAction()
            pageExpects -> not T2.isNullAction()
            pageExpects -> not T3.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "insertBefore" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  In every single case, they
should report non-null, since inserting a child is always an action
that impacts the DOM, and thus is not a null action.

        it 'should detect null "insertBefore" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                span1 = document.createElement 'span'
                span1.innerHTML = 'Hello, <b>friend.</b>'
                span2 = document.createElement 'span'
                span2.innerHTML = 'Hello, <b>frenemy.</b>'
                window.T1 = new DOMEditAction 'insertBefore', div,
                    span1
                window.T2 = new DOMEditAction 'insertBefore', div,
                    span2
                window.T3 = new DOMEditAction 'insertBefore',
                    span1, span2, span1.childNodes[1]
            pageExpects -> not T1.isNullAction()
            pageExpects -> not T2.isNullAction()
            pageExpects -> not T3.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "normalize" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  Such instances should be null
actions iff there were no adjacent text nodes under the node on
which the action was constructed.

        it 'should detect null "normalize" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'

Create a span in which normalize does nothing.

                span1 = document.createElement 'span'
                span1.innerHTML = 'Hello, <b>friend.</b>'

Create a span in which normalize does something.

                span2 = document.createElement 'span'
                span2.textContent = 'Hello...'
                span2.appendChild document.createTextNode 'frenemy'

Place both spans in the div, so that we can check more than one
level deep.

                div.appendChild span1
                div.appendChild span2

Then we investigate whether normalize is null on each of those two
spans, as well as the whole div.  It should be null only on the
first span, and non-null everywhere else.

                window.T1 = new DOMEditAction 'normalize', div
                window.T2 = new DOMEditAction 'normalize', span1
                window.T3 = new DOMEditAction 'normalize', span2
            pageExpects -> not T1.isNullAction()
            pageExpects -> T2.isNullAction()
            pageExpects -> not T3.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "removeAttribute" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff the
attribute to be removed didn't exist in the first place.

        it 'should detect null "removeAttribute" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'

We try it on an attribute that exists, and then one that doesn't,
requiring "null" and "not null" as the answers, in that order.

                window.T1 = new DOMEditAction 'removeAttribute',
                    div, 'id'
                window.T2 = new DOMEditAction 'removeAttribute',
                    div, 'attribute-not-there'
            pageExpects -> not T1.isNullAction()
            pageExpects -> T2.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "removeAttributeNode" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff the
attribute to be removed didn't exist in the first place.
We proceed the same as in the "removeAttribute" case, above.

        it 'should detect null "removeAttributeNode" instances',
        inPage ->
            pageDo ->
                div = document.getElementById '0'
                togo = document.createAttribute 'id'
                window.T1 = new DOMEditAction \
                    'removeAttributeNode', div, togo
                togo = document.createAttribute \
                    'attribute-not-there'
                window.T2 = new DOMEditAction \
                    'removeAttributeNode', div, togo
            pageExpects -> not T1.isNullAction()
            pageExpects -> T2.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "removeChild" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are never null, because
removing a child always changes the DOM.

        it 'should detect null "removeChild" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                div.appendChild span
                window.T1 = new DOMEditAction 'removeChild', div,
                    span
                window.T2 = new DOMEditAction 'removeChild', span,
                    span.childNodes[1]
            pageExpects -> not T1.isNullAction()
            pageExpects -> not T2.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "replaceChild" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff the new
child has the same exact structure as the one it's replacing.

        it 'should detect null "replaceChild" instances', inPage ->
            pageDo ->
                window.div = document.getElementById '0'
                window.span = document.createElement 'span'
                span.innerHTML = 'Hello, <b>friend.</b>'
                span.setAttribute 'example', 'some value'
                div.appendChild span

Replacing it witha a completely different child must be a non-null
action.

                span2 = document.createElement 'span'
                span2.innerHTML = '<h1>Heading</h1>'
                window.T1 = new DOMEditAction 'replaceChild', div,
                    span2, span
            pageExpects -> not T1.isNullAction()

Replacing it with a very similar (but still slightly different)
child must be a non-null action.

            pageDo ->
                span3 = document.createElement 'span'
                span3.innerHTML = 'Hello, <b>friend.</b>'
                window.T2 = new DOMEditAction 'replaceChild', div,
                    span3, span
            pageExpects -> not T2.isNullAction()

Replacing it with an exact copy must be a null action.

            pageDo ->
                span4 = document.createElement 'span'
                span4.innerHTML = 'Hello, <b>friend.</b>'
                span4.setAttribute 'example', 'some value'
                window.T3 = new DOMEditAction 'replaceChild', div,
                    span4, span
            pageExpects -> T3.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "setAttribute" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff the new
attribute value is the same as the old one.

        it 'should detect null "setAttribute" instances',
        inPage ->
            pageDo ->
                window.div = document.getElementById '0'

If we set an existing attribute to its current value, that's a null
action; setting it to a new value is a non-null action.

                window.T1 = new DOMEditAction 'setAttribute', div,
                    'id', 0
                window.T2 = new DOMEditAction 'setAttribute', div,
                    'id', 17
            pageExpects -> T1.isNullAction()
            pageExpects -> not T2.isNullAction()

If we set a non-existant attribute to the empty string is a null
action; setting it to any other value is a non-null action.

            pageDo ->
                window.T1 = new DOMEditAction 'setAttribute', div,
                    'other-thing', ''
                window.T2 = new DOMEditAction 'setAttribute', div,
                    'other-thing', null
                window.T3 = new DOMEditAction 'setAttribute', div,
                    'other-thing', undefined
                window.T4 = new DOMEditAction 'setAttribute', div,
                    'other-thing', 'not empty'
            pageExpects -> T1.isNullAction()
            pageExpects -> not T2.isNullAction()
            pageExpects -> not T3.isNullAction()
            pageExpects -> not T4.isNullAction()

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
            pageExpects -> T.tracker is DOMEditTracker.instances[0]
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

### should detect null "setAttributeNode" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff the new
attribute value is the same as the old one.

        it 'should detect null "setAttributeNode" instances',
        inPage ->
            pageDo ->
                window.div = document.getElementById '0'

If we set an existing attribute to its current value, that's a null
action; setting it to a new value is a non-null action.

                tmp = document.createAttribute 'id'
                tmp.value = 0
                window.T1 = new DOMEditAction 'setAttributeNode',
                    div, tmp
                tmp = document.createAttribute 'id'
                tmp.value = 17
                window.T2 = new DOMEditAction 'setAttributeNode',
                    div, tmp
            pageExpects -> T1.isNullAction()
            pageExpects -> not T2.isNullAction()

If we set a non-existant attribute to the empty string is a null
action; setting it to any other value is a non-null action.

            pageDo ->
                tmp = document.createAttribute 'other-thing'
                tmp.value = ''
                window.T1 = new DOMEditAction 'setAttributeNode',
                    div, tmp
                tmp = document.createAttribute 'other-thing'
                tmp.value = null
                window.T2 = new DOMEditAction 'setAttributeNode',
                    div, tmp
                tmp = document.createAttribute 'other-thing'
                tmp.value = undefined
                window.T3 = new DOMEditAction 'setAttributeNode',
                    div, tmp
                tmp = document.createAttribute 'other-thing'
                tmp.value = 'not empty'
                window.T4 = new DOMEditAction 'setAttributeNode',
                    div, tmp
            pageExpects -> T1.isNullAction()
            pageExpects -> not T2.isNullAction()
            pageExpects -> not T3.isNullAction()
            pageExpects -> not T4.isNullAction()

### should have "compound" instances

That is, we should be able to construct instances of the class with
the type "compound", as described [in the documentation for
the class's constructor](domeditaction.litcoffee.html#constructor).
These will have a string `description` member containing the name
of the compound action group, as well as an array of other actions
stored inside.

        it 'should have "compound" instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                attr = document.createAttribute 'id'
                attr.value = 1

First we construct two DOMEditAction instances that will be used
to form the compound action.

                window.T1 = new DOMEditAction 'setAttributeNode',
                    div, attr
                span = document.createElement 'span'
                span.textContent = 'abcdefg'
                window.T2 = new DOMEditAction 'appendChild',
                    div, span

Next we assemble them in two ways, because the constructor for
compound edit actions can be called in either of the following two
ways; we must test both.

                window.T3 = new DOMEditAction 'compound',
                    [ T1, T2 ]
                window.T4 = new DOMEditAction 'compound', T1, T2

Now we verify the same things for both `T3` and `T4`: that they
have the correct tracker, node, description, type, and subactions.

            pageExpects ->
                T3.tracker is DOMEditTracker.instances[0]
            pageExpects ( -> T3.node ), 'toEqual', []
            pageExpects ( -> T3.description ),
                'toEqual', 'Document edit'
            pageExpects ( -> T3.type ), 'toEqual', 'compound'
            pageExpects -> T3.subactions[0] is T1
            pageExpects -> T3.subactions[1] is T2
            pageExpects ->
                T4.tracker is DOMEditTracker.instances[0]
            pageExpects ( -> T4.node ), 'toEqual', []
            pageExpects ( -> T4.description ),
                'toEqual', 'Document edit'
            pageExpects ( -> T4.type ), 'toEqual', 'compound'
            pageExpects -> T4.subactions[0] is T1
            pageExpects -> T4.subactions[1] is T2

### should correctly describe "compound" instances

That is, instances constructed as above should have a sensible
description provided when their `toString` method is called.

        it 'should correctly describe "compound" ' +
           'instances', inPage ->
            pageDo ->
                div = document.getElementById '0'
                attr = document.createAttribute 'id'
                attr.value = 1
                window.T1 = new DOMEditAction 'setAttributeNode',
                    div, attr
                span = document.createElement 'span'
                span.textContent = 'abcdefg'
                window.T2 = new DOMEditAction 'appendChild',
                    div, span
                window.T3 = new DOMEditAction 'compound',
                    [ T1, T2 ]
                T3.description = 'Burnsnoggle the widgets'
            pageExpects ( -> T3.toString() ),
                'toEqual', 'Burnsnoggle the widgets'

### should detect null "compound" instances

That is, instances constructed as above should be able to correctly
report whether or not they are null.  They are null iff all of the
subactions are null.

        it 'should detect null "compound" instances', inPage ->
            pageDo ->
                window.div = document.getElementById '0'

Let's create some non-null atomic actions.

                attr = document.createAttribute 'id'
                attr.value = 1
                T1 = new DOMEditAction 'setAttributeNode', div,
                    attr
                span = document.createElement 'span'
                span.textContent = 'abcdefg'
                T2 = new DOMEditAction 'appendChild', div, span

Let's create some null atomic actions.

                T3 = new DOMEditAction 'normalize', div
                T4 = new DOMEditAction 'setAttribute', div, 'id',
                    '0'

Let's form five compound actions, two null and three non-null.

                window.C1 = new DOMEditAction 'compound',
                    [ T3, T4 ]
                window.C2 = new DOMEditAction 'compound',
                    [ T4, T3 ]
                window.C3 = new DOMEditAction 'compound',
                    [ T1, T3 ]
                window.C4 = new DOMEditAction 'compound',
                    [ T2, T3 ]
                window.C5 = new DOMEditAction 'compound',
                    [ T1, T4 ]
            pageExpects -> C1.isNullAction()
            pageExpects -> C2.isNullAction()
            pageExpects -> not C3.isNullAction()
            pageExpects -> not C4.isNullAction()
            pageExpects -> not C5.isNullAction()

### should have no other instances

That is, we should get errors if we attempt to construct instances
of the class with types other than those tested in the other tests
in this specification, above.

        it 'should have no other instances', inPage ->
            pageDo -> window.div = document.getElementById '0'
            pageExpectsError ( -> new DOMEditAction 'foo', div )
            pageExpectsError ( -> new DOMEditAction div, div )
            pageExpectsError ( -> new DOMEditAction 17, div )
            pageExpectsError ( ->
                new DOMEditAction 'appendChildren', div )

Eventually it would also be good to test here every other error
case in the constructor, but I have not yet written such tests.
I have added them to [the planning document](plan.md.html),
however, so they are not forgotten.

