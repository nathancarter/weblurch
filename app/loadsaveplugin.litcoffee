
# Load/Save Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage [jsfs](https://github.com/nathancarter/jsfs) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and jsfs have been loaded into the global namespace, so that it can
access both.

# `LoadSave` class

We begin by defining a class that will contain all the information needed regarding loading and saving a document.  An instance of this class will be stored as a member in the TinyMCE editor object.

    class LoadSave

## Class variables

As a class variable, we store the name of the app.  We allow changing this
by a global function defined at the end of this file.  Be default, there is
no app name.  If one is provided, it will be used when filling in the title
of the page, upon changes to the filename and/or document dirty state.

        appName: null

It comes with a setter, so that if the app name changes, all instances will
automatically change their app names as well.

        @setAppName: ( newname = null ) ->
            LoadSave::appName = newname
            instance.setAppName newname for instance in LoadSave::instances

We must therefore track all instances in a class variable.

        instances: [ ]

## Constructor

A newly-constructed document defaults to being clean, having no filename,
and being in an unnamed app.  These attributes can be changed with the
setters defined in the following section.

        constructor: ( @editor ) ->
            @setAppName LoadSave::appName
            @setFilename null
            setTimeout ( => @clear() ), 0

Whenever the contents of the document changes, we mark the document dirty in
this object, which therefore adds the \* marker to the page title.

            @editor.on 'change', ( event ) => @setDocumentDirty yes

Lastly, keep track of this instance in the class member for that purpose.

            LoadSave::instances.push this

## Setters

We then provide setters for the `@documentDirty`, `@filename`, and
`@appName` members, because changes to those members trigger the
recomputation of the page title.  The page title will be of the form "app
name: document title \*", where the \* is only present if the document is
dirty, and the app name (with colon) are omitted if none has been specified
in code.

        recomputePageTitle: ->
            document.title = "#{if @appName then @appName+': ' else ''}
                              #{@filename or '(untitled)'}
                              #{if @documentDirty then '*' else ''}"
        setDocumentDirty: ( setting = yes ) ->
            @documentDirty = setting
            @recomputePageTitle()
        setFilename: ( newname = null ) ->
            @filename = newname
            @recomputePageTitle()
        setAppName: ( newname = null ) ->
            @appName = newname
            @recomputePageTitle()

## New documents

To clear the contents of the document, use this method in its `LoadSave`
member.  It handles notifying this instance that the document is then clean.

        clear: ->
            @editor.setContent ''
            @setDocumentDirty no

# Plugin setup, etc.

The plugin, when initialized on an editor, places an instance of the
`LoadSave` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'loadsave', ( editor, url ) ->
        editor.LoadSave = new LoadSave editor

Finally, the global function that changes the app name.

    window.setAppName = ( newname = null ) -> LoadSave::appName = newname
