
# Definitions for the Sidebar Example App

The main file for the app is located [here](sidebar-example-solo.litcoffee).

This file contains the definitions of code forms and categories as well as
their validation functions, plus translation routines for various languages.

## Registering basic code forms and categories

    registerCategory 'Coding Basics', [
        registerCodeForm 'Variable', ( group, verbose ) ->
            variableRE = /^[a-zA-Z_][a-zA-Z_0-9]*$/
            if variableRE.test group.contentAsText()
                result : 'valid'
                message : 'This is a valid variable name.'
            else
                result : 'invalid'
                message : 'This is not a valid variable name.'
                verbose : 'It must begin with a Roman letter or an
                    underscore, and contain only Roman letters, underscores,
                    or Arabic digits.'
        registerCodeForm 'Number', ( group, verbose ) ->
            numberRE = /^[+-]?([0-9]+\.[0-9]*|[0-9]*\.?[0-9]+)$/
            if numberRE.test group.contentAsText()
                result : 'valid'
                message : 'This is a valid number.'
            else
                result : 'invalid'
                message : 'This is not a valid number.'
                verbose : 'Numbers may contain only Arabic digits and one
                    optional decimal point, plus optionally a leading + or
                    - sign.'
        registerCodeForm 'Store a value', [ 'Variable', 'Number' ]
    ]

## Registering JavaScript translation

    registerTranslator 'Variable', 'javascript', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Number', 'javascript', 'code', ( group ) ->
        group.contentAsText().trim()
    registerTranslator 'Store a value', 'javascript', 'code',
        '__A__ = __B__;'
