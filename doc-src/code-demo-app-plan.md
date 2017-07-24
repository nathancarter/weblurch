
# Plan for a code-related demo app

This document is the specifications and development for a demo app built on
the Lurch Web Platform.  The app will be a prototype of an idea for how code
can be written in natural language using the groups-and-connections UI that
we use in webLurch for proofs.

The app will be divided by a vertical splitter into two panes, the left of
which will be the standard webLurch UI, and the right of which will be code
generated from the document's meaning. The code for this demo app is
[here](../app/sidebar-example-solo.litcoffee).

## Suggestions

This is not yet planned, but the "suggestions" feature that exists in the
main app would make a nice showcase feature in this app as well.

## Refactoring forms

 * On the context menu for groups will be an item "Rephrase..."
 * Clicking it opens a dialog in which the user can browse through all the
   structure translators that apply to the code form represented by the
   group, and choose one (or cancel).
 * If the user chooses one, the content of the group in the document
   is rewritten to match the output of the translator.  No interior
   groups are destroyed, only moved.
 * Editing a group by hand (the text immediately inside a group)
   marks it dirty, so that the "rephrase" action will first warn you
   that if you accept the changes, you'll be throwing away your
   manual edits.

## Low priority

 * If there is a selection when the user attempts to insert a group, and it
   contains text only with zero or more entire groups among the text, but
   no partial groups, and the selection is not exactly equal to the content
   of an existing group, then the boilerplate code is inserted at the
   cursor point, and (a) if the boiler-plate code has no inner groups, all
   of its inner text is replaced by the content of the selection, but (b)
   if it does have inner groups, then the first one's content is replaced
   by the content of the selection.
 * If there is a selection when the user attempts to insert a group, and
   that selection is exactly the extent of an existing group, a modal
   dialog will ask if the user wishes to (a) wrap the existing group in the
   new group, (b) insert the new group inside the existing one, or (c)
   change the existing group into the new type.
 * If there is a selection when the user attempts to insert a group, and
   none of the above criteria apply, let the user know that they cannot
   insert a new group in that situation.
