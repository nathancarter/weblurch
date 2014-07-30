
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

## More Word Processing Foundation

### Cursor

For every item in this section, as it is accomplished, we should
also (of course) create unit tests verifying that it was completed
correctly.

 * Implement the following cursor features in `LurchEditor`.
    * Create member variables in the `LurchEditor` class for
      storing the cursor position and anchor elements.
    * Create `LurchEditor` method for refreshing those member
      variables by seeking out the relevant elements.
    * Create method in Node prototype for computing the number of
      text characters in the node.  (For elements with no children,
      this is 1.  For elements with children, it is the sum of the
      values for the children.)
    * Create a Node prototype method for splitting the node after
      the character with a given index, and returning the two nodes
      before and after the split.  (Or it can return `[A,null]` if
      the position equals the text length, and `[null,B]` if the
      position equals zero.)
    * Create a `LurchEditor` method for placing a cursor position
      at a given position inside a given node (which defaults to
      the main div of the editor).
    * Create a `LurchEditor` method for removing the cursor from
      the document (i.e., defocusing) and normalizing as needed.
      Ensure that this is automatically called if the
      insert-a-cursor method is called when a cursor is already
      there.
    * Add to `LurchEditor` instances a timer that flashes the
      cursor just as MathQuill does.
    * Add to the Node prototype a method for finding the previous
      leaf node in the tree, even if that's a "cousin" node.  Do
      the ame for "next" nodes.
    * Add a CSS class that gives a blue background, for use on the
      cursor selection.
    * Add to the cursor placement routine a parameter for whether
      or not to move the anchor as well, defaulting to yes.  If the
      anchor does not move, ensure that all elements between the
      old and new cursor positions get the requisite class for
      showing the blue background.  If the anchor does move, ensure
      that all elements that had that class lose it.
    * Add methods for moving the cursor by a given delta, with or
      without moving the anchor (defaults to moving it).
 * Add all the functions for dealing with that cursor as if it
   were a real cursor.  Each of these may make several edits to the
   document, and so should use the new block-of-edits support
   mentioned above.
    * insert text, HTML, or entire object before cursor
    * replace selection with text, HTML, or entire object
    * change properties of selection (e.g., font, color)
    * delete character before/after cursor
    * delete selection
    * change properties of paragraph around cursor
      (e.g., justification, indentation)
    * cut, copy, and paste
      (See [this StackOverflow answer](
      http://stackoverflow.com/a/11347714/670492) for a possibly
      helpful way to put complex content on the clipboard from
      JavaScript.)
      * implement copy, and then cut is copy-then-delete
      * implement paste when there is no selection, and then paste
        when there is a selection is just delete-then-paste

### Keyboard

 * Layer on top of the cursor functions a set of keyboard event
   handlers, which call the cursor functions under the hood.
    * text character = insert text before cursor or replace
      selection with text
    * left/right arrow = move by rel amt +/-1
    * shift left/right arrow = same but without moving anchor
    * up, down, home, end, page up, page down = also movement,
      but need to be more sophisticated about querying the view
      ([see if this information helps](
      http://stackoverflow.com/a/3710561/670492))
    * enter = split paragraph into two
    * backspace = delete character before cursor, or cursor
      selection
    * delete = delete character after cursor, or cursor
      selection
    * Ctrl + B/I/U/L/R/E = apply properties to selection or
      paragraph around cursor, as appropriate
    * Ctrl + X/C/V = cut/copy/paste
 * In the test app, when the JS eval
   input does not have focus (and yet we're in one of the main
   view tabs, not the export-a-test-JSON view) react to
   keyboard events by calling the `LurchEditor`'s appropriate
   keyboard API functions.
 * When the main controller is generating a test record, it
   should record the calls it's sending to that API.
   This may require extending the test
   runner to also use that same API.

### Mouse

 * Should be handled similarly to Up, Home, etc. keys:
   Create an API that sits on top of the low-level cursor API
   and can accept mouse clicks and drags, translating them into
   calls to the low-level API functions.
 * Connect mouse events in the app and test app to calls to this
   new API in `LurchEditor`.
 * [How to detect on which element inside a large region the
   user clicked](http://jsfiddle.net/Xotic750/M7mgv/)
 * [How to find the particular character on which the user
   clicked](http://stackoverflow.com/a/3710561/670492)

### Load and save

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
 * Consider whether you can render the MathQuill using
   [MathJax](http://www.mathjax.org/) when the cursor exits,
   to get prettier results.
 * Consider whether you can add the capability to do
   MathJax-rendered LaTeX source, with a popup text box, like
   in the Simple Math Editor in the desktop Lurch.

### Groupers

 * (throughout all the to-dos in this category, be sure to
   create unit tests and verify that the test script can handle
   them, to keep all of this honest and solid)
 * Give `LurchEditor` the ability to create groupers in pairs
   (correctly nested) and if one is deleted its partner is
   automatically deleted as well.
 * Create all the corresponding API, such as querying and
   navigating the group hierarchy.
 * Decide the UI for groups, tags, etc.:
   Same as old Lurch?  Something different?  Easier?  Better?
 * Build the 3 foundational grouper types, although so far all
   that's happening is that the data about the user's choices
   is getting stored in each group, but the groups don't
   compute their meanings, don't modify one another, nothing
   except store a record of the user's choices for later
   computation by background workers.

### Background processing

 * Create the structure for running computations in the
   background.  I think it will work like this:
    * Add to the `LurchEditor` class a list of computations
      that must be run on the document before it's done/stable.
      This should be an attribute of the document that gets
      preserved across load/save.
    * Upon each change, the editor will know whether that
      change requires any recomputation, and if so, it enqueues
      it in that attribute.
       * The enqueue function is smart enough to dispatch a
         WebWorker to handle anything enqueued, provided that
         there are not too many workers already dispatched.
       * Whenever a worker completes its task, if there are
         tasks on the queue, it gets given another.
       * The result of worker computations will often be just
         the first step in a process, and thus will involve
         enqueueing yet still more to-dos.  E.g., meaning
         recomputation -> revalidation -> revalidation of
         later stuff -> etc.
 * All of the following test-related tools should know to wait
   for all background processing to complete before examining
   the result of any given action on the document and calling
   that the "next state" of the document.  This can be achieved
   by `LurchEditor` providing a function to say whether it's
   still computing stuff or not.
    * automated headless test runner
    * web-based test generator
    * web-based test replayer

### Background computation of the property graph

 * more detail needed here later
 * create unit tests as you go

### Background computation of bubble meanings

 * (yes, that is a huge task that is contingent upon decisions
   about parsing, etc., but simple defaults could be put in
   place to start, such as a sensible interpretation of
   MathQuill content, or simpleLob notation only, or whatever)
 * create unit tests as you go

### Background validation, probably in stages

 * (again, first we should check to see if validation was
   redesigned in any important way, including any relevant
   theorems proven based on assumptions that you therefore must
   guarantee hold in your implementation)
 * create unit tests as you go

## For later

### Making unit tests more complete

The following unit tests were skipped earlier in development,
because they are less important than the ones that were written,
and yet are included here for the sake of completeness, and so that
they are not forgotten.  A complete unit testing suite would have
tests for all of the following cases.
 * [The tests for the DOMEditAction constructor](
   domeditaction-spec.litcoffee.html) test every constructor by
   passing it correct parameters.  They do not do any testing to
   ensure that the constructor throws an error upon receiving
   incorrect parameters, except one test that ensures that the
   action type is valid.  In particular, no testing is done to
   ensure that the node must be valid, nor that for each individual
   action type, the parameters must be given correctly.
 * All the functionality of the test app.  Currently, it is only
   tested by the developers' using it, together with some minimal
   unit tests [in the basic spec file](basic-spec.litcoffee.html).

Someday, when regular, automated testing becomes important, have
a server do a nightly git pull of the latest version.  Once that's
working, have it run a shell script that does the following.
 * Back up the old HTML version of the test suite output.
 * Run the test suite.
 * Email the developers if and only if the new output differs from
   the old in an important way (i.e., not just timings, but
   results).

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

