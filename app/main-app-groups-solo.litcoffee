
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
                alert 'Forming that connection would create a cycle,
                    which is not permitted.'
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

        tagMenuItems : ( group ) ->
            result = [ ]
            if group.get( 'keyposition' ) is 'source'
                result.push
                    text : "Move \"#{group.get 'key'}\" onto arrow"
                    onclick : ->
                        tinymce.activeEditor.undoManager.transact ->
                            group.set 'keyposition', 'arrow'
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

The context menu should also contain a submenu for changing the key to any
of several common choices, or "Other..." which lets the user input any text
key they choose.

            result.push
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
                        newKey = prompt 'Choose a new key:', group.get 'key'
                        if newKey
                            tinymce.activeEditor.undoManager.transact ->
                                group.set 'key', newKey
                ]

If group $A$ connects to group $B$ with key $k$, and nothing else connects
to $B$ using $k$, and $A$ connects to nothing else, then add an item for
embedding $A$ into $B$.

            connections = group.connectionsOut()
            key = group.get 'key'
            if connections.length is 1 and key isnt 'premise'
                target = tinymce.activeEditor.Groups[connections[0][1]]
                onlyOneToEmbed = yes
                for connection in target.connectionsIn()
                    source = tinymce.activeEditor.Groups[connection[0]]
                    if source.get( 'key' ) is key and source isnt group
                        onlyOneToEmbed = no
                        break
                if onlyOneToEmbed then result.push
                    text : 'Hide this attribute'
                    onclick : ->
                        numPremises =
                            ( group.attributionAncestry yes ).length -
                            ( group.attributionAncestry no ).length
                        if numPremises > 0
                            tinymce.activeEditor.Dialogs.confirm
                                message : "There are #{numPremises} premise
                                    connections that will be broken if you
                                    hide that attribute.  Continue anyway?"
                                okCallback : ->
                                    target.embedAttribute key
                        else
                            target.embedAttribute key

* If the attribution ancestry of $A$ contains any premise-type
  attributes, be sure to prompt the user that those connections will be
  broken by this action, and see if they still wish to proceed.

            result

    ]
