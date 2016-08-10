
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

## Attribute dialog

 * Next to any embedded attribute, provide a "Remove" button that deletes
   the attribute internally from the expression.  Ensure that this action is
   placed correctly on the undo/redo stack.
 * Next to any non-embedded attribute, provide a "Remove" button that
   deletes the connection from the source to the target.  Ensure that this
   action is placed correctly on the undo/redo stack.
 * Next to any embedded attribute whose value is not a list, provide an
   "Expand" button that places the in-document version of that attribute,
   with the appropriate connection, immediately after the group in which it
   is embedded.  This also removes the embedded version.  Ensure that this
   action is one single action on the undo/redo stack.
 * Next to any embedded attribute whose value is a list, provide an "Expand"
   button that places the in-document version of that attribute's elements,
   in the order they appear in the list, with the appropriate connections,
   immediately after the group in which it is embedded.  This also removes
   the embedded version.  Ensure that this action is one single action on
   the undo/redo stack.
 * For any hidden attribute whose value is atomic, show it as an editable
   text box.  When edits take place in that text box, immediately update the
   value of the hidden attribute in accordance with the edits.  Place each
   such change on the undo/redo stack, merging when possible.
 * Every key should also be shown as an editable text box.  When edits take
   place in that text box, immediately update the value of the hidden
   attribute in accordance with the edits.  Place each such change on the
   undo/redo stack, merging when possible.
 * At the end of the dialog, provide a button to add a new key-value pair to
   the attributes list.  It will always create an atomic value, which can
   immediately be edited, either in key or in value.  Ensure that this action is one single action on the undo/redo stack.

