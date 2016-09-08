
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

 * Just a note that none of the changes below impact the wiki import and
   export functionality; that stays as it is now.
 * Provide a section in the File > Application settings... dialog that will
   be for Google Drive authentication, but you don't have to put the Google
   login functionality there yet.  Include full explanatory text about how
   cloud saving works with webLurch (as described below).
 * File > Save and File > Save as... actions should be removed entirely.
 * Before adding Google Drive integration, change the items on the File menu
   to behave as follows.
   * Whenever the document is dirty, it has a warning message on the toolbar
     that says something like "Not saved" followed by a button that says
     "Enable cloud storage."
   * That button will open the document preferences dialog and scroll down
     to/highlight the section about logging into Google Drive.
   * File > Document properties... will let you change the name of the
     document which will simply be stored as document metadata; it will have
     no impact on filename, since there is no filename (yet).
   * Corresponding changes take place in the toolbar.
   * Add File > Download, which starts a download of the file as HTML.
   * Add File > Upload, which lets the user choose an HTML file to upload,
     accepts the upload, strips any dangerous tags from it, then does the
     same thing as File > New, above, before pasting the HTML content
     directly into the new, blank document.
 * Add to the application settings section about Google Drive the actual
   login/auth button.  Once a user has logged in, the button becomes a
   disconnect-from-my-Drive button (de-auth).  See the tutorial on how to
   do so [here](
   https://developers.google.com/google-apps/realtime/realtime-quickstart),
   and especially the JavaScript tools they've developed for your use
   [here](https://github.com/googledrive/realtime-utils/blob/master/realtime-client-utils.js).
 * When a user gives such authorization, the following changes take place:
   * The currently-open file in the app should then be moved into Google
     Drive as a new document.  Attempt to preserve document title, if one
     was set in document properties.  If Drive requires unique titles, you
     may need to append a number.
   * Change File > New so that it does this same procedure of moving the
     (newly created) document into Drive, with a default title such as
     "Untitled Document."
   * The toolbar will no longer say "Not saved," but will say either
     "Saved to Drive" or "Syncing..." (if in progress).
   * File > Open looks in your Google Drive for Lurch files to open, and
     presents you a flat list.  If possible, sort it by most recently used.
   * File > Manage files... gets replaced by File > Open my Google Drive.
     All file management will take place through Google's UI, not mine.
 * If a user de-authorizes webLurch from their Google Drive, then all
   entries on the File menu should revert to their original behavior.
 * Get this to work across multiple instances of the Lurch app in different
   tabs as follows.
   * Store in Local Storage the fact that the user has given a Drive login
     and succeeded, when that login takes place.
   * Have the app poll that setting every second or two, and if it sees that
     it has changed from no to yes (due to the user's logging into Drive in
     another tab of the app), then re-run the silent Google login attempt
     routine to complete the login in that tab as well.  (I think?)

## Offline support

To make an HTML5 app available offline, I believe the appropriate step is
simply to provide an app manifest.  I'm verifying that with [this
StackOverflow
question](http://stackoverflow.com/questions/27136144/how-can-online-offline-versions-of-an-html5-app-access-the-same-localstorage).
That question links to a tutorial on app manifests, if the answer turns out
to be "yes" to that question.

## Ideas from various sources

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
