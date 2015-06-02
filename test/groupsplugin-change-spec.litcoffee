
# Tests of change events in Groups plugin for TinyMCE Editor

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

The following function will be called before all the tests below.

    setup = ->

First, it installs a dummy group type whose sole purpose is to log the calls
made to its `contentsChanged()` method, to help us run our tests.

        recentlyChangedGroups = [ ]
        window.recents = -> recentlyChangedGroups
        window.clearRecents = -> recentlyChangedGroups = [ ]
        tinymce.activeEditor.Groups.addGroupType 'logger',
            text : 'Logger'
            contentsChanged : ( group ) -> recentlyChangedGroups.push group

Second, it defines the `htmlToNode` function, which is handy for converting
a string of HTML text into actual DOM nodes, in the TinyMCE editor's
iframe's document.

        window.htmlToNode = ( html ) ->
            container = tinymce.activeEditor.getDoc().createElement 'span'
            container.innerHTML = html
            container.childNodes[0]

## Change members in Group class

    phantomDescribe 'Change members in Group class', './app/index.html', ->
        beforeEach -> pageDo setup

### should call contentsChanged() upon construction

New instances should fire `contentsChanged()` immediately upon construction.

        it 'should call contentsChanged() on construction', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

Construct several groups of this dummy type.

            pageDo ->
                open = htmlToNode grouperHTML 'logger', 'open', 0
                close = htmlToNode grouperHTML 'logger', 'close', 0
                window._tmp0 = new Group open, close, null
                open = htmlToNode grouperHTML 'logger', 'open', 1
                close = htmlToNode grouperHTML 'logger', 'close', 1
                window._tmp1 = new Group open, close, null
                open = htmlToNode grouperHTML 'logger', 'open', 2
                close = htmlToNode grouperHTML 'logger', 'close', 2
                window._tmp2 = new Group open, close, null

Verify that each of them has resulted in a call to `contentsChanged()` in
the group type.

            pageExpects ( -> recents().length ), 'toEqual', 3
            pageExpects -> recents()[0] is _tmp0
            pageExpects -> recents()[1] is _tmp1
            pageExpects -> recents()[2] is _tmp2

### should fire a change event for attribute changes

Instances should fire editor change events when their attributes are changed
with `set()` calls.

        it 'should fire a change event for attribute changes', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

Construct two groups, then clear the log messages, because the constructors
will store entries in the log (as verified in the previous test).  Verify
that the log is empty.

            pageDo ->
                open = htmlToNode grouperHTML 'logger', 'open', 0
                close = htmlToNode grouperHTML 'logger', 'close', 0
                window._tmp0 = new Group open, close, null
                open = htmlToNode grouperHTML 'logger', 'open', 1
                close = htmlToNode grouperHTML 'logger', 'close', 1
                window._tmp1 = new Group open, close, null
                clearRecents()
            pageExpects ( -> recents() ), 'toEqual', [ ]

Change a few attributes on the two groups, and ensure that after each
change, the log has had an entry added for that group.

            pageDo -> _tmp0.set 'example', 5
            pageExpects ( -> recents().length ), 'toEqual', 1
            pageExpects -> recents()[0] is _tmp0
            pageDo -> _tmp1.set 'another', { a : -300, b : [ 'smile' ] }
            pageExpects ( -> recents().length ), 'toEqual', 2
            pageExpects -> recents()[0] is _tmp0
            pageExpects -> recents()[1] is _tmp1
            pageDo -> _tmp0.set 'non-example', -5
            pageExpects ( -> recents().length ), 'toEqual', 3
            pageExpects -> recents()[0] is _tmp0
            pageExpects -> recents()[1] is _tmp1
            pageExpects -> recents()[2] is _tmp0

### should propagate contentsChanged() to ancestors

Whenever `contentsChanged()` is called in a group, it should automatically
call the same function in parent, grandparent, etc. groups.

        it 'should propagate contentsChanged() to ancestors', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

