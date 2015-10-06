
# Tests of Groups plugin for TinyMCE Editor

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage, pageWaitFor,
      simplifiedHTML, pageExpectsError, pageType,
      pageKey } = require './phantom-utils'
    { pageInstall, pageCommand, allContent, selectedContent,
      setAllContent, setSelectedContent,
      pageSelectAll } = require './app-test-utils'

These auxiliary function creates the HTML code for groupers, for use in the
tests below.

    openBase64 = 'data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMCcgaGVpZ2h0PScyMSc+PGZvcmVpZ25PYmplY3Qgd2lkdGg9JzEwMCUnIGhlaWdodD0nMTAwJSc+PGRpdiB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMTk5OS94aHRtbCcgc3R5bGU9J2ZvbnQtc2l6ZToxNnB4OyBmb250LWZhbWlseTpWZXJkYW5hLCBBcmlhbCwgSGVsdmV0aWNhLCBzYW5zLXNlcmlmOyc+PGZvbnQgY29sb3I9IiM5OTY2NjYiPls8L2ZvbnQ+PC9kaXY+PC9mb3JlaWduT2JqZWN0Pjwvc3ZnPg=='
    closeBase64 = 'data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMCcgaGVpZ2h0PScyMSc+PGZvcmVpZ25PYmplY3Qgd2lkdGg9JzEwMCUnIGhlaWdodD0nMTAwJSc+PGRpdiB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMTk5OS94aHRtbCcgc3R5bGU9J2ZvbnQtc2l6ZToxNnB4OyBmb250LWZhbWlseTpWZXJkYW5hLCBBcmlhbCwgSGVsdmV0aWNhLCBzYW5zLXNlcmlmOyc+PGZvbnQgY29sb3I9IiM5OTY2NjYiPl08L2ZvbnQ+PC9kaXY+PC9mb3JlaWduT2JqZWN0Pjwvc3ZnPg=='
    grouper = ( openClose, id, typeName = 'me' ) ->
        "<img id=\"#{openClose}#{id}\" class=\"grouper #{typeName}\"
          src=\"#{if openClose is 'open' then openBase64 else closeBase64}\"
          alt=\"\">"
    open = ( id ) -> grouper 'open', id
    close = ( id ) -> grouper 'close', id

## Groups plugin

Start with a simple test to verify that the plugin has been loaded.

    phantomDescribe 'Groups plugin', './app/app.html', ->

### should be installed

Just verify that the active TinyMCE editor has a Groups plugin.

        it 'should be installed', inPage ->
            pageExpects -> tinymce.activeEditor.Groups

## Group instances

Some aspects of this class can be tested independently of the editor, so we
do so here, to do some tests in the simplest context possible.

    phantomDescribe 'Group class', './app/app.html', ->

First, a very simple test of the constructor, just ensuring that it's
recording its two inputs.

### are constructible from any two inputs

        it 'are constructible from any two inputs', inPage ->
            pageDo -> window._tmp = new Group 1, 2
            pageExpects ( -> window._tmp.open ), 'toEqual', 1
            pageExpects ( -> window._tmp.close ), 'toEqual', 2
            pageDo ->
                open = document.createElement 'span'
                open.textContent = 'uno'
                close = document.createElement 'p'
                close.setAttribute 'align', 'right'
                window._tmp = new Group open, close
            pageExpects ( -> window._tmp.open.outerHTML ), 'toEqual',
                '<span>uno</span>'
            pageExpects ( -> window._tmp.close.outerHTML ), 'toEqual',
                '<p align="right"></p>'

Second, we verify that `Group` instances can correctly look up their ID in
their open groupers.

### can look up their IDs from their open groupers

        it 'can look up their IDs from their open groupers', inPage ->
            pageDo ->
                htmlToNode = ( html ) ->
                    container = document.createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]
                open = htmlToNode grouperHTML 'test', 'open', 5
                close = htmlToNode grouperHTML 'test', 'close', 5
                window._tmp = new Group open, close
            pageExpects ( -> window._tmp.id() ), 'toEqual', 5
            pageDo ->
                htmlToNode = ( html ) ->
                    container = document.createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]
                open = htmlToNode grouperHTML 'test', 'open', 2
                close = htmlToNode grouperHTML 'test', 'close', 6
                window._tmp = new Group open, close
            pageExpects ( -> window._tmp.id() ), 'toEqual', 2

Last, we verify that `Group` instances with invalid open groupers return
null when we look up their IDs.

### return a null ID if the open grouper is invalid

        it 'return a null ID if the open grouper is invalid', inPage ->
            pageDo ->
                htmlToNode = ( html ) ->
                    container = document.createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]
                open = 10
                close = htmlToNode grouperHTML 'test', 'close', 5
                window._tmp = new Group open, close
            pageExpects ( -> window._tmp.id() ), 'toBeNull'

### return their type name correctly

