
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
`exports` data in the document's metadata upon each save.

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

We construct new instances of the Dependencies class as follows, and these
are inserted as members of the corresponding editor by means of the code
[below, under "Installing the Plugin."](#installing-the-plugin)

        constructor: ( @editor ) ->
            # no constructor needed yet, beyond storing the editor

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dependencies` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dependencies', ( editor, url ) ->
        editor.Dependencies = new Dependencies editor
