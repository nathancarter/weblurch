
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

Other

 * Formats menu is currently empty

## Enhancements

Features needed for real Lurch

 * We do not yet have a way to place visible indicators at the end of groups
   (like the thumbs or traffic lights used in the desktop version).  The
   first solution that comes to mind is replacing IMG tags for groupers with
   spans that have the contenteditable=false property, and can contain
   arbitrary data, like the MathQuill plugin does.  However, doing so draws
   the cursor very poorly and confusingly, especially near grouper
   boundaries.  Thus the best way to go is probably to create a new custom
   image for each type of indicator-grouper pair, and switch the src of the
   groupers in question to update their appearance.
 * The matching package in the desktop Lurch needs re-implementing on the
   web, preferably as a function that takes very little input, so that it's
   easy to use in a BackgroundFunction.  Furthermore, that package's
   algorithms never fully functioned for arbitrary numbers of metavariables
   inside substitution expressions; that needs to be designed correctly and
   implemented correctly, perhaps even afresh.

Miscellaneous

 * Move all plugin files into the `src/` folder, if possible.
 * Make unit tests for `Group.contentAsText`, `Group.contentAsFragment`, and
   `Group.contentAsHTML`.  All were tested informally in the browser, but
   have not yet become unit tests.
 * Bubble tags are not drawn at retina resolution on Macs with retina
   displays.  [See my question about how to fix this problem here.](http://stackoverflow.com/questions/30537138/rendering-html-to-canvas-on-retina-displays)
 * Complete [the unit test for the DOM Utils
   package](../test/domutils-spec.litcoffee).  See the end of that file for
   the few missing tests.

New members for the Group class that will be needed as we create more
complex webLurch-based applications

 * `saveCursorPosition()`, which returns a bookmark
 * `restoreCursorPosition()`, which returns to a bookmark you provide
 * `allContents()`, which returns an array of alternating strings and groups
 * `indexInParent`, computed by `scanDocument()`
 * `nextSibling` and `previousSibling`, also computed by `scanDocument()`

Background processing efficiency

 * Design and implement how this could be extended to support passing arrays
   of argument lists and receiving arrays of results, to minimize the
   overhead of message-passing.
 * Leverage the previous change to make the current implementation more
   efficient as follows:  When starting a background computation, take
   several other waiting computations with the same background function, and
   start all at once, on the array of argument lists, so that only one
   message passing need occur.
