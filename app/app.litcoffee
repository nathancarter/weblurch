
# Dependencies Plugin for [TinyMCE](http://www.tinymce.com)

## Overview

This plugin adds features for making the current document depend on others,
much like programming languages permit one file importing the definitions in
another file (such as with `#include` in C, for example).

The particular mechanism by which this is implemented in Lurch is described
here.  It will be convenient to assume we're discussing two documents, A and
B, with A being used as a dependency by B (that is, B imports A).

 * Document B must store in its metadata a member called `exports`.  As with
   all document metadata, it must be JSON data.
 * Document A will see none of the actual contents of document B.  Rather,
   it will see all the data stored in that `exports` member of B.
 * Both documents must leave the `dependencies` member of their metadata
   untouched; this plugin will manage it.
 * When the user indicates that document A should import document B as a
   dependency, this plugin will store the address (URL or filename) of
   document B in the `dependencies` member of document A's metadata.  It
   will also fetch all of document B's `exports` data and store that, too.
 * Whenever document A is opened, the last modified time of document B will
   be checked.  If it is newer than the last import, B's `exports` data will
   be re-fetched, and the updated version stored in A.
 * If B depended on another document C, then both the `exports` data in B
   (if any) *and* its `dependencies` data would be imported into A.  The
   `dependencies` would be embedded as a member of the `exports`, so do not
   ever include a `dependencies` member inside an `exports` member, or it
   may be overwritten and/or misinterpreted.
 * Documents may import more than one dependency, and so the dependencies
   data is actually an array.  These examples have considered the case of
   importing only one dependency, for simplicity.

## Example

Here is a summary of the metadata structure described by the above bullet
points.

### Document C

 * Exports some data about its own contents.  Thus its metadata has an
   `exports` member, let's say this one for example:

```json
    [ "example", "C", "data" ]
```

 * Has no dependencies.  Thus its metadata has no dependencies member, which
   by default is equivalent to an empty array, `[ ]`.

### Document B

 * Exports some data about its own contents.  Thus its metadata has an
   `exports` member, let's say this one for example:

```json
    { "what" : "example data", "whence" : "document B" }
```

 * Imports document C.  Thus its metadata has a dependencies member like
   the following.  Recall that this is a one-element array just for the
   simplicity of this example.

```json
    [
        {
            "address" : "http://www.example.com/document_c",
            "data" : [ "example", "C", "data" ],
            "date" : "2012-04-23T18:25:43.511Z"
        }
    ]
```

### Document A

 * Exports some data about its own contents, but that's irrelevant here
   because in this example no document depends on A.
 * Imports document B.  Thus its metadata has a dependencies member like
   the following.  Note the embedding of C's dependencies inside B's.

```json
    [
        {
            "address" : "http://www.example.com/document_b",
            "data" : {
                "what" : "example data",
                "whence" : "document B",
                "dependencies" : [
                    {
                        "address" : "http://www.example.com/document_c",
                        "data" : [ "example", "C", "data" ],
                        "date" : "2012-04-23T18:25:43.511Z"
                    }
                ]
            },
            "date" : "2012-05-21T16:00:51.278Z",
        }
    ]
```

## Responsibilities