This test is simpler than the subsequent one, because the type name is just
a string that is lifted out of the open grouper.

        it 'return their type name correctly', inPage ->
            pageDo ->
                htmlToNode = ( html ) ->
                    container = document.createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]
                open = htmlToNode grouperHTML 'test', 'open', 5
                close = htmlToNode grouperHTML 'test', 'close', 5
                window._tmp1 = new Group open, close
                open = htmlToNode grouperHTML 'foo', 'open', 0
                close = htmlToNode grouperHTML 'foo', 'close', 0
                window._tmp2 = new Group open, close
            pageExpects ( -> window._tmp1.typeName() ), 'toEqual', 'test'
            pageExpects ( -> window._tmp2.typeName() ), 'toEqual', 'foo'

### return their type object correctly

This test is more complex than the previous.  Each of its sub-cases is
commented on below.

        it 'return their type object correctly', inPage ->
            pageDo ->
                window.htmlToNode = ( html ) ->
                    container =
                        tinymce.activeEditor.getDoc().createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]

It should return undefined if the group was constructed with no Groups
plugin provided.

            pageDo ->
                open = htmlToNode grouperHTML 'foo', 'open', 0
                close = htmlToNode grouperHTML 'foo', 'close', 0
                window._tmp = new Group open, close, null
            pageExpects ->
                window._tmp.open.ownerDocument() is \
                    tinymce.activeEditor.getDoc()
            pageExpects ( -> window._tmp.type() ), 'toBeUndefined'

It should return undefined if the group was constructed with a type name
that doesn't appear in its plugin's list of registered group names.

            pageDo ->
                open = htmlToNode grouperHTML 'test', 'open', 5
                close = htmlToNode grouperHTML 'test', 'close', 5
                window._tmp = new Group open, close
            pageExpects ->
                window._tmp.open.ownerDocument() is \
                    tinymce.activeEditor.getDoc()
            pageExpects ( -> window._tmp.type() ), 'toBeUndefined'

It should return an object, if the name of a valid group type provided at
the time the group was constructed.

            pageDo ->
                open = htmlToNode grouperHTML 'me', 'open', 1
                close = htmlToNode grouperHTML 'me', 'close', 1
                window._tmp = new Group open, close
            pageExpects ->
                window._tmp.open.ownerDocument() is \
                    tinymce.activeEditor.getDoc()
            pageExpects ( -> window._tmp.type() ), 'toBeTruthy'

The object returned should be the same one used when registering the group,
in the case when a valid group type is provided.

            pageDo ->
                window.example =
                    text : 'Name of group here'
                    other : 'attributes would go here'
                tinymce.activeEditor.Groups.addGroupType 'exa', example
                open = htmlToNode grouperHTML 'exa', 'open', 2
                close = htmlToNode grouperHTML 'exa', 'close', 2
                window._tmp = new Group open, close
            pageExpects ->
                window._tmp.open.ownerDocument() is \
                    tinymce.activeEditor.getDoc()
            pageExpects -> window._tmp.type() is example

## ID tracking methods

Next, test the routines that track which IDs have been used and which
remain free.

    phantomDescribe 'Groups plugin ID tracking', './app/app.html', ->

### nextFreeId() should count 0,1,2,...

Calling `nextFreeId()` on a freshly created `Groups` plugin should keep
yielding nonnegative integers starting with zero and counting upwards.  The
resulting `freeIds` array should have in it just the next integer.

        it 'nextFreeId() should count 0,1,2,...', inPage ->
            pageDo -> window.gr = tinymce.activeEditor.Groups
            pageExpects -> window.gr.freeIds
            pageExpects ( -> window.gr.freeIds ), 'toEqual', [ 0 ]
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 0
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 1
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 2
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 3
            pageExpects ( -> window.gr.freeIds ), 'toEqual', [ 4 ]

### addFreeId() re-inserts in order

After repeating the same four fetches of `nextFreeId()` as in the previous
test, we then restore the id 2 to the "free" set.  This should put it back
on the `freeIds` list in the correct spot, but restoring any id 4 or higher
should do nothing.  Then calls to `nextFreeId` should yield 2, 4, 5, 6, ...

        it 'addfreeId() re-inserts in order', inPage ->
            pageDo -> window.gr = tinymce.activeEditor.Groups
            pageExpects -> window.gr.freeIds
            pageExpects ( -> window.gr.freeIds ), 'toEqual', [ 0 ]
            pageDo -> window.gr.nextFreeId()
            pageDo -> window.gr.nextFreeId()
            pageDo -> window.gr.nextFreeId()
            pageDo -> window.gr.nextFreeId()
            pageExpects ( -> window.gr.freeIds ), 'toEqual', [ 4 ]
            pageDo -> window.gr.addFreeId 2
            pageExpects ( -> window.gr.freeIds ), 'toEqual', [ 2, 4 ]
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 2
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 4
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 5
            pageExpects ( -> window.gr.nextFreeId() ), 'toEqual', 6

## Grouping routines

Now we test the foundation of the Groups plugin, those routines that wrap
sections of the document in groupers.

    phantomDescribe 'Grouping routines', './app/app.html', ->

### wrap selections in groups

We test here the `groupCurrentSelection()` method of the Groups plugin.  It
does exactly what its name says; it wraps the current selection in a group.
We test here that this happens correctly in several situations.

        it 'wrap selections in groups', inPage ->

Ensure the editor is empty, then type some text, and ensure it got there.

            pageExpects allContent, 'toEqual', ''
            pageType 'ONETWOTHREE'
            pageExpects allContent, 'toEqual', '<p>ONETWOTHREE</p>'

