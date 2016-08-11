
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Group types

The design calls for just one group type, but if we need more later, this is
where we will add them.

    window.groupTypes = [
        name : 'expression'
        text : 'Expression'
        imageHTML : '<font color="#996666">[ ]</font>'
        openImageHTML : '<font color="#996666">[</font>'
        closeImageHTML : '<font color="#996666">]</font>'
        tooltip : 'Make the selected text an expression'
        color : '#996666'
        shortcut : 'Ctrl+['
        LaTeXshortcut : '\\['

You can form a connection from any expression to any other, provided that no
cycle of connections is formed in the process.  Thus we write the
`reachable` function to test whether its first argument can (through zero or
more steps through connections) reach its second argument.

        connectionRequest : ( from, to ) ->
            reachable = ( source, target ) ->
                if source is target then return yes
                for c in source.connectionsOut()
                    next = tinymce.activeEditor.Groups[c[1]]
                    if reachable next, target then return yes
                no
            if reachable to, from
                from.plugin.editor.Dialogs.alert
                    title : 'Cannot connect expressions'
                    message : 'Forming that connection would create a cycle
                        of connections among expressions, which is not
                        permitted.'
            else
                tinymce.activeEditor.undoManager.transact ->
                    from.connect to
                    if not from.get 'key' then from.set 'key', 'label'
                    if not from.get 'keyposition'
                        from.set 'keyposition', 'arrow'

When drawing expressions, draw all arrows that come in or go out.  (The
default is to only draw arrows that go out; we override that here, so that
an expression highlights both its attributes and those things for which it
is an attribute.)

        connections : ( group ) ->
            outs = group.connectionsOut()
            ins = group.connectionsIn()
            for cxn in [ ins..., outs... ]
                source = tinymce.activeEditor.Groups[cxn[0]]
                if source.get( 'keyposition' ) is 'arrow'
                    cxn[2] = source.get 'key'
                if source.get( 'key' ) is 'premise'
                    cxn[3] = ( context ) -> context.setLineDash [ 3, 3 ]
            [ outs..., ins...,
              ( t[1] for t in outs )..., ( t[0] for t in ins )... ]

An expression used as an attribute, with the key stored in the attribute
itself, will show that key on its bubble tag.

        tagContents : ( group ) ->
            if group.get( 'keyposition' ) is 'source'
                group.get 'key'
            else
                null

In the case where the tag shows the key, as in the code immediately above,
the tag menu should let the user move the tag out onto the arrow instead.

We also include the "change attribute action" defined
[below](#auxiliary-functions).

        tagMenuItems : ( group ) ->
            result = [ ]
            if group.get( 'keyposition' ) is 'source'
                result.push
                    text : "Move \"#{group.get 'key'}\" onto arrow"
                    onclick : ->
                        tinymce.activeEditor.undoManager.transact ->
                            group.set 'keyposition', 'arrow'
                result.push changeAttributeAction group
            result

However, when the attribute key is already shown on the arrow, the
expression should have a context menu item for moving it back.

        contextMenuItems : ( group ) ->
            result = [ ]
            if group.get( 'keyposition' ) is 'arrow'
                result.push
                    text : "Move \"#{group.get 'key'}\" onto attribute"
                    onclick : ->
                        tinymce.activeEditor.undoManager.transact ->
                            group.set 'keyposition', 'source'

We also include the "change attribute action" defined
[below](#auxiliary-functions).

            result.push changeAttributeAction group

If group $A$ connects to groups $B_1$ through $B_n$ with key $k$, and
nothing else connects to any $B_i$ using $k$, then add an item for embedding
$A$ into each $B_i$.

            connections = group.connectionsOut()
            key = group.get 'key'
            if connections.length > 0 and key isnt 'premise'

Here we check whether all the $B_i$ have only $A$ attributing them using
$k$.

                targets = ( tinymce.activeEditor.Groups[connection[1]] \
                    for connection in connections )
                allHaveJustThisGroupAsAttributeForKey = yes
                for target in targets
                    if target.attributeGroupsForKey( key ).length > 1
                        allHaveJustThisGroupAsAttributeForKey = no
                        break
                if allHaveJustThisGroupAsAttributeForKey then result.push
                    text : 'Hide this attribute'
                    onclick : ->

This is the action we will take, unless there are warnings that cause the
user to cancel.

                        doIt = ->
                            tinymce.activeEditor.undoManager.transact ->
                                for target, index in targets
                                    last = index == targets.length - 1
                                    target.embedAttribute key, last
                                    if not last
                                        group.connect targets[index+1]
                        warnings = ''

We create a warning if they are embedding the attribute in more than one
expression, just to be sure they're aware of that.

                        if targets.length > 1
                            warnings += "You are hiding this attribute in
                                #{targets.length} expressions.  "

We create a warning if they will break premise connections by this
embedding, again, just to be sure they're aware.

                        numPremises =
                            ( group.attributionAncestry yes ).length -
                            ( group.attributionAncestry no ).length
                        if numPremises > 0
                            warnings += "There are #{numPremises} premise
                                connections that will be broken if you
                                hide that attribute.  "

Either execute the action immediately, or if there are warnings, execute it
if and only if the user chooses to continue despite the warnings.

                        if warnings.length > 0
                            tinymce.activeEditor.Dialogs.confirm
                                title : 'Warning'
                                message : "#{warnings}Continue anyway?"
                                okCallback : doIt
                        else
                            doIt()

Alternatively, if $n=1$ (i.e., there is only one target group, $B_1$), but
there are many groups $A_1$ through $A_k$ that attribute it, all with the
same key, we can embed all of them in the one target, as follows.  We
require that none of the $A_i$ also modifies any group other than $B_1$.

                else if targets.length is 1
                    target = targets[0]
                    sources = target.attributeGroupsForKey key
                    anySourceModifiesAnotherGroup = no
                    for source in sources
                        if source.connectionsOut().length > 1
                            anySourceModifiesAnotherGroup = yes
                            break
                    if not anySourceModifiesAnotherGroup then result.push
                        text : 'Hide this attribute'
                        onclick : ->

This is the action we will take, unless the user chooses to cancel after
seeing the warning(s).

                            doIt = ->
                                tinymce.activeEditor.undoManager.transact ->
                                    for target, index in targets
                                        last = index == targets.length - 1
                                        target.embedAttribute key, last
                                        if not last
                                            group.connect targets[index+1]
                            warnings = "You are about to hide not one
                                attribute, but #{sources.length}, all of
                                type #{key}.  "

We create a warning if they will break premise connections by this
embedding, again, just to be sure they're aware.

                            numPremises = 0
                            for source in sources
                                numPremises += \
                                ( source.attributionAncestry yes ).length -
                                ( source.attributionAncestry no ).length
                            if numPremises > 0
                                warnings += "There are #{numPremises}
                                    premise connections that will be broken
                                    if you hide that attribute.  "

Either execute the action immediately, or if there are warnings, execute it
if and only if the user chooses to continue despite the warnings.

                            if warnings.length > 0
                                tinymce.activeEditor.Dialogs.confirm
                                    title : 'Warning'
                                    message : "#{warnings}Continue anyway?"
                                    okCallback : doIt
                            else
                                doIt()

Every expression has a context menu item for seeing its attributes
summarized in a dialog.

            result.push
                text : 'Attributes...'
                onclick : window.attributesActionForGroup group

            result

    ]

## Auxiliary functions

The following submenu will appear on both the tag menu and the context menu,
so we create here a function that produces it, so that we can simply call
the function twice, above.

It allows the user to change the attribute key to any of several common
choices, or "Other..." which lets the user input any text key they choose.

    changeAttributeAction = ( group ) ->
        text : 'Change attribute key to...'
        menu : [
            text : 'Label'
            onclick : ->
                tinymce.activeEditor.undoManager.transact ->
                    group.set 'key', 'label'
        ,
            text : 'Reason'
            onclick : ->
                tinymce.activeEditor.undoManager.transact ->
                    group.set 'key', 'reason'
        ,
            text : 'Premise'
            onclick : ->
                tinymce.activeEditor.undoManager.transact ->
                    group.set 'key', 'premise'
        ,
            text : 'Other...'
            onclick : ->
                tinymce.activeEditor.Dialogs.prompt
                    title : 'Enter new key'
                    message : "Change \"#{group.get 'key'}\" to what?"
                    okCallback : ( newKey ) ->
                        if not /^[a-zA-Z0-9-_]+$/.test newKey
                            tinymce.activeEditor.Dialogs.alert
                                title : 'Invalid key'
                                message : 'Keys can only contain Roman
                                    letters, decimal digits, hyphens, and
                                    underscores (no spaces or other
                                    punctuation).'
                                width : 300
                                height : 200
                            return
                        tinymce.activeEditor.undoManager.transact ->
                            group.set 'key', newKey
        ]
