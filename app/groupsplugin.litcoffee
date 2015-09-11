
# Groups Plugin for [TinyMCE](http://www.tinymce.com)

This plugin adds the notion of "groups" to a TinyMCE editor.  Groups are
contiguous sections of the document, often nested but not otherwise
overlapping, that can be used for a wide variety of purposes.  This plugin
provides the following functionality for working with groups in a document.
 * defines the `Group` and `Groups` classes
 * provides methods for installing UI elements for creating and interacting
   with groups in the document
 * shows groups visually on screen in a variety of ways
 * calls update routines whenever group contents change, so that they can be
   updated/processed

It assumes that TinyMCE has been loaded into the global namespace, so that
it can access it.  It also requires [the overlay
plugin](overlayplugin.litcoffee) to be loaded in the same editor.

All changes made to the document by the user are tracked so that appropriate
events can be called in this plugin to update group objects.  The one
exception to this rule is that calls to the `setContents()` method of the
editor's selection, made by a client, cannot be tracked.  Thus if you call
such a method, you should call `groupChanged()` in any groups whose contents
have changed based on your call to `setContents()`.

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
        if not info then return null
        result = openOrClose : info[1], id : parseInt info[2]
        more = /^grouper ([^ ]+)/.exec grouper?.getAttribute? 'class'
        if more then result.type = more[1]
        result
    window.grouperInfo = grouperInfo

A few functions in this module make use of a tool for computing the default
editor style as a CSS style string (e.g., "font-size:16px;").  That function
is defined here.

    createStyleString = ( styleObject = window.defaultEditorStyles ) ->
        result = [ ]
        for own key, value of styleObject
            newkey = ''
            for letter in key
                if letter.toUpperCase() is letter then newkey += '-'
                newkey += letter.toLowerCase()
            result.push "#{newkey}:#{value};"
        result.join ' '

A few functions in this module make use of a tool for computing a CSS style
string describing the default font size and family of an element.  That
function is defined here.

    createFontStyleString = ( element ) ->
        style = element.ownerDocument.defaultView.getComputedStyle element
        "font-size:#{style.fontSize}; font-family:#{style.fontFamily};"

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

The final parameter is an instance of the Groups class, which is the plugin
defined in this file.  Thus each group will know in which environment it
sits, and be able to communicate with that environment.  If that parameter
is not provided, the constructor will attempt to correctly detect it, but
providing the parameter is more efficient.

We call the contents changed event as soon as the group is created, because
any newly-created group needs to have its contents processed for the first
time (assuming a processing routine exists, otherwise the call does
nothing).  We pass "yes" as the second parameter to indicate that this is
the first call ever to `contentsChanged`, and thus the group type may wish
to do some initial setup.

        constructor: ( @open, @close, @plugin ) ->
            if not @plugin?
                for editor in tinymce.editors
                    if editor.getDoc() is @open.ownerDocument
                        @plugin = editor.Groups
                        break
            @contentsChanged yes, yes

## Core group data

This method returns the ID of the group, if it is available within the open
grouper.

        id: => grouperInfo( @open )?.id ? null

The first of the following methods returns the name of the type of the
group, as a string.  The second returns the type as an object, as long as
the type exists in the plugin stored in `@plugin`.

        typeName: => grouperInfo( @open )?.type
        type: => @plugin?.groupTypes?[@typeName()]

## Group attributes

We provide the following two simple methods for getting and setting
arbitrary data within a group.  Clients should use these methods rather than
write to fields in a group instance itself, because these (a) guarantee no
collisions with existing properties/methods, and (b) mark that group (and
thus the document) dirty, and ensure that changes to a group's data bring
about any recomputation/reprocessing of that group in the document.

Because we use HTML data attributes to store the data, the keys must be
alphanumeric, optionally with dashes.  Furthermore, the data must be able to
be amenable to JSON stringification.

IMPORTANT:  If you call `set()` in a group, the changes you make will NOT be
stored on the TinyMCE undo/redo stack.  If you want your changes stored on
that stack, you should obey the following coding pattern.
 * Before you make any of your changes, call
   `editor.undoManager.beforeChange()`.
 * After you've made all of your changes, call `editor.undoManager.add()`.

