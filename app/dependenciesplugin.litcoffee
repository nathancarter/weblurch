
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

This class is currently a stub, so we don't do anything on editor
initialization, but we will almost certainly want to do something in this
event later.  So we put this stub here.

            @editor.on 'init', =>
                # nothing

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Dependencies` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'dependencies', ( editor, url ) ->
        editor.Dependencies = new Dependencies editor
