
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
and using the app name as the filesystem name.  These attributes can be
changed with the setters defined in the following section.

        constructor: ( @editor ) ->
            @setAppName LoadSave::appName
            @setFileSystem @appName
            @setFilepath FileSystem::pathSeparator # root
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
is called immediately after a document is loaded.

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
                key = if data.icon then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData
                @editor.addMenuItem name, data
            control 'newfile',
                text : 'New'
                icon : 'newdocument'
                context : 'file'
                shortcut : 'ctrl+N'
                onclick : => @tryToClear()
            control 'savefile',
                text : 'Save'
                icon : 'save'
                context : 'file'
                shortcut : 'ctrl+S'
                onclick : => @tryToSave()
            @editor.addMenuItem 'saveas',
                text : 'Save as...'
                context : 'file'
                shortcut : 'ctrl+shift+S'
                onclick : => @tryToSave null, ''
            control 'openfile',
                text : 'Open...'
                icon : 'browse'
                context : 'file'
                shortcut : 'ctrl+O'
                onclick : => @handleOpen()
            @editor.addMenuItem 'managefiles',
                text : 'Manage files...'
                context : 'file'
                onclick : => @manageFiles()

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
        setFilepath: ( newpath = null ) -> @filepath = newpath
        setAppName: ( newname = null ) ->
            mustAlsoUpdateFileSystem = @appName is @fileSystem
            @appName = newname
            if mustAlsoUpdateFileSystem then @fileSystem = @appName
            @recomputePageTitle()
        setFileSystem: ( newname = @appName ) -> @fileSystem = newname

## New documents

To clear the contents of the document, use this method in its `LoadSave`
member.  It handles notifying this instance that the document is then clean.
It does *not* check to see if the document needs to be saved first; it just
outright clears the editor.  It also clears the filename, so that if you
create a new document and then save, it does not save over your last
document.

        clear: ->
            @editor.setContent ''
            @setDocumentDirty no
            @setFilename null

Unlike the previous, this function *does* first check to see if the contents
of the editor need to be saved.  If they do, and they aren't saved (or if
the user cancels), then the clear is aborted.  Otherwise, clear is run.

        tryToClear: ->
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

To save the current document under the filename in the `@filename` member,
call the following function.  It returns a boolean indicating success or
failure.  If there is no filename in the `@filename` member, failure is
returned and no action taken.  If the save succeeds, mark the document
clean.

        save: ->
            if @filename is null then return
            tmp = new FileSystem @fileSystem
            tmp.cd @filepath
            objectToSave = [ @editor.getContent(), @saveMetaData?() ]
            if tmp.write @filename, objectToSave, yes # use compression
                @setDocumentDirty no

This function tries to save the current document.  When the save has been
completed or canceled, the callback will be called, with one of the
following parameters:  `false` means the save was canceled, `true` means it
succeeded, and any string means there was an error.  If the save succeeded,
the internal `@filename` field of this object may have been updated.

To force a save into a file other than the current `@filename`, pass the
other filename as the optional second parameter.  To force "save as"
behavior when there is a current `@filename`, pass null as the optional
second parameter.

        tryToSave: ( callback, filename = @filename ) ->

If there is a filename for the current document already in this object's
`@filename` member, then a save is done directly to that filename.  If there
is no filename, then a save dialog is shown.

            if filename
                @setFilename filename
                result = @save() # save happens even if no callback
                return callback? result

There is not a readily available filename, so we must pop up a "Save as"
dialog.  First we create a routine for updating the dialog we're about to
show with an enabled/disabled Save button, based on whether there is a file
selected.

            refreshDialog = ->
                dialog = document.getElementsByClassName( 'mce-window' )[0]
                if not dialog then return
                for button in dialog.getElementsByTagName 'button'
                    if button.textContent is 'Save'
                        if filename
                            button.removeAttribute 'disabled'
                            button.parentNode.style.backgroundImage = null
                            button.parentNode.style.backgroundColor = null
                        else
                            button.setAttribute 'disabled', yes
                            button.parentNode.style.backgroundImage = 'none'
                            button.parentNode.style.backgroundColor = '#ccc'
                        break

