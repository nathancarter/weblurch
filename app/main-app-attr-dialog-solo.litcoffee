
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Attributes dialog

This module creates the functions related to the attributes dialog for an
expression in the document.  That dialog is a large and complex piece of the
UI, so it deserves to have its code grouped into a single file, this one.

We take this opportunity to document some of the conventions used internally
in storing group attributes.  There are several, and their interplay is a
bit confusing, so it deserves some documentation.

### Group Attributes

In the Groups plugin, there are [functions for setting/getting attributes in
a Group object](groupsplugin.litcoffee#group-attributes).  We will call
these *group attributes* in this documentation.

Example group attributes include connection data, bubble tag contents,
grouper decoration formatting, and validation results, among others.

 * These can be used by any script code to store any kind of attribute in a
   group.
 * Under the hood, these are stored as HTML data attributes on the open
   grouper element.  For example, if you set "color" to "blue" then the open
   grouper element has an attribute data-color="blue".
 * Consequently, the key must contain only Roman letters, decimal digits,
   hyphens, or underscores.  The keys are case-insensitive, because they are
   HTML element attributes, which are case-insensitive.
 * The values given when setting these attributes must be amenable to
   `JSON.stringify`.  They are placed inside an array (as in `[ datum ]`)
   before being stringified.
 * **The group attribute mechanism introduced in the next section is built
   upon this one, partially, as documented below.**

### Expression Attributes

Authors of Lurch documents do not think in terms of "groups," which are the
underlying technology by which we implement "expressions."  Lurch
documentation for authors speaks only in terms of expressions, not groups,
because the only type of group in the main Lurch app is "expression."

Document authors attach attributes to expressions by creating connections
among expressions (shown in the app visually with arrows), and optionally
embedding (or "hiding") such attributes within the target expression.
(Also, hidden attributes can be created without being placed in the
document first, but that is less relevant here.)

We will call these *expression attributes.*  Example expression attributes
include labels, reasons, premises, code flags, rule flags, among others.
They behave differently than group attributes, in several ways.

 * Document authors have no way of viewing or manipulating group
   attributes; those are read and written only by the application code.
 * Multiple expression attributes with the same key can be attached to the
   same target, having different values, and thus forming a list.
 * Visible expression attributes are not stored in the target group; they
   exist in the document and thus do not impact the target group's internal
   data at all.
 * Hidden expression attributes are stored as group attributes, by encoding
   the attribute key using the `OM.encodeAsIdentifier` function [documented
   here](../src/openmath-duo.litcoffee#creating-valid-identifiers) and the
   value using a combination of complete form, JSON, and LZString
   compression.  **This is the primary relationship between the group and
   expression attribute mechanisms.**
 * The `OM.encodeAsIdentifier` function produces output of the form `id_X`,
   where `X` is a sequence of decimal digits.  Thus developers accessing
   group attributes should avoid using keys of that form, to prevent
   collisions with hidden expression attributes (however unlikely).
 * The complete form of a group includes both visible and hidden expression
   attributes, and thus looks internally for keys of the form `id_X`,
   decodes them, and notices the hidden attributes stored there.  Complete
   forms do *not* include any group attributes besides those that are being
   used to encode hidden expression attributes.
 * The complete form of an expression encodes attribute keys as OpenMath
   symbols whose name is the key itself, and whose content dictionary is the
   single word "Lurch."  For this reason, we restrict expression attribute
   keys to be valid OpenMath identifiers.

## Utilities

The following routine converts any canonical form into a reasonable HTML
representation of the expression, but which is not intended for insertion
into a live document.  (It is superficial only, not containing any embedded
data.)

    canonicalFormToHTML = ( form ) ->
        type = tinymce.activeEditor.Groups.groupTypes.expression
        inside = if form.type is 'st' then form.value else \
            ( canonicalFormToHTML child for child in form.children ).join ''
        type.openImageHTML + inside + type.closeImageHTML

## The dialog action

The following function creates an on-click handler for a given group.  That
is, you call this function on a group, and it returns a function that can be
used as the on-click handler for the "Attributes..." item of the context
menu for that group.

    window.attributesActionForGroup = ( group ) ->
        reload = ->
            tinymce.activeEditor.windowManager.close()
            showDialog()
        showDialog = ->
            summary = "<p>Expression:
                #{canonicalFormToHTML group.canonicalForm()}</p>
                <table border=0 cellpadding=5 cellspacing=0 width=100%>"

Create a table listing all attributes, both external and internal.  The code
here follows a similar pattern to that in `Group::completeForm`, defined in
[another file](main-app-group-class-solo.litcoffee).

            addRow = ( key, value = '', type = '', links = '' ) ->
                summary += "<tr><td width=33% align=left>#{key}</td>
                                <td width=33% align=left>#{value}</td>
                                <td width=24% align=right>#{type}</td>
                                <td width=10% align=right>#{links}</td>
                            </tr>"
            addRule = -> summary += "<tr><td colspan=4><hr></td></tr>"
            prepare = { }
            for attribute in group.attributeGroups()
                key = attribute.get 'key'
                ( prepare[key] ?= [ ] ).push attribute
            for key in group.keys()
                if decoded = OM.decodeIdentifier key
                    prepare[decoded] ?= [ ]

The following utility functions make it easy to encode any JSON data as the
ID of a hyperlink, button, or text input, and to decode the ID as well.
This way we can tag a link/button/etc. in the dialog with any data we like,
and it will be handed to us (for decoding) in our event handler for the
on-click event of the link.

            encodeId = ( json ) -> OM.encodeAsIdentifier JSON.stringify json
            decodeId = ( href ) -> JSON.parse OM.decodeIdentifier href
            encodeLink = ( text, json, style = yes, hover ) ->
                style = if style then '' else \
                    'style="text-decoration: none; color: black;" '
                hover = if hover then " title='#{hover}'" else ''
                "<a href='#' id='#{encodeId json}' #{style} #{hover}
                  >#{text}</a>"
            encodeButton = ( text, json ) ->
                "<input type='button' id='#{encodeId json}'
                        value='#{text}'/>"
            encodeTextInput = ( text, json ) ->
                "<input type='text' id='#{encodeId json}' value='#{text}'/>"
            nonLink = ( text, hover ) ->
                "<span title='#{hover}'
                       style='color: #aaaaaa;'>#{text}</span>"

This code, too, imitates that of `Group::completeForm`.

            for key, list of prepare
                if embedded = group.get OM.encodeAsIdentifier key
                    list.push group
                strictGroupComparator = ( a, b ) ->
                    strictNodeComparator a.open, b.open
                showKey = key + ' ' +
                    encodeLink '&#x1f589;', [ 'edit key', key ], no,
                        'Edit attribute key'
                for attr in list.sort strictGroupComparator
                    if attr is group
                        expression = OM.decode embedded.m
                        if expression.type is 'a' and \
                           expression.children[0].equals \
                                Group::listSymbol
                            for meaning, index in expression.children[1..]
                                lang = null
                                if meaning.type is 'st'
                                    lang = meaning.getAttribute \
                                        OM.sym( 'code', 'Lurch' )
                                    if lang and lang.type is 'a' and \
                                       lang.children[0].equals \
                                       Group::listSymbol
                                        lang = lang.children[ \
                                            lang.children.length - 1]
                                addRow showKey,
                                    canonicalFormToHTML( meaning ) + ' ' +
                                        ( if lang then \
                                            encodeLink( '&#x1f589;',
                                                [ 'edit code from internal
                                                    list', key, index,
                                                    lang.value ], no,
                                                    'Edit as code' ) else \
                                          if meaning.type is 'st' then \
                                            encodeLink( '&#x1f589;',
                                                [ 'edit from internal list',
                                                  key, index ], no,
                                                'Edit attribute' ) else \
                                            nonLink( '&#x1f589;',
                                                'Cannot edit --
                                                 not atomic' ) ),
                                    'hidden ' + encodeLink( '&#x1f441;',
                                        [ 'show', key ], no,
                                        'Show attribute' ),
                                    encodeLink( '&#10007;',
                                        [ 'remove from internal list',
                                            key, index ], no,
                                        'Remove attribute' )
                                showKey = ''
                        else
                            lang = null
                            if expression.type is 'st'
                                lang = expression.getAttribute \
                                    OM.sym( 'code', 'Lurch' )
                                if lang and lang.type is 'a' and \
                                   lang.children[0].equals \
                                   Group::listSymbol
                                    lang = lang.children[ \
                                        lang.children.length - 1]
                            addRow showKey,
                                canonicalFormToHTML( expression ) + ' ' +
                                    ( if lang then \
                                        encodeLink( '&#x1f589;',
                                            [ 'edit code internal solo',
                                              key, lang.value ], no,
                                            'Edit as code' ) else \
                                      if expression.type is 'st' then \
                                        encodeLink( '&#x1f589;',
                                            [ 'edit internal solo', key ],
                                            no, 'Edit attribute' ) else \
                                        nonLink( '&#x1f589;',
                                            'Cannot edit -- not atomic' ) ),
                                'hidden ' + encodeLink( '&#x1f441;',
                                    [ 'show', key ], no, 'Show attribute' ),
                                encodeLink( '&#10007;',
                                    [ 'remove internal solo', key ], no,
                                    'Remove attribute' )
                            showKey = ''
                    else
                        meaning = attr.canonicalForm()
                        addRow showKey,
                            canonicalFormToHTML( meaning ) + ' ' +
                                ( if meaning.type is 'st' then \
                                    encodeLink( '&#x1f589;',
                                        [ 'edit external', attr.id() ], no,
                                        'Edit attribute' ) else \
                                    nonLink( '&#x1f589;',
                                        'Cannot edit -- not atomic' ) ),
                            'visible ' + encodeLink( '&#x1f441;',
                                [ 'hide', key ], no, 'Hide attribute' ),
                            encodeLink( '&#10007;',
                                [ 'remove external', attr.id() ], no,
                                'Remove attribute' )
                        showKey = ''
                addRule()
            summary += '</table>'
            if Object.keys( prepare ).length is 0
                summary += '<p>The expression has no attributes.</p>'
                addRule()
            summary += '<center><p>' +
                encodeLink( '<b>+</b>', [ 'add attribute' ], no,
                    'Add new attribute' ) + '</p></center>'

Show the dialog, and listen for any links that were clicked.

            tinymce.activeEditor.Dialogs.alert
                title : 'Attributes'
                message : summary
                width : 600
                onclick : ( data ) ->
                    try [ type, key, index, language ] = decodeId data.id

They may have clicked "Remove" on an embedded attribute that's just one
entry in an entire embedded list.  In that case, we need to decode the list
(both its meaning and its visuals), and remove the specified entries.  We
then put the data right back into the group from which we extracted it.

The `reload()` function just closes and re-opens this same dialog.  There
will be a brief flicker, but then its content will be up-to-date.  We can
try to remove that flicker some time in the future, or come up with a
slicker way to reload the dialog's content.

                    if type is 'remove from internal list'
                        internalKey = OM.encodeAsIdentifier key
                        internalValue = group.get internalKey
                        meaning = OM.decode internalValue.m
                        meaning = OM.app meaning.children[0],
                            meaning.children[1...index+1]...,
                            meaning.children[index+2...]...
                        visuals = decompressWrapper internalValue.v
                        visuals = visuals.split '\n'
                        visuals.splice index, 1
                        visuals = visuals.join '\n'
                        internalValue =
                            m : meaning.encode()
                            v : compressWrapper visuals
                        group.plugin.editor.undoManager.transact ->
                            group.set internalKey, internalValue
                        reload()

They may have clicked "Remove" on an embedded attribute that's not part of
a list.  This case is easier; we simply remove the entire attribute and
reload the dialog.

                    else if type is 'remove internal solo'
                        group.plugin.editor.undoManager.transact ->
                            group.clear OM.encodeAsIdentifier key
                        reload()

They may have clicked "Remove" on a non-embedded attribute.  This case is
also easy; we simply disconnect the attribute from the attributed group.
As usual, we then reload the dialog.

                    else if type is 'remove external'
                        group.plugin.editor.undoManager.transact ->
                            tinymce.activeEditor.Groups[key].disconnect \
                                group
                        reload()

If they clicked "Show" on any hidden attribute, we unembed it, then reload
the dialog.

                    else if type is 'show'
                        group.unembedAttribute key
                        reload()

If they clicked "Hide" on any visible attribute, we embed it, then reload
the dialog.

                    else if type is 'hide'
                        group.embedAttribute key
                        reload()

If they asked to change the text of a key, then prompt for a new key.  Check
to be sure the key they entered is valid, and if so, in one single undo/redo
transaction, change the keys of all external and internal attributes that
had the old key, to have the new key instead.  If it is invalid, tell the
user why.

                    else if type is 'edit key'
                        tinymce.activeEditor.Dialogs.prompt
                            title : 'Enter new key'
                            message : "Change \"#{key}\" to what?"
                            okCallback : ( newKey ) ->
                                if not /^[a-zA-Z0-9-_]+$/.test newKey
                                    tinymce.activeEditor.Dialogs.alert
                                        title : 'Invalid key'
                                        message : 'Keys can only contain
                                            Roman letters, decimal digits,
                                            hyphens, and underscores (no
                                            spaces or other punctuation).'
                                        width : 300
                                        height : 200
                                    return
                                oldInternals =
                                    group.get OM.encodeAsIdentifier key
                                newInternals =
                                    group.get OM.encodeAsIdentifier newKey
                                if oldInternals and newInternals
                                    tinymce.activeEditor.Dialogs.alert
                                        title : 'Invalid key'
                                        message : 'That key is already in
                                            use by a different hidden
                                            attribute.  You cannot rename
                                            one hidden attribute over
                                            another, because the order of
                                            combining their contents is
                                            ambiguous.  Reveal one or both
                                            attributes into the document
                                            first, to make the order clear.'
                                        width : 300
                                        height : 200
                                    return
                                tinymce.activeEditor.undoManager.transact ->
                                    attrs = group.attributeGroupsForKey key
                                    for attr in attrs
                                        attr.set 'key', newKey
                                    encKey = OM.encodeAsIdentifier key
                                    encNew = OM.encodeAsIdentifier newKey
                                    tmp = group.get encKey
                                    group.clear encKey
                                    group.set encNew, tmp
                                    reload()

They may have clicked "Edit" on an embedded attribute that's just one entry
in an entire embedded list.  In that case, we need to decode the list (both
its meaning and its visuals), and edit the specified entries.  We then put
the data right back into the group from which we extracted it.

                    if type is 'edit from internal list'
                        internalKey = OM.encodeAsIdentifier key
                        internalValue = group.get internalKey
                        meaning = OM.decode internalValue.m
                        visuals = decompressWrapper internalValue.v
                        visuals = visuals.split '\n'
                        match = /^<([^>]*)>((?:[^<]|<br>)*)<(.*)$/i.exec \
                            visuals[index]
                        if not match then return
                        tinymce.activeEditor.Dialogs.prompt
                            title : 'Enter new value'
                            message : "Provide the new content of the
                                atomic expression."
                            okCallback : ( newValue ) ->
                                meaning.children[index+1].tree.v = newValue
                                newValue = newValue.replace /&/g, '&amp;'
                                                   .replace /</g, '&lt;'
                                                   .replace />/g, '&gt;'
                                                   .replace /"/g, '&quot;'
                                                   .replace /'/g, '&apos;'
                                visuals[index] =
                                    "<#{match[1]}>#{newValue}<#{match[3]}"
                                visuals = visuals.join '\n'
                                internalValue =
                                    m : meaning.encode()
                                    v : compressWrapper visuals
                                group.plugin.editor.undoManager.transact ->
                                    group.set internalKey, internalValue
                                reload()

The same thing can happen if the hidden attribute is code.  In that case, we
do the exact same thing as in the previous case, but with a code editor.

                    else if type is 'edit code from internal list'
                        internalKey = OM.encodeAsIdentifier key
                        internalValue = group.get internalKey
                        meaning = OM.decode internalValue.m
                        visuals = decompressWrapper internalValue.v
                        visuals = visuals.split '\n'
                        match = /^<([^>]*)>((?:[^<]|<br>)*)<(.*)$/i.exec \
                            visuals[index]
                        if not match then return
                        tinymce.activeEditor.Dialogs.codeEditor
                            value : meaning.value
                            language : language
                            okCallback : ( newCode ) ->
                                meaning.children[index+1].tree.v =
                                    Group.codeToHTML newCode
                                newCode = newCode.replace /&/g, '&amp;'
                                                 .replace /</g, '&lt;'
                                                 .replace />/g, '&gt;'
                                                 .replace /"/g, '&quot;'
                                                 .replace /'/g, '&apos;'
                                visuals[index] =
                                    "<#{match[1]}>#{newCode}<#{match[3]}"
                                visuals = visuals.join '\n'
                                internalValue =
                                    m : meaning.encode()
                                    v : compressWrapper visuals
                                group.plugin.editor.undoManager.transact ->
                                    group.set internalKey, internalValue
                                reload()

They may have clicked "Edit" on an embedded attribute that's not part of a
list.  This case is very similar to editing an entry from a list, except it
does not operate on just one entry in a list, but rather the entire
expression.

                    else if type is 'edit internal solo'
                        internalKey = OM.encodeAsIdentifier key
                        internalValue = group.get internalKey
                        meaning = OM.decode internalValue.m
                        visuals = decompressWrapper internalValue.v
                        match = /^<([^>]*)>((?:[^<]|<br>)*)<(.*)$/i.exec \
                            visuals
                        if not match then return
                        tinymce.activeEditor.Dialogs.prompt
                            title : 'Enter new value'
                            message : "Provide the new content of the
                                atomic expression."
                            okCallback : ( newValue ) ->
                                meaning.tree.v = newValue
                                newValue = newValue.replace /&/g, '&amp;'
                                                   .replace /</g, '&lt;'
                                                   .replace />/g, '&gt;'
                                                   .replace /"/g, '&quot;'
                                                   .replace /'/g, '&apos;'
                                visuals =
                                    "<#{match[1]}>#{newValue}<#{match[3]}"
                                internalValue =
                                    m : meaning.encode()
                                    v : compressWrapper visuals
                                group.plugin.editor.undoManager.transact ->
                                    group.set internalKey, internalValue
                                reload()

The same thing can happen if the hidden attribute is code.  In that case, we
do the exact same thing as in the previous case, but with a code editor.

                    else if type is 'edit code internal solo'
                        internalKey = OM.encodeAsIdentifier key
                        internalValue = group.get internalKey
                        meaning = OM.decode internalValue.m
                        visuals = decompressWrapper internalValue.v
                        match = /^<([^>]*)>((?:[^<]|<br>)*)<(.*)$/i.exec \
                            visuals
                        if not match then return
                        tinymce.activeEditor.Dialogs.codeEditor
                            value : meaning.value
                            language : index
                            okCallback : ( newValue ) ->
                                meaning.tree.v = Group.codeToHTML newValue
                                newValue = newValue.replace /&/g, '&amp;'
                                                   .replace /</g, '&lt;'
                                                   .replace />/g, '&gt;'
                                                   .replace /"/g, '&quot;'
                                                   .replace /'/g, '&apos;'
                                visuals =
                                    "<#{match[1]}>#{newValue}<#{match[3]}"
                                internalValue =
                                    m : meaning.encode()
                                    v : compressWrapper visuals
                                group.plugin.editor.undoManager.transact ->
                                    group.set internalKey, internalValue
                                reload()

They may have clicked "Edit" on a non-embedded attribute.  This case is also
easy; we simply change the contents of the attribute group.  As usual, we
then reload the dialog.

                    else if type is 'edit external'
                        tinymce.activeEditor.Dialogs.prompt
                            title : 'Enter new value'
                            message : "Provide the new content of the
                                atomic expression."
                            okCallback : ( newValue ) ->
                                group.plugin[key].setContentAsText newValue
                                reload()

If the user clicks "Add attribute," we choose a new key and atomic value,
which the user can then edit thereafter.

                    else if type is 'add attribute'
                        index = 1
                        key = -> OM.encodeAsIdentifier "attribute#{index}"
                        index++ while group.get key()
                        meaning = OM.string 'edit this'
                        grouper = ( type ) ->
                            result = grouperHTML 'expression', type, 0, no
                            if type is 'open'
                                result = result.replace 'grouper',
                                    'grouper mustreconnect'
                            result
                        visuals = grouper( 'open' ) + meaning.value +
                            grouper 'close'
                        internalValue =
                            m : meaning.encode()
                            v : compressWrapper visuals
                        group.plugin.editor.undoManager.transact ->
                            group.set key(), internalValue
                        reload()
