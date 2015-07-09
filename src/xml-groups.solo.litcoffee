
# XML Groups Module

This module lets the client convert the contents of a TinyMCE editor (with
[the Groups plugin](../app/groupsplugin.litcoffee) enabled) into XML, and to
check first whether the structure of the groups in the document satisfies
certain criteria (so that the resulting XML will be valid).

## Tag Data

Clients of this module will specify which XML tags are relevant to their
particular application, and how we should go about validating their
structure.  We provide the `setTagData` and `addTagData` functions, each of
which takes one argument, a mapping from tag names to objects that give the
properties of the named tag.

The following properties are supported for each tag name.
 * `topLevel` - true if and only if the document itself is to be treated as
   a Group with this tag.  There should be exactly one tag with this
   attribute set to true.
 * `defaultChild` - the tag name that children should have by default.  When
   a new Group is inserted into the document, its parent Group will be
   queried for its `defaultChild` property, and that value used to set the
   tag of the new group.  If the new group has no parent, then the
   `defaultChild` property of the `topLevel` tag is used.
 * `externalName` - a human-readable name to be used in the user interface
   when mentioning this tag, for example "widgetNum" might have the external
   name "Widget Number."  This is useful for populating bubble tags, for
   instance.  See the `getExternalTagName` function
   [below](#querying-tag-data).
 * `documentation` - an HTML string (possibly lengthy) describing the tag's
   purpose from the end user's point of view.  This module places on the
   groups' tag and context menus an option for reading this documentation in
   a popup window.
 * `includeText` - This impacts how the XML representation of a group with
   the tag in question is computed.
   * If this attribute is true, then the XML will include, between inner
     elements, any text that appears between those elements' groups in the
     document.
   * If this attribute is a string containing the name of another tag, then
     the text will be included and will be wrapped in an element with that
     tag name.
   * If this attribute is false (or any value that doesn't fit either of the
     previous two cases), then any text between inner groups is ignored.
   * The default is true for leaves in the group hierarchy, and false for
     non-leaf groups.

    tagData = { }
    window.setTagData = ( newData ) -> tagData = newData
    window.addTagData = ( newData ) ->
        tagData[key] = value for own key, value of newData

## Tagging Groups

You can set the tag name for a Group object, and query it as well, with the
following two functions.  They simply use the "tagName" attribute of the
Group object.

    window.setGroupTag = ( group, tagName ) -> group.set 'tagName', tagName
    window.getGroupTag = ( group ) -> group.get 'tagName'

To tag a Group with its appropriate default tag name, based on its parent's
tag name, call the following function.

    window.initializeGroupTag = ( group ) ->
        parentTagName = if group.parent
            window.getGroupTag group.parent
        else
            window.topLevelTagName()
        tagName = window.getTagData parentTagName, 'defaultChild'
        if tagName then window.setGroupTag group, tagName

## Querying Tag Data

Clients can query the data in that object at a primitive level with
`getTagData`.  More specialized query functions follow.

    window.getTagData = ( tagName, key ) -> tagData[tagName]?[key]

This function queries the official name associated with the given tag name.
If it has an "externalName," then that is returned.  Otherwise the given tag
name is returned unchanged.

    window.getTagExternalName = ( tagName ) ->
        window.getTagData( tagName, 'externalName' ) ? tagName

This function locates the one tag name that has the attribute `topLevel` set
to true.  (Technically it locates the first, in the arbitrary order of keys
given by the `tagData` object internally, but since there should be only one
such tag name, that means the same thing.)

    window.topLevelTagName = ->
        for own key, value of tagData
            if value.topLevel then return key

This function creates a set of menu items for the given group.  Specifics
are documented within the code below.

    window.XMLMenuItems = ( group ) ->
        result = [ ]

First, check to see if the given group has any documentation, and if it
does, add to the given array of TinyMCE menu items an item for querying the
group's documentation.  If it has none, do nothing.

        if ( tag = window.getGroupTag group )?
            external = window.getTagExternalName tag
            if ( documentation = window.getTagData tag, 'documentation' )?
                documentation = documentation.replace /a href=/g,
                    'a target="_blank" href='
                result.push
                    text : "Read \"#{external}\" documentation"
                    onclick : -> showHTMLPopup documentation,
                        "Documentation for \"#{external}\""

Create a menu item for seeing the XML code representing the given group.

        result.push
            text : "View XML representation"
            onclick : ->
                xml = window.convertToXML group
                .replace /&/g, '&amp;'
                .replace /</g, '&lt;'
                showHTMLPopup "<pre>#{xml}</pre>", 'XML Representation'

Return the full list of menu items we generated.

        result

The above function uses the following utility a few times.  This function
displays arbitrary HTML in a TinyMCE dialog (something you would think would
be a simple built-in TinyMCE function, but it most definitely is not).  You
may pass an options object containing keys for title, width, height, and
button (replacement text for the "Done" button).

    showHTMLPopup = ( html, options = { } ) ->
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : window.objectURLForBlob window.makeBlob html,
                'text/html;charset=utf-8'
            width : options.width ? 500
            height : options.height ? 400
            buttons : [
                type : 'button'
                text : options.button ? 'Done'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
            ]

## Define one toolbar button

This toolbar button is for viewing the XML representation of the entire
document in a new tab.

    window.groupToolbarButtons =
        viewxml :
            text : 'XML'
            tooltip : 'View XML representation of this document'
            onclick : ->
                xml = encodeURIComponent window.convertToXML()
                window.open "data:application/xml,#{xml}", '_blank'

## Forming XML

The following function converts the given group (or the whole document if
none is given into an XML representation using the data in `tagData`).

    window.convertToXML = ( group ) ->
        if group?
            children = group.children
            tag = window.getGroupTag group
        else
            children = tinymce.activeEditor.Groups.topLevel
            tag = window.topLevelTagName()
        wrapper = window.getTagData( tag, 'includeText' )
        wrap = ( text ) ->
            if not wrapper then return ''
            if not tagData.hasOwnProperty wrapper then return text
            "<#{wrapper}>#{text}</#{wrapper}>"
        if children.length
            indent = ( text ) ->
                "  #{text.replace RegExp( '\n', 'g' ), '\n  '}"
            inner = wrap tinymce.DOM.encode rangeToHTML \
                children[0].rangeBefore()
            for child in children
                if inner[inner.length-1] isnt '\n' then inner += '\n'
                inner += "#{window.convertToXML child}\n" + \
                    wrap tinymce.DOM.encode rangeToHTML child.rangeAfter()
            "<#{tag}>\n#{indent inner}\n</#{tag}>"
        else
            text = if group? then group.contentAsText() else \
                tinymce.activeEditor.getContent()
            wrapper ?= true
            "<#{tag}>#{wrap tinymce.DOM.encode text}</#{tag}>"

The previous function makes use of the following utility function.  It
converts a range to HTML by first passing it through a document fragment.

    rangeToHTML = ( range ) ->
        if not fragment = range?.cloneContents() then return null
        tmp = range.startContainer.ownerDocument.createElement 'div'
        tmp.appendChild fragment
        html = tmp.innerHTML
        whiteSpaceBefore = if /^\s/.test html then ' ' else ''
        whiteSpaceAfter = if /\s+$/.test html then ' ' else ''
        result = tinymce.activeEditor.serializer.serialize tmp,
            { get : yes, format : 'html', selection : yes, getInner : yes }
        whiteSpaceBefore + result + whiteSpaceAfter
