
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

This function locates the one tag name that has the attribute `topLevel` set
to true.  (Technically it locates the first, in the arbitrary order of keys
given by the `tagData` object internally, but since there should be only one
such tag name, that means the same thing.)

    window.topLevelTagName = ->
        for own key, value of tagData
            if value.topLevel then return key