You may or may not wish to have your changes stored on the undo/redo stack.
In general, if the change you're making to the group is in direct and
immediate response to the user's actions, then it should be on the undo/redo
stack, so that the user can change their mind.  However, if the change is
the result of a background computation, which was therefore not in direct
response to one of the user's actions, they will probably not expect to be
able to undo it, and thus you should not place the change on the undo/redo
stack.

        set: ( key, value ) =>
            if not /^[a-zA-Z0-9-]+$/.test key then return
            toStore = JSON.stringify [ value ]
            if @open.getAttribute( "data-#{key}" ) isnt toStore
                @open.setAttribute "data-#{key}", toStore
                if @plugin?
                    @plugin.editor.fire 'change'
                    @plugin.editor.isNotDirty = no
                    @contentsChanged()
                if key is 'openDecoration' or key is 'closeDecoration'
                    @updateGrouper key[...-10]
                if key is 'openHoverText' or key is 'closeHoverText'
                    grouper = @[key[...-9]]
                    for attr in [ 'title', 'alt' ] # browser differences
                        grouper.setAttribute attr, "#{value}"
        get: ( key ) =>
            try
                JSON.parse( @open.getAttribute "data-#{key}" )[0]
            catch e
                undefined
        clear: ( key ) =>
            if not /^[a-zA-Z0-9-]+$/.test key then return
            if @open.getAttribute( "data-#{key}" )?
                @open.removeAttribute "data-#{key}"
                if @plugin?
                    @plugin.editor.fire 'change'
                    @plugin.editor.isNotDirty = no
                    @contentsChanged()
                if key is 'openDecoration' or key is 'closeDecoration'
                    @updateGrouper key[...-10]
                if key is 'openHoverText' or key is 'closeHoverText'
                    grouper = @[key[...-9]]
                    for attr in [ 'title', 'alt' ] # browser differences
                        grouper.removeAttribute attr

The `set` and `clear` functions above call an update routine if the
attribute changed was the decoration data for a grouper.  This update
routine recomputes the appearance of that grouper as an image, and stores it
in the `src` attribute grouper itself (which is an `img` element).  We
implement that routine here.

This routine is also called from `hideOrShowGroupers`, defined later in this
file.  It can accept any of three parameter types, the string "open", the
string "close", or an actual grouper element from the document that is
either the open or close grouper for this group.

        updateGrouper: ( openOrClose ) =>
            if openOrClose is @open then openOrClose = 'open'
            if openOrClose is @close then openOrClose = 'close'
            if openOrClose isnt 'open' and openOrClose isnt 'close'
                return
            jquery = $ grouper = @[openOrClose]
            if ( decoration = @get "#{openOrClose}Decoration" )?
                jquery.addClass 'decorate'
            else
                jquery.removeClass 'decorate'
                decoration = ''
            html = if jquery.hasClass 'hide' then '' else \
                @type()?["#{openOrClose}ImageHTML"]
            if openOrClose is 'open'
                html = decoration + html
            else
                html += decoration
            window.base64URLForBlob window.svgBlobForHTML( html,
                createFontStyleString grouper ), ( base64 ) =>
                    if grouper.getAttribute( 'src' ) isnt base64
                        grouper.setAttribute 'src', base64
                        @plugin?.editor.Overlay?.redrawContents()

## Group contents

We will need to be able to query the contents of a group, so that later
computations on that group can use its contents to determine how to act.  We
provide functions for fetching the contents of the group as plain text, as
an HTML `DocumentFragment` object, or as an HTML string.

        contentAsText: => @innerRange()?.toString()
        contentAsFragment: => @innerRange()?.cloneContents()
        contentAsHTML: =>
            if not fragment = @contentAsFragment() then return null
            tmp = @open.ownerDocument.createElement 'div'
            tmp.appendChild fragment
            tmp.innerHTML

You can also fetch the exact sequence of Nodes between the two groupers
(including only the highest-level ones, not their children when that would
be redundant) using the following routine.

        contentNodes: =>
            result = [ ]
            strictOrder = ( a, b ) ->
                cmp = a.compareDocumentPosition b
                ( Node.DOCUMENT_POSITION_FOLLOWING & cmp ) and \
                    not ( Node.DOCUMENT_POSITION_CONTAINED_BY & cmp )
            walk = @open
            while walk?
                if strictOrder walk, @close
                    if strictOrder @open, walk then result.push walk
                    if walk.nextSibling? then walk = walk.nextSibling \
                        else walk = walk.parentNode
                    continue
                if strictOrder @close, walk
                    console.log 'Warning!! walked past @close...something
                        is wrong with this loop'
                    break
                if walk is @close then break else walk = walk.childNodes[0]
            result

We can also set the contents of a group with the following function.  This
function can only work if `@plugin` is a `Groups` class instance.

        setContentAsText: ( text ) =>
            if not inside = @innerRange() then return
            @plugin?.editor.selection.setRng inside
            @plugin?.editor.selection.setContent text

## Group ranges

Those functions rely on the `innerRange()` function, defined below, with a
corresponding `outerRange` function for the sake of completeness.  We use a
`try`/`catch` block because it's possible that the group has been removed
from the document, and thus we can no longer set range start and end points
relative to the group's open and close groupers.

        innerRange: =>
            range = @open.ownerDocument.createRange()
            try
                range.setStartAfter @open
                range.setEndBefore @close
                range
            catch e then null
        outerRange: =>
            range = @open.ownerDocument.createRange()
            try
                range.setStartBefore @open
                range.setEndAfter @close
                range
            catch e then null

