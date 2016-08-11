
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
            add = ( element ) ->
                element.addEventListener 'click', ( event ) ->
                    top.postMessage event.target.getAttribute( 'id' ), '*'
            add element for element in document.getElementsByTagName 'a'
            add element for element in document.getElementsByTagName 'input'
        window.objectURLForBlob window.makeBlob \
            html + "<script>(#{script})()</script>",
            'text/html;charset=utf-8'

The second installs in the top-level window a listener for the events
posted from the interior of the dialog.  It then calls the given event
handler with the ID of the element clicked.  It returns the handler
installed, so that callers can pass it to the following function.

    installClickListener = ( handler ) ->
        innerHandler = ( event ) -> handler event.data
        window.addEventListener 'message', innerHandler, no
        innerHandler

The third uninstalls such event handlers; be sure to call it when your
dialog closes, passing in the same event handler returned by the call to
the previous function.

    uninstallClickListener = ( innerHandler ) ->
        window.removeEventListener 'message', innerHandler

## Alert box

This function shows a simple alert box, with a callback when the user
clicks OK.  The message can be text or HTML.

    Dialogs.alert = ( options ) ->
        if options.onclick
            handler = installClickListener options.onclick
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
                    if options.onclick then uninstallClickListener handler
            ]

## Confirm dialog

This function is just like the alert box, but with two callbacks, one for OK
and one for Cancel, named `okCallback` and `cancelCallback`, respectively.
The user can rename the OK and Cancel buttons by specfying strings in the
options object with the 'OK' and 'Cancel' keys.


    Dialogs.confirm = ( options ) ->
        if options.onclick
            handler = installClickListener options.onclick
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
                    if options.onclick then uninstallClickListener handler
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    tinymce.activeEditor.windowManager.close()
                    options.okCallback? event
                    if options.onclick then uninstallClickListener handler
            ]

# Installing the plugin

    tinymce.PluginManager.add 'dialogs', ( editor, url ) ->
        editor.Dialogs = Dialogs
