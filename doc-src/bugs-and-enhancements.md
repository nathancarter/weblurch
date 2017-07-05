
# Bug fixes and Enhancements

This document lists known bugs that we plan to fix and planned enhancements
not yet made.  They are listed in this file, rather than in [the Project
Plan](plan.md) because these are things that are not part of the linear
progression of the project, in the sense that further work can be done on
the main project plan without these bug fixes or enhancements.

## Bug fixes

### Overall

 * Arrows representing connections between groups don't look good sometimes.
   Improve the heuristics for drawing them as follows.
    * The default path is (a) up from the source until it reaches a distance
      of h above the target's top (for some fixed constant h), (b) turn
      NE/NW toward the target with radius r, (c) horizontally toward the
      target, (d) turn SE/SW toward the target with radius r, then (e) down
      to the target with an arrowhead.
    * One problem with that strategy is that if there is little or no
      horizontal separation, then it is (close to) just one vertical line.
      So if the horizontal separation is under 2r, make the following
      change.  The end of the curve can still be a turn SW of radius r,
      followed by a step down with an arrowhead.  But from the source until
      that point should be a single Bézier curve that begins with velocity N
      and ends with velocity W.
    * The other problem with the strategy is if there are many targets in
      the same row of text, then the lines on the way to those targets will
      all overlap, and thus become indistinguishable.  To solve this, let h
      be a function equal to $C + 0.03\Delta x$, where $C$ is some constant
      and $\Delta x$ is the horizontal distance between source and target
      bubbles.  The $0.03$ is an estimate that can be customized with
      testing.

### Load and save

 * Not all edits cause the document to be marked dirty.  TinyMCE events are
   not firing correctly.  [Minimal working example created.](
   https://github.com/tinymce/tinymce/issues/2224)
   [Or see this related issue.](
   https://github.com/tinymce/tinymce/issues/2028)
   Use the responses from that to get this
   problem fixed in Lurch, either by updating to a fixed version of TinyMCE
   or by installing a workaround here.  Although you've heard about the
   KeyUp and SetContent events that you're using in the Groups package, so
   you may be able to correct this problem partially with those events.
   (Verified on 9/22/16 that these bugs are still unresolved.)
   The bug just mentioned has since been closed, and suggests that it may
   have been fixed in TinyMCE 4.x; check to see.

### Other

 * Some of the `*-duo.litcoffee` files in `src/` in the master branch also
   have committed versions in `app/` that are merely copies.  This is
   necessary in the gh-pages branch, but in master it's redundant.  Fix.
 * Travis-CI build was segmentation faulting, though the tests run just fine
   locally for me.  Figure out why and get the Travis build working again,
   then uncomment the Travis status indicator in
   [README.md](https://github.com/nathancarter/weblurch/blob/master/README.md).
 * In the Lean example app, `termGroupToCode` uses `contentsAsText`, which
   ignores paragraph breaks, as if they were not whitespace; this is
   problematic.  Use `contentAsCode` instead.

## Enhancements

### Validation

 * The boilerplate code at the end of `computeStepValidationAsync` in the
   validation module is not as extensive (and thus as helpful) as it is in
   the OverLeaf specification.  Specifically, you can declare variables for
   `valid`, `message`, and `verbose`, and then package them into an object
   at the end as part of the boilerplate.  Then users just need to assign to
   those variables.
 * Make validation icons go grey at the start of validation, and they'll be
   replaced by non-gray ones when validation completes.

### MathQuill parsing

 * Before doing any MathQuill updates, import MathQuill 0.10, which has big
   breaking API changes, and update all Lurch MathQuill calls to use the new
   API.  [See here for migration
   notes.](https://github.com/mathquill/mathquill/wiki/v0.9.x-%E2%86%92-v0.10.0-Migration-Guide)
   Because that is a major change to many parts of Lurch, test thoroughly,
   including parsing MathQuill content.
 * Support adjacent atomics as factors in a product
 * Support chained equations
 * Add tests for things that should *not* parse, and verify that they do not

### Dependencies

 * Right now circular dependency relationships never cause an infinite loop
   because dependency content is only embedded when a document is opened.
   So if A depends on B which depends on A, then when A is opened, it will
   embed B, which indirectly embeds the saved version of A.  If A is saved
   and B is opened, that will embed the (new, larger) A, and this can
   continue to increase file sizes as we repeatedly open documents.  But
   each step of this infinite expansion requires a user action, so the
   application will never hang.  However, it can be a silent and highly
   undesirable file inflater.  Expand the dependency loading mechanism to
   check for a loop by finding the same filename or wiki URL nested within
   itself in the dependency data of a document, and alert the user.
 * Extend the "Add URL dependency" event handler with a "please wait"
   indicator while the document is being fetched.  Use the `waiting` method
   in the `Dialogs` plugin.
 * There is not yet support for adding dependencies from files in your
   Dropbox.  Add this feature.

## Cheat sheets

The "Cheatsheets" menu item of the RStudio GUI is an excellent resource for
many users.  It contains links to online PDFs of one- or two-sided
printable, dense reference sheets for common topics in RStudio.  A similar
cheatsheet (or set thereof) could be created about Lurch.  Consider these
topics.

 * The advanced users guide, condensed into a two-sided reference
 * Understanding and dealing with validation messages
 * A reference for each of the built-in libraries

### Groups Plugin

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

### UI for Connections Between Groups

 * Add a keyboard shortcut for entering connection mode (that is, clicking
   the connection button on the toolbar).  This should be in the groups
   plugin.
 * Add a keyboard shortcut for cycling through the built-in keys an
   attribute expression can have.  This should be in the main Lurch app.
 * Add an option that when entering arrow-creation mode, ALL bubble outlines
   in the document are faintly drawn (not their tags), so that it's
   completely clear where a user wants to aim the mouse to hit a certain
   bubble.
 * Add an option that show-groupers (Ctrl/Cmd+1) mode is automatically
   enabled when the user enters arrow-connection mode, and re-disabled (if
   it was disabled in the first place) when exiting arrow-connection mode.
   This is like the previous feature, but more aggressive and techy.  (Do we
   still need it now that we have the previous feature?)
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

### Miscellaneous

 * Move all plugin files into the `src/` folder, if possible.
 * See [this answer](http://stackoverflow.com/a/32120344/670492) to your
   StackOverflow question about higher resolution HTML canvas rendering on
   retina deisplays.  See if its suggestions can work in your case.  This
   may be the same as the following one...
 * Bubble tags are not drawn at retina resolution on Macs with retina
   displays.  [See my question about how to fix this problem here.](http://stackoverflow.com/questions/30537138/rendering-html-to-canvas-on-retina-displays)
 * Complete [the unit test for the DOM Utils
   package](../test/domutils-spec.litcoffee).  See the end of that file for
   the few missing tests.
 * If you ever need to export PDFs of Lurch documents, consider
   [jsPDF](https://github.com/MrRio/jsPDF).
 * Eventually, pull the LoadSave plugin out into its own repository on
   GitHub, so that anyone can easily get and use that TinyMCE plugin, and
   improve on its code.
 * In the Lean example app:  How might we work Lean's `notation`
   definitions in with MathQuill widgets in the document?

### Background processing

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

### Enhancements to the XML Groups module and/or demo app

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