Now we install a handler for when a file is selected, save that filename for
possible later use, and refresh the dialog.

            filename = null
            @saveFileNameChangedHandler = ( newname ) ->
                filename = newname
                refreshDialog()

Do the same thing for when the folder changes, but there's no need to
refresh the dialog in this case.

            filepath = null
            @changedFolderHandler = ( newfolder ) -> filepath = newfolder

We will also need to know whether the `save` function will overwrite an
existing file, so that we can verify that the user actually wants to do so
before we save.  The following function performs that check.

            saveWouldOverwrite = ( filepath, filename ) =>
                tmp = new FileSystem @fileSystem
                tmp.cd filepath
                null isnt tmp.type filename

Create a handler to receive the button clicks.  We do this here so that if
the dialog clicks a button programmatically, which then passes to us a
message that the button was clicked, we will still hear it through this
handler, because the `window.onmessage` handler installed at the end of this
file will call this function.

            @buttonClickedHandler = ( name, args... ) =>
                if name is 'Save'

If the file chosen already exists, ask the user if they're sure they want to
overwrite it.  If they say no, then we go back to the save dialog.  However,
the dialog, by default, resets itself to "manage files" mode whenever a
button is clicked.  So we put it back in "save file" mode before exiting.

                    if saveWouldOverwrite filepath, filename
                        if not confirm "Are you sure you want to overwrite
                          the file #{filename}?"
                            @tellDialog 'setFileBrowserMode', 'save file'
                            return

Now that we're sure the user wants to save, we store the path and filename
for use in later saves, and perform the save, closing the dialog.

                    @setFilepath filepath
                    @setFilename filename
                    @editor.windowManager.close()
                    result = @save() # save happens even if no callback
                    callback? result
                else if name is 'Cancel'
                    @editor.windowManager.close()
                    callback? no

Now we are sufficiently ready to pop up the dialog.  We use one made from
[filedialog/filedialog.html](filedialog.html), which was copied from [the
jsfs submodule](../jsfs/demo) and modified to suit the needs of this
application.

            @editor.windowManager.open {
                title : 'Save file...'
                url : 'filedialog/filedialog.html'
                width : 600
                height : 400
                buttons : [
                    text : 'Save'
                    subtype : 'primary'
                    onclick : => @buttonClickedHandler 'Save'
                ,
                    text : 'Cancel'
                    onclick : => @buttonClickedHandler 'Cancel'
                ]
            }, {
                fsName : @fileSystem
                mode : 'save file'
            }

## Loading documents

The following function loads into the editor the contents of the file.  It
must be a file containing a string of HTML, because that content will be
directly used as the content of the editor.  The current path and filename
of this plugin are set to be the parameters passed here.

        load: ( filepath, filename ) ->
            if filename is null then return
            if filepath is null then filepath = '.'
            tmp = new FileSystem @fileSystem
            tmp.cd filepath
            [ content, metadata ] = tmp.read filename
            @editor.setContent content
            @setFilepath filepath
            @setFilename filename
            @setDocumentDirty no
            if metadata then @loadMetaData? metadata

The following function pops up a dialog to the user, allowing them to choose
a filename to open.  If they choose a file, it (with the current directory)
is passed to the given callback function.  If they do not choose a file, but
cancel the dialog instead, then null is passed to that callback to indicate
the cancellation. It makes the most sense to leave the callback function the
default, `@load`.

        tryToOpen: ( callback = ( p, f ) => @load p, f ) ->

First we create a routine for updating the dialog we're about to show with
an enabled/disabled Save button, based on whether there is a file selected.

            refreshDialog = ->
                dialog = document.getElementsByClassName( 'mce-window' )[0]
                if not dialog then return
                for button in dialog.getElementsByTagName 'button'
                    if button.textContent is 'Open'
                        if filename
                            button.removeAttribute 'disabled'
                            button.parentNode.style.backgroundImage = null
                            button.parentNode.style.backgroundColor = null
                        else
                            button.setAttribute 'disabled', yes
                            button.parentNode.style.backgroundImage = 'none'
                            button.parentNode.style.backgroundColor = '#ccc'
                        break