Highlight the word TWO and wrap it in an ME Group.  Verify that this works.

            pageKey 'left' for i in [1..5]
            pageKey 'left', 'shift' for i in [1..3]
            pageExpects allContent, 'toEqual', '<p>ONETWOTHREE</p>'
            pageExpects selectedContent, 'toEqual', 'TWO'
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ONE#{open 0}TWO#{close 0}THREE</p>"

Highlight the existing group plus two characters on either side.  Wrap it in
another group and verify that this works.

            pageKey 'home'
            pageKey 'right' for i in [1..2]
            pageKey 'right', 'shift' for i in [1..7]
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ON#{open 1}E#{open 0}TWO#{close 0}T#{close 1}HREE</p>"

### wrap selections in groups across elements

This function is much like the previous, except we put the two ends of the
cursor in different HTML elements, to be sure the result comes out as we
desire.

        it 'wrap selections in groups across elements', inPage ->

Ensure the editor is empty, then insert some complex content.

            pageExpects allContent, 'toEqual', ''
            setAllContent simplifiedHTML \
                '<table>
                   <tbody>
                     <tr>
                       <td id="left">2 words</td>
                       <td>even more</td>
                     </tr>
                   </tbody>
                 </table>'
            pageExpects allContent, 'toBeSimilarHTML',
                '<table>
                   <tbody>
                     <tr>
                       <td id="left">2 words</td>
                       <td>even more</td>
                     </tr>
                   </tbody>
                 </table>'

Highlight the two words nearest to the column break and wrap them in an ME
Group.  Verify that this works.

            pageDo ->
                leftTD = tinymce.activeEditor.getDoc().getElementById 'left'
                tinymce.activeEditor.selection.setCursorLocation \
                    leftTD.childNodes[0], 2
            pageKey 'right', 'shift' for i in [1..10]
            pageExpects selectedContent, 'toEqual', 'wordseven'
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<table>
                   <tbody>
                     <tr>
                       <td id=\"left\">2 #{open 0}words</td>
                       <td>even#{close 0} more</td>
                     </tr>
                   </tbody>
                 </table>"

Highlight the whole table and wrap it in another group.  Verify that this
works as well.

            pageSelectAll()
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>#{open 1}</p>
                 <table>
                   <tbody>
                     <tr>
                       <td id=\"left\">2 #{open 0}words</td>
                       <td>even#{close 0} more</td>
                     </tr>
                   </tbody>
                 </table>
                 <p>#{close 1}</p>"

## Group hierarchy

Now we test the meat of the Groups plugin, those routines that maintain the
integrity of groups and deal with the group hierarchy.

    phantomDescribe 'Group hierarchy', './app/app.html', ->

### creates correct lists of free IDs

We use `groupCurrentSelection()` from the Groups plugin, then check to see
that the list of free IDs is correct after each use.

        it 'creates correct lists of free IDs', inPage ->

