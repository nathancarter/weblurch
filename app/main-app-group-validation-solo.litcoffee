
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Storing validity

The following function takes an object containing validation data, stores it
in the group, and updates the group's close grouper to include an icon and
hover text that reflects the validation data.

The data must contain the following attributes.

 * `result` - a string containing either "valid", "invalid", or
   "indeterminate"
 * `message` - a short string explaining why the validation results are what
   they are; may include HTML

The operation is performed without reference to the editor's undo/redo
manager, so that the undo/redo stack is not corrupted.  (For example, if the
user were to undo some change they had made to the document, which resulted
in revalidating some portions of it, those validation results, when saved in
the document, should not count as an "edit," or the user would be able to
use "redo" to move forward in the stack again.)

If the parameter is null, then all validation data is removed from the group
and no other action is taken.  This is a handy way to "clear" validation
data.

    window.Group::saveValidation = ( data ) ->

First, handle the case for clearing out data rather than storing new data.

        if data is null
            if @wasValidated()
                @clear 'validation'
                @clear 'closeDecoration'
                @clear 'closeHoverText'
            return

Prepare the visuals based on the data given.

        color = if data.result is 'valid' then 'green' \
            else if data.result is 'invalid' then 'red' else 'gray'
        symbol = if data.result is 'valid' then '&#10003;' \
            else if data.result is 'invalid' then '&#10006;' else '...'

Store the data and visuals in the group.

        @set 'validation', data
        @set 'closeDecoration',
            "<font color='#{color}'>#{symbol}</font>"
        @set 'closeHoverText',
            "#{data.message}\n(Double-click for details.)"

We can also test whether any validation data has been stored, and fetch the
validation data if so.

    window.Group::getValidation = -> @get 'validation'
    window.Group::wasValidated = -> @getValidation()?

## When to run validation

Let's extend the current `contentsChanged` handler for expressions so that
it runs validation if necessary.  We assume the existence of a `validate`
member in the `Group` class, which we will define immediately after this
handler.

    window.afterEditorReadyArray.push ( editor ) ->
        oldHandler = editor.Groups.groupTypes.expression.contentsChanged
        editor.Groups.groupTypes.expression.contentsChanged =
        ( group, firstTime ) ->
            oldHandler group, firstTime

Everything after this should happen after a brief delay, so that document
scanning has had a chance to complete.

            setTimeout ->

Whenever a group changes, it and anything it modifies must be revalidated.
(The only exception to this is if it is a premise, we don't need to
revalidate what it modifies, because each step in a chain of reasoning is
considered independent in Lurch.)

Furthermore, whenever a rule is revalidated, anything that cites it later in
the document must also be revalidated.  Thus we will spread the need for
revalidation outward from this group in two ways: by attribute arrows (other
than premise arrows) and by citation.

We start by creating an array to hold all the things we will find that need
revalidation.  We also create a function for adding an entry to the list.
Naturally, it doesn't add anything twice.

                groupsToRevalidate = [ ]
                addToRevalidateList = ( newGroup ) ->
                    if newGroup not in groupsToRevalidate
                        groupsToRevalidate.push newGroup

Now we create a function that adds all expressions that cite a given rule to
the list, for use when spreading revalidation according to citations, as
described above.  You can call this on any expression, and it will just do
nothing for non-rules.  If the second parameter is set to true, then *every*
step of work after this rule will be marked for revalidation, not just those
that cite *this* rule.

                addCitersToRevalidateList =
                ( ruleGroup, everything = no ) ->
                    if ruleGroup.lookupAttributes( 'rule' ).length is 0
                        return
                    allIds = editor.Groups.ids()
                    if ( start = allIds.indexOf ruleGroup.id() ) is -1
                        return
                    namesForRule = window.lookupLabelsFor ruleGroup
                    for id in allIds[start...]
                        continue unless citer = editor.Groups[id]
                        reasons = citer.lookupAttributes 'reason'
                        if everything and reasons.length > 0
                            return addToRevalidateList citer
                        for reason in reasons
                            text = if reason instanceof OM
                                reason.value
                            else
                                reason.contentAsText()
                            if text in namesForRule
                                addToRevalidateList citer

