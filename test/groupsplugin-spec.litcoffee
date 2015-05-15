
# Tests of Groups plugin for TinyMCE Editor

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage, pageWaitFor,
      pageExpectsError, pageType, pageKey } = require './phantom-utils'

These auxiliary function creates the HTML code for groupers, for use in the
tests below.

    grouper = ( type, id ) ->
        "<img id=\"#{type}#{id}\" class=\"grouper me\" src=\"images/red-bracket-#{type}.png\" alt=\"\" />"
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

            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', ''
            pageType 'ONETWOTHREE'
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', '<p>ONETWOTHREE</p>'

Highlight the word TWO and wrap it in an ME Group.  Verify that this works.

            pageKey pageKey.left for i in [1..5]
            pageKey pageKey.left, pageKey.shift for i in [1..3]
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', '<p>ONETWOTHREE</p>'
            pageExpects ( -> tinymce.activeEditor.selection.getContent() ),
                'toEqual', 'TWO'
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ONE#{open 0}TWO#{close 0}THREE</p>"

Highlight the existing group plus two characters on either side.  Wrap it in
another group and verify that this works.

            pageKey pageKey.home
            pageKey pageKey.right for i in [1..2]
            pageKey pageKey.right, pageKey.shift for i in [1..7]
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ON#{open 1}E#{open 0}TWO#{close 0}T#{close 1}HREE</p>"

### wrap selections in groups across elements

This function is much like the previous, except we put the two ends of the
cursor in different HTML elements, to be sure the result comes out as we
desire.

        it 'wrap selections in groups across elements', inPage ->

We will make use of the following auxiliary function for simplifying HTML
strings.

            shtml = ( html ) ->
                html = html.replace />\s*</g, '><'
                old = ''
                while html isnt old
                    old = html
                    html = html.replace \
                        /<span[^>]+Apple-style-span[^>]+>(.*?)<\/span>/g,
                        '$1'
                html
            pageDo -> window.shtml = ( html ) ->
                html = html.replace />\s*</g, '><'
                old = ''
                while html isnt old
                    old = html
                    html = html.replace \
                        /<span[^>]+Apple-style-span[^>]+>(.*?)<\/span>/g,
                        '$1'
                html

Ensure the editor is empty, then insert some complex content.

            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', ''
            pageDo -> tinymce.activeEditor.setContent shtml \
                '<table>
                   <tbody>
                     <tr>
                       <td id="left">2 words</td>
                       <td>even more</td>
                     </tr>
                   </tbody>
                 </table>'
            pageExpects ( -> shtml tinymce.activeEditor.getContent() ),
                'toEqual', shtml \
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

            pageDo -> tinymce.activeEditor.selection.setCursorLocation \
                tinymce.activeEditor.getDoc().getElementById( 'left' ) \
                .childNodes[0], 2
            pageKey pageKey.right, pageKey.shift for i in [1..10]
            pageExpects ( -> tinymce.activeEditor.selection.getContent() ),
                'toEqual', 'wordseven'
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> shtml tinymce.activeEditor.getContent() ),
                'toEqual', shtml \
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

            pageDo ->
                tinymce.activeEditor.selection.select \
                    tinymce.activeEditor.getBody(), no
                tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> shtml tinymce.activeEditor.getContent() ),
                'toEqual', shtml \
                "<p>#{open 1}</p>
                 <table>
                   <tbody>
                     <tr>
                       <td id=\"left\">2 #{open 0}words</td>
                       <td>even#{close 0} more</td>
                     </tr>
                   </tbody>
                 </table>
                 <p>#{close 1}<br /></p>"

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

            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 0 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 0 ]

In an editor with content but no groups, the result should be the same.

            pageType 'ONETWOTHREE'
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 0 ]
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 0 ]

If we put a group in the document, then the first ID should be used up on
that group.

            pageKey pageKey.left for i in [1..5]
            pageKey pageKey.left, pageKey.shift for i in [1..3]
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ONE#{open 0}TWO#{close 0}THREE</p>"
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 1 ]

If we nest that in a group, then the first two IDs should be used up.

            pageKey pageKey.home
            pageKey pageKey.right for i in [1..2]
            pageKey pageKey.right, pageKey.shift for i in [1..7]
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ON#{open 1}E#{open 0}TWO#{close 0}T#{close 1}HREE</p>"
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 2 ]

If we delete one of the inner groupers, then scanning the document will
cause its partner to be deleted, and the correct list of free IDs to be
created.

            pageKey pageKey.home
            pageKey pageKey.right for i in [1..5]
            pageKey pageKey.backspace
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ON#{open 1}ETWO#{close 0}T#{close 1}HREE</p>"
            pageDo -> tinymce.activeEditor.Groups.scanDocument()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ON#{open 1}ETWOT#{close 1}HREE</p>"
            pageExpects ( -> tinymce.activeEditor.Groups.freeIds ),
                'toEqual', [ 0, 2 ]
