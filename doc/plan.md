
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

## Arrows among groups

Add to the Group class the following two functions for use by LAs.  When
bubbles are edited, if the contents must be kept in sync with the arrows,
the LA can manipulate the arrows to fit the contents using these functions.
Or the LA can use these functions to create arrows based on other UI events
in the first place.
 * `group.connect( otherGroup, optionalTag )`
   * `optionalTag` is treated as a string, and defaults to the empty string
   * Constructs the array `[group.id(),otherGroup.id(),tag]` and adds it
     to the set of links in each group.  If such a link already exists, do
     not add it again; the set of links is indeed a set.
   * Link sets should be stored as group properties, modified via
     `group.set()`, so that changing them triggers group updates.
 * `group.disconnect( otherGroup, optionalTag )`
   * `optionalTag` is treated as a string, and defaults to the empty string,
     unless it is a regular expression
   * Finds all arrays of the form `[group.id(),otherGroup.id(),T]` stored in
     the link sets of `group` or `otherGroup`, and removes them, where T is
     either equal to `optionalTag` if `optionalTag` is a string, or matches
     `optionalTag` if `optionalTag` is a regular expression.
 * `group.connectedTo()` returns the set of triples in this group's link set
   that begin with its own ID, that is, those links that lead outward.
 * `group.connectedFrom()` is the dual of the previous.

Update the way groups are drawn as follows.
 * Draw a background for only the innermost nested group, not its ancestors.
 * Draw a light background for the group over which the mouse pointer is
   hovering, at all times.
 * Just as `drawGroups` respects `group.type.color` and
   `group.type.tagContents`, it should also respect
   `group.type.connections`, which will return an array of links (triples)
   and other groups (Group instances) to be drawn whenever this group is the
   innermost one containing the cursor.  For now, just call this function
   and dump its results to the console.  Provide a default implementation
   that returns `group.connectedTo()` plus all the targets of those links.
   (The real Lurch LA may provide a way to toggle between this and its dual,
   to see how the current statement sits in the logical flow before and
   after it in a proof.)
 * Implement half of the support for `group.type.connections` by drawing the
   outlines of all groups on the resulting list.
 * Implement the next quarter of the support for `group.type.connections` by
   drawing arrows from the source group to the target groups.
 * Complete the implementation of `group.type.connections` by adding labels
   to the arrows by using the tags.  Note that `group.type.connections` is
   free to translate the tags as part of its computation, so that their
   internal and external representations need not be the same.

Create a nice UI for introducing arrows.  It will not be enabled by default,
but can be added by any LA.
 * Provide a function that installs the arrow-creating UI.  This can begin
   as a stub, and be extended with each of the following UI items.
 * Create a toolbar button for entering arrow-creation mode.  At first, just
   make it stay down when pressed, and pop up when pressed again.  It should
   pop up automatically if you exit all bubbles, and should be disabled when
   the cursor is not in any bubbles.
 * In arrow-creation mode, if the user's cursor is in group G and the user
   clicks on bubble H, call `G.type.connectionRequest( H )`, if such a
   function exists.  The LA can handle this as they see fit, such as
   toggling a link, or prompting for a link tag, or anything.
 * Optional feature for later:  Add an option that when entering
   arrow-creation mode, ALL bubble outlines in the document are faintly
   drawn (not their tags), so that it's completely clear where a user wants
   to aim the mouse to hit a certain bubble.
 * Optional feature for later:  Add an optional that show-groupers (Ctrl+1)
   mode is automatically enabled when the user enters arrow-connection mode,
   and re-disabled (if it was disabled in the first place) when exiting
   arrow-connection mode.  This is like the previous feature, but more
   aggressive and techy.  (Do we still need it now that we have the previous
   feature?)
 * Optional feature for later:  On mobile, a tap highlights the innermost
   bubble under it, without creating the arrow yet, and shows OK/cancel
   buttons hovering nearby.  If the user tapped what he/she expected to tap,
   then he/she hits OK and it creates the arrow.  Cancel (or just tapping
   elsewhere) closes the OK/cancel buttons and does nothing else.
 * Optional feature for later:  When in arrow-making mode, keystrokes are
   interpreted as typing bubble labels, which will scroll the view to the
   bubbles with those labels, and highlight them as if the user had
   mouse-hovered them.  If the user presses enter, the arrow will be
   created.  Hence there are keyboard-shortcut ways to specify arrows among
   bubbles.  This would work best with a keyboard shortcut for entering
   bubble-making mode also.  (If there are ambiguous labels--i.e., ones that
   apply to more than one bubble--just choose any one; that's the user's
   fault.)  Note that this requires two additional features to help it out:
   * A function in the group type for computing the default label for any
     bubble in the document.  The default can be the address of the bubble
     in the hierarchy, as a list of positive integers; e.g., the second
     bubble immediate inside the tenth topmost bubble has number 10.2.
   * Drawing bubbles in arrow-creation mode should include these labels
     somewhere nearby.

