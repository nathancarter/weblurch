
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Attributes dialog

This module creates the functions related to the attributes dialog for an
expression in the document.  That dialog is a large and complex piece of the
UI, so it deserves to have its code grouped into a single file, this one.

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

            addRow = ( left, middle = '', right = '' ) ->
                summary += "<tr><td width=40% align=left>#{left}</td>
                                <td width=40% align=right>#{middle}</td>
                                <td width=20% align=left>#{right}</td></tr>"
            prepare = { }
            for attribute in group.attributeGroups()
                key = attribute.get 'key'
                ( prepare[key] ?= [ ] ).push attribute
            for key in group.keys()
                if decoded = OM.decodeIdentifier key
                    prepare[decoded] ?= [ ]

The following two utility functions just make it easy to encode any JSON
data as a hyperlink with a unique ID that encodes that data, and then to
invert the operation.  This way we can tag a link in the dialog with any
data we like, and it will be handed to us in our event handler for the
on-click event of the link.

            encodeLink = ( text, json ) ->
                href = OM.encodeAsIdentifier JSON.stringify json
                "<a href='#' id='#{href}'>#{text}</a>"
            decodeLink = ( href ) -> JSON.parse OM.decodeIdentifier href

This code, too, imitates that of `Group::completeForm`.

            for key, list of prepare
                if embedded = group.get OM.encodeAsIdentifier key
                    list.push group
                strictGroupComparator = ( a, b ) ->
                    strictNodeComparator a.open, b.open
                showKey = key
                for attr in list.sort strictGroupComparator
                    if attr is group
                        expression = OM.decode embedded.m
                        if expression.type is 'a' and \
                           expression.children[0].equals \
                                Group::listSymbol
                            for meaning, index in expression.children[1..]
                                addRow showKey,
                                    canonicalFormToHTML( meaning ),
                                    encodeLink( 'Remove',
                                        [ 'remove from internal list',
                                            key, index ] ) + ' ' +
                                    encodeLink 'Show', [ 'expand', key ]
                                showKey = ''
                        else
                            addRow showKey,
                                canonicalFormToHTML( expression ),
                                encodeLink( 'Remove',
                                    [ 'remove internal solo', key ] ) +
                                    ' ' +
                                encodeLink 'Show', [ 'expand', key ]
                            showKey = ''
                    else
                        addRow showKey,
                            canonicalFormToHTML( attr.canonicalForm() ),
                            encodeLink 'Remove',
                                [ 'remove external', attr.id() ]
                        showKey = ''
            if Object.keys( prepare ).length is 0
                addRow '<p>The expression has no attributes.</p>'
            summary += '</table>'

Show the dialog, and listen for any links that were clicked.

            tinymce.activeEditor.Dialogs.alert
                title : 'Attributes'
                message : summary
                onclick : ( id ) ->
                    [ type, key, index ] = decodeLink id

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
                        group.set internalKey, internalValue
                        reload()

They may have clicked "Remove" on an embedded attribute that's not part of
a list.  This case is easier; we simply remove the entire attribute and
reload the dialog.

                    else if type is 'remove internal solo'
                        group.clear OM.encodeAsIdentifier key
                        reload()

They may have clicked "Remove" on a non-embedded attribute.  This case is
also easy; we simply disconnect the attribute from the attributed group.
As usual, we then reload the dialog.

                    else if type is 'remove external'
                        tinymce.activeEditor.Groups[key].disconnect group
                        reload()

If they clicked "Expand" on any embedded attribute, we unembed it, then
reload the dialog.

                    else if type is 'expand'
                        group.unembedAttribute key
                        reload()