We now create a recursive function that traverses the document according to
the two spreading rules described above: attribution and citation.  The
second parameter of the recursion is for internal use; it says how the
recursion got to this point -- if it was by a step from a label, and the
current expression is a rule, then rule names changed, meaning *everything*
needs revalidating.

                recursivelyMarkForRevalidation = ( fromHere, lastStep ) ->
                    addToRevalidateList fromHere
                    addCitersToRevalidateList fromHere, lastStep is 'label'
                    key = fromHere.get 'key'
                    if key and key isnt 'premise'
                        for connection in fromHere.connectionsOut()
                            recursivelyMarkForRevalidation \
                                editor.Groups[connection[1]], key

Now let's use all these preparatory functions to do something.

Whenever a group changes, compute everything that must be revalidated, then
revalidate it.

                recursivelyMarkForRevalidation group
                for needsRevalidation in groupsToRevalidate
                    needsRevalidation.validate()
            , 0

Let's also install a `dependencyLabelsUpdated` handler so that when a
dependency is added/removed/updated, we revalidate any expression that cites
a rule defined in a dependency.

        editor.on 'dependencyLabelsUpdated', ( event ) ->
            for id in editor.Groups.ids()
                continue unless citer = editor.Groups[id]
                for reason in citer.lookupAttributes 'reason'
                    text = if reason instanceof OM
                        reason.value
                    else
                        reason.contentAsText()
                    if text in event.oldAndNewLabels
                        citer.validate()

## The validation process

### Primary API

Validating a group is defined by the following function, which calls a big
workhorse function `computeValidationAsync` on the group, then uses the
`saveValidation` member of the group on the result.  The workhorse function
is defined below.

    window.Group::validate = ->
        @plugin.editor.Storage.validationsPending ?= { }
        @plugin.editor.Storage.validationsPending[@id()] = yes
        try
            @computeValidationAsync ( result ) =>
                try
                    @saveValidation result
                    delete @plugin.editor.Storage.validationsPending[@id()]
                catch e
                    delete @plugin.editor.Storage.validationsPending[@id()]
                    throw e
        catch e
            delete @plugin.editor.Storage.validationsPending[@id()]
            throw e

The following function can be applied to any expression.  It runs validation
and passes the result to a callback.  The verbosity flag defaults to false,
to speed up the process.  This function can be run a second time with the
parameter set to true if the user specifically asks for greater detail.

This workhorse function is called internally only.  The external API is a
member of the Group class defined immediately above, and calls this one.
This function detects which of several specific validation functions it
should call, and dispatches the work to one of those functions, based on
what kind of expression is to be validated.

    window.Group::computeValidationAsync = ( callback, verbose = no ) ->
        # console.log "VALIDATING: #{@contentAsText()} (id #{@id()})"

If the expression is a rule, it gets validated differently than if it is a
step of work.  We thus dispatch to the rule-specific validation function.

        if @lookupAttributes( 'rule' ).length > 0
            return @computeRuleValidationAsync callback, verbose

If the expression has no reason attribute, we clear out any old validation,
and are done.  The expression does not need to be validated.

        if ( @lookupAttributes 'reason' ).length is 0
            return callback null

Since it does have a reason attribute, we consider it a step of work, and
dispatch the rest of the computation to that validation function.

        @computeStepValidationAsync callback, verbose

### Specialized validation routines

Here follow the definitions of the specialized validation functions called
from the dispatcher defined immediately above.

This validation function validates rules:

    ruleLanguages = [ 'JavaScript' ]
    window.Group::computeRuleValidationAsync = ( callback, verbose ) ->

