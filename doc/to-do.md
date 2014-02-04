
# To-do list for this project

## Documentation improvements

 * Add title to navigation bar.
 * Make nav bar and right side hover always about 30px from top,
   even as you scroll down.
 * Add link in nav bar to `app/index.html`.
 * Make hyperlinks from individual `describe "..."` code lines to
   the corresponding sections of `test/results.md`.

## Create `testapp/` folder

 * Put in it a stub html file for now, like `app/index.html`, but
   later we’ll add real functionality to it for testing purposes
   (e.g., multi-pane view, etc.).
 * Create link to that page from the docs nav bar.
 * Create another section in `cake.litcoffee` that will take
   `.litcoffee` files in `testapp/` and put them in a separate
   joined, minified file in that same folder.
 * Create a stub file of that type and ensure it gets imported
   into the test app.
 * Make these files yet another section in the nav bar created
   by `cake doc`.

## `LurchEditor` class must implement these features

 * Its constructor takes a DOM element and initializes it for
   use
    * Collect a list of all used ids, removing any ids that
      aren’t of the correct form
    * Create a list of the complement of the set of used ids,
      as a set of free ids
    * For every un-id’d element, give it the next available id
 * Later one can query which element in the document is the
   editable one managed by that `LurchEditor`, but it cannot be
   swapped out for another.  If you wish to edit another, just
   create a new `LurchEditor` instance.
 * It will provide, in itself, an API that one would normally
   place inside DOM elements, but that in this case we won’t,
   to avoid creating an unnecessary new node class
    * `insert(node,location)`
    * `remove(node)`
    * `move(node,newlocation)`
    * `replace(node,withthisnode)`
    * `change(node,attrkey,attrval)`
 * Each of the above will emit events that can be listened to
   by anyone who needs to know about them, including later
   bubbling and validation features.

## Test all the above

## Add a cursor API to the document

 * Insert a cursor before/after a given sub-node of the
   editable DOM element (iff one isn’t already in the element
   somewhere).
 * Get the existing cursor object.
 * Move the existing cursor object
   left/right/up/down/home/end/pgup/pgdn.
   (Note that most of these will need to query the view for
   placement after the move.)
 * Move only the cursor position without moving its anchor, so
   that text becomes selected.
 * Insert text at the cursor
 * Insert HTML at the cursor
 * Replace selection with given text
 * Replace selection with given HTML

## Test all of the above, as implemented

