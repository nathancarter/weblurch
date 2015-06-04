
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
 * Inserting a group sometimes still leaves the put_cursor_here span in it.

## Enhancements

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

Background processing efficiency

 * Design and implement how this could be extended to support passing arrays
   of argument lists and receiving arrays of results, to minimize the
   overhead of message-passing.
 * Leverage the previous change to make the current implementation more
   efficient as follows:  When starting a background computation, take
   several other waiting computations with the same background function, and
   start all at once, on the array of argument lists, so that only one
   message passing need occur.