First, you cannot attach a reason to a rule to support it.  Rules are
validated based solely on their structure.

        if ( @lookupAttributes 'reason' ).length > 0
            validationData =
                result : 'invalid'
                message : 'You may not attempt to justify a rule using a
                    reason.  Rule validity is determined solely by the
                    rule\'s structure.'
            if verbose
                validationData.verbose = 'Try removing all reason
                    attributes from the rule.'
            return callback validationData

Second, it must be a code-based rule, because that's all that's currently
supported.

        languages = @lookupAttributes 'code'
        if languages.length is 0
            validationData =
                result : 'invalid'
                message : 'Only code-based rules are supported at this
                    time.  This rule does not have a code attribute.'
            if verbose
                validationData.verbose = "<p>Try adding an attribute
                    with key \"code\" and value equal to the name of the
                    language in which the code is written.  Supported
                    languages:</p>
                    <ul><li>#{ruleLanguages.join '</li><li>'}</li></ul>"
            return callback validationData
        for language, index in languages
            languages[index] = if language instanceof OM
                language.value
            else
                language.canonicalForm().value
        if languages.length > 1
            validationData =
                result : 'invalid'
                message : 'This code-based rule has more than one
                    language specified, which is ambiguous.'
            if verbose
                validationData.verbose = "Too many languages
                    specified for the rule.  Only one is permitted.
                    You specified: #{languages.join ','}.  Try removing any
                    language attributes that are incorrect or unnecessary,
                    until you have only one remaining, the correct one."
            return callback validationData

Finally, it must be in one of the supported languages for code-based rules.

        if languages[0].toLowerCase() not in \
           ( r.toLowerCase() for r in ruleLanguages )
            validationData =
                result : 'invalid'
                message : "Code rules must be written in
                    #{ruleLanguages.join '/'}."
            if verbose
                validationData.verbose = "<p>The current version of
                    Lurch supports only code-based rules written in one
                    of the following languages.  The rule you cited is
                    written in #{languages[0]}, and thus cannot be
                    used.</p>
                    <ul><li>#{ruleLanguages.join '</li><li>'}</li></ul>
                    You will need to rewrite your rule in one of the
                    supported languages, and then change its language
                    attribute accordingly."
            return callback validationData

If all of those checks pass, then a rule is valid.

        callback
            result : 'valid'
            message : 'This is a valid code-based rule.'

This validation function validates steps of work:

    window.Group::computeStepValidationAsync = ( callback, verbose ) ->

If the expression has more than one reason attribute, save a validation
result that explains that this is not permitted (at most one reason per
step).

        reasons = @lookupAttributes 'reason'
        if reasons.length > 1
            validationData =
                result : 'invalid'
                message : 'You may not attach more than one reason to an
                    expression.'
            if verbose
                validationData.verbose = '<p>The following reasons are
                    attached to the expression:</p><ul>'
                for reason in reasons
                    validationData.verbose += if reason instanceof OM
                        "<li>Hidden: #{reason.value}</li>"
                    else
                        "<li>Visible: #{reason.contentAsText()}</li>"
                validationData.verbose += '</ul>'
            return callback validationData

If the (now known to be only existing) reason does not actually cite
an accessible expression, then validation fails with the appropriate
message.

        reason = reasons[0]
        reasonText = if reason instanceof OM then reason.value \
            else reason.contentAsText()
        labelPairs = lookupLabel reasonText
        if labelPairs.length is 0
            validationData =
                result : 'invalid'
                message : "No rule called #{reasonText} is accessible here."
            if verbose then validationData.verbose = validationData.message
            return callback validationData

Compute the complete form of each cited expression.

        citedExpressions = for pair in labelPairs
            if pair.target instanceof OM then pair.target else \
                pair.target.completeForm()

