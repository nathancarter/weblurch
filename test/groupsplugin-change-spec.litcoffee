
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

This test is not yet done being written.  It is a stub for now, with the
following note that will be replaced with real test code later.

            console.log 'test not yet complete'

### groupsTouchingRange() must work correctly

These tests cover several use cases of the `groupsTouchingRange()` function.

        it 'groupsTouchingRange() must work correctly', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

This test is not yet done being written.  It is a stub for now, with the
following note that will be replaced with real test code later.

            console.log 'test not yet complete'

### rangeChanged() must work correctly

These tests cover several use cases of the `rangeChanged()` function.

        it 'rangeChanged() must work correctly', inPage ->

Verify that there have not yet been any recently changed groups.

            pageExpects ( -> recents() ), 'toEqual', [ ]

This test is not yet done being written.  It is a stub for now, with the
following note that will be replaced with real test code later.

            console.log 'test not yet complete'

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
