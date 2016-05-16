
A "solo" source file (ending in `-solo.litcoffee`) does not get compiled
into the app itself, but rather gets compiled into its own `.min.js` file,
usable wherever it is needed.

This file, for instance, is used in [filedialog.html](filedialog.html), and
therefore should not be compiled into the app.

It defines tools for communicating with a [TinyMCE](http://www.tinymce.com/)
editor that may have launched this page inside a pop-up dialog.  When it
loads a dialog, TinyMCE passes parameters using the `getParams()` method of
the top-level window's active editor.  This code extracts those parameters,
after the page has loaded, as follows.

    window.onload = ->
        args = top.tinymce.activeEditor.windowManager.getParams()

If the `fsName` parameter was passed, it is used as the filesystem name.

        if args.fsName then setFileSystemName args.fsName

If the `mode` parameter was passed, it is used as the dialog mode.  It must
not be set immediately, because the dialog is still loading; it must be set
after a zero timeout.

        if args.mode then setTimeout ( -> setFileBrowserMode args.mode ), 0