In an empty editor, the free IDs list should be `[ 0 ]` (all IDs free).
This should hold true whether or not we have scanned the document.

            getFreeIds = -> tinymce.activeEditor.Groups.freeIds
            pageExpects getFreeIds, 'toEqual', [ 0 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getFreeIds, 'toEqual', [ 0 ]

In an editor with content but no groups, the result should be the same.

            pageType 'ONETWOTHREE'
            pageExpects getFreeIds, 'toEqual', [ 0 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getFreeIds, 'toEqual', [ 0 ]

If we put a group in the document, then the first ID should be used up on
that group.  This is true whether or not we explicitly scan the document,
because changes should trigger such scanning automatically.

            pageKey 'left' for i in [1..5]
            pageKey 'left', 'shift' for i in [1..3]
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ONE#{open 0}TWO#{close 0}THREE</p>"
            pageExpects getFreeIds, 'toEqual', [ 1 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getFreeIds, 'toEqual', [ 1 ]

If we nest that in a group, then the first two IDs should be used up.  As
above, this is true before or after a document scan.

            pageKey 'home'
            pageKey 'right' for i in [1..2]
            pageKey 'right', 'shift' for i in [1..7]
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ON#{open 1}E#{open 0}TWO#{close 0}T#{close 1}HREE</p>"
            pageExpects getFreeIds, 'toEqual', [ 2 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getFreeIds, 'toEqual', [ 2 ]

If we delete one of the inner groupers, then scanning the document will
automatically occur, and will cause its partner to be deleted, and the
correct list of free IDs to be created.

            pageKey 'home'
            pageKey 'right' for i in [1..5]
            pageKey 'backspace'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ON#{open 1}ETWOT#{close 1}HREE</p>"
            pageExpects getFreeIds, 'toEqual', [ 0, 2 ]

### registers group instances correctly

We use `groupCurrentSelection()` from the Groups plugin, then check to see
that there are Group instances registered and stored under the appropriate
indices in the Groups plugin object itself.

        it 'registers group instances correctly', inPage ->

In an empty editor, the Groups plugin should have no objects stored in it
under integer indices.  This should hold true whether or not we have scanned
the document.

            getGroup = ( index ) ->
                eval "(function(){ return
                    tinymce.activeEditor.Groups[#{index}]; })"
            getOpen = ( index ) ->
                eval "(function(){ return
                    tinymce.activeEditor.Groups[#{index}].open.outerHTML;
                })"
            pageExpects getGroup( 0 ), 'toBeUndefined',
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getGroup( 0 ), 'toBeUndefined',
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',

In an editor with content but no groups, the result should be the same.

            pageType 'ONETWOTHREE'
            pageExpects getGroup( 0 ), 'toBeUndefined',
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getGroup( 0 ), 'toBeUndefined',
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',

If we put a group in the document, then the index 0 should point to that
group, but higher indices should have no objects stored under them.  As in
previous tests, whether or not we have scanned the document should be
irrelevant, because scanning should be automatically triggered by editing.

            pageKey 'left' for i in [1..5]
            pageKey 'left', 'shift' for i in [1..3]
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ONE#{open 0}TWO#{close 0}THREE</p>"
            pageExpects getOpen( 0 ), 'toBeSimilarHTML', open 0
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageExpects getGroup( 3 ), 'toBeUndefined',
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getOpen( 0 ), 'toBeSimilarHTML', open 0
            pageExpects getGroup( 1 ), 'toBeUndefined',
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageExpects getGroup( 3 ), 'toBeUndefined',

If we nest that in a group, then the first two IDs should point to stored
Group instances, but any thereafter should not.  Again, scanning should not
change the results.

            pageKey 'home'
            pageKey 'right' for i in [1..2]
            pageKey 'right', 'shift' for i in [1..7]
            pageCommand 'me'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ON#{open 1}E#{open 0}TWO#{close 0}T#{close 1}HREE</p>"
            pageExpects getOpen( 0 ), 'toBeSimilarHTML', open 0
            pageExpects getOpen( 1 ), 'toBeSimilarHTML', open 1
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageExpects getGroup( 3 ), 'toBeUndefined',
            pageExpects getGroup( 4 ), 'toBeUndefined',
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects getOpen( 0 ), 'toBeSimilarHTML', open 0
            pageExpects getOpen( 1 ), 'toBeSimilarHTML', open 1
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageExpects getGroup( 3 ), 'toBeUndefined',
            pageExpects getGroup( 4 ), 'toBeUndefined',

If we delete one of the inner groupers, then scanning the document will
cause its partner to be deleted, and only the index 1 will point to a stored
Group instance.  We have no need to scan the document manually, because
pressing backspace will do it automatically.

            pageKey 'home'
            pageKey 'right' for i in [1..5]
            pageKey 'backspace'
            pageExpects allContent, 'toBeSimilarHTML',
                "<p>ON#{open 1}ETWOT#{close 1}HREE</p>"
            pageExpects getGroup( 0 ), 'toBeUndefined',
            pageExpects getOpen( 1 ), 'toBeSimilarHTML', open 1
            pageExpects getGroup( 2 ), 'toBeUndefined',
            pageExpects getGroup( 3 ), 'toBeUndefined',
            pageExpects getGroup( 4 ), 'toBeUndefined',

### builds group hierarchy correctly

We create a document with many nested groups, then check to see if the
Groups plugin has correctly constructed a hierarchy of them in memory.  We
will test both the `topLevel` field and the `ids()` member function of the
`Groups` class.

        it 'builds group hierarchy correctly', inPage ->

We create a simple function that turns the group hierarchy into a simplified
JSON structure that can be transported back from the headless testing
browser into this environment for comparisons.

            getTree = ->
                tree = ( group ) ->
                    id : group.id()
                    children : ( tree g for g in group.children )
                tree g for g in tinymce.activeEditor.Groups.topLevel

Ensure that the group hierarchy, at first, is completely empty.

            pageExpects ( -> tinymce.activeEditor.Groups.topLevel ),
                'toEqual', [ ]
            pageExpects getTree, 'toEqual', [ ]
            pageExpects ( -> tinymce.activeEditor.Groups.ids() ), 'toEqual',
                [ ]

We now create a function that will quickly create a nested group structure
based on a readable English description that looks like the document we want
to create.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter

We use it to create a document with a trivial group hierarchy.

            createHierarchy '[text]'

Verify that a one-group hierarchy has been created.

            pageExpects getTree, 'toEqual', [ id : 0, children : [ ] ]
            pageExpects ( -> tinymce.activeEditor.Groups.ids() ), 'toEqual',
                [ 0 ]

Verify that calling `ids()` repeatedly returns the exact same object, thus
demonstrating that it is re-using the result from cache.

            pageExpects -> tinymce.activeEditor.Groups.ids() is \
                           tinymce.activeEditor.Groups.ids()

Clear out the document and verify that the hierarchy is empty again.

            pageDo -> tinymce.activeEditor.setContent ''
            pageExpects ( -> tinymce.activeEditor.Groups.topLevel ),
                'toEqual', [ ]
            pageExpects getTree, 'toEqual', [ ]
            pageExpects ( -> tinymce.activeEditor.Groups.ids() ), 'toEqual',
                [ ]

Verify that calling `ids()` repeatedly returns the exact same object, thus
demonstrating that it is re-using the result from cache.

            pageExpects -> tinymce.activeEditor.Groups.ids() is \
                           tinymce.activeEditor.Groups.ids()

Now create a document with a nontrivial group hierarchy.

            createHierarchy 'initial text
                [ start of big group [ foo [ bar ] baz ] [ 1 ] [ 2 ] ]
                [ a second [ group after ] the first big one ]
                final text'

Verify that a deep hierarchy has been created that matches the text above.

            pageExpects getTree, 'toEqual', [
                {
                    id : 0
                    children : [
                        { id : 1, children : [ id : 2, children : [ ] ] }
                        { id : 3, children : [ ] }
                        { id : 4, children : [ ] }
                    ]
                }
                { id : 5, children : [ id : 6, children : [ ] ] }
            ]
            pageExpects ( -> tinymce.activeEditor.Groups.ids() ), 'toEqual',
                [ 0, 1, 2, 3, 4, 5, 6 ]

Verify that calling `ids()` repeatedly returns the exact same object, thus
demonstrating that it is re-using the result from cache.

            pageExpects -> tinymce.activeEditor.Groups.ids() is \
                           tinymce.activeEditor.Groups.ids()

## Hierarchy queries

Now we test those functions that build on the ability to construct a groups
hierarchy, by querying that already-constructed hierarchy in various ways.

    phantomDescribe 'Hierarchy queries', './app/app.html', ->

### can convert groupers to groups

We create a document with many nested groups, then query various parts of
the resulting hierarchy.  We aim to test the `grouperToGroup` function in
the Groups plugin.

        it 'can convert groupers to groups', inPage ->

Construct the same simple hierarchy as in the previous test.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'

Find its open and close groupers in the editor, and store them in global
variables for use in the tests below.

            pageDo ->
                window._test_mainParagraph =
                    tinymce.activeEditor.getBody().childNodes[0]
                window._test_open =
                    window._test_mainParagraph.childNodes[0]
                window._test_close =
                    window._test_mainParagraph.childNodes[2]

Verify that these are open and close groupers with ID 0.

            pageExpects ( -> window._test_open.outerHTML ),
                'toBeSimilarHTML', open 0
            pageExpects ( -> window._test_close.outerHTML ),
                'toBeSimilarHTML', close 0

Verify that Group 0 in the Groups hierarchy has these two elements as its
open and close groupers.

            pageExpects ( -> tinymce.activeEditor.Groups[0].open is \
                             window._test_open )
            pageExpects ( -> tinymce.activeEditor.Groups[0].close is \
                             window._test_close )

And now, what we're focusing on testing in this test:  If we ask the Groups
plugin for the group corresponding to either of those groupers, it should
give us group #0 in the hierarchy.

            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_open ) is tinymce.activeEditor.Groups[0]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_close ) is tinymce.activeEditor.Groups[0]

Verify that if we call `grouperToGroup` on some other objects, we get null.

            pageExpects ( -> tinymce.activeEditor.Groups.grouperToGroup 5 ),
                'toBeNull'
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup null
            , 'toBeNull'
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup \
                    tinymce.activeEditor.getBody()
            , 'toBeNull'
            pageExpects ->
                text = window._test_open.nextSibling
                tinymce.activeEditor.Groups.grouperToGroup text
            , 'toBeNull'

Construct the complex hierarchy as in the previous test.

            pageDo -> tinymce.activeEditor.setContent ''
            createHierarchy 'initial text
                [ start of big group [ foo [ bar ] baz ] [ 1 ] [ 2 ] ]
                [ a second [ group after ] the first big one ]
                final text'

Find a few open and close groupers in the editor, and store them in global
variables for use in the tests below.

            pageDo ->
                window._test_mainParagraph =
                    tinymce.activeEditor.getBody().childNodes[0]
                window._test_open_0 =
                    window._test_mainParagraph.childNodes[1]
                window._test_open_1 =
                    window._test_open_0.nextSibling.nextSibling
                window._test_open_2 =
                    window._test_open_1.nextSibling.nextSibling
                window._test_close_2 =
                    window._test_open_2.nextSibling.nextSibling
                all = tinymce.activeEditor.Groups.allGroupers()
                window._test_close_5 = all[all.length - 1]
                window._test_close_6 = all[all.length - 2]

Verify that these are open and close groupers with the IDs that I expect,
based on the naming convention I used above.

            pageExpects ( -> window._test_open_0.outerHTML ),
                'toBeSimilarHTML', open 0
            pageExpects ( -> window._test_open_1.outerHTML ),
                'toBeSimilarHTML', open 1
            pageExpects ( -> window._test_open_2.outerHTML ),
                'toBeSimilarHTML', open 2
            pageExpects ( -> window._test_close_2.outerHTML ),
                'toBeSimilarHTML', close 2
            pageExpects ( -> window._test_close_5.outerHTML ),
                'toBeSimilarHTML', close 5
            pageExpects ( -> window._test_close_6.outerHTML ),
                'toBeSimilarHTML', close 6

Verify that groups 0, 1, 2, 5, and 6 in the Groups hierarchy have the
open/close groupers chosen above.

            pageExpects ( -> tinymce.activeEditor.Groups[0].open is \
                             window._test_open_0 )
            pageExpects ( -> tinymce.activeEditor.Groups[1].open is \
                             window._test_open_1 )
            pageExpects ( -> tinymce.activeEditor.Groups[2].open is \
                             window._test_open_2 )
            pageExpects ( -> tinymce.activeEditor.Groups[2].close is \
                             window._test_close_2 )
            pageExpects ( -> tinymce.activeEditor.Groups[5].close is \
                             window._test_close_5 )
            pageExpects ( -> tinymce.activeEditor.Groups[6].close is \
                             window._test_close_6 )

And now, what we're focusing on testing in this test:  If we ask the Groups
plugin for the group corresponding to any of those groupers, it should
give us the correct group in the hierarchy.

            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_open_0 ) is tinymce.activeEditor.Groups[0]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_open_1 ) is tinymce.activeEditor.Groups[1]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_open_2 ) is tinymce.activeEditor.Groups[2]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_close_2 ) is tinymce.activeEditor.Groups[2]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_close_5 ) is tinymce.activeEditor.Groups[5]
            pageExpects ->
                tinymce.activeEditor.Groups.grouperToGroup(
                    window._test_close_6 ) is tinymce.activeEditor.Groups[6]

