
# Dropbox Plugin for [TinyMCE](http://www.tinymce.com)

This plugin provides functions for loading *Lurch* documents from and saving
*Lurch* documents to a user's Dropbox.

# `Dropbox` class

We begin by defining a class that will contain all the information needed
about the overlay element and how to use it.  An instance of this class will
be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Dropbox

We construct new instances of the Dropbox class as follows, and these are
inserted as members of the corresponding editor by means of the code [below,
under "Installing the Plugin."](#installing-the-plugin)

        constructor: ( @editor ) ->

The constructor does not yet take any action.

            @editor.on 'init', => # pass

The following function can be used as a handler for the "File > Open" event
in the UI (or the Open button on the toolbar).

It assumes that it will be installed as an open handler in [the LoadSave
plugin](loadsaveplugin.litcoffee), and thus uses `this` as if it were that
plugin.

        openHandler: ->
            window.Dropbox.choose
                success : ( files ) => $.ajax
                    url : files[0].link
                    success : ( result ) =>
                        { metadata, document } = extractMetadata result
                        tinymce.activeEditor.setContent document
                        if metadata? then @loadMetaData metadata
                        @setFilename files[0].name
                    error : ( jqxhr, message, error ) ->
                        editor.Dialogs.alert
                            title : 'File load error'
                            message : "<h1>Error loading file</h1>
                                       <p>The file failed to load from the
                                       URL Dropbox provided, with an error
                                       of type #{message}.</p>"
                linkType : 'direct'
                multiselect : no

The following function can be used as a handler for the "File > Save" event
in the UI (or the Save button on the toolbar).  Unfortunately, the Dropbox
Saver does not allow us to specify a file path, and have the save completed
without the user's direct involvement.  Thus "Save" cannot happen in just
one click; the user must choose where to save each time.  We hope to add
functionality for an improved user experience in a future commit.

It assumes that it will be installed as an open handler in [the LoadSave
plugin](loadsaveplugin.litcoffee), and thus uses `this` as if it were that
plugin.

        saveHandler: ->
            content = embedMetadata editor.getContent(), @saveMetaData()
            url = 'data:text/html,' + encodeURIComponent content
            if not editor.LoadSave.filename?
                @setFilename prompt 'Choose a filename',
                    'My Lurch Document.html'
                if not @filename?
                    editor.Dialogs.alert
                        title : 'Saving requires a filename'
                        message : 'You must specify a filename before
                            you can save the file into your Dropbox.'
                    return
            window.Dropbox.save url, @filename,
                success : =>
                    editor.Dialogs.alert
                        title : 'File saved successfully.'
                        message : "<h1>Saved successfully.</h1>
                                   <p>File saved to Dropbox:<br>
                                   #{@filename}</p>"
                    @setDocumentDirty no
                error : ( message ) =>
                    editor.Dialogs.alert
                        title : 'Error saving file'
                        message : "<h1>File not saved!</h1>
                                   <p>File NOT saved to Dropbox:<br>
                                   #{@filename}</p>
                                   <p>Reason: #{message}</p>"

The following function can be used as a handler for the "File > Manage
files" event in the UI.  It simply navigates to [dropbox.com], because that
website will show the user his or her own Dropbox.

        manageFilesHandler: ->
            window.location.href = 'https://www.dropbox.com'

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dropbox` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dropbox', ( editor, url ) ->
        editor.Dropbox = new Dropbox editor
