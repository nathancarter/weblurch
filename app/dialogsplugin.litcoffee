
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

## Alert box

This function shows a simple alert box, with a callback when the user
clicks OK.  The message can be text or HTML.

    Dialogs.alert = ( options ) ->
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : window.objectURLForBlob window.makeBlob options.message,
                'text/html;charset=utf-8'
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

## Confirm dialog

This function is just like the alert box, but with two callbacks, one for OK
and one for Cancel, named `okCallback` and `cancelCallback`, respectively.
The user can rename the OK and Cancel buttons by specfying strings in the
options object with the 'OK' and 'Cancel' keys.

    Dialogs.confirm = ( options ) ->
        tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : window.objectURLForBlob window.makeBlob options.message,
                'text/html;charset=utf-8'
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

# Installing the plugin

    tinymce.PluginManager.add 'dialogs', ( editor, url ) ->
        editor.Dialogs = Dialogs
