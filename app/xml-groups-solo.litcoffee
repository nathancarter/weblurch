
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
 * `alterXML` - If this key is provided, its value should be a function
   taking two parameters, a string and a Group.  The string will contain the
   XML generated from the Group, and this function is free to alter that XML
   as it sees fit, returning the (optionally changed) result, before it gets
   returned from the recursive XML-generating procedure.
 * `belongsIn` - the value should be an array of strings, each the name of a
   tag in which groups of this tag type can sit, as children.  Any gruop of
   this tag type will be marked invalid if it sits inside a group whose tag
   type is not on this list.  (See [validation](#validating-the-hierarchy).)
   A group automatically satisfies this requirement if it has no
   "belongsIn" data set for it.
 * `belongsAfter` - Functions exactly like "belongsIn" except examines the
   previous sibling rather than the parent.  The only difference is that not
   every group has a previous sibling, whereas all have a parent given that
   the document counts as a parent.  Thus if a group has "belongsAfter"
   defined but no previous sibling, it satisfies this requirement if and
   only if `null` appears on the "belongsAfter" list.
 * `unique` - if true, this indicates that only one group with this tag can
   exist in any given parent group.  Any others will be flagged as invalid
   by the validation routine.  (See
   [validation](#validating-the-hierarchy).)
 * `allowedChildren` - if present, this should be a mapping from names of
   other tags to intervals [min,max] of permitted number of occurrences of
   them as children of elements with this tag.  For instance, the Employee
   tag might have an "allowedChildren" map of
   `Client : [0,999999999], Gender : [1,1]`, which indicates that there can
   be any number of Client elements for an Employee, but only one Gender.
   This will be checked at validation time.  (See
   [validation](#validating-the-hierarchy).)  Also, the set of permitted
   child elements will be used to restrict the menu when the user attempts
   to change the type of a child; only permitted types will be active.
 * `contentCheck` - If present, this should be a function that will be run
   last in any validation of the group.  It should return an array of error
   strings describing zero or more ways the group failed to validate.  If
   the group passes validation, return an empty array.  If absent, no custom
   validation will be done; only the criteria described above will be
   applied.  If present, this function can do whatever additional custom
   validation of the document hierarchy you need.  (See
   [validation](#validating-the-hierarchy).)
 * `rawXML` - If true, this attribute means that the content of the element
   should be passed into the XML encoding raw, without being escaped.  Use
   this when you anticipate actually typing XML code into a group in the
   document, and you want that XML transferred directly to the XML encoding.

    tagData = { }
    window.setTagData = ( newData ) -> tagData = newData
    window.addTagData = ( newData ) ->
        tagData[key] = value for own key, value of newData

Use the Dialogs plugin.

    window.pluginsToLoad = [ 'dialogs' ]

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

If a group is given as the first parameter, its tag name is extracted.

    window.getTagData = ( tagName, key ) ->
        if tagName instanceof window.Group
            tagName = window.getGroupTag tagName
        tagData[tagName]?[key]

This function queries the official name associated with the given tag name.
If it has an "externalName," then that is returned.  Otherwise the given tag
name is returned unchanged.

If a group is given as the first parameter, its tag name is extracted.

    window.getTagExternalName = ( tagName ) ->
        if tagName instanceof window.Group
            tagName = window.getGroupTag tagName
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
                    onclick : ->
                        tinymce.activeEditor.Dialogs.alert
                            title : "Documentation for \"#{external}\""
                            message : documentation

Create a menu item for seeing the XML code representing the given group.

        result.push
            text : "View XML representation"
            onclick : ->
                xml = window.convertToXML group
                .replace /&/g, '&amp;'
                .replace /</g, '&lt;'
                tinymce.activeEditor.Dialogs.alert
                    title : 'XML Representation'
                    message : "<pre>#{xml}</pre>"

Create a submenu for changing the tag of this group.

        parentTag = if group.parent then window.getGroupTag group.parent \
            else window.topLevelTagName()
        allowed = window.getTagData parentTag, 'allowedChildren'
        result.push
            text : 'Change tag to...'
            menu : for tagName in Object.keys( tagData ).sort()
                do ( tagName ) ->
                    text : window.getTagExternalName tagName
                    disabled : allowed? and tagName not of allowed
                    onclick : -> group.set 'tagName', tagName

Return the full list of menu items we generated.

        result

## Define one toolbar button

This toolbar button is for viewing the XML representation of the entire
document in a new tab.

    window.groupToolbarButtons =
        viewxml :
            text : 'XML'
            tooltip : 'View XML representation of this document'
            onclick : ->
                problems = [ ]
                editor = tinymce.activeEditor
                for id in editor.Groups.ids()
                    if not isGroupRight editor.Groups[id]
                        problems.push 'At least one element in your document
                            has errors (indicated by a red X following the
                            element).'
                        break
                allowed = window.getTagData window.topLevelTagName(),
                    'allowedChildren'
                if allowed
                    problems = problems.concat \
                        allowedChildrenProblems editor.Groups.topLevel,
                            allowed, 'document'
                doExport = ->
                    xml = encodeURIComponent window.convertToXML()
                    window.open "data:application/xml,#{xml}", '_blank'
                if problems.length is 0 then return doExport()
                tinymce.activeEditor.Dialogs.confirm
                    title : 'Problems with your document'
                    message : "<p><b>The problems listed below exist in your
                    document.</b></p>
                    <ul><li>#{problems.join '</li><li>'}</li></ul>
                    <p>You can click OK to generate XML anyway, but
                    it may be invalid.  Click Cancel to go back and fix
                    these problems first.</b></p>"
                    okCallback : doExport

## Provide generic event handlers

Clients will want to install these event handlers in the group types they
define to act as XML elements in their document.  We provide these so that
they can easily install them.

They should set their group's `contentsChanged` handler to this.

    window.XMLGroupChanged = ( group, firstTime ) ->

If the group has just come into existence, we must check to see what its
default tag type should be, and initialize it to that default.  We must do
this on a delay, because when `firstTime` is true, the group does not even
yet have its parent pointer set.

        if firstTime and not group.get 'tagName'
            setTimeout ( -> window.initializeGroupTag group ), 0

And every time, revalidate the XML hierarchy at this point.

        window.validateHierarchy group

They should set their group's `deleted` handler to this.

    window.XMLGroupDeleted = ( group ) ->

We need to revalidate every other child in the same parent.  This will start
the chain reaction that does so.

        if group.parent?
            if group.parent.children[0]
                window.validateHierarchy group.parent.children[0]
        else
            if group.plugin?.topLevel[0]
                window.validateHierarchy group.plugin.topLevel[0]

## Validating the hierarchy

We will need three functions, one for marking a group as without problems,
one for marking a group as having problems (with explanations of them), and
one for detecting whether a group has problems.

    markGroupRight = ( group ) ->
        group.set 'valid', yes
        group.clear 'closeDecoration'
        group.clear 'closeHoverText'
    markGroupWrong = ( group, reason ) ->
        group.set 'valid', no
        group.set 'closeDecoration', '<font color="red">&#10006;</font>'
        group.set 'closeHoverText', reason
    isGroupRight = ( group ) -> group.get 'valid'

The following function tests to see if all of the rules specified in the
`tagData` object are followed by the given group.  Each rule that we must
validate is described individually, interleaved with its corresponding code
within the function.

    window.validateHierarchy = ( group ) ->
        problems = [ ]

If the group does not even have a children array, then it probably just
appeared, and is still being initialized.  In that case, just do validation
in 100ms isntead of now.

        if not group.children
            setTimeout ( -> window.validateHierarchy group ), 100
            return

If this group does not have a tag name, we cannot even tell if it belongs
here or not, and it will create "undefined" tags in any XML export.  That is
a problem.

        if not ( groupTag = window.getGroupTag group )?
            problems.push "Each element must have a tag, but this one does
                not.  Add a tag using the context menu."

Consider the parent of this group (or the whole document functioning as a
virtual parent group for top-level groups).  Is the parent's tag name on the
list of valid container tags for this group?

        parentTag = if group.parent then window.getGroupTag group.parent \
            else window.topLevelTagName()
        belongsIn = window.getTagData group, 'belongsIn'
        if typeof belongsIn is 'string' then belongsIn = [ belongsIn ]
        if belongsIn instanceof Array and parentTag not in belongsIn
            gname = window.getTagExternalName group
            pname = window.getTagExternalName parentTag
            bnames = ( window.getTagExternalName b for b in belongsIn )
            pname = if pname then "#{pname} elements" \
                else "in an element without a tag"
            bnames = ( window.getTagExternalName b for b in belongsIn )
            phrase = switch bnames.length
                when 1 then "this kind of element: #{bnames[0]}"
                when 2 then "these kinds of elements:
                    #{bnames.join ' and '}"
                else "these kinds of elements: #{bnames.join ', '}"
            problems.push "#{gname} elements are only permitted in
                #{phrase} (not #{pname})."

Very similar check, except for the previous sibling rather than the parent.

        prevTag = if group.previousSibling() then \
            window.getGroupTag group.previousSibling() else null
        belongsAfter = window.getTagData group, 'belongsAfter'
        if typeof belongsIn is 'string' then belongsAfter = [ belongsAfter ]
        if belongsAfter is null then belongsAfter = [ null ]
        if belongsAfter instanceof Array and prevTag not in belongsAfter
            gname = window.getTagExternalName group
            pname = window.getTagExternalName prevTag
            pname = if pname then "#{pname} elements" \
                else "being first in their context"
            bnames = ( window.getTagExternalName( b ) ? \
                "none (i.e., being the first in their context)" \
                for b in belongsAfter )
            phrase = switch bnames.length
                when 1 then "this kind of element: #{bnames[0]}"
                when 2 then "these kinds of elements:
                    #{bnames.join ' and '}"
                else "these kinds of elements: #{bnames.join ', '}"
            problems.push "#{gname} elements are only permitted to follow
                #{phrase} (not #{pname})."

If the group's tag is marked "unique" then we must check to see if there are
any previous siblings with the same tag.  If so, this one is invalid for
that reason.

        if window.getTagData group, 'unique'
            walk = group
            while walk = walk.previousSibling()
                if window.getGroupTag( walk ) is groupTag
                    problems.push "Each context may contain only one
                        \"#{window.getTagExternalName group}\" element.  But
                        there is already an earlier one in this context,
                        making this one invalid."
                    break

Check to see if the group's set of children elements are within the allowed
numbers.  To do so, we utilize the auxiliary function
`allowedChildrenProblems`, which is also used before exporting as XML, to
ensure that the top-level groups satisfy the children requirements of the
whole document.

        if allowed = window.getTagData group, 'allowedChildren'
            problems = problems.concat \
                allowedChildrenProblems group.children, allowed

If the group's tag is marked with a "contentCheck" function, we run it now
on the group, to see if it gives us any additional problems.  It returns an
array of error messages for us to append to the problems array (an empty
array if it finds no problems).

        if check = window.getTagData group, 'contentCheck'
            moreProblems = check group
            if moreProblems instanceof Array
                problems = problems.concat moreProblems

If there were any problems, mark the group as invalid.  Otherwise, clear any
indication of invalidity.

        if problems.length > 0
            markGroupWrong group, problems.join '\n'
        else
            markGroupRight group

Validating a group happens when some change has taken place that requires
revalidation.  Perhaps the tag on this group changed, for instance.  Thus we
must also check any later siblings of this group, in case they have the
"unique" attribute, which would could change their validation status based
on attributes of this group.

        if next = group.nextSibling() then window.validateHierarchy next

Here is the auxiliary function used earlier in validating counts of allowed
children.

    allowedChildrenProblems = ( children, allowed, subject = 'element' ) ->
        problems = [ ]

Get a count of how many children exist with each tag.

        counts = { }
        for child in children
            childTag = window.getGroupTag child
            counts[childTag] ?= 0
            counts[childTag]++
        for own tagName of allowed
            counts[tagName] ?= 0

Now loop through all the counts and see if any violate the restrictions in
`allowed`.  (Allowed is a mapping of the type described at the top of this
file, under the `childrenAllowed` bullet point.)  Any violations generate a
new message onto the `problems` array.

        for own tagName, count of counts
            if not allowed.hasOwnProperty tagName then continue
            [ min, max ] = allowed[tagName]
            if not min? or not max? then continue
            if typeof min isnt 'number' or typeof max isnt 'number'
                continue
            verb = if count is 1 then 'is' else 'are'
            word = if min is 1 then 'child' else 'children'
            external = window.getTagExternalName tagName
            if count < min then problems.push "The #{subject} requires at
                least #{min} #{word} with tag #{external}, but there
                #{verb} #{count} in this #{subject}."
            word = if max is 1 then 'child' else 'children'
            if count > max then problems.push "The #{subject} permits at
                most #{max} #{word} with tag #{external}, but there
                #{verb} #{count} in this #{subject}."

Return the list of problems found.

        problems

## Forming XML

The following function converts the given group (or the whole document if
none is given) into an XML representation using the data in `tagData`.

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
            result = "<#{wrapper}>#{text}</#{wrapper}>"
            if alterXML = window.getTagData wrapper, 'alterXML'
                result = alterXML result
            result
        result = if children.length
            indent = ( text ) ->
                "  #{text.replace RegExp( '\n', 'g' ), '\n  '}"
            range = children[0].rangeBefore()
            inner = ''
            if not /^\s*$/.test range.toString()
                inner += wrap tinymce.DOM.encode rangeToHTML range
            for child in children
                if inner[inner.length-1] isnt '\n' then inner += '\n'
                inner += "#{window.convertToXML child}\n"
                range = child.rangeAfter()
                if not /^\s*$/.test range.toString()
                    inner += wrap tinymce.DOM.encode rangeToHTML range
            "<#{tag}>\n#{indent inner}\n</#{tag}>"
        else
            text = if window.getTagData tag, 'rawXML'
                ( if group? then group.contentAsText() else \
                    tinymce.activeEditor.getContent format : 'text' )
                .replace /\xA0/g, '\n'
            else
                tinymce.DOM.encode \
                    if group? then group.contentAsHTML() else \
                        tinymce.activeEditor.getContent()
            wrapper ?= true
            "<#{tag}>#{wrap text}</#{tag}>"
        if alterXML = window.getTagData tag, 'alterXML'
            result = alterXML result, group
        result

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