We then create analogous functions for creating ranges that include the text
before or after the group.  These ranges extend to the next grouper in the
given direction, whether it be an open or close grouper of any type.
Specifically,
 * The `rangeBefore` range always ends immediately before this group's open
   grouper, and
   * if this group is the first in its parent, the range begins immediately
     after the parent's open grouper;
   * otherwise it begins immediately after its previous sibling's close
     grouper.
   * But if this is the first top-level group in the document, then the
     range begins at the start of the document.
 * The `rangeAfter` range always begins immediately after this group's close
   grouper, and
   * if this group is the last in its parent, the range ends immediately
     before the parent's close grouper;
   * otherwise it ends immediately before its next sibling's open grouper.
   * But if this is the last top-level group in the document, then the
     range ends at the end of the document.

        rangeBefore: =>
            range = ( doc = @open.ownerDocument ).createRange()
            try
                range.setEndBefore @open
                if prev = @previousSibling()
                    range.setStartAfter prev.close
                else if @parent
                    range.setStartAfter @parent.open
                else
                    range.setStartBefore doc.body.childNodes[0]
                range
            catch e then null
        rangeAfter: =>
            range = ( doc = @open.ownerDocument ).createRange()
            try
                range.setStartAfter @close
                if next = @nextSibling()
                    range.setEndBefore next.open
                else if @parent
                    range.setEndBefore @parent.close
                else
                    range.setEndAfter \
                        doc.body.childNodes[doc.body.childNodes.length-1]
                range
            catch e then null

## Group hierarchy

The previous two functions require being able to query this group's index in
its parent group, and to use that index to look up next and previous sibling
groups.  We provide those functions here.

        indexInParent: =>
            ( @parent?.children ? @plugin?.topLevel )?.indexOf this
        previousSibling: =>
            ( @parent?.children ? @plugin?.topLevel )?[@indexInParent()-1]
        nextSibling: =>
            ( @parent?.children ? @plugin?.topLevel )?[@indexInParent()+1]

## Group change event

The following function should be called whenever the contents of the group
have changed.  It notifies the group's type, so that the requisite
processing, if any, of the new contents can take place.  It is called
automatically by some handlers in the `Groups` class, below.

By default, it propagates the change event up the ancestor chain in the
group hierarchy, but that can be disabled by passing false as the parameter.

The second parameter indicates whether this is the first `contentsChanged`
call since the group was constructed.  By default, this is false, but is set
to true from the one call made to this function from the group's
constructor.

        contentsChanged: ( propagate = yes, firstTime = no ) =>
            @type()?.contentsChanged? this, firstTime
            if propagate then @parent?.contentsChanged yes

## Group serialization

The following serialization routine is useful for sending groups to a Web
Worker for background processing.

        toJSON: =>
            data = { }
            for attr in @open.attributes
                if attr.nodeName[..5] is 'data-' and \
                   attr.nodeName[..9] isnt 'data-mce-'
                    try
                        data[attr.nodeName] =
                            JSON.parse( attr.nodeValue )[0]
            id : @id()
            typeName : @typeName()
            deleted : @deleted
            text : @contentAsText()
            html : @contentAsHTML()
            parent : @parent?.id() ? null
            children : ( child?.id() ? null for child in @children ? [ ] )
            data : data

## Group connections ("arrows")

Groups can be connected in a graph.  The graph is directed, and there can be
multiple arrows from one group to another.  Each arrow has an optional
string attribute attached to it called its "tag," which defaults to the
empty string. For multiple arrows between the same two groups, different
tags are required.

Connect group `A` to group `B` by calling `A.connect B`.  The optional
second parameter is the tag string to attach.  It defaults to the empty
string.  Calling this more than once with the same `A`, `B`, and tag has the
same effect as calling it once.

        connect: ( toGroup, tag = '' ) =>
            connection = [ @id(), toGroup.id(), "#{tag}" ]
            connstring = "#{connection}"
            oldConnections = @get( 'connections' ) ? [ ]
            mustAdd = yes
            for oldConnection in oldConnections
                if "#{oldConnection}" is connstring
                    mustAdd = no
                    break
            if mustAdd
                @set 'connections', [ oldConnections..., connection ]
            oldConnections = toGroup.get( 'connections' ) ? [ ]
            mustAdd = yes
            for oldConnection in oldConnections
                if "#{oldConnection}" is connstring
                    mustAdd = no
                    break
            if mustAdd
                toGroup.set 'connections', [ oldConnections..., connection ]

The following function undoes the previous.  The third parameter can be
either a string or a regular expression.  It defaults to the empty string.
Calling `A.disconnect B, C` finds all connections from `A` to `B` satisfying
a condition on `C`.  If `C` is a string, then the connection tag must equal
`C`; if `C` is a regular expression, then the connection tag must match `C`.
Connections not satisfying these criterion are not candidates for deletion.

        disconnect: ( fromGroup, tag = '' ) =>
            matches = ( array ) =>
                array[0] is @id() and array[1] is fromGroup.id() and \
                    ( tag is array[2] or tag.test? array[2] )
            @set 'connections', ( c for c in @get( 'connections' ) ? [ ] \
                when not matches c )
            fromGroup.set 'connections', ( c for c in \
                fromGroup.get( 'connections' ) ? [ ] when not matches c )

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