Verify that if we call `grouperToGroup` on some other objects, we get null.

            pageExpects ->
                text = window._test_open_0.nextSibling
                tinymce.activeEditor.Groups.grouperToGroup text
            , 'toBeNull'
            pageExpects ->
                paragraph = window._test_open_0.parentNode
                tinymce.activeEditor.Groups.grouperToGroup paragraph
            , 'toBeNull'

### can convert any node to a group

We create a document with many nested groups, then query various parts of
the resulting hierarchy.  We aim to test the `groupAboveNode` function in
the Groups plugin.

        it 'can convert any node to a group', inPage ->

Construct the same simple hierarchy as in the previous two tests.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'

Find a few nodes in the editor, and store them in global variables for use
in the tests below.

            pageDo ->
                window._test_mainParagraph =
                    tinymce.activeEditor.getBody().childNodes[0]
                window._test_open = window._test_mainParagraph.childNodes[0]
                window._test_text = window._test_open.nextSibling
                window._test_close = window._test_text.nextSibling

Verify that the group containing the whole body is null.

            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode \
                    window._test_mainParagraph
            , 'toBeNull'

Verify that the group containing any of the other three nodes is the one
group in the document.

            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_open ).id()
            , 'toEqual', 0
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_text ).id()
            , 'toEqual', 0
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_close ).id()
            , 'toEqual', 0

