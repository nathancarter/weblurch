
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
    callback : function ( event ) { console.log( event ); }
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
                        parent.postMessage
                            value : event.currentTarget.value
                            id : event.currentTarget.getAttribute 'id'
                        , '*'
            install 'a', 'click'
            install 'input', 'click'
            install 'input', 'input'
            for element in document.getElementsByTagName 'input'
                if 'file' is element.getAttribute 'type'
                    element.addEventListener 'change', ->
                        reader = new FileReader()
                        reader.onload = ( event ) =>
                            parent.postMessage
                                value : event.target.result
                                id : @getAttribute 'id'
                            , '*'
                        reader.readAsDataURL @files[0]
            document.getElementsByTagName( 'input' )[0]?.focus()
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
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 400
            height : options.height ? 300
            buttons : [
                type : 'button'
                text : 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.callback? event
            ]
        if options.onclick then installClickListener options.onclick

## Confirm dialog

This function is just like the alert box, but with two callbacks, one for OK
and one for Cancel, named `okCallback` and `cancelCallback`, respectively.
The user can rename the OK and Cancel buttons by specfying strings in the
options object with the 'OK' and 'Cancel' keys.


    Dialogs.confirm = ( options ) ->
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 400
            height : options.height ? 300
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Cancel'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.cancelCallback? event
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
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
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 300
            height : options.height ? 200
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Cancel'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.cancelCallback? lastValue
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.okCallback? lastValue
            ]
        installClickListener ( data ) ->
            if data.id is 'promptInput' then lastValue = data.value

## File upload dialog

This function allows the user to choose a file from their local machine to
upload.  They can do so with a "choose" button or by dragging the file into
the dialog.  The dialog then calls its `okCallback` with the contents of the
uploaded file, in the format of a data URL, or calls its `cancelCallback`
with no parameter.

    Dialogs.promptForFile = ( options ) ->
        value = if options.value then " value='#{options.value}'" else ''
        types = if options.types then " accept='#{options.types}'" else ''
        options.message +=
            "<p><input type='file' #{value} id='promptInput'/></p>"
        lastValue = null
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 400
            height : options.height ? 100
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Cancel'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.cancelCallback?()
            ,
                type : 'button'
                text : options.OK ? 'OK'
                subtype : 'primary'
                onclick : ( event ) ->
                    dialog.close()
                    options.okCallback? lastValue
            ]
        installClickListener ( data ) ->
            if data.id is 'promptInput' then lastValue = data.value

## Code editor dialog

    Dialogs.codeEditor = ( options ) ->
        setup = ( language ) ->
            window.codeEditor = CodeMirror.fromTextArea \
                document.getElementById( 'editor' ),
                lineNumbers : yes
                fullScreen : yes
                autofocus : yes
                theme : 'base16-light'
                mode : language
            handler = ( event ) ->
                if event.data is 'getEditorContents'
                    parent.postMessage window.codeEditor.getValue(), '*'
            window.addEventListener 'message', handler, no
        html = "<html><head>
            <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.17.0/codemirror.min.css'>
            <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.17.0/theme/base16-light.min.css'>
            <script src='https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.17.0/codemirror.min.js'></script>
            <script src='https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.17.0/addon/display/fullscreen.min.js'></script>
            <script src='https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.17.0/mode/javascript/javascript.min.js'></script>
            </head>
            <body style='margin: 0px;'>
            <textarea id='editor'>#{options.value ? ''}</textarea>
            <script>
                (#{setup})(\"#{options.language ? 'javascript'}\")
            </script>
            </body></html>"
        whichCallback = null
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? 'Code editor'
            url : window.objectURLForBlob window.makeBlob html,
                'text/html;charset=utf-8'
            width : options.width ? 700
            height : options.height ? 500
            buttons : [
                type : 'button'
                text : options.Cancel ? 'Discard'
                subtype : 'primary'
                onclick : ( event ) ->
                    whichCallback = options.cancelCallback
                    dialog.getContentWindow().postMessage \
                        'getEditorContents', '*'
            ,
                type : 'button'
                text : options.OK ? 'Save'
                subtype : 'primary'
                onclick : ( event ) ->
                    whichCallback = options.okCallback
                    dialog.getContentWindow().postMessage \
                        'getEditorContents', '*'
            ]
        handler = ( event ) ->
            dialog.close()
            whichCallback? event.data
        window.addEventListener 'message', handler, no
        dialog.on 'close', -> window.removeEventListener 'message', handler

## Waiting dialog

This function shows a dialog with no buttons you can use for closing it. You
should pass as parameter an options object, just as with every other
function in this plugin, but in this case it must contain a member called
`work` that is a function that will do whatever work you want done while the
dialog is shown.  That function will *receive* as its one parameter a
function to call when the work is done, to close this dialog.

Example use:
```javascript
tinymce.activeEditor.Dialogs.waiting( {
    title : 'Loading file'
    message : 'Please wait...',
    work : function ( done ) {
        doLengthyAsynchronousTask( param1, param2, function ( result ) {
            saveMyResult( result );
            done();
        } );
    }
} );
```

    Dialogs.waiting = ( options ) ->
        dialog = tinymce.activeEditor.windowManager.open
            title : options.title ? ' '
            url : prepareHTML options.message
            width : options.width ? 300
            height : options.height ? 100
            buttons : [ ]
        if options.onclick then installClickListener options.onclick
        options.work -> dialog.close()

# Installing the plugin

    tinymce.PluginManager.add 'dialogs', ( editor, url ) ->
        editor.Dialogs = Dialogs
