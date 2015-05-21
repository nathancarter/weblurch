
# Groups Plugin for [TinyMCE](http://www.tinymce.com)

This plugin adds the notion of "groups" to a TinyMCE editor.  Groups are
contiguous sections of the document, often nested but not otherwise
overlapping, that can be used for a wide variety of purposes.  This plugin
provides the following functionality for working with groups in a document.
 * defines the `Group` and `Groups` classes
 * provides methods for installing UI elements for creating and interacting
   with groups in the document
 * shows groups visually on screen in a variety of ways

It assumes that TinyMCE has been loaded into the global namespace, so that
it can access it.  It also requires [the overlay
plugin](overlayplugin.litcoffee) to be loaded in the same editor.

# Global functions

The following two global functions determine how we construct HTML to
represent group boundaries (called "groupers") and how we decipher such HTML
back into information about the groupers.

First, how to create HTML representing a grouper.  The parameters are as
follows:  `typeName` is a string naming the type of the group, which must be
[registered](#registering-group-types); `image` is the path to the image
that will be used to represent this grouper; `openClose` must be either the
string "open" or the string "close"; `id` is a nonnegative integer unique to
this group; `hide` is a boolean representing whether the grouper should be
invisible in the document.

    grouperHTML = ( typeName, openClose, id, hide = yes, image ) ->
        hide = if hide then ' hide' else ''
        image ?= "images/red-bracket-#{openClose}.png"
        "<img src='#{image}' class='grouper #{typeName}#{hide}'
              id='#{openClose}#{id}'>"
    window.grouperHTML = grouperHTML

Second, how to extract group information from a grouper.  The two pieces of
information that are most important to extract are whether the grouper is an
open grouper or close grouper, and what its ID is.  This routine extracts
both and returns them in an object with the keys `type` and `id`.  If the
data is not available in the expected format, it returns `null`.

    grouperInfo = ( grouper ) ->
        info = /^(open|close)([0-9]+)$/.exec grouper?.getAttribute? 'id'
        if info then type : info[1], id : parseInt info[2] else null
    window.grouperInfo = grouperInfo

# `Group` class

This file defines two classes, this one called `Group` and another
([below](#groups-class)) called `Groups`.  They are obviously quite
similarly named, but here is the distinction:  An instance of the `Group`
class represents a single section of text within the document that the user
has "grouped" together.  Thus each document may have zero or more such
instances.  Each editor, however, gets only one instance of the `Groups`
class, which manages all the `Group` instances in that editor's document.

## Group constructor

    class Group

The constructor takes as parameters the two DOM nodes that are its open and
close groupers (i.e., group boundary markers), respectively.  It does not
validate that these are indeed open and close grouper nodes, but just stores
them for later lookup.

        constructor: ( @open, @close ) -> # no body needed

This method returns the ID of the group, if it is available within the open
grouper.

        id: -> grouperInfo( @open )?.id ? null

<font color=red>This class is not yet complete. See [the project
plan](plan.md) for details of what's to come.</font>

The `Group` class should be accessible globally.

    window.Group = Group

# `Groups` class

We then define a class that will encapsulate all the functionality about
groups in the editor.  An instance of this class will be stored as a member
in the TinyMCE editor object.  It will keep track of many instances of the
`Group` class.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

This particular plugin defines two classes, `Group` and `Groups`.  The differences are spelled out here:
 * Only one instance of the `Groups` class exists for any given editor.
   That instance manages global functionality about groups for that editor.
   Some of its methods create instances of the `Group` class.
 * Zero or more instances of the `Group` class exist for any given editor.
   Each instance corresponds to a single group in the document in that
   editor.

If there were only one editor, this could be changing by making all instance
methods of the `Groups` class into class methods of the `Group` class.  But
since there can be more than one editor, we need separate instances of that
"global" context for each, so we use a `Groups` class to do so.

## Groups constructor

    class Groups

        constructor: ( @editor ) ->

Each editor has a mapping from valid group type names to their attributes.

            @groupTypes = {}

It also has a list of the top-level groups in the editor, which is a forest
in which each node is a group, and groups are nested as hierarchies/trees.

            @topLevel = [ ]

The object maintains a list of unique integer ids for assigning to Groups in
the editor.  The list `@freeIds` is a list `[a_1,...,a_n]` such that an id
is available if and only if it's one of the `a_i` or is greater than `a_n`.
For this reason, the list begins as `[ 0 ]`.

            @freeIds = [ 0 ]

When a free id is needed, we need a function that will give the next such
free id and then mark that id as consumed from the list.

        nextFreeId: =>
            if @freeIds.length > 1 then @freeIds.shift() else @freeIds[0]++

When an id in use becomes free, we need a function that will put it back
into the list of free ids.

        addFreeId: ( id ) =>
            if id < @freeIds[@freeIds.length-1]
                @freeIds.push id
                @freeIds.sort()

When a free id becomes used in some way other than through a call to
`nextFreeId`, we will want to be able to record that fact.  The following
function does so.

        setUsedID: ( id ) =>
            last = @freeIds[@freeIds.length-1]
            while last < id then @freeIds.push ++last
            i = @freeIds.indexOf id
            @freeIds.splice i, 1
            if i is @freeIds.length then @freeIds.push id + 1

## Registering group types

To register a new type of group, simply provide its name, as a text string,
together with an object of attributes.

The name string should only contain alphabetic characters, a through z, case
sensitive, hyphens, or underscores.  All other characters are removed. Empty
names are not allowed, which includes names that become empty when all
illegal characters have been removed.

Re-registering the same name with a new data object will overwrite the old
data object with the new one.  Data objects may have the following key-value
pairs.
 * key: `open-img`, value: a string pointing to the image file to use when
   the open grouper is visible, defaults to `'images/red-bracket-open.png'`
 * key: `close-img`, complement to the previous, defaults to
   `'images/red-bracket-close.png'`
 * any key-value pairs useful for placing the group into a menu or toolbar,
   such as the keys `text`, `context`, `tooltip`, `shortcut`, `image`,
   and/or `icon`

Clients don't actually need to call this function.  In their call to their
editor's `init` function, they can include in the large, single object
parameter a key-value pair with key `groupTypes` and value an array of
objects.  Each should have the key `name` and all the other data that this
routine needs, and they will be passed along directly.

        addGroupType: ( name, data = {} ) =>
            name = ( n for n in name when /[a-zA-Z_-]/.test n ).join ''
            @groupTypes[name] = data
            if data.hasOwnProperty 'text'
                menuData =
                    text : data.text
                    context : data.context ? 'Insert'
                    onclick : => @groupCurrentSelection name
                if data.shortcut? then menuData.shortcut = data.shortcut
                if data.icon? then menuData.icon = data.icon
                @editor.addMenuItem name, menuData
                buttonData =
                    tooltip : data.tooltip
                    onclick : => @groupCurrentSelection name
                key = if data.image? then 'image' else \
                    if data.icon? then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData

## Inserting new groups

The following method will wrap the current selection in the current editor
in groupers (i.e., group endpoints) of the given type.  The type must be on
the list of valid types registered with `addGroupType`, above, or this will
do nothing.

        groupCurrentSelection: ( type ) =>

Ignore attempts to insert invalid group types.

            if not @groupTypes.hasOwnProperty type then return

Determine whether existing groupers are hidden or not, so that we insert the
new ones to match.

            hide = ( $ @allGroupers()?[0] ).hasClass 'hide'

Create data to be used for open and close groupers, a cursor placeholder,
and the current contents of the cursor selection.

            id = @nextFreeId()
            open = grouperHTML type, 'open', id, hide,
                @groupTypes[type]['open-img']
            close = grouperHTML type, 'close', id, hide,
                @groupTypes[type]['close-img']

Wrap the current cursor selection in open/close groupers, with the cursor
placeholder after the old selection.

            sel = @editor.selection
            if sel.getStart() is sel.getEnd()

If the whole selection is within one element, then we can just replace the
selection's content with wrapped content, plus a cursor placeholder that we
immediately remove after placing the cursor back there.  We also keep track
of the close grouper element so that we can place the cursor immediatel to
its left after removing the cursor placeholder (or else the cursor may leap
to the start of the document).

                cursor = '<span id="put_cursor_here">\u200b</span>'
                content = @editor.selection.getContent()
                @editor.insertContent open + content + cursor + close
                cursor = ( $ @editor.getBody() ).find '#put_cursor_here'
                close = cursor.get( 0 ).nextSibling
                sel.select cursor.get 0
                cursor.remove()
                sel.select close
                sel.collapse yes
            else

But if the selection spans multiple elements, then we must handle each edge
of the selection separately.  We cannot use this solution in general,
because editing an element messes up cursor bookmarks within that element.

                range = sel.getRng()
                leftNode = range.startContainer
                leftPos = range.startOffset
                rightNode = range.endContainer
                rightPos = range.endOffset
                range.collapse no
                sel.setRng range
                @disableScanning()
                @editor.insertContent close
                range.setStart leftNode, leftPos
                range.setEnd leftNode, leftPos
                sel.setRng range
                @editor.insertContent open
                @enableScanning()

## Hiding and showing "groupers"

The word "grouper" refers to the objects that form the boundaries of a group, and thus define the group's extent.  Each is an image with specific classes that define its partner, type, visibility, etc.  The following method applies or removes the visibility flag to all groupers at once, thus toggling their visibility in the document.

        allGroupers: => @editor.getDoc().getElementsByClassName 'grouper'
        hideOrShowGroupers: =>
            groupers = $ @allGroupers()
            if ( $ groupers?[0] ).hasClass 'hide'
                groupers.removeClass 'hide'
            else
                groupers.addClass 'hide'

## Scanning

Scanning is the process of reading the entire document and observing where
groupers lie.  This has several purposes.
 * It verifyies that groups are well-formed (i.e., no unpaired groupers, no
   half-nesting).
 * It ensures the list of `@freeIds` is up-to-date.
 * It maintains an in-memory hierarchy of Group objects (to be implemented).

There are times when we need programmatically to make several edits to the
document, and want them to happen as a single unit, without the
`scanDocument` function altering the document's structure admist the work.
Document scanning can be disabled by adding a scan lock.  Do so with the
following two convenience functions.

        disableScanning: => @scanLocks = ( @scanLocks ?= 0 ) + 1
        enableScanning: =>
            @scanLocks = Math.max ( @scanLocks ? 0 ) - 1, 0
            if @scanLocks is 0 then @scanDocument()

Now the routine itself.

        scanDocument: =>
            if @scanLocks > 0 then return
            groupers = Array::slice.apply @allGroupers()
            gpStack = [ ]
            usedIds = [ ]
            @topLevel = [ ]
            before = @freeIds[..]
            index = ( id ) ->
                for gp, i in gpStack
                    if gp.id is id then return i
                -1

Scanning processes each grouper in the document.

            for grouper in groupers

If it had the grouper class but wasn't really a grouper, delete it.

                if not ( info = grouperInfo grouper )?
                    ( $ grouper ).remove()

If it's an open grouper, push it onto the stack of nested ids we're
tracking.

                else if info.type is 'open'
                    gpStack.unshift
                        id : info.id
                        grouper : grouper
                        children : [ ]

Otherwise, it's a close grouper.  If it doesn't have a corresponding open
grouper that we've already seen, delete it.

                else
                    if index( info.id ) is -1
                        ( $ grouper ).remove()
                    else

It has an open grouper.  In case that open grouper wasn't the most recent
thing we've seen, delete everything that's intervening, because they're
incorrectly positioned.

                        while gpStack[0].id isnt info.id
                            ( $ gpStack.shift().grouper ).remove()

Then allow the grouper and its partner to remain in the document, and pop
the stack, because we've moved past the interior of that group.
Furthermore, register the group and its ID in this Groups object.

                        groupData = gpStack.shift()
                        usedIds.push info.id
                        @registerGroup groupData.grouper, grouper
                        newGroup = @[info.id]

Assign parent and child relationships, and store this just-created group on
either the list of children for the next parent outwards in the hierarchy,
or the "top level" list if there is no surrounding group.

                        newGroup.children = groupData.children
                        for child in newGroup.children
                            child.parent = newGroup
                        if gpStack.length > 0
                            gpStack[0].children.push newGroup
                        else
                            @topLevel.push newGroup

Any groupers lingering on the "open" stack have no corresponding close
groupers, and must therefore be deleted.

            while gpStack.length > 0
                ( $ gpStack.shift().grouper ).remove()

Now update the `@freeIds` list to be the complement of the `usedIds` array.

            usedIds.sort()
            count = 0
            @freeIds = [ ]
            while usedIds.length > 0
                if count is usedIds[0]
                    usedIds.shift()
                else
                    @freeIds.push count
                count++
                if count > 20 then break
            @freeIds.push count

And any ID that is free now but wasn't before must have its group deleted
from this object's internal cache.

            after = @freeIds[..]
            while before[before.length-1] < after[after.length-1]
                before.push before[before.length-1] + 1
            while after[after.length-1] < before[before.length-1]
                after.push after[after.length-1] + 1
            becameFree = ( a for a in after when a not in before )
            delete @[id] for id in becameFree

Invalidate the `ids()` cache ([defined below](
#querying-the-group-hierarchy)) so that the next time that function is run,
it recomputes its results from the newly-generated hierarchy in `topLevel`.

            delete @idsCache

The above function needs to create instances of the `Group` class, and
associate them with their IDs.  The following function does so, re-using
copies from the cache when possible.

        registerGroup: ( open, close ) =>
            cached = @[id = grouperInfo( open ).id]
            if cached?.open isnt open or cached?.close isnt close
                @[id] = new Group open, close
            id

## Querying the group hierarchy

The results of the scanning process in [the previous section](#scanning) are
readable through the following functions.

The `ids()` method returns a list of all ids that appear in the Groups
hierarchy, in tree order.

        ids: =>
            if not @idsCache?
                @idsCache = [ ]
                recur = ( g ) =>
                    @idsCache.push g.id()
                    recur child for child in g.children
                recur group for group in @topLevel
            @idsCache

<font color=red>This class is not yet complete. See [the project
plan](plan.md) for details of what's to come.</font>

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Groups` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'groups', ( editor, url ) ->
        editor.Groups = new Groups editor
        editor.on 'init', ( event ) -> editor.dom.loadCSS 'groupsplugin.css'
        for type in editor.settings.groupTypes
            editor.Groups.addGroupType type.name, type
        editor.addMenuItem 'hideshowgroups',
            text : 'Hide/show groups'
            context : 'View'
            onclick : -> editor.Groups.hideOrShowGroupers()

The document needs to be scanned (to rebuild the groups hierarchy) whenever
it changes.  The editor's change event is not reliable, in that it fires
only once at the beginning of any sequence of typing.  Thus we watch not
only for change events, but also for KeyUp events.  We filter the latter so
that we do not rescan the document if the key in question was only an arrow
key or home/end/pgup/pgdn.

        editor.on 'change SetContent', ( event ) ->
            editor.Groups.scanDocument()
        editor.on 'KeyUp', ( event ) ->
            if 33 <= event.keyCode <= 40 then return
            editor.Groups.scanDocument()
