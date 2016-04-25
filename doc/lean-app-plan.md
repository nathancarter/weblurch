
# Plan for a Lean UI Lurch Application

## Future Considerations

 * Lean `notation` definitions, and how they might work together with
   MathQuill widgets in the document

## Bug Fixes

 * `termGroupToCode` uses `contentsAsText`, which ignores paragraph breaks,
   as if they were not whitespace; this is problematic.  Create a new option
   to pass to `contentsAsText` that respects paragraph breaks as newlines or
   spaces of some kind.
