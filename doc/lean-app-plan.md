
# Plan for a Lean UI Lurch Application

## Namespaces

 1. Modify the context menu for body groups as follows.
    * If the group has no connections and no `namespace` attribute, add to
      the context menu an item called "Make this a namespace..."  For now,
      the handler can be a stub, which will be fleshed out below.
    * If the group has no connections but has a `namespace` attribute, add
      to the context menu two items:
      * One called "Make this a section" should remove the group's
        `namespace` attribute.
      * One called "Rename this namespace..." should behave just like "Make
        this a namespace..." as described further below.  (Stub for now.)
    * If the group has connections, then do not modify the context menu.
 1. Fill in the handler for the "Make this a namespace..." action (which can
    also be the "Rename this namespace..." action) so that it gives the user
    a JavaScript `prompt` asking for the name of the namespace.  The initial
    value should be the current value of the group's namespace attribute (or
    empty string if it has none), and canceling should do nothing.  Clicking
    OK should update the value of that attribute.
 1. Update the `sectionGroupToCode` function so that if the group has a
    namespace attribute with value `N`, then in place of `section S`, use
    the text `namespace N`, and in place of `end S`, use the text `end N`.
 1. Test, updating your example document to use this new feature.
 1. Add the next page of the tutorial that shows how to use this feature to
    be able to group definitions and theorems into a namespace, just as in
    the Lean tutorials.

## UI Tweaks and Organization

 1. Remove arrow labels, which are distracting.
 1. Permit body groups to have zero children, in which case their contents
    are processed as if it were a single term group inside the body group,
    containing all the contents.
 1. Update tutorial pages to reflect this special case of body groups.
 1. Update all screenshots to take all these visual changes (plus those on
    the toolbar) into account.
 1. Rename all screenshots to the format `tut-N-ss-DESC.png`.

## Special Characters

 1. Include [this file](https://raw.githubusercontent.com/leanprover/tutorial/master/js/input-method.js) from the Lean-JS Live Demo into this project.
 1. Whenever the user inserts text, then presses space or backslash, check
    to see if the text preceding the space or backslash is a key in the
    corrections object.  If so, replace the key with the value.

See [this code](https://github.com/leanprover/tutorial/blob/master/js/main_live.js#L349) in the Lean-JS Live Demo for how it is implemented there.

## Future Considerations

 * Lean `notation` definitions, and how they might work together with
   MathQuill widgets in the document

## Bug Fixes

 * `termGroupToCode` uses `contentsAsText`, which ignores paragraph breaks,
   as if they were not whitespace; this is problematic.  Create a new option
   to pass to `contentsAsText` that respects paragraph breaks as newlines or
   spaces of some kind.