Create a group in the editor and fill it with text and an inner group.

            pageCommand 'logger'
            pageType 'text before inner group'
            pageCommand 'logger'
            pageType 'text inside inner group'
            pageKey 'right'
            pageType 'text after inner group'

This will, of course, have caused a great number of change events.  Verify
this, then clear them out.

            pageExpects ( -> recents().length ), 'toBeGreaterThan', 0
            pageDo -> clearRecents()

Verify that there are two groups, and that the second is a child of the
first.

            pageExpects -> tinymce.activeEditor.Groups[0]?
            pageExpects -> tinymce.activeEditor.Groups[1]?
            pageExpects -> not tinymce.activeEditor.Groups[2]?
            pageExpects ->
                tinymce.activeEditor.Groups[0].children.length
            , 'toEqual', 1
            pageExpects ->
                tinymce.activeEditor.Groups[0].children[0] is \
                    tinymce.activeEditor.Groups[1]
            pageExpects ->
                tinymce.activeEditor.Groups[1].parent is \
                    tinymce.activeEditor.Groups[0]

Make a change to an attribute of the inner group, and verify that this also
causes a change call in the outer group.

            pageExpects ( -> recents() ), 'toEqual', [ ]
            pageDo -> tinymce.activeEditor.Groups[1].set 'x', 'y'
            pageExpects ( -> recents().length ), 'toEqual', 2
            pageExpects -> recents()[0] is tinymce.activeEditor.Groups[1]
            pageExpects -> recents()[1] is tinymce.activeEditor.Groups[0]

## Change support in Groups plugin

    phantomDescribe 'Change support in Groups plugin', './app/index.html',
    ->
        beforeEach -> pageDo setup

### grouperIndexOfRangeEndpoint() must work correctly

These tests cover several use cases of the `grouperIndexOfRangeEndpoint()`
function.

        it 'grouperIndexOfRangeEndpoint() must work correctly', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

Construct the pattern of open and close groupers `[[[][]]][]` in the editor.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[[[][]]][]'

Define two convenience functions for calling the
`grouperIndexOfRangeEndpoint` function on the editor's current selection,
for either the left or right end of that selection.

            testLeft = ->
                E = tinymce.activeEditor
                E.Groups.grouperIndexOfRangeEndpoint E.selection.getRng(),
                    yes
            testRight = ->
                E = tinymce.activeEditor
                E.Groups.grouperIndexOfRangeEndpoint E.selection.getRng(),
                    no

Cursor at the far right should give left 9 and right 9.

            pageExpects testLeft, 'toEqual', 9
            pageExpects testRight, 'toEqual', 9

Cursor at the far left should give left -1 and right -1.

            pageKey 'home'
            pageExpects testLeft, 'toEqual', -1
            pageExpects testRight, 'toEqual', -1

Cursor at position 1 should give left 0 and right 0.

            pageKey 'right'
            pageExpects testLeft, 'toEqual', 0
            pageExpects testRight, 'toEqual', 0

Cursor at position 2 should give left 1 and right 1.

            pageKey 'right'
            pageExpects testLeft, 'toEqual', 1
            pageExpects testRight, 'toEqual', 1

Cursor at position 3 should give left 2 and right 2.

            pageKey 'right'
            pageExpects testLeft, 'toEqual', 2
            pageExpects testRight, 'toEqual', 2

Cursor at position 4 should give left 3 and right 3.

            pageKey 'right'
            pageExpects testLeft, 'toEqual', 3
            pageExpects testRight, 'toEqual', 3

Cursor at position 8 should give left 7 and right 7.

            pageKey 'right'
            pageKey 'right'
            pageKey 'right'
            pageKey 'right'
            pageExpects testLeft, 'toEqual', 7
            pageExpects testRight, 'toEqual', 7

