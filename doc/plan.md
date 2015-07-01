
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

 * Larger bug fix
   * Ensure that `trySubs()` does not permit a substitution unless the new
     value is free to replace the old at that location.
   * Ensure that the checks in lines 440-480 proceed as follows:  Create a
     list of final results and initialize it to empty.  Then loop through
     the existing matches and do the following for each:
     * If its LHS has any uninstantiated metavariables, the check passes for
       that result, because unused_N variables will ensure that it is
       irrelevant, and thus does not harm the match results.
     * Compute the list of descendants of the instantiated pattern
       satisfying these criteria:
       * They contain no metavariables
       * They are free at their position in the instantiated pattern.
     * For each such descendant, compute its address, then compute the
       subexpression of `expression` having the same address.  Call this
       list E_1,...,E_n.
     * Recur, matching the tuple `[E_1,...,E_n]` against the tuple
       `[rhs,...,rhs]`, that is, n copies of the instantiated RHS of the
       substitution.
     * With each result R in the list returned by that recursion, do this:
       * Re-instantiate the substitution RHS with this (expanded) match R.
       * If that instantiated version is free to replace every one of the
         E_i, then push R onto the list of final results.
     * Return the list of final results.
   * Check to ensure that all existing tests pass, and debug.
 * More tests
   * Create unit tests for all the unusual invalid uses of quantifier rules
     stored in the Overleaf document shared between Nathan and Ken.
   * Create unit tests between things like `f(X,X)[c=d]` and `f(g(d),g(c))`,
     and all the tons of variations you can think of on that theme.
 * Complete the unit tests for the matching algorithm.  Some are already
   complete, but those listed below remain to be implemented.
   I list an extensive test suite here, using capital letters for
   metavariables and lower case letters for regular variables, and otherwise
   easily human-readable/suggestive notation.  The one exception is that @
   means the universal quantifier and # means the existential quantifier.
```
    pattern             expression      results
    -------             ----------      -------

    HARDER SUBSTITUTIONS

    Now we list pattern, expresion, and results, as at first.

    a=b[X=Y]            a=b             [{X:unused_1,Y:unused_2}]
    a=b[X=a]            a=b             [{X:unused_1}]
    a=b[a=Y]            a=b             [{Y:a}]
    a=b[a=b]            a=b             []
    a=b[a~b]            a=b             [{}]
    a=b[a=c]            a=b             []
    a=b[a~c]            a=b             [{}]
    a=b[a=a]            a=b             [{}]
    A[a=b]              a=b             []
    A[a~b]              a=b             [{A:a=b}]
    A[c=b]              a=b             [{A:a=b}]
    A[c~b]              a=b             [{A:a=b}]
    A[B=b]              a=b             [{A:a=b,B:unused_1}]
    A[B~b]              a=b             [{A:a=b,B:unused_1}]
    f(f[A=g])           f(g)            [{A:f}]
    f(f)[A=g]           g(g)            [{A:f}]
    f(f[A=g])           g(g)            []
    f(g(a))[A=B]        f(g(b))         [{A:a,B:b}]
    f(g(a),a)[A=B]      f(g(b),a)       []
    f(g(a),a)[A~B]      f(g(b),a)       [{A:a,B:b}]
    f(g(a),a)[A=B]      f(g(b),c)       []
    f(g(a),a)[A~B]      f(g(b),c)       []
        previous four cases repeated, but with first and second arguments
        in both the pattern and the expression interchanged should give same
        results

    UNDERSPECIFIED

    A[B=C]              any(thing)      [{A:any(thing),B:unused_1,
                                          C:unused_2}]
    A[B~C]              any(thing)      [{A:any(thing),B:unused_1,
                                          C:unused_2}]

    Also verify that if there are metavariables in the expression, that an
    error is thrown.
```
 * Add tests to verify that if you try to put more than one substitution
   expression into a pattern (whether nested or not) an error is thrown.
 * Remove `app/openmath.duo.litcoffee` from git control in master.  Ensure
   that it remains under git control in gh-pages.  Furthermore, ensure that
   `app/matching.duo.litcoffee` does not go under git control in master, but
   does in gh-pages.

## Parsing

 * Import the Earley parser from the desktop version of Lurch, into the file
   `src/parsing.duo.litcoffee`.
 * Document it, while creating unit tests for its features.
 * Create a routine that translates MathQuill DOM trees into unambiguous
   string representations of their content (using parentheses to group
   things like exponents, etc.).
 * Use the web app to create and save many example DOM trees using the
   MathQuill TinyMCE plugin, for use in unit tests.
 * Manually convert each of those into unambiguous strings, and use those to
   generate unit tests for the translation routine created above.
 * Create a parser that can convert such strings into OpenMath trees.
 * Convert all the previous tests into unit tests for that parser.

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