Now we install a handler for when a file is selected, save that filename for
possible later use, and refresh the dialog.

            filename = null
            @selectedFileHandler = ( newname ) ->
                filename = newname
                refreshDialog()

Do the same thing for when the folder changes, but there's no need to
refresh the dialog in this case.

            filepath = null
            @changedFolderHandler = ( newfolder ) -> filepath = newfolder

Create a handler to receive the button clicks.  We do this here so that if
the dialog clicks a button programmatically, which then passes to us a
message that the button was clicked, we will still hear it through this
handler, because the `window.onmessage` handler installed at the end of this
file will call this function.

            @buttonClickedHandler = ( name, args... ) =>
                if name is 'Open'
                    @editor.windowManager.close()
                    callback? filepath, filename
                else if name is 'Cancel'
                    @editor.windowManager.close()
                    callback? null, null

Now we are sufficiently ready to pop up the dialog.  We use one made from
[filedialog/filedialog.html](filedialog.html), which was copied from [the
jsfs submodule](../jsfs/demo) and modified to suit the needs of this
application.

            @editor.windowManager.open {
                title : 'Open file...'
                url : 'filedialog/filedialog.html'
                width : 600
                height : 400
                buttons : [
                    text : 'Open'
                    subtype : 'primary'
                    onclick : => @buttonClickedHandler 'Open'
                ,
                    text : 'Cancel'
                    onclick : => @buttonClickedHandler 'Cancel'
                ]
            }, {
                fsName : @fileSystem
                mode : 'open file'
            }
            refreshDialog()

The following handler for the "open" controls checks with the user to see if
they wish to save their current document first, if and only if that document
is dirty.  The user may save, or cancel, or discard the document.

        handleOpen: ->

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
                        @tryToSave ( success ) =>
                            if success then @tryToOpen()
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

## Communcating with dialogs

When a dialog is open, it is in an `<iframe>` within the main page, which
means that it can only communicate with the script environment of the main
page through message-passing.  This function finds the `<iframe>` containing
the file dialog and (if there was one) sends it the message given as the
argument list.

        tellDialog: ( args... ) ->
            frames = document.getElementsByTagName 'iframe'
            for frame in frames
                if 'filedialog/filedialog.html' is frame.getAttribute 'src'
                    return frame.contentWindow.postMessage args, '*'

## Managing files

The final menu item is one that shows a dialog for managing files in the
filesystem.  On desktop apps, no such feature is necessary, because every
operating system comes with a file manager of its own.  In this web app,
where we have a virtual filesystem, we must provide a file manager to access
it and move, rename, and delete files, create folders, etc.

        manageFiles: ->
            @editor.windowManager.open {
                title : 'Manage files'
                url : 'filedialog/filedialog.html'
                width : 700
                height : 500
                buttons : [
                    text : 'New folder'
                    onclick : => @tellDialog 'buttonClicked', 'New folder'
                ,
                    text : 'Done'
                    onclick : => @editor.windowManager.close()
                ]
            }, {
                fsName : @fileSystem
                mode : 'manage files'
            }

# Global stuff

## Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`LoadSave` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'loadsave', ( editor, url ) ->
        editor.LoadSave = new LoadSave editor

## Event handler

When a file dialog sends a message to the page, we look through the existing
instances of the `LoadSave` class for whichever one wants to handle that
message.  Whichever one has a handler ready, we call that handler.

    window.onmessage = ( event ) ->
        handlerName = "#{event.data[0]}Handler"
        for instance in LoadSave::instances
            if instance.hasOwnProperty handlerName
                return instance[handlerName].apply null, event.data[1..]

## Global functions

Finally, the global function that changes the app name.

    window.setAppName = ( newname = null ) -> LoadSave::appName = newname



# Add an editor to the app

