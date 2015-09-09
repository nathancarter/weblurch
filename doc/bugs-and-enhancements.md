
# Bug fixes and Enhancements

This document lists known bugs that we plan to fix and planned enhancements
not yet made.  They are listed in this file, rather than in [the Project
Plan](plan.md) because these are things that are not part of the linear
progression of the project, in the sense that further work can be done on
the main project plan without these bug fixes or enhancements.

## Bug fixes

Load and save

 * Not all edits cause the document to be marked dirty.  TinyMCE events are
   not firing correctly.  [Minimal working example created.](
   http://www.tinymce.com/develop/bugtracker_view.php?id=7511)
   [Or see this related issue.](
   http://www.tinymce.com/develop/bugtracker_view.php?id=7304)
   Use the responses from that to get this
   problem fixed in Lurch, either by updating to a fixed version of TinyMCE
   or by installing a workaround here.  Although you've heard about the
   KeyUp and SetContent events that you're using in the Groups package, so
   you may be able to correct this problem partially with those events.
 * Using the keyboard shortcut for New or Open on Mac triggers the Chrome
   behaviors on the Chrome File menu, not the TinyMCE behaviors on its File
   menu.  See [my question about this on the TinyMCE forum,](
   http://www.tinymce.com/forum/viewtopic.php?pid=116179) and the
   StackOverflow page to which it links with information on how you might go
   about building a workaround if one doesn't exist already.
 * It's too easy to navigate away from the editor and lose your work.  Make
   a popup that asks if you really want to leave the page or not.

Other

 * Formats menu is currently empty
 * When you open a file that's longer than the screen, you must open and
   close the JS console to force resizing, or it won't scroll vertically.
 * Some of the `.duo.litcoffee` files in `src/` in the master branch also
   have committed versions in `app/` that are merely copies.  This is
   necessary in the gh-pages branch, but in master it's redundant.  Fix.
 * Travis-CI build was segmentation faulting, though the tests run just fine
   locally for me.  Figure out why and get the Travis build working again,
   then uncomment the Travis status indicator in [README.md](../README.md).

## Enhancements

MathQuill parsing

 * Support adjacent atomics as factors in a product
 * Support chained equations
 * Add tests for things that should *not* parse, and verify that they do not

Groups Plugin

 * Make a menu item for hiding/showing group decorations.
 * The `Group.set` function no longer takes any action if the new value is
   the same as the old value.  (Similarly, `clear` doesn't do anything if
   the attribute is already gone.)  This prevents clients from needing to
   implement their own checks to prevent infinite loops of change event
   handlers.  The remaining task is to go through the demo apps and find
   their workarounds for this annoyance and remove them to clean up those
   apps (and not confuse readers).  Then verify that the apps still work,
   i.e., that there truly are no infinite loops remaining.
 * Several new methods have been added to the Groups Plugin without unit
   tests being written for them.  Be sure to look back through the full list
   of functions in that file and find those which have no unit tests, and
   create unit tests for them, debugging the functions as you do so.
 * The following new members will be needed in the Group class as we create
   more complex webLurch-based applications
   * `saveCursorPosition()`, which returns a bookmark
   * `restoreCursorPosition()`, which returns to a bookmark you provide
   * `allContents()`, which returns an array of alternating strings and
     groups

Miscellaneous

 * See [this answer](http://stackoverflow.com/a/32120344/670492) to your
   StackOverflow question about higher resolution HTML canvas rendering on
   retina deisplays.  See if its suggestions can work in your case.
 * Move all plugin files into the `src/` folder, if possible.
 * Bubble tags are not drawn at retina resolution on Macs with retina
   displays.  [See my question about how to fix this problem here.](http://stackoverflow.com/questions/30537138/rendering-html-to-canvas-on-retina-displays)
 * Complete [the unit test for the DOM Utils
   package](../test/domutils-spec.litcoffee).  See the end of that file for
   the few missing tests.
 * Improve build process to not compile files whose dates indicate that they
   do not need it, nor to minify files whose dates indicate that they do not
   need it.
 * If you ever need to export PDFs of Lurch documents, consider
   [jsPDF](https://github.com/MrRio/jsPDF).

Background processing

 * Create a way to write a foreground function tht is a series of background
   steps as inner functions, and only the one for teh current state of the
   group is run, automatically placing it in the next state.  The following
   example client code would create internal state names in a linear order.
   This could be a subclass of a more general one that's an arbitrary state
   graph.
```
P = new Processor 'group type name here'
P.addStep ( group ) -> ...
P.addStep ( group ) -> ...
```
 * Design and implement how this could be extended to support passing arrays
   of argument lists and receiving arrays of results, to minimize the
   overhead of message-passing.
 * Leverage the previous change to make the current implementation more
   efficient as follows:  When starting a background computation, take
   several other waiting computations with the same background function, and
   start all at once, on the array of argument lists, so that only one
   message passing need occur.

Enhancements to the XML Groups module and/or demo app

 * Make an option for whether to show tags even when the cursor is not in
   the bubble.  If so, make the open decoration of every bubble
   "#{tagName}:".
 * The validation routine for that demo app is one routine with four
   independent checks.  That's perfect for breaking into four separate
   routines an enqueueing all into the background as separate tasks.  This
   would be an excellent test of that model, which you plan to use in the
   real webLurch.
 * Each tag's data can specify a set of Group attributes that should be
   copied into the XML output as element attributes.  Then clients can
   create their own UI for editing such attributes, and just store them in
   the Groups themselves, content with the fact that the `xml-groups` module
   will carry that data over into the XML output.
 * Add support to the Groups package for accepting click and/or double-click
   events on open/close groupers, and passing them to the Group type for
   handling.  Here is the code the MathQuill plugin uses for this purpose.
   Note the selector in the second line.
```
editor.on 'init', ->
    ( $ editor.getDoc() ).on 'click', '.rendered-latex', ( event ) ->
        event.stopPropagation()
        # here, "this" is the element that received the click event
```
 * Use the feature from the previous bullet point to give more detailed
   feedback about failed structural rules.
 * Create an importer that reads in OM CDs and creates documents from them
   that use Groups.  This would then truly be an OM CD Editor!
