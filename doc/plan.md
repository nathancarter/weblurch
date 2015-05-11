
# Project Plan

Readers unfamiliar with this project may wish to first read what's already
been accomplished, on the [Project Progress](progress.md) page.  This page
is a complement to that one, stating what remains to be done.

This document aims to be a complete plan for what needs to be done on this
project, readable by developers.  It can therefore be viewed as a to-do list
in chronological order, the first items being those that should be done
next, and the later items those that must come after.  Necessarily, the
later items are more vague than the earlier ones.

## Bug fixes

Load and save

 * Not all edits cause the document to be marked dirty.  Perhaps the TinyMCE
   events are not firing when I expect, or perhaps I am not handling them
   correctly.  (No easily known way to reproduce this, yet.)
 * Using the keyboard shortcut for Save throws up a dialog with error
   messages about invalid content.  (To reproduce: Open app, press Cmd+S.)
 * Using the keyboard shortcut for New or Open on Mac triggers the Chrome
   behaviors on the Chrome File menu, not the TinyMCE behaviors on its File
   menu.

## Extending the Editor

### Groups plugin

Create a Groups plugin with the following features.

 * Create a convenience function for installing a keyboard shortcut that
   calls the hide/show method.
 * Create convenience functions that create buttons and menu items that call
   the insertion function.
 * Create the Group class with a constructor that can accept a DOM element
   that is the open/close grouper, and it will find the other.
 * Extend Group instances with getters for the open/close grouper elements.
 * Introduce unique IDs by doing the following enhancements as a unit.
   * Give every matching pair of groupers a unique number at insertion time,
     stored in their ids, as in `id='open3'` and `id='close3'`.
   * Extend Group instances with a getter for the integer id number.
   * Add a class method that scans the document, indexing all pairs of
     groupers, in order, deleting each that doesn't match up with a
     same-numbered partner.  From those that remain, build a hierarchy
     stored in a class member `Groups.tree`, as an array of `Group` object
     instances.  It also computes the list of unused ID numbers, so that
     it's easy to determine the next available ID for insertion.
   * Call that scanning routine after each document change.
 * Extend the scanning routine to also map all Group id numbers to the
   object instances, and keep that mapping within the Groups class itself,
   as in `Groups[7]`
 * Write a class method `Groups.numbers()`, which returns a list of all id
   numbers that appear in `Groups.tree`.  They should appear in tree order.
 * Have `Groups.numbers()` cache its results and only invalidate the cache
   when the scanning routine is re-run.
 * Extend Group instances with a function for getting the array of child
   Groups.
 * Extend Group instances with a function for getting the parent Group, if
   there is one.
 * Use the overlay plugin to draw bubbles around Groups if and only if the
   cursor is inside them.
 * Extend the constructor so that it can take any DOM node and yield the
   deepest Group instance surrounding it, if there is one.  (If this can't
   be done with a constructor--since it may fail--use a class method
   instead.)
 * Enhance the Group insertion actions so that they are unavailable when the
   base and anchor of the selection are not in the same Group.
 * Add instance methods for getting/setting arbitrary data on a Group, as
   key-value pairs stored in the open grouper DOM element attributes.

### More sophisticated testing

The first big change has just been completed.  Before this all we had done
was import a well-tested project (TinyMCE) and integrate into it another
well-tested project (jsfs).  Now we've added two of our own plugins, neither
of which has a test suite associated with it.

The problem is that we do not have experience in testing things that require
the level of user interaction that testing these requires.  It is essential
to pause here and learn how to create the tools you need for automating
testing with user interactivity.  PhantomJS certainly permits automated
typing, clicking, and screen capturing.  Learn those methods and how to use
them to test the Groups plugin.

Furthermore, factor out of that testing process the re-usable tools you
create, so that testing the additional features you'll introduce below is
easier, and thus more likely to be done, and done well.

### Events

 * Create a generic event system that can fire events and hear the collected
   responses from their event listeners.  You may be able to re-use one from
   the browser's JavaScript environment, or re-use the handlers package from
   the original Lurch; it is less than 150 lines of code, including
   comments.  It should not be a TinyMCE plugin, because it should be able
   to be used in many contexts, not just that of a TinyMCE editor.  It
   should be a standalone class whose instances are individual event
   systems, and each instance of the `Groups` class can have an instance of
   this `Events` class as a member.
 * Create a `groupContentsChanged` event and fire it whenever the inside of
   a group is edited by the user, or any code writes to the Group's
   properties using the Group API.
 * Create a `groupTagRequested` event, and use it as follows.
   * When planning to draw bubbles, fire this event for each Group
     containing the cursor.
   * Cache the aggregated results from any listeners in the Group.
   * Clear that cache on `groupContentsChanged` for the group or any of its
     parents.
   * Draw such labels above the bubbles.
   * Extend that algorithm so that labels never collide, as in the desktop
     Lurch.
 * Create a `groupMenuRequested` event, and use it as follows.
   * When the user right-clicks inside the group, fire this event and use
     the aggregated results from any listeners to extend the context menu
     that's shown.
   * When the user clicks inside the bubble tag, do the same.
 * Create a `groupAdded` event and fire it when inserting new Groups.
 * Create a `groupDeleted` event and fire it when processing the whole
   document and updating the cache of Group data, for any Group that has
   simply disappeared, or that half-disappeared and we were forced to remove
   the remaining, unmatched grouper.

