
# Project Plan

This document aims to be a complete plan for what needs to be done
on this project.  It can be viewed as a to-do list in chronological
order, the first items being those that should be done next, and
the later items those that must come after.  Necessarily, the later
items are more vague than the earlier ones.

# Word Processing Foundation

## DOM Edit Tracker

 * Create a `DOMEditTracker` class that can be instantiated with a
   single HTML element as parameter and that remembers that
   element.  Make `LurchEditor` inherit from this class, so we're
   factoring out that aspect of a `LurchEditor` into that class.
 * Give `DOMEditTracker` a class method that returns the instance
   whose main HTML element is or contains the one passed as
   argument, if there is such an instance.  Create a unit test for
   the `DOMEditTracker` class that tests this class method.
 * Create a new class for storing DOM editing events, but for now
   it's just a stub; call it `DOMEditAction`.
 * Create a `DOMEditTracker` instance method called
   `nodeEditHappened` that takes a `DOMEditAction` instance as
   parameter and pushes it onto an internal stack.  See the next
   bullet point for the definition of that class.
 * Add to the `DOMEditAction` class the ability to instantiate it
   with any of the following types of data.  Do this in parallel
   with the following bullet points, which instantiate this class
   and discuss the testing thereof.
    * N.appendChild(node)
       * returns node
       * record with N's address and the serialized node
    * N.insertBefore(node,beforeThisChild)
       * returns newnode
       * if beforeThisChild is omitted, it's the same as append
       * record with N's address, the serialized node, and the
         index of beforeThisChild (or child node length if absent)
    * N.normalize()
       * removes empty text nodes
       * joins adjacent text nodes
       * no return value
       * record as N's address together with a mapfrom indices to
         text content of all current child text nodes of N
    * N.removeAttribute(name)
       * no return value
       * record as N's address, name, and original attribute value
    * N.removeAttributeNode(attrNode)
       * returns attrNode
       * e.g.: N.removeAttributeNode(N.getAttributeNode('style'))
       * record as N's address and original attribute name and
         value
    * N.removeChild(childNode)
       * returns childNode
       * record as N's address, the child's original index within
         N, and a serialization of the child
    * N.replaceChild(newnode,oldnode)
       * returns oldnode, I think
       * record as N's address, the child's original index within
         N, and serializations of both oldnode and newnode
    * N.setAttribute(name,value)
       * both strings, no return value
       * record as N's address, name, and value, as well as the
         original value of the attribute beforehand
    * N.setAttributeNode(attrNode)
       * returns replaced node if any, otherwise null
       * e.g.:
         `var atr=document.createAttribute("class");
         atr.nodeValue="democlass";
         myDiv.setAttributeNode(atr);`
       * record as N's address, the name and value of the attribute
         after setting, as well as the original value of the
         attribute beforehand
    * Note that element.dataset.foo is not supported.
 * In the [DOM utilities module](domutils.litcoffee.html), modify
   all functions in the Node prototype that manipulate the DOM so
   that, after their completion, they call `nodeEditHappened` in
   the containing `DOMEditTracker` instance notifying it of which
   method was called in them, if it was successful in modifying the
   DOM, by creating and passing a `DOMEditAction` instance.
   Create unit tests that verify that the data is correctly
   recorded in the internal array of the `DOMEditTracker` instance.
 * Add undo and redo methods to a `LurchEditor` instance that move
   an index pointer up and down the internal list of past actions,
   and that chop off the redo-able actions if an edit comes in that
   is not from an undo/redo action.  Thorough unit tests as well.
 * Add canUndo() and canRedo() methods to the `LurchEditor` class
   that just report whether the index pointer isn't at the top or
   bottom of the stack.  Test.
 * Add a `toString()` method to `DOMEditAction` that can describe
   it.  Add methods to `LurchEditor` that can describe the actions
   that would take place if undo or redo were invoked.  Test.

# Test environment

