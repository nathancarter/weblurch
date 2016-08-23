
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
            if @hasValidation()
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

The following function can be applied to any expression.  It runs validation
and stores the result in the group.  The verbosity flag defaults to false,
to speed up the process.  This function can be run a second time with the
parameter set to true in those situations where the user specifically asks
for greater detail.

    window.Group::validate = ( verbose = no ) ->

If the expression has no reason attribute, we clear out any old validation,
and are done.

        reasons = @attributeGroupsForKey 'reason'
        if reasons.length is 0 then return @saveValidation null

If the expression has more than one reason attribute, save a validation
result that explains that this is not permitted (at most one reason per
step).

        if reasons.length > 1
            return @saveValidation
                result : 'invalid'
                message : 'You may not attach more than one reason to an
                    expression.'
