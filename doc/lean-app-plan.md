
# Plan for a Lean UI Lurch Application

## Types

 1. Update `termGroupToCode` as follows.
    * First, find the set of type bubbles that point to the term group in
      question.
    * If the set is empty, proceed as before.
    * If the set has more than one element, throw an error saying that is
      invalid.
    * Otherwise, take the contents of the one type group and insert them
      after the first identifier in the term group, separated by a colon
      (`:`), when converting its text to Lean code.
 1. Update the validation routine so that if `termGroupToCode` throws an
    error, that group is marked invalid without its contents being converted
    to code at all.
 1. Add to the end of validation that any type groups without arrows to term
    groups are marked yellow, with an explanatory message saying that this
    group was ignored in validation.
 1. Test, updating your example document to use this new feature.
 1. Add the next page of the tutorial that shows how to use this feature to
    insert some explanatory phrases between a term and its type, thus
    forming nice English sentences.  Be sure to create an example document
    and include either its HTML or a screenshot in the tutorial page.

## Bodies

 1. Permit a term group's command to include "definition," "theorem," or
    "example," in addition to the commands already permitted.
 1. Create a new group type for bodies of definitions, theorems, examples,
    sections, and namespaces.
 1. Make it so that one can create arrows connecting bodies to terms, but
    not any other new kind of arrow.
 1. Create a new function `bodyGroupToCode` as follows.
    * Obviously, it accepts a single body group as parameter.
    * Find the ordered list of immediate child groups that are either terms
      or other bodies.
    * If this set is empty, throw an error explaining that a body cannot be
      empty.
    * If this list has a body group anywhere but as its final element, throw
      an error, because a body group cannot be an "assumption" to another
      body group.
    * If any term group on the list has a body group pointing to it, throw
      an error, because those structures are not permitted here.
    * Recursively call `termGroupToCode` or `bodyGroupToCode` on each of the
      elements of the list; call the results `r1` through `rN`.
    * Form the text `assume r1, assume r2, ..., assume rN-1, rN`, with each
      assumption and the body on separate lines, ensuring that the commas
      are correctly placed before the group-ID comments on each line.  Note
      that there may be zero `assume` entries, if `N` is 1.
 1. Update `termGroupToCode` as follows.
    * When finding the set of type bubbles that point to the term group in
      question, also find the set of body bubbles that do so.
    * If the set is empty, proceed as before.
    * If the set has more than one element, throw an error saying that is
      invalid.
    * If the term group to which the body group points isn't marked with a
      command on the list "theorem," "definition," or "example," throw an
      error saying that only those types of structures can have bodies.
    * Otherwise, compute its meaning using `bodyGroupToCode`.  Prefix that
      meaning with `:=` and place it, on a new line, after the meaning of
      the term without the body.
 1. Add to the end of validation that any body groups without arrows to term
    groups are marked yellow, with an explanatory message saying that this
    group was ignored in validation.
 1. Test, updating your example document to use this new feature.
 1. Add the next page of the tutorial that shows how to use this feature to
    be able to put flarf before/amidst definitions and proofs.  Be sure to
    create an example document and include either its HTML or a screenshot
    in the tutorial page.

## Trees

 1. Permit arrows from one term group to another term group, or to a body
    group.
 1. When creating an arrow from a term group or a body group, verify that it
    would not create a cycle, as follows.
    * Call `A` the proposed source group and `B` the proposed destination
      group for the new arrow.
    * Computing the set of all groups reachable from `B`.
    * Permit the arrow iff that set does not contain `A`.
 1. Update the `termGroupToCode` function as follows.
    * Compute the meanings of any other groups to which this group has
      direct arrows.  Optionally replace all occurrences of `assume` with
      `fun`.
    * If this group has an incoming arrow from a term group, do not permit
      incoming arrows from type groups, nor from body groups.  (That would
      create, as far as I know, invalid Lean syntax.  Subterms can't be
      type assertions, nor definitions/theorems/etc.)
    * Then take this group's meaning without those connections, and suffix
      it with the ordered list of those connections.  Place one group per
      line, to preserve the group-ID comments, and place a single-line `(`
      before and a single-line `)` after, each with a group-ID comment
      linked to the group of the head term.
 1. Update the `documentToCode` function so that it ignores any term group
    that has arrows coming into it from another term group.
 1. Update the `bodyGroupToCode` function so that it ignores any term group
    that has arrows coming into it from another term group.
 1. Test, updating your example document to use this new feature.
 1. Add the next page of the tutorial that shows how to use this feature to
    be able to put flarf just about anywhere and/or rearrange the elements
    of a proof into a more typical logical order.  Be sure to create an
    example document and include either its HTML or a screenshot in the
    tutorial page.

## Sections

 1. Modify the body group type so that when a body group has no arrows into
    or out of it, its group tag says "Section."
 1. Create a new function `sectionGroupToCode` as follows.
    * It accepts a single body group as parameter.
    * Let `S` be the bubble ID for that body group, prefixed by some dummy
      ID to make it an identifier.
    * Find the ordered list of immediate child groups that are either terms
      that do not have any arrows coming into them from another term group,
      or that are bodies with no arrows in or out of any kind.
    * Recursively call `termGroupToCode` or `sectionGroupToCode` on each of
      the elements of the list; call the results `r1` through `rN`.
    * Form the text `section S r1 r2 ... rN end S`, with each `ri` and the
      start/end markers on separate lines, and with group-ID comments added
      to the start and end markers for the section group.  Note that `S` is
      as computed above (not a literal letter S).
 1. Remove the feature from validation that marks body groups yellow if they
    have no arrows to term groups; instead, create code from them using
    `sectionGroupToCode`.
 1. Test, updating your example document to use this new feature.
 1. Add the next page of the tutorial that shows how to use this feature to
    be able to declare temporary variables and constants, just as in the
    Lean tutorials.

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
