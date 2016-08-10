
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

    window.attributesActionForGroup = ( group ) -> ->
        summary = "<p>Expression:
            #{canonicalFormToHTML group.canonicalForm()}</p>
            <table border=0 cellpadding=5 cellspacing=0 width=100%>"
        addRow = ( left, right ) ->
            summary += if right
                "<tr><td width=50%>#{left}</td>
                     <td width=50%>#{right}</td></tr>"
            else
                "<tr colspan=2><td>#{left}</td></tr>"
        prepare = { }
        for attribute in group.attributeGroups()
            key = attribute.get 'key'
            ( prepare[key] ?= [ ] ).push attribute
        for key in group.keys()
            if decoded = OM.decodeIdentifier key
                prepare[decoded] ?= [ ]
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
                        for meaning in expression.children[1..]
                            addRow showKey, canonicalFormToHTML meaning
                    else
                        addRow showKey, canonicalFormToHTML expression
                else
                    addRow showKey, canonicalFormToHTML attr.canonicalForm()
                showKey = ''
        if Object.keys( prepare ).length is 0
            addRow '<p>The expression has no attributes.</p>'
        summary += '</table>'
        tinymce.activeEditor.Dialogs.alert
            title : 'Attributes'
            message : summary
