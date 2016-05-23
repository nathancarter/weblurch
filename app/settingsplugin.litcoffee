
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
         #{if id? then " id='#{id}'" else ''}>#{name}</td>"
    plugin.UI.heading = ( name, id ) ->
        plugin.UI.info "<hr style='border: 1px solid black;'>
            <span style='font-size: 20px;'
            #{if id? then " id='#{id}'" else ''}>#{name}</span>
            <hr style='border: 1px solid black;'>"

For creating read-only rows:

    plugin.UI.readOnly = ( label, data ) -> plugin.UI.tpair label, data

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

For creating a button:

    plugin.UI.button = ( text, id ) ->
        "<input type='button' #{if id? then " id='#{id}'" else ''}
          value='#{text}' style='border: 1px solid #999999; background:
          #dddddd; padding: 2px; margin: 2px;'
          onmouseover='this.style.background=\"#eeeeee\";'
          onmouseout='this.style.background=\"#dddddd\";'/>"

And two utility functions used by all the functions above.

    plugin.UI.tr = ( content ) ->
        '<table border=0 cellpadding=0 cellspacing=10
                style="width: 100%;">
            <tr style="width: 100%; vertical-align: middle;">' + \
        content + '</tr></table>'
    plugin.UI.tpair = ( left, right ) ->
        plugin.UI.tr "<td style='width: 50%; text-align: right;
                        vertical-align: middle;'><b>#{left}:</b></td>
                      <td style='width: 50%; text-align: left;
                        vertical-align: bottom;'>#{right}</td>"

# Installing the plugin

The plugin, when initialized on an editor, installs all the functions above
into the editor, in a namespace called `Settings`.

    tinymce.PluginManager.add 'settings', ( editor, url ) ->
        editor.Settings = plugin