## Matching Module

The Matching Module may no longer be necessary, if we build Lurch on top of
[Lean](http://leanprover.github.io/).  Therefore these tasks are on hold.

If you end up needing to complete your own Matching Module, rework what you
have now **significantly**, as follows.

 * The matching algorithm should first verify that metavariables appear only
   in the pattern, not the expression.  If they appear in the expression,
   throw an exception.
 * The matching algorithm should proceed as if there are no replacement
   expressions within the pattern, using the ordinary matching algorithm.
   When it encounters a replacement pattern, it should add it to a list of
   "deferred for later" computations, stored in the match object itself.
 * Before returning any match objects, their deferred computations must be
   processed.  Here is the algorithm for doing so on a match object M.
   * Record a copy of the set of deferred computations, for later
     comparison.
   * For each deferred computation C in M:
     * If enough of C's metavariables have been instantiated in M to compute
       the rest, do so.  Here are the possible outcomes:
       * This may reject M:  Return a failure value.  M should then be
         removed from the list of match results from the outer algorithm.
       * There may be multiple matches:  Remove C from M's deferred list,
         and create copies of M, one for each of the matches, extended with
         those matches.  Return that list of copies.  The outer algorithm
         should replace M on its list of results with this new list.  But
         it should not return them yet; each may have deferred computations
         still waiting to be done.
       * There may be one match:  Extend M with that match and proceed with
         the loop, to handle the next deferred computation on the list.
     * Otherwise (not enough of C's metavariables are known) then just move
       on to the next deferred computation on the list.
   * If the set of deferred computations is equal to the recorded copy, then
     no progress has been made.  Throw an error saying that this matching
     problem is outside the capabilities of this algorithm.
   * Otherwise, progress has been made.  So repeat from 3 steps above this
     one, "Record a copy..."
 * Run that algorithm on all existing unit tests, with one of three results:
   * The test passes, and you can move on to the next test.
   * The test fails, but merely due to an output formatting issue, and thus
     the test itself can be tweaked so that it passes.
   * The test fails, but because it throws an error about the test being
     outside the algorithm's capabilities.  Verify yourself that this is so,
     and if it is, change the test to expect such an error to be thrown, and
     thereafter function as a test that the algorithm knows its limits.
   * Any other possibility is a bug that needs to be fixed.
 * Add the following unit tests as well.
```
    a(X,X(Y))[M~N]     a(b,b(c,d,e))      [ { X : b,
                                              Y : unused_1,
                                              M : b(unused_1),
                                              N : b(c,d,e) },
                                            { X : b,
                                              Y : unused_1,
                                              M : a(b,b(unused_1)),
                                              N : a(b,b(c,d,e)) } ]
    a(X,X(Y))[M~N]     a(b,b(c,d,e))      [ { X : b,
                                              Y : unused_1,
                                              M : b(unused_1),
                                              N : b(c,d,e) },
                                            { X : unused_1,
                                              Y : unused_2,
                                              M : a(unused_1,
                                                    unused_1(unused_2)),
                                              N : a(b,b(c,d,e)) } ]
```

## Real Lurch

We are currently considering building webLurch on top of
[Lean](http://leanprover.github.io/), and are designing how we might do so.

## For thereafter

### Dependencies

This subsection connects tightly with the other subsections of this same
section.  Be sure to read them all together.  This one connects most tightly
with the subsection about a wiki.  Also, this will need to be extended later
when enhancing Lurch to be usable offline; see [Offline
support](#offline-support), below.

 * Reference dependencies by URLs; these can be file:/// URLs, which is a
   reference to LocalStorage, or http:// URLs, which is a reference to
   `lurchmath.org`.
 * Provide a UI for editing the dependency list for a document.  Store this
   data in JavaScript variables in the Lurch app.
 * Load/save that metadata using the `loadMetaData` and `saveMetaData`
   members of the LoadSave plugin.
 * Design what you will do when files are opened/closed, re: computation of
   the meaning in them and their dependencies.  Issues to consider:
   * If background computations are pending on a document, should the user
     be permitted to save it?  What if it's used as a dependency elsewhere?
     Will that cause it to be loaded in a permanently-paused-as-incomplete
     state in the other document?
   * Or does that imply that we should recompute lots of stuff about each
     dependency as it's loaded, in invisible DOM elements somewhere?  That
     sounds expensive and error-prone.
   * Knowing whether recomputation is needed could be determined by
     inspecting an MD5 hash of the document to see if it has changed since
     the last computation.  This is what [SCons
     does](http://www.scons.org/doc/0.98.4/HTML/scons-user/c779.html).

### Extending load and save

Sharing

Move all work done in MediaWiki locally in testing form onto a dedicated
host on the Internet.  (This refers to work tested on Nathan's laptop so
far, with notes taken on how to replicate it later, on, for example, a
Linode instance.)

Google Drive also provides a very nice [real time collaboration API](
https://developers.google.com/google-apps/realtime/overview) that makes any
document you like into a Google-Docs-like collaborative model where changes
are auto-synced across collaborators.  This was an idea that Dana Ernst
asked for long ago when he first heard about the webLurch project. Integrate
that into webLurch, imitating the UX Ken describes from typical online
collaboration apps such as Google Docs and Overleaf, as follows.
 * Just a note that none of the changes below impact the wiki import and
   export functionality; that stays as it is now.
 * Before adding Google Drive integration, change the items on the File menu
   to behave as follows.
   * File > New not only does what it does now--creating a new document--
     but it also gives it a default filename (such as `Untitled 1.lurch`)
     and begins autosaving it to the browser's Local Storage very often
     (every few seconds).
   * File > Document properties... will let you change the name of the
     document (as long as you don't already have a document with that name)
     and that will change the filename into which it's autosaved.
   * File > Save and File > Save as... should therefore be removed.
   * File > Open and File > Manage files... can be simplified to not permit
     the creation of folders, so that all of a user's files are just in one
     alphabetical list.
   * Corresponding changes take place in the toolbar.
   * Add File > Download, which starts a download of the file as HTML.
   * Add File > Upload, which lets the user choose an HTML file to upload,
     accepts the upload, strips any dangerous tags from it, then does the
     same thing as File > New, above, before pasting the HTML content
     directly into the new, blank document.
 * Provide a button in the File > Application settings... dialog that users
   can push to initiate Google's authorization UI, thereby giving Lurch
   access to their Google Drive.  When it has been used, replace it with a
   button that de-authorizes webLurch from the user's Google Drive.
 * When a user gives such authorization, the following changes take place at
   once, and persist for the remainder of their use of the webLurch app:
   * All files formerly stored in the browser's Local Storage, if any, are
     automatically imported into Google Drive, and the originals (in Local
     Storage) discarded.  (Space in Local Storage is at a premium.)
   * File > New creates a new realtime-shared file on Google Drive, which
     automatically includes free and constant autosaving.  It will start out
     with some stupid title like "Untitled Document" just as in Google Docs.
     To change this title, use File > Document properties...
   * File > Save and File > Save as... are still gone, as above.
   * File > Open looks in your Google Drive for files to open.
   * File > Manage files... gets replaced by File > Open my Google Drive.
     That is another way to rename any newly-created file.
   * Corresponding changes take place in the toolbar.
 * If a user de-authorizes webLurch from their Google Drive, change the app
   as follows:
   * All entries on the File menu revert to their original behavior.
   * Give the user the option to import back into their browser's Local
     Storage all `.lurch` files currently sitting in their Google Drive,
     before the de-authorization completes.  The files will *not* also be
     deleted from the Google Drive, but the user can do so manually if they
     choose to.

Tutorials

Once the "Sharing" features above have been built (with wiki integration),
we can make Lurch tutorials as follows.
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
 * Make links with protocol "load://" fetch their results from the wiki
   using AJAX and load them in the current editor, again after prompting
   with an "Are you sure?" dialog.
 * Now you can create an number of tutorials by simply publishing all the
   pages to the wiki, and having them link to one another in whatever
   configuration you want (linear or otherwise).
 * Create an initial Lurch tutorial and post it to the wiki.
 * Create a Help menu item that loads that tutorial.
 * When Lurch launches, pop up a dialog saying that there is a tutorial on
   the Help menu, and they can check the "Don't show again" box if they so
   desire.

Eventually, pull the LoadSave plugin out into its own repository on GitHub,
so that anyone can easily get and use that TinyMCE plugin, and improve on
its code.

### Offline support

To make an HTML5 app available offline, I believe the appropriate step is
simply to provide an app manifest.  I'm verifying that with [this
StackOverflow
question](http://stackoverflow.com/questions/27136144/how-can-online-offline-versions-of-an-html5-app-access-the-same-localstorage).
That question links to a tutorial on app manifests, if the answer turns out
to be "yes" to that question.

Once the app is usable offline, it will also be helpful to cache in
LocalStorage the meaning computed from all dependencies, so that Lurch is
usable offline even when dependencies of the current document are online.

### Ideas from various sources

Suggestion from Dana Ernst: Perhaps this is not necessary or feasible, but
if you go with a web app, could you make it easy for teachers to "plug into"
the common LMS's (e.g. Blackboard, Canvas, etc.)?  I'm envisioning students
being able to submit assignments with ease to an LMS and then teachers can
grade and enter grades easily without have to go back and forth between web
pages.  

Is it possible for the entire Lurch app to exist inside MediaWiki, so that
editing a wiki page was done using Lurch as the editor?  That would be
excellent for many use cases.  Offline use would still necessitate the
normal app, and this would be tricky to accomplish, because wiki integration
of something that complex will be touchy, but it would be impressive and
intuitive.

Convert webLurch into a desktop app using
[electron](https://github.com/atom/electron).
This gives the user an app that always works
offline, has an icon in their Applications folder/Start menu, etc., and
feels like an official app that they can alt-tab to, etc., but it’s the
exact same web app, just wrapped in a thin desktop-app shell.  You can then
add features to that as time permits.
 * When the user clicks "save," you can have the web app first query to see
   if it’s sitting in a desktop-app wrapper, and if so, don’t save to
   webstorage, but pop up the usual save box.
 * Same for File > Open.
 * Same for accessing the system clipboard
Similar apps could be created for iOS, Android, etc., but would need to use
tools other than Electron.  These are orthogonal tasks, and need not all be
done by the same developer.

### Improving documentation

Documentation at the top of most unit test spec files is incomplete. Add
documentation so that someone who does not know how to read a test spec file
could learn it from that documentation.  Probably the best way to do this is
to add general documentation to the simplest/main test spec, and then
reference that general documentation from all other test specs.
