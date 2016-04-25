
# Plan for a Lean UI Lurch Application

## UI Tweaks and Organization

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
