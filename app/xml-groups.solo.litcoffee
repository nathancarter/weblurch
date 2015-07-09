
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
        if children.length
            indent = ( text ) ->
                "  #{text.replace RegExp( '\n', 'g' ), '\n  '}"
            inner = ( window.convertToXML child for child in children )
            "<#{tag}>\n#{indent inner.join '\n'}\n</#{tag}>"
        else
            text = if group? then group.contentAsText() else \
                tinymce.activeEditor.getContent()
            "<#{tag}>#{text}</#{tag}>"
