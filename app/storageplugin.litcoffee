
# Storage Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage
[the cloud storage module](https://github.com/lurchmath/cloud-storage) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and the cloud storage module have been loaded into the global
namespace, so that it can access both.  It provides both in-cloud and
in-browser storage.

# `Storage` class

We begin by defining a class that will contain all the information needed
regarding loading and saving documents to various storage back-ends.  An
instance of this class will be stored as a member in the TinyMCE editor
object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Storage

## Class variables

As a class variable, we store the name of the app.  We allow changing this
by a global function defined at the end of this file.  Be default, there is
no app name.  If one is provided, it will be used when filling in the title
of the page, upon changes to the filename and/or document dirty state.

        appName: null

It comes with a setter, so that if the app name changes, all instances will
automatically change their app names as well.

        @setAppName: ( newname = null ) ->
            Storage::appName = newname
            instance.setAppName newname for instance in Storage::instances

We must therefore track all instances in a class variable.

        instances: [ ]

## Constructor

        constructor: ( @editor ) ->

Clients can specify the app's name in a class variable, and all instances
will use it by default.  At the end of this file is a global function for
setting the app name in the class variable.

            @setAppName Storage::appName

Install all back-ends supported by this plugin, and default to the simplest.

            @backends =
                'browser storage' : new LocalStorageFileSystem()
                'Dropbox' : new DropboxFileSystem '7mfyk58haigi2c4'
            @setBackend 'browser storage'

The "last file object" is one returned by
[the cloud storage module](https://github.com/lurchmath/cloud-storage),
with information about the last file opened or saved.  It can be used to
re-save the current file in the same location.  It defaults to null,
meaning that we have not yet opened or saved any files.

            @setLastFileObject null

A newly-constructed document defaults to being clean.

            setTimeout ( => @clear() ), 0

The following handlers exist for wrapping metadata around a document before
saving, or unwrapping after loading.  They default to null, but can be
overridden by a client by direct assignment of functions to these members.

The `saveMetaData` function should take no inputs, and yield as output a
single object encoding all the metadata as key-value pairs in the object.
It will be saved together with the document content.

The `loadMetaData` function should take as input one argument, an object
that was previously created by the a call to `saveMetaData`, and repopulate
the UI and memory with the relevant portions of that document metadata.  It
is called immediately after a document is loaded.  It is also called when a
new document is created, with an empty object to initialize the metadata.

            @saveMetaData = @loadMetaData = null

Whenever the contents of the document changes, we mark the document dirty in
this object, which therefore adds the \* marker to the page title.

            @editor.on 'change', ( event ) => @setDocumentDirty yes

Now install into the editor controls that run methods in this object.  The
`control` method does something seemingly inefficient to duplicate the input
data object to pass to `addButton`, but this turns out to be necessary, or
the menu items look like buttons.  (I believe TinyMCE manipulates the object
upon receipt.)

            control = ( name, data ) =>
                buttonData =
                    icon : data.icon
                    shortcut : data.shortcut
                    onclick : data.onclick
                    tooltip : data.tooltip
                key = if data.icon? then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData
                @editor.addMenuItem name, data
            control 'newfile',
                text : 'New'
                icon : 'newdocument'
                context : 'file'
                shortcut : 'meta+alt+N'
                tooltip : 'New file'
                onclick : => @tryToClear()
            control 'savefile',
                text : 'Save'
                icon : 'save'
                context : 'file'
                shortcut : 'meta+S'
                tooltip : 'Save file'
                onclick : => @tryToSave()
            @editor.addMenuItem 'saveas',
                text : 'Save as...'
                context : 'file'
                shortcut : 'meta+shift+S'
                onclick : => @tryToSave null, yes
            control 'openfile',
                text : 'Open...'
                icon : 'browse'
                context : 'file'
                shortcut : 'meta+O'
                tooltip : 'Open file...'
                onclick : => @handleOpen()

Lastly, keep track of this instance in the class member for that purpose.

            Storage::instances.push this

## Setters and getters

We then provide setters for the `@documentDirty`, `@filename`, and
`@appName` members, because changes to those members trigger the
recomputation of the page title.  The page title will be of the form "app
name: document title \*", where the \* is only present if the document is
dirty, and the app name (with colon) are omitted if none has been specified
in code.

        recomputePageTitle: =>
            document.title = "#{if @appName then @appName+': ' else ''}
                              #{@getFilename() or '(untitled)'}
                              #{if @documentDirty then '*' else ''}"
        setDocumentDirty: ( setting = yes ) =>
            @documentDirty = setting
            @recomputePageTitle()
        setAppName: ( newname = null ) =>
            @appName = newname
            @recomputePageTitle()

We can also set which back-end is used for storage, which comes with a
related getters for listing all back-ends, or getting the current one.

        availableBackends: => Object.keys @backends
        getBackend: => @backend
        setBackend: ( which ) =>
            console.log 'setting back end', which
            if which in @availableBackends()
                @backend = which
                window.setFileSystem @backends[@backend]
                console.log @backends[@backend]

The following function is useful for storing file objects provided by
[the cloud storage module](https://github.com/lurchmath/cloud-storage), and
for querying the filename from them.

        setLastFileObject: ( fileObject ) =>
            @lastFileObject = fileObject
            @recomputePageTitle()
        getFilename: => @lastFileObject?.path?.slice()?.pop()

## Embedding metadata and code

Here are two functions for embedding metadata into/extracting metadata from
the HTML content of a document.  These are useful before saving and after
loading, respectively.  They use an invisible span on the front of the
document containing the encoded metadata, which can be any object amenable
to JSON.

        embedMetadata: ( documentHTML, metadataObject = { } ) ->
            encoding = encodeURIComponent JSON.stringify metadataObject
            "<span id='metadata' style='display: none;'
             >#{encoding}</span>#{documentHTML}"
        extractMetadata: ( html ) ->
            re = /^<span[^>]+id=.metadata.[^>]*>([^<]*)<\/span>/
            if match = re.exec html
                metadata : JSON.parse decodeURIComponent match[1]
                document : html[match[0].length..]
            else
                metadata : null
                document : html

Here are two functions for appending a useful script to the end of an HTML
document, and removing it again later.  These functions are inverses of one
another, and can be used before/after saving a document, to append the
script in question.  The script is useful as follows.

If the user double-clicks a Lurch file stored on their local disk (e.g.,
through Dropbox syncing), the behavior they expect will happen:  Because
Lurch files are HTML, the user's default browser opens the file, the script
at the end runs, and its purpose is to reload the same document, but in the
web app that saved it, thus in an active editor rather than as merely a
static view of the content.

        addLoadingScript: ( document ) ->
            currentHref = window.location.href.split( '?' )[0]
            """
            <div id="EmbeddedLurchDocument">#{document}</div>
            <script>
                elt = document.getElementById( 'EmbeddedLurchDocument' );
                window.location.href = '#{currentHref}'
                  + '?document=' + encodeURIComponent( elt.innerHTML );
            </script>
            """
        removeLoadingScript: ( document ) ->
            openTag = '<div id="EmbeddedLurchDocument">'
            closeTag = '</div>'
            openIndex = document.indexOf openTag
            closeIndex = document.lastIndexOf closeTag
            document[openIndex+openTag.length...closeIndex]

## New documents

To clear the contents of the editor, use this method in its `Storage`
member.  It handles notifying this instance that the document is then clean.
It does *not* check to see if the document needs to be saved first; it just
outright clears the editor.  It also clears the filename, so that if you
create a new document and then save, it does not save over your last
document.

        clear: =>
            @editor.setContent ''
            @editor.undoManager.clear()
            @setDocumentDirty no
            @loadMetaData? { }

Unlike the previous, this function *does* first check to see if the contents
of the editor need to be saved.  If they do, and they aren't saved (or if
the user cancels), then the clear is aborted.  Otherwise, clear is run.

        tryToClear: =>
            if not @documentDirty
                @clear()
                @editor.focus()
                return
            @editor.windowManager.open {
                title : 'Save first?'
                buttons : [
                    text : 'Save'
                    onclick : =>
                        @tryToSave ( success ) => if success then @clear()
                        @editor.windowManager.close()
                ,
                    text : 'Discard'
                    onclick : =>
                        @clear()
                        @editor.windowManager.close()
                ,
                    text : 'Cancel'
                    onclick : => @editor.windowManager.close()
                ]
            }

## Saving documents

This function tries to save the current document.  When the save has been
completed or canceled, the callback will be called, with one of the
following parameters:  `false` means the save was canceled, `true` means it
succeeded, and any string means there was an error.  If the save succeeded,
the internal `@filename` field of this object may have been updated.

To force a save into a file other than the current `@filename`, pass a true
value as the second parameter, and "Save As..." behavior will be invoked.

        tryToSave: ( callback, saveAs = no ) ->

### Compute content to save

Get the contents of the editor and embed in them any metadata the app may
have about the document, then wrap them in the loading script mentioned
above.

            content = @editor.getContent()
            content = @embedMetadata content, @saveMetaData?()
            content = @addLoadingScript content

### If saving in same location as last time

If we are capable of re-saving over top of the most recently loaded/saved
file, *and* that's what the caller asked of us, then let's do so, using the
`update` method of the object returned from the last call do `openFile` or
`saveFile`.  That method takes three parameters: the new content, the
success callback, and the failure callback.

            if not saveAs and @lastFileObject
                filename = @lastFileObject.path.slice().pop()
                return @editor.Dialogs.waiting
                    title : 'Saving file'
                    message : 'Please wait...'
                    work : ( done ) =>
                        @lastFileObject.update content, ( success ) =>
                            @setDocumentDirty no
                            done()
                        , ( error ) =>
                            done()
                            @editor.Dialogs.alert
                                title : 'Error saving file'
                                message : "<h1>File not saved!</h1>
                                           <p>File NOT saved to
                                           #{@backend}:<br>
                                           #{filename}</p>
                                           <p>Reason: #{error}</p>"

### If not saving in same location as last time

If we have reached this point, then either we are not capable of re-saving
over top of the most recently loaded/saved file, or the caller asked us to
prompt the user for a filename before saving, and so in either case we must
do that prompting.

The `window.saveFile` function is installed by [the cloud storage tools
mentioned above](https://lurchmath.github.io/cloud-storage/).  Its first
argument is the success callback from the dialog.

            window.saveFile ( destination ) =>

It provides an object in which we can call the `update` method to overwrite
the file's contents.

                @setLastFileObject destination
                filename = @lastFileObject.path.slice().pop()

The first argument to the `update` function is the new content to write.
The second and third are the success and failure callbacks from the save
operation.

                @editor.Dialogs.waiting
                    title : 'Saving file'
                    message : 'Please wait...'
                    work : ( done ) =>
                        destination.update content, ( success ) =>
                            done()
                            @setDocumentDirty no
                        , ( error ) =>
                            done()
                            @editor.Dialogs.alert
                                title : 'Error saving file'
                                message : "<h1>File not saved!</h1>
                                           <p>File NOT saved to
                                           #{@backend}:<br>
                                           #{filename}</p>
                                           <p>Reason: #{error}</p>"

## Loading documents

The following function can be called when a document has been loaded from
storage, and it will place the document into the editor.  This includes
extracting the metadata from the document and loading that, if needed, as
well as making several adjustments to the editor itself in recognition of a
newly loaded file.

        loadIntoEditor: ( loadedData ) =>
            loadedData = @removeLoadingScript loadedData
            { document, metadata } = @extractMetadata loadedData
            @editor.setContent document
            @editor.undoManager.clear()
            @editor.focus()
            @setDocumentDirty no
            @loadMetaData? metadata ? { }

This function lets the user choose a new document to open.  If the user
successfully chooses one, the callback will be called with its only
parameter being the contents of the file as loaded from whatever storage
back-end is currently in use.  A very sensible callback to use is the
`loadIntoEditor` function defined immediately above, which we use as the
default.

        tryToOpen: ( callback = ( data ) => @loadIntoEditor data ) =>

The `window.openFile` function is installed by [the cloud storage tools
mentioned above](https://lurchmath.github.io/cloud-storage/).  Its first
argument is the success callback from the dialog.

            window.openFile ( chosenFile ) =>

It provides an object in which we can call the `get` method to load the
file's contents.  We store that object so that we can call `update` in it
later, if the user clicks "Save."

                @setLastFileObject chosenFile

The first argument to the `get` function is the success callback from the
load operation.

                @editor.Dialogs.waiting
                    title : 'Loading file'
                    message : 'Please wait...'
                    work : ( done ) =>
                        chosenFile.get ( contents ) =>

The success handler just hands things off to the `loadIntoEditor` function.

                            @loadIntoEditor contents
                            done()

The `get` function might also return an error, which we report here.

                        , ( error ) =>
                            @setLastFileObject null
                            done()
                            @editor.Dialogs.alert
                                title : 'File load error'
                                message : "<h1>Error loading file</h1>
                                           <p>The file failed to load from
                                           #{@backend}, with an error of
                                           type #{error}.</p>"

The file dialog might also return an error, which we report here.

                    , ( error ) =>
                        done()
                        @editor.Dialogs.alert
                            title : 'File dialog error',
                            message : "<h1>Error in file dialog</h1>
                                       <p>The file dialog gave the following
                                       error: #{error}.</p>"

The following handler for the "open" controls checks with the user to see if
they wish to save their current document first, if and only if that document
is dirty.  The user may save, or cancel, or discard the document.

        handleOpen: =>

First, if the document does not need to be saved, just do a regular "open."

            if not @documentDirty then return @tryToOpen()

Now, we know that the document needs to be saved.  So prompt the user with a
dialog box asking what they wish to do.

            @editor.windowManager.open {
                title : 'Save first?'
                buttons : [
                    text : 'Save'
                    onclick : =>
                        @editor.windowManager.close()
                        @tryToSave ( success ) => @tryToOpen() if success
                ,
                    text : 'Discard'
                    onclick : =>
                        @editor.windowManager.close()
                        @tryToOpen()
                ,
                    text : 'Cancel'
                    onclick : => @editor.windowManager.close()
                ]
            }

# Direct access

It is also possible to read a file directly from or write a file directly to
a particular storage back-end.  This is uncommon, because usually the user
should be involved.  However, there are times when files need to be opened
for inspection in the background, or temporary files saved, and this
interface can be useful for that.

The following function reads a file directly from a given back-end.  The
first parameter is the name of the back-end, the second is an array of the
full path to the file, and the final two arguments are callback functions.
The first receives the contents of the file, and the second receives an
error message; exatly one of the two will be called.

The function does nothing if the first parameter is not the name of one of
the back-ends installed in this object.

        directRead: ( backend, filepath, success, failure ) =>
            @backends[backend]?.readFile filepath, success, failure

The following is analogous, but for writing a file instead.  The only change
is the new third argument, which is the content to be written.

        directWrite: ( backend, filepath, content, success, failure ) =>
            @backends[backend]?.writeFile filepath, content,
                success, failure

# Global stuff

## Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Storage` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'storage', ( editor, url ) ->
        editor.Storage = new Storage editor

## Global functions

Finally, the global function that changes the app name.

    window.setAppName = ( newname = null ) -> Storage::appName = newname
