
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Proto-Groups

A "proto-group" is an object representing a group that could be formed in
the document, but has not yet been formed.  It thus contains only some of
the information that the actual group would contain if formed, but not all.
The set of information it contains is just what is required to draw the
proto-group on screen, so that it can be shown to users as a possibility for
them to decide if they wish to form it.

    window.ProtoGroup = class ProtoGroup

The constructor takes as input any HTML `Range` object in the document,
representing the text that would be converted into a group, should this
proto-group be converted into a real group.  It also requires a group type,
which must be one of the types registered in
[the Groups Plugin](groupsplugin.litcoffee).

Ensure that the type provided knows that its `tagContents` and
`tagMenuItems` handlers may be handed proto-groups, and those functions need
to be able to handle instance of this class as inputs, and give sensible
outputs without errors.

        constructor: ( @range, @groupType ) ->

Its open grouper can be any old HTML element near the range provided,
because this will only be used to set the font for the bubble tag, should it
have one that needs to be drawn.

            open = @range.startContainer
            while open? and not open.tagName?
                open = open.parentNode

A proto-group can answer some basic questions about itself, including the
following.

Its type must be the type provided at construction time.

        type: -> @groupType

Its screen boundaries must be determined by the range provided at
contruction time.

        getScreenBoundaries: ->

Much of the code for this function was taken from the `getScreenBoundaries`
function in [the Groups Plugin](groupsplugin.litcoffee).  It was then
slightly customized to the needs of this context.

            if not rects = @range.getClientRects() then return null
            if rects.length is 0 then return null
            rects = ( rects[i] for i in [0...rects.length] )

Initialize the rectangle data for the open and close groupers.

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

Compute whether the open and close groupers are in the same line of text.
This is done by examining whether they extend too far left/right/up/down
compared to one another.  If they are on the same line, then force their top
and bottom coordinates to match, to make it clear (to the caller) that this
represents a rectangle, not a "zone."

            onSameLine = yes
            for rect, index in rects
                open.top = Math.min open.top, rect.top
                close.bottom = Math.max close.bottom, rect.bottom
                if rect.left < open.left then onSameLine = no
                if rect.top > open.bottom then onSameLine = no
            if onSameLine
                close.top = open.top
                open.bottom = close.bottom

Return the results as an object.

            open : open
            close : close

## Detecting content for use in proto-groups

The functions in this section depend on the editor, so we install them only
after the editor is known.

    window.afterEditorReadyArray.push ( editor ) ->

The app must watch the text near the cursor, so that it can use proto-groups
to suggest groups that the user may wish to form, based on the content near
the cursor.  The following functions enable this feature.

The `allRangesNearCursor` function returns, as an array, the set of all
Ranges in the document of the given length and containing the cursor.  They
are returned in the same order in which they sit in the document.

This function requires that the current selection is collapsed.  If it is
not collapsed, this function starts instead from a collapsed range at the
left edge of the current selection.

        window.allRangesNearCursor = ( length ) ->
            cursor = editor.selection.getRng().cloneRange()
            cursor.collapse yes
            for i in [0..length]
                copy = cursor.cloneRange()
                if i > 0 and not copy.extendByCharacters i then continue
                if i < length and \
                   not copy.extendByCharacters -( length - i ) then continue
                copy

The `allPhrasesNearCursor` function operates very similarly to the previous,
but returns ranges containing the specified number of words, rather than a
number of characters.

        window.allPhrasesNearCursor = ( length ) ->
            cursor = editor.selection.getRng().cloneRange()
            cursor.collapse yes
            cursor.includeWholeWords()
            if cursor.toString().length > 0 then length--
            for i in [0..length]
                copy = cursor.cloneRange()
                if i > 0 and not copy.extendByWords i then continue
                if i < length and \
                   not copy.extendByWords -( length - i ) then continue
                copy
