
# Load/Save Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage [jsfs](https://github.com/nathancarter/jsfs) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and jsfs have been loaded into the global namespace, so that it can
access both.

We begin by defining a class that will contain all the information needed regarding loading and saving a document.  An instance of this class will be stored as a member in the TinyMCE editor object.

    class LoadSave

A newly-constructed document defaults to being clean.

        constructor: ( @editor ) ->
            @setDocumentDirty no
            @setFilename null

We then provide setters for the `@documentDirty` and `@filename` members,
because there will be events triggered when they are changed.  Those events
are not yet present in the code below, but these setters have been written
to prepare for those events later.

        setDocumentDirty: ( setting = yes ) ->
            @documentDirty = setting
        setFilename: ( newname = null ) ->
            @filename = newname

The plugin, when initialized on an editor, places an instance of the
`LoadSave` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'loadsave', ( editor, url ) ->
        editor.LoadSave = new LoadSave editor
