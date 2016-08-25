
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

The operation is performed as a single undo/redo transaction.  If the group
does not have access to the Groups plugin, the function does nothing.

If the parameter is null, then all validation data is removed from the group
in a single undo/redo transaction, and no other action is taken.  This is a
handy way to "clear" validation data.

    window.Group::saveValidation = ( data ) ->

First, handle the case for clearing out data rather than storing new data.

        if data is null
            if @wasValidated()
                @plugin?.editor.undoManager.transact =>
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

        @plugin?.editor.undoManager.transact =>
            @set 'validation', data
            @set 'closeDecoration',
                "<font color='#{color}'>#{symbol}</font>"
            @set 'closeHoverText', data.message

We can also test whether any validation data has been stored, and fetch the
validation data if so.

    window.Group::getValidation = -> @get 'validation'
    window.Group::wasValidated = -> @getValidation()?

## Running validation

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

Whenever a group changes, re-validate it.

                group.validate()

Whenever a reason attribute changes, re-validate each of its targets.

                if group.get( 'key' ) is 'reason'
                    for connection in group.connectionsOut()
                        editor.Groups[connection[1]]?.validate()

Whenever a rule changes, re-validate everything that follows it and that
cites it.

                if group.lookupAttributes( 'rule' ).length > 0
                    labels = window.lookupLabelsFor group
                    allIds = editor.Groups.ids()
                    return unless ( start = allIds.indexOf group.id() ) > -1
                    for id in allIds[start...]
                        continue unless otherGroup = editor.Groups[id]
                        for reason in otherGroup.lookupAttributes 'reason'
                            text = if reason instanceof OM
                                reason.value
                            else
                                reason.contentAsText()
                            if text in labels then otherGroup.validate()
            , 0

The following function can be applied to any expression.  It runs validation
and stores the result in the group.  The verbosity flag defaults to false,
to speed up the process.  This function can be run a second time with the
parameter set to true in those situations where the user specifically asks
for greater detail.

    window.Group::validate = ( verbose = no ) ->
        # console.log "VALIDATING: #{@contentAsText()} (id #{@id()})"
        reasons = @lookupAttributes 'reason'
        ruleLanguages = [ 'JavaScript' ]

If the expression is a rule, it gets validated differently than if it is a
step of work.  Rules have the following requirements:

First, you cannot attach a reason to a rule to support it.  Rules are
validated based solely on their structure.

        if @lookupAttributes( 'rule' ).length > 0
            if reasons.length > 0
                validationData =
                    result : 'invalid'
                    message : 'You may not attempt to justify a rule using a
                        reason.  Rule validity is determined solely by the
                        rule\'s structure.'
                if verbose
                    validationData.verbose = 'Try removing all reason
                        attributes from the rule.'
                return @saveValidation validationData

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
                return @saveValidation validationData
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
                        You specified: #{languages.join ','}."
                return @saveValidation validationData

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
                        <ul><li>#{ruleLanguages.join '</li><li>'}</li></ul>"
                return @saveValidation validationData

If all of those checks pass, then a rule is valid.

            return @saveValidation
                result : 'valid'
                message : 'This is a valid code-based rule.'
                verbose : 'This is a valid code-based rule.'

With the rule case taken care of, the rest of this function considers the
case where the expression is a step of work, not a rule.

If the expression has no reason attribute, we clear out any old validation,
and are done.

        if reasons.length is 0 then return @saveValidation null

If the expression has more than one reason attribute, save a validation
result that explains that this is not permitted (at most one reason per
step).

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            return @saveValidation validationData

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
            @saveValidation result ?
                result : 'invalid'
                message : 'The code in the rule did not run successfully.'
                verbose : 'The background process in which the code was to
                    be run returned no value, so the code has an error.'
        , undefined, [ 'openmath-duo.min.js' ]
