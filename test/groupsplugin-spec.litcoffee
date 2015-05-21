
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

    grouper = ( type, id ) ->
        "<img id=\"#{type}#{id}\" class=\"grouper me\"
          src=\"images/red-bracket-#{type}.png\" alt=\"\">"
    open = ( id ) -> grouper 'open', id
    close = ( id ) -> grouper 'close', id

## Groups plugin

Start with a simple test to verify that the plugin has been loaded.

    phantomDescribe 'Groups plugin', './app/index.html', ->

### should be installed

Just verify that the active TinyMCE editor has a Groups plugin.

        it 'should be installed', inPage ->
            pageExpects -> tinymce.activeEditor.Groups

## Group class

Some aspects of this class can be tested independently of the editor, so we
do so here, to do some tests in the simplest context possible.

    phantomDescribe 'Group class', './app/index.html', ->

First, a very simple test of the constructor, just ensuring that it's
recording its two inputs.

        it 'is constructible from any two inputs', inPage ->
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

        it 'can look up its ID from its open grouper', inPage ->
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

        it 'returns a null ID if invalid open grouper', inPage ->
            pageDo ->
                htmlToNode = ( html ) ->
                    container = document.createElement 'span'
                    container.innerHTML = html
                    container.childNodes[0]
                open = 10
                close = htmlToNode grouperHTML 'test', 'close', 5
                window._tmp = new Group open, close
            pageExpects ( -> window._tmp.id() ), 'toBeNull'

## ID tracking methods

Next, test the routines that track which IDs have been used and which
remain free.

    phantomDescribe 'Groups plugin ID tracking', './app/index.html', ->

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

    phantomDescribe 'Grouping routines', './app/index.html', ->

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
                 <p>#{close 1}<br></p>"

## Group hierarchy

Now we test the meat of the Groups plugin, those routines that maintain the
integrity of groups and deal with the group hierarchy.

    phantomDescribe 'Group hierarchy', './app/index.html', ->

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
