
# Project Plan

This document aims to be a complete plan for what needs to be done on this
project, readable by developers.  It can therefore be viewed as a to-do list
in chronological order, the first items being those that should be done
next, and the later items those that must come after.  Necessarily, the
later items are more vague than the earlier ones.

Note also that there are some [known bugs and planned enhancements](
bugs-and-enhancements.md) not listed in this file, because they are not part
of the linear progression of the project.  They can be addressed whenever it
becomes convenient or useful; this document lists things in a more-or-less
required order of completion.

## Enabling and disabling features

Implement the following system satisfying the following requirements, for
allowing users to enable/disable certain app features on a per-document
basis.  The first optional feature is pattern-based rules, so this is not
necessary to implement until then.

 * The app register a list of features (probably a short phrase naming each,
   plus a one-to-two-sentence description of it, plus a default value for
   enabled/disabled).
 * The app can then query, at any time, the enabled/disabled status of any
   feature in the currently open document.  At first, such a function should
   just return the default value.
 * The document settings dialog will then have a section for application
   features, with checkboxes for enabling/disabling all registered features.
   Such changes will be written to document metadata.
 * Then you can upgrade the enable/disable query function to check the
   document metadata first, and return the default value only if there is no
   information in the document metadata about the feature.
 * Look through the OverLeaf specification for places where various features
   are mentioned as optional, and if any are currently implemented in the
   app, add code that ignores/disables them in any document for which the
   query function returns "disabled" for that feature.
 * Ensure that there is an event that fires when document settings are
   changed; if there is not one, create one.
 * At any point where a change in settings will require some kind of
   re-processing (e.g., the list of supported validation features was
   changed) be sure that a handler for the event exists and works.

## Parsing test

