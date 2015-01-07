
# Groups Plugin for [TinyMCE](http://www.tinymce.com)

This plugin adds the notion of "groups" to a TinyMCE editor.  Groups are
contiguous sections of the document, often nested but not otherwise
overlapping, that can be used for a wide variety of purposes.  This plugin
provides the following functionality for working with groups in a document.
 * defines the `Group` and `Groups` classes
 * provides methods for installing UI elements for creating and interacting
   with groups in the document
 * shows groups visually on screen in a variety of ways

It assumes that TinyMCE has been loaded into the global namespace, so that
it can access it.  It also requires [the overlay
plugin](overlayplugin.litcoffee) to be loaded in the same editor.

# `Groups` class

We begin by defining a class that will encapsulate all the functionality
about groups in the editor.  An instance of this class will be stored as a
member in the TinyMCE editor object.

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

    class Groups

        constructor: ( @editor ) ->
            # nothing yet

## Class variables

We keep a global list of valid group types.

        groupTypes: []

To register a new type of group, simply provide its name, as a text string.
That string should only contain alphabetic characters, a through z, case
sensitive, or underscores.  All other characters are removed.  Adding a name
twice is the same as adding it once; nothing happens the second time.  Empty
names are not allowed, which includes names that become empty when all
illegal characters have been removed.

        @addGroupType: ( name ) ->
            name = ( n for n in name when /[a-zA-Z_]/.test n ).join ''
            if name is '' then return
            Groups::groupTypes.push name if name not in Groups::groupTypes

<font color=red>This class is not yet complete. See [the project
plan](plan.md) for details of what's to come.</font>

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Groups` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'groups', ( editor, url ) ->
        editor.Groups = new Groups editor
