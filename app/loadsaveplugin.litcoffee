
# Load/Save Plugin for [TinyMCE](http://www.tinymce.com)

This plugin will leverage [jsfs](https://github.com/nathancarter/jsfs) to
add load and save functionality to a TinyMCE instance.  It assumes that both
TinyMCE and jsfs have been loaded into the global namespace, so that it can
access both.

    tinymce.PluginManager.add 'loadsave', ( editor, url ) ->
        console.log 'Loaded Load/Save Plugin.  Just a stub for now.'
