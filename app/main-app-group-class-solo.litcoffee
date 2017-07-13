
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Canonical and complete form

In this app, groups have a special attribute called "canonical form," which
we want to be able to compute conveniently for all groups.  So we extend the
Group class itself.

The canonical form of an atomic group (one with no children) is the text
content of the group, which we encode as an OpenMath string.  The canonical
form of a non-atomic group is just the array of children of the group, which
we encode as an OpenMath application with the children in the same order.

Rather than use `contentAsText()` here, we use `contentAsCode()`, because it
pays attention to tabs and newlines, whereas `contentAsText()` simply
reduces them all to spaces.  Thus `contentAsCode()` is more faithful to the
appearance in the document, and preserves more of what the author expects.

    window.Group::canonicalForm = ->
        if @children.length is 0
            OM.str @contentAsCode()
        else
            OM.app ( child.canonicalForm() for child in @children )...

Groups can also compute the list of attributes attached to them, returning
it as an array.  We provide the following extension to the Group class to
accomplish this.

    window.Group::attributeGroups = ( includePremises = no ) ->
        result = [ ]
        for connection in @connectionsIn()
            source = tinymce.activeEditor.Groups[connection[0]]
            if key = source.get 'key'
                if not includePremises and key is 'premise' then continue
                result.push source
        result

We can get the attributes that just have a specific key by simply filtering
the results of the previous function.

    window.Group::attributeGroupsForKey = ( key ) ->
        ( group for group in @attributeGroups( yes ) \
            when group.get( 'key' ) is key )

The following function is like the transitive closure of the previous; it
gives all groups that directly or indirectly attribute this group.

    window.Group::attributionAncestry = ( includePremises = no ) ->
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

    window.Group::listSymbol = OM.sym 'List', 'Lurch'
    window.Group::completeForm = ( includePremises = no ) ->

Start with canonical form.

        result = @canonicalForm()

Find all attribute groups and store them in a dictionary.  For hidden
attributes, ensure they show up as keys in the dictionary as well.

        prepare = { }
        for group in @attributeGroups includePremises
            key = group.get 'key'
            ( prepare[key] ?= [ ] ).push group
        for key in @keys()
            if decoded = OM.decodeIdentifier key
                prepare[decoded] ?= [ ]

Now loop through the dictionary.

        for own key, list of prepare

If there are hidden attributes, include the group itself as an attribute of
itself.

            if embedded = @get OM.encodeAsIdentifier key
                list.push this

Sort the list of attribute groups by the order they appear in the document.

            meanings = [ ]
            strictGroupComparator = ( a, b ) ->
                strictNodeComparator a.open, b.open
            for group in list.sort strictGroupComparator

Form the meaning list, either by extracting the embedded attribute value or
looking up the external attribute value.

                if group is this
                    expression = OM.decode embedded.m
                    if expression.type is 'a' and \
                       expression.children[0].equals Group::listSymbol
                        meanings = meanings.concat expression.children[1..]
                    else
                        meanings.push expression
                else
                    meanings.push group.completeForm includePremises

Store either the meanings list as a list expression, or the single meaning
as a single expression, depending on the length of the meanings list.

            result = OM.att result, OM.sym( key, 'Lurch' ),
                if meanings.length is 1
                    meanings[0]
                else
                    OM.app Group::listSymbol, meanings...

If the expression has validation data, we must convert that to an attribute,
even though technically it is not one.  We do this here so as not to expose
validation results as editable attributes to the user; we simply cram them
into the complete form here before returning the result.

Note that `@getValidation` is defined in
[a separate file](main-app-group-validation-solo.litcoffee).

            if validationData = @getValidation()
                result = OM.att result, OM.sym( 'validation', 'Lurch' ),
                    OM.str JSON.stringify validationData
        result

Now that `Group::completeForm` exists, let's use that to serialize groups
for background processes, rather than the old, simple `toJSON` routine
that's the default in the Groups plugin.

    window.Group::toJSON = -> @completeForm().encode()

## Looking up attributes

To find out the attributes a group has for a specific key, call the
following function.  It returns an array of zero or more items.  The array
will include at least the results of `attributeGroupsForKey`, but it will
also include, at the appropriate place in the array (based on document
ordering) any internal attributes with the same key.

Internal attributes in the result array will be OpenMath objects, while
external attributes will be Group instances; the caller will need to be able
to handle both types of data.  For instance, the caller could simply call
`canonicalForm` or `completeForm` on the Group instances to convert them all
to OpenMath objects.

    window.Group::lookupAttributes = ( key ) ->
        list = @attributeGroupsForKey key
        if embedded = @get OM.encodeAsIdentifier key then list.push this
        result = [ ]
        strictGroupComparator = ( a, b ) ->
            strictNodeComparator a.open, b.open
        for group in list.sort strictGroupComparator
            if group is this
                expression = OM.decode embedded.m
                if expression.type is 'a' and \
                   expression.children[0].equals Group::listSymbol
                    result = result.concat expression.children[1..]
                else
                    result.push expression
            else
                result.push group
        result

