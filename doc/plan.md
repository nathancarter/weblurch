
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

## Documenting each demo app better

 * Write a thorough introduction at the top of its source code file.
 * Add a help menu item that opens the demo app's source code file so the
   reader can see the thorough introduction just discussed.
 * Add a help menu item that will open The Tutorial in a new tab.
 * Make the help menu flash when the page is first loaded, until someone
   clicks it, or until a certain amount of time has passed.

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

We may later want to add more load-and-save features, such as Dropbox
integration.  See the following web links for details on how such extensions
could be implemented.

Dropbox:

 * [You can use ready-made open and save dialogs.](
   https://www.dropbox.com/developers/dropins)
   This is minimally invasive, but does not allow you to upload files from
   the browser's LocalStorage (at the time of this writing).  Rather, it
   only permits uploading files from the user's hard drive.
 * [You can store tables that are a JSON-SQL hybrid.](
   https://www.dropbox.com/developers/datastore)
   This is quite general, but also comes with increased complexity over
   the previous option.  It is not, however, really that complex.
 * A bonus on top of the previous bullet point is that
   [recent, bleeding-edge changes in the API](
   https://www.dropbox.com/developers/blog/99/using-the-new-local-datastores-feature)
   make it possible to use one codebase for both local storage and Dropbox
   storage, a very attractive option.

Local filesystem:

 * If Dropbox is not used, and thus the user's files are not present on
   their own local machine, provide a way to transfer files from their
   local filesystem to/from the browser's LocalStorage?

Sharing:

Add the ability to share documents with the world.  I considered
[Firebase](https://www.firebase.com/), but it seemed like too much work, and
requires integrating a whole new technology.  If using Dropbox, we might be
able to make files shared, if the API supports that.  But that, too,
introduces new sources of complexity, and requires users to get Dropbox.  So
I have the following recommended solution.
 * Create a wiki on `lurchmath.org` into which entire Lurch HTML files
   can be pasted as new pages, but only editable by the original author.
   This way instructors can post on that wiki core dependencies that
   anyone can use, and the integrity of a course (or the whole Lurch
   project!) is not dependent on the state of any individual's Dropbox
   folder.  [MediaWiki](https://www.mediawiki.org/) is obviously robust and
   popular.
 * Note that external websites are not an option, since `XMLHttpRequest`
   restricts cross-domain access, unless you run a proxy on `lurchmath.org`
   or set up CORS rules in the web server running there.  Thus we must host
   the webLurch application and the wiki on the same domain,
   `lurchmath.org`.  This is even more true since many of the improvements
   suggested below require wiki extensions to access the same `LocalStorage`
   object that the webLurch app itself is accessing, which requires them to
   come from the same domain.
 * Write a plugin for the wiki that can access the same LocalStorage
   filesystem that Lurch does, and can pop up dialogs with all your Lurch
   documents.  Just choose one and the wiki will paste its content cleanly
   into the page you're editing, or a new page, your choice.  It's possible
   that this may not need to be a wiki plugin, but could be accomplished
   with only a link in the wiki navigational pane.
 * Similarly, that same wiki plugin could be useful for extracting a copy of
   a document in a wiki page into your Lurch filesystem, for opening in the
   Lurch app itself thereafter.
 * Make the transfer from the wiki to Lurch even easier by providing a
   single "Open in Lurch" button in the wiki that opens Lurch in a new tab,
   then sends it the document using [`window.postMessage()`](
   http://davidwalsh.name/window-postmessage).  The Lurch app should listen
   for such messages and load their contents into the editor.
 * Make the transfer from Lurch to the wiki even easier as follows:
   * Set up permissions on the wiki so that users who create accounts cannot
     edit much of anything, except pages in a folder whose name equals their
     username.  Permissions to edit the main wiki pages will be restricted
     to project leaders.
   * Add a Lurch setting for specifying the user's wiki username, so that
     Lurch knows where to post their files when they ask it to do so.
   * Provide a single button in Lurch that will export to the wiki in one
     click, as follows.
     * If the user has not yet set a wiki username in their Lurch settings,
       pop up an alert to that effect and do not proceed.
     * Pop up an alert that the user must be already logged into the wiki
       for this to succeed, with a "Don't show this message again" checkbox.
     * Create a wiki page name for posting as follows.  Call the user's wiki
       username W, and the name of the file F, then the page name is W_F,
       where any underscores in F are escaped.
     * At first, dump that path to the console and stop.  Then replace that
       with a full implementation that uses the MediaWiki API as follows.
   * How to post a new version of a page to MediaWiki with a JavaScript API:
     * Use the lightweight JS API for MediaWiki [from this GitHub
       repository](https://github.com/brettz9/mediawiki-js).
     * Run a query to get an edit token, as in the example shown in [this
       documentation](https://www.mediawiki.org/wiki/API:Tokens#Example).
       Pop up an error dialog if the response isn't of the correct format.
     * Post the new page content using that edit token.  This is a little
       complicated.  See the [documentation
       here](https://www.mediawiki.org/wiki/API:Edit#Editing_pages) and
       [examples
       here](https://www.mediawiki.org/wiki/API:Edit#Editing_via_Ajax).
       It seems you will need to pass these parameters:
       * `title` - title of page to edit, W_F from above
       * `section` - do NOT provide this, because you're editing the whole
         page
       * `text` - new content, as HTML (I think??)
       * `token` - edit token from previous step
       * `md5` - optional, for additional data integrity check, the MD5 hash
         of the `text` parameter
       * `contentformat` - should be "text/x-wiki"
       * `contentmodel` - should be "wikitext"
     * Pop up a dialog telling the user whether the edit was successful or
       not (based on the response from the API call above) and providing a
       link for them to view the published version in a new window.

### Making things more elegant

 * Eventually, pull the LoadSave plugin out into its own repository on
   GitHub, so that anyone can easily get and use that TinyMCE plugin, and
   improve on its code.

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

Suggestion from Dana Ernst: I’ve been having my students type up their
homework using writeLaTeX.  One huge advantage of this is that students can
share their project with me.  This allows me to simultaneously edit their
document, which is a great way for me to help students debug.  I give them a
ton of help for a week or two and then they are off and running on their
own.  It might be advantageous to allow multiple users to edit the same
Lurch document.  No idea if this is feasible or not, nor if it is even an
idea worth pursuing.

If we have the wiki integration as [described
above](#extending-load-and-save), is it possible for the entire Lurch app to
exist inside the wiki, so that editing a wiki page was done using Lurch as
the editor?  That would be excellent for many use cases.  Offline use would
still necessitate the normal app, and this would be tricky to accomplish,
because wiki integration of something that complex will be touchy, but it
would be impressive and intuitive.

A web Lurch is trivially also a desktop Lurch, as follows.  You can, of
course, write a stupid shell app that’s just a single web view that loads
the Lurch web app into it.  This gives the user an app that always works
offline, has an icon in their Applications folder/Start menu, etc., and
feels like an official app that they can alt-tab to, etc., but it’s the
exact same web app, just wrapped in a thin desktop-app shell.  You can then
add features to that as time permits.  When the user clicks “save,” you can
have the web app first query to see if it’s sitting in a desktop-app
wrapper, and if so, don’t save to webstorage, but pop up the usual save box.
same for accessing the system clipboard, opening files, etc., etc.  And
those things are so modular that a different person can be in charge of the
app on different platforms, even!  E.g., someone does the iOS app, someone
does the Android app, and someone does the cross-platform-Qt-based-desktop
app.  Also, there are toolkits that do this for you.  Here are some links.
 * [Node-WebKit](https://github.com/rogerwang/node-webkit)
 * [PHP Desktop](https://code.google.com/p/phpdesktop/)
 * [Webapp XUL Wrapper](https://github.com/neam/webapp-xul-wrapper)
 * [Atom Shell](https://github.com/atom/atom-shell/) which seems to be like
   Node-WebKit, except it's Node-Chromium
 * See more information in [this blog post](http://blog.neamlabs.com/post/36584972328/2012-11-26-web-app-cross-platform-desktop-distribution).

### Improving documentation

Documentation at the top of most unit test spec files is incomplete. Add
documentation so that someone who does not know how to read a test spec file
could learn it from that documentation.  Probably the best way to do this is
to add general documentation to the simplest/main test spec, and then
reference that general documentation from all other test specs.