### Math

Before proceeding with this section, do review what's already been done in
this space, including
[this](https://github.com/foraker/tinymce_equation_editor) and
[this](https://github.com/efloti/plugin-mathjax-pour-tinymce) and
[this](http://www.wiris.com/solutions/tinymce) and
[this](http://www.imathas.com/editordemo/demo.html) and
[this](https://docs.moodle.org/26/en/TinyMCE_Mathslate) and
[this](https://www.codecogs.com/latex/integration/tinymce_v4/install.php).
There are similar projects for CKEditor as well.

 * Create a button or keystroke that allows you to insert a
   [MathQuill](http://mathquill.com/) instance in your document, and stores
   it as a special kind of content.
 * Whenever the cursor (the browser's one, not the model's one) is inside a
   MathQuill instance, frequently recompute the content of that instance and
   store it in that content object in the document.
 * Make ordinary keyboard motions of the cursor able to enter and exit
   MathQuill instances.
 * Make keyboard and mouse actions that create/extend a selection (e.g.,
   shift-arrows, shift-click, click-and-drag) unable to select only a
   portion of a MathQuill object, but instead select all or none of it.
 * Consider whether you can render the MathQuill using
   [MathJax](http://www.mathjax.org/) when the cursor exits, to get prettier
   results.
 * Consider whether you can add the capability to do MathJax-rendered LaTeX
   source, with a popup text box, like in the Simple Math Editor in the
   desktop Lurch.

## Background processing

Import [this polyfill](https://github.com/oftn/core-estimator) for
estimating the optimal number of cores for use by background threads.

Build a BackgroundComputation class with the following API.
 * There is one function to enqueue a computation based on the name of the
   background function to be called, and the list of groups to use as
   arguments.
 * The first implementation can simply be single-threaded, by using
   `setInterval` and dequeueing a new task every so often, if and only if
   the previous one has completed.

Build a BackgroundFunction class with the following API.
 * One can register new functions to be run in the background, by mapping
   any string name to any JS function.  This is a class method.
 * One can create new instances of BackgroundFunction objects by calling a
   constructor and passing the name of a previously- registered function.
   This should create a web worker that has the following capabilities.
   * It has the registered function precompiled into the worker.
     Be sure to use the [Function constructor](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function)
     to build the function on the worker side, because it compiles the code
     rather than interpreting it, and is much faster. See [this blog post](http://www.scottlogic.com/blog/2011/02/24/web-workers-part-3-creating-a-generic-worker.html)
     for details.
   * On the worker side there are functions for starting that function on a
     single argument list or an array of argument lists, and returning
     either a single result or an array of results, respectively.  Both the
     call and return happen by posting messages.
 * Add a member `call` that takes an array as inputs and posts the message
   that sends that array as the argument list to the background thread, thus
   starting the computation.  Return a `Promise` object.
   * In a `Promise`, one can call `sendTo` and provide a callback that
     registers that callback as the handler for the completion of the
     background task, receiving the computed results.  This method returns
     the same `Promise`, for chaining.
   * Also in the `Promise` one can call `orElse` and provide an
     error-handling callback.
 * Extend `call` to take an array of arrays, and send them as an array of
   argument lists to the background thread.  Further extend the `Promise`
   class so that when it receives an array of results, it calls the
   appropriate callback for each one.

Return to the BackgroundComputation class, now improving it by means of the
BackgroundFunction class.
 * The second implementation can be two-threaded, without any optimizations,
   by doing the exact same thing as the single-threaded implementation,
   except in one background thread. (But still waiting for each task to
   complete before starting another one.)
 * The third implementation can be many-threaded, using $n-1$ threads, where
   $n$ is the optimal number of concurrent threads for the client's
   hardware.  The top $n-1$ items on the queue can be run in parallel.
 * The final implementation can add various optimizations to the previous
   implementation.
   * When starting a background computation, take several other waiting
     computations with the same background function, and start all at once,
     on the array of argument lists, so that only one message passing need
     occur.
   * When enqueueing a background computation, if another with the same
     background function and argument list is already waiting to be run,
     delete it.
   * When enqueueing a background computation, if another with the same
     background function and argument list is already running, terminate it
     and delete it.

At this point it may be worthwhile creating some non-Lurch application that
uses the above technology, as a way to verify that it's behaving the way you
expect.  That test application could become part of the test suite.  After
all, the technology that exists to this point (groups and the background
processing thereof) is complext and many-layered, and it would be good to
have a thorough test at this level.

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
   * If Dropbox is not used, and thus the user's files are not present on
     their own local machine, provide a way to transfer files from their
     local filesystem to/from the browser's LocalStorage?
   * Add the ability to share documents with the world.  Options:
     * Use something like [Firebase](https://www.firebase.com/).  (Too much
       work, and requires integrating a whole new technology.)
     * If using Dropbox, make files shared, if the API supports that.
       (Again, too complex, and requires Dropbox.)
     * Create a wiki on `lurchmath.org` into which entire Lurch HTML files
       can be pasted as new pages, but only editable by the original author.
       This way instructors can post on that wiki core dependencies that
       anyone can use, and the integrity of a course (or the whole Lurch
       project!) is not dependent on the state of any individual's Dropbox
       folder.  (Note that external websites are not an option, since
       `XMLHttpRequest` restricts cross-domain access, unless you run a
       proxy on `lurchmath.org`.)  This could be even better as follows:
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
