
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
                            value : event.target.value
                            id : event.target.getAttribute 'id'
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
