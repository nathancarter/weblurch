
# Dropbox Plugin for [TinyMCE](http://www.tinymce.com)

This plugin provides functions for loading *Lurch* documents from and saving
*Lurch* documents to a user's Dropbox.

**Warning:**  This plugin assumes that [the cloud storage tools developed
here](https://lurchmath.github.io/cloud-storage/) are available in the page
in which the Lurch app is running.  Visit that project's website to see how
you can import its code conveniently from a CDN to satisfy this requirement.

# `Dropbox` class

We begin by defining a class that will contain all the information needed
about the Dropbox plugin and how to use it.  An instance of this class will
be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Dropbox

## Constructor

We construct new instances of the Dropbox class as follows, and these are
inserted as members of the corresponding editor by means of the code [below,
under "Installing the Plugin."](#installing-the-plugin)

The constructor creates a field in which we will store the last filename
used by any load/save operation, to re-use if they hit "Save" again.

        constructor: ( @editor ) ->
            @lastFileObject = null

## Open handler

The following function can be used as a handler for the "File > Open" event
in the UI (or the Open button on the toolbar).

It assumes that it will be installed as an open handler in [the LoadSave
plugin](loadsaveplugin.litcoffee), and thus uses `this` as if it were that
plugin.

        openHandler: ->

The `window.openFile` function is installed by [the cloud storage tools
mentioned above](https://lurchmath.github.io/cloud-storage/).  Its first
argument is the success callback from the dialog.

            window.openFile ( chosenFile ) =>

It provides an object in which we can call the `get` method to load the
file's contents.  We store that object so that we can call `update` in it
later, if the user clicks "Save."

                @editor.Dropbox.lastFileObject = chosenFile

The first argument to the `get` function is the success callback from the
load operation.

                chosenFile.get ( contents ) =>

The corresponding [save handler](#save-handler), below, wraps content in a
DIV (for reasons explained below), so we must undo that operation here.  The
following section of code finds the interior of the main DIV, by finding its
open tag, then counting open and close DIV tags until we've found the
corresponding close one.

                    open = '<div id="EmbeddedLurchDocument">'
                    start = contents.indexOf open
                    if start > -1
                        start += open.length
                        rest = contents.substring start
                        interior = ''
                        munge = ( n ) ->
                            interior += rest.substring 0, n
                            rest = rest.substring n
                        nextDivTag = /<\s*([/]?)\s*div(>|\s+)/i
                        depth = 1
                        while match = nextDivTag.exec rest
                            munge match.index
                            if match[1] is '/'
                                depth--
                            else
                                depth++
                            if depth is 0
                                rest = ''
                                break
                            else
                                munge match[0].length
                        munge rest.length
                        contents = interior

Now we can extract the metadata from the interior of the main DIV, and
finish.

                    { metadata, document } = extractMetadata contents
                    @editor.setContent document
                    if metadata? then @loadMetaData metadata
                    @setFilename chosenFile.path.slice().pop()

The `get` function might also return an error, which we report here.

                , ( error ) =>
                    @editor.Dialogs.alert
                        title : 'File load error'
                        message : "<h1>Error loading file</h1>
                                   <p>The file failed to load from the
                                   URL Dropbox provided, with an error
                                   of type #{error}.</p>"

The file dialog might also return an error, which we report here.

            , ( error ) =>
                @editor.Dialogs.alert
                    title : 'File dialog error',
                    message : "<h1>Error in file dialog</h1>
                               <p>The file dialog gave the following
                               error: #{error}.</p>"

## Save handler

The following function can be used as a handler for the "File > Save" event
in the UI (or the Save button on the toolbar).

It assumes that it will be installed as an open handler in [the LoadSave
plugin](loadsaveplugin.litcoffee), and thus uses `this` as if it were that
plugin.

        saveHandler: ( callback, filename ) ->
            content = embedMetadata @editor.getContent(), @saveMetaData()

We begin by wrapping the document content in a DIV, so that we can separate
it from a simple, one-line JavaScript block.  The purpose of that block is
so that if the user visits his or her Dropbox on their hard drive and
double-clicks a Lurch file to open it, the correct handling will (probably)
transpire.  That is, because Lurch files are HTML, the user's default
browser should open the file.  As soon as it finishes loading, the script at
the end will run, which reloads the same file in the web app that saved it,
which will be an active editor rather than a static view of the document's
content.

            content = '<div id="EmbeddedLurchDocument">' + \
                      content + \
                      "</div>
                      <script>
                      window.location.href =
                          '#{window.location.href.split( '?' )[0]}'
                        + '?document='
                        + encodeURIComponent(
                            EmbeddedLurchDocument.innerHTML );
                      </script>"
            url = 'data:text/html,' + encodeURIComponent content

If we are capable of re-saving over top of the most recently loaded/saved
file, *and* that's what the caller asked of us, then let's do so, using the
`update` method of the object returned from the last call do `openFile` or
`saveFile`.  That method takes three parameters: the new content, the
success callback, and the failure callback.

            if filename? and lfo = @editor.Dropbox.lastFileObject
                lastFilename = lfo.path.slice().pop()
                if lastFilename is filename
                    lfo.update content, ( successMessage ) =>
                        @editor.Dialogs.alert
                            title : 'File saved successfully.'
                            message : "<h1>Saved successfully.</h1>
                                       <p>File saved to Dropbox:<br>
                                       #{filename}</p>"
                    , ( failureMessage ) =>
                        @editor.Dialogs.alert
                            title : 'Error saving file'
                            message : "<h1>File not saved!</h1>
                                       <p>File NOT saved to Dropbox:<br>
                                       #{filename}</p>
                                       <p>Reason: #{failureMessage}</p>"
                    return

If we have reached this point, then we are not capable of re-saving over top
of the most recently loaded/saved file, and thus (regardless of what the
caller asked for) we must prompt the user for the filename.

The `window.saveFile` function is installed by [the cloud storage tools
mentioned above](https://lurchmath.github.io/cloud-storage/).  Its first
argument is the success callback from the dialog.

            window.saveFile ( destination ) =>

It provides an object in which we can call the `update` method to overwrite
the file's contents.

                @editor.Dropbox.lastFileObject = destination
                filename = destination.path.slice().pop()

The first argument to the `update` function is the new content to write.
The second and third are the success and failure callbacks from the save
operation.

                destination.update content, ( successMessage ) =>
                    @editor.Dialogs.alert
                        title : 'File saved successfully.'
                        message : "<h1>Saved successfully.</h1>
                                   <p>File saved to Dropbox:<br>
                                   #{filename}</p>"
                    @setDocumentDirty no
                , ( failureMessage ) =>
                    @editor.Dialogs.alert
                        title : 'Error saving file'
                        message : "<h1>File not saved!</h1>
                                   <p>File NOT saved to Dropbox:<br>
                                   #{filename}</p>
                                   <p>Reason: #{failureMessage}</p>"

The following function can be used as a handler for the "File > Manage
files" event in the UI.  It simply navigates to [dropbox.com], because that
website will show the user his or her own Dropbox.

        manageFilesHandler: ->
            window.location.href = 'https://www.dropbox.com'

# Installing the plugin

    tinymce.PluginManager.add 'dropbox', ( editor, url ) ->

The plugin, when initialized on an editor, places an instance of the
`Dropbox` class inside the editor, and points the class at that editor.
Apps that wish to use this plugin should make calls to the various methods
in the [Load/Save Plugin](loadsaveplugin.litcoffee), installing the methods
defined in this plugin into that one (`installOpenHandler`,
`installSaveHandler`, and `installManageFilesHandler`).

        editor.Dropbox = new Dropbox editor

It then installs a Dropbox file system (as defined in [the cloud storage
tools](https://lurchmath.github.io/cloud-storage/)) with the Dropbox API key
for the Lurch project and the CDN URL to the login page.

        window.setFileSystem new DropboxFileSystem '7mfyk58haigi2c4'
