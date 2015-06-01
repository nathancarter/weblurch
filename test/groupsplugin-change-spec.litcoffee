
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

## Change members in Group class

    phantomDescribe 'Change members in Group class', './app/index.html', ->

### should call contentsChanged() upon construction

New instances should fire `contentsChanged()` immediately upon construction.

        it 'should call contentsChanged() on construction', inPage ->
            console.log 'test not yet written'

### should fire a change event for attribute changes

Instances should fire editor change events when their attributes are changed
with `set()` calls.

        it 'should fire a change event for attribute changes', inPage ->
            console.log 'test not yet written'

### should propagate contentsChanged() to ancestors

Whenever `contentsChanged()` is called in a group, it should automatically
call the same function in parent, grandparent, etc. groups.

        it 'should propagate contentsChanged() to ancestors', inPage ->
            console.log 'test not yet written'

## Change support in Groups plugin

    phantomDescribe 'Change support in Groups plugin', './app/index.html',
    ->

### grouperIndexOfRangeEndpoint() must work correctly

These tests cover several use cases of the `grouperIndexOfRangeEndpoint()`
function.

        it 'grouperIndexOfRangeEndpoint() must work correctly', inPage ->
            console.log 'test not yet written'

### groupsTouchingRange() must work correctly

These tests cover several use cases of the `groupsTouchingRange()` function.

        it 'groupsTouchingRange() must work correctly', inPage ->
            console.log 'test not yet written'

### rangeChanged() must work correctly

These tests cover several use cases of the `rangeChanged()` function.

        it 'rangeChanged() must work correctly', inPage ->
            console.log 'test not yet written'

### changes in the editor must trigger rangeChanged()

Typing, etc. in the editor must trigger a call to the `rangeChanged()`
function in the Groups plugin, which then triggers appropriate calls to the
`contentsChanged()` functions in all groups that touch the range.

        it 'changes in the editor must trigger rangeChanged()', inPage ->
            console.log 'test not yet written'
