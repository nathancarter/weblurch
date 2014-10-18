
# Project Plan

Readers unfamiliar with this project may wish to first read what's
already been accomplished, on the [Project Progress](
progress.md.html) page.  This page is a complement to that one,
stating what remains to be done.

This document aims to be a complete plan for what needs to be done
on this project, readable by developers.  It can therefore be
viewed as a to-do list in chronological order, the first items
being those that should be done next, and the later items those
that must come after.  Necessarily, the later items are more vague
than the earlier ones.

## Reworking this whole repository

### Cleanup

 * In the master branch, clear out all the following stuff.
   * everything in `src/` except `utils` and `domutils`
   * everything in `test/` except `utils-spec` and `domutils-spec`,
     including the `histories` subfolder
   * `app/app.litcoffee` and possibly `app/appsetup.litcoffee`,
     but first figure out which of them, if either, is built by the
     build process
   * `testapp` folder, plus any reference to it in the build
     proces
   * `doc/wp-spec.md` and `doc/test-app-help.md`
   * `bootstrap` folder
 * Make significant revisions to anything remaining in `doc/`.
 * See what tests now fail and clean them up.
 * Regenerate gh-pages.

### New tools

 * Import jQuery and TinyMCE into the respository.
 * Include jQuery and TinyMCE scripts into the main app.
 * Create a setup function in the main app that installs TinyMCE
   and makes it full-screen, with appropriate buttons and plugins.

