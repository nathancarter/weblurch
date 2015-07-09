
# Project Plan

Readers unfamiliar with this project may wish to first read what's already
been accomplished, on the [Project Progress](progress.md) page.  This page
is a complement to that one, stating what remains to be done.

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

## Matching Module

 * Extend Match's `set(k,v)` member as follows:
   * It should begin by making a backup copy of `@map`.
   * Then write into `@map` the `k,v` pair.
   * For each key in the map, classify it as one of these three things:
     * in a cycle of metavariables that form an equivalence class under
       instantiation -- with these, do nothing
     * divergent, meaning that repeated applications of the map to `v` grow
       without bound on the number of nodes -- if there are any of these,
       destroy the new map, restore the backup copy, and return false to
       indicate failure
     * neither of the previous two -- with these, repeatedly apply the map
       to `v` until you reach a fixed point, and use that as the new `v`
   * Return true to indicate success.
 * Use unit test to debug the above changes.
 * Extend `matches` to expect that the expression may contain metavariables,
   as follows.
   * Comparing nonatomic to nonatomic proceeds recursively, as now.
   * Comparing atomic non-metavariable to nonatomic proceeds by `trySubs()`,
     as now.  This is true regardless of which is which, pattern vs.
     expression.
   * Comparing atomic non-metavariable to atomic non-metavariable proceeds
     by direct equality or resorting to `trySubs()`, as now.
   * Comparing metavariable to anything proceeds as follows, regardless of
     whether the metavariable is the pattern or the expression.
     * If the metavariable has an instantiation, recursively match it
       against the other side and return that result, just as we do now.
       Keep the two arguments (pattern and expression) in the same order.
     * Try to call `set` to mark the metavariable as being instantiated with
       the other expression.  If `set` returns false, then return
       `trySubs()`.
     * Since the call to `set` succeeded, return `[ soFar ]`, as now.
 * Use unit tests to debug the above changes.
```
    a(X,X(Y))[M~N]     a(b,b(c,d,e))      [ { X : b,
                                              Y : unused_1,
                                              M : b(unused_1),
                                              N : b(c,d,e) },
                                            { X : b,
                                              Y : unused_1,
                                              M : a(b,b(unused_1)),
                                              N : a(b,b(c,d,e)) } ]
```
 * Rework `trySubs()` so that it is not called only if a match fails.  It
   should be used to add alternate matches to every single return value for
   every match.  For this reason, it does not actually need to walk up the
   parent chain, because the recursion will do that automatically.  The
   recursive call to `matches` should not bias things by using the same
   `soFar` that was manipulated in the failed attempt to complete it; keep
   a copy of `soFar` as it was given to the current `matches` call and use
   that.  This will also return more general results in some cases.  For
   instance, the test given above should now give the following result
   instead of its too-specific one.
```
    a(X,X(Y))[M~N]     a(b,b(c,d,e))      [ { X : b,Y:unused_1,
                                              M : b(unused_1),
                                              N : b(c,d,e) },
                                            { X : unused_1,
                                              Y : unused_2,
                                              M : a(unused_1,
                                                    unused_1(unused_2)),
                                              N : a(b,b(c,d,e)) } ]
```
 * Ensure that the above changes cause the final tests in the "harder
   substitution situations" section to pass.  Add some more complex tests of
   that same ilk to be sure.
 * Add tests to verify that if you try to put more than one substitution
   expression into a pattern (whether nested or not) an error is thrown.
 * Also verify that if there are metavariables in the expression, that an
   error is thrown.
 * Remove `app/openmath.duo.litcoffee` from git control in master.  Ensure
   that it remains under git control in gh-pages.  Furthermore, ensure that
   `app/matching.duo.litcoffee` does not go under git control in master, but
   does in gh-pages.

## Example Applications

### OpenMath Content Dictionary Authoring Application

Necessary next steps:

 * Add a handler to each XML tag that takes the XML after it's been
   generated from a group and manipulates it as it sees fit.  (The group is
   also passed.)  Use this for:
   * Wrapping OMOBJs that sit in a CDDefinition in an FMP.
   * Replacing MathematicalProperty tags with either FMP or CMP, depending
     on whether they contain OMOBJs or not.
 * Add support for each bubble to show its groupers differently at each
   moment.  This should be do-able with a simple `Group` class member that
   sets the open or close grouper appearance to the given HTML.  It can be
   implemented using code as simple as the following.
