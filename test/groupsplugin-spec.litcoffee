
# Tests of Groups plugin for TinyMCE Editor

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage, pageWaitFor,
      pageExpectsError, pageType, pageKey } = require './phantom-utils'

<font color='red'>Right now this specification file is almost a stub.  It
will be enhanced later with real tests of the Groups plugin.  For now, it
just does one or two simple tests that can be replaced later.</font>

## Groups plugin

This is a very simple test that will be extended later.

    phantomDescribe 'TinyMCE Groups plugin',
    './app/index.html', ->

### should be installed

Just verify that the active TinyMCE editor has a Groups plugin.

        it 'should be installed', inPage ->
            pageExpects -> tinymce.activeEditor.Groups

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

### wraps selections in groups

This auxiliary function creates the HTML code for a grouper, for use in the
subsequent tests.

        grouper = ( type, id ) ->
            "<img id=\"#{type}#{id}\" class=\"grouper me\" src=\"images/red-bracket-#{type}.png\" alt=\"\" />"

We test here the `groupCurrentSelection()` method of the Groups plugin.  It
does exactly what its name says; it wraps the current selection in a group.
We test here that this happens correctly in several situations.

        it 'wraps selections in groups', inPage ->
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', ''
            pageType 'ONETWOTHR3'
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', '<p>ONETWOTHR3</p>'
            pageKey pageKey.left for i in [1..4]
            pageKey pageKey.left, pageKey.shift for i in [1..3]
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', '<p>ONETWOTHR3</p>'
            pageExpects ( -> tinymce.activeEditor.selection.getContent() ),
                'toEqual', 'TWO'
            pageDo -> tinymce.activeEditor.buttons.me.onclick()
            pageExpects ( -> tinymce.activeEditor.getContent() ), 'toEqual',
                "<p>ONE#{grouper 'open', 0}TWO#{grouper 'close', 0}THR3</p>"
