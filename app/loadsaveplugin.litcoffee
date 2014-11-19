
# Load/Save Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage [jsfs](https://github.com/nathancarter/jsfs) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and jsfs have been loaded into the global namespace, so that it can
access both.

We begin by defining a class that will contain all the information needed regarding loading and saving a document.  An instance of this class will be stored as a member in the TinyMCE editor object.

    class LoadSave

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

A newly-constructed document defaults to being clean, having no filename,
and being in an unnamed app.  These attributes can be changed below.  We
also track all instances in a class member of that name, to support the
above function.

        instances: [ ]
        constructor: ( @editor ) ->
            @setDocumentDirty no
            @setFilename null
            @setAppName LoadSave::appName
            LoadSave::instances.push this

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

The plugin, when initialized on an editor, places an instance of the
`LoadSave` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'loadsave', ( editor, url ) ->
        editor.LoadSave = new LoadSave editor

Finally, the global function that changes the app name.

    window.setAppName = ( newname = null ) -> LoadSave::appName = newname