The author of a Lurch Application (see [tutorial](../doc/tutorial.md)) must
implement a `saveMetadata` function (as documented
[here](loadsaveplugin.litcoffee#constructor)) to store the appropriate
`exports` data in the document's metadata upon each save.  It should also
store the document's `dependencies` data, which can be obtained by calling
`export` in this plugin.

Sometimes, however, it is not possible, to give accurate `exports` data.
For example, if a lengthy background computation is taking place, the
application may not know up-to-date exports information for the current
document state.  If `saveMetadata` is called at such times, the application
should do two things.
 1. Inform the user that the document was saved while a background
    computation (or other cause) left the document's data not fully updated.
    Consequently, the document *cannot* be used as a dependency until this
    problem is corrected.  Wait for background computations (or whatever)
    to complete, and then save again.
 1. Store in the `exports` member an object of the following form.  The
    error message will be used if another user attempts to import this
    document as a dependency, to explain why that operation is not valid.

```json
    { "error" : "Error message explaining why exports data not available." }
```

The author of a Lurch Application must also have the application call this
plugin's `import` function immediately after a document is loaded, on the
dependency data stored in that document's metadata.  This can happen as part
of the `loadMetadata` event, for example.

Whenever any dependency is added, removed, or updated, a
`dependenciesChanged` event is fired in the editor, with no parameters.  Any
aspect of the current document that the app needs to update or recompute
based on the fact that the dependencies list or data has changed should be
done in response to that event.  That event will (rarely) fire several times
in succession.  This happens only if `update` was called in this plugin in
a document for which many dependencies have new versions that need to be
imported, replacing the cached data from old versions.  See the `update`
function below for details.

This plugin provides functionality for constructing a user interface for
editing a document's dependency list.  That functionality is responsible for
importing other documents' `exports` data into the current document's
`dependencies` array, and managing the structure of that array.  The
recursive embedding show in the examples above is handled by this plugin.

Applications need to give users access to that interface, using the methods
documented in the [Presenting a UI](#presenting-a-ui) section, below.

# `Dependencies` class

We begin by defining a class that will contain all the information needed
about the current document's dependencies.  An instance of this class will
be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Dependencies

## Constructor and static members

We construct new instances of the Dependencies class as follows, and these
are inserted as members of the corresponding editor by means of the code
[below, under "Installing the Plugin."](#installing-the-plugin)

        constructor: ( @editor ) ->
            @length = 0

This function takes a path into a `jsfs` filesystem and extracts the
metadata from the file, returning it.  It assumes that the filesystem into
which it should look is the same one used by [the Load/Save
Plugin](loadsaveplugin.litcoffee), and fetches the name of the filesystem
from there.

        getFileMetadata: ( filepath, filename ) ->
            if filename is null then return
            if filepath is null then filepath = '.'
            tmp = new FileSystem @editor.LoadSave.fileSystem
            tmp.cd filepath
            tmp.read( filename )[1]

## Importing, exporting, and updating

To make this plugin aware of the dependency information in the current
document, call this function.  Pass to it the `dependencies` member of the
document's metadata, which must be of the form documented at the top of this
file.  It uses JSON methods to make deep copies of the parameter's entries,
rather than re-using the same objects.

This function gives this plugin a `length` member, and storing the entries
of the `dependencies` array as entries 0, 1, 2, etc. of this plugin object.
Therefore clients can treat the plugin itself as an array, writing code like
`tinymce.activeEditor.Dependencies[2].address`, for example, or looping
through all dependencies in this object based on its length.

After importing dependencies, this function also updates them to their
latest versions.  (See the `update` function defined further below for
details.)  Note that `update` may result in many `dependenciesChanged`
events.

        import: ( dependencies ) ->
            for i in [0...@length] then delete @[i]
            for i in [0...@length = dependencies.length]
                @[i] = JSON.parse JSON.stringify dependencies[i]
            @update()

The following function is the inverse of the previous.  It, too, makes deep
copies using JSON methods.

        export: -> ( JSON.parse JSON.stringify @[i] for i in [0...@length] )

This function updates a dependency to its most recent version.  If the
dependency is not reachable at the time this function is invoked or if its
last modified date is newer than the date stored in this plugin, this
function does not update the dependency.  The parameter indicates the
dependency to update by index.  If no index is given, then all dependencies
are updated, one at a time, in order.

Note that update may not complete its task immediately.  The function may
return while files are still being fetched from the wiki, and callback
functions waiting to be run.  (Parts of this function are asynchronous.)

Any time the dependency data actually changes, a `dependenciesChanged` event
is fired in the editor.  This may result in many such events, if this
function is called with no argument, and depending on how many dependencies
need updating.

        update: ( index ) ->

Handle the no-parameter case first, as a loop.

            if not index? then return ( @update i for i in [0...@length] )

Ensure that the parameter makes sense.

            return unless index >= 0 and index < @length
            dependency = @[index]

A `file://`-type dependency is in the `jsfs` filesystem.  It does not have
last modified dates, so we always update file dependencies.

            if dependency.address[...7] is 'file://'
                splitPoint = dependency.address.lastIndexOf '/'
                filename = dependency.address[splitPoint...]
                filepath = dependency.address[7...splitPoint]
                newData = @getFileMetadata( filepath, filename ).exports
                if JSON.stringify( newData ) isnt JSON.stringify @[index]
                    @[index].data = newData
                    @[index].date = new Date
                    @editor.fire 'dependenciesChanged'

A `wiki://`-type dependency is in the wiki.  It does have last modified
dates, so we check to see if updating is necessary

            else if dependency.address[...7] is 'wiki://'
                pageName = dependency.address[7...]
                @editor.MediaWiki.getPageTimestamp pageName,
                ( result, error ) =>
                    return unless result?
                    lastModified = new Date result
                    currentVersion = new Date dependency.date
                    return unless lastModified > currentVersion
                    @editor.MediaWiki.getPageMetadata pageName,
                    ( metadata ) =>
                        if metadata? and JSON.stringify( @[index] ) isnt \
                                JSON.stringify metadata.exports
                            @[index].data = metadata.exports
                            @[index].date = lastModified
                            @editor.fire 'dependenciesChanged'

No other types of dependencies are supported (yet).

## Adding and removing dependencies

Adding a dependency is an inherently asynchronous activity, because the
dependency may need to be fetched from the wiki.  Thus this function takes
a dependency address and a callback function.  The new dependency is always
appended to the end of the list.

The address must be of a type supported by `update` (see above).  The
callback will be passed result and an error, exactly one of which will be
non-null, depending on success or failure.

If the callback is null, it will not be used, but the dependency will still
be added.  Whether the callback is null or not, this function ends by firing
the `dependenciesChanged` event in the editor if and only if the dependency
was successfully added.

        add: ( address, callback ) ->
            if address[...7] is 'file://'
                splitPoint = address.lastIndexOf '/'
                filename = address[splitPoint...]
                filepath = address[7...splitPoint]
                try
                    newData = @getFileMetadata( filepath, filename ).exports
                    @[@length++] =
                        address : address
                        data : newData
                        date : new Date
                    callback? newData, null
                    @editor.fire 'dependenciesChanged'
                catch e
                    callback? null, e
            else if address[...7] is 'wiki://'
                pageName = address[7...]
                @editor.MediaWiki.getPageTimestamp pageName,
                ( result, error ) =>
                    if not result?
                        return callback? null,
                            'Could not get wiki page timestamp'
                    @editor.MediaWiki.getPageMetadata pageName,
                    ( metadata ) =>
                        if not metadata?
                            return callback? null,
                                'Could not access wiki page'
                        @[@length++] =
                            address : address
                            data : metadata.exports
                            date : new Date result
                        callback? metadata.exports, null
                        @editor.fire 'dependenciesChanged'

To remove a dependency (which should happen only in reponse to user input),
call this function.  It updates the indices and length of this plugin, much
like `splice` does for JavaScript arrays, and then fires a
`dependenciesChanged` event.

        remove: ( index ) ->
            return unless index >= 0 and index < @length
            @[i] = @[i+1] for i in [index...@length-1]
            delete @[--@length]
            @editor.fire 'dependenciesChanged'

## Presenting a UI

The following method fills a DIV (probably in a pop-up dialog) with the
necessary user interface elements necessary for viewing and editing the
dependencies stored in this plugin.  It also installs event handlers for the
buttons it creates, so that they will respond to clicks by calling methods
in this plugin, and updating that user interface accordingly.

        installUI: ( div ) ->
            parts = [ ]
            for dependency, index in @
                parts.push @editor.Settings.UI.generalPair \
                    dependency.address,
                    @editor.Settings.UI.button( 'Remove',
                        "dependencyRemove#{index}" ),
                    "dependencyRow#{index}", 80, 'center'
            if @length is 0
                parts.push @editor.Settings.UI.info '(no dependencies)'
            parts.push @editor.Settings.UI.info \
                "#{@editor.Settings.UI.button 'Add file dependency',
                    'dependencyAddFile'}
                 #{@editor.Settings.UI.button 'Add wiki page dependency',
                    'dependencyAddWiki'}"
            div.innerHTML = parts.join '\n'
            elt = ( id ) -> div.ownerDocument.getElementById id
            for dependency, index in @
                elt( "dependencyRemove#{index}" ).addEventListener 'click',
                    do ( index ) => => @remove index ; @installUI div
            elt( 'dependencyAddFile' ).addEventListener 'click', =>
                @editor.LoadSave.tryToOpen ( path, file ) =>
                    if file?
                        if path? then path += '/' else path = ''
                        @add "file://#{path}#{file}", ( result, error ) =>
                            if error?
                                @editor.Dialogs.alert
                                    title : 'Error adding dependency'
                                    message : error
                            else
                                @installUI div
            elt( 'dependencyAddWiki' ).addEventListener 'click', =>
                if url = prompt 'Enter the wiki page name of the dependency
                        to add.', 'Example Page Name'
                    @add "wiki://#{url}", ( result, error ) =>
                        if error?
                            @editor.Dialogs.alert
                                title : 'Error adding dependency'
                                message : error
                        else
                            @installUI div

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dependencies` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dependencies', ( editor, url ) ->
        editor.Dependencies = new Dependencies editor



# Dialogs Plugin

This plugin adds to TinyMCE some much-needed convenience functions for
showing dialog boxes and receiving callbacks from events within them.

All of these functions will be installed in an object called `Dialogs` in
the editor itself.  So, for example, you might call one via code like the
following.
```javascript
tinymce.activeEditor.Dialogs.alert( {
    title : 'Alert!'
    message : 'Content of the alert box here.',
    callback : function ( event ) { console.log( event );
} );
```

    Dialogs = { }

## Generic function

The following functions give every dialog in this plugin the ability to
include buttons and links, together with an on-click handler
`options.onclick`.

The first extends any HTML code for the interior of a dialog with the
necessary script for passing all events from links and buttons out to the
parent window.  It also converts the resulting page into the object URL for
a blob, so that it can be passed to the TinyMCE dialog-creation routines.

    prepareHTML = ( html ) ->
        script = ->
            install = ( tagName, eventName ) ->
                for element in document.getElementsByTagName tagName
                    element.addEventListener eventName, ( event ) ->
                        top.postMessage
                            value : event.currentTarget.value
                            id : event.currentTarget.getAttribute 'id'
                        , '*'
            install 'a', 'click'
            install 'input', 'click'
            install 'input', 'input'
        window.objectURLForBlob window.makeBlob \
            html + "<script>(#{script})()</script>",
            'text/html;charset=utf-8'

The second installs in the top-level window a listener for the events
posted from the interior of the dialog.  It then calls the given event
handler with the ID of the element clicked.  It also makes sure that when
the dialog is closed, this event handler will be uninstalled

    installClickListener = ( handler ) ->
        innerHandler = ( event ) -> handler event.data
        window.addEventListener 'message', innerHandler, no
        tinymce.activeEditor.windowManager.getWindows()[0].on 'close', ->
            window.removeEventListener 'message', innerHandler

## Alert box

This function shows a simple alert box, with a callback when the user
clicks OK.  The message can be text or HTML.

    Dialogs.alert = ( options ) ->
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 400
            height : options.height ? 300
            buttons : [
                type : 'button'
                text : 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.callback? event
            ]
        if options.onclick then installClickListener options.onclick

## Confirm dialog

This function is just like the alert box, but with two callbacks, one for OK
and one for Cancel, named `okCallback` and `cancelCallback`, respectively.
The user can rename the OK and Cancel buttons by specfying strings in the
options object with the 'OK' and 'Cancel' keys.


    Dialogs.confirm = ( options ) ->
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 400
            height : options.height ? 300
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Cancel'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.cancelCallback? event
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.okCallback? event
            ]
        if options.onclick then installClickListener options.onclick

## Prompt dialog

This function is just like the prompt dialog in JavaScript, but it uses two
callbacks instead of a return value.  They are named `okCallback` and
`cancelCallback`, as in [the confirm dialog](#confirm-dialog), but they
receive the text in the dialog's input as a parameter.

    Dialogs.prompt = ( options ) ->
        value = if options.value then " value='#{options.value}'" else ''
        options.message +=
            "<p><input type='text' #{value} id='promptInput' size=40/></p>"
        lastValue = options.value ? ''
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 300
            height : options.height ? 200
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Cancel'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.cancelCallback? lastValue
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.okCallback? lastValue
            ]
        installClickListener ( data ) ->
            if data.id is 'promptInput' then lastValue = data.value

# Installing the plugin

    tinymce.PluginManager.add 'dialogs', ( editor, url ) ->
        editor.Dialogs = Dialogs



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

The following section of code finds the interior of the main DIV, by finding
all DIVs and ensuring we count nesting correctly.

                        open = '<div id="EmbeddedLurchDocument">'
                        start = result.indexOf open
                        if start > -1
                            start += open.length
                            rest = result.substring start
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
                            result = interior

Now we can extract the metadata from the interior of the main DIV, and
finish.

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
            console.log document, content, url
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



# Groups Plugin for [TinyMCE](http://www.tinymce.com)

This plugin adds the notion of "groups" to a TinyMCE editor.  Groups are
contiguous sections of the document, often nested but not otherwise
overlapping, that can be used for a wide variety of purposes.  This plugin
provides the following functionality for working with groups in a document.
 * defines the `Group` and `Groups` classes
 * provides methods for installing UI elements for creating and interacting
   with groups in the document
 * shows groups visually on screen in a variety of ways
 * calls update routines whenever group contents change, so that they can be
   updated/processed

It assumes that TinyMCE has been loaded into the global namespace, so that
it can access it.  It also requires [the overlay
plugin](overlayplugin.litcoffee) to be loaded in the same editor.

All changes made to the document by the user are tracked so that appropriate
events can be called in this plugin to update group objects.  The one
exception to this rule is that calls to the `setContents()` method of the
editor's selection, made by a client, cannot be tracked.  Thus if you call
such a method, you should call `groupChanged()` in any groups whose contents
have changed based on your call to `setContents()`.

# Global functions

The following two global functions determine how we construct HTML to
represent group boundaries (called "groupers") and how we decipher such HTML
back into information about the groupers.

First, how to create HTML representing a grouper.  The parameters are as
follows:  `typeName` is a string naming the type of the group, which must be
[registered](#registering-group-types); `image` is the path to the image
that will be used to represent this grouper; `openClose` must be either the
string "open" or the string "close"; `id` is a nonnegative integer unique to
this group; `hide` is a boolean representing whether the grouper should be
invisible in the document.

    grouperHTML = ( typeName, openClose, id, hide = yes, image ) ->
        hide = if hide then ' hide' else ''
        image ?= "images/red-bracket-#{openClose}.png"
        "<img src='#{image}' class='grouper #{typeName}#{hide}'
              id='#{openClose}#{id}'>"
    window.grouperHTML = grouperHTML

Second, how to extract group information from a grouper.  The two pieces of
information that are most important to extract are whether the grouper is an
open grouper or close grouper, and what its ID is.  This routine extracts
both and returns them in an object with the keys `type` and `id`.  If the
data is not available in the expected format, it returns `null`.

    grouperInfo = ( grouper ) ->
        info = /^(open|close)([0-9]+)$/.exec grouper?.getAttribute? 'id'
        if not info then return null
        result = openOrClose : info[1], id : parseInt info[2]
        more = /^grouper ([^ ]+)/.exec grouper?.getAttribute? 'class'
        if more then result.type = more[1]
        result
    window.grouperInfo = grouperInfo

A few functions in this module make use of a tool for computing the default
editor style as a CSS style string (e.g., "font-size:16px;").  That function
is defined here.

    createStyleString = ( styleObject = window.defaultEditorStyles ) ->
        result = [ ]
        for own key, value of styleObject
            newkey = ''
            for letter in key
                if letter.toUpperCase() is letter then newkey += '-'
                newkey += letter.toLowerCase()
            result.push "#{newkey}:#{value};"
        result.join ' '

The main function that uses the previous function is one for converting
well-formed HTML into an image URL.

    htmlToImage = ( html ) ->
        objectURLForBlob svgBlobForHTML html, createStyleString()

A few functions in this module make use of a tool for computing a CSS style
string describing the default font size and family of an element.  That
function is defined here.

    createFontStyleString = ( element ) ->
        style = element.ownerDocument.defaultView.getComputedStyle element
        "font-size:#{style.fontSize}; font-family:#{style.fontFamily};"

# `Group` class

This file defines two classes, this one called `Group` and another
([below](#groups-class)) called `Groups`.  They are obviously quite
similarly named, but here is the distinction:  An instance of the `Group`
class represents a single section of text within the document that the user
has "grouped" together.  Thus each document may have zero or more such
instances.  Each editor, however, gets only one instance of the `Groups`
class, which manages all the `Group` instances in that editor's document.

## Group constructor

    class Group

The constructor takes as parameters the two DOM nodes that are its open and
close groupers (i.e., group boundary markers), respectively.  It does not
validate that these are indeed open and close grouper nodes, but just stores
them for later lookup.

The final parameter is an instance of the Groups class, which is the plugin
defined in this file.  Thus each group will know in which environment it
sits, and be able to communicate with that environment.  If that parameter
is not provided, the constructor will attempt to correctly detect it, but
providing the parameter is more efficient.

We call the contents changed event as soon as the group is created, because
any newly-created group needs to have its contents processed for the first
time (assuming a processing routine exists, otherwise the call does
nothing).  We pass "yes" as the second parameter to indicate that this is
the first call ever to `contentsChanged`, and thus the group type may wish
to do some initial setup.

        constructor: ( @open, @close, @plugin ) ->
            if not @plugin?
                for editor in tinymce.editors
                    if editor.getDoc() is @open.ownerDocument
                        @plugin = editor.Groups
                        break
            @contentsChanged yes, yes

## Core group data

This method returns the ID of the group, if it is available within the open
grouper.

        id: => grouperInfo( @open )?.id ? null

The first of the following methods returns the name of the type of the
group, as a string.  The second returns the type as an object, as long as
the type exists in the plugin stored in `@plugin`.

        typeName: => grouperInfo( @open )?.type
        type: => @plugin?.groupTypes?[@typeName()]

## Group attributes

We provide the following four simple methods for getting and setting
arbitrary data within a group.  Clients should use these methods rather than
write to fields in a group instance itself, because these (a) guarantee no
collisions with existing properties/methods, and (b) mark that group (and
thus the document) dirty, and ensure that changes to a group's data bring
about any recomputation/reprocessing of that group in the document.

Because we use HTML data attributes to store the data, the keys must be
alphanumeric, optionally with dashes and/or underscores.  Furthermore, the
data must be able to be amenable to JSON stringification.

IMPORTANT:  If you call `set()` in a group, the changes you make will NOT be
stored on the TinyMCE undo/redo stack.  If you want your changes stored on
that stack, you should make the changes inside a function passed to the
TinyMCE Undo Manager's [transact](https://www.tinymce.com/docs/api/tinymce/tinymce.undomanager/#transact) method.

You may or may not wish to have your changes stored on the undo/redo stack.
In general, if the change you're making to the group is in direct and
immediate response to the user's actions, then it should be on the undo/redo
stack, so that the user can change their mind.  However, if the change is
the result of a background computation, which was therefore not in direct
response to one of the user's actions, they will probably not expect to be
able to undo it, and thus you should not place the change on the undo/redo
stack.

        set: ( key, value ) =>
            if not /^[a-zA-Z0-9-_]+$/.test key then return
            toStore = JSON.stringify [ value ]
            if @open.getAttribute( "data-#{key}" ) isnt toStore
                @open.setAttribute "data-#{key}", toStore
                if @plugin?
                    @plugin.editor.fire 'change'
                    @plugin.editor.isNotDirty = no
                    @contentsChanged()
                if key is 'openDecoration' or key is 'closeDecoration'
                    @updateGrouper key[...-10]
                if key is 'openHoverText' or key is 'closeHoverText'
                    grouper = @[key[...-9]]
                    for attr in [ 'title', 'alt' ] # browser differences
                        grouper.setAttribute attr, "#{value}"
        get: ( key ) =>
            try
                JSON.parse( @open.getAttribute "data-#{key}" )[0]
            catch e
                undefined
        keys: => Object.keys @open.dataset
        clear: ( key ) =>
            if not /^[a-zA-Z0-9-_]+$/.test key then return
            if @open.getAttribute( "data-#{key}" )?
                @open.removeAttribute "data-#{key}"
                if @plugin?
                    @plugin.editor.fire 'change'
                    @plugin.editor.isNotDirty = no
                    @contentsChanged()
                if key is 'openDecoration' or key is 'closeDecoration'
                    @updateGrouper key[...-10]
                if key is 'openHoverText' or key is 'closeHoverText'
                    grouper = @[key[...-9]]
                    for attr in [ 'title', 'alt' ] # browser differences
                        grouper.removeAttribute attr

The `set` and `clear` functions above call an update routine if the
attribute changed was the decoration data for a grouper.  This update
routine recomputes the appearance of that grouper as an image, and stores it
in the `src` attribute of the grouper itself (which is an `img` element).
We implement that routine here.

This routine is also called from `hideOrShowGroupers`, defined later in this
file.  It can accept any of three parameter types, the string "open", the
string "close", or an actual grouper element from the document that is
either the open or close grouper for this group.

        updateGrouper: ( openOrClose ) =>
            if openOrClose is @open then openOrClose = 'open'
            if openOrClose is @close then openOrClose = 'close'
            if openOrClose isnt 'open' and openOrClose isnt 'close'
                return
            jquery = $ grouper = @[openOrClose]
            if ( decoration = @get "#{openOrClose}Decoration" )?
                jquery.addClass 'decorate'
            else
                jquery.removeClass 'decorate'
                decoration = ''
            html = if jquery.hasClass 'hide' then '' else \
                @type()?["#{openOrClose}ImageHTML"]
            if openOrClose is 'open'
                html = decoration + html
            else
                html += decoration
            window.base64URLForBlob window.svgBlobForHTML( html,
                createFontStyleString grouper ), ( base64 ) =>
                    if grouper.getAttribute( 'src' ) isnt base64
                        grouper.setAttribute 'src', base64
                        @plugin?.editor.Overlay?.redrawContents()

## Group contents

We will need to be able to query the contents of a group, so that later
computations on that group can use its contents to determine how to act.  We
provide functions for fetching the contents of the group as plain text, as
an HTML `DocumentFragment` object, or as an HTML string.

        contentAsText: => @innerRange()?.toString()
        contentAsFragment: => @innerRange()?.cloneContents()
        contentAsHTML: =>
            if not fragment = @contentAsFragment() then return null
            tmp = @open.ownerDocument.createElement 'div'
            tmp.appendChild fragment
            tmp.innerHTML

You can also fetch the exact sequence of Nodes between the two groupers
(including only the highest-level ones, not their children when that would
be redundant) using the following routine.

        contentNodes: =>
            result = [ ]
            walk = @open
            while walk?
                if strictNodeOrder walk, @close
                    if strictNodeOrder @open, walk then result.push walk
                    if walk.nextSibling? then walk = walk.nextSibling \
                        else walk = walk.parentNode
                    continue
                if strictNodeOrder @close, walk
                    console.log 'Warning!! walked past @close...something
                        is wrong with this loop'
                    break
                if walk is @close then break else walk = walk.childNodes[0]
            result

We can also set the contents of a group with the following function.  This
function can only work if `@plugin` is a `Groups` class instance.

        setContentAsText: ( text ) =>
            if not inside = @innerRange() then return
            @plugin?.editor.selection.setRng inside
            @plugin?.editor.selection.setContent text

## Group ranges

The above functions rely on the `innerRange()` function, defined below, with
a corresponding `outerRange` function for the sake of completeness.  We use
a `try`/`catch` block because it's possible that the group has been removed
from the document, and thus we can no longer set range start and end points
relative to the group's open and close groupers.

        innerRange: =>
            range = @open.ownerDocument.createRange()
            try
                range.setStartAfter @open
                range.setEndBefore @close
                range
            catch e then null
        outerRange: =>
            range = @open.ownerDocument.createRange()
            try
                range.setStartBefore @open
                range.setEndAfter @close
                range
            catch e then null

We then create analogous functions for creating ranges that include the text
before or after the group.  These ranges extend to the next grouper in the
given direction, whether it be an open or close grouper of any type.
Specifically,
 * The `rangeBefore` range always ends immediately before this group's open
   grouper, and
   * if this group is the first in its parent, the range begins immediately
     after the parent's open grouper;
   * otherwise it begins immediately after its previous sibling's close
     grouper.
   * But if this is the first top-level group in the document, then the
     range begins at the start of the document.
 * The `rangeAfter` range always begins immediately after this group's close
   grouper, and
   * if this group is the last in its parent, the range ends immediately
     before the parent's close grouper;
   * otherwise it ends immediately before its next sibling's open grouper.
   * But if this is the last top-level group in the document, then the
     range ends at the end of the document.

        rangeBefore: =>
            range = ( doc = @open.ownerDocument ).createRange()
            try
                range.setEndBefore @open
                if prev = @previousSibling()
                    range.setStartAfter prev.close
                else if @parent
                    range.setStartAfter @parent.open
                else
                    range.setStartBefore doc.body.childNodes[0]
                range
            catch e then null
        rangeAfter: =>
            range = ( doc = @open.ownerDocument ).createRange()
            try
                range.setStartAfter @close
                if next = @nextSibling()
                    range.setEndBefore next.open
                else if @parent
                    range.setEndBefore @parent.close
                else
                    range.setEndAfter \
                        doc.body.childNodes[doc.body.childNodes.length-1]
                range
            catch e then null

## Working with whole groups

You can remove an entire group from the document using the following method.
It does two things:  First, it disconnects this group from any group to
which it's connected.  Second, relying on the `contentNodes` member above,
it removes all the nodes returned by that member.

This function requires that the `@plugin` member exists, or it does nothing.
It also tells the TinyMCE instance that this should all be considered part
of one action for the purposes of undo/redo.

        remove: =>
            if not @plugin then return
            @disconnect @plugin[cxn[0]] for cxn in @connectionsIn()
            @disconnect @plugin[cxn[1]] for cxn in @connectionsOut()
            @plugin.editor.undoManager.transact =>
                ( $ [ @open, @contentNodes()..., @close ] ).remove()

Sometimes you want the HTML representation of the entire group.  The
following method gives it to you, by imitating the code of `contentAsHTML`,
except using `outerRange` rather than `innerRange`.

The optional parameter, if set to false, will omit the `src` attributes on
all groupers (the two for this group, as well as each pair for every inner
group as well).  This can be useful because those `src` attributes can be
recomputed from the other grouper data, and they are enormous, so omitting
them saves significant space.

        groupAsHTML: ( withSrcAttributes = yes ) =>
            if not fragment = @outerRange()?.cloneContents()
                return null
            tmp = @open.ownerDocument.createElement 'div'
            tmp.appendChild fragment
            if not withSrcAttributes
                ( $ tmp ).find( '.grouper' ).removeAttr 'src'
            tmp.innerHTML

## Group hierarchy

The previous two functions require being able to query this group's index in
its parent group, and to use that index to look up next and previous sibling
groups.  We provide those functions here.

        indexInParent: =>
            ( @parent?.children ? @plugin?.topLevel )?.indexOf this
        previousSibling: =>
            ( @parent?.children ? @plugin?.topLevel )?[@indexInParent()-1]
        nextSibling: =>
            ( @parent?.children ? @plugin?.topLevel )?[@indexInParent()+1]

Note that the `@children` array for a group is constructed by the
`scanDocument` function of the `Groups` class, defined [below](#scanning).
Thus one can get an array of child groups for any group `G` by writing
`G.children`.

## Group change event

The following function should be called whenever the contents of the group
have changed.  It notifies the group's type, so that the requisite
processing, if any, of the new contents can take place.  It is called
automatically by some handlers in the `Groups` class, below.

By default, it propagates the change event up the ancestor chain in the
group hierarchy, but that can be disabled by passing false as the parameter.

The second parameter indicates whether this is the first `contentsChanged`
call since the group was constructed.  By default, this is false, but is set
to true from the one call made to this function from the group's
constructor.

        contentsChanged: ( propagate = yes, firstTime = no ) =>
            @type()?.contentsChanged? this, firstTime
            if propagate then @parent?.contentsChanged yes

## Group serialization

The following serialization routine is useful for sending groups to a Web
Worker for background processing.

        toJSON: =>
            data = { }
            for attr in @open.attributes
                if attr.nodeName[..5] is 'data-' and \
                   attr.nodeName[..9] isnt 'data-mce-'
                    try
                        data[attr.nodeName] =
                            JSON.parse( attr.nodeValue )[0]
            id : @id()
            typeName : @typeName()
            deleted : @deleted
            text : @contentAsText()
            html : @contentAsHTML()
            parent : @parent?.id() ? null
            children : ( child?.id() ? null for child in @children ? [ ] )
            data : data

## Group connections ("arrows")

Groups can be connected in a graph.  The graph is directed, and there can be
multiple arrows from one group to another.  Each arrow has an optional
string attribute attached to it called its "tag," which defaults to the
empty string. For multiple arrows between the same two groups, different
tags are required.

IMPORTANT: Connections among groups are not added to the undo/redo stack (by
default).  Many apps do want them on the undo/redo stack, and you can
achieve this by following the same directions given under `get` and `set`,
using the TinyMCE Undo Manager's [transact](https://www.tinymce.com/docs/api/tinymce/tinymce.undomanager/#transact) method.

Connect group `A` to group `B` by calling `A.connect B`.  The optional
second parameter is the tag string to attach.  It defaults to the empty
string.  Calling this more than once with the same `A`, `B`, and tag has the
same effect as calling it once.

        connect: ( toGroup, tag = '' ) =>
            connection = [ @id(), toGroup.id(), "#{tag}" ]
            connstring = "#{connection}"
            oldConnections = @get( 'connections' ) ? [ ]
            mustAdd = yes
            for oldConnection in oldConnections
                if "#{oldConnection}" is connstring
                    mustAdd = no
                    break
            if mustAdd
                @set 'connections', [ oldConnections..., connection ]
            oldConnections = toGroup.get( 'connections' ) ? [ ]
            mustAdd = yes
            for oldConnection in oldConnections
                if "#{oldConnection}" is connstring
                    mustAdd = no
                    break
            if mustAdd
                toGroup.set 'connections', [ oldConnections..., connection ]

The following function undoes the previous.  The third parameter can be
either a string or a regular expression.  It defaults to the empty string.
Calling `A.disconnect B, C` finds all connections from `A` to `B` satisfying
a condition on `C`.  If `C` is a string, then the connection tag must equal
`C`; if `C` is a regular expression, then the connection tag must match `C`.
Connections not satisfying these criterion are not candidates for deletion.

        disconnect: ( fromGroup, tag = '' ) =>
            matches = ( array ) =>
                array[0] is @id() and array[1] is fromGroup.id() and \
                    ( tag is array[2] or tag.test? array[2] )
            @set 'connections', ( c for c in @get( 'connections' ) ? [ ] \
                when not matches c )
            fromGroup.set 'connections', ( c for c in \
                fromGroup.get( 'connections' ) ? [ ] when not matches c )

For looking up connections, we have two functions.  One that returns all the
connections that lead out from the group in question (`connectionsOut()`)
and one that returns all connections that lead into the group in question
(`connectionsIn()`).  Each function returns an array of triples, all those
that appear in the group's connections set and have the group as the source
(for `connectionsOut()`) or the destination (for `connectionsIn()`).

        connectionsOut: =>
            id = @id()
            ( c for c in ( @get 'connections' ) ? [ ] when c[0] is id )
        connectionsIn: =>
            id = @id()
            ( c for c in ( @get 'connections' ) ? [ ] when c[1] is id )

## Group screen coordinates

The following function gives the sizes and positions of the open and close
groupers.  Because the elements between them may be taller (or sink lower)
than the groupers themselves, we also inspect the client rectangles of all
elements in the group, and adjust the relevant corners of the open and close
groupers outward to make sure the bubble encloses the entire contents of the
group.

        getScreenBoundaries: =>

The first few lines here redundantly add rects for the open and close
groupers because there seems to be a bug in `getClientRects()` for a range
that doesn't always include the close grouper.  If for some reason there are
no rectangles, we cannot return a value.  This would be a very erroneous
situation, but is here as paranoia.

            toArray = ( a ) ->
                if a? then ( a[i] for i in [0...a.length] ) else [ ]
            rects = toArray @open.getClientRects()
            .concat toArray @outerRange()?.getClientRects()
            .concat toArray @close.getClientRects()
            if rects.length is 0 then return null

Initialize the rectangle data for the open and close groupers.

            open = rects[0]
            open =
                top : open.top
                left : open.left
                right : open.right
                bottom : open.bottom
            close = rects[rects.length-1]
            close =
                top : close.top
                left : close.left
                right : close.right
                bottom : close.bottom

Compute whether the open and close groupers are in the same line of text.
This is done by examining whether they extend too far left/right/up/down
compared to one another.  If they are on the same line, then force their top
and bottom coordinates to match, to make it clear (to the caller) that this
represents a rectangle, not a "zone."

            onSameLine = yes
            for rect, index in rects
                open.top = Math.min open.top, rect.top
                close.bottom = Math.max close.bottom, rect.bottom
                if rect.left < open.left then onSameLine = no
                if rect.top > open.bottom then onSameLine = no
            if onSameLine
                close.top = open.top
                open.bottom = close.bottom

If either the open or close grouper has zero size, then an image file (for
an open/close grouper) isn't yet loaded.  Thus we need to return null, to
tell the caller that the results couldn't be computed.  The caller should
probably just set up a brief timer to recall this function again soon, when
the browser has completed the image loading.

            if ( open.top is open.bottom or close.top is close.bottom or \
                 open.left is open.right or close.left is close.right ) \
               and not ( $ @open ).hasClass 'hide' then return null

Otherwise, return the results as an object.

            open : open
            close : close

The `Group` class should be accessible globally.

    window.Group = Group

# `Groups` class

We then define a class that will encapsulate all the functionality about
groups in the editor.  An instance of this class will be stored as a member
in the TinyMCE editor object.  It will keep track of many instances of the
`Group` class.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

This particular plugin defines two classes, `Group` and `Groups`.  The differences are spelled out here:
 * Only one instance of the `Groups` class exists for any given editor.
   That instance manages global functionality about groups for that editor.
   Some of its methods create instances of the `Group` class.
 * Zero or more instances of the `Group` class exist for any given editor.
   Each instance corresponds to a single group in the document in that
   editor.

If there were only one editor, this could be changing by making all instance
methods of the `Groups` class into class methods of the `Group` class.  But
since there can be more than one editor, we need separate instances of that
"global" context for each, so we use a `Groups` class to do so.

## Groups constructor

    class Groups

        constructor: ( @editor ) ->

Each editor has a mapping from valid group type names to their attributes.

            @groupTypes = {}

It also has a list of the top-level groups in the editor, which is a forest
in which each node is a group, and groups are nested as hierarchies/trees.

            @topLevel = [ ]

The object maintains a list of unique integer ids for assigning to Groups in
the editor.  The list `@freeIds` is a list `[a_1,...,a_n]` such that an id
is available if and only if it's one of the `a_i` or is greater than `a_n`.
For this reason, the list begins as `[ 0 ]`.

            @freeIds = [ 0 ]

Install in the Overlay plugin for the same editor object a handler that
draws the groups surrounding the user's cursor.

            @editor.Overlay.addDrawHandler @drawGroups

When a free id is needed, we need a function that will give the next such
free id and then mark that id as consumed from the list.

        nextFreeId: =>
            if @freeIds.length > 1 then @freeIds.shift() else @freeIds[0]++

When an id in use becomes free, we need a function that will put it back
into the list of free ids.

        addFreeId: ( id ) =>
            if id < @freeIds[@freeIds.length-1]
                @freeIds.push id
                @freeIds.sort ( a, b ) -> a - b

We can also check to see if an id is free.

        isIdFree: ( id ) => id in @freeIds or id > @freeIds[@freeIds.length]

When a free id becomes used in some way other than through a call to
`nextFreeId`, we will want to be able to record that fact.  The following
function does so.

        setUsedID: ( id ) =>
            last = @freeIds[@freeIds.length-1]
            while last < id then @freeIds.push ++last
            i = @freeIds.indexOf id
            @freeIds.splice i, 1
            if i is @freeIds.length then @freeIds.push id + 1

## Registering group types

To register a new type of group, simply provide its name, as a text string,
together with an object of attributes.

The name string should only contain alphabetic characters, a through z, case
sensitive, hyphens, or underscores.  All other characters are removed. Empty
names are not allowed, which includes names that become empty when all
illegal characters have been removed.

Re-registering the same name with a new data object will overwrite the old
data object with the new one.  Data objects may have the following key-value
pairs.
 * key: `openImage`, value: a string pointing to the image file to use when
   the open grouper is visible, defaults to `'images/red-bracket-open.png'`
 * If instead you provide the `openImageHTML` tag, an image will be created
   for you by rendering the HTML you provide, and you need not provide an
   `openImage` key-value pair.
 * key: `closeImage`, complement to the previous, defaults to
   `'images/red-bracket-close.png'`
 * Similarly, `closeImageHTML` functions like `openImageHTML`.
 * any key-value pairs useful for placing the group into a menu or toolbar,
   such as the keys `text`, `context`, `tooltip`, `shortcut`, `image`,
   and/or `icon`

Clients don't actually need to call this function.  In their call to their
editor's `init` function, they can include in the large, single object
parameter a key-value pair with key `groupTypes` and value an array of
objects.  Each should have the key `name` and all the other data that this
routine needs, and they will be passed along directly.

        addGroupType: ( name, data = {} ) =>
            name = ( n for n in name when /[a-zA-Z_-]/.test n ).join ''
            @groupTypes[name] = data
            if data.hasOwnProperty 'text'
                plugin = this
                if data.imageHTML?
                    data.image = htmlToImage data.imageHTML
                if data.openImageHTML?
                    blob = svgBlobForHTML data.openImageHTML,
                        createStyleString()
                    data.openImage = objectURLForBlob blob
                    base64URLForBlob blob, ( result ) ->
                        data.openImage = result
                if data.closeImageHTML?
                    blob = svgBlobForHTML data.closeImageHTML,
                        createStyleString()
                    data.closeImage = objectURLForBlob blob
                    base64URLForBlob blob, ( result ) ->
                        data.closeImage = result
                menuData =
                    text : data.text
                    context : data.context ? 'Insert'
                    onclick : => @groupCurrentSelection name
                    onPostRender : -> # must use -> here to access "this":
                        plugin.groupTypes[name].menuItem = this
                        plugin.updateButtonsAndMenuItems()
                if data.shortcut? then menuData.shortcut = data.shortcut
                if data.icon? then menuData.icon = data.icon
                @editor.addMenuItem name, menuData
                buttonData =
                    tooltip : data.tooltip
                    onclick : => @groupCurrentSelection name
                    onPostRender : -> # must use -> here to access "this":
                        plugin.groupTypes[name].button = this
                        plugin.updateButtonsAndMenuItems()
                key = if data.image? then 'image' else \
                    if data.icon? then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData
            data.connections ?= ( group ) ->
                triples = group.connectionsOut()
                [ triples..., ( t[1] for t in triples )... ]

The above function calls `updateButtonsAndMenuItems()` whenever a new button
or menu item is first drawn.  That function is also called whenever the
cursor in the document moves or the groups are rescanned.  It enables or
disables the group-insertion routines based on whether the selection should
be allowed to be wrapped in a group.  This is determined based on whether
the two ends of the selection are inside the same deepest group.

        updateButtonsAndMenuItems: =>
            left = @editor?.selection?.getRng()?.cloneRange()
            if not left then return
            right = left.cloneRange()
            left.collapse yes
            right.collapse no
            left = @groupAboveCursor left
            right = @groupAboveCursor right
            for own name, type of @groupTypes
                type?.button?.disabled left isnt right
                type?.menuItem?.disabled left isnt right
            @connectionsButton?.disabled not left? or ( left isnt right )
            @updateConnectionsMode()

The above function calls `updateConnectionsMode()`, which checks to see if
connections mode has been entered/exited since the last time the function
was run, and if so, updates the UI to reflect the change.

        updateConnectionsMode: =>
            if @connectionsButton?.disabled()
                @connectionsButton?.active no

## Inserting new groups

The following method will wrap the current selection in the current editor
in groupers (i.e., group endpoints) of the given type.  The type must be on
the list of valid types registered with `addGroupType`, above, or this will
do nothing.

        groupCurrentSelection: ( type ) =>

Ignore attempts to insert invalid group types.

            if not @groupTypes.hasOwnProperty type then return

Determine whether existing groupers are hidden or not, so that we insert the
new ones to match.

            hide = ( $ @allGroupers()?[0] ).hasClass 'hide'

Create data to be used for open and close groupers, a cursor placeholder,
and the current contents of the cursor selection.

            id = @nextFreeId()
            open = grouperHTML type, 'open', id, hide,
                @groupTypes[type].openImage
            close = grouperHTML type, 'close', id, hide,
                @groupTypes[type].closeImage

Wrap the current cursor selection in open/close groupers, with the cursor
placeholder after the old selection.

            sel = @editor.selection
            if sel.getStart() is sel.getEnd()

If the whole selection is within one element, then we can just replace the
selection's content with wrapped content, plus a cursor placeholder that we
immediately remove after placing the cursor back there.  We also keep track
of the close grouper element so that we can place the cursor immediately to
its left after removing the cursor placeholder (or else the cursor may leap
to the start of the document).

                content = @editor.selection.getContent()
                @editor.insertContent open + content + '{$caret}' + close
                cursor = @editor.selection.getRng()
                close = cursor.endContainer.childNodes[cursor.endOffset] ?
                    cursor.endContainer.nextSibling
                if close.tagName is 'P' then close = close.childNodes[0]
                newGroup = @grouperToGroup close
                newGroup.parent?.contentsChanged()
            else

But if the selection spans multiple elements, then we must handle each edge
of the selection separately.  We cannot use this solution in general,
because editing an element messes up cursor bookmarks within that element.

                range = sel.getRng()
                leftNode = range.startContainer
                leftPos = range.startOffset
                rightNode = range.endContainer
                rightPos = range.endOffset
                range.collapse no
                sel.setRng range
                @disableScanning()
                @editor.insertContent '{$caret}' + close
                range = sel.getRng()
                close = range.endContainer.childNodes[range.endOffset] ?
                    range.endContainer.nextSibling
                range.setStart leftNode, leftPos
                range.setEnd leftNode, leftPos
                sel.setRng range
                @editor.insertContent open
                @enableScanning()
                @editor.selection.select close
                @editor.selection.collapse yes
                newGroup = @grouperToGroup close
                newGroup.parent?.contentsChanged()

## Hiding and showing "groupers"

The word "grouper" refers to the objects that form the boundaries of a group, and thus define the group's extent.  Each is an image with specific classes that define its partner, type, visibility, etc.  The following method applies or removes the visibility flag to all groupers at once, thus toggling their visibility in the document.

        allGroupers: => @editor.getDoc().getElementsByClassName 'grouper'
        hideOrShowGroupers: =>
            groupers = $ @allGroupers()
            if ( $ groupers?[0] ).hasClass 'hide'
                groupers.removeClass 'hide'
            else
                groupers.addClass 'hide'
            groupers.filter( '.decorate' ).each ( index, grouper ) =>
                @grouperToGroup( grouper ).updateGrouper grouper
            @editor.Overlay?.redrawContents()
            @editor.focus()

## Scanning

Scanning is the process of reading the entire document and observing where
groupers lie.  This has several purposes.
 * It verifyies that groups are well-formed (i.e., no unpaired groupers, no
   half-nesting).
 * It ensures the list of `@freeIds` is up-to-date.
 * It maintains an in-memory hierarchy of Group objects (to be implemented).

There are times when we need programmatically to make several edits to the
document, and want them to happen as a single unit, without the
`scanDocument` function altering the document's structure admist the work.
Document scanning can be disabled by adding a scan lock.  Do so with the
following two convenience functions.

        disableScanning: => @scanLocks = ( @scanLocks ?= 0 ) + 1
        enableScanning: =>
            @scanLocks = Math.max ( @scanLocks ? 0 ) - 1, 0
            if @scanLocks is 0 then @scanDocument()

We also want to track when scanning is happening, so that `scanDocument`
cannot get into infinitely deep recursion by triggering a change in the
document, which in turn calls `scanDocument` again.  We track whether a scan
is running using this flag.  (Note that the scanning routine constructs new
`Group` objects, which call `contentsChanged` handlers, which let clients
execute arbitrary code, so the infinite loop is quite possible, and thus
must be prevented.)

        isScanning = no

Now the routine itself.

        scanDocument: =>

If scanning is disabled, do nothing.  If it's already happening, then
whatever change is attempting to get us to scan again should just have the
new scan start *after* this one completes, not during.

            if @scanLocks > 0 then return
            if isScanning then return setTimeout ( => @scanDocument ), 0
            isScanning = yes

Group ids should be unique, so if we encounter the same one twice, we have a
problem.  Thus we now mark all old groups as "old," so that we can tell when
the first time we re-register them is, and avoid re-regestering the same
group (with the same id) a second time.

            for id in @ids()
                if @[id]? then @[id].old = yes

Initialize local variables:

            groupers = Array::slice.apply @allGroupers()
            gpStack = [ ]
            usedIds = [ ]
            @topLevel = [ ]
            @idConversionMap = { }
            before = @freeIds[..]
            index = ( id ) ->
                for gp, i in gpStack
                    if gp.id is id then return i
                -1

Scanning processes each grouper in the document.

            for grouper in groupers

If it had the grouper class but wasn't really a grouper, delete it.

                if not ( info = grouperInfo grouper )?
                    ( $ grouper ).remove()

If it's an open grouper, push it onto the stack of nested ids we're
tracking.

                else if info.openOrClose is 'open'
                    gpStack.unshift
                        id : info.id
                        grouper : grouper
                        children : [ ]

Otherwise, it's a close grouper.  If it doesn't have a corresponding open
grouper that we've already seen, delete it.

                else
                    if index( info.id ) is -1
                        ( $ grouper ).remove()
                    else

It has an open grouper.  In case that open grouper wasn't the most recent
thing we've seen, delete everything that's intervening, because they're
incorrectly positioned.

                        while gpStack[0].id isnt info.id
                            ( $ gpStack.shift().grouper ).remove()

Then allow the grouper and its partner to remain in the document, and pop
the stack, because we've moved past the interior of that group.
Furthermore, register the group and its ID in this Groups object.

                        groupData = gpStack.shift()
                        id = @registerGroup groupData.grouper, grouper
                        usedIds.push id
                        newGroup = @[id]

Assign parent and child relationships, and store this just-created group on
either the list of children for the next parent outwards in the hierarchy,
or the "top level" list if there is no surrounding group.

                        newGroup.children = groupData.children
                        for child in newGroup.children
                            child.parent = newGroup
                        if gpStack.length > 0
                            gpStack[0].children.push newGroup
                        else
                            @topLevel.push newGroup
                            newGroup.parent = null

Any groupers lingering on the "open" stack have no corresponding close
groupers, and must therefore be deleted.

            while gpStack.length > 0
                ( $ gpStack.shift().grouper ).remove()

Now update the `@freeIds` list to be the complement of the `usedIds` array.

            usedIds.sort ( a, b ) -> a - b
            count = 0
            @freeIds = [ ]
            while usedIds.length > 0
                if count is usedIds[0]
                    while count is usedIds[0] then usedIds.shift()
                else
                    @freeIds.push count
                count++
            @freeIds.push count

And any ID that is free now but wasn't before must have its group deleted
from this object's internal cache.  After we delete all of them from the
cache, we also call the group type's `deleted` method on each one, to permit
finalization code to run.  We also mark each with a "deleted" attribute set
to true, so that if there are any pending computations about that group,
they know not to bother actually modifying the group when they complete,
because it is no longer in the document anyway.

            after = @freeIds[..]
            while before[before.length-1] < after[after.length-1]
                before.push before[before.length-1] + 1
            while after[after.length-1] < before[before.length-1]
                after.push after[after.length-1] + 1
            becameFree = ( a for a in after when a not in before )
            deleted = [ ]
            for id in becameFree
                deleted.push @[id]
                @[id]?.deleted = yes
                delete @[id]
            group?.type()?.deleted? group for group in deleted

If any groups were just introduced to this document by pasting, we need to
process their connections, because the groups themselves may have had to be
given new ids (to preserve uniqueness within this document) and thus the ids
in any of their connections need to be updated to stay internally consistent
within the pasted content.

            justPasted =
                @editor.getDoc().getElementsByClassName 'justPasted'
            justPasted = ( justPasted[i] for i in [0...justPasted.length] )
            for grouper in justPasted
                if /^close/.test grouper.getAttribute 'id' then continue
                group = @grouperToGroup grouper
                connections = group.get 'connections'
                if not connections then continue
                for connection in connections
                    if @idConversionMap.hasOwnProperty connection[0]
                        connection[0] = @idConversionMap[connection[0]]
                    if @idConversionMap.hasOwnProperty connection[1]
                        connection[1] = @idConversionMap[connection[1]]
                group.set 'connections', connections
            ( $ justPasted ).removeClass 'justPasted'

Invalidate the `ids()` cache
([defined below](#querying-the-group-hierarchy)) so that the next time that
function is run, it recomputes its results from the newly-generated
hierarchy in `topLevel`.

            delete @idsCache

If the Overlay plugin is in use, it should now redraw, since the list of
groups may have changed.  We put it on a slight delay, because there may
still be some pending cursor movements that we want to ensure have finished
before this drawing routine is called.  At the same time, we also update
the enabled/disabled state of group-insertion buttons and menu items.

            setTimeout =>
                @editor.Overlay?.redrawContents()
                @updateButtonsAndMenuItems()
            , 0
            isScanning = no

The above function needs to create instances of the `Group` class, and
associate them with their IDs.  The following function does so, re-using
copies from the cache when possible.  When it encounters a duplicate id, it
renames it to the first unused number in the document.  Note that we cannot
use `@freeIds` here, because it is being updated by `@scanDocument()`, so we
must use the more expensive version of actually querying the elements that
exist in the document itself via `getElementById()`.

        registerGroup: ( open, close ) =>
            cached = @[id = grouperInfo( open ).id]
            if cached?.open isnt open or cached?.close isnt close
                if @[id]? and not @[id].old
                    newId = 0
                    doc = @editor.getDoc()
                    while doc.getElementById "open#{newId}" or \
                          doc.getElementById "close#{newId}" then newId++
                    open.setAttribute 'id', "open#{newId}"
                    close.setAttribute 'id', "close#{newId}"
                    @idConversionMap[id] = newId
                    id = newId
                @[id] = new Group open, close, this
            else
                delete @[id].old

Also, for each group, we inspect whether its groupers have correctly loaded
their images (by checking their `naturalWidth`), because in several cases
(e.g., content pasted from a different browser tab, or pasted from this same
page before a page reload, or re-inserted by an undo operation) the object
URLs for the images can become invalid.  Thus to avoid broken images for our
groupers, we must recompute their `src` attributes.

            if open.naturalWidth is undefined or open.naturalWidth is 0
                @[id].updateGrouper 'open'
            if close.naturalWidth is undefined or close.naturalWidth is 0
                @[id].updateGrouper 'close'

Return the (old and kept, or newly updated) ID.

            id

## Querying the group hierarchy

The results of the scanning process in [the previous section](#scanning) are
readable through the following functions.

The following method returns a list of all ids that appear in the Groups
hierarchy, in tree order.

        ids: =>
            if not @idsCache?
                @idsCache = [ ]
                recur = ( g ) =>
                    @idsCache.push g.id()
                    recur child for child in g.children
                recur group for group in @topLevel
            @idsCache

The following method finds the group for a given open/close grouper element
from the DOM.  It returns null if the given object is not an open/close
grouper, or does not appear in the group hierarchy.

        grouperToGroup: ( grouper ) =>
            if ( id = grouperInfo( grouper )?.id )? then @[id] else null

The following method finds the deepest group containing a given DOM Node.
It does so by a binary search through the groupers array for the closest
grouper before the node.  If it is an open grouper, the node is in that
group.  If it is a close grouper, the node is in its parent group.

        groupAboveNode: ( node ) =>
            if ( all = @allGroupers() ).length is 0 then return null
            left = index : 0, grouper : all[0], leftOfNode : yes
            return @grouperToGroup left.grouper if left.grouper is node
            return null if not strictNodeOrder left.grouper, node
            right = index : all.length - 1, grouper : all[all.length - 1]
            return @grouperToGroup right.grouper if right.grouper is node
            return null if strictNodeOrder right.grouper, node
            loop
                if left.grouper is node
                    return @grouperToGroup left.grouper
                if right.grouper is node
                    return @grouperToGroup right.grouper
                if left.index + 1 is right.index
                    return null unless group = @grouperToGroup left.grouper
                    return if left.grouper is group.open then group \
                        else group.parent
                middle = Math.floor ( left.index + right.index ) / 2
                if strictNodeOrder all[middle], node
                    left =
                        index : middle
                        grouper : all[middle]
                        leftOfNode : yes
                else
                    right =
                        index : middle
                        grouper : all[middle]
                        leftOfNode : no

The following method is like the previous, but instead of computing the
deepest group above a given node, it computes the deepest group above a
given cursor position.  This must be presented to the method in the form of
an HTML Range object that has the same start and end nodes and offsets, such
as one that has been collapsed.

        groupAboveCursor: ( cursor ) =>
            if cursor.startContainer instanceof @editor.getWin().Text
                return @groupAboveNode cursor.startContainer
            if cursor.startContainer.childNodes.length > cursor.startOffset
                elementAfter =
                    cursor.startContainer.childNodes[cursor.startOffset]
                itsGroup = @groupAboveNode elementAfter
                return if itsGroup?.open is elementAfter \
                    then itsGroup.parent else itsGroup
            if cursor.startContainer.childNodes.length > 0
                elementBefore =
                    cursor.startContainer.childNodes[cursor.startOffset - 1]
                itsGroup = @groupAboveNode elementBefore
                return if itsGroup?.close is elementBefore \
                    then itsGroup.parent else itsGroup
            @groupAboveNode cursor.startContainer

The following method generalizes the previous to HTML Range objects that do
not have the same starting and ending points.  The group returned will be
the deepest group containing both ends of the cursor.

        groupAboveSelection: ( range ) =>

Compute the complete ancestor chain of the left end of the range.

            left = range.cloneRange()
            left.collapse yes
            left = @groupAboveCursor left
            leftChain = [ ]
            while left?
                leftChain.unshift left
                left = left.parent

Compute the complete ancestor chain of the right end of the range.

            right = range.cloneRange()
            right.collapse no
            right = @groupAboveCursor right
            rightChain = [ ]
            while right?
                rightChain.unshift right
                right = right.parent

Find the deepest group in both ancestor chains.

            result = null
            while leftChain.length > 0 and rightChain.length > 0 and \
                  leftChain[0] is rightChain[0]
                result = leftChain.shift()
                rightChain.shift()
            result

## Change Events

The following function can be called whenever a certain range in the
document has changed, and groups touching that range need to be updated.  It
assumes that `scanDocument()` was recently called, so that the group
hierarchy is up-to-date.  The parameter must be a DOM Range object.

        rangeChanged: ( range ) =>
            group.contentsChanged no for group in @groupsTouchingRange range

That method uses `@groupsTouchingRange()`, which is implemented below.  It
uses the previous to get a list of all groups that intersect the given DOM
Range object, in the order in which their close groupers appear (which means
that child groups are guaranteed to appear earlier in the list than their
parent groups).

The return value will include all groups whose interior or groupers
intersect the interior of the range.  This includes groups that intersect
the range only indirectly, by being parents whose children intersect the
range, and so on for grandparent groups, etc.  When the selection is
collapsed, the only "leaf" group intersecting it is the one containing it.

This routine requires that `scanDocument` has recently been called, so that
groupers appear in perfectly matched pairs, correctly nested.

        groupsTouchingRange: ( range ) =>
            if ( all = @allGroupers() ).length is 0 then return [ ]
            firstInRange = 1 + @grouperIndexOfRangeEndpoint range, yes, all
            lastInRange = @grouperIndexOfRangeEndpoint range, no, all

If there are no groupers in the selected range at all, then just create the
parent chain of groups above the closest node to the selection.

            if firstInRange > lastInRange
                node = range.startContainer
                if node instanceof @editor.getWin().Element and \
                   range.startOffset < node.childNodes.length
                    node = node.childNodes[range.startOffset]
                group = @groupAboveNode node
                result = if group
                    if group.open is node
                        if group.parent then [ group.parent ] else [ ]
                    else
                        [ group ]
                else
                    [ ]
                while maybeOneMore = result[result.length-1]?.parent
                    result.push maybeOneMore
                return result

Otherwise walk through all the groupers in the selection and push their
groups onto a stack in the order that the close groupers are encountered.

            stack = [ ]
            result = [ ]
            for index in [firstInRange..lastInRange]
                group = @grouperToGroup all[index]
                if all[index] is group.open
                    stack.push group
                else
                    result.push group
                    stack.pop()

Then push onto the stack any open groupers that aren't yet closed, and any
ancestor groups of the last big group encountered, the only one whose parent
groups may not have been seen as open groupers.

            while stack.length > 0 then result.push stack.pop()
            while maybeOneMore = result[result.length-1].parent
                result.push maybeOneMore
            result

The above method uses `@grouperIndexOfRangeEndpoint`, which is defined here.
It locates the endpoint of a DOM Range object in the list of groupers in the
editor.  It performs a binary search through the ordered list of groupers.

The `range` parameter must be a DOM Range object.  The `left` paramter
should be true if you're asking about the left end of the range, false if
you're asking about the right end.

The return value will be the index into `@allGroupers()` of the last grouper
before the range endpoint.  Clearly, then, the grouper on the other side of
the range endpoint is the return value plus 1.  If no groupers are before
the range endpoint, this return value will be -1; a special case of this is
when there are no groupers at all.

The final parameter is optional; it prevents having to compute
`@allGroupers()`, in case you already have that data available.

        grouperIndexOfRangeEndpoint: ( range, left, all ) =>
            if ( all ?= @allGroupers() ).length is 0 then return -1
            endpoint = if left then Range.END_TO_START else Range.END_TO_END
            isLeftOfEndpoint = ( grouper ) =>
                grouperRange = @editor.getDoc().createRange()
                grouperRange.selectNode grouper
                range.compareBoundaryPoints( endpoint, grouperRange ) > -1
            left = 0
            return -1 if not isLeftOfEndpoint all[left]
            right = all.length - 1
            return right if isLeftOfEndpoint all[right]
            loop
                return left if left + 1 is right
                middle = Math.floor ( left + right ) / 2
                if isLeftOfEndpoint all[middle]
                    left = middle
                else
                    right = middle

## Drawing Groups

The following function draws groups around the user's cursor, if any.  It is
installed in [the constructor](#groups-constructor) and called by [the
Overlay plugin](overlayplugin.litcoffee).

        drawGroups: ( canvas, context ) =>
            @bubbleTags = [ ]

We do not draw the groups if document scanning is disabled, because it means
that we are in the middle of a change to the group hierarchy, which means
that calls to the functions we'll need to figure out what to draw will give
unstable/incorrect results.

            if @scanLocks > 0 then return
            group = @groupAboveSelection @editor.selection.getRng()
            bodyStyle = getComputedStyle @editor.getBody()
            leftMar = parseInt bodyStyle['margin-left']
            rightMar = parseInt bodyStyle['margin-right']
            pad = 3
            padStep = 2
            radius = 4
            tags = [ ]

We define a group-drawing function that we will call on all groups from
`group` on up the group hierarchy.

            drawGroup = ( group, drawOutline, drawInterior, withTag ) =>
                type = group.type()
                color = type?.color ? '#444444'

Compute the group's boundaries, and if that's not possible, quit this whole
routine right now.

                if not boundaries = group.getScreenBoundaries()
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 100
                    return null
                { open, close } = boundaries

Pad by `pad/3` in the x direction, `pad` in the y direction, and with corner
radius `radius`.

                x1 = open.left - pad/3
                y1 = open.top - pad
                x2 = close.right + pad/3
                y2 = close.bottom + pad

Compute the group's tag contents, if any, and store where and how to draw
them.

                if withTag and tagString = type?.tagContents? group
                    tags.push
                        content : tagString
                        corner : { x : x1, y : y1 }
                        color : color
                        style : createFontStyleString group.open
                        group : group

Draw this group, either a rounded rectangle or a "zone," which is a
rounded rectangle that experienced something like word wrapping.

                context.fillStyle = context.strokeStyle = color
                if open.top is close.top and open.bottom is close.bottom
                    context.roundedRect x1, y1, x2, y2, radius
                else
                    context.roundedZone x1, y1, x2, y2, open.bottom,
                        close.top, leftMar, rightMar, radius
                if drawOutline
                    context.globalAlpha = 1.0
                    context.lineWidth = 1.5
                    context.stroke()
                if drawInterior
                    context.globalAlpha = 0.3
                    context.fill()
                yes # success

That concludes the group-drawing function.  Let's now call it on all the
groups in the hierarchy, from `group` on upwards.

            innermost = yes
            walk = group
            while walk
                if not drawGroup walk, yes, innermost, yes then return
                walk = walk.parent
                pad += padStep
                innermost = no

Now draw the tags on all the bubbles just drawn.  We proceed in reverse
order, so that outer tags are drawn behind inner ones.  We also track the
rectangles we've covered, and move any later ones upward so as not to
collide with ones drawn earlier.

We begin by measuring the sizes of the rectangles, and checking for
collisions.  Those that collide with previously-scanned rectangles are slid
upwards so that they don't collide anymore.  After all collisions have been
resolved, the rectangle's bottom boundary is reset to what it originally
was, so that the rectangle actually just got taller.

            tagsToDraw = [ ]
            while tags.length > 0
                tag = tags.shift()
                context.font = tag.font
                if not size = context.measureHTML tag.content, tag.style
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 10
                    return
                x1 = tag.corner.x - padStep
                y1 = tag.corner.y - size.height - 2*padStep
                x2 = x1 + 2*padStep + size.width
                y2 = tag.corner.y
                for old in tagsToDraw
                    if rectanglesCollide x1, y1, x2, y2, old.x1, old.y1, \
                                         old.x2, old.y2
                        moveBy = old.y1 - y2
                        y1 += moveBy
                        y2 += moveBy
                y2 = tag.corner.y
                [ tag.x1, tag.y1, tag.x2, tag.y2 ] = [ x1, y1, x2, y2 ]
                tagsToDraw.unshift tag

Now we draw the tags that have already been sized for us by the previous
loop.

            for tag in tagsToDraw
                context.roundedRect tag.x1, tag.y1, tag.x2, tag.y2, radius
                context.globalAlpha = 1.0
                context.fillStyle = '#ffffff'
                context.fill()
                context.lineWidth = 1.5
                context.strokeStyle = tag.color
                context.stroke()
                context.globalAlpha = 0.7
                context.fillStyle = tag.color
                context.fill()
                context.fillStyle = '#000000'
                context.globalAlpha = 1.0
                if not context.drawHTML tag.content, tag.x1 + padStep, \
                        tag.y1, tag.style
                    setTimeout ( => @editor.Overlay?.redrawContents() ), 10
                    return
                @bubbleTags.unshift tag

If there is a group the mouse is hovering over, also draw its interior only,
to show where the mouse is aiming.

            pad = 3
            if @groupUnderMouse
                if not drawGroup @groupUnderMouse, no, yes, no then return

If this group has connections to any other groups, draw them now.

First, define a few functions that draw an arrow from one group to another.
The label is the optional string tag on the connection, and the index is an
index into the list of connections that are to be drawn.

            topEdge = ( open, close ) =>
                left :
                    x : open.left
                    y : open.top
                right :
                    x : if open.top is close.top and \
                           open.bottom is close.bottom
                        close.right
                    else
                        canvas.width - rightMar
                    y : open.top
            bottomEdge = ( open, close ) =>
                left :
                    x : if open.top is close.top and \
                           open.bottom is close.bottom
                        open.left
                    else
                        leftMar
                    y : close.bottom
                right :
                    x : close.right
                    y : close.bottom
            gap = 20
            groupEdgesToConnect = ( fromBds, toBds ) =>
                if fromBds.close.bottom + gap < toBds.open.top
                    from : bottomEdge fromBds.open, fromBds.close
                    to : topEdge toBds.open, toBds.close
                    startDir : 1
                    endDir : 1
                else if toBds.close.bottom + gap < fromBds.open.top
                    from : topEdge fromBds.open, fromBds.close
                    to : bottomEdge toBds.open, toBds.close
                    startDir : -1
                    endDir : -1
                else
                    from : topEdge fromBds.open, fromBds.close
                    to : topEdge toBds.open, toBds.close
                    startDir : -1
                    endDir : 1
            interp = ( left, right, index, length ) =>
                pct = ( index + 1 ) / ( length + 1 )
                right = Math.min right, left + 40 * length
                ( 1 - pct ) * left + pct * right
            drawArrow = ( index, outOf, from, to, label, setStyle ) =>
                context.save()
                context.strokeStyle = from.type()?.color or '#444444'
                setStyle? context
                context.globalAlpha = 1.0
                context.lineWidth = 2
                fromBox = from.getScreenBoundaries()
                toBox = to.getScreenBoundaries()
                if not fromBox or not toBox then return
                fromBox.open.top -= pad
                fromBox.close.top -= pad
                fromBox.open.bottom += pad
                fromBox.close.bottom += pad
                toBox.open.top -= pad
                toBox.close.top -= pad
                toBox.open.bottom += pad
                toBox.close.bottom += pad
                how = groupEdgesToConnect fromBox, toBox
                startX = interp how.from.left.x, how.from.right.x, index,
                    outOf
                startY = how.from.left.y
                endX = interp how.to.left.x, how.to.right.x, index, outOf
                endY = how.to.left.y
                context.bezierArrow startX, startY,
                    startX, startY + how.startDir * gap,
                    endX, endY - how.endDir * gap, endX, endY
                context.stroke()
                if label isnt ''
                    centerX = context.applyBezier startX, startX, endX,
                        endX, 0.5
                    centerY = context.applyBezier startY,
                        startY + how.startDir * gap,
                        endY - how.endDir * gap, endY, 0.5
                    style = createFontStyleString group.open
                    if not size = context.measureHTML label, style
                        setTimeout ( => @editor.Overlay?.redrawContents() ),
                            10
                        return
                    context.roundedRect \
                        centerX - size.width / 2 - padStep,
                        centerY - size.height / 2 - padStep,
                        centerX + size.width / 2 + padStep,
                        centerY + size.width / 2, radius
                    context.globalAlpha = 1.0
                    context.fillStyle = '#ffffff'
                    context.fill()
                    context.lineWidth = 1.5
                    context.strokeStyle = from.type()?.color ? '#444444'
                    context.stroke()
                    context.fillStyle = '#000000'
                    context.globalAlpha = 1.0
                    context.drawHTML label,
                        centerX - size.width / 2 + padStep,
                        centerY - size.height / 2, style
                context.restore()

Second, draw all connections from the innermost group containing the cursor,
if there are any.

            if group
                connections = group.type().connections? group
                numArrays = ( c for c in connections \
                    when c instanceof Array ).length
                for connection in connections ? [ ]
                    if connection not instanceof Array
                        drawGroup @[connection], yes, no, no
                for connection, index in connections ? [ ]
                    if connection instanceof Array
                        drawArrow index, numArrays, @[connection[0]],
                            @[connection[1]], connection[2..]...

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Groups` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'groups', ( editor, url ) ->
        editor.Groups = new Groups editor
        editor.on 'init', ( event ) -> editor.dom.loadCSS 'groupsplugin.css'
        for type in editor.settings.groupTypes
            editor.Groups.addGroupType type.name, type
        editor.addMenuItem 'hideshowgroups',
            text : 'Hide/show groups'
            context : 'View'
            onclick : -> editor.Groups.hideOrShowGroupers()

Applications which want to use arrows among groups often want to give the
user a convenient way to connect groups visually.  We provide the following
function that installs a handy UI for doing so.  This function should be
called before `tinymce.init`, which means at page load time, not thereafter.

        if window.useGroupConnectionsUI
            editor.addButton 'connect',
                image : htmlToImage '&#x2197;'
                tooltip : 'Connect groups'
                onclick : ->
                    @active not @active()
                    editor.Groups.updateConnectionsMode()
                onPostRender : ->
                    editor.Groups.connectionsButton = this
                    editor.Groups.updateButtonsAndMenuItems()

The document needs to be scanned (to rebuild the groups hierarchy) whenever
it changes.  The editor's change event is not reliable, in that it fires
only once at the beginning of any sequence of typing.  Thus we watch not
only for change events, but also for KeyUp events.  We filter the latter so
that we do not rescan the document if the key in question was only an arrow
key or home/end/pgup/pgdn.

In addition to rescanning the document, we also call the `rangeChanged`
event of the Groups plugin, to update any groups that overlap the range in
which the document was modified.

        editor.on 'change SetContent', ( event ) ->
            editor.Groups.scanDocument()
            if event?.level?.bookmark
                orig = editor.selection.getBookmark()
                editor.selection.moveToBookmark event.level.bookmark
                range = editor.selection.getRng()
                editor.selection.moveToBookmark orig
                editor.Groups.rangeChanged range
        editor.on 'KeyUp', ( event ) ->
            movements = [ 33..40 ] # arrows, pgup/pgdn/home/end
            modifiers = [ 16, 17, 18, 91 ] # alt, shift, ctrl, meta
            if event.keyCode in movements or event.keyCode in modifiers
                return
            editor.Groups.scanDocument()
            editor.Groups.rangeChanged editor.selection.getRng()

Copying and pasting content that contains groups can be very problematic,
because each group is supposed to have a unique ID.  If we permit direct
copying and pasting of content, it will duplicate the same group (with its
ID intact) throughout the document.  Thus we must process the content we've
pasted immediately after a paste, and possibly renumber any group IDs in
that content.  This is done in `@scanDocument()`, but it needs to know which
content was just pasted; we mark such content here.

        editor.on 'PastePostProcess', ( event ) ->
            recur = ( node, address ) ->
                id = node?.getAttribute? 'id'
                if match = /^(open|close)(\d+)$/.exec id
                    ( $ node ).addClass 'justPasted'
                for index in [0...node?.childNodes?.length ? 0]
                    recur node.childNodes[index], "#{address}.#{index}"
            recur event.node, ''

Whenever the cursor moves, we should update whether the group-insertion
buttons and menu items are enabled.

        editor.on 'NodeChange', ( event ) ->
            editor.Groups.updateButtonsAndMenuItems()

The following handler installs a context menu that is exactly like that
created by the TinyMCE context menu plugin, except that it appends to it
any custom menu items needed by any groups inside which the user clicked.

        editor.on 'contextMenu', ( event ) ->

Prevent the browser's context menu.

            event.preventDefault()

Figure out where the user clicked, and whether there are any groups there.

            x = event.clientX
            y = event.clientY
            if node = editor.getDoc().nodeFromPoint x, y
                group = editor.Groups.groupAboveNode node

Compute the list of normal context menu items.

            contextmenu = editor.settings.contextmenu or \
                'link image inserttable | cell row column deletetable'
            items = [ ]
            for name in contextmenu.split /[ ,]/
                item = editor.menuItems[name]
                if name is '|' then item = text : name
                if item then item.shortcut = '' ; items.push item

Add any group-specific context menu items.

            if newItems = group?.type()?.contextMenuItems group
                items.push text : '|'
                items = items.concat newItems

Construct the menu and show it on screen.

            menu = new tinymce.ui.Menu(
                items : items
                context : 'contextmenu'
                classes : 'contextmenu'
            ).renderTo()
            editor.on 'remove', -> menu.remove() ; menu = null
            pos = ( $ editor.getContentAreaContainer() ).position()
            menu.moveTo x + pos.left, y + pos.top

There are two actions the plugin must take on the mouse down event in the
editor.

In connection-making mode, if the user clicks inside a bubble, we must
attempt to form a connection between the group the cursor is currently in
and the group in which the user clicked.

Otherwise, if the user clicks in a bubble tag, we must discern which bubble
tag received the click, and trigger the tag menu for that group, if it
defines one.  We use the mousedown event rather than the click event,
because the mousedown event is the only one for which `preventDefault()` can
function. By the time the click event happens (strictly after mousedown), it
is too late to prevent the default handling of the event.

        editor.on 'mousedown', ( event ) ->
            x = event.clientX
            y = event.clientY

First, the case for connection-making mode.

            if editor.Groups.connectionsButton?.active()
                if group = editor.groupUnderMouse x, y
                    left = editor.selection?.getRng()?.cloneRange()
                    if not left then return
                    left.collapse yes
                    currentGroup = editor.Groups.groupAboveCursor left
                    currentGroup.type()?.connectionRequest? currentGroup,
                        group
                    event.preventDefault()
                    editor.Groups.connectionsButton?.active false
                    editor.Groups.updateConnectionsMode()
                    return no
                return

Now the case for clicking bubble tags.

            for tag in editor.Groups.bubbleTags
                if tag.x1 < x < tag.x2 and tag.y1 < y < tag.y2
                    menuItems = tag.group?.type()?.tagMenuItems tag.group
                    menuItems ?= [
                        text : 'no actions available'
                        disabled : true
                    ]
                    menu = new tinymce.ui.Menu(
                        items : menuItems
                        context : 'contextmenu'
                        classes : 'contextmenu'
                    ).renderTo()
                    editor.on 'remove', -> menu.remove() ; menu = null
                    pos = ( $ editor.getContentAreaContainer() ).position()
                    menu.moveTo x + pos.left, y + pos.top
                    event.preventDefault()
                    return no

The previous function uses the `nodeUnderMouse()` routine, defined here.
That same routine is also used in the mouse move handler defined below.

The following functions install an event handler that highlights the
innermost group under the mouse pointer at all times.

        editor.on 'mousemove', ( event ) ->
            editor.Groups.groupUnderMouse =
                editor.groupUnderMouse event.clientX, event.clientY
            editor.Overlay?.redrawContents()

The previous two functions both leverage the following utility.

        editor.groupUnderMouse = ( x, y ) ->
            doc = editor.getDoc()
            el = doc.elementFromPoint x, y
            for i in [0...el.childNodes.length]
                node = el.childNodes[i]
                if node.nodeType is 3
                    range = doc.createRange()
                    range.selectNode node
                    rects = range.getClientRects()
                    rects = ( rects[i] for i in [0...rects.length] )
                    for rect in rects
                        if x > rect.left and x < rect.right and \
                           y > rect.top and y < rect.bottom
                            return editor.Groups.groupAboveNode node
            null

## LaTeX-like shortcuts for groups

Now we install code that watches for certain text sequences that should be
interpreted as the insertion of groups.

This relies on the KeyUp event, which may only fire once for a few quick
successive keystrokes.  Thus someone typing very quickly may not have these
shortcuts work correctly for them, but I do not yet have a workaround for
this behavior.

        editor.on 'KeyUp', ( event ) ->
            movements = [ 33..40 ] # arrows, pgup/pgdn/home/end
            modifiers = [ 16, 17, 18, 91 ] # alt, shift, ctrl, meta
            if event.keyCode in movements or event.keyCode in modifiers
                return
            range = editor.selection.getRng()
            if range.startContainer is range.endContainer and \
               range.startContainer instanceof editor.getWin().Text
                allText = range.startContainer.textContent
                lastCharacter = allText[range.startOffset-1]
                if lastCharacter isnt ' ' and lastCharacter isnt '\\' and \
                   lastCharacter isnt String.fromCharCode( 160 )
                    return
                allBefore = allText.substr 0, range.startOffset - 1
                allAfter = allText.substring range.startOffset - 1
                for typeName, typeData of editor.Groups.groupTypes
                    if shortcut = typeData.LaTeXshortcut
                        if allBefore[-shortcut.length..] is shortcut
                            newCursorPos = range.startOffset -
                                shortcut.length - 1
                            if lastCharacter isnt '\\'
                                allAfter = allAfter.substr 1
                            allBefore = allBefore[...-shortcut.length]
                            range.startContainer.textContent =
                                allBefore + allAfter
                            range.setStart range.startContainer,
                                newCursorPos
                            if lastCharacter is '\\'
                                range.setEnd range.startContainer,
                                    newCursorPos + 1
                            else
                                range.setEnd range.startContainer,
                                    newCursorPos
                            editor.selection.setRng range
                            editor.Groups.groupCurrentSelection typeName
                            break



# Load/Save Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage [jsfs](https://github.com/nathancarter/jsfs) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and jsfs have been loaded into the global namespace, so that it can
access both.

# `LoadSave` class

We begin by defining a class that will contain all the information needed
regarding loading and saving a document.  An instance of this class will be
stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

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
                shortcut : 'ctrl+N'
                tooltip : 'New file'
                onclick : => @tryToClear()
            control 'savefile',
                text : 'Save'
                icon : 'save'
                context : 'file'
                shortcut : 'ctrl+S'
                tooltip : 'Save file'
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
                tooltip : 'Open file...'
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

        recomputePageTitle: =>
            document.title = "#{if @appName then @appName+': ' else ''}
                              #{@filename or '(untitled)'}
                              #{if @documentDirty then '*' else ''}"
        setDocumentDirty: ( setting = yes ) =>
            @documentDirty = setting
            @recomputePageTitle()
        setFilename: ( newname = null ) =>
            @filename = newname
            @recomputePageTitle()
        setFilepath: ( newpath = null ) => @filepath = newpath
        setAppName: ( newname = null ) =>
            mustAlsoUpdateFileSystem = @appName is @fileSystem
            @appName = newname
            if mustAlsoUpdateFileSystem then @fileSystem = @appName
            @recomputePageTitle()
        setFileSystem: ( newname = @appName ) => @fileSystem = newname

## New documents

To clear the contents of the document, use this method in its `LoadSave`
member.  It handles notifying this instance that the document is then clean.
It does *not* check to see if the document needs to be saved first; it just
outright clears the editor.  It also clears the filename, so that if you
create a new document and then save, it does not save over your last
document.

        clear: =>
            @editor.setContent ''
            @setDocumentDirty no
            @setFilename null
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

To save the current document under the filename in the `@filename` member,
call the following function.  It returns a boolean indicating success or
failure.  If there is no filename in the `@filename` member, failure is
returned and no action taken.  If the save succeeds, mark the document
clean.

        save: =>
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

        tryToSave: ( callback, filename = @filename ) =>

If there is a filename for the current document already in this object's
`@filename` member, then a save is done directly to that filename.  If there
is no filename, then a save dialog is shown.

            if filename
                @setFilename filename
                result = @save() # save happens even if no callback
                @editor.focus()
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

        load: ( filepath, filename ) =>
            if filename is null then return
            if filepath is null then filepath = '.'
            tmp = new FileSystem @fileSystem
            tmp.cd filepath
            [ content, metadata ] = tmp.read filename
            @editor.setContent content
            @editor.focus()
            @setFilepath filepath
            @setFilename filename
            @setDocumentDirty no
            @loadMetaData? metadata ? { }

The following function pops up a dialog to the user, allowing them to choose
a filename to open.  If they choose a file, it (with the current directory)
is passed to the given callback function.  If they do not choose a file, but
cancel the dialog instead, then null is passed to that callback to indicate
the cancellation. It makes the most sense to leave the callback function the
default, `@load`.

        tryToOpen: ( callback = ( p, f ) => @load p, f ) =>

First we create a routine for updating the dialog we're about to show with
an enabled/disabled Save button, based on whether there is a file selected.

            refreshDialog = =>
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

By default, the function called to open the document is `@tryToOpen`, but if
the caller provides a different function, it can be used instead.  For
instance, if this function is called before showing the open dialog for an
online file-sharing service, that function could be used as the callback.

        handleOpen: ( callback = => @tryToOpen() ) =>

First, if the document does not need to be saved, just do a regular "open."

            if not @documentDirty then return callback()

Now, we know that the document needs to be saved.  So prompt the user with a
dialog box asking what they wish to do.

            @editor.windowManager.open {
                title : 'Save first?'
                buttons : [
                    text : 'Save'
                    onclick : =>
                        @editor.windowManager.close()
                        @tryToSave ( success ) => callback() if success
                ,
                    text : 'Discard'
                    onclick : =>
                        @editor.windowManager.close()
                        callback()
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

        manageFiles: =>
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

## Changing UI handlers

This plugin is in charge of presenting the UI for loading and saving
documents, and providing default handlers for that UI that use the browser's
Local Storage.  But there may be other ways to load and save files, such as
upload/download, integration with an online storage provider (Dropbox,
Google Drive, etc.).  For that reason, we provide the following functions.

The first allows you to install your own handler in place of the built-in
`tryToOpen` handler.  It accepts no arguments, and should present the user
with a UI for choosing a file to open, from whatever source.  If called with
no arguments, this function installs the original handler again.  (For the
implementation of `replaceInternalHandler`, see further below.)

        installOpenHandler: ( handler ) ->
            @replaceInternalHandler 'tryToOpen', handler

The second allows you to install your own handler in place of the built-in
`tryToSave` handler.  It accepts two arguments, a path and filename, which
may be null/undefined/empty strings if "Save as..." was invoked.  It should
either save to the file specified (if one was specified), or present the
user with a UI for choosing where to save (if none was specified) before
obeying the request to save.  If called with no arguments, this function
installs the original handler again.

        installSaveHandler: ( handler ) ->
            @replaceInternalHandler 'tryToSave', handler

The third allows you to install your own handler in place of the built-in
`manageFiles` handler.  It accepts no arguments, and should show the user a
UI for browsing the files in the data store in question, if possible.  If
not, respond to the user's request in some way (e.g., a dialog stating that
it is not possible, and why.)

        installManageFilesHandler: ( handler ) ->
            @replaceInternalHandler 'manageFiles', handler

The following utility function was used to implement the three functions
above.

        replaceInternalHandler: ( internalName, newHandler ) ->
            if newHandler?
                ( @handlerBackups ?= { } )[internalName] ?= @[internalName]
                @[internalName] = newHandler
            else if @handlerBackups[internalName]?
                @[internalName] = @handlerBackups[internalName]

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



# MediaWiki Integration

[MediaWiki](https://www.mediawiki.org/wiki/MediaWiki) is the software that
powers [Wikipedia](wikipedia.org).  We plan to integrate webLurch with a
MediaWiki instance by adding features that let the software load pages from
the wiki into webLurch for editing, and easily post changes back to the
wiki as well.  This plugin implements that two-way communication.

This first version is a start, and does not yet implement full
functionality.

## Global variable

We store the editor into which we're installed in this global variable, so
that we can access it easily later.  We initialize it to null here.

    editor = null

## Setup

Before you do anything else with this plugin, you must specify the URLs for
the wiki's main page (usually index.php) and API page (usually api.php).
Do so with the following functions.

    setIndexPage = ( URL ) -> editor.indexURL = URL
    getIndexPage = -> editor.indexURL
    setAPIPage = ( URL ) -> editor.APIURL = URL
    getAPIPage = -> editor.APIURL

## Embedding metadata

Here are two functions for embedding metadata into/extracting metadata from
the HTML content of a document.  These are useful before export to/after
import from the wiki.

    window.embedMetadata = embedMetadata =
    ( documentHTML, metadataObject = { } ) ->
        encoding = encodeURIComponent JSON.stringify metadataObject
        "<span id='metadata' style='display: none;'
         >#{encoding}</span>#{documentHTML}"
    window.extractMetadata = extractMetadata = ( html ) ->
        re = /^<span[^>]+id=.metadata.[^>]*>([^<]*)<\/span>/
        if match = re.exec html
            metadata : JSON.parse decodeURIComponent match[1]
            document : html[match[0].length..]
        else
            metadata : null
            document : html

## Extracting wiki pages

The following (necessarily asynchronous) function accesses the wiki, fetches
the content for the page with the given name, and sends it to the given
callback.  The callback takes two parameters, the content and an error.
Only one will be non-null, depending on the success or failure of the
process.

This internal function therefore does the grunt work.  It can fetch any data
about a wiki page using the `rvprop` parameter of [the MediaWiki Revisions
API](https://www.mediawiki.org/wiki/API:Revisions).  Two convenience
functions for common use cases follow.

    getPageData = ( pageName, rvprop, callback ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null,
                    'Invalid response format.\nShould be JSON:\n' + json
                return
            try
                content = object.query.pages[0].revisions[0][rvprop]
            catch e
                callback null, 'No such page on wiki.\nRaw reply:\n' + json
                return
            callback content, null
        xhr.open 'GET',
            editor.MediaWiki.getAPIPage() + '?action=query&titles=' + \
            encodeURIComponent( pageName ) + \
            '&prop=revisions' + \
            '&rvprop=' + rvprop + '&rvparse' + \
            '&format=json&formatversion=2'
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

Inserting the response data from this function into the editor happens in
the function after this one.

    getPageContent = ( pageName, callback ) ->
        getPageData pageName, 'content', callback

This function is very similar to `getPageContent`, but gets the last
modified date of the page instead of its content.

    getPageTimestamp = ( pageName, callback ) ->
        getPageData pageName, 'timestamp', callback

The following function wraps `getPageContent` in a simple UI, which either
inserts the fetched content into the editor on success, or pops up an error
information dialog on failure.  An optional callback will be called with
true or false, indicating success or failure.

    importPage = ( pageName, callback ) ->
        editor.MediaWiki.getPageContent pageName, ( content, error ) ->
            if error
                editor.Dialogs.alert
                    title : 'Wiki Error'
                    message : "<p>Error loading content from wiki:</p>
                        <p>#{error.split( '\n' )[0]}</p>"
                console.log error
                callback? false # failure
            { metadata, document } = extractMetadata content
            if not metadata?
                editor.Dialogs.alert
                    title : 'Not a Lurch document'
                    message : '<p><b>The wiki page that you attempted to
                        import is not a Lurch document.</b></p>
                        <p>Although it is possible to import any wiki page
                        into Lurch, it does not work well to edit and
                        re-post such pages to the wiki.</p>
                        <p>To edit a non-Lurch wiki page, visit the page on
                        the wiki and edit it there.</p>'
                callback? false # failure
            editor.setContent document
            callback? document, metadata # success

A variant of the previous function silently attempts to fetch just the
metadata from a document stored in the wiki.  It calls the callback with
null on any failure, and the metadata as JSON on success.

    getPageMetadata = ( pageName, callback ) ->
        editor.MediaWiki.getPageContent pageName, ( content, error ) ->
            callback? if error then null else \
                extractMetadata( content ).metadata

The following function accesses the wiki, logs in using the given username
and password, and sends the results to the given callback.  The "token"
parameter is for recursive calls only, and should not be provided by
clients.  The callback accepts result and error parameters.  The result will
either be true, in which case login succeeded, or null, in which case the
error parameter will contain the error message as a string.

    login = ( username, password, callback, token ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null, 'Invalid JSON response: ' + json
                return
            if object?.login?.result is 'Success'
                callback true, null
            else if object?.login?.result is 'NeedToken'
                editor.MediaWiki.login username, password, callback,
                    object.login.token
            else
                callback null, 'Login error of type ' + \
                    object?.login?.result
        URL = editor.MediaWiki.getAPIPage() + '?action=login' + \
            '&lgname=' + encodeURIComponent( username ) + \
            '&lgpassword=' + encodeURIComponent( password ) + \
            '&format=json&formatversion=2'
        if token then URL += '&lgtoken=' + token
        xhr.open 'POST', URL
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

The following function accesses the wiki, attempts to overwrite the page
with the given name, using the given content (in wikitext form), and then
calls the given callback with the results.  That callback should take two
parameters, result and error.  If result is `'Success'` then error will be
null, and the edit succeeded.  If result is null, then the error will be a
string explaining the problem.

Note that if the posting you attempt to do with the following function would
need a certain user's access rights to complete it, you should call the
`login()` function, above, first, to establish that access.  Call this one
from its callback (or any time thereafter).

    exportPage = ( pageName, content, callback ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null, 'Invalid JSON response: ' + json
                return
            if not object?.query?.tokens?.csrftoken
                callback null, 'No token provided: ' + json
                return
            xhr2 = new XMLHttpRequest()
            xhr2.addEventListener 'load', ->
                json = @responseText
                try
                    object = JSON.parse json
                catch e
                    callback null, 'Invalid JSON response: ' + json
                    return
                # callback JSON.stringify object, null, 4
                if object?.edit?.result isnt 'Success'
                    callback null, 'Edit failed: ' + json
                    return
                callback 'Success', null
            content = formatContentForWiki content
            xhr2.open 'POST',
                editor.MediaWiki.getAPIPage() + '?action=edit' + \
                '&title=' + encodeURIComponent( pageName ) + \
                '&text=' + encodeURIComponent( content ) + \
                '&summary=' + encodeURIComponent( 'posted from Lurch' ) + \
                '&contentformat=' + encodeURIComponent( 'text/x-wiki' ) + \
                '&contentmodel=' + encodeURIComponent( 'wikitext' ) + \
                '&format=json&formatversion=2', true
            token = 'token=' + \
                encodeURIComponent object.query.tokens.csrftoken
            xhr2.setRequestHeader 'Content-type',
                'application/x-www-form-urlencoded'
            xhr2.setRequestHeader 'Api-User-Agent', 'webLurch application'
            xhr2.send token
        xhr.open 'GET',
            editor.MediaWiki.getAPIPage() + '?action=query&meta=tokens' + \
            '&format=json&formatversion=2'
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

The previous function makes use of the following one.  This depends upon the
[HTMLTags](https://www.mediawiki.org/wiki/Extension:HTML_Tags) extension to
MediaWiki, which permits arbitrary HTML, as long as it is encoded using tags
of a certain form, and the MediaWiki configuration permits the tags.  See
the documentation for the extension for details.

    formatContentForWiki = ( editorHTML ) ->
        result = ''
        depth = 0
        openRE = /^<([^ >]+)\s*([^>]+)?>/i
        closeRE = /^<\/([^ >]+)\s*>/i
        charRE = /^&([a-z0-9]+|#[0-9]+);/i
        toReplace = [ 'img', 'span', 'var', 'sup' ]
        decoder = document.createElement 'div'
        while editorHTML.length > 0
            if match = closeRE.exec editorHTML
                tagName = match[1].toLowerCase()
                if tagName in toReplace
                    depth--
                    result += "</htmltag#{depth}>"
                else
                    result += match[0]
                editorHTML = editorHTML[match[0].length..]
            else if match = openRE.exec editorHTML
                tagName = match[1].toLowerCase()
                if tagName in toReplace
                    result += "<htmltag#{depth}
                        tagname='#{tagName}' #{match[2]}>"
                    if not /\/\s*$/.test match[2] then depth++
                else
                    result += match[0]
                editorHTML = editorHTML[match[0].length..]
            else if match = charRE.exec editorHTML
                decoder.innerHTML = match[0]
                result += decoder.textContent
                editorHTML = editorHTML[match[0].length..]
            else
                result += editorHTML[0]
                editorHTML = editorHTML[1..]
        result

# Installing the plugin

The plugin, when initialized on an editor, installs all the functions above
into the editor, in a namespace called `MediaWiki`.

    tinymce.PluginManager.add 'mediawiki', ( ed, url ) ->
        ( editor = ed ).MediaWiki =
            setIndexPage : setIndexPage
            getIndexPage : getIndexPage
            setAPIPage : setAPIPage
            getAPIPage : getAPIPage
            login : login
            getPageContent : getPageContent
            getPageTimestamp : getPageTimestamp
            importPage : importPage
            exportPage : exportPage
            embedMetadata : embedMetadata
            extractMetadata : extractMetadata
            getPageMetadata : getPageMetadata



# Overlay Plugin for [TinyMCE](http://www.tinymce.com)

This plugin creates a canvas element that sits directly on top of the
editor.  It is transparent, and thus invisible, unless items are drawn on
it; hence it functions as an overlay.  It also passes all mouse and keyboard
events through to the elements beneath it, so it does not interefere with
the functionality of the rest of the page in that respect.

# `Overlay` class

We begin by defining a class that will contain all the information needed
about the overlay element and how to use it.  An instance of this class will
be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Overlay

We construct new instances of the Overlay class as follows, and these are
inserted as members of the corresponding editor by means of the code [below,
under "Installing the Plugin."](#installing-the-plugin)

        constructor: ( @editor ) ->

The first task of the constructor is to create and style the canvas element,
inserting it at the appropriate place in the DOM.  The following code does
so.  Note the use of `rgba(0,0,0,0)` for transparency, the `pointer-events`
attribute for ignoring mouse clicks, and the fact that the canvas is a child
of the same container as the editor itself.

            @editor.on 'init', =>
                @container = @editor.getContentAreaContainer()
                @canvas = document.createElement 'canvas'
                ( $ @container ).after @canvas
                @canvas.style.position = 'absolute'
                @canvas.style['background-color'] = 'rgba(0,0,0,0)'
                @canvas.style['pointer-events'] = 'none'
                @canvas.style['z-index'] = '10'

We then allow any client to register drawing routines with this plugin, and
all registered routines will be called (in the order in which they were
registered) every time the canvas needs to be redrawn.  The following line
initializes the list of drawing handlers to empty.

            @drawHandlers = []
            @editor.on 'NodeChange', @redrawContents
            ( $ window ).resize @redrawContents

This function installs an event handler that, each time something in the
document changes, repositions the canvas, clears it, and runs all drawing
handlers.

        redrawContents: ( event ) =>
            @positionCanvas()
            if not context = @canvas?.getContext '2d' then return
            @clearCanvas context
            context.translate 0, ( $ @container ).position().top
            for doDrawing in @drawHandlers
                try
                    doDrawing @canvas, context
                catch e
                    console.log "Error in overlay draw function: #{e.stack}"

The following function permits the installation of new drawing handlers.
Each will receive two parameters (as shown in the code immediately above),
the first being the canvas on which to draw, and the second being the
drawing context.

        addDrawHandler: ( drawFunction ) -> @drawHandlers.push drawFunction

This function is part of the private API, and is used only by
`positionCanvas`, below.  It fetches the `<iframe>` used by the editor in
which this plugin was installed.

        getEditorFrame: ->
            for frame in window.frames
                if frame.document is @editor.getDoc()
                    return frame
            null

This function repositions the canvas, so that if the window is moved or
resized, then before redrawing takes place, the canvas reacts accordingly.
This is called only by the handler installed in the constructor, above.

        positionCanvas: ->
            con = $ @container
            can = $ @canvas
            if not con.position()? then return
            can.css 'top', 0
            can.css 'left', con.position().left
            can.width con.width()
            can.height con.position().top + con.height()
            @canvas.width = can.width()
            @canvas.height = can.height()

This function clears the canvas before drawing.  It is called only by the
handler installed in the constructor, above.

        clearCanvas: ( context ) ->
            context.clearRect 0, 0, @canvas.width, @canvas.height

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Overlay` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'overlay', ( editor, url ) ->
        editor.Overlay = new Overlay editor

Whenever the user scrolls, redraw the contents of the overlay, since things
probably need to be repositioned.

        editor.on 'init', ( event ) ->
            ( $ editor.getWin() ).scroll -> editor.Overlay.redrawContents()



# Settings Plugin

There are a few situations in which apps wish to specify settings.  One is
the most common type of settings -- those global to the entire app.  Another
is per-document settings, stored in the document's metadata.  This plugin
therefore provides a way to create categories of settings (e.g., a global
app category, and a per-document category) and provide ways for getting,
setting, and editing each type.  It provides TinyMCE dialog boxes to make
this easier for the client.

We store all data about the plugin in the following object, which we will
install into the editor into which this plugin is installed.

    plugin = { }

## Creating a category

Any app that uses this module will want to create at least one category of
settings (e.g., the global app category).  To do so requires just one
function call, the following.

    plugin.addCategory = ( name ) ->
        plugin[name] =
            get : ( key ) -> window.localStorage.getItem key
            set : ( key, value ) -> window.localStorage.setItem key, value
            setup : ( div ) -> null
            teardown : ( div ) -> null
            showUI : -> plugin.showUI name

Of course, the client may not want to use these default functions.  The
`get` and `set` implementations are perfectly fine for global settings, but
the `setup` and `teardown` functions (explained below) do nothing at all.
The `showUI` function is also explained below.

## How settings are stored

Once the client has created a category (say,
`editor.Settings.addCategory 'global'`), he or she can then store values in
that category using the category name, as in
`editor.Settings.global.get 'key'` or
`editor.Settings.global.set 'key', 'value'`.

The default implementations for these, given above, use the browser's
`localStorage` object.  But the client can define new `get` and `set`
methods by simply overwriting the existing ones, as in
`editor.Settings.global.get = ( key ) -> 'put new implementation here'`.

## How settings are edited

The client may wish to present to the user some kind of UI related to a
category of settings, so that the user can interactively see and edit those
settings.  The following (non-customizable) function pops up a dialog box
and sets it up so that the user can see and edit the settings for a given
category.

The heart of this function is its reliance on the `setup` and `teardown`
functions defined for the category, so that while this function is not
directly customizable, it is indirectly very customizable.  See the code
below.

    plugin.showUI = ( category ) ->

All the controls for editing the settings will be in a certain DIV in the
DOM, inside the dialog box that's about to pop up.  It will be created
below, and stored in the following variable.

        div = null

Create the buttons for the bottom of the dialog box.  Cancel just closes the
dialog, but Save saves the settings if the user chooses to do so.  It will
run the `teardown` function on the DIV with all the settings editing
controls in it.  The `teardown` function is responsible for inspecting the
state of all those controls and storing the corresponding values in the
settings, via calls to `set`.

        buttons = [
            type : 'button'
            text : 'Cancel'
            onclick : ( event ) ->
                tinymce.activeEditor.windowManager.close()
        ,
            type : 'button'
            text : 'Save'
            subtype : 'primary'
            onclick : ( event ) ->
                plugin[category].teardown div
                tinymce.activeEditor.windowManager.close()
        ]

Create a title and show the dialog box with a blank interior.

        categoryTitle = category[0].toUpperCase() + \
            category[1..].toLowerCase() + ' Settings'
        tinymce.activeEditor.windowManager.open
            title : categoryTitle
            url : 'about:blank'
            width : 500
            height : 400
            buttons : buttons

Find the DIV in the DOM that represents the dialog box's interior.

        wins = tinymce.activeEditor.windowManager.windows
        div = wins[wins.length-1].getEl() \
            .getElementsByClassName( 'mce-container-body' )[0]

Clear out that DIV, then allow the `setup` function to fill it with whatever
controls (in whatever state) are appropriate for representing the current
settings in this category.  This will happen instants after the dialog
becomes visible, so the user will not perceive the reversal of the usual
order (of setting up a UI and then showing it).

        div.innerHTML = ''
        plugin[category].setup div

## Convenience functions for a UI

A common UI for settings dialogs is a two-column view, in which the left
column contains labels for corresponding controls in the right column.  The
functions in this section provide a convenient way to create such a UI.
Each function herein creates a single row of two columns, with the label on
the left, and the control on the right (with a few exceptions).

    plugin.UI = { }

Each function below takes an optional `id` argument.  If it is omitted, the
generated HTML code will contain no `id` attributes.  If it is present, the
generated HTML code will contain an `id` attribute, and its value will be
the value of that parameter.

For creating informational lines and category headings:

    plugin.UI.info = ( name, id ) -> plugin.UI.tr \
        "<td style='width: 100%; text-align: center; white-space: normal;'
         >#{name}</td>", id
    plugin.UI.heading = ( name, id ) ->
        plugin.UI.info "<hr style='border: 1px solid black;'>
            <span style='font-size: 20px;'>#{name}</span>
            <hr style='border: 1px solid black;'>", id

For creating read-only rows:

    plugin.UI.readOnly = ( label, data, id ) ->
        plugin.UI.tpair label, data, id

For creating a text input (`id` not optional in this case):

    plugin.UI.text = ( label, id, initial ) ->
        plugin.UI.tpair label,
            "<input type='text' id='#{id}' value='#{initial}'
            style='border-width: 2px; border-style: inset;'/>"

For creating a password input (`id` not optional in this case):

    plugin.UI.password = ( label, id, initial ) ->
        plugin.UI.tpair label,
            "<input type='password' id='#{id}' value='#{initial}'
            style='border-width: 2px; border-style: inset;'/>"

For creating a check box input (`id` not optional in this case):

    plugin.UI.checkbox = ( text, checked = no, id, optionalDescription ) ->

        checked = if checked then ' checked' else ''
        result = plugin.UI.generalPair \
            "<input type='checkbox' id='#{id}' #{checked}/>",
            "<b>#{text}</b>", null, 10
        if optionalDescription
            result += plugin.UI.generalPair '',
                "<p>#{optionalDescription}</p>", null, 10
        result

For creating a radio box input (`id` not optional in this case):

    plugin.UI.radioButton = ( text, groupName, checked = no, id,
                              optionalDescription ) ->
        checked = if checked then ' checked' else ''
        result = plugin.UI.generalPair \
            "<input type='radio' name='#{groupName}' id='#{id}'
             #{checked}/>", "<b>#{text}</b>", null, 10
        if optionalDescription
            result += plugin.UI.generalPair '',
                "<p>#{optionalDescription}</p>", null, 10
        result

For creating a button:

    plugin.UI.button = ( text, id ) ->
        "<input type='button' #{if id? then " id='#{id}'" else ''}
          value='#{text}' style='border: 1px solid #999999; background:
          #dddddd; padding: 2px; margin: 2px;'
          onmouseover='this.style.background=\"#eeeeee\";'
          onmouseout='this.style.background=\"#dddddd\";'/>"

And some utility functions used by functions above.

    plugin.UI.tr = ( content, id ) ->
        "<table border=0 cellpadding=0 cellspacing=10
                style='width: 100%;' #{if id? then " id='#{id}'" else ''}>
            <tr style='width: 100%; vertical-align: middle;'>" + \
        content + '</tr></table>'
    plugin.UI.tpair = ( left, right, id ) ->
        plugin.UI.tr "<td style='width: 50%; text-align: right;
                        vertical-align: middle;'><b>#{left}:</b></td>
                      <td style='width: 50%; text-align: left;
                        vertical-align: middle;'>#{right}</td>", id
    plugin.UI.generalPair = ( left, right, id, percent, align = 'left' ) ->
        plugin.UI.tr "<td style='width: #{percent}%; text-align: #{align};
                        vertical-align: middle;'>#{left}</td>
                      <td style='width: #{100-percent}%; text-align: left;
                        vertical-align: middle;'>#{right}</td>", id

# Installing the plugin

The plugin, when initialized on an editor, installs all the functions above
into the editor, in a namespace called `Settings`.

    tinymce.PluginManager.add 'settings', ( editor, url ) ->
        editor.Settings = plugin



# App Setup Script

## Specify app settings

First, applications should specify their app's name using a call like the
following.  In this generic setup script, we fill in a placeholder value.
This will be used when creating the title for this page (e.g., to show up in
the tab in Chrome).

    setAppName 'Untitled'

Second, we initialize a very simple default configuration for the Groups
plugin.  It can be overridden by having any script assign to the global
variable `groupTypes`, overwriting this data.  Such a change must be done
before the page is fully loaded, when the `tinymce.init` call, below, takes
place.  For examples of how to do this, see
[the simple example app](simple-example.solo.litcoffee),
[the complex example app](complex-example.solo.litcoffee), and
[the mathematical example app](math-example.solo.litcoffee).

    window.groupTypes ?= [
        name : 'example'
        text : 'Example group'
        imageHTML : '['
        openImageHTML : ']'
        closeImageHTML : '[]'
        tooltip : 'Wrap text in a group'
        color : '#666666'
    ]

Clients who define their own group types may also define their own toolbar
buttons and menu items to go with them.  But these lists default to empty.

    window.groupToolbarButtons ?= { }
    window.groupMenuItems ?= { }

Similarly, a client can provide a list of plugins to load when initializing
TinyMCE, and they will be added to the list loaded by default.

    window.pluginsToLoad ?= [ ]

We also provide a variable in which apps can specify an icon to appear on
the menu bar, at the very left.  It defaults to an empty object, but can be
overridden, in the same way as `window.groupTypes`, above.  If you override
it, specify its file as the `src` attribute, and its `width`, `height`, and
`padding` attributes as CSS strings (e.g., `'2px'`).

    window.menuBarIcon ?= { }

We also provide a set of styles to be added to the editor by default.
Clients can also override this object if they prefer different styles.

    window.defaultEditorStyles ?=
        fontSize : '16px'
        fontFamily : 'Verdana, Arial, Helvetica, sans-serif'

We can also provide the text for the Help/About menu item by overriding the
following in a separate configuration file.  (See the same examples apps for
specific code.)

    window.helpAboutText ?=
        'webLurch\n\nalpha\n\nnot yet intended for non-developer use'

## Add an editor to the app

This file initializes a [TinyMCE](http://www.tinymce.com/) editor inside the
[main app page](index.html).  It is designed to be used inside that page,
where [jQuery](http://jquery.com/) has already been loaded, thus defining
the `$` symbol used below.  Its use in this context causes the function to
be run only after the DOM has been fully loaded.

    $ ->

Create a `<textarea>` to be used as the editor.

        editor = document.createElement 'textarea'
        editor.setAttribute 'id', 'editor'
        document.body.appendChild editor

If the query string is telling us to switch the app into test-recording
mode, then do so.  This uses the main function defined in
[testrecorder.litcoffee](./testrecorder.litcoffee), which does nothing
unless the query string contains the code that invokes test-recording mode.

        maybeSetupTestRecorder()

We need the list of group types names so that we can include them in the
toolbar and menu initializations below.

        groupTypeNames = ( type.name for type in groupTypes )

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
            paste_data_images : true

Not all of the following plugins are working yet, but most are.  A plugin
that begins with a hyphen is a local plugin written as part of this project.

            plugins :
                'advlist table charmap colorpicker image link importcss
                paste print save searchreplace textcolor fullscreen
                -loadsave -overlay -groups -equationeditor -dependencies
                -dialogs ' \
                + ( "-#{p}" for p in window.pluginsToLoad ).join ' '

The groups plugin requires that we add the following, to prevent resizing of
group boundary images.

            object_resizing : ':not(img.grouper)'

We then install two toolbars, with separators indicated by pipes (`|`).

            toolbar : [
                'newfile openfile savefile managefiles | print
                    | undo redo | cut copy paste
                    | alignleft aligncenter alignright alignjustify
                    | bullist numlist outdent indent blockquote | table'
                'fontselect styleselect | bold italic underline
                    textcolor subscript superscript removeformat
                    | link unlink | charmap image
                    | spellchecker searchreplace | equationeditor | ' + \
                    groupTypeNames.join( ' ' ) + ' connect' + \
                    moreToolbarItems()
            ]

We then customize the menus' contents as follows.

            menu :
                file :
                    title : 'File'
                    items : 'newfile openfile | savefile saveas
                           | managefiles | print' + moreMenuItems 'file'
                edit :
                    title : 'Edit'
                    items : 'undo redo
                           | cut copy paste pastetext
                           | selectall' + moreMenuItems 'edit'
                insert :
                    title : 'Insert'
                    items : 'link media
                           | template hr
                           | me' + moreMenuItems 'insert'
                view :
                    title : 'View'
                    items : 'visualaid hideshowgroups' \
                          + moreMenuItems 'view'
                format :
                    title : 'Format'
                    items : 'bold italic underline
                             strikethrough superscript subscript
                           | formats | removeformat' \
                           + moreMenuItems 'format'
                table :
                    title : 'Table'
                    items : 'inserttable tableprops deletetable
                           | cell row column' + moreMenuItems 'table'
                help :
                    title : 'Help'
                    items : 'about website' + moreMenuItems 'help'

Then we customize the context menu.

            contextmenu : 'link image inserttable
                | cell row column deletetable' + moreMenuItems 'contextmenu'

And finally, we include in the editor's initialization the data needed by
the Groups plugin, so that it can find it when that plugin is initialized.

            groupTypes : groupTypes

Each editor created will have the following `setup` function called on it.
In our case, there will be only one, but this is how TinyMCE installs setup
functions, regardless.

            setup : ( editor ) ->

Add a Help menu.

                editor.addMenuItem 'about',
                    text : 'About...'
                    context : 'help'
                    onclick : -> editor.Dialogs.alert
                        title : 'webLurch'
                        message : helpAboutText ? ''
                editor.addMenuItem 'website',
                    text : 'Lurch website'
                    context : 'help'
                    onclick : -> window.open 'http://www.lurchmath.org',
                        '_blank'

Add actions and toolbar buttons for all other menu items the client may have
defined.

                for own name, data of window.groupMenuItems
                    editor.addMenuItem name, data
                for own name, data of window.groupToolbarButtons
                    editor.addButton name, data

Install our DOM utilities in the TinyMCE's iframe's window instance.
Increase the default font size and maximize the editor to fill the page.
This requires not only invoking the "mceFullScreen" command, but also then
setting the height properties of many pieces of the DOM hierarchy (in a way
that seems like it ought to be handled for us by the fullScreen plugin).

                editor.on 'init', ->
                    installDOMUtilitiesIn editor.getWin()
                    for own key, value of window.defaultEditorStyles
                        editor.getBody().style[key] = value
                    setTimeout ->
                        editor.execCommand 'mceFullScreen'
                        walk = editor.iframeElement
                        while walk and walk isnt editor.container
                            if walk is editor.iframeElement.parentNode
                                walk.style.height = 'auto'
                            else
                                walk.style.height = '100%'
                            walk = walk.parentNode
                        for h in editor.getDoc().getElementsByTagName 'html'
                            h.style.height = 'auto'
                    , 0

The third-party plugin for math equations requires the following stylesheet.

                    editor.dom.loadCSS './eqed/mathquill.css'

Add an icon to the left of the File menu, if one has been specified.

                    if window.menuBarIcon?.src?
                        filemenu = ( editor.getContainer()
                            .getElementsByClassName 'mce-menubtn' )[0]
                        icon = document.createElement 'img'
                        icon.setAttribute 'src', window.menuBarIcon.src
                        icon.style.width = window.menuBarIcon.width
                        icon.style.height = window.menuBarIcon.height
                        icon.style.padding = window.menuBarIcon.padding
                        filemenu.insertBefore icon, filemenu.childNodes[0]

Workaround for [this bug](http://www.tinymce.com/develop/bugtracker_view.php?id=3162):

                    editor.getBody().addEventListener 'focus', ->
                        if editor.windowManager.getWindows().length isnt 0
                            editor.windowManager.close()

Override the default handling of the tab key so that it does not leave the
editor, but instead inserts a large space ("em space").  In HTML, if we were
to insert a tab, it would be treated as any other whitespace, and look just
like a single, small space.  So we use this instead, the largest space in
HTML.

                    editor.on 'KeyDown', ( event ) ->
                        if event.keyCode is 9 # tab key
                            event.preventDefault()
                            editor.insertContent '&emsp;'

And if the app installed a global handler for editor post-setup, run that
function now.

                    window.afterEditorReady? editor

The following utility functions are used to help build lists of menu and
toolbar items in the setup data above.

    moreMenuItems = ( menuName ) ->
        names = if window.groupMenuItems.hasOwnProperty "#{menuName}_order"
            window.groupMenuItems["#{menuName}_order"]
        else
            ( k for k in Object.keys window.groupMenuItems \
                when window.groupMenuItems[k].context is menuName ).join ' '
        if names.length and names[...2] isnt '| ' then "| #{names}" else ''
    moreToolbarItems = ->
        names = ( window.groupToolbarButtons.order ? \
            Object.keys window.groupToolbarButtons ).join ' '
        if window.useGroupConnectionsUI then names = "connect #{names}"
        if names.length and names[...2] isnt '| ' then "| #{names}" else ''

## Support demo apps

We want to allow the demo applications in the webLurch source code
repository to place links on their Help menu to their documented source
code.  This will help people who want to learn Lurch coding find
resources to do so more easily.  We thus provide this function they can use
to do so as a one-line call.

Not only does it set up the link they request, but it also sets up a link to
the developer tutorial in general, and it flashes the Help menu briefly to
draw the viewer's attention there.

    window.addHelpMenuSourceCodeLink = ( path ) ->
        window.groupMenuItems ?= { }
        window.groupMenuItems.sourcecode =
            text : 'View documented source code'
            context : 'help'
            onclick : ->
                window.location.href = 'http://github.com/' + \
                    'nathancarter/weblurch/blob/master/' + path
        window.groupMenuItems.tutorial =
            text : 'View developer tutorial'
            context : 'help'
            onclick : ->
                window.location.href = 'http://github.com/' + \
                    'nathancarter/weblurch/blob/master/doc/tutorial.md'
        flash = ( count, delay, elts ) ->
            if count-- <= 0 then return
            elts.fadeOut( delay ).fadeIn delay, -> flash count, delay, elts
        setTimeout ->
            flash 3, 500, ( $ '.mce-menubtn' ).filter ( index, element ) ->
                element.textContent.trim() is 'Help'
        , 1000



# Test Recording Loader

webLurch supports a mode in which it can record various keystrokes and
command invocations, and store them in the form of code that can be copied
and pasted into the source code for the app's unit testing suite.  This is
very handy for constructing new test cases without writing a ton of code.
It is also less prone to typographical and other small errors, since the
code is generated for you automatically.

That mode is implemented in two script files:
 * This file pops up a separate browser window that presents the
   test-recording UI.
 * That popup window uses the script
   [testrecorder-solo.litcoffee](testrecorder-solo.litcoffee), which
   implements all that window's UI interactivity.

First, we have a function that switches the app into test-recording mode, if
and only if the query string equals "?test".  Test-recording mode uses a
popup window so that the main app window stays pristine and undisturbed, and
tests are recorded in the normal app environment.

    maybeSetupTestRecorder = ->
        if location.search is '?test'

Launch popup window.

            testwin = open './testrecorder.html', 'recording',
                "status=no, location=no, toolbar=no, menubar=no,
                left=#{window.screenX+($ window).width()},
                top=#{window.screenY}, width=400, height=600"

If the browser blocked it, notify the user.

            if not testwin
                alert 'You have asked to run webLurch in test-recording
                    mode, which requires a popup window.  Your browser has
                    blocked the popup window.  Change its settings or allow
                    this popup to use test-recording mode.'

If the browser did not block it, then it is loaded.  It loads its own
scripts for handling UI events for controls in the popup window.

Now we setup timers that (in 0.1 seconds) will install in the editor
listeners for various events that we want to record.

            installed = [ ]
            do installListeners = ->
                notSupported = ( whatYouDid ) ->
                    alert "You #{whatYouDid}, which the test recorder does
                        not yet support.  The current test has therefore
                        become corrupted, and you should reload this page
                        and start your test again.  You will need to limit
                        yourself to using only supported keys, menu items,
                        and mouse operations."
                try

If a keypress occurs for a key that can be typed (letter, number, space),
tell the test recorder window about it.  For any other type of key, tell the
user that we can't yet record it, so the test is corrupted.

                    if 'keypress' not in installed
                        tinymce.activeEditor.on 'keypress', ( event ) ->
                            letter = String.fromCharCode event.keyCode
                            if /[A-Za-z0-9 ]/.test letter
                                testwin.editorKeyPress event.keyCode,
                                    event.shiftKey, event.ctrlKey, event.altKey
                            else
                                notSupported "pressed the key with code
                                    #{event.keyCode}"
                        installed.push 'keypress'

If a keyup occurs for any key, do one of three things.  First, if it's a
letter, ignore it, because the previous case handles that better.  Second,
if it's shift/ctrl/alt/meta, ignore it.  Finally, if it's one of the special
keys we can handle (arrows, backspace, etc.), notify the test recorder about
it.  For any other type of key, tell the user that we can't yet record it,
so the test is corrupted.

                    if 'keyup' not in installed
                        tinymce.activeEditor.on 'keyup', ( event ) ->
                            letter = String.fromCharCode event.keyCode
                            if /[A-Za-z0-9 ]/.test letter then return
                            ignore = [ 16, 17, 18, 91 ] # shft,ctl,alt,meta
                            if event.keyCode in ignore then return
                            conversion =
                                8 : 'backspace'
                                13 : 'enter'
                                35 : 'end'
                                36 : 'home'
                                37 : 'left'
                                38 : 'up'
                                39 : 'right'
                                40 : 'down'
                                46 : 'delete'
                            if conversion.hasOwnProperty event.keyCode
                                testwin.editorKeyPress \
                                    conversion[event.keyCode],
                                    event.shiftKey, event.ctrlKey, event.altKey
                            else
                                notSupported "pressed the key with code
                                    #{event.keyCode}"
                        installed.push 'keyup'

Tell the test recorder about any mouse clicks in the editor.  If the user
is holding a ctrl, alt, or shift key while clicking, we cannot currently
support that, so we warn the user if they try to record such an action.

                    if 'click' not in installed
                        tinymce.activeEditor.on 'click', ( event ) ->
                            if event.shiftKey
                                notSupported "shift-clicked"
                            else if event.ctrlKey
                                notSupported "ctrl-clicked"
                            else if event.altKey
                                notSupported "alt-clicked"
                            else
                                testwin.editorMouseClick event.clientX,
                                    event.clientY
                        installed.push 'click'

Tell the test recorder about any toolbar buttons that are invoked in the
editor.

                    findAll = ( type ) ->
                        Array::slice.apply \
                            tinymce.activeEditor.theme.panel.find type
                    if 'buttons' not in installed
                        for button in findAll 'button'
                            do ( button ) ->
                                button.on 'click', ->
                                    testwin.buttonClicked \
                                        button.settings.icon
                        installed.push 'buttons'

Disable any drop-down menu, for which I am (as yet) unable to attach event
listeners.

                    object.disabled yes for object in \
                        [ findAll( 'splitbutton' )...,
                          findAll( 'listbox' )...,
                          findAll( 'menubutton' )... ]

Tell the test recording page that the main page has finished loading, and it
can show its contents.

                    testwin.enterReadyState()

If any of the above handler installations fail, the reason is probably that
the editor hasn't been initialized yet.  So just wait 0.1sec and retry.

                catch e
                    setTimeout installListeners, 100