## Load and save

 * Before executing any of the tasks in this section, first look
   ahead to the [Dependencies](#dependencies) section, below.  It
   has requirements that will require you to be careful *here*
   about your design decisions.  Ensure that a sensible design for
   loading, saving, sharing, and dependency loading is in place
   before proceeding to implement any of the load/save features in
   this section.
 * Research the notion of using Dropbox as a data storage
   location; it may impact how you proceed with the other tasks in
   this section, below.  Here are some details:
   * [You can use ready-made open and save dialogs.](
     https://www.dropbox.com/developers/dropins)
     This may be the best for us, since it's minimally invasive
     and may handle what we need.  Not sure how it would work with
     (a) the settings file or (b) dependencies.
   * [You can store tables that are a JSON-SQL hybrid.](
     https://www.dropbox.com/developers/datastore)
     This is quite general, but also comes with increased
     complexity over the previous option.  It is not, however,
     really that complex.
   * A bonus on top of the previous bullet point is that
     [recent, bleeding-edge changes in the API](
     https://www.dropbox.com/developers/blog/99/using-the-new-local-datastores-feature)
     make it possible to use one codebase for both local storage
     and Dropbox storage, a very attractive option.
 * Implement the following needs.
   * The main app must be able to load and save documents at least
     locally (e.g.,
     [Web Storage](http://www.w3schools.com/html/html5_webstorage.asp))
     but preferably everywhere (e.g., Dropbox, as described above)
   * If Dropbox is not used, and thus the user's files are not
     present on their own local machine, provide a way for the
     user to load/save files into/out of web storage?
 * Add the ability to share documents with the world, using
   something like [Firebase](https://www.firebase.com/), or making
   Dropbox files shared, if the API supports that.
 * Make there be a way to share files as webpages as well,
   read-only pages that contain full meaning information.  This way
   instructors can post on their websites (or Lurch can post on its
   project web space) core dependencies that anyone can use, and
   the integrity of a course (or the whole Lurch project!) is not
   dependent on the state of any individual's Dropbox folder.

## Extending the Editor

### Overlay plugin

 * Create an overlay plugin for TinyMCE that installs (and can
   later fetch) the overlay canvas.  Use it in the main app.

### Groups plugin

 * Create a Groups plugin
   * It should let you register any type of Group.
   * It should provide a function for inserting open/close pairs,
     and easy ways to create buttons and menu items for calling
     that insertion function.  (Use classes to distinguish open
     and close groupers.)
   * Give every matching pair of groupers a unique number at
     insertion time, stored in their ids, as in `id='open3'` and
     `id='close3'`, for example.
   * Create a `Group` class with the following features.
     * integer id number
     * array of child Groups
     * pointer to parent Group, if any
     * open and close groupers (DOM elements)
   * Add a class method that scans the document, indexing all pairs
     of groupers, in order, deleting each that doesn't match up
     with a same-numbered partner.  From those that remain, build
     a hierarchy stored in a class member `Group.tree`, as an array
     of `Group` object instances.
   * Call that scanning routine after each document change.
   * Extend the scanning routine to also map all Group id numbers
     to the object instances, and keep that mapping within the
     Group class itself, as in `Group[7]`
   * Write a class method `Group.numbers()`, which returns a list
     of all id numbers that appear in `Group.tree`.  They should
     appear in tree order.  It should cache its results and only
     invalidate the cache when the scanning routine is re-run.
   * The plugin should provide a function for hiding/showing Group
     boundaries, and a keyboard shortcut for it.
   * The plugin should use the overlay plugin to draw bubbles
     around Groups if and only if the cursor is inside them.
   * Create an easy way to find the deepest Group surrounding any
     DOM Node.
   * Make Group insertion only available when the base and anchor
     of the selection are in the same Group.
   * Extend the `Group` class with a way to get/set arbitrary data
     on a Group as key-value pairs stored in the element
     attributes.

### Events

 * Create a generic event system that can fire events and hear the
   collected responses from their event listeners.  You may be
   able to re-use one from the browser's JavaScript environment,
   or re-use the handlers package from the original Lurch; it is
   less than 150 lines of code, including comments.
 * Create a `groupContentsChanged` event and fire it whenever the
   inside of a group is edited by the user, or any code writes to
   the Group's properties using the Group API.
 * Create a `groupTagRequested` event, and use it as follows.
   * When planning to draw bubbles, fire this event for each Group
     containing the cursor.
   * Cache the aggregated results from any listeners in the Group.
   * Clear that cache on `groupContentsChanged` for the group or
     any of its parents.
   * Draw such labels above the bubbles.
   * Extend that algorithm so that labels never collide, as in the
     current Lurch.
 * Create a `groupMenuRequested` event, and use it as follows.
   * When the user right-clicks inside the group, fire this event
     and use the aggregated results from any listeners to extend
     the context menu that's shown.
   * When the user clicks inside the bubble tag, do the same.
 * Create a `groupAdded` event and fire it when inserting new
   Groups.
 * Create a `groupDeleted` event and fire it when processing the
   whole document and updating the cache of Group data, for any
   Group that has simply disappeared, or that half-disappeared and
   we were forced to remove the remaining, unmatched grouper.

## Background processing

Import [this polyfill](https://github.com/oftn/core-estimator)
for estimating the optimal number of cores for use by background
threads.

Build a BackgroundComputation class with the following API.
 * There is one function to enqueue a computation based on the
   name of the background function to be called, and the list of
   groups to use as arguments.
 * The first implementation can simply be single-threaded, by
   using `setInterval` and dequeueing a new task every so often,
   if and only if the previous one has completed.

Build a BackgroundFunction class with the following API.
 * One can register new functions to be run in the background,
   by mapping any string name to any JS function.  This is a class
   method.
 * One can create new instances of BackgroundFunction objects by
   calling a constructor and passing the name of a previously-
   registered function.  This should create a web worker that has
   the following capabilities.
   * It has the registered function precompiled into the worker.
     Be sure to use the [Function constructor](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function)
     to build the function on the worker side, because it compiles
     the code rather than interpreting it, and is much faster.
     See [this blog post](http://www.scottlogic.com/blog/2011/02/24/web-workers-part-3-creating-a-generic-worker.html)
     for details.
   * On the worker side there are functions for starting that
     function on a single argument list or an array of argument
     lists, and returning either a single result or an array of
     results, respectively.  Both the call and return happen by
     posting messages.
 * Add a member `call` that takes an array as inputs and posts the
   message that sends that array as the argument list to the
   background thread, thus starting the computation.  Return a
   `Promise` object.
   * In a `Promise`, one can call `sendTo` and provide a callback
     that registers that callback as the handler for the completion
     of the background task, receiving the computed results.  This
     method returns the same `Promise`, for chaining.
   * Also in the `Promise` one can call `orElse` and provide an
     error-handling callback.
 * Extend `call` to take an array of arrays, and send them as an
   array of argument lists to the background thread.  Further
   extend the `Promise` class so that when it receives an array of
   results, it calls the appropriate callback for each one.

Return to the BackgroundComputation class, now improving it by
means of the BackgroundFunction class.
 * The second implementation can be two-threaded, without any
   optimizations, by doing the exact same thing as the single-
   threaded implementation, except in one background thread.
   (But still waiting for each task to complete before starting
   another one.)
 * The third implementation can be many-threaded, using $n-1$
   threads, where $n$ is the optimal number of concurrent threads
   for the client's hardware.  The top $n-1$ items on the queue
   can be run in parallel.
 * The final implementation can add various optimizations to the
   previous implementation.
   * When starting a background computation, take several other
     waiting computations with the same background function, and
     start all at once, on the array of argument lists, so that
     only one message passing need occur.
   * When enqueueing a background computation, if another with the
     same background function and argument list is already waiting
     to be run, delete it.
   * When enqueueing a background computation, if another with the
     same background function and argument list is already running,
     terminate it and delete it.

## Design discussions to have

Imagine the whole Lurch experience being online, in the sense
that our website could house a wiki-like thing of Lurch
documents.  You want to share a document with your students?
just get an instructor account, save the document from your
weblurch to the wiki, then give the students the URL to use as a
dependency.  True cloud lurch sharing.

## Logical Foundation

### Dependencies

 * Create a way to give a document a title, author, language,
   and version, like we did before.  But perhaps we can drop
   language?  Version?
 * Create a way to find a document in the user's web storage or
   anywhere online (Firebase, web, Dropbox public folder, etc.)
   based on its URN.
 * Cache such files in local/Dropbox storage, so that Lurch is
   usable offline.
 * This will impact the events of what needs to happen when files
   are closed/opened, and what needs to be recomputed, based on
   whether or not the dependencies changed.  Perhaps do what
   [SCons does](http://www.scons.org/doc/0.98.4/HTML/scons-user/c779.html)
   and use a combination of timestamps and MD5 hashes to tell
   whether you need to bother recomputing the data from a
   dependency.  But where should such data even be stored?
   Design discussion to have...

### Math

 * Create a button or keystroke that allows you to insert a
   [MathQuill](http://mathquill.com/) instance in your document,
   and stores it as a special kind of content.
 * Whenever the cursor (the browser's one, not the model's one)
   is inside a MathQuill instance, frequently recompute the
   content of that instance and store it in that content object
   in the document.
 * Make ordinary keyboard motions of the cursor able to enter
   and exit MathQuill instances.
 * Make keyboard and mouse actions that create/extend a selection
   (e.g., shift-arrows, shift-click, click-and-drag) unable to
   select only a portion of a MathQuill object, but instead select
   all or none of it.
 * Consider whether you can render the MathQuill using
   [MathJax](http://www.mathjax.org/) when the cursor exits,
   to get prettier results.
 * Consider whether you can add the capability to do
   MathJax-rendered LaTeX source, with a popup text box, like
   in the Simple Math Editor in the desktop Lurch.

## Real Lurch!

Build the 3 foundational Group types, according to Ken's new spec!

## For later

### Ideas from various sources

Someday, when regular, automated testing becomes important, have
a server do a nightly git pull of the latest version.  Once that's
working, have it run a shell script that does the following.
 * Back up the old HTML version of the test suite output.
 * Run the test suite.
 * Email the developers if and only if the new output differs from
   the old in an important way (i.e., not just timings, but
   results).

Suggestion from Dana Ernst: Perhaps this is not necessary or
feasible, but if you go with a web app, could you make it easy
for teachers to “plug into” the common LMS’s (e.g. Blackboard,
Canvas, etc.)?  I’m envisioning students being able to submit
assignments with ease to an LMS and then teachers can grade and
enter grades easily without have to go back and forth between web
pages.  

Suggestion from Dana Ernst: I’ve been having my students type up
their homework using writeLaTeX.  One huge advantage of this is
that students can share their project with me.  This allows me to
simultaneously edit their document, which is a great way for me
to help students debug.  I give them a ton of help for a week or
two and then they are off and running on their own.  It might be
advantageous to allow multiple users to edit the same Lurch
document.  No idea if this is feasible or not, nor if it is even
an idea worth pursuing.

A web Lurch is trivially also a desktop Lurch, as follows.  You
can, of course, write a stupid shell app that’s just a single web
view that loads the Lurch web app into it.  This gives the user
an app that always works offline, has an icon in their
Applications folder/Start menu, etc., and feels like an official
app that they can alt-tab to, etc., but it’s the exact same web
app, just wrapped in a thin desktop-app shell.  You can then add
features to that as time permits.  When the user clicks “save,”
you can have the web app first query to see if it’s sitting in a
desktop-app wrapper, and if so, don’t save to webstorage, but pop
up the usual save box.  same for accessing the system clipboard,
opening files, etc., etc.  And those things are so modular that a
different person can be in charge of the app on different
platforms, even!  E.g., someone does the iOS app, someone does
the Android app, and someone does the
cross-platform-Qt-based-desktop app.

### Improving documentation

Documentation in most unit test spec files promises that [the
basic spec file](basic-spec.litcoffee.html) will provide complete
documentation on how to read and understand a test spec file.  But
it does not.

 * Add documentation to that file so that someone who does not know
   how to read a test spec file could learn it from that file.

### Citing sources

The glyph icons that come with Bootstrap were provided free by
[Glyphicons](http://glyphicons.com/).  Bootstrap requests that if
you use them, you provide a link back to that site.  When my apps
are further along in production, such a link should be provided
somewhere on the site where it makes sense to do so.

