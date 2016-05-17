
# Dependencies Plugin for [TinyMCE](http://www.tinymce.com)

This plugin adds features for making the current document depend on others.
It requries the definiton of an `exports` function, which computes, for any
given document, what JSON data it wishes to export to any document that uses
it for a dependency.  It then stores such data in the document's metadata
each time the document is saved, so that those that use it as a dependency
can extract the data from there.  It also provides a UI for editing the list
of dependencies of the current document, together with change events for
that list.

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

See the top of this page for an explanation of the `exports` function.  App
developers importing this plugin should override this function with one that
takes a TinyMCE document (the `iframe`'s document element) as input and
yields any valid JSON object as output, the data the document exports.  (It
may return null, meaning no data to export.)

Alternately, it may throw an error, meaning that the document is not in a
state for which its exports data can be computed.  Implementations that do
throw errors may also choose to alert the user with a dialog box, so that
the user knows that the document they're trying do save will not contain
valid "exports" data.

Therefore the default value of this member is a function that always returns
null (meaning that no document exports any data).  Since that is not very
useful, app developers will certainly want to override this default.

            @exports = -> null

Later we may wish to fill in this event handler.  For now, it's a stub.

            @editor.on 'init', =>
                # nothing

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dependencies` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dependencies', ( editor, url ) ->
        editor.Dependencies = new Dependencies editor
