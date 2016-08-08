
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Group class extensions

In this app, groups have a special attribute called "canonical form," which
we want to be able to compute conveniently for all groups.  So we extend the
Group class itself.

The canonical form of an atomic group (one with no children) is the text
content of the group, which we encode as an OpenMath string.  The canonical
form of a non-atomic group is just the array of children of the group, which
we encode as an OpenMath application with the children in the same order.

    window.Group.prototype.canonicalForm = ->
        if @children.length is 0
            OM.str @contentAsText()
        else
            OM.app ( child.canonicalForm() for child in @children )...

Groups can also compute the list of attributes attached to them, returning
it as an array.  We provide the following extension to the Group class to
accomplish this.

    window.Group.prototype.attributeGroups = ( includePremises = no ) ->
        result = [ ]
        for connection in @connectionsIn()
            source = tinymce.activeEditor.Groups[connection[0]]
            if key = source.get 'key'
                if not includePremises and key is 'premise' then continue
                result.push source
        result

The following function is like the transitive closure of the previous; it
gives all groups that directly or indirectly attribute this group.

    window.Group.prototype.attributionAncestry = ( includePremises = no ) ->
        result = [ ]
        for group in @attributeGroups includePremises
            for otherGroup in [ group, group.attributionAncestry()... ]
                if otherGroup not in result then result.push otherGroup
        result

Leveraging the idea of a list of groups that attribute a given group, we can
implement the notion of "complete form."  This is the same as canonical
form, except that all attributes of the encoded group are also encoded,
using OpenMath attributions.  The keys are encoded as symbols using their
own names, and "Lurch" as the content dictionary.

    window.Group.prototype.completeForm = ( includePremises = no ) ->
        result = @canonicalForm()
        prepare = { }
        for group in @attributeGroups includePremises
            key = group.get 'key'
            ( prepare[key] ?= [ ] ).push group
        for key, list of prepare
            list = ( group.completeForm includePremises \
                for group in list.sort strictNodeComparator )
            result = OM.att result, OM.sym( key, 'Lurch' ),
                if list.length is 1
                    list[0]
                else
                    OM.app OM.sym( 'List', 'Lurch' ), list...
        result

Now we add a member function to the group class for embedding in an
expression an attribute expression, including its entire attribution
ancestry.

    window.Group.prototype.embedAttribute = ( key ) ->

For now, we support only the case where there is exactly one attribute
expression with the given key.

        groups = ( g for g in @attributeGroups() \
            when g.get( 'key' ) is key )
        if groups.length isnt 1 then return

The key to use inside this group is the expression key, encoded so that it
can function as an OpenMath identifier.  The value to use will have two
fields, the first ("m" for meaning) will be the complete form of the
attribute to embed.

        internalKey = OM.encodeAsIdentifier key
        internalValue = m : g.completeForm()

The second ("v" for visual) will be its representation in HTML form, for
later extraction back into the document if the user so chooses.  Before
computing that HTML representation, we disconnect the attribute from this
group.

        groups[0].disconnect this
        ancestry = groups[0].attributionAncestry()
        ancestry.sort strictNodeComparator
        internalValue.v = LZString.compress \
            ( g.groupAsHTML no for g in [ groups[0], ancestry... ] ).join ''

Embed the data, then remove the attribute expression from the document.
Then delete every expression in the attribution ancestry iff it's not also
attributing another node outside the attribution ancestry.  Do all of this
in a single undo/redo transaction.

        groups[0].plugin.editor.undoManager.transact =>
            this.set internalKey, internalValue
            groups[0].remove()
            ancestorIds = [
                groups[0].id()
                ( a.id() for a in ancestry )...
            ]
            for ancestor in ancestry
                hasConnectionToNonAncestor = no
                for connection in ancestor.connectionsOut()
                    if connection[1] not in ancestorIds
                        hasConnectionToNonAncestor = yes
                        break
                ancestor.remove() unless hasConnectionToNonAncestor
