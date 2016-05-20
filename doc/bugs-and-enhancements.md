
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

 * When you open (or type) a file that's longer than the screen, you must
   open and close the JS console to force resizing, or it won't scroll
   vertically.  Alternatively, you can resize the window.  Seems like the
   resize event handler needs to be called immediately after the page
   geometry is set up.
 * The Insert Menu covers the toolbar and will not disappear, even when an
   item is selected.  This seems like it is either a TinyMCE bug (and may go
   away if we update TinyMCE) or it is a bug in our use of TinyMCE.
 * Formats menu is currently empty.
 * Some of the `*-duo.litcoffee` files in `src/` in the master branch also
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

HTML export/import

Currently the only ways to load/save Lurch documents are `localStorage` and
the wiki.  Consequently, dependencies can only be specified in one of these
two ways.  Extend this to general HTML pages, as follows:

 * Add an HTML export function that lets you download the contents of the
   editor (plus metadata at the front, just like when exporting to the wiki)
   for publishing on your own website, for example, or pasting into a blog
   post.  Wrap it in a DIV with class "EmbeddedLurchDocument" or something
   similarly unique.
 * Expose that functionality to the user, on the File menu.
 * Add an HTML import function that lets you specify a URL, sends an XHR to
   get the page at that URL, and extracts the full content of the Lurch DIV.
   Be sure to extract the metadata as well, just as with a wiki import.
 * Expose that functionality to the user, on the File menu.
 * Extend dependencies so that they can be at arbitrary URLs, now, not just
   on the wiki.  Use the HTML import function just created for this purpose.

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

UI for Connections Between Groups

 * Add an option that when entering arrow-creation mode, ALL bubble outlines
   in the document are faintly drawn (not their tags), so that it's
   completely clear where a user wants to aim the mouse to hit a certain
   bubble.
 * Add an option that show-groupers (Ctrl+1) mode is automatically enabled
   when the user enters arrow-connection mode, and re-disabled (if it was
   disabled in the first place) when exiting arrow-connection mode.  This is
   like the previous feature, but more aggressive and techy.  (Do we still
   need it now that we have the previous feature?)
 * On mobile, a tap highlights the innermost bubble under it, without
   creating the arrow yet, and shows OK/cancel buttons hovering nearby.  If
   the user tapped what he/she expected to tap, then he/she hits OK and it
   creates the arrow.  Cancel (or just tapping elsewhere) closes the
   OK/cancel buttons and does nothing else.
 * When in arrow-creation mode, keystrokes are interpreted as typing bubble
   labels, which will scroll the view to the bubbles with those labels, and
   highlight them as if the user had mouse-hovered them.  If the user
   presses enter, the arrow will be created.  Hence there are
   keyboard-shortcut ways to specify arrows among bubbles.  This would work
   best with a keyboard shortcut for entering bubble-making mode also.  (If
   there are ambiguous labels--i.e., ones that apply to more than one
   bubble--just choose any one; that's the user's fault.)  Note that this
   requires two additional features to help it out:
   * A function in the group type for computing the default label for any
     bubble in the document.  The default can be the address of the bubble
     in the hierarchy, as a list of positive integers; e.g., the second
     bubble immediate inside the tenth topmost bubble has number 10.2.
   * Drawing bubbles in arrow-creation mode should include these labels
     somewhere nearby.

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
 * Eventually, pull the LoadSave plugin out into its own repository on
   GitHub, so that anyone can easily get and use that TinyMCE plugin, and
   improve on its code.

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