## Code attributes

 * Add to the list of suggested key types on the group context menu "code."
 * For expressions that have an attribute with key "code," add to their
   context menu an item "Edit as code."  It should pop up a dialog
   containing a [CodeMirror](http://codemirror.net/) editor and the contents
   of the expression as plain text.  Approved edits are propagated back into
   the document, inside the expression.  Some work may need to be done to
   preserve newlines and indentation.  Ensure that any such change is placed
   correctly on the undo/redo stack.
 * In the attributes dialog, for any value that is code (i.e., it itself has
   a code attribute), provide an "Edit" button next to it that pops up the
   same code editor that would be used if the value were in the document and
   its "Edit as code" context menu item were chosen.  The only difference is
   that changes will be stored within a hidden attribute instead of in the
   document, and thus care may need to be taken regarding the undo/redo
   stack.

## Labels

 * Create a global array of all labeled expressions.
 * Create a function for initializing the array to empty, and do so whenever
   a new document is created, or the app is launched, or a new document is
   loaded.
 * Create an `addPair` function for adding a label-expression pair to the
   list.  It should store both the labeled group and the label attribute
   attached to it.  Ensure that it never adds the same pair more than once
   to the list.  (That is, this function is idempotent when called on the
   same set of arguments a second time.)
 * Create a function `addExpression` that inspects an expression and calls
   `addPair` zero or more times, once for each label the expression has,
   hidden or visible.
 * Whenever a document is loaded, loop through all of its expressions and
   call `addExpression` on each.
 * Create a `deleteExpression` function for deleting from the list any pair
   that mentions the expression, either as the label or as the labeled
   expression.
 * Whenever an expression is deleted from the document, call
   `deleteExpression` on it.  This includes when it is deleted in order to
   be embedded as a hidden attribute in something else.
 * Update the specification to state that hidden expressions cannot be the
   targets of labels; only expressions *in the document* can.
 * Whenever a group's contents, attributes, or connections change, call
   `deleteExpression` on it, and then `addExpression` on it.  Also, if it is
   a label, call `addExpression` on each expression that it labels.
 * Add a function for looking up a label and receiving a set of pairs as the
   result, those pairs whose label matches the given text.  They should be
   returned in the order in which they appear in the document.
 * Add a function for looking up a label from a certain position in the
   document.  This will call the previous function, then filter its results
   to only those that apply at the point in the document in question.

## Validation

 * Extend the Background Computation module with a convenience function that
   lets us skip the two-step process of `registerFunction`/`addTask`, and
   just provide code to run and the groups on which to run it.  This can use
   the code itself (or a hash thereof) as the name *and* code for the
   function to register, and later to run.  Name this new function
   `addCodeTask`.
 * Write a function `saveValidation` that records validation results into an
   expression.  If it receives `null` as the validation data, it removes any
   validation data that formerly was in the expression.
 * Add to the list of suggested key types on the group context menu "rule."
 * Create a `validate` function that can be applied to any expression, and
   takes a verbosity flag as well.
 * If the expression has no reason attributes, call `saveValidation` on the
   step, with `null`.
 * If the expression has more than one reason attribute, the function
   saves a validation result that explains that this is not permitted (at
   most one reason per step).
 * If the expression's single reason attribute does not name an actual
   reason accessible from that point in the document, the function saves a
   validation result that explains the problem (incorrect reason citation).
 * If the expressions cited by the reason attribute are not rule definitions
   (none of them) then the function saves a validation result explaining
   that exactly one rule must be cited as the reason for a step, but none
   were.
 * If any of the cited rules are invalid, discard them from the list of
   cited rules.  If none remain, the function returns a validation result
   explaining that none of the cited rules were valid.  If more than one
   remain, the function saves a validation result explaining that too many
   rules were cited (at most one per step is allowed).
 * If the unique valid cited rule is not a piece of code, the function
   saves a validation result explaining that Lurch doesn't (yet?) know the
   type of rule cited.
 * If the unique valid cited rule is code in a language other than
   JavaScript, the function saves a validation result explaining that Lurch
   doesn't (yet?) know the language in which the rule is coded.
 * Otherwise, call `Background.addCodeTask` on the code and step in
   question, with a callback that saves the result as the validation result.
 * Whenever an expression attributed by a reason changes, call `validate` on
   it.
 * Whenever a reason attribute changes, call `validate` on its target.
 * Whenever a rule's content changes, call `validate` on all later
   expressions whose reason cites the rule that just changed.

## Dependencies

 * Extend the Background Computation module so that it can accept as
   parameters for a task not only groups in the document, but also groups in
   dependencies.
 * Implement the `saveMetaData` function used by [the Dependencies
   plugin](../app/dependenciesplugin.litcoffee) to export the list of
   labeled, top-level expressions.
 * Implement a handler for `loadMetaData` that calls `import`, as documented
   in that plugin's ["Responsibilities"
   section](../app/dependenciesplugin.litcoffee#responsibilities).
 * Extend the global list of label-labeled pairs to support pairs from
   dependencies.  
 * Implement a handler for `dependenciesChanged` that does these things:
    * Recompute the label-labeled pairs in that global list that come from
      dependencies.
    * Call `validate` again on any expression whose reason cites a rule in a
      dependency.

## Parsing test

Rewrite the following section to more accurately reflect Section 24 of the
specification, then implement it as a module attached to the main Lurch
application, a module that can easily be disabled if we need to redesign it.

 * Create a group type called "category name" that can hold any text.  Its
   tag will always contain the phrase "category name."
 * Create a group type called "category definition."
   * It has an attribute called "definition type" that can be selected with
     the bubble tag context menu, and is one of the following.
     * Built-in types
       * integers base 10
       * real numbers base 10
       * one letter a-z/A-Z
       * (more can be added to this list later)
     * Regular expression
     * Symbol (containing, for example, the infinity symbol or π)
     * Pattern (containing, for example, a non-atomic bubble, or a
       MathQuill instance)
   * Whichever of the above is chosen will be used as the bubble tag
     contents.
   * Choosing any of the options, if the bubble is empty, fills the bubble
     with example content for that definition type.  For built-in types, it
     fills the bubble with a human-readable description of the built-in.
 * Make "category name" groups able to connect by arrows to "category
   definition" groups or "category name" groups, but only up to one target.
 * Create a group type called "name" that can hold any text.
   * Permit it to connect to a "category definition" group, but only up to
     one target.
   * Permit "category type" groups to connect to "name" type groups also,
     but still at most one target.
   * Its tag will behave as follows.
     * If it is not connected to a target, the tag says "name."
     * If it has no category name connected to it, the tag says "operator
       name."
     * If it contains any commas or spaces, the tag says "variable names."
     * Otherwise, it says "variable name."
 * Create a group type called "test" that can hold any text.  Its tag always
   contains the phrase "test."
 * Create a method that computes, for any given "category definition" group,
   a simple representation of what function should be called in a parser
   object to extend it by adding that definition; the result should be JSON.
   * A built-in category definition B modified by a category name N should
     represent the grammar rule N -> B.
   * A regular expression category definition R modified by a category name
     N should represent the grammar rule N -> R.
   * A symbol category definition S modified by a category name N should
     represent the grammar rule N -> S.
   * One category name N1 modified by another N2 should represent the
     grammar rule N2 -> N1.  This is the first rule for which the right-hand
     side is a non-terminal.
   * A pattern category definition P modified by a category name N will
     usually also have other things modifying it.  An optional operator name
     (as a name bubble) can target P; call that bubble O.  Also there may be
     bubble V1 through Vn targeting P, each of type name, specifying which
     identifiers in P are to be seen as placeholders (not literals).  Each
     such Vi should be modified by a category name Ni to give it a type (in
     the sense of grammar non-terminals).  This entire structure should
     represent the grammar rule N -> P', where P' is P with each Vi replaced
     by Ni.  The bubble O will be used to construct an OpenMath symbol used
     when constructing a parse tree, and which will be mentioned in the
     bubble tag for expressions with this operator as their outermost.  Note
     also that each Vi may contain one or more variables.
 * The `contentsChanged` handler for any given group in the document should
   call that function in itself (if it's a category definition group) or (if
   it's not) in any category definition group to which it's connected,
   storing the result as an attribute of the group on which it was called.
 * Create a function that applies any such JSON record of a command to a
   parser object, thus modifying that parser appropriately.
 * Whenever any definition type group in the document has its JSON meaning
   recomputed, loop through all category definition top-level groups in the
   document, doing the following.
   * Before the loop, create a parser P.
   * Upon encountering a category definition group *after* the one that
     changed, apply to it the function that extends P with the meaning of
     that group.
   * Upon encountering a test type group, run P on its contents and place
     the resulting structure within the test type group.
 * Whenever any test type group in the document changes, do the same loop as
   above, but the only test that should be recomputed is the one that
   changed.
 * Create a context menu item in test type groups that allows you to see, in
   a popup window, the parsed structure stored in that group.
 * Add a context menu item in test type groups that allows you to mark a
   test as currently passing.  This takes the currently parsed meaning of
   that group and stores it under a second key, the meaning that *ought* to
   be parsed by that group.  (For later comparison purposes, if input data
   changes, to prevent regression.)
 * Add a context menu item for removing such marks.
 * When writing to a test type group's meaning attribute (or to the
   attribute storing the meaning it ought to have), also mark it with a
   suffix that looks like one of the following.
   * If it has no data stored for what structure it ought to have, mark it
     with a gray question mark.  Hovering the question mark should explain
     this.
   * If the "what ought to be parsed" data matches the data we just parsed
     and are now storing, mark it with a green check box.  Hovering should,
     again, explain this.
   * Mark it with a red check box, and a corresponding hover explanation.

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
   * The "Go online" button will open the document preferences dialog and
     scroll down to/highlight the section about logging into Google Drive.
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

## Tutorials

 * Create a way for users to navigate the pages of a tutorial.  Probably the
   easiest and most flexible way to do this is to make it so that one of a
   document's settings is whether clicking links in it navigates to them.
   (Right now it just puts the cursor in them.)  Enabling such a setting
   then allows the document author full freedom to format the tutorial
   pages however they like, with next/previous/other links wherever they
   want them, looking however they want them to look.
 * Make it so that following such links first prompts you with an "Are you
   sure?" dialog, so that you can save first or optionally open the link in
   a new tab.
 * In such documents, links whose target is not "new window" (as determined
   by the checkbox in the link-editing UI built into TinyMCE) should fetch
   their results using AJAX and load them in the current editor, again after
   prompting with an "Are you sure?" dialog.
 * Now you can create any number of tutorials by simply publishing all the
   pages to the wiki, and having them link to one another in whatever
   configuration you want (linear or otherwise) using absolute URLs.
 * Create an initial Lurch tutorial and post it to the wiki.
 * Create a Help menu item that loads that tutorial.
 * When Lurch launches, pop up a dialog saying that there is a tutorial on
   the Help menu, and they can check the "Don't show again" box if they so
   desire.  Alternately, just flash the Help menu as you do in the demo
   apps.

On a related note, the "Cheatsheets" menu item of the RStudio GUI is an
excellent resource for many users.  It contains links to online PDFs of
one- or two-sided printable, dense reference sheets for common topics in
RStudio.  A similar cheatsheet (or set thereof) could be created about
Lurch.  Consider these topics.

 * The advanced users guide, condensed into a two-sided reference
 * Understanding and dealing with validation messages
 * A reference for each of the built-in libraries

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
excellent for many use cases.  Offline use would still necessitate the
normal app, and this would be tricky to accomplish, because wiki integration
of something that complex will be touchy, but it would be impressive and
intuitive.

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