If none of them are rules, then validation fails with that as the reason.

        rules = ( expression for expression in citedExpressions when \
            expression.getAttribute OM.sym 'rule', 'Lurch' )
        if rules.length is 0
            validationData =
                result : 'invalid'
                message : 'The cited reason is not the name of a rule.'
            if verbose
                numFromDependencies = ( pair for pair in labelPairs when \
                    pair.target instanceof OM ).length
                validationData.verbose = "The cited reason,
                    \"#{reasonText},\" is the name of #{numFromDependencies}
                    expressions imported from other documents, and
                    #{labelPairs.length - numFromDependencies} expressions
                    in this document, accessible from the citation.  None of
                    those expressions is a rule."
            return callback validationData

If any of the cited rules are invalid, discard them.

        isValidRule = ( rule ) ->
            ruleValidationData =
                rule.getAttribute OM.sym 'validation', 'Lurch'
            if not ruleValidationData? then return no
            try
                JSON.parse( ruleValidationData.value ).result is 'valid'
            catch
                return no
        validRules = ( rule for rule in rules when isValidRule rule )

If that leaves no rules left, then validation fails, and we must explain it
to the user.

        if validRules.length is 0
            validationData =
                result : 'invalid'
                message : 'None of the cited rule are valid.'
            if verbose
                validationData.verbose = "Although there are
                    #{rules.length} rules called \"#{reasonText},\" none of
                    them have been successfully validated.  Only a valid
                    rule can be used to justify an expression."
            return callback validationData

If that leaves more than one rule left, then validation fails, and we must
explain to the user that at most one valid rule can be cited.

        if validRules.length > 1
            validationData =
                result : 'invalid'
                message : 'You may cite at most one valid rule.'
            if verbose
                validationData.verbose = "The reason \"#{reasonText}\"
                    refers to #{validRules.length} valid rules.  Only one
                    valid rule can be used at a time to justify an
                    expression."
            return callback validationData

If the unique valid cited rule is not a piece of code, the validation result
must explain that Lurch doesn't (yet?) know the type of rule cited.

        rule = validRules[0]
        language = rule.getAttribute OM.sym 'code', 'Lurch'
        if not language
            validationData =
                result : 'invalid'
                message : 'Only code-based rules are supported.'
            if verbose
                validationData.verbose = "The current version of Lurch
                    supports only code-based rules.  The rule you cited is
                    not a piece of code, and thus cannot be used."
            return callback validationData

If the language in which the rule is written isn't supported, then
validation fails, and we explain that the language used isn't yet supported.

        if language.value.toLowerCase() not in \
           ( r.toLowerCase() for r in ruleLanguages )
            validationData =
                result : 'invalid'
                message : "Code rules must be written in
                    #{ruleLanguages.join '/'}."
            if verbose
                validationData.verbose = "<p>The current version of Lurch
                    supports only code-based rules written in one of the
                    following languages.  The rule you cited is
                    written in #{language.value}, and thus cannot be
                    used.</p>
                    <ul><li>#{ruleLanguages.join '</li><li>'}</li></ul>"
            return callback validationData

Run the code in the background to validate the step of work.  Whatever the
result, save it as the expression's validation result.  Note that the code
must be the code that defines a function which accepts as argument a single
group to be validated, and returns a validation data object.  The group to
be validated will be passed in serialized form, as documented
[here](groupsplugin.litcoffee#group-serialization).

The final parameter passed to `addCodeTask` imports the OpenMath module so
that serialied groups can be decoded on the other end.

        wrappedCode = "function () {
            var conclusion = OM.decode( arguments[0] );
            var premises = [ ];
            for ( var i = 1 ; i < arguments.length ; i++ )
                premises.push( OM.decode( arguments[i] ) );
            #{rule.value}
        }"
        Background.addCodeTask wrappedCode, [ this ], ( result ) =>
            callback result ?
                result : 'invalid'
                message : 'The code in the rule did not run successfully.'
                verbose : 'The background process in which the code was to
                    be run returned no value, so the code has an error.'
        , undefined, [ 'openmath-duo.min.js' ]