## Embedding and unembedding attributes

Now we add a member function to the group class for embedding in an
expression an attribute expression, including its entire attribution
ancestry.

The second parameter can be set to false to tell the routine not to delete
the group from the document after embedding.  This is primarily useful when
embedding an attribute in many targets; you can embed it without deletion in
the first $n-1$, and then delete it on the $n$th embedding.

    window.Group::embedAttribute = ( key, andDelete = yes ) ->

For now, we support only the case where there is exactly one attribute
expression with the given key.

        groups = ( g for g in @attributeGroups() \
            when g.get( 'key' ) is key )

The key to use inside this group is the expression key, encoded so that it
can function as an OpenMath identifier.  The value to use will have two
fields, the first ("m" for meaning) will be the complete form of the
attribute to embed.

        internalKey = OM.encodeAsIdentifier key
        internalValue = m : if groups.length is 1
            groups[0].completeForm()
        else
            OM.app Group::listSymbol,
                   ( g.completeForm() for g in groups )...
        internalValue.m = internalValue.m.encode()

The second ("v" for visual) will be its representation in HTML form, for
later extraction back into the document if the user so chooses.  Before
computing that HTML representation, we disconnect the attribute from all its
targets.  Consequently, since we now begin modifying the document, we do all
of this in a single undo/redo transaction.

        @plugin.editor.undoManager.transact =>
            internalValue.v = ''
            for group in groups
                for connection in group.connectionsOut()
                    target = tinymce.activeEditor.Groups[connection[1]]
                    group.disconnect target
                ( $ group.open ).addClass 'mustreconnect'
                ancestry = group.attributionAncestry()
                ancestry.sort strictNodeComparator
                if internalValue.v.length > 0 then internalValue.v += '\n'
                internalValue.v += ( g.groupAsHTML no \
                    for g in [ group, ancestry... ] ).join ''
            internalValue.v = compressWrapper internalValue.v

Embed the data, then remove the attribute expression from the document.
Then delete every expression in the attribution ancestry iff it's not also
attributing another node outside the attribution ancestry.

            this.set internalKey, internalValue

If they've asked us to delete the group from the document, do so here.  If
not, stop at this point.

            return unless andDelete
            for group in groups
                group.remove()
                ancestry = group.attributionAncestry()
                ancestry.sort strictNodeComparator
                ancestorIds = [
                    group.id()
                    ( a.id() for a in ancestry )...
                ]
                for ancestor in ancestry
                    hasConnectionToNonAncestor = no
                    for connection in ancestor.connectionsOut()
                        if connection[1] not in ancestorIds
                            hasConnectionToNonAncestor = yes
                            break
                    ancestor.remove() unless hasConnectionToNonAncestor

The reverse process of the previous function is the following function, for
moving an embedded attribute (or a list of them) back out into the document.

The parameter here is the key for the attribute, as it was stored in the
attribute expression before embedding.  The code for `embedAttribute` alters
this key to make it a valid OpenMath identifier, but this parameter is the
unaltered (original) key.  If there is no embedded attribute with that key,
this function does nothing.

    window.Group::unembedAttribute = ( key, useCurrentCursor = no ) ->
        if not value = @get OM.encodeAsIdentifier key then return
        html = decompressWrapper value.v
        meaning = OM.decode value.m

We add the "justPasted" flag to all groupers before pasting, so that
`scanDocument` can correctly renumber them if needed, while keeping any
connections intact.

        grouperClassRE =
            /class=('[^']*grouper[^']*'|"[^"]*grouper[^"]*")/
        modifiedHTML = ''
        while match = grouperClassRE.exec html
            modifiedHTML += html.substr( 0, match.index ) +
                            match[0].substr( 0, match[0].length - 1 ) +
                            ' justPasted' +
                            match[0].substr match[0].length - 1
            html = html.substr match.index + match[0].length
        modifiedHTML += html

Now begin the transaction that modifies the document.

        @plugin.editor.undoManager.transact =>

We only move the cursor if the second parameter says to do so.

            if not useCurrentCursor
                range = @rangeAfter()
                range.collapse yes
                @plugin.editor.selection.setRng range

Insert the HTML for the embedded attribute(s).

            @plugin.editor.insertContent modifiedHTML