Install in the Overlay plugin for the same editor object a handler that
draws the groups surrounding the user's cursor.

            @editor.Overlay.addDrawHandler @drawGroups

When a free id is needed, we need a function that will give the next such
free id and then mark that id as consumed from the list.

        nextFreeId: =>
            if @freeIds.length > 1 then @freeIds.shift() else @freeIds[0]++

When an id in use becomes free, we need a function that will put it back
into the list of free ids.

        addFreeId: ( id ) =>
            if id < @freeIds[@freeIds.length-1]
                @freeIds.push id
                @freeIds.sort ( a, b ) -> a - b

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
 * key: `openImage`, value: a string pointing to the image file to use when
   the open grouper is visible, defaults to `'images/red-bracket-open.png'`
 * If instead you provide the `openImageHTML` tag, an image will be created
   for you by rendering the HTML you provide, and you need not provide an
   `openImage` key-value pair.
 * key: `closeImage`, complement to the previous, defaults to
   `'images/red-bracket-close.png'`
 * Similarly, `closeImageHTML` functions like `openImageHTML`.
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
                plugin = this
                if data.imageHTML?
                    data.image = objectURLForBlob svgBlobForHTML \
                        data.imageHTML, createStyleString()
                if data.openImageHTML?
                    blob = svgBlobForHTML data.openImageHTML,
                        createStyleString()
                    data.openImage = objectURLForBlob blob
                    base64URLForBlob blob, ( result ) ->
                        data.openImage = result
                if data.closeImageHTML?
                    blob = svgBlobForHTML data.closeImageHTML,
                        createStyleString()
                    data.closeImage = objectURLForBlob blob
                    base64URLForBlob blob, ( result ) ->
                        data.closeImage = result
                menuData =
                    text : data.text
                    context : data.context ? 'Insert'
                    onclick : => @groupCurrentSelection name
                    onPostRender : -> # must use -> here to access "this":
                        plugin.groupTypes[name].menuItem = this
                        plugin.updateButtonsAndMenuItems()
                if data.shortcut? then menuData.shortcut = data.shortcut
                if data.icon? then menuData.icon = data.icon
                @editor.addMenuItem name, menuData
                buttonData =
                    tooltip : data.tooltip
                    onclick : => @groupCurrentSelection name
                    onPostRender : -> # must use -> here to access "this":
                        plugin.groupTypes[name].button = this
                        plugin.updateButtonsAndMenuItems()
                key = if data.image? then 'image' else \
                    if data.icon? then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData

The above function calls `updateButtonsAndMenuItems()` whenever a new button
or menu item is first drawn.  That function is also called whenever the
cursor in the document moves or the groups are rescanned.  It enables or
disables the group-insertion routines based on whether the selection should
be allowed to be wrapped in a group.  This is determined based on whether
the two ends of the selection are inside the same deepest group.

        updateButtonsAndMenuItems: =>
            left = @editor?.selection?.getRng()?.cloneRange()
            if not left then return
            right = left.cloneRange()
            left.collapse yes
            right.collapse no
            inSameGroup =
                @groupAboveCursor( left ) is @groupAboveCursor( right )
            for own name, type of @groupTypes
                type?.button?.disabled not inSameGroup
                type?.menuItem?.disabled not inSameGroup

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
                @groupTypes[type].openImage
            close = grouperHTML type, 'close', id, hide,
                @groupTypes[type].closeImage

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

                content = @editor.selection.getContent()
                @editor.insertContent open + content + '{$caret}' + close
                cursor = @editor.selection.getRng()
                close = cursor.endContainer.childNodes[cursor.endOffset] ?
                    cursor.endContainer.nextSibling
                newGroup = @grouperToGroup close
                newGroup.parent?.contentsChanged()
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
                @editor.insertContent '{$caret}' + close
                range = sel.getRng()
                close = range.endContainer.childNodes[range.endOffset] ?
                    range.endContainer.nextSibling
                range.setStart leftNode, leftPos
                range.setEnd leftNode, leftPos
                sel.setRng range
                @editor.insertContent open
                @enableScanning()
                @editor.selection.select close
                @editor.selection.collapse yes
                newGroup = @grouperToGroup close
                newGroup.parent?.contentsChanged()

## Hiding and showing "groupers"

The word "grouper" refers to the objects that form the boundaries of a group, and thus define the group's extent.  Each is an image with specific classes that define its partner, type, visibility, etc.  The following method applies or removes the visibility flag to all groupers at once, thus toggling their visibility in the document.

        allGroupers: => @editor.getDoc().getElementsByClassName 'grouper'
        hideOrShowGroupers: =>
            groupers = $ @allGroupers()
            if ( $ groupers?[0] ).hasClass 'hide'
                groupers.removeClass 'hide'
            else
                groupers.addClass 'hide'
            groupers.filter( '.decorate' ).each ( index, grouper ) =>
                @grouperToGroup( grouper ).updateGrouper grouper
            @editor.Overlay?.redrawContents()
            @editor.focus()

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