First, specify that the app's name is "Lurch," so that will be used when
creating the title for this page (e.g., to show up in the tab in Chrome).

    setAppName 'Lurch'

This file initializes a [TinyMCE](http://www.tinymce.com/) editor inside the
[main app page](index.html).  It is designed to be used inside that page,
where [jQuery](http://jquery.com/) has already been loaded, thus defining
the `$` symbol used below.  It use in this context causes the function to be
run only after the DOM has been fully loaded.

    $ ->

Create a `<textarea>` to be used as the editor.

        editor = document.createElement 'textarea'
        editor.setAttribute 'id', 'editor'
        document.body.appendChild editor

Install a TinyMCE instance in that text area, with specific plugins, toolbar
buttons, and context menu items as given below.

        tinymce.init
            selector : '#editor'
            auto_focus : 'editor'

These enable the use of the browser's built-in spell-checking facilities, so
that no server-side callback needs to be done for spellchecking.

            browser_spellcheck : yes
            gecko_spellcheck : yes
            statusbar : no

Not all of the following plugins are working yet, but most are.  A plugin
that begins with a hyphen is a local plugin written as part of this project.

            plugins : 'advlist table charmap colorpicker contextmenu image
                link importcss paste print save searchreplace textcolor
                fullscreen -loadsave'

We then install two toolbars, with separators indicated by pipes (`|`).

            toolbar : [
                'newfile openfile savefile managefiles | print
                    | undo redo | cut copy paste
                    | alignleft aligncenter alignright alignjustify
                    | bullist numlist outdent indent blockquote | table'
                'fontselect styleselect | bold italic underline
                    textcolor subscript superscript removeformat
                    | link unlink | charmap image
                    | spellchecker searchreplace'
            ]

We then customize the menus' contents as follows.

            menu :
                file :
                    title : 'File'
                    items : 'newfile openfile | savefile saveas
                           | managefiles | print'
                edit :
                    title : 'Edit'
                    items : 'undo redo
                           | cut copy paste pastetext
                           | selectall'
                insert :
                    title : 'Insert'
                    items : 'link media
                           | template hr'
                view :
                    title : 'View'
                    items : 'visualaid'
                format :
                    title : 'Format'
                    items : 'bold italic underline
                             strikethrough superscript subscript
                           | formats | removeformat'
                table :
                    title : 'Table'
                    items : 'inserttable tableprops deletetable
                           | cell row column'
                help :
                    title : 'Help'
                    items : 'about website'

And, finally, we customize the context menu.

            contextmenu : 'link image inserttable
                | cell row column deletetable'

Each editor created will have the following `setup` function called on it.
In our case, there will be only one, but this is how TinyMCE installs setup
functions, regardless.

            setup : ( editor ) ->

Add a Help menu.

                editor.addMenuItem 'about',
                    text : 'About...'
                    context : 'help'
                    onclick : -> alert 'webLurch\n\npre-alpha,
                        not intended for general consumption!'
                editor.addMenuItem 'website',
                    text : 'Lurch website'
                    context : 'help'
                    onclick : -> window.open 'http://www.lurchmath.org',
                        '_blank'

Increase the default font size and maximize the editor to fill the page.

                editor.on 'init', ->
                    editor.getBody().style.fontSize = '16px'
                    setTimeout ( -> editor.execCommand 'mceFullScreen' ), 0

Add Lurch icon to the left of the File menu.

                    filemenu = ( editor.getContainer()
                        .getElementsByClassName 'mce-menubtn' )[0]
                    icon = document.createElement 'img'
                    icon.setAttribute 'src',
                        'icons/apple-touch-icon-76x76.png'
                    icon.style.width = icon.style.height = '26px'
                    icon.style.padding = '2px'
                    filemenu.insertBefore icon, filemenu.childNodes[0]

Workaround for [this bug](http://www.tinymce.com/develop/bugtracker_view.php?id=3162):

                    editor.getBody().addEventListener 'focus', ->
                        if editor.windowManager.getWindows().length isnt 0
                            editor.windowManager.close()