Cursor spanning positions 0 through 3 should give left -1 and right 2.

            pageKey 'home'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageExpects testLeft, 'toEqual', -1
            pageExpects testRight, 'toEqual', 2

Cursor spanning positions 3 through 5 should give left 2 and right 4.

            pageKey 'right'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageExpects testLeft, 'toEqual', 2
            pageExpects testRight, 'toEqual', 4

Cursor spanning positions 6 through 9 should give left 5 and right 8.

            pageKey 'right'
            pageKey 'right'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageExpects testLeft, 'toEqual', 5
            pageExpects testRight, 'toEqual', 8

### groupsTouchingRange() must work correctly

These tests cover several use cases of the `groupsTouchingRange()` function.
They also serve as a proxy for the `rangeChanged()` function, because it is
simply a loop over the results of `groupsTouchingRange()`.

        it 'groupsTouchingRange() must work correctly', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

Construct the pattern of open and close groupers `[[[][]]][]` in the editor.

            createHierarchy = ( description ) ->
                for letter in description
                    switch letter
                        when '[' then pageCommand 'me'
                        when ']' then pageKey 'right'
                        else pageType letter
            createHierarchy '[[[][]]][]'

Create a convenience function for computing and storing in a global variable
the set of groups touching the current cursor selection.

            computeGroupsTouching = ->
                pageDo ->
                    window._tmp =
                        tinymce.activeEditor.Groups.groupsTouchingRange \
                            tinymce.activeEditor.selection.getRng()

Cursor at the far right should give an empty list.

            computeGroupsTouching()
            pageExpects ( -> _tmp ), 'toEqual', [ ]

Cursor at the far left should give an empty list.

            pageKey 'home'
            computeGroupsTouching()
            pageExpects ( -> _tmp ), 'toEqual', [ ]

Cursor at position 1 should give group 0.

            pageKey 'right'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 1
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[0]

Cursor at position 2 should give groups 1 and 0, in that order.

            pageKey 'right'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 2
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[0]

Cursor at position 3 should give groups 2, 1, and 0, in that order.

            pageKey 'right'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 3
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[2]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[2] is tinymce.activeEditor.Groups[0]

Cursor at position 4 should give groups 1 and 0, in that order.

            pageKey 'right'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 2
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[0]

Cursor at position 8 should give an empty list.

            pageKey 'right'
            pageKey 'right'
            pageKey 'right'
            pageKey 'right'
            computeGroupsTouching()
            pageExpects ( -> _tmp ), 'toEqual', [ ]

Cursor spanning positions 0 through 3 should give groups 2, 1, and 0, in
that order.

            pageKey 'home'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 3
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[2]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[2] is tinymce.activeEditor.Groups[0]

Cursor spanning positions 3 through 5 should give groups 2, 3, 1, and 0, in
that order.

            pageKey 'right'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 4
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[2]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[3]
            pageExpects -> _tmp[2] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[3] is tinymce.activeEditor.Groups[0]

Cursor spanning positions 6 through 9 should give groups 1, 0, and 4, in
that order.

            pageKey 'right'
            pageKey 'right'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            pageKey 'right', 'shift'
            computeGroupsTouching()
            pageExpects ( -> _tmp.length ), 'toEqual', 3
            pageExpects -> _tmp[0] is tinymce.activeEditor.Groups[1]
            pageExpects -> _tmp[1] is tinymce.activeEditor.Groups[0]
            pageExpects -> _tmp[2] is tinymce.activeEditor.Groups[4]

### changes in the editor must trigger rangeChanged()

Typing, etc. in the editor must trigger a call to the `rangeChanged()`
function in the Groups plugin, which then triggers appropriate calls to the
`contentsChanged()` functions in all groups that touch the range.

        it 'changes in the editor must trigger rangeChanged()', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

This test is not yet done being written.  It is a stub for now, with the
following note that will be replaced with real test code later.

            console.log 'test not yet complete'