Construct the complex hierarchy as in the previous test.

            pageDo -> tinymce.activeEditor.setContent ''
            createHierarchy 'initial text
                [ start of big group [ foo [ bar ] baz ] [ 1 ] [ 2 ] ]
                [ a second [ group after ] the first big one ]
                final text'

Find a few nodes in the editor, and store them in global variables for use
in the tests below.

            pageDo ->
                window._test_mainParagraph =
                    tinymce.activeEditor.getBody().childNodes[0]
                window._test_open_0 =
                    window._test_mainParagraph.childNodes[1]
                window._text_in_0 = window._test_open_0.nextSibling
                window._test_open_1 = window._text_in_0.nextSibling
                window._text_in_1 = window._test_open_1.nextSibling
                window._test_open_2 = window._text_in_1.nextSibling
                window._text_before_0 = window._test_open_0.previousSibling
                window._text_after_0 =
                    tinymce.activeEditor.Groups.grouperToGroup(
                        window._test_open_0 ).close.nextSibling

And now, what we're focusing on testing in this test:  If we ask the Groups
plugin for the group above any of those nodes, it should give us the correct
group in the hierarchy.

            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_open_0 ) is tinymce.activeEditor.Groups[0]
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._text_in_0 ) is tinymce.activeEditor.Groups[0]
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_open_1 ) is tinymce.activeEditor.Groups[1]
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._text_in_1 ) is tinymce.activeEditor.Groups[1]
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_open_2 ) is tinymce.activeEditor.Groups[2]
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_before_0 ) is null
            pageExpects ->
                tinymce.activeEditor.Groups.groupAboveNode(
                    window._test_after_0 ) is null

## Group attributes

Now we test the ability to store hidden attributes in groups and retrieve
them again later.

    phantomDescribe 'Group attributes', './app/app.html', ->

### support atomic values

We test to be sure we can read and write atomic values (numbers, strings,
and booleans) and read them back again.

        it 'support atomic values', inPage ->

Construct the same simple hierarchy as in the previous test.  Ensure that
Group 0 exists and Group 1 does not.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'
            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> not tinymce.activeEditor.Groups[1]?

Write a few numbers as attributes of Group 0 and be sure that you can
accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'x', 0
            pageDo -> tinymce.activeEditor.Groups[0].set 'thingy-do', 100
            pageDo -> tinymce.activeEditor.Groups[0].set 'y', -0.1698
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'x' ),
                'toEqual', 0
            pageExpects (
                -> tinymce.activeEditor.Groups[0].get 'thingy-do'
            ), 'toEqual', 100
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'y' ),
                'toEqual', -0.1698

