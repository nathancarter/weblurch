
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

## Parsing

 * Create a parser that can handle the following types of input, all of
   which were created from MathQuill instances using the function
   `mathQuillToMeaning` in [setup.litcoffee](../app/setup.litcoffee).
   Tasks remaining:
   * Support parentheses and brackets as groupers
   * Support fractions
   * Support square roots
   * Support equality-like relations of all kinds
   * Support the infinity symbol
   * Support exponentiation and radicals (both of which use sup, which may
     require adjusting `mathQuillToMeaning`)
   * Support for ln, log, and log-base-b
   * Support the `\pm` operation
   * Support the units dollars, degrees, percent
   * Support the overline and overarc modifiers
   * Support the therefore symbol
   * Support the "not" symbol
   * Support geometry relations for parallel, perpendicular, and arrows
   * Support geometry operations of angle, measure, triangle, quadrilateral,
     and circle-with-dot
   * Support pairing and interval-forming operations
   * Support absolute values
   * Support trig functions
   * Support subscripted variables
   * Support factorials
   * Support limits with subscripts
   * Support summations with optional subscripts and superscripts
   * Support differentials (d-then-variable)
   * Support indefinite integrals (not requiring differentials, since it may
     be in a numerator and thus hard to structure correctly)
   * Support definite integrals (same as previous re: differentials
     optional)
```
["3", ".", "1", "4", "1", "5", "9"]
3 . 1 4 1 5 9

["α", "·", "β", "·", "γ", "·", "δ", "·", "θ", "=", "π"]
α · β · γ · δ · θ = π

["a", "+", "b", "−", "c", "×", "d", "÷", "√", "fraction", "(", "e", "(", "ƒ", "sup", "g", ")", ")", "=", "h", "≈", "i"]
a + b − c × d ÷ √ fraction ( e ( ƒ sup g ) ) = h ≈ i

["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "π", "−", "i", "+", "fraction", "(", "e", "∞", ")"]
0 1 2 3 4 5 6 7 8 9 + π − i + fraction ( e ∞ )

["overline", "x", "±", "y", "·", "fraction", "(", "z", "w", ")", "+", "$", "3", "0", "+", "3", "0", "sup", "∘", "+", "3", "0", "%"]
overline x ± y · fraction ( z w ) + $ 3 0 + 3 0 sup ∘ + 3 0 %

["a", "sup", "b", "√", "c", "sup", "3", "√", "d", "sup", "e", "√", "ƒ", "e", "sup", "g", "ln", "h", "log", "i", "log", "sub", "j", "k"]
a sup b √ c sup 3 √ d sup e √ ƒ e sup g ln h log i log sub j k

["a", "=", "b", "≠", "c", "∼", "d", "¬", "∼", "e", "g", "≈", "h", "¬", "≈", "i", "≤", "j", "≥", "k", "≃", "l", "¬", "≃", "m", "∴", "o"]
a = b ≠ c ∼ d ¬ ∼ e g ≈ h ¬ ≈ i ≤ j ≥ k ≃ l ¬ ≃ m ∴ o

["A", "→", "overline", "B", "↔", "overarc", "C", "∥", "D", "⊥", "∠", "E", ">", "m", "∠", "A", "+", "△", "A", "B", "C", "+", "▱", "A", "B", "C", "D", "⊙", "2"]
A → overline B ↔ overarc C ∥ D ⊥ ∠ E > m ∠ A + △ A B C + ▱ A B C D ⊙ 2

["(", "1", "+", "2", ")", "−", "[", "3", "+", "4", "]", "·", "|", "fraction", "(", "5", "6", ")", "|", "+", "(", "x", ",", "y", ")", "+", "[", "x", ",", "y", "]", "+", "(", "x", ",", "y", "]", "+", "[", "x", ",", "y", ")"]
( 1 + 2 ) − [ 3 + 4 ] · | fraction ( 5 6 ) | + ( x , y ) + [ x , y ] + ( x , y ] + [ x , y )

["sin", "cos", "tan", "x", "+", "sec", "csc", "cot", "y", "=", "sin", "sup", "(", "−", "1", ")", "cos", "sup", "(", "−", "1", ")", "tan", "sup", "(", "−", "1", ")", "z", "+", "sec", "sup", "(", "−", "1", ")", "csc", "sup", "(", "−", "1", ")", "cot", "sup", "(", "−", "1", ")", "w"]
sin cos tan x + sec csc cot y = sin sup ( − 1 ) cos sup ( − 1 ) tan sup ( − 1 ) z + sec sup ( − 1 ) csc sup ( − 1 ) cot sup ( − 1 ) w

["fraction", "(", "μ", "σ", ")", "+", "overline", "x", "·", "overline", "y", "+", "x", "sup", "i", "−", "x", "sub", "i", "+", "x", "!", "=", "Σ"]
fraction ( μ σ ) + overline x · overline y + x sup i − x sub i + x ! = Σ

["∫", "x", "d", "x", "=", "∫", "sub", "a", "sup", "b", "fraction", "(", "d", "(", "d", "x", ")", ")", "u", "=", "lim", "sub", "(", "x", "→", "∞", ")", "∑", "sub", "(", "i", "=", "1", ")", "sup", "n", "t", "sup", "∞"]
∫ x d x = ∫ sub a sup b fraction ( d ( d x ) ) u = lim sub ( x → ∞ ) ∑ sub ( i = 1 ) sup n t sup ∞
```

## Example Application

Create a tutorial page in the repository (as a `.md` file) on how the reader
can create their own webLurch-based applications.  Link to it from [the main
README file](../README.md).

It might be nice to have another example application, this one that lets you
write math formulas in ordinary mathematical notation, and then does simple
computations based on them, using MathJS.  You would need a method for
converting OpenMath trees into MathJS calls.

That is the last work that can be done without there being additional design
work completed.  The section on [Dependencies](#dependencies), below,
requires us to design how background computation is paused/restarted when
things are saved/loaded, including when they are dependencies.  The section
thereafter is about building the symbolic manipulation core of Lurch itself,
which is currently being redesigned by
[Ken](http://mathweb.scranton.edu/ken/), and that design is not yet
complete.

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
