
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
        shortcut : 'meta+['
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
            if group instanceof ProtoGroup
                result = group.connections ? []
                for connection in result
                    if connection instanceof Array
                        if 2 not in connection then connection[2] = ''
                        connection[3] = ( context ) ->
                            context.globalAlpha = 0.5
                            context.setLineDash [ 2, 2 ]
                return result
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
            if group instanceof ProtoGroup
                group.tagContents
            else if group.get( 'keyposition' ) is 'source'
                group.get 'key'
            else
                null

In the case where the tag shows the key, as in the code immediately above,
the tag menu should let the user move the tag out onto the arrow instead.

We also include the "change attribute action" defined
[below](#auxiliary-functions).

        tagMenuItems : ( group ) ->
            result = [ ]
            if group instanceof ProtoGroup
                result.push
                    text : "Accept suggestion"
                    onclick : -> group.promote()
            else if group.connectionsOut().length > 0 and \
               group.get( 'keyposition' ) is 'source'
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
            connections = group.connectionsOut()
            key = group.get 'key'
            if connections.length > 0
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

Atomic expressions with a "code" attribute can be edited as code.

            if ( languages = group.lookupAttributes 'code' ).length > 0
                last = languages[languages.length - 1]
                if last instanceof Group then last = last.canonicalForm()
                if last.type is 'st'
                    result.push
                        text : 'Edit as code...'
                        onclick : ->
                            group.plugin.editor.Dialogs.codeEditor
                                value : group.contentAsCode()
                                okCallback : ( newCode ) ->
                                    group.plugin.editor.undoManager
                                    .transact ->
                                        group.setContentAsCode newCode

            result

Here is the handler for clicking on group boundaries ("groupers").

        clicked : ( group, numClicks, whichGrouper ) ->
            if numClicks is 'double' and whichGrouper is 'close'
                tinymce.activeEditor.Dialogs.waiting
                    title : 'Just sit tight'
                    message : 'Waiting...'
                    work : ( done ) ->
                        group.computeValidationAsync ( result ) ->
                            done()
                            tinymce.activeEditor.Dialogs.alert
                                title : 'Validation details'
                                message : "<table>
                                    <tr><td>Result:</td>
                                        <td>#{result.result}</td></tr>
                                    <tr><td>Explanation:</td>
                                        <td>#{result.message}</td></tr>
                                    <tr><td>Details:</td>
                                        <td>#{result.verbose ? \
                                        '(none available)'}</td></tr>
                                    </table>"
                        , yes

Proto-groups must be drawn more lightly than actual groups.

        setOutlineStyle : ( group, context ) ->
            if group instanceof ProtoGroup
                context.globalAlpha = 0.5
                context.setLineDash [ 2, 2 ]
        setFillStyle : ( group, context ) ->
            if group instanceof ProtoGroup
                context.globalAlpha = 0.15
                context.setLineDash [ 2, 2 ]

    ]

## Automatic grouping suggestions

Automatic grouping is a feature in Lurch by which it notices meaningful text
near the user's cursor, and suggests groups that the user may wish to form.
The user can confirm it with mouse or keyboard actions.  We install here the
functionality supporting this feature.

    window.afterEditorReadyArray.push ( editor ) ->

For now, we're using some dummy code here.  Pretend we're in a predicate
logic context, and there is a small, finite list of reasons named here.  Of
course, this will eventually be replaced with an implementation that fetches
the list of rules defined at the user's cursor point, but for testing
purposes, we're using this list, temporarily.

        reasonNames = [ 'and+', 'and-', 'or+', 'or-', 'implies+',
            'implies-', 'not+', 'not-', 'forall+', 'forall-', 'exists+',
            'exists-', '=+', '=-' ]

The following function scans a given range in the document to see if it
contains exactly any of the reason names above, or something that looks like
a sequence of characters that might form a simple mathematical expression.
This, too, is temporary code that will eventually be replaced with actual
parsing later.

        scanRangeForSuggestions = ( range ) ->
            makeProtoGroup = ->
                result = new ProtoGroup range,
                    editor.Groups.groupTypes.expression
                result.tagContents = 'Suggestion:'
                result
            text = range.toString()
            for reasonName in reasonNames
                if reasonName is text then return makeProtoGroup()
            if /^[0-9\.+*\/\^-]+$/.test text then return makeProtoGroup()
            no

The following function scans many ranges near the cursor, by passing them
all to the previous function.  It returns the first suggested group that it
detects.

        scanForSuggestions = ->
            range = editor.selection.getRng()
            if not range.collapsed
                return scanRangeForSuggestions range
            word = range.cloneRange()
            word.includeWholeWords()
            if maybe = scanRangeForSuggestions word then return maybe
            lengths = [ ]
            for reasonName in reasonNames
                if reasonName.length not in lengths
                    lengths.push reasonName.length
            lengths.sort ( a, b ) -> b - a
            for length in lengths
                for R in allRangesNearCursor length
                    if maybe = scanRangeForSuggestions R then return maybe
            no

Whenever anything changes in the document or the cursor position, we run
`scanForSuggestions` and store its results in a member of the expression
type, for use below.

        editor.on 'NodeChange KeyUp change setContent', ( event ) ->
            editor.Groups.groupTypes.expression.suggestions =
                if suggestion = scanForSuggestions()
                    [ suggestion ]
                else
                    [ ]
            editor.Overlay?.redrawContents()

The `visibleGroups` handler is what shows suggested groups to the user.
Here, it just reports anything stored by the handler installed immediately
above.

        editor.Groups.visibleGroups = ->
            editor.Groups.groupTypes.expression.suggestions ? [ ]

## Auxiliary functions

The following submenu will appear on both the tag menu and the context menu,
so we create here a function that produces it, so that we can simply call
the function twice, above.

It allows the user to change the attribute key to any of several common
choices, or "Other..." which lets the user input any text key they choose.

    changeAttributeAction = ( group ) ->
        setKey = ( value ) ->
            tinymce.activeEditor.undoManager.transact ->
                group.set 'key', value
        menuItem = ( name ) ->
            text : name, onclick : -> setKey name.toLowerCase()
        text : 'Change attribute key to...'
        menu : [
            menuItem 'Label'
        ,
            menuItem 'Reason'
        ,
            menuItem 'Premise'
        ,
            menuItem 'Rule'
        ,
            menuItem 'Code'
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
                        setKey newKey
        ]