Write a few strings as attributes of Group 0 and be sure that you can
accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'x', 'ex'
            pageDo -> tinymce.activeEditor.Groups[0].set 'speech',
                'Four score and seven years ago our fathers brought forth on
                this continent, a new nation, conceived in Liberty, and
                dedicated to the proposition that all men are created
                equal.'
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'x' ),
                'toEqual', 'ex'
            pageExpects (
                -> tinymce.activeEditor.Groups[0].get 'speech'
            ), 'toEqual', 'Four score and seven years ago our fathers
                brought forth on this continent, a new nation, conceived in
                Liberty, and dedicated to the proposition that all men are
                created equal.'

Write a few booleans as attributes of Group 0 and be sure that you can
accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'speech', yes
            pageDo -> tinymce.activeEditor.Groups[0].set 'nay', no
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'speech' ),
                'toEqual', yes
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'nay' ),
                'toEqual', no

### support arrays

We test to be sure we can read and write non-atomic values in the form of
arrays, and read them back again.

        it 'support arrays', inPage ->

Construct the same simple hierarchy as in the previous test.  Ensure that
Group 0 exists and Group 1 does not.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'
            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> not tinymce.activeEditor.Groups[1]?

Write a few arrays of atomic values as attributes of Group 0 and be sure
that you can accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'one', [1,2,3]
            pageDo -> tinymce.activeEditor.Groups[0].set 'colors',
                [ 'red', 'green', 'blue', 'cyan', 'magenta', 'yellow' ]
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'one' ),
                'toEqual', [1,2,3]
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'colors' ),
                'toEqual',
                [ 'red', 'green', 'blue', 'cyan', 'magenta', 'yellow' ]

Write an array of arrays as an attribute of Group 0 and be sure that you can
accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'colors',
                [ [ 'red', 'green', 'blue' ],
                  [ 'cyan', 'magenta', 'yellow' ],
                  'grayscale' ]
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'colors' ),
                'toEqual',
                [ [ 'red', 'green', 'blue' ],
                  [ 'cyan', 'magenta', 'yellow' ],
                  'grayscale' ]

### support objects

We test to be sure we can read and write non-atomic values in the form of
objects, and read them back again.

        it 'support objects', inPage ->

Construct the same simple hierarchy as in the previous test.  Ensure that
Group 0 exists and Group 1 does not.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'
            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> not tinymce.activeEditor.Groups[1]?

Write a few objects with keys and values all atomic, as attributes of Group
0, and be sure that you can accurately read them back again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'obj',
                { a : 1, b : 2, c : 3 }
            pageDo -> tinymce.activeEditor.Groups[0].set 'tryNumber2',
                { someBoolean : true, someString : 'foo', someNumber : 3 }
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'obj' ),
                'toEqual', { a : 1, b : 2, c : 3 }
            pageExpects (
                -> tinymce.activeEditor.Groups[0].get 'tryNumber2'
            ), 'toEqual',
                { someBoolean : true, someString : 'foo', someNumber : 3 }

Write two complex objects that nest objects and arrays inside one another,
as attributes of Group 0, and be sure that you can accurately read them back
again.

            pageDo -> tinymce.activeEditor.Groups[0].set 'color-spaces',
                {
                    rgbColorSpace : [ 'red', 'green', 'blue' ]
                    cmyColorSpace : [ 'cyan', 'magenta', 'yellow' ]
                    anotherColorSpace : 'grayscale'
                }
            pageDo -> tinymce.activeEditor.Groups[0].set 'randomData',
                [
                    { x : 'one', y : -2, z : 0.03 }
                    { title : 'Prof.', first : 'James', last : 'Moriarity' }
                ]
            pageExpects (
                -> tinymce.activeEditor.Groups[0].get 'color-spaces'
            ),
                'toEqual',
                {
                    rgbColorSpace : [ 'red', 'green', 'blue' ]
                    cmyColorSpace : [ 'cyan', 'magenta', 'yellow' ]
                    anotherColorSpace : 'grayscale'
                }
            pageExpects (
                -> tinymce.activeEditor.Groups[0].get 'randomData'
            ),
                'toEqual',
                [
                    { x : 'one', y : -2, z : 0.03 }
                    { title : 'Prof.', first : 'James', last : 'Moriarity' }
                ]

### reject bad keys

We test to be sure that when we use invalid keys (i.e., keys containing some
character that is neither alphanumeric nor a hyphen) that there is no change
to the open grouper's HTML code, and thus no change to its attributes.

        it 'reject bad keys', inPage ->

Construct the same simple hierarchy as in the previous test.  Ensure that
Group 0 exists and Group 1 does not.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[text]'
            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> not tinymce.activeEditor.Groups[1]?

Attempt to write to a few invalid keys, and ensure that after every stop,
the result is the same open grouper we had at the start.  Begin by
establishing a baseline.

            check = ->
                pageExpects (
                    -> tinymce.activeEditor.Groups[0].open.outerHTML
                ), 'toBeSimilarHTML', grouper 'open', 0
            check()
            pageDo -> tinymce.activeEditor.Groups[0].set 'in valid', 0
            check()
            pageDo -> tinymce.activeEditor.Groups[0].set { }, 0
            check()
            pageDo -> tinymce.activeEditor.Groups[0].set 'under_score', 0
            check()
            pageDo -> tinymce.activeEditor.Groups[0].set '2+3', 0
            check()
            pageDo -> tinymce.activeEditor.Groups[0].set '13.45', 0
            check()