Scan the document so that the newly inserted groups are registered, enabling
us to call "connect" on them to make them attributes of the group out of
which they were just unembedded.  Furthermore, ensure that the key of each
is set to the key it had while embedded.  This is important because the key
may have been edited while it was embedded, which was not reflected in the
(zipped) HTML representation stored in the attributed expression.
Furthermore, if the attribute was just created, it may not have a key
position, so we supply a default.

            @plugin.scanDocument()
            $ @plugin.editor.getDoc()
            .find '.grouper.mustreconnect'
            .each ( index, grouper ) =>
                g = @plugin.grouperToGroup grouper
                g.connect this
                g.set 'key', key
                g.set 'keyposition', 'arrow' unless g.get 'keyposition'
                ( $ grouper ).removeClass 'mustreconnect'

Now delete the embedding data from within the attributed expression.

            @clear OM.encodeAsIdentifier key

## Compression

The `LZString.compress` and `LZString.decompress` functions would be ideal
for compression in this module, but unfortunately they have the following
problem.  They occasionally create characters with codes above 55000, and in
Chrome, characters in that range are not copied and pasted faithfully in
HTML.  (It replaces them with the `&thinsp;` character, which has code
65533, and thus corrupts the compressed data, so that it cannot be
decompressed.)

Consequently, we create wrappers around the LZString compression and
decompression routines here.  These begin by removing the (usually large)
`src` attributes from grouper `img` tags.  Then we perform
`LZString.compress` and `decompress`, but modifying the results to avoid the
problematic character range.

    maxCharCode = 50000
    window.compressWrapper = ( string ) ->
        grouperRE = /<img\s+([^>]*)\s+src=('[^']*'|"[^"]*")([^>]*)>/
        while match = grouperRE.exec string
            string = string.substr( 0, match.index ) +
                     "<img #{match[1]} #{match[2]}>" +
                     string.substr match.index + match[0].length
        string = LZString.compress string
        result = ''
        for i in [0...string.length]
            if ( code = string.charCodeAt( i ) ) < maxCharCode
                result += string[i]
            else
                result += String.fromCharCode( 50000 ) +
                          String.fromCharCode( code - 50000 )
        result

When groupers are placed back into the document, their `src` attributes are
automatically refreshed anyway.  So we have no need to attempt to put them
back here.  Instead, we just have to undo the charCode manipulation done by
the compress wrapper.

    window.decompressWrapper = ( string ) ->
        result = ''
        while string.length > 0
            if ( code = string.charCodeAt 0 ) < maxCharCode
                result += string[0]
                string = string.substr 1
            else
                result += String.fromCharCode code + string.charCodeAt 1
                string = string.substr 2
        LZString.decompress result

## Code attributes

The following extension to the Group class reads the contents of a group,
replaces all `&emsp;` characters with tabs, and all paragraph breaks or line
breaks with `\n` characters.  Keep in mind that webLurch responds to the tab
key by inserting an `&emsp;` character, so this is a sensible conversion.
In reality, it is not only paragraph breaks that are counted as newlines,
but any transition into or out of a block-level element.

Note that sometimes TinyMCE stores an extra BR at the end of a paragraph.
For this reason, we do not translate final BR tags inside a parent node as
newlines.

    window.Group::contentAsCode = ->
        shouldBreak = ( node ) -> node.tagName in [ 'P', 'DIV' ]
        recur = ( nodeOrList ) =>
            if nodeOrList?.nodeType is 3 # HTML Text node
                return nodeOrList.textContent.replace /\u2003/g, '\t'
            if nodeOrList.tagName is 'BR' then return '\n'
            result = ''
            for index in [0...nodeOrList.childNodes.length]
                if index > 0 and \
                   ( shouldBreak( nodeOrList.childNodes[index-1] ) or \
                     shouldBreak( nodeOrList.childNodes[index] ) )
                    result += '\n'
                if index < nodeOrList.childNodes.length - 1 or \
                   nodeOrList.childNodes[index].tagName isnt 'BR'
                    result += recur nodeOrList.childNodes[index]
            result
        recur @contentAsFragment()

The following is the inverse of the previous operation.  You can give it
code using plain text (newlines and tabs) and it will replace the contents
of the group with that same code, converted to use BR tags and `&emsp;`
characters in place of tabs.

    window.Group::setContentAsCode = ( code ) ->
        @setContentAsText Group.codeToHTML code
    window.Group.codeToHTML = ( code ) ->
        code.replace /&/g, '&amp;'
            .replace /</g, '&lt;'
            .replace />/g, '&gt;'
            .replace /"/g, '&quot;'
            .replace /'/g, '&apos;'
            .replace /\n/g, '<br>'
            .replace /\t/g, '&emsp;'