We also want to track when scanning is happening, so that `scanDocument`
cannot get into infinitely deep recursion by triggering a change in the
document, which in turn calls `scanDocument` again.  We track whether a scan
is running using this flag.  (Note that the scanning routine constructs new
`Group` objects, which call `contentsChanged` handlers, which let clients
execute arbitrary code, so the infinite loop is quite possible, and thus
must be prevented.)

        isScanning = no

Now the routine itself.

        scanDocument: =>

If scanning is disabled, do nothing.  If it's already happening, then
whatever change is attempting to get us to scan again should just have the
new scan start *after* this one completes, not during.

            if @scanLocks > 0 then return
            if isScanning then return setTimeout ( => @scanDocument ), 0
            isScanning = yes

Initialize local variables:

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

                else if info.openOrClose is 'open'
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
                            newGroup.parent = null

Any groupers lingering on the "open" stack have no corresponding close
groupers, and must therefore be deleted.

            while gpStack.length > 0
                ( $ gpStack.shift().grouper ).remove()

Now update the `@freeIds` list to be the complement of the `usedIds` array.

            usedIds.sort ( a, b ) -> a - b
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
from this object's internal cache.  After we delete all of them from the
cache, we also call the group type's `deleted` method on each one, to permit
finalization code to run.  We also mark each with a "deleted" attribute set
to true, so that if there are any pending computations about that group,
they know not to bother actually modifying the group when they complete,
because it is no longer in the document anyway.

            after = @freeIds[..]
            while before[before.length-1] < after[after.length-1]
                before.push before[before.length-1] + 1
            while after[after.length-1] < before[before.length-1]
                after.push after[after.length-1] + 1
            becameFree = ( a for a in after when a not in before )
            deleted = [ ]
            for id in becameFree
                deleted.push @[id]
                @[id]?.deleted = yes
                delete @[id]
            group?.type()?.deleted? group for group in deleted