Rewrite the following section to more accurately reflect Section 24 of the
specification, then implement it as a module attached to the main Lurch
application, a module that can easily be disabled if we need to redesign it.

 * Add two new attribute types to the context menu for attribute expressions
   in the document: "notation," "type," and "meaning."
 * Add a new validation category for anything that has a "notation",
   "meaning," or "type" arrow going in or out.  Call it notation validation.
 * Start notation validation by verifying that the expression being
   validated fits all of the following criteria.  If it does not, mark it
   invalid.
    * If you output type arrows, you output no other kind of arrows.
      Reason: A type cannot also be a notation or meaning.
    * If you output type arrows, you take no arrows in.
      Reason: A type cannot be assigned any notation, type, or meaning.
    * If you output a notation arrow, you output at most one.
      Reason: We currently require notation to be in exactly one category.
    * If you output a meaning arrow, you output at most one.
      Reason: Notation must be unambiguous.
    * If you output a meaning, you do not take in a type.
      Reason: Only patterns can have meaning, and thus they are non-atomic
      expressions.  Types are only for atomic expressions.
    * If you take in a meaning, you take in no notation arrows.
      Reason: Meanings cannot also be notational categories.
    * If you take in a meaning, you take in no type arrows.
      Reason: Meanings are not notations, and thus can't have notational
      types.
    * If you take in a notation, you take in no type arrows.
      Reason: Notational categories aren't expressions, to be assigned
      types.
    * If you take in a type, you take in no other kind of arrows.
      Reason: This means you're the notation for an atomic type, and cannot
      be assigned a meaning, nor treated as a notational category.
    * If you take in a meaning, you output no arrows.
      Reason: Meanings are supposed to stand alone, not be a piece of
      something else.
    * If you take in a notation, you output no type arrow.
      Reason: Notational categories can't also be types.
    * If you take in a type arrow, you output neither type nor meaning
      arrows.
      Reason: Only atomic notations have types, and they canont be types or
      meanings.
 * Create a function that computes, for any given expression, whether it is
   the "core" of a notation definition.  For a non-pattern, this is the
   target of the type arrow.  For a pattern, this is the source of the
   meaning arrow.
 * Extend that function to return false if any expression in the connected
   component of the attribution graph is not valid.
 * Create a function that, for cores of notation definitions, computes a
   JSON representation of how to modify a parser with that new rule.  Here's
   how:
     * For a structure of the form `[A]<--notation--[B]<--type--[C]`:
        * If C is "built-in" then try to read B as integer/real/letter/etc.,
          and use a built-in regular expression to create an atomic parsing
          rule in category A.
        * If C is "regular expression" or "regexp" or "re" then create an
          atomic parsing rule using B's content as a regular expression in
          category A.
        * If C is "symbol" then create an atomic parsing rule using B as
          static (not a regular expression) in category A.
     * For a structure of the form `[A]<--notation--[B]`:
       Create the parsing rule that B is a subcategory of A.
     * For a structure of the form `[A]<--notation--[B]` with n other
       structures of the form `[A1]--type-->[variables]-->[B]`, and
       optionally a connection `[B]--meaning-->[M]`:
       Create, in category A, a grammar rule that follows the pattern in B,
       but with each variable replaced by its type (some Ai).  As the
       head of the OpenMath expression that will be generated, use the
       `OM.encodeAsIdentifier` version of the first label on the definition
       core.  If there is no label, encode the definition itself (with the
       types, not the variable names).
       Also record in the same JSON data all labels of the core, and the
       complete form of the meaning.  That complete form will include the
       notational definition as an attribute, which should be removed.
 * Create a function that applies any such JSON record of a command to a
   parser object, thus modifying that parser appropriately.
 * Extend the `contentsChanged` handler for expressions so that, if they are
   part of a notation/type/meaning component in the attribution graph, find
   their core and call this function on it, saving the result internally,
   much like validation does.
 * Whenever any such parsing JSON data is recomputed and stored, loop
   through all later expressions in the document, doing the following.
   * Before the loop, create an empty parser P.
   * Upon encountering an expression containing notation JSON data, apply to
     it the function that extends P with that data.
   * Upon encountering an expression with attribute test set to true, run P
     on its contents and store the resulting structure as a group attribute
     in the expression.  (If the expression doesn't parse, this may be
     null.)
 * Create three functions for storing meanings in parsing test expressions:
    * The first reads two attributes, one storing the computed meaning and
      one storing the official meaning (which, for now, no expression yet
      has, but that's coming soon).  It then writes into the expression the
      following data.
       * If there is no official meaning stored, decorate the close grouper
         with a question mark.  The hover message should show the canonical
         form of the computed meaning, and mention that there is no official
         meaning against which to compare it.
       * If there is an official meaning and it matches the computed one,
         decorate the close grouper with a green check (as in validation)
         and the tooltip can report the one (correct) meaning in canonical
         form.
       * If there is an official meaning and it differs from the computed
         one, decorate the close grouper with a red X (as in validation) and
         the tooltip can report the two meanings in canonical forms.
    * The second takes an official meaning as input, writes it to the
      official meaning attribute of the expression, then calls the first
      function to update validation.
    * The third takes a parser and applies it to the text content of the
      expression, then writes it to the computed meaning attribute of the
      expression, then calls the first function to update validation.
 * Update the loop that re-parses all test-type groups to use this new
   function to store computed meanings in test expressions, so that their
   visual validation results are also updated.
 * Whenever any expression with type test set to true changes, do the same
   loop, but the only test that should be recomputed is the one that
   changed.
 * Add a context menu item in expressions that have "test" set to true; it
   should allow you to mark a test as currently passing.  This takes the
   currently parsed meaning of that group and stores it as the official
   meaning.  This should trigger a change event in the group, and thus
   update its visual appearance.
 * Add another context menu item for clearing out the offical meaning.

## Google Drive support

Google Drive also provides a very nice [real time collaboration API](
https://developers.google.com/google-apps/realtime/overview) that makes any
document you like into a Google-Docs-like collaborative model where changes
are auto-synced across collaborators.  This was an idea that Dana Ernst
asked for long ago when he first heard about the webLurch project. Integrate
that into webLurch, imitating the UX Ken describes from typical online
collaboration apps such as Google Docs and Overleaf, as follows.

 * Create a function that can update the UI when users log into or out of
   Google Drive.  At first, it will just hide/show the File > Save and
   File > Save as... actions on the menu and toolbars.
 * Add an HTML element to the toolbar in which we can place text about the
   document's dirty state, and controls for enabling cloud storage.
 * Place a button in that element that says "Enable cloud storage" and make
   the button visible iff the user has not authenticated to Google Drive.
   Implement the click handler later, as described below.
 * Create a function that can specify any message to appear to the left of
   that button (whether the button is visible or not).
 * For now, whenever a new document is created, call that function with a
   warning message saying "Not saved".
 * Provide a section in the File > Application settings... dialog that will
   be for Google Drive authentication.  You will add the Google login
   functionality there later, as well as explanatory text about how cloud
   saving works.
 * Implement the click handler for the "Enable cloud storage" button to open
   the application settings dialog and scroll to the Google Drive section.
 * Add to the application settings section about Google Drive the actual
   login/auth button.  Once a user has logged in, the button becomes a
   disconnect-from-my-Drive button (de-auth).  See the tutorial on how to
   do so [here](
   https://developers.google.com/google-apps/realtime/realtime-quickstart),
   and especially the JavaScript tools they've developed for your use
   [here](https://github.com/googledrive/realtime-utils/blob/master/realtime-client-utils.js).
 * Add a handler function for when a user enables or disables cloud storage.
   At first, the only result will be the hiding/showing of the "Enable Cloud
   Storage" button.
 * Extend the Google login/out handler so that logging in moves the current
   file into Google Drive as a new document.  Attempt to preserve document
   title, if one was set in document properties.  If Drive requires unique
   titles, you may need to append a number.
 * When the file is moved into Drive, update the toolbar message to say
   "Saved to Drive."
 * Extend File > New so that, if the user is already logged into Drive, the
   new file is placed into Drive, with its default "Untitled" title.  Also
   change the toolbar message to "Saved to Drive."
 * When the user makes changes to their document, queue up a syncing event
   for maybe 2 seconds in the future; if one was already queued, cancel it.
   Immediately change the toolbar message to "Syncing..."
 * When the syncing event fires, save the file to Google Drive, then change
   the toolbar message to "Saved to Drive" again.
 * Extend File > Open so that, if the user is logged into Google Drive, it
   replaces its old functionality with a dialog that lists all Lurch files
   in the Drive, as a flat list sorted by most recently used.  Picking one
   opens the file.
 * Create a new action, File > Open my Google Drive, that does just that, in
   another tab.  This will be used for file management.  We need to create
   no UI for it; Google has done so.
 * Extend the function that can update the UI when users log into or out of
   Google Drive as follows:  Have File > Open my Google Drive hidden by
   default, but shown when you log into Drive.  Hide it again if you log
   out.
 * We want Google Drive logins in one browser tab containing the Lurch app
   to impact any other browser tabs containing the Lurch app.  So have the
   app check the application settings every second or two, and if it sees
   that the user has changed their Google Drive settings (stored in Local
   Storage, due to the user's logging into Drive in another tab of the app),
   then re-run the silent Google login attempt routine to complete the login
   in the new tab as well.  (At least, this seems like it would work.
   Investigate.)
 * Add to the application settings dialog, in the Google Drive
   authentication section, a description of how cloud storage works.

## Offline support

To make an HTML5 app available offline, I believe the appropriate step is
simply to provide an app manifest.  I'm verifying that with [this
StackOverflow
question](http://stackoverflow.com/questions/27136144/how-can-online-offline-versions-of-an-html5-app-access-the-same-localstorage).
That question links to a tutorial on app manifests, if the answer turns out
to be "yes" to that question.

## Ideas from various sources

### Outsourcing the file dialog

The `jsfs` file dialogs I made myself, and thus must also maintain.  They are
not beautiful.  Instead, you could use the
[jquery.filebrowser](https://github.com/jcubic/jquery.filebrowser) plugin.
Furthermore, it's already generalized to allow you to swap out back ends.  So
you could not only update jsfs with this, but also easily make it support
Google Drive or Dropbox with minimal changes.  Create plans to do so.

### Parsing speed improvements

If parsing with the current package becomes a performance bottleneck,
note that there are several improvements available, some already implemented
in JavaScript.  See
[here](https://en.wikipedia.org/wiki/Earley_parser#JavaScript).

### All images consistently base64

[This GitHub comment](
https://github.com/buddyexpress/bdesk_photo/issues/2#issuecomment-166245603)
might be useful for ensuring that even images pasted into a document get
converted to base64, as all the other images in the document are.

### LMS integration

Suggestion from Dana Ernst: Perhaps this is not necessary or feasible, but
if you go with a web app, could you make it easy for teachers to "plug into"
the common LMS's (e.g. Blackboard, Canvas, etc.)?  I'm envisioning students
being able to submit assignments with ease to an LMS and then teachers can
grade and enter grades easily without have to go back and forth between web
pages.

### Further wiki integration?

Is it possible for the entire Lurch app to exist inside MediaWiki, so that
editing a wiki page was done using Lurch as the editor?  That would be
excellent for many use cases.  Certainly, we can use the editor in an iframe
but the question is about integrating with (replacing) MediaWiki's existing
editing features.  You would still want to keep the normal full-page app
available for those who don't want the trappings of the wiki.  But it would
be very intuitive, because people are familiar with wikis, and can begin as
readers, then move up to being writers.

### Desktop app

Convert webLurch into a desktop app using
[electron](https://github.com/atom/electron).
This gives the user an app that always works offline, has an icon in their
Applications folder/Start menu, etc., and feels like an official app that
they can alt-tab to, etc., but it’s the exact same web app, just wrapped in
a thin desktop-app shell.  You can then add features to that as time
permits.

 * When the user clicks "save," you can have the web app first query to see
   if it’s sitting in a desktop-app wrapper, and if so, don’t save to
   webstorage, but pop up the usual save box.
 * Same for File > Open.
 * Same for accessing the system clipboard
Similar apps could be created for iOS, Android, etc., but would need to use
tools other than Electron.  These are orthogonal tasks, and need not all be
done by the same developer.

## Repository organization

 * The `app/` folder is getting cluttered.  Create an `app/examples/`
   subfolder and move every `*-example.html` and `*-example-solo.litcoffee`
   into it.  Update any relative links to other resources, and any links to
   those pages.
    * This requires also updating the `cake.litcoffee` to compile files in
      that subfolder as well.
    * It also requires taking care with the `gh-pages` merge, so that
      compiled files get deleted/recreated correctly in that branch (once).

## Improving documentation

Documentation at the top of most unit test spec files is incomplete. Add
documentation so that someone who does not know how to read a test spec file
could learn it from that documentation.  Probably the best way to do this is
to add general documentation to the simplest/main test spec, and then
reference that general documentation from all other test specs.
