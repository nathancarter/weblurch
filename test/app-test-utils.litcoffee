
# App-Testing Utilities

When testing the main webLurch app, there are several utilities that it's
handy to have available, including functions for sending UI events to the
headless browser used for testing, as well as functions for comparing DOM
trees and injecting code into the JavaScript environment of the headless
browser.  This module provides those utilities.

    { pageDo } = require './phantom-utils'

## Injecting code

We can easily execute functions in the testing browser using the `pageDo`
routine, but it's not easy to transport a function already defined in the
`node.js`-based testing environment into the headless browser environment,
to assign it to a global variable for later re-use.  The following function
makes that possibly by installing a given function as a member in the
`window` object in the PhantomJS environment.

For example, you could call `pageInstall myFunc, 'foo'` and then
depend upon the fact that the function `myFunc` from the `node.js`-based
testing environment now existed as `window.foo` in the PhantomJS
environment.  (Note that the function will not take with it any captured
variables.)

    exports.pageInstall = ( func, name ) ->
        pageDo ( ( func, name ) -> window[name] = func ), func, name

## Sending/Receiving HTML

The following function is useful as the first argument to `pageExpects`,
and fetches the full contents of the editor.

    exports.allContent = -> tinymce.activeEditor.getContent()

And we have a setter corresponding to the previous function.

    exports.setAllContent = ( content ) ->
        pageDo ( content ) ->
            tinymce.activeEditor.setContent content
        , content

The following function is useful as the first argument to `pageExpects`,
and fetches the contents of the current cursor selection.

    exports.selectedContent = -> tinymce.activeEditor.selection.getContent()

And we have a setter corresponding to the previous function.

    exports.setSelectedContent = ( content ) ->
        pageDo ( content ) ->
            tinymce.activeEditor.selection.setContent content
        , content

## Interacting with TinyMCE

To programmatically invoke a TinyMCE toolbar button or menu item, call this
command, passing the name of the button or menu item.  This name must be the
internal name, that is, the one used in the call to `tinymce.init`,
mentioned in the toolbar/menu entries (usually a single, lower-case word).
If the given name is not a sequence of alphabetic characters, no action is
taken.

    exports.pageCommand = ( name ) ->
        if not /^[a-zA-Z]+$/.test name then return
        pageDo eval "(function() {
            ( tinymce.activeEditor.buttons.#{name}
           || tinymce.activeEditor.menuItems.#{name} ).onclick() })"

There are many page commands worth knowing about.  I list them here, but
many pop up dialogs with which you would then need commands to interact.  So
not all are simple to use.
 * newfile, openfile, savefile, managefiles
 * print
 * undo, redo
 * cut, copy, paste
 * alignleft, aligncenter, alignright, alignjustify
 * bullist, numlist
 * outdent, indent, blockquote
 * inserttable, tableprops, deletetable, column, row, cell
 * fontselect, styleselect
 * bold, italic, underline, textcolor, subscript, superscript,
   strikethrough, removeformat
 * link, unlink
 * charmap, image, hr
 * spellchecker
 * searchreplace
 * about, website
 * me (Meaningful Expression Group), hideshowgroups

"Select all" is problematic; it seems necessary to invoke it twice, or its
effects immediately reverse after they take effect, for reasons unknown. The
following convenience function calls "select all" twice in succession, with
the briefest of pauses in between, as a workaround.

    exports.pageSelectAll = ->
        exports.pageCommand 'selectall'
        exports.pageCommand 'selectall'