Invalidate the `ids()` cache ([defined below](
#querying-the-group-hierarchy)) so that the next time that function is run,
it recomputes its results from the newly-generated hierarchy in `topLevel`.

            delete @idsCache

If the Overlay plugin is in use, it should now redraw, since the list of
groups may have changed.  We put it on a slight delay, because there may
still be some pending cursor movements that we want to ensure have finished
before this drawing routine is called.  At the same time, we also update
the enabled/disabled state of group-insertion buttons and menu items.

            setTimeout =>
                @editor.Overlay?.redrawContents()
                @updateButtonsAndMenuItems()
            , 0
            isScanning = no

The above function needs to create instances of the `Group` class, and
associate them with their IDs.  The following function does so, re-using
copies from the cache when possible.

        registerGroup: ( open, close ) =>
            cached = @[id = grouperInfo( open ).id]
            if cached?.open isnt open or cached?.close isnt close
                @[id] = new Group open, close, this
            id

## Querying the group hierarchy

The results of the scanning process in [the previous section](#scanning) are
readable through the following functions.

The following method returns a list of all ids that appear in the Groups
hierarchy, in tree order.

        ids: =>
            if not @idsCache?
                @idsCache = [ ]
                recur = ( g ) =>
                    @idsCache.push g.id()
                    recur child for child in g.children
                recur group for group in @topLevel
            @idsCache

The following method finds the group for a given open/close grouper element
from the DOM.  It returns null if the given object is not an open/close
grouper, or does not appear in the group hierarchy.

        grouperToGroup: ( grouper ) =>
            if ( id = grouperInfo( grouper )?.id )? then @[id] else null

The following method finds the deepest group containing a given DOM Node.
It does so by a binary search through the groupers array for the closest
grouper before the node.  If it is an open grouper, the node is in that
group.  If it is a close grouper, the node is in its parent group.

        groupAboveNode: ( node ) =>
            if ( all = @allGroupers() ).length is 0 then return null
            less = ( a, b ) ->
                Node.DOCUMENT_POSITION_FOLLOWING & \
                    a.compareDocumentPosition( b )
            left = index : 0, grouper : all[0], leftOfNode : yes
            return @grouperToGroup left.grouper if left.grouper is node
            return null if not less left.grouper, node
            right = index : all.length - 1, grouper : all[all.length - 1]
            return @grouperToGroup right.grouper if right.grouper is node
            return null if less right.grouper, node
            loop
                if left.grouper is node
                    return @grouperToGroup left.grouper
                if right.grouper is node
                    return @grouperToGroup right.grouper
                if left.index + 1 is right.index
                    return null unless group = @grouperToGroup left.grouper
                    return if left.grouper is group.open then group \
                        else group.parent
                middle = Math.floor ( left.index + right.index ) / 2
                if less all[middle], node
                    left =
                        index : middle
                        grouper : all[middle]
                        leftOfNode : yes
                else
                    right =
                        index : middle
                        grouper : all[middle]
                        leftOfNode : no

The following method is like the previous, but instead of computing the
deepest group above a given node, it computes the deepest group above a
given cursor position.  This must be presented to the method in the form of
an HTML Range object that has the same start and end nodes and offsets, such
as one that has been collapsed.

        groupAboveCursor: ( cursor ) =>
            if cursor.startContainer instanceof @editor.getWin().Text
                return @groupAboveNode cursor.startContainer
            if cursor.startContainer.childNodes.length > cursor.startOffset
                elementAfter =
                    cursor.startContainer.childNodes[cursor.startOffset]
                itsGroup = @groupAboveNode elementAfter
                return if itsGroup?.open is elementAfter \
                    then itsGroup.parent else itsGroup
            if cursor.startContainer.childNodes.length > 0
                elementBefore =
                    cursor.startContainer.childNodes[cursor.startOffset - 1]
                itsGroup = @groupAboveNode elementBefore
                return if itsGroup?.close is elementBefore \
                    then itsGroup.parent else itsGroup
            @groupAboveNode cursor.startContainer

The following method generalizes the previous to HTML Range objects that do
not have the same starting and ending points.  The group returned will be
the deepest group containing both ends of the cursor.

        groupAboveSelection: ( range ) =>

Compute the complete ancestor chain of the left end of the range.

            left = range.cloneRange()
            left.collapse yes
            left = @groupAboveCursor left
            leftChain = [ ]
            while left?
                leftChain.unshift left
                left = left.parent

Compute the complete ancestor chain of the right end of the range.

            right = range.cloneRange()
            right.collapse no
            right = @groupAboveCursor right
            rightChain = [ ]
            while right?
                rightChain.unshift right
                right = right.parent

Find the deepest group in both ancestor chains.

            result = null
            while leftChain.length > 0 and rightChain.length > 0 and \
                  leftChain[0] is rightChain[0]
                result = leftChain.shift()
                rightChain.shift()
            result

## Change Events

The following function can be called whenever a certain range in the
document has changed, and groups touching that range need to be updated.  It
assumes that `scanDocument()` was recently called, so that the group
hierarchy is up-to-date.  The parameter must be a DOM Range object.

        rangeChanged: ( range ) =>
            group.contentsChanged no for group in @groupsTouchingRange range

That method uses `@groupsTouchingRange()`, which is implemented below.  It
uses the previous to get a list of all groups that intersect the given DOM
Range object, in the order in which their close groupers appear (which means
that child groups are guaranteed to appear earlier in the list than their
parent groups).

The return value will include all groups whose interior or groupers
intersect the interior of the range.  This includes groups that intersect
the range only indirectly, by being parents whose children intersect the
range, and so on for grandparent groups, etc.  When the selection is
collapsed, the only "leaf" group intersecting it is the one containing it.

This routine requires that `scanDocument` has recently been called, so that
groupers appear in perfectly matched pairs, correctly nested.

        groupsTouchingRange: ( range ) =>
            if ( all = @allGroupers() ).length is 0 then return [ ]
            firstInRange = 1 + @grouperIndexOfRangeEndpoint range, yes, all
            lastInRange = @grouperIndexOfRangeEndpoint range, no, all

If there are no groupers in the selected range at all, then just create the
parent chain of groups above the closest node to the selection.

            if firstInRange > lastInRange
                node = range.startContainer
                if node instanceof @editor.getWin().Element and \
                   range.startOffset < node.childNodes.length
                    node = node.childNodes[range.startOffset]
                group = @groupAboveNode node
                result = if group
                    if group.open is node
                        if group.parent then [ group.parent ] else [ ]
                    else
                        [ group ]
                else
                    [ ]
                while maybeOneMore = result[result.length-1]?.parent
                    result.push maybeOneMore
                return result

Otherwise walk through all the groupers in the selection and push their
groups onto a stack in the order that the close groupers are encountered.

            stack = [ ]
            result = [ ]
            for index in [firstInRange..lastInRange]
                group = @grouperToGroup all[index]
                if all[index] is group.open
                    stack.push group
                else
                    result.push group
                    stack.pop()

Then push onto the stack any open groupers that aren't yet closed, and any
ancestor groups of the last big group encountered, the only one whose parent
groups may not have been seen as open groupers.

            while stack.length > 0 then result.push stack.pop()
            while maybeOneMore = result[result.length-1].parent
                result.push maybeOneMore
            result

The above method uses `@grouperIndexOfRangeEndpoint`, which is defined here.
It locates the endpoint of a DOM Range object in the list of groupers in the
editor.  It performs a binary search through the ordered list of groupers.

The `range` parameter must be a DOM Range object.  The `left` paramter
should be true if you're asking about the left end of the range, false if
you're asking about the right end.

The return value will be the index into `@allGroupers()` of the last grouper
before the range endpoint.  Clearly, then, the grouper on the other side of
the range endpoint is the return value plus 1.  If no groupers are before
the range endpoint, this return value will be -1; a special case of this is
when there are no groupers at all.

The final parameter is optional; it prevents having to compute
`@allGroupers()`, in case you already have that data available.

        grouperIndexOfRangeEndpoint: ( range, left, all ) =>
            if ( all ?= @allGroupers() ).length is 0 then return -1
            endpoint = if left then Range.END_TO_START else Range.END_TO_END
            isLeftOfEndpoint = ( grouper ) =>
                grouperRange = @editor.getDoc().createRange()
                grouperRange.selectNode grouper
                range.compareBoundaryPoints( endpoint, grouperRange ) > -1
            left = 0
            return -1 if not isLeftOfEndpoint all[left]
            right = all.length - 1
            return right if isLeftOfEndpoint all[right]
            loop
                return left if left + 1 is right
                middle = Math.floor ( left + right ) / 2
                if isLeftOfEndpoint all[middle]
                    left = middle
                else
                    right = middle

## Drawing Groups

The following function draws groups around the user's cursor, if any.  It is
installed in [the constructor](#groups-constructor) and called by [the
Overlay plugin](overlayplugin.litcoffee).

        drawGroups: ( canvas, context ) =>
            @bubbleTags = [ ]

We do not draw the groups if document scanning is disabled, because it means
that we are in the middle of a change to the group hierarchy, which means
that calls to the functions we'll need to figure out what to draw will give
unstable/incorrect results.

            if @scanLocks > 0 then return
            group = @groupAboveSelection @editor.selection.getRng()
            bodyStyle = null
            pad = 3
            padStep = 2
            radius = 4
            tags = [ ]
            while group
                type = group.type()
                color = type?.color ? '#444444'

Compute the sizes and positions of the open and close groupers.  Because the
elements between them may be taller (or sink lower) than the groupers
themselves, we also inspect the client rectangles of all elements in the
group, and adjust the relevant corners of the open and close groupers
outward to make sure the bubble encloses the entire contents of the group.

                rects = group.outerRange()?.getClientRects()
                if not rects?
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 100
                    return
                rects = ( rects[i] for i in [0...rects.length] )
                open = rects[0]
                open =
                    top : open.top
                    left : open.left
                    right : open.right
                    bottom : open.bottom
                close = rects[rects.length-1]
                close =
                    top : close.top
                    left : close.left
                    right : close.right
                    bottom : close.bottom
                onSameLine = yes
                for rect, index in rects
                    open.top = Math.min open.top, rect.top
                    close.bottom = Math.max close.bottom, rect.bottom
                    if rect.left < open.left then onSameLine = no
                if onSameLine
                    close.top = open.top
                    open.bottom = close.bottom

If any of them has zero size, then that means that an image file (for an
open/close grouper) isn't yet loaded.  Thus we need to stop here and queue
up a later call to this same drawing routine, at which time the image file
may be loaded.

                if ( open.top is open.bottom or \
                     close.top is close.bottom or \
                     open.left is open.right or \
                     close.left is close.right ) and \
                   not ( $ group.open ).hasClass 'hide'
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 100
                    return

Compute the group's tag contents, if any, and store where and how to draw
them.

                x1 = open.left - pad/3
                y1 = open.top - pad
                x2 = close.right + pad/3
                y2 = close.bottom + pad
                if tagString = type?.tagContents? group
                    tags.push
                        content : tagString
                        corner : { x : x1, y : y1 }
                        color : color
                        style : createFontStyleString group.open
                        group : group

Draw this group and then move one step up the group hierarchy, ready to draw
the next one on the next pass through the loop.

                context.fillStyle = context.strokeStyle = color
                if open.top is close.top and open.bottom is close.bottom

A rounded rectangle from open's top left to close's bottom right, padded by
`pad/3` in the x direction, `pad` in the y direction, and with corner radius
`radius`.

                    context.roundedRect x1, y1, x2, y2, radius
                else
                    if not bodyStyle?
                        bodyStyle = getComputedStyle @editor.getBody()
                        leftMar = parseInt bodyStyle['margin-left']
                        rightMar = parseInt bodyStyle['margin-right']
                    context.roundedZone x1, y1, x2, y2, open.bottom,
                        close.top, leftMar, rightMar, radius
                context.globalAlpha = 1.0
                context.lineWidth = 1.5
                context.stroke()
                context.globalAlpha = 0.3
                context.fill()
                group = group.parent
                pad += padStep

Now draw the tags on all the bubbles just drawn.  We proceed in reverse
order, so that outer tags are drawn behind inner ones.  We also track the
rectangles we've covered, and move any later ones upward so as not to
collide with ones drawn earlier.

We begin by measuring the sizes of the rectangles, and checking for
collisions.  Those that collide with previously-scanned rectangles are slid
upwards so that they don't collide anymore.  After all collisions have been
resolved, the rectangle's bottom boundary is reset to what it originally
was, so that the rectangle actually just got taller.

            tagsToDraw = [ ]
            while tags.length > 0
                tag = tags.shift()
                context.font = tag.font
                if not size = context.measureHTML tag.content, tag.style
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 10
                    return
                x1 = tag.corner.x - padStep
                y1 = tag.corner.y - size.height - 2*padStep
                x2 = x1 + 2*padStep + size.width
                y2 = tag.corner.y
                for old in tagsToDraw
                    if rectanglesCollide x1, y1, x2, y2, old.x1, old.y1, \
                                         old.x2, old.y2
                        moveBy = old.y1 - y2
                        y1 += moveBy
                        y2 += moveBy
                y2 = tag.corner.y
                [ tag.x1, tag.y1, tag.x2, tag.y2 ] = [ x1, y1, x2, y2 ]
                tagsToDraw.unshift tag

Now we draw the tags that have already been sized for us by the previous
loop.

            for tag in tagsToDraw
                context.roundedRect tag.x1, tag.y1, tag.x2, tag.y2, radius
                context.globalAlpha = 1.0
                context.fillStyle = '#ffffff'
                context.fill()
                context.lineWidth = 1.5
                context.strokeStyle = tag.color
                context.stroke()
                context.globalAlpha = 0.7
                context.fillStyle = tag.color
                context.fill()
                context.fillStyle = '#000000'
                context.globalAlpha = 1.0
                context.drawHTML tag.content, tag.x1 + padStep, tag.y1,
                    tag.style
                @bubbleTags.unshift tag

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

In addition to rescanning the document, we also call the `rangeChanged`
event of the Groups plugin, to update any groups that overlap the range in
which the document was modified.

        editor.on 'change SetContent', ( event ) ->
            editor.Groups.scanDocument()
            if event?.level?.bookmark
                orig = editor.selection.getBookmark()
                editor.selection.moveToBookmark event.level.bookmark
                range = editor.selection.getRng()
                editor.selection.moveToBookmark orig
                editor.Groups.rangeChanged range
        editor.on 'KeyUp', ( event ) ->
            movements = [ 33..40 ] # arrows, pgup/pgdn/home/end
            modifiers = [ 16, 17, 18, 91 ] # alt, shift, ctrl, meta
            if event.keyCode in movements or event.keyCode in modifiers
                return
            editor.Groups.scanDocument()
            editor.Groups.rangeChanged editor.selection.getRng()

Whenever the cursor moves, we should update whether the group-insertion
buttons and menu items are enabled.

        editor.on 'NodeChange', ( event ) ->
            editor.Groups.updateButtonsAndMenuItems()

The following handler installs a context menu that is exactly like that
created by the TinyMCE context menu plugin, except that it appends to it
any custom menu items needed by any groups inside which the user clicked.

        editor.on 'contextMenu', ( event ) ->

Prevent the browser's context menu.

            event.preventDefault()

Figure out where the user clicked, and whether there are any groups there.

            x = event.clientX
            y = event.clientY
            if node = editor.getDoc().nodeFromPoint x, y
                group = editor.Groups.groupAboveNode node

Compute the list of normal context menu items.

            contextmenu = editor.settings.contextmenu or \
                'link image inserttable | cell row column deletetable'
            items = [ ]
            for name in contextmenu.split /[ ,]/
                item = editor.menuItems[name]
                if name is '|' then item = text : name
                if item then item.shortcut = '' ; items.push item

Add any group-specific context menu items.

            if newItems = group?.type()?.contextMenuItems group
                items.push text : '|'
                items = items.concat newItems

Construct the menu and show it on screen.

            menu = new tinymce.ui.Menu(
                items : items
                context : 'contextmenu'
            ).addClass( 'contextmenu' ).renderTo()
            editor.on 'remove', -> menu.remove() ; menu = null
            pos = ( $ editor.getContentAreaContainer() ).position()
            menu.moveTo x + pos.left, y + pos.top

When the user clicks in a bubble tag, we must discern which bubble tag
received the click, and trigger the tag menu for that group, if it defines
one.

We use the mousedown event rather than the click event, because the
mousedown event is the only one for which `preventDefault()` can function.
By the time the click event happens (strictly after mousedown), it is too
late to prevent the default handling of the event.

        editor.on 'mousedown', ( event ) ->
            x = event.clientX
            y = event.clientY
            for tag in editor.Groups.bubbleTags
                if tag.x1 < x < tag.x2 and tag.y1 < y < tag.y2
                    menuItems = tag.group?.type()?.tagMenuItems tag.group
                    menuItems ?= [
                        text : 'no actions available'
                        disabled : true
                    ]
                    menu = new tinymce.ui.Menu(
                        items : menuItems
                        context : 'contextmenu'
                    ).addClass( 'contextmenu' ).renderTo()
                    editor.on 'remove', -> menu.remove() ; menu = null
                    pos = ( $ editor.getContentAreaContainer() ).position()
                    menu.moveTo x + pos.left, y + pos.top
                    event.preventDefault()
                    break