### distinguish among multiple groups

For simplicity, all the previous tests used only one group.  Now we verify
that when setting attributes on one group, it does not impact any other
group in the document.

        it 'distinguish among multiple groups', inPage ->

We create a few groups, set a few attributes on some subset of them, and
verify that those same attributes did not appear on any of the groups other
than the ones on which they were set.

Construct a simple hierarchy, but this time not the same as in the previous
tests.  Ensure that Groups 0 through 3 exist, and Group 4 does not.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy 'A [b] [c[d]e] and then [eff]'
            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> tinymce.activeEditor.Groups[1]?
            pageExpects -> tinymce.activeEditor.Groups[2]?
            pageExpects -> tinymce.activeEditor.Groups[3]?
            pageExpects -> not tinymce.activeEditor.Groups[4]?

Set one attribute in Group 0, two in Group 1, and another in Group 3.

            pageDo -> tinymce.activeEditor.Groups[0].set 'one', [1,2,3]
            pageDo -> tinymce.activeEditor.Groups[1].set 'X', [ [ [ ] ] ]
            pageDo -> tinymce.activeEditor.Groups[1].set 'Y-2', 'Han Solo'
            pageDo -> tinymce.activeEditor.Groups[3].set 'thing', { 1 : 9 }

Verify that all were set correctly.

            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'one' ),
                'toEqual', [1,2,3]
            pageExpects ( -> tinymce.activeEditor.Groups[1].get 'X' ),
                'toEqual', [ [ [ ] ] ]
            pageExpects ( -> tinymce.activeEditor.Groups[1].get 'Y-2' ),
                'toEqual', 'Han Solo'
            pageExpects ( -> tinymce.activeEditor.Groups[3].get 'thing' ),
                'toEqual', { 1 : 9 }

Verify that any of those same keys, queried on any group other than the one
one which it was set, yields undefined as the result.

            pageExpects ( -> tinymce.activeEditor.Groups[1].get 'one' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[2].get 'one' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[3].get 'one' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'X' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[2].get 'X' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[3].get 'X' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'Y-2' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[2].get 'Y-2' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[3].get 'Y-2' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[0].get 'thing' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[1].get 'thing' ),
                'toBeUndefined'
            pageExpects ( -> tinymce.activeEditor.Groups[2].get 'thing' ),
                'toBeUndefined'

### trigger document change events

This test verifies that modifying a group object counts as a modification to
the document, from TinyMCE's point of view.  That is, "change" events should
be triggered, and the document should be marked dirty.

        it 'trigger document change events', inPage ->

We begin by installing a change handler that will set a global variable
whenever the editor's "change" event is called.  This way we can verify that
it has been called when we expect.

            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.on 'change', ->
                    window.changeEventCalled = yes

Verify that, initially, the document is not dirty.

            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()

We create a few groups and set a few attributes on some subset of them.  I
re-use here the same setup as in the previous test.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy 'A [b] [c[d]e] and then [eff]'

Verify that, after that insertion, the document has become dirty.

            pageExpects -> window.changeEventCalled
            pageExpects -> tinymce.activeEditor.isDirty()

Mark the document as clean at this point, to create a new baseline.

            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.isNotDirty = yes
            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()

Now we will set attributes on some of those groups, again, re-using the same
configuration as in the previous test.

            pageDo -> tinymce.activeEditor.Groups[0].set 'one', [1,2,3]

Verify that, after that insertion, the document has become dirty.

            pageExpects -> window.changeEventCalled
            pageExpects -> tinymce.activeEditor.isDirty()

Mark the document as clean at this point, to create a new baseline.

            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.isNotDirty = yes
            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()

Repeat the same test, but now on a different attribute of a different group.

            pageDo -> tinymce.activeEditor.Groups[1].set 'X', [ [ [ ] ] ]

Verify the same things, then reset the changed/dirty indicators, as before.

            pageExpects -> window.changeEventCalled
            pageExpects -> tinymce.activeEditor.isDirty()
            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.isNotDirty = yes
            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()

Repeat the same test, but now on a different attribute of a different group.

            pageDo -> tinymce.activeEditor.Groups[1].set 'Y-2', 'Han Solo'

Verify the same things, then reset the changed/dirty indicators, as before.

            pageExpects -> window.changeEventCalled
            pageExpects -> tinymce.activeEditor.isDirty()
            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.isNotDirty = yes
            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()

Repeat the same test, but now on a different attribute of a different group.

            pageDo -> tinymce.activeEditor.Groups[3].set 'thing', { 1 : 9 }

Verify the same things, then reset the changed/dirty indicators, as before.

            pageExpects -> window.changeEventCalled
            pageExpects -> tinymce.activeEditor.isDirty()
            pageDo ->
                window.changeEventCalled = no
                tinymce.activeEditor.isNotDirty = yes
            pageExpects -> not window.changeEventCalled
            pageExpects -> not tinymce.activeEditor.isDirty()
