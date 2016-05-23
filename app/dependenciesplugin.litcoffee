
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

Applications need to give users access to that interface, using methods not
yet documented in this file.  Coming soon.

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
                ( result, error ) ->
                    return unless result?
                    lastModified = new Date result
                    currentVersion = new Date dependency.date
                    return unless lastModified > currentVersion
                    @editor.MediaWiki.getPageMetadata pageName,
                    ( metadata ) ->
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
                if newData = @getFileMetadata( filepath, filename ).exports
                    @[@length++] =
                        address : address
                        data : newData
                        date : new Date
                    callback? newData, null
                    @editor.fire 'dependenciesChanged'
                else
                    callback? null, 'No such file'
            else if address[...7] is 'wiki://'
                pageName = address[7...]
                @editor.MediaWiki.getPageTimestamp pageName,
                ( result, error ) ->
                    if not result?
                        return callback? null,
                            'Could not get wiki page timestamp'
                    @editor.MediaWiki.getPageMetadata pageName,
                    ( metadata ) ->
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

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dependencies` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dependencies', ( editor, url ) ->
        editor.Dependencies = new Dependencies editor