```
base64URLForBlob svgBlobForHTML( html ), ( base64 ) ->
   img.setAttribute 'src', base64
```
 * Write a function that can check a given Group to see if it "follows all
   the rules."  It should, at first, just check to be sure that the Group's
   parent tag is on its list of "belongsIn" (if such a list exists;
   otherwise the group can be anywhere).  If the check passes, set the
   Group's close grouper to be the ordinary close grouper for the type.  If
   it fails, set it to be the same thing, plus a red X, with alt text that
   explains the reason for the failure.  Test this by manually calling it
   from the console.
 * Update the `contentsChanged` event for the one Group type to call the
   rule-checking function on the Group.
 * Add a tag attribute "unique" that means that only one Group with that tag
   can exist inside its parent Group.  Support this by making the
   rule-checking function verify that no earlier sibling has the same tag.
   Ensure this is called when necessary by having the `contentsChanged`
   handler not only recheck the changed group, but all later siblings as
   well.
 * Add a tag attribute "belongsAfter" that functions exactly like
   "belongsIn" but examines the previous sibling rather than the parent.
   A Group can also pass this check if this attribute is not set, or if the
   list contains `null` and the Group has no previous sibling.
 * Add a tag attribute "contentCheck" that is a function that will be called
   on a group during the rule-checking function, as the last step in
   validating the Group.  It can do anything, and must either return true
   (meaning the check passes) or an error message (meaning that it does
   not).  The error message, if any, will be used as the alt text for the
   red X in the close grouper.  This feature can be used to check text
   format of leaf groups, or complex structure of non-leaf groups.
 * Write a function that lists the tags that can appear in a parent of a
   given tag type.  It will need to invert the "belongsIn" relation to give
   its results.
 * Use the function created in the previous bullet point to create a submenu
   of the context/tag menu that lets you change a tag of one type to an
   entirely different type.  Types that aren't permitted at that point are
   grayed out (disabled).  See roughly lines 1127-1164 of
   [groupsplugin.litcoffee](../app/groupsplugin.litcoffee) for code on how
   to create arbitrary context menus.  The code
   [here](http://stackoverflow.com/a/17213889/670492) shows that any item
   on the list can have a "menu" key which points to another array of items,
   thus creating a submenu.

Optional next steps, that can be saved for later:

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

### General documentation

Create a tutorial page in the repository (as a `.md` file) on how the reader
can create their own webLurch-based applications.  Link to it from [the main
README file](../README.md).

That is the last work that can be done without there being additional design
work completed.  The section on [Dependencies](#dependencies), below,
requires us to design how background computation is paused/restarted when
things are saved/loaded, including when they are dependencies.  The section
thereafter is about building the symbolic manipulation core of Lurch itself,
which is currently being redesigned by
[Ken](http://mathweb.scranton.edu/ken/), and that design is not yet
complete.

## Miscellany

Future math parsing enhancements:
 * Support adjacent atomics as factors in a product
 * Support chained equations
 * Add tests for things that should *not* parse, and verify that they do not

Improve build process to not compile files whose dates indicate that they
do not need it, nor to minify files whose dates indicate that they do not
need it.

Several new methods have been added to the Groups Plugin without unit tests
being written for them.  Be sure to look back through the full list of
functions in that file and find those which have no unit tests, and create
unit tests for them, debugging the functions as you do so.

## Logical Foundation

### Dependencies

This section connects tightly with [Extending load and
save](#extending-load-and-save), below.  Be sure to read both together.
Also, this will need to be extended later when enhancing Lurch to be usable
offline; see [Offline support](#offline-support), below.

 * Reference dependencies by URLs; these can be file:/// URLs, which is a
   reference to LocalStorage, or http:// URLs, which is a reference to
   `lurchmath.org`.
 * Provide a UI for editing the dependency list for a document.  Store this
   data outside the document.
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

## Real Lurch!

Build the 3 foundational Group types, according to Ken's new spec!

## For later

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
   folder.
 * Note that external websites are not an option, since `XMLHttpRequest`
   restricts cross-domain access, unless you run a proxy on `lurchmath.org`
   or set up CORS rules in the web server running there.  Thus we must host
   the webLurch application and the wiki on the same domain,
   `lurchmath.org`.  This is even more true since many of the improvements
   suggested below require wiki extensions to access the same `LocalStorage`
   object that the webLurch app itself is accessing, which requires them to
   come from the same domain.
 * This could be even better as follows:
   * Write a plugin for the wiki that can access the same LocalStorage
     filesystem that Lurch does, and can pop up dialogs with all your
     Lurch documents.  Just choose one and the wiki will paste its
     content cleanly into the page you're editing, or a new page, your
     choice.
   * Similarly, that same wiki plugin could be useful for extracting a
     copy of a document in a wiki page into your Lurch filesystem, for
     opening in the Lurch app itself thereafter.
   * Make the transfer from Lurch to the wiki even easier by providing a
     single button in Lurch that exports to the wiki in one click, using
     some page naming convention based on your wiki username and the
     local path and/or name of the file.  Or perhaps, even better, you
     have a public subfolder of your Lurch filesystem that's synced, on
     every document save or Manage Files event, to the wiki, through
     `XMLHttpRequest` calls.
   * Make the transfer from the wiki to Lurch even easier by providing a
     single "Open in Lurch" button in the wiki that stores the document
     content in a temporary file in your Lurch filesystem, then opens
     Lurch in a new tab.  The Lurch app will then be smart enough to
     open any such temporary file on launch, and then delete it (but the
     user can choose to save it thereafter, of course).

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