## Test app

 * Import into the project a UI toolkit such as
   [Bootstrap](http://getbootstrap.com).
   (If you use bootstrap, replace your link png with its link
   glyphicon.)
 * Import that UI into both the app and test app pages, rewriting
   them to fit its format if necessary.
 * Split the test app into tabs, one containing a view that shows
   the document as HTML source.
 * Add to the test app a user interface for making any of the
   editing API calls on any Node in the `LurchEditor`'s main HTML
   element (could be just a JS eval of the code in an input box).
 * Update the source view after every API call.

## Easy test generation

 * Have test app save the state of the model at the start and
   after every API call, as well as storing all API calls, thus
   keeping a full history.  API calls are recorded as the actual
   code that was evaluated, easy to replay later (and objective).
 * Add buttons to the test app for marking points in the history
   as correct or incorrect (with optional comments) and store
   that data in the history as well
 * Create a UI for viewing that history, giving it a name, and
   downloading it as a JSON file `putTestNameHere.json`.
 * Create a method in [phantom-utils](phantom-utils.litcoffee.html)
   (possibly rename to `test-utils`?) that can run such a test
   history inside a jasmine test (i.e., one `describe` with a bunch
   of `it`s and `expect`s in it.
 * Create a folder in the repository for holding such test JSON
   files and organize it hierarchically by topic
 * Add to the `cake test` procedure the running of all test
   histories, verifying each step, and outputting a report,
   in [Markdown](https://daringfireball.net/projects/markdown/).
 * Categorize the outputs with section headers, etc., imitating
   the structure of the folder hierarchy.

## Better access to automated testing results

 * As part of the `cake test` procedure, unite the JSON of all
   the saved test histories into one big JSON object and create a
   `.js` file that assigns that object to a global variable.
 * Import that `.js` file into the test app.
 * Create a UI for choosing a test to run from a hierarchical
   list generated from that variable's value.
 * Create functionality that can replay the chosen test one
   step at a time and show the expected vs. the actual, with
   differences highlighted.

## Later, when you put the repository on a server

 * Have the server nightly do a git pull of the latest version.
   Once that's working, have it run a shell script that does the
   following.
    * Back up the old HTML version of the test suite output.
    * Run the test suite.
    * Email the developers if and only if the new output differs
      from the old in an important way (i.e., not just timings,
      but results).

# More Word Processing Foundation

## Events

 * Make each call to `nodeEditHappened` (as well as each call to
   undo or redo in a `DOMEditTracker`) fire events about which
   address(es) in the DOM (below the tracker's main HTML element)
   changed.  These events can be listened to by later bubbling and
   validation features.
 * Have the test app update the HTML source view when it hears
   one of those events, rather than after every API call.

## Cursor

 * Build the `LurchEditor` API for placing a cursor in the
   document, or nowhere, depending on whether the document has
   focus.
 * Add all the functions for dealing with that cursor as if it
   were a real cursor
    * insert a cursor before/after a given sub-node of the
      editable DOM element (iff one isn’t already in the element
      somewhere).
    * get the existing cursor object.
    * jump to abs pos, with or without moving the anchor
    * move by rel amt, with or without moving the anchor
    * insert text, HTML, or entire object before cursor
    * split content at cursor
    * replace selection with text, HTML, or entire object
    * change properties of selection (e.g., font, color)
    * delete character before/after cursor
    * delete selection
    * change properties of paragraph around cursor
      (e.g., justification, indentation)
 * As you create each, create tests for it as well, and save
   them in the repository

## Keyboard

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
 * In the test app, when the JS eval
   input does not have focus (and yet we're in one of the main
   view tabs, not the export-a-test-JSON view) react to
   keyboard events by calling the `LurchEditor`'s appropriate
   keyboard API functions.
 * When the main controller is generating a test record, it
   should record the calls it's sending to that API.
   This may require extending the test
   runner to also use that same API.

## Mouse

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

## Load and save

 * Add to the main app the ability to load and save documents
   from web storage
 * Add the ability to upload and download documents from the
   local machine into/out of web storage
 * Add the ability to share documents that are in your web
   storage with the world using something like
   [Firebase](https://www.firebase.com/) or a custom server.

# Logical Foundation

## Dependencies

 * Create a way to give a document a title, author, language,
   and version, like we did before.  But perhaps we can drop
   language?  Version?
 * Create a way to find a document in the user's web storage
   based on its URN.

## Math

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

## Groupers

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

## Background processing

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

## Background computation of the property graph

 * more detail needed here later
 * create unit tests as you go

## Background computation of bubble meanings

 * (yes, that is a huge task that is contingent upon decisions
   about parsing, etc., but simple defaults could be put in
   place to start, such as a sensible interpretation of
   MathQuill content, or simpleLob notation only, or whatever)
 * create unit tests as you go

## Background validation, probably in stages

 * (again, first we should check to see if validation was
   redesigned in any important way, including any relevant
   theorems proven based on assumptions that you therefore must
   guarantee hold in your implementation)
 * create unit tests as you go

