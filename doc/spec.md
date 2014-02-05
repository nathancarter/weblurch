
# Some specifications for the finished system

The plan for implementing this specification is documented in
[the to-do list for this project](to-do.md.html).

## A vision for testing

 * Two-tab view
    * rendered HTML of model
    * HTML src of model
 * In either of the two, you can use the keyboard to navigate the
   document, and watch the changes.
 * In the first, you can use the mouse to navigate the document,
   and watch the changes.
 * All actions taken by the user are recorded by the controller
   so that they can be played back later, virtually.  (They are
   recorded as the names and parameters of functions called in the
   `LurchEditor` model by the controller, easy to replay later.)
    * It may seem tempting to utilize the built-in `undo()` and
      `redo()` methods of `LurchEditor` for this, but resist that
      temptation for two reasons:
    * First, this makes the test suite depend for its correctness
      on the correctness of the thing being tested, which is bad.
    * Second, it forces us to implement `undo()` and `redo()` in
      the `LurchEditor` class as early as possible, which may not
      otherwise be optimal.
 * There can be two new shortcut keys, one for "mark this state as
   approved correct" and one for "mark this state as an error"
   that can be used, with the above feature, to record assertions
   among the actions, which constitute a test when replayed.
 * Document states are just HTML, so that test suites can be run
   by a node script from the command line.  If need be, this HTML
   can be converted to JSON using `xml2js` or the even simpler
   technique in [this StackOverflow answer](
   http://stackoverflow.com/a/7824214/670492).

## Document structure and the `LurchEditor` class

 * A document will simply be an HTML DIV that's *not* browser
   `content-editable` but that is made editable through the
   `LurchEditor` class.
 * That class will give individual DOM nodes a unique integer id,
   for the purposes of referencing one node from another.
    * unique ids are maintained across insertions/deletions by
      keeping in the `LurchEditor` object (not the DOM) a list
      $[a\_1,\ldots,a\_n]$ such that an id is available iff it's
      on the list or $>a\_n$
    * to get a new integer id, either `shift()` the list if it's
      length is $>1$, or return `list[0]++` otherwise
    * when deleting a container/content with an id, if its id is
      `< list[length-1]`, insert it into the list, preserving order
 * Its constructor therefore takes a DOM element and initializes it
   for use as follows
    * Collect a list of all used ids, removing any ids that
      aren’t of the correct form
    * Create a list of the complement of the set of used ids,
      as a set of free ids
    * For every un-id’d element, give it the next available id
 * Later one can query which element in the document is the
   editable one managed by that `LurchEditor`, but it cannot be
   swapped out for another.  If you wish to edit another, just
   create a new `LurchEditor` instance.
 * `LurchEditor` will provide an API that one would normally
   place inside DOM elements, but that in this case we won’t,
   to avoid creating an unnecessary new node class
    * `insert(node,location)`
    * `remove(node)`
    * `move(node,newlocation)`
    * `replace(node,withthisnode)`
    * `change(node,attrkey,attrval)`
 * It should also provide an `undo()` function (together with
   `redo()` and `canUndo()` and `canRedo()`) that invert/replay
   the above events
 * Each of the above will emit events that can be listened to
   by anyone who needs to know about them, including later
   bubbling and validation features.

## Document events

 * All changes to the document will happen using one of four
   functions in the public API provided by the `LurchEditor` class,
   listed above
 * They generate corresponding events upon completion, which may be
   listened to by the controller for the purposes of updating a
   secondary view, or verifying correctness in testing, etc.
 * If the document wants to merge adjacent pieces of content with
   identical attributes, concatenating their string contents, this
   should result in the firing of one delete and one change event.

